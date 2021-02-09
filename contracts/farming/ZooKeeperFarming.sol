pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
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

    function checkWithdraw(uint pid, address user) external returns (bool);

    function getMultiplier(uint pid, address user) external returns (uint); // zoom in 1e12 times;
}

contract ZooKeeperFarming is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of WASPs
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
        uint256 allocPoint;       // How many allocation points assigned to this pool. WASPs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that WASPs distribution occurs.
        uint256 accZooPerShare;  // Accumulated WASPs per share, times 1e12. See below.
    }

    // The ZOO TOKEN!
    ZooToken public zoo;
    // Dev address.
    address public devaddr;
    // Block number when test ZOO period ends.
    uint256 public allEndBlock;
    // ZOO tokens created per block.
    uint256 public zooPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ZOO mining starts.
    uint256 public startBlock;

    // boosting controller contract address
    address public boostingAddr;

    // Extra reward contract address
    address public extraRewardAddr;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        ZooToken _zoo,
        address _devaddr,
        address _boostingAddr,
        address _extraRewardAddr,
        uint256 _zooPerBlock,
        uint256 _startBlock,
        uint256 _allEndBlock
    ) public {
        zoo = _zoo;
        devaddr = _devaddr;
        startBlock = _startBlock;
        allEndBlock = _allEndBlock;
        boostingAddr = _boostingAddr;
        extraRewardAddr = _extraRewardAddr;
    }

    function setBoostingAddr(address _boostingAddr) public onlyOwner {
        boostingAddr = _boostingAddr;
    }

    function setExtrRewardAddr(address _extraRewardAddr) public onlyOwner {
        extraRewardAddr = _extraRewardAddr;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accZooPerShare: 0
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
        if (from >= allEndBlock) {
            return 0;
        }

        if (to < startBlock) {
            return 0;
        }

        if (to > allEndBlock) {
            return allEndBlock.sub(from);
        }

        return to.sub(from);
    }

    // View function to see pending WASPs on frontend.
    function pendingZoo(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accZooPerShare = pool.accZooPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 zooReward = multiplier.mul(zooPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accZooPerShare = accZooPerShare.add(zooReward.mul(1e12).div(lpSupply));
            // multiplier from lockTime and NFT
            if (boostingAddr != address(0)) {
                uint multiplier2 = Boosting(boostingAddr).getMultiplier(_pid, _user);
                accZooPerShare = accZooPerShare.mul(multiplier2).div(1e12);
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

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 zooReward = multiplier.mul(zooPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        // zoo.mint(devaddr, zooReward.div(20));
        // zoo.mint(address(this), zooReward);
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
                pending = pending.mul(multiplier2).div(1e12);
            }
            zoo.mint(devaddr, pending.mul(28).div(100));
            zoo.mint(address(this), pending);
            safeZooTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accZooPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from ZooKeeperFarming.
    function withdraw(uint256 _pid, uint256 _amount) public {
        if (boostingAddr != address(0)) {
            require(Boosting(boostingAddr).checkWithdraw(_pid, msg.sender), "Lock time not finish");
        }
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accZooPerShare).div(1e12).sub(user.rewardDebt);
        if (boostingAddr != address(0)) {
            // multiplier from lockTime and NFT
            uint multiplier2 = Boosting(boostingAddr).getMultiplier(_pid, msg.sender);
            pending = pending.mul(multiplier2).div(1e12);
        }
        zoo.mint(devaddr, pending.mul(28).div(100));
        zoo.mint(address(this), pending);

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accZooPerShare).div(1e12);
        safeZooTransfer(msg.sender, pending);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Safe zoo transfer function, just in case if rounding error causes pool to not have enough WASPs.
    function safeZooTransfer(address _to, uint256 _amount) internal {
        uint256 zooBal = zoo.balanceOf(address(this));
        if (_amount > zooBal) {
            zoo.transfer(_to, waspBal);
        } else {
            zoo.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "Should be dev address");
        devaddr = _devaddr;
    }
}
