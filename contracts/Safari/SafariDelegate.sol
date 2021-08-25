// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./SafariStorage.sol";

interface IRewardToken {
    function decimals() external view returns(uint8);
}

contract SafariDelegate is SafariStorage, Initializable, AccessControl {

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event QuitWanwan(address to, uint256 amount);
    event EmergencyQuitWanwan(address to, uint256 amount);

    function initialize(address admin, IWWAN _wwan) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        wwan = _wwan;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(IERC20 _lpToken,
                 uint256 _bonusStartBlock,
                 uint256 _bonusEndBlock,
                 uint256 _rewardPerBlock,
                 address _rewardToken
                 ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(block.number < _bonusEndBlock, "block.number >= bonusEndBlock");
        require(_bonusStartBlock < _bonusEndBlock, "_bonusStartBlock >= _bonusEndBlock");
        require(address(_lpToken) != address(0), "_lpToken == 0");

        uint256 lastRewardBlock = block.number > _bonusStartBlock ? block.number : _bonusStartBlock;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            currentSupply: 0,
            bonusStartBlock: _bonusStartBlock,
            bonusEndBlock: _bonusEndBlock,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0,
            rewardPerBlock: _rewardPerBlock,
            rewardToken: _rewardToken
        }));
    }

    // Update the given pool's. Can only be called by the owner.
    function set(uint256 _pid, uint256 _rewardPerBlock, uint256 _bonusEndBlock, bool _withUpdate) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        if (_withUpdate) {
            massUpdatePools();
        }
        poolInfo[_pid].rewardPerBlock = _rewardPerBlock;
        poolInfo[_pid].bonusEndBlock = _bonusEndBlock;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending wanWans on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256, uint256) {
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        uint256 curBlockNumber = (block.number < pool.bonusEndBlock) ? block.number : pool.bonusEndBlock;
        if (curBlockNumber > pool.lastRewardBlock && pool.currentSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, curBlockNumber);
            uint256 tokenReward = multiplier.mul(pool.rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(tokenReward.mul(getScale(pool.rewardToken)).div(pool.currentSupply));
        }
        return (user.amount, user.amount.mul(accRewardPerShare).div(getScale(pool.rewardToken)).sub(user.rewardDebt));
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 curBlockNumber = (block.number < pool.bonusEndBlock) ? block.number : pool.bonusEndBlock;
        if (curBlockNumber <= pool.lastRewardBlock) {
            return;
        }

        if (pool.currentSupply == 0) {
            pool.lastRewardBlock = curBlockNumber;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, curBlockNumber);
        uint256 tokenReward = multiplier.mul(pool.rewardPerBlock);
        pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(getScale(pool.rewardToken)).div(pool.currentSupply));
        pool.lastRewardBlock = curBlockNumber;
    }

    function deposit(uint256 _pid, uint256 _amount) public virtual {
        require(_pid < poolInfo.length, "pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number < pool.bonusEndBlock,"already end");

        updatePool(_pid);
        
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(getScale(pool.rewardToken)).sub(user.rewardDebt);
        
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        pool.currentSupply = pool.currentSupply.add(_amount);

        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(getScale(pool.rewardToken));

        if(pending > 0) {
            if (pool.rewardToken == address(wwan)) { // convert wwan to wan 
                wwan.withdraw(pending);
                msg.sender.transfer(pending);
            } else {
                require(IERC20(pool.rewardToken).transfer(msg.sender, pending), 'transfer token failed');
            }
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public virtual {
        require(_pid < poolInfo.length, "pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(getScale(pool.rewardToken)).sub(user.rewardDebt);
        
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.currentSupply = pool.currentSupply.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(getScale(pool.rewardToken));
        if(pending > 0) {
            if (pool.rewardToken == address(wwan)) { // convert wwan to wan 
                wwan.withdraw(pending);
                msg.sender.transfer(pending);
            } else {
                require(IERC20(pool.rewardToken).transfer(msg.sender, pending), 'transfer token failed');
            }
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        require(_pid < poolInfo.length, "pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        if(user.amount > 0){
            pool.currentSupply = pool.currentSupply.sub(user.amount);
            user.amount = 0;
            user.rewardDebt = 0;
            pool.lpToken.safeTransfer(address(msg.sender), amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function quitRewardToken(address payable _to, address rewardToken) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(_to != address(0), "_to == 0");
        uint balance = IERC20(rewardToken).balanceOf(address(this));
        require(IERC20(rewardToken).transfer(_to, balance), 'transfer token failed');
    }

    receive() external payable {
        require(msg.sender == address(wwan), "Only support value from WWAN"); // only accept WAN via fallback from the WWAN contract
    }

    function getScale(address _rewardToken) public view returns (uint256) {
        uint256 decimals = IRewardToken(_rewardToken).decimals();
        if (decimals == 18) {
            return 1e12;
        } else {
            return 1e32;
        }
    }
}
