// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./NFTFactoryStorageV3.sol";

contract NFTFactoryStorageV4 is NFTFactoryStorageV3 {
    struct MintRequestInfoV2 {
        address user;
        uint price;
        uint chestType; // 0: buy silver, 1: buy golden, 2: zoo claim, 4: zoorena silver, 5: zoorena golden
    }

    // request index => request info
    mapping(uint => MintRequestInfoV2) mintRequestInfoV2;

    bytes32 public constant FACTORY_MINTER_ROLE = keccak256("FACTORY_MINTER_ROLE");
}

