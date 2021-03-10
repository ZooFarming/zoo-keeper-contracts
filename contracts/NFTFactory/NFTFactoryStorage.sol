// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract NFTFactoryStorage {
    using SafeMath for uint256;

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
}
