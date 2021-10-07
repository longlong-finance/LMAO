//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./LMAsOptionsWithBal.sol";

contract LMAsOptionsTokenWithBal is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address immutable public reward;
    LMAsOptionsWithBal immutable public optionContract;

    constructor(
        address _reward,
        address _buywith,
        address _treasury,
        uint256 _option_expiry,
        uint256 _strikeToMarketratio,
        address _balPoolAsOracle,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        address optionContractAddress = address(new LMAsOptionsWithBal(
            _reward, _buywith, msg.sender, _treasury, _option_expiry, _strikeToMarketratio, _balPoolAsOracle,
            _name, _symbol
        ));
        optionContract = LMAsOptionsWithBal(optionContractAddress);
        reward = _reward;
        IERC20(_reward).approve(optionContractAddress, type(uint256).max);
    }

    function refreshOptionApproval() public {
        IERC20(reward).approve(address(optionContract), type(uint256).max);
    }

    function mintOption(uint256 _amount) public returns(uint256){
        _burn(msg.sender, _amount);
        return optionContract.mintOption(msg.sender, _amount);
    }

    // Only owner could create option tokens
    function mintOptionToken(uint256 amount) public onlyOwner {
        IERC20(reward).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }
}
