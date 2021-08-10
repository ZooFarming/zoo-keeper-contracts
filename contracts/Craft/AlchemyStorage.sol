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

    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
        uint256 elixirId;
    }

    // tokenId => ElixirInfo
    mapping(uint => ElixirInfo) public elixirInfoMap;

    // user => tokenId
    mapping(address => uint) public elixirOwnerMap;

    // user => UserInfo
    mapping(address => UserInfo) public userInfoMap;

    uint256 lastRewardBlock;  // Last block number that drops distribution occurs.

    uint256 accDropPerShare;   // Accumulated Drops per share, times 1e12. See below.

    uint256 totalZooStaked;
}
