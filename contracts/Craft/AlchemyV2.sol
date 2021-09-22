// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./AlchemyV1.sol";

interface IRandomElixirName {
    function generateName(uint random) external view returns (string memory);
}

contract AlchemyV2 is AlchemyV1 {
    address public randomNameAddr;

    function setRandomNameAddr(address _randomNameAddr) external onlyAdmin {
        randomNameAddr = _randomNameAddr;
    }

    function buy() external {
        require(randomNameAddr != address(0), "random name contract not config");
        uint256 randomSeed = uint256(
            keccak256(
                abi.encode(msg.sender, blockhash(block.number - 30), "NAME_RANDOM_SEED")
            )
        );

        super.buy(IRandomElixirName(randomNameAddr).generateName(randomSeed));
    }
}