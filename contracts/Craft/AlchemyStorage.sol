// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";


contract AlchemyStorage {
    using SafeMath for uint256;

    uint public dropRate;

    address public elixirNFT;

    uint public totalMint;

    uint public totalBurn;

    uint public buyPrice;

    address public buyToken;

    struct ElixirInfo {
        uint level; // current level
        uint drops; // current drops in bottle
    }

    // tokenId => ElixirInfo
    mapping(uint => ElixirInfo) public elixirInfoMap;

    // user => tokenId
    mapping(address => uint) public elixirOwnerMap;
}
