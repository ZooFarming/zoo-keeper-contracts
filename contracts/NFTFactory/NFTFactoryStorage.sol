// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract NFTFactoryStorage {
    struct StakeInfo {
        uint lockTime;
        uint startTime;
        uint stakeAmount;
    }

    struct StakePlan {
        uint priceMul;
        uint priceDiv;
        uint lockTime;
    }

    // user => stake type => stake info
    mapping(address => mapping(uint => StakeInfo)) public stakeInfo;

    mapping(address => uint) public emptyTimes;

    // id => plan
    mapping(uint => StakePlan) public stakePlan;

    uint public goldenChestPrice;

    address public zooToken;

    address public zooNFT;

    uint public maxNFTLevel;

    uint public maxNFTCategory;

    uint public maxNFTItem;

    uint public maxNFTRandom;

    uint public lastPrice;

    uint public lastOrderTimestamp;

    uint public priceUp0;

    uint public priceUp1;

    uint public priceDown0;

    uint public priceDown1;

    uint public stakePlanCount;

    uint public dynamicPriceTimeUnit;

    uint public dynamicMaxPrice;

    uint public dynamicMinPrice;
    
    uint[] public LEVEL_MASK; // 60%, 30%, 5%, 1%

    uint[] public CATEGORY_MASK; // 40%, 33%, 17%, 7%, 2%, 1%
    
    uint[] public ITEM_MASK; // 35%, 30%, 20%, 10%, 5%

    // planId => stakeZooAmount
    mapping(uint => uint) public stakedAmount;

    uint internal _foundationSeed;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    uint public currentRequestCount;

    uint public doneRequestCount;

    struct MintRequestInfoV2 {
        address user;
        uint price;
        uint chestType; // 0: buy silver, 1: buy golden, 2: zoo claim, 4: zoorena silver, 5: zoorena golden
    }

    // request index => request info
    mapping(uint => MintRequestInfoV2) mintRequestInfoV2;

    bytes32 public constant FACTORY_MINTER_ROLE = keccak256("FACTORY_MINTER_ROLE");

    // add for VRF
    uint64 public s_subscriptionId;
    
    // The default is 1, but you can set this higher.
    uint16 requestConfirmations = 1;
    
    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 2500000;
    
    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    VRFCoordinatorV2Interface COORDINATOR;
}
