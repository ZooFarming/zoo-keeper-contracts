// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../token/ZooToken.sol";



// ZooKeeperFarming is the master of ZOO. He can make ZOO and he is a fair guy.
//
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

interface IWaspFarming {
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);

    function pendingWasp(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}

contract ZooKeeperFarming is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.

        uint256 waspRewardDebt; // extra reward debt
        //
        // We do some fancy math here. Basically, any point in time, the amount of ZOOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accZooPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accZooPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ZOOs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ZOOs distribution occurs.
        uint256 accZooPerShare;   // Accumulated ZOOs per share, times 1e12. See below.

        // extra pool reward
        uint256 waspPid;         // PID for extra pool
        uint256 accWaspPerShare; // Accumulated extra token per share, times 1e12.
    }

    // The ZOO TOKEN!
    ZooToken public zoo;
    // Dev address.
    address public devaddr;
    // The block number when ZOO mining starts.
    uint256 public startBlock;
    // Block number when test ZOO period ends.
    uint256 public allEndBlock;
    // ZOO tokens created per block.
    uint256 public zooPerBlock;
    // Max multiplier
    uint256 public maxMultiplier;
    // sc address for dual farming
    address public wanswapFarming;          
    // the reward token for dual farming
    address public wasp;       

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;


    // boosting controller contract address
    address public boostingAddr;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        ZooToken _zoo,
        address _devaddr,
        address _boostingAddr,
        uint256 _zooPerBlock,
        uint256 _startBlock,
        uint256 _allEndBlock,
        address _wanswapFarmingAddr,
        address _waspAddr
    ) public {
        zoo = _zoo;
        devaddr = _devaddr;
        startBlock = _startBlock;
        allEndBlock = _allEndBlock;
        boostingAddr = _boostingAddr;
        zooPerBlock = _zooPerBlock;
        maxMultiplier = 3e12;
        wanswapFarming = _wanswapFarmingAddr;
        wasp = _waspAddr;
    }

    function setBoostingAddr(address _boostingAddr) public onlyOwner {
        boostingAddr = _boostingAddr;
    }

    function setWaspSC(address _wanswapFarming, address _wasp) public onlyOwner {
        wanswapFarming = _wanswapFarming;
        wasp = _wasp;
    }

    function setWaspPid(uint _pid, uint _waspPid) public onlyOwner {
        poolInfo[_pid].waspPid = _waspPid;
        poolInfo[_pid].accWaspPerShare = 0;
    }

    function setMaxMultiplier(uint _maxMultiplier) public onlyOwner {
        maxMultiplier = _maxMultiplier;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate, uint _waspPid) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accZooPerShare: 0,
            waspPid: _waspPid,
            accWaspPerShare: 0
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
        if (_from >= allEndBlock) {
            return 0;
        }

        if (_to < startBlock) {
            return 0;
        }

        if (_to > allEndBlock) {
            return allEndBlock.sub(_from);
        }

        if (_from < startBlock) {
            return _to.sub(startBlock);
        }

        return _to.sub(_from);
    }

    // View function to see pending ZOOs on frontend.
    function pendingZoo(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accZooPerShare = pool.accZooPerShare;
        
        uint256 lpSupply;
        if (wanswapFarming == address(0)) {
            lpSupply = pool.lpToken.balanceOf(address(this));
        } else {
            (lpSupply,) = IWaspFarming(wanswapFarming).userInfo(pool.waspPid, address(this));
        }

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 zooReward = multiplier.mul(zooPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accZooPerShare = accZooPerShare.add(zooReward.mul(1e12).div(lpSupply));
            // multiplier from lockTime and NFT
            if (boostingAddr != address(0)) {
                uint multiplier2 = Boosting(boostingAddr).getMultiplier(_pid, _user);
                if (multiplier2 > maxMultiplier) {
                    multiplier2 = maxMultiplier;
                }
                accZooPerShare = accZooPerShare.mul(multiplier2).div(1e12);
            }
        }
        return user.amount.mul(accZooPerShare).div(1e12).sub(user.rewardDebt);
    }

    function pendingWasp(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWaspPerShare = pool.accWaspPerShare;
        
        uint256 lpSupply;
        if (wanswapFarming == address(0)) {
            return 0;
        } 
        
        (lpSupply,) = IWaspFarming(wanswapFarming).userInfo(pool.waspPid, address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 waspReward = IWaspFarming(wanswapFarming).pendingWasp(pool.waspPid, address(this));
            accWaspPerShare = accWaspPerShare.add(waspReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accWaspPerShare).div(1e12).sub(user.waspRewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply;
        if (wanswapFarming == address(0)) {
            lpSupply = pool.lpToken.balanceOf(address(this));
        } else {
            (lpSupply,) = IWaspFarming(wanswapFarming).userInfo(pool.waspPid, address(this));
            uint256 waspReward = IWaspFarming(wanswapFarming).pendingWasp(pool.waspPid, address(this));
            pool.accWaspPerShare = pool.accWaspPerShare.add(waspReward.mul(1e12).div(lpSupply));
            //claim
            IWaspFarming(wanswapFarming).withdraw(pool.waspPid, 0);
        }
        
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 zooReward = multiplier.mul(zooPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accZooPerShare = pool.accZooPerShare.add(zooReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to ZooKeeperFarming for ZOO allocation.
    function deposit(uint256 _pid, uint256 _amount, uint lockTime, uint nftTokenId) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
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
            mintZoo(pending);
            safeZooTransfer(msg.sender, pending);

            if (wanswapFarming != address(0)) {
                uint256 waspPending = user.amount.mul(pool.accWaspPerShare).div(1e12).sub(user.waspRewardDebt);
                safeWaspTransfer(msg.sender, waspPending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accZooPerShare).div(1e12);

        if (wanswapFarming != address(0)) {
            IWaspFarming(wanswapFarming).deposit(pool.waspPid, _amount);
            user.waspRewardDebt = user.amount.mul(pool.accZooPerShare).div(1e12);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from ZooKeeperFarming.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 userOldAmount = user.amount;
        uint256 pending = user.amount.mul(pool.accZooPerShare).div(1e12).sub(user.rewardDebt);
        if (boostingAddr != address(0)) {
            // multiplier from lockTime and NFT
            uint multiplier2 = Boosting(boostingAddr).getMultiplier(_pid, msg.sender);
            if (multiplier2 > maxMultiplier) {
                multiplier2 = maxMultiplier;
            }
            pending = pending.mul(multiplier2).div(1e12);
        }
        mintZoo(pending);
        safeZooTransfer(msg.sender, pending);

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accZooPerShare).div(1e12);

        if (wanswapFarming != address(0)) {
            uint256 waspPending = userOldAmount.mul(pool.accWaspPerShare).div(1e12).sub(user.waspRewardDebt);
            safeWaspTransfer(msg.sender, waspPending);
            user.waspRewardDebt = user.amount.mul(pool.accWaspPerShare).div(1e12);
        }

        if (_amount > 0) {
            if (boostingAddr != address(0)) {
                require(Boosting(boostingAddr).checkWithdraw(_pid, msg.sender), "Lock time not finish");
                if (user.amount == 0x0) {
                    Boosting(boostingAddr).withdraw(_pid, msg.sender);
                }
            }

            if (wanswapFarming != address(0)) { 
                IWaspFarming(wanswapFarming).withdraw(pool.waspPid, _amount);
            }

            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        emit Withdraw(msg.sender, _pid, _amount);
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

    // Safe wasp transfer function, just in case if rounding error causes pool to not have enough WASP.
    function safeWaspTransfer(address _to, uint256 _amount) internal {
        uint256 waspBal = IERC20(wasp).balanceOf(address(this));
        if (_amount > waspBal) {
            IERC20(wasp).transfer(_to, waspBal);
        } else {
            IERC20(wasp).transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "Should be dev address");
        devaddr = _devaddr;
    }

    function mintZoo(uint amount) private {
        zoo.mint(devaddr, amount.mul(28).div(100));
        zoo.mint(address(this), amount);
    }
}
