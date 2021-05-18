// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICallback {
  function inputSeed(uint _seed) external;
}

contract TestOracle {
  function inputSeed(uint _seed) external {
    uint random = uint(keccak256(abi.encode(_seed)));
    ICallback(msg.sender).inputSeed(random);
  }
}

