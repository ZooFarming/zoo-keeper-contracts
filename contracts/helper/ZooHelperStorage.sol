// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract ZooHelperStorage {
    using SafeMath for uint256;

    address public zooToken;
    address public zooFarming;
    address public zooPair;
    address public nftFactory;
    address public safari;
    address public alchemy;
}