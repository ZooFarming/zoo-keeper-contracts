pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract NFTFactoryStorage {
    using SafeMath for uint256;

    struct UserInfo {
        uint emptyTimes; // silver chest empty times;
    }

    mapping(address => UserInfo) public userInfo;

    uint public goldenChestPrice;

    uint public silverChestPrice;

    address public zooToken;

    address public zooNFT;

    address public maxNFTLevel;

    address public maxNFTCategory;

    address public maxNFTItem;

    address public maxNFTRandom;
}
