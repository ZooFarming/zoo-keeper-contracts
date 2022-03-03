// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./AlchemyV2.sol";

contract AlchemyV3 is AlchemyV2 {
    bytes32 public constant CROSS_CHAIN_ROLE = keccak256("CROSS_CHAIN_ROLE");

    modifier onlyCrossChain() {
        require(hasRole(CROSS_CHAIN_ROLE, msg.sender), "only crosschain");
        _;
    }

    function crossMint(
        uint256 _level, 
        uint256 _drops, 
        uint256 _color,
        uint256 _shape,
        string calldata _name
    ) external onlyCrossChain {
        totalMint = totalMint.add(1);
        IElixirNFT(elixirNFT).mint(totalMint, _shape);

        IERC721(elixirNFT).safeTransferFrom(
            address(this),
            msg.sender,
            totalMint
        );

        elixirInfoMap[totalMint].level = _level;
        elixirInfoMap[totalMint].drops = _drops;
        elixirInfoMap[totalMint].color = _color;
        elixirInfoMap[totalMint].shape = _shape;
        elixirInfoMap[totalMint].name = _name;

        emit MintElixir(totalMint, _name, _color, _shape);
    }
}