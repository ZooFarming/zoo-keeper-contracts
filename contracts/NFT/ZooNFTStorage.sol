// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract ZooNFTStorage {
    using SafeMath for uint256;

    struct TokenInfo {
        uint256 level;
        uint256 category;
        uint256 item;
        uint256 random;
    }

    // Use for boosting calc: boosting = (level - 1) * a + category * b + item * c + random * d;
    struct ScaleParams {
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
    }

    ScaleParams public scaleParams;

    // tokenId => tokenInfo
    mapping(uint => TokenInfo) public tokenInfo;

    // level => category => item => tokenURI
    mapping(uint => mapping(uint => mapping(uint => string))) public nftURI;

    // chance scaled 1e12
    // level => chance
    mapping(uint => uint) public LEVEL_CHANCE;         // 60%, 30%, 5%, 1%

    mapping(uint => uint) public CATEGORY_CHANCE;      // 40%, 33%, 17%, 7%, 2%, 1%

    mapping(uint => uint) public ITEM_CHANCE;          // 35%, 30%, 20%, 10%, 5%

    // chance => boost
    mapping(uint => uint) public boostMap;

    // chance => lockTime reduce
    mapping(uint => uint) public reduceMap;
}
