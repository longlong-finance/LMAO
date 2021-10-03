//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface v3oracle {
    function assetToAsset(address from, uint amount, address to, uint twap_duration) external view returns (uint);
}