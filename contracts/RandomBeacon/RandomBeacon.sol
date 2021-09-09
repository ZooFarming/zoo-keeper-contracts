// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./RandomBase.sol";



contract RandomBeacon is AccessControl, Initializable, IRandomOracle {
    bytes32 private constant OPERATOR_ROLE =
        keccak256("random.oracle.operator");

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "only operator");
        _;
    }

    event RequestRandom(address indexed user, uint256 indexed id);

    function initialize(
        address admin,
        address operator
    ) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(OPERATOR_ROLE, operator);
    }

    function requestRandom(address _callback, uint256 _id) external override {
        emit RequestRandom(_callback, _id);
    }

    function sendSeed(address _user, uint256 _id, uint256 _randomSeed) external onlyOperator {
        RandomBase(_user).randomCallback(_id, _randomSeed);
    }
}
