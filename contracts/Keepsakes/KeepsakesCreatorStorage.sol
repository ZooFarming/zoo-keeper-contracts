// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


contract KeepsakesCreatorStorage {
    using SafeMath for uint256;

    address public keepsakeNFT;

    EnumerableSet.AddressSet authorList;

    mapping(bytes32 => uint) public keepsakesSupply;
    mapping(uint => uint) public keepsakesIndex;
    mapping(uint => bytes32) public keepsakesInitUriHash;
}
