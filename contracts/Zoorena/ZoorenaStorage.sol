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
        uint randomSeed;
        uint timestamp;
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

    // eventId(1~8) => options count
    mapping(uint => uint) public eventOptions;

    // roundId => user => eventId => claimed
    mapping(uint => mapping(address => mapping(uint => bool))) public eventClaimed;

    // roundId => ticket => claimed
    mapping(uint => mapping(uint => bool)) public jackpotClaimed;

    // roundId => index => leftTicket number
    mapping(uint => mapping(uint => uint)) public leftTickets;
    mapping(uint => uint) public leftTicketCount;

    // roundId => index => rightTicket number
    mapping(uint => mapping(uint => uint)) public rightTickets;
    mapping(uint => uint) public rightTicketCount;

    // ticket number => user address
    mapping(uint => address) public ticketOwner;

    // pos random contract address
    address public POS_RANDOM_ADDRESS;

    // roundId => user address => ticket index => ticket code
    mapping(uint => mapping(address => mapping(uint => uint))) public userTickets;

    // roundId => user address => ticket count
    mapping(uint => mapping(address => uint)) public userTicketCount;

    // roundId => user address => eventId => bet price
    mapping(uint => mapping(address => mapping(uint => uint))) public userBetPrice;
}
