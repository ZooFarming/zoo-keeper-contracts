// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IWWAN {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract SafariStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of wanWans
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20  lpToken;          // Address of LP token contract.
        uint256 currentSupply;   //
        uint256 bonusStartBlock;  //
        uint256 bonusEndBlock;    // Block number when bonus period ends.

        uint256 lastRewardBlock;  // Last block number that reward distribution occurs.
        uint256 accRewardPerShare;// Accumulated reward per share, times 1e12. See below.
        uint256 rewardPerBlock;   // tokens reward per block.
        address rewardToken;      // token address for reward
    }

    IWWAN public wwan;            // The WWAN contract
    PoolInfo[] public poolInfo;   // Info of each pool.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;// Info of each user that stakes LP tokens.
}
