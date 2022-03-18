// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../token/ZooToken.sol";



// ZooKeeperFarming is the master of ZOO. He can make ZOO and he is a fair guy.
// https://zookeeper.finance
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ZOO is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

interface Boosting {

    function deposit(uint pid, address user, uint lockTime, uint tokenId) external;

    function withdraw(uint pid, address user) external;

    function checkWithdraw(uint pid, address user) external view returns (bool);

    function getMultiplier(uint pid, address user) external view returns (uint); // zoom in 1e12 times;
}

contract ZooKeeperFarming is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.

        // We do some fancy math here. Basically, any point in time, the amount of ZOOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accZooPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accZooPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ZOOs to distribute per block.
        uint256 lastRewardTimestamp;  // Last timestamp that ZOOs distribution occurs.
        uint256 accZooPerShare;   // Accumulated ZOOs per share, times 1e12. See below.

        bool emergencyMode;
    }

    // The ZOO TOKEN!
    ZooToken public zoo;
    // Dev address.
    address public devaddr;
    // The timestamp when ZOO mining starts.
    uint256 public startTime;
    // timestamp when ZOO farming ends.
    uint256 public allEndTime;
    // ZOO tokens created per second.
    uint256 public zooPerSecond;
    // Max multiplier
    uint256 public maxMultiplier;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // boosting controller contract address
    address public boostingAddr;

    // params fixed after finalized
    bool public finalized;

    uint256 public constant TEAM_PERCENT = 20; 

    uint256 public constant PID_NOT_SET = 0xffffffff; 

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        ZooToken _zoo,
        address _devaddr,
        address _boostingAddr
    ) public {
        zoo = _zoo;
        devaddr = _devaddr;
        boostingAddr = _boostingAddr;
        maxMultiplier = 3e12;
    }

    function farmingConfig(uint256 _startTime, uint256 _endTime, uint256 _zooPerSecond) external onlyOwner {
        require(!finalized, "finalized, can not modify.");
        startTime = _startTime;
        allEndTime = _endTime;
        zooPerSecond = _zooPerSecond;
    }

    function finalize() external onlyOwner {
        finalized = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        require(startTime > 0 && allEndTime > 0 && zooPerSecond > 0, "not init");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accZooPerShare: 0,
            emergencyMode: false
        }));
    }

    // Update the given pool's ZOO allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (startTime == 0 || allEndTime == 0 || zooPerSecond == 0) {
            return 0;
        }

        if (_from >= allEndTime) {
            return 0;
        }

        if (_to < startTime) {
            return 0;
        }

        if (_to > allEndTime && _from < startTime) {
            return allEndTime.sub(startTime);
        }

        if (_to > allEndTime) {
            return allEndTime.sub(_from);
        }

        if (_from < startTime) {
            return _to.sub(startTime);
        }

        return _to.sub(_from);
    }

    // View function to see pending ZOOs on frontend.
    function pendingZoo(uint256 _pid, address _user) external view returns (uint256) {
        if (startTime == 0 || allEndTime == 0 || zooPerSecond == 0) {
            return 0;
        }

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accZooPerShare = pool.accZooPerShare;
        
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 zooReward = multiplier.mul(zooPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
            accZooPerShare = accZooPerShare.add(zooReward.mul(1e12).div(lpSupply));
            // multiplier from lockTime and NFT
            if (boostingAddr != address(0)) {
                uint multiplier2 = Boosting(boostingAddr).getMultiplier(_pid, _user);
                if (multiplier2 > maxMultiplier) {
                    multiplier2 = maxMultiplier;
                }
                return user.amount.mul(accZooPerShare).div(1e12).sub(user.rewardDebt).mul(multiplier2).div(1e12);
            }
        }
        return user.amount.mul(accZooPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // claim all rewards in farming pools
    function claimAll() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            withdraw(pid, 0);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        if (startTime == 0 || allEndTime == 0 || zooPerSecond == 0) {
            return;
        }

        PoolInfo storage pool = poolInfo[_pid];
        
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            if (pool.lastRewardTimestamp < block.timestamp) {
                pool.lastRewardTimestamp = block.timestamp;
            }
            return;
        }
        
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
        uint256 zooReward = multiplier.mul(zooPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accZooPerShare = pool.accZooPerShare.add(zooReward.mul(1e12).div(lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP tokens to ZooKeeperFarming for ZOO allocation.
    function deposit(uint256 _pid, uint256 _amount, uint lockTime, uint nftTokenId) public {
        require(startTime > 0 && allEndTime > 0 && zooPerSecond > 0, "not init");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount.add(_amount) > 0) {
            uint256 pending = user.amount.mul(pool.accZooPerShare).div(1e12).sub(user.rewardDebt);
            if (boostingAddr != address(0)) {
                // multiplier from lockTime and NFT
                uint multiplier2 = Boosting(boostingAddr).getMultiplier(_pid, msg.sender);
                if (multiplier2 > maxMultiplier) {
                    multiplier2 = maxMultiplier;
                }
                pending = pending.mul(multiplier2).div(1e12);

                Boosting(boostingAddr).deposit(_pid, msg.sender, lockTime, nftTokenId);
            }

            if (pending > 0) {
                mintZoo(pending);
                safeZooTransfer(msg.sender, pending);
            }
        }

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accZooPerShare).div(1e12);
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from ZooKeeperFarming.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(startTime > 0 && allEndTime > 0 && zooPerSecond > 0, "not init");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accZooPerShare).div(1e12).sub(user.rewardDebt);
        if (boostingAddr != address(0)) {
            // multiplier from lockTime and NFT
            uint multiplier2 = Boosting(boostingAddr).getMultiplier(_pid, msg.sender);
            if (multiplier2 > maxMultiplier) {
                multiplier2 = maxMultiplier;
            }
            pending = pending.mul(multiplier2).div(1e12);
        }

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accZooPerShare).div(1e12);

        if (pending > 0) {
            mintZoo(pending);
            safeZooTransfer(msg.sender, pending);
        }

        if (_amount > 0) {
            if (boostingAddr != address(0)) {
                require(Boosting(boostingAddr).checkWithdraw(_pid, msg.sender), "Lock time not finish");
                if (user.amount == 0x0) {
                    Boosting(boostingAddr).withdraw(_pid, msg.sender);
                }
            }

            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdrawEnable(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.emergencyMode = true;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.emergencyMode, "not enable emergence mode");

        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe zoo transfer function, just in case if rounding error causes pool to not have enough ZOOs.
    function safeZooTransfer(address _to, uint256 _amount) internal {
        uint256 zooBal = zoo.balanceOf(address(this));
        if (_amount > zooBal) {
            zoo.transfer(_to, zooBal);
        } else {
            zoo.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    function mintZoo(uint amount) private {
        zoo.mint(devaddr, amount.mul(TEAM_PERCENT).div(100));
        zoo.mint(address(this), amount);
    }
}
