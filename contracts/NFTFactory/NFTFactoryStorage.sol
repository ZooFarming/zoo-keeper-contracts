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

    // user => stake type => stake info
    mapping(address => mapping(uint => StakeInfo)) public stakeInfo;

    mapping(address => uint) public emptyTimes;

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
    
    uint[] public LEVEL_MASK = [74, 94, 99, 100]; // 74.00%, 20.00%, 5.00%, 1.00%
    uint[] public CATEGORY_MASK = [45, 75, 90, 97, 99, 100]; // 45%, 30%, 15%, 7%, 2%, 1%
    uint[] public ITEM_MASK = [35, 65, 85, 95, 100]; // 35%, 30%, 20%, 10%, 5%
}
