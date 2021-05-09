// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract ZoorenaStorage {
    using SafeMath for uint256;

    struct RoundInfo {
        uint jackpot;

        uint leftUserCount;
        uint leftNftCount;
        uint leftPower;

        uint rightUserCount;
        uint rightNftCount;
        uint rightPower;

        uint fightStartBlock;
    }

    bool public pause;

    // A timestamp for round 0 betting start, Monday UTC 00:00
    uint public baseTime;

    // A round total seconds (A week)
    uint public roundTime;

    // fight start time = roundTime - startTime
    uint public startTime;

    // bet close time = roundTime - closeTime
    uint public closeTime;

    // time for each event
    uint public eventTime;

    // init power point for both
    uint public initPower;

    uint internal _foundationSeed;

    // roundId => info
    mapping(uint => RoundInfo) public roundInfo;

    // roundId => index => user
    mapping(uint => mapping(uint => address)) public leftUser;

    // roundId => index => tokenId
    mapping(uint => mapping(uint => uint)) public leftNft;

    // roundId => index => user
    mapping(uint => mapping(uint => address)) public rightUser;

    // roundId => index => tokenId
    mapping(uint => mapping(uint => uint)) public rightNft;

    // roundId => user address => eventIndex(0~8) => eventSelection(0:empty, silver:1~10, golden:101~110)
    mapping(uint => mapping(address => mapping(uint => uint))) public userEvent;

    // user address => deposited tokenId
    mapping(address => uint) public userNft;

    // jackpot: roundId => index(0~2) => user address
    mapping(uint => mapping(uint => address)) public jackpotResult;

    uint[] public LEVEL_MASK; // 60%, 30%, 5%, 1%

    uint[] public CATEGORY_MASK; // 40%, 33%, 17%, 7%, 2%, 1%
    
    uint[] public ITEM_MASK; // 35%, 30%, 20%, 10%, 5%
}
