pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract NFTFactoryStorage {
    using SafeMath for uint256;

    struct UserInfo {
        uint emptyTimes; // silver chest empty times;
    }

    mapping(address => UserInfo) public userInfo;

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
}
