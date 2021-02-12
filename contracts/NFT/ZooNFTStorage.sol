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

    mapping(uint => TokenInfo) public tokenInfo;
}