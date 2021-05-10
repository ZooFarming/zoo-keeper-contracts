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

    address public playToken;

    address public nftFactory;

    address public zooNFT;

    bool public pause;

    // A timestamp for round 0 betting start, Monday UTC 00:00
    uint public baseTime;

    // A round total seconds (A week)
    uint public roundTime;

    // bet close time in a round 
    uint public closeTime;

    // roundId => info
    mapping(uint => RoundInfo) public roundInfo;

    // roundId => index => user
    mapping(uint => mapping(uint => address)) public leftUser;

    // roundId => index => user
    mapping(uint => mapping(uint => address)) public rightUser;

    // roundId => user address => eventIndex(0~8) => eventSelection(0:empty, silver:1~10, golden:101~110)
    mapping(uint => mapping(address => mapping(uint => uint))) public userEvent;

    // user address => deposited tokenId
    mapping(address => uint) public userNft;

    // jackpot: roundId => index(0~2) => user address
    mapping(uint => mapping(uint => address)) public jackpotResult;

    // eventId(1~8) => options count
    mapping(uint => uint) public eventOptions;

    uint[] public LEVEL_MASK; // 60%, 30%, 5%, 1%

    uint[] public CATEGORY_MASK; // 40%, 33%, 17%, 7%, 2%, 1%
    
    uint[] public ITEM_MASK; // 35%, 30%, 20%, 10%, 5%
}
