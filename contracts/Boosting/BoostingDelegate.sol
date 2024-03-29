// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "./BoostingStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IZooNFT {
    // scaled 1e12
    function getBoosting(uint _tokenId) external view returns (uint);

    // scaled 1e12
    function getLockTimeReduce(uint _tokenId) external view returns (uint);
}

contract BoostingDelegate is Initializable, AccessControl, ERC721Holder, BoostingStorage, ReentrancyGuard {

    bytes32 public constant ZOO_FARMING_ROLE = keccak256("FARMING_CONTRACT_ROLE");

    uint public constant MULTIPLIER_SCALE = 1e12;

    event BoostingDeposit(uint indexed _pid, address indexed _user, uint _lockTime, uint _tokenId);

    event BoostingWithdraw(uint indexed _pid, address indexed _user);

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(ZOO_FARMING_ROLE, DEFAULT_ADMIN_ROLE);
        minLockDays = 8 days;
        maxLockDays = 180 days;
        baseBoost = 2e9;
        increaseBoost = 4e9;
    }

    /// @dev Config the farming contract address
    function setFarmingAddr(address _farmingAddr) public {
        grantRole(ZOO_FARMING_ROLE, _farmingAddr);
    }

    function setNFTAddress(address _NFTAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        NFTAddress = _NFTAddress;
    }

    function setBoostScale(uint _minLockDays, uint _baseBoost, uint _increaseBoost) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        minLockDays = _minLockDays;
        baseBoost = _baseBoost;
        increaseBoost = _increaseBoost;
    }

    function setMaxLockDays(uint _maxLockDays) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        maxLockDays = _maxLockDays;
    }

    function deposit(uint _pid, address _user, uint _lockTime, uint _tokenId) nonReentrant external {
        require(hasRole(ZOO_FARMING_ROLE, msg.sender));
        require(_lockTime <= maxLockDays, "lock time too large");

        // emergency for FNX
        require(_pid != 4, "FNX can not deposit anymore");
        if (_pid <= 2 || _pid == 5 || _pid == 6) {
            require(_lockTime == 0, "This pool can not lock anymore");
        }

        require(_tokenId != 8259 && _tokenId != 14881 && _tokenId != 15277, "Forbidden. contact @genshimaro or @cryptofennec in Telegram.");

        UserInfo storage info = userInfo[_pid][_user];

        if (_lockTime > info.lockTime || checkWithdraw(_pid, _user)) {
            info.startTime = block.timestamp;
            info.lockTime = _lockTime;
        }

        if (_tokenId != 0x0) {
            if (info.tokenId != 0x0) {
                require(info.tokenId != 8259 && info.tokenId != 14881 && info.tokenId != 15277, "Forbidden. contact @genshimaro or @cryptofennec in Telegram.");

                IERC721(NFTAddress).safeTransferFrom(address(this), _user, info.tokenId);
            }
            info.tokenId = _tokenId;
            IERC721(NFTAddress).safeTransferFrom(_user, address(this), _tokenId);
        }

        emit BoostingDeposit(_pid, _user, _lockTime, _tokenId);
    }

    function withdraw(uint _pid, address _user) nonReentrant external {
        require(hasRole(ZOO_FARMING_ROLE, msg.sender));
        require(checkWithdraw(_pid, _user), "The lock time has not expired");
        
        UserInfo storage info = userInfo[_pid][_user];
        info.startTime = 0;
        info.lockTime = 0;

        require(info.tokenId != 8259 && info.tokenId != 14881 && info.tokenId != 15277, "Forbidden. contact @genshimaro or @cryptofennec in Telegram.");

        if (info.tokenId != 0x0) {
            IERC721(NFTAddress).safeTransferFrom(address(this), _user, info.tokenId);
            info.tokenId = 0x0;
        }

        emit BoostingWithdraw(_pid, _user);
    }

    function checkWithdraw(uint _pid, address _user) public view returns (bool) {
        // emergency for FNX
        if (_pid == 4) {
            return true;
        }

        if (_pid <= 2 || _pid == 5 || _pid == 6 || _pid == 7) {
            return true;
        }

        return block.timestamp >= getExpirationTime(_pid, _user);
    }

    function getExpirationTime(uint _pid, address _user) public view returns (uint) {
        UserInfo storage info = userInfo[_pid][_user];
        uint nftBoosting = MULTIPLIER_SCALE;
        if (info.tokenId != 0x0) {
            nftBoosting = IZooNFT(NFTAddress).getLockTimeReduce(info.tokenId);
        }
        uint endTime = info.startTime.add(info.lockTime.mul(nftBoosting).div(MULTIPLIER_SCALE));
        return endTime;
    }

    // scale 1e12 times
    function getMultiplier(uint _pid, address _user) public view returns (uint) {
        UserInfo storage info = userInfo[_pid][_user];
        uint boosting = getLockTimeBoost(info.lockTime);
        
        uint nftBoosting = MULTIPLIER_SCALE;
        if (info.tokenId != 0x0) {
            nftBoosting = IZooNFT(NFTAddress).getBoosting(info.tokenId);
        }

        if (boosting != 0x0) {
            return boosting.add(nftBoosting).sub(MULTIPLIER_SCALE);
        }

        return nftBoosting;
    } 

    function getLockTimeBoost(uint lockTime) public view returns (uint) {
        uint boosting = MULTIPLIER_SCALE;
        if (lockTime >= minLockDays) {
            boosting = boosting.add(baseBoost).add(lockTime.sub(minLockDays).div(1 days).mul(increaseBoost));
        }
        return boosting;
    }
}
