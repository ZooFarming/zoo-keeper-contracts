// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract MarketplaceStorage {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct OrderInfo {
        // NFT owner
        address owner;
        // NFT contract address
        address nftContract;
        // NFT tokenId
        uint tokenId;
        // pay token;
        address token;
        // pay amount;
        uint price;
        // order expiration time
        uint expiration;
        // order expiration time
        uint createTime;
    }

    uint public maxExpirationTime;

    uint public minExpirationTime;


    EnumerableSet.UintSet internal orderIds; 

    mapping(uint => OrderInfo) orders;
}
