// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./NFTFactoryStorage.sol";

contract NFTFactoryStorageV2 is NFTFactoryStorage {
    uint internal _foundationSeed;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
}

