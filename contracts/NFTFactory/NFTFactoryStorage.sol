pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract NFTFactoryStorage {
    using SafeMath for uint256;

    uint public randomNFTPrice;

    uint public stakeUnitPeriod;

    uint public stakeUnitAmount;

    address public zooToken;

    address public zooNFT;

    address public maxNFTLevel;

    address public maxNFTCategory;

    address public maxNFTItem;

    address public maxNFTRandom;
}
