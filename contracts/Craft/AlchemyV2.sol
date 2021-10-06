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

    function getTransferFee(uint tokenId) public view returns (uint) {
        uint price = getElixirPrice();
        uint level = elixirInfoMap[tokenId].level;
        // price * 0.1 + price * 0.1 * level / 10
        return price.div(10).add(price.div(10).mul(level).div(10));
    }

    function transferElixir(uint tokenId, address to) external {
        uint fee = getTransferFee(tokenId);

        IERC20(buyToken).safeTransferFrom(
            msg.sender,
            address(this),
            fee
        );
        IBurnToken(buyToken).burn(fee);

        IERC721(elixirNFT).safeTransferFrom(
            msg.sender,
            to,
            tokenId
        );
    }
}
