//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IBalancerPoolPriceOracle.sol";
import "./interface/IBalancerV2Vault.sol";


/*
    Users get rewarded with LPOptionsToken
    A user can burn LPOptionsToken to mint an option here.
        => LMOptionsToken is the minter of this contract

    This contract is responsible for moving the reward ERC20 from the LPOptionsToken to users.
*/

contract LMAsOptionsWithBal is ERC721, Ownable {
    address immutable public reward;
    address immutable public buyWith;
    address immutable public optionsToken;
    
    IBalancerV2Vault constant balancerV2Vault = IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address public treasury;
    uint256 public OPTION_EXPIRY;
    uint256 public strikeToMarketRatio; // in BPS

    using SafeERC20 for IERC20;
    
    IBalancerPoolPriceOracle public oracle;
    uint256 immutable buyWithDecimalAdjustments;
    uint256 immutable rewardDecimalAdjustments;

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
        address _balancerPoolAsOracle,
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
        oracle = IBalancerPoolPriceOracle(_balancerPoolAsOracle);
        transferOwnership(_owner);
        buyWithDecimalAdjustments = 10 ** ERC20(_buyWith).decimals();
        rewardDecimalAdjustments = 10 ** ERC20(_reward).decimals();

        (address[] memory poolTokens, ,) = balancerV2Vault.getPoolTokens(IBalancerPoolPriceOracle(_balancerPoolAsOracle).getPoolId());
        if(_buyWith == poolTokens[0]) {
            require(_reward == poolTokens[1], "pool tokens doesn't match option tokens");
        } else {
            require(_buyWith == poolTokens[1] && _reward == poolTokens[0], "pool tokens doesn't match option tokens");
        }

    }

    function setTreasury(address _treasury) onlyOwner public {
        treasury = _treasury;
    }

    function oracleAssetToAsset(uint256 amount, uint256 time) internal view returns (uint256) {
        IBalancerPoolPriceOracle.OracleAverageQuery[] memory arg = new IBalancerPoolPriceOracle.OracleAverageQuery[](1);

        arg[0] = IBalancerPoolPriceOracle.OracleAverageQuery({
            variable: IBalancerPoolPriceOracle.Variable.PAIR_PRICE,
            secs: time,
            ago: 0
        });

        uint256[] memory _queriedResult = oracle.getTimeWeightedAverage(
            arg
        );

        (address[] memory poolTokens, ,) = balancerV2Vault.getPoolTokens(oracle.getPoolId());

        // quriedResult gives us "the price of the second token in units of the first token"
        //   Note from Balancer Doc
        //   "the price is computed *including* the tokens decimals. This means that the pair price of a Pool with
        //    DAI and USDC will be close to 1.0, despite DAI having 18 decimals and USDC 6."
        uint256 _unitMarketPrice;
        if(buyWith == poolTokens[0]) {
            _unitMarketPrice = _queriedResult[0];
        } else {
            // the price is in 18 decimal
            // to keep it in 18 decimal, we do 10^18 * 10^18 / returnedPrice, where returnedPrice is realPrice * 10^18
            _unitMarketPrice = 10**36 / _queriedResult[0];
        }

        return amount * _unitMarketPrice * buyWithDecimalAdjustments   // reward amount * reward decimal * marketPrice * 18 decimal * buyWith decimal 
                / (10 ** 18) / rewardDecimalAdjustments;        // 18 decimal / reward decimal
    }


    // This should only be called by the options token contract
    // as we expect options token to be burnt. 
    function mintOption(address receiver, uint256 amount) public onlyOptionToken returns (uint256)  {
        // using similar interface as the original Andre's PoC, 
        // reward & buyWith are already set globally, no need to pass them in
        // uint256 _marketPrice = oracle.assetToAsset(reward, amount, buyWith, 3600);
        uint256 _marketPrice = oracleAssetToAsset(amount, 3600);
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