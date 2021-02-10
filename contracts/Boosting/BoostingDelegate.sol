pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./BoostingStorage.sol";

contract TokenSwapDelegate is Initializable, AccessControl, BoostingStorage {

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

    function deposit(uint pid, address user, uint lockTime, uint tokenId) external {
        require(hasRole(ZOO_FARMING_ROLE, msg.sender));

    }

    function checkWithdraw(uint pid, address user) external view returns (bool);

    function getMultiplier(uint pid, address user) external view returns (uint); // zoom in 1e12 times;
}

