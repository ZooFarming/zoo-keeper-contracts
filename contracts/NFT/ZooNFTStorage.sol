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
    uint[] public LEVEL_CHANCE = [6e11, 3e11, 5e10, 1e10];             // 60%, 30%, 5%, 1%
    uint[] public CATEGORY_CHANCE = [4e11, 33e10, 17e10, 7e10, 2e10, 1e10];  // 40%, 33%, 17%, 7%, 2%, 1%
    uint[] public ITEM_CHANCE = [35e10, 3e11, 2e11, 1e11, 5e10];          // 35%, 30%, 20%, 10%, 5%

    // chance => boost
    mapping(uint => uint) public boostMap;

    // chance => lockTime reduce
    mapping(uint => uint) public reduceMap;
}
