// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract BoostingStorage {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 startTime;
        uint256 lockTime;
        // Staked NFT Information
        uint256 tokenId;
    }

    // NFT contract address
    address public NFTAddress;

    uint public scaleA;

    uint public scaleB;

    // storage all users info
    mapping (uint => mapping (address => UserInfo)) public userInfo;

    uint public minLockDays;

    uint public baseBoost;

    uint public increaseBoost;
}
