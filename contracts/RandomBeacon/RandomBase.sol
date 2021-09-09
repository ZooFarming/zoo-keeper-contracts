// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRandomOracle {
    function requestRandom(address _callback, uint256 _id) external;
}

contract RandomBase {
    bytes32 private constant RANDOM_ORACLE_SLOT =
        keccak256("random.oracle.wanchain");

    modifier onlyRandomOracle() {
        require(msg.sender == _randomOracle(), "only random oracle");
        _;
    }

    function initRandomOracle(address _newOracle) internal {
        _setRandomOracle(_newOracle);
    }

    function requestRandom(address _callback, uint256 _id) internal {
        IRandomOracle(_randomOracle()).requestRandom(_callback, _id);
    }

    /**
     * @dev Override this function to use the callback execute
     */
    function randomCallback(uint256 /* _id */, uint256 /* _randomSeed */) external virtual onlyRandomOracle {}

    /**
     * @dev Returns the current oracle address.
     */
    function _randomOracle() private view returns (address oracle) {
        bytes32 slot = RANDOM_ORACLE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            oracle := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the slot.
     */
    function _setRandomOracle(address newOracle) private {
        bytes32 slot = RANDOM_ORACLE_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newOracle)
        }
    }
}
