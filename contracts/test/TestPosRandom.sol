// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract TestPosRandom {
  function getRandomNumberByEpochId(uint256 epochId) external view returns(uint256) {
    uint random = uint(keccak256(abi.encode(epochId)));
    return random;
  }
}
