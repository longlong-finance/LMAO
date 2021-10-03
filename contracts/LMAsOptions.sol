//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/v3oracle.sol";


/*
    Users get rewarded with LMAsOptions
    A user can burn LMAsOptions to mint an option here.
        => LMAsOptions is the minter of this contract

    This contract is responsible for moving the reward ERC20 from the LMAsOptions to users.
*/

contract LMAsOptions is ERC721, Ownable {
    address immutable public reward;
    address immutable public buyWith;
    address immutable public optionsToken;
    
    address public treasury;
    uint256 public OPTION_EXPIRY;
    uint256 public strikeToMarketRatio; // in BPS

    using SafeERC20 for IERC20;
    
    v3oracle constant oracle = v3oracle(0xF8FEe9AD9C20705D806eABEB250d5E606C2D8bC3);

    struct option {
        uint amount;
        uint strike;
        uint expiry;
        bool exercised; 
    }

    option[] public options;
    uint256 public nextIndex;
    mapping(address => uint[]) _userOptions;

    modifier onlyOptionToken() {
        require(optionsToken == msg.sender, "caller is not the option token contract");
        _;
    }

    event Created(address indexed owner, uint amount, uint strike, uint expiry, uint id);
    event Redeem(address indexed from, address indexed owner, uint amount, uint strike, uint id);

    constructor(
        address _reward,
        address _buyWith,
        address _owner,
        address _treasury,
        uint256 _optionExpiry,
        uint256 _strikeToMarketRatio,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        require(_strikeToMarketRatio <= 10000, "invalid ratio");
        reward = _reward;
        buyWith = _buyWith;
        optionsToken = msg.sender;
        treasury = _treasury;
        OPTION_EXPIRY = _optionExpiry;
        strikeToMarketRatio = _strikeToMarketRatio;
        transferOwnership(_owner);
    }

    function setTreasury(address _treasury) onlyOwner public {
        treasury = _treasury;
    }

    // This should only be called by the options token contract
    // as we expect options token to be burnt. 
    function mintOption(address receiver, uint256 amount) public onlyOptionToken returns (uint256)  {
        uint256 _marketPrice = oracle.assetToAsset(reward, amount, buyWith, 3600);
        uint256 _strike = _marketPrice * strikeToMarketRatio / 10000;
        uint256 _expiry = block.timestamp + OPTION_EXPIRY;
        options.push(option(amount, _strike, _expiry, false));
        _safeMint(receiver, nextIndex);
        emit Created(receiver, amount, _strike, _expiry, nextIndex);
        return nextIndex++;        
    }

    function redeem(uint id) external {
        require(_isApprovedOrOwner(msg.sender, id));
        option storage _opt = options[id];
        require(_opt.expiry >= block.timestamp && !_opt.exercised);
        _opt.exercised = true;
        IERC20(buyWith).safeTransferFrom(msg.sender, treasury, _opt.strike);
        IERC20(reward).safeTransferFrom(optionsToken, msg.sender, _opt.amount);
        emit Redeem(msg.sender, msg.sender, _opt.amount, _opt.strike, id);
    }

}