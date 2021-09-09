// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract AlchemyStorage {
    using SafeMath for uint256;

    uint256 public baseRatePerBlock; // drops per block

    address public elixirNFT;

    uint256 public totalMint;

    uint256 public totalBurn;

    uint256 public priceFactor0;

    uint256 public priceFactor1;

    uint256 public maxBoosting;

    uint256 public maxStakeZoo;

    uint256 public dropCostPerLevel;

    address public priceOracle;

    address public buyToken;

    address public zooNFT;

    struct ElixirInfo {
        uint256 level; // current level
        uint256 drops; // current drops in bottle
        uint256 color; // color of the elixir
        uint256 shape; // shape of the elixir
        string name; // name of the elixir
    }

    struct UserInfo {
        uint256 amount;
        uint256 lastRewardBlock; // Last block number that drops distribution occurs.
    }

    struct CraftInfo {
        uint256 elixirId;
        uint256 tokenId0;
        uint256 tokenId1;
    }

    // tokenId => ElixirInfo
    mapping(uint256 => ElixirInfo) public elixirInfoMap;

    // user => tokenId
    mapping(address => uint256) public userElixirMap;

    // user => UserInfo
    mapping(address => UserInfo) public userInfoMap;

    // user => CraftInfo
    mapping(address => CraftInfo) public pendingCraft;

    uint256 public elixirBaseScore;
}
