// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./NFTFactoryStorageV2.sol";

contract NFTFactoryStorageV3 is NFTFactoryStorageV2 {
    struct MintRequestInfo {
        address user;
        uint price;
        bool golden;
    }

    // request index => request info
    mapping(uint => MintRequestInfo) mintRequestInfo;

    uint public currentRequestCount;

    uint public doneRequestCount;
}

