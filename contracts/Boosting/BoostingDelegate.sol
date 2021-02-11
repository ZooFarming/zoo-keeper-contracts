pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "./BoostingStorage.sol";

interface ZooNFT {
    // scaled 1e12
    function getBoosting(uint _tokenId) external view returns (uint);
}

contract TokenSwapDelegate is Initializable, AccessControl, ERC721Holder, BoostingStorage {

    bytes32 public constant ZOO_FARMING_ROLE = keccak256("FARMING_CONTRACT_ROLE");

    uint public constant MULTIPLIER_SCALE = 1e12;

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        scaleA = 3e13; // 30
        scaleB = 1e11; // 0.1
    }

    /// @dev Config the farming contract address
    function setFarmingAddr(address _farmingAddr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setupRole(ZOO_FARMING_ROLE, _farmingAddr);
    }

    function setNFTAddress(address _NFTAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        NFTAddress = _NFTAddress;
    }

    function setBoostScale(uint a, uint b) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        scaleA = a;
        scaleB = b;
    }

    function deposit(uint _pid, address _user, uint _lockTime, uint _tokenId) external {
        require(hasRole(ZOO_FARMING_ROLE, msg.sender));
        UserInfo storage info = userInfo[_pid][_user];
        info.startTime = block.timestamp;
        if (_lockTime > info.lockTime || block.timestamp > getExpirationTime(_pid, _user)) {
            info.lockTime = _lockTime;
        }

        if (_tokenId != 0x0) {
            if (info.tokenId != 0x0) {
                IERC721(NFTAddress).safeTransferFrom(address(this), _user, info.tokenId);
            }
            info.tokenId = _tokenId;
            IERC721(NFTAddress).safeTransferFrom(_user, address(this), _tokenId);
        }
    }

    function checkWithdraw(uint _pid, address _user) external view returns (bool) {
        return block.timestamp > getExpirationTime(_pid, _user);
    }

    function getExpirationTime(uint _pid, address _user) public view returns (uint) {
        UserInfo storage info = userInfo[_pid][_user];
        uint nftBoosting = 1e12;
        if (info.tokenId != 0x0) {
            nftBoosting = ZooNFT(NFTAddress).getBoosting(info.tokenId);
        }
        uint endTime = info.startTime + info.lockTime.div(nftBoosting).mul(1e12);
        return endTime;
    }

    // scale 1e12 times
    function getMultiplier(uint _pid, address _user) external view returns (uint) {
        UserInfo storage info = userInfo[_pid][_user];
        uint boosting = info.lockTime.div(1 days).mul(1e12).mul(scaleB).div(scaleA).add(1e12);
        if (boosting != 0 && info.tokenId != 0x0) {
            uint nftBoosting = ZooNFT(NFTAddress).getBoosting(info.tokenId);
            boosting = boosting.mul(nftBoosting).div(1e12);
        }
        return boosting;
    } 
}

