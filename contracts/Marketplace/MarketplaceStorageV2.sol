// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./MarketplaceStorage.sol";

contract MarketplaceStorageV2 is MarketplaceStorage {

    // level => category => item => ZOO price
    mapping(uint => mapping(uint => mapping(uint => uint))) public zooNftPrice;

    uint public constant defaultPrice;

    address public zooNFT;
}
