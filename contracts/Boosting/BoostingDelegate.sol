pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "./BoostingStorage.sol";

contract TokenSwapDelegate is Initializable, AccessControl, ERC721Holder, BoostingStorage {

    bytes32 public constant ZOO_FARMING_ROLE = keccak256("FARMING_CONTRACT_ROLE");

    uint public constant MULTIPLIER_SCALE = 1e12;

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
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

    function deposit(uint _pid, address _user, uint _lockTime, uint _tokenId) external {
        require(hasRole(ZOO_FARMING_ROLE, msg.sender));
        UserInfo storage info = userInfo[_pid][_user];
        info.startTime = block.timestamp;
        info.lockTime = _lockTime;
        info.tokenId = _tokenId;
        IERC721(NFTAddress).safeTransferFrom(_user, address(this), _tokenId);
    }

    function checkWithdraw(uint pid, address user) external view returns (bool) {
        return false;
    }

    // zoom in 1e12 times;
    function getMultiplier(uint pid, address user) external view returns (uint) {
        return 1e12;
    } 
}

