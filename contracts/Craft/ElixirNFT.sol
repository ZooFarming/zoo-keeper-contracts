// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

// ElixirNFT
contract ElixirNFT is
    ERC721Burnable("ElixirNFT", "ElixirNFT"),
    Initializable,
    AccessControl
{
    bytes32 public constant NFT_FACTORY_ROLE =
        keccak256("FARMING_CONTRACT_ROLE");

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function setNFTFactory(address _nftFactory) external {
        grantRole(NFT_FACTORY_ROLE, _nftFactory);
    }

    function mint(tokenId) external {
        require(hasRole(NFT_FACTORY_ROLE, msg.sender));
        _safeMint(msg.sender, tokenId);
    }
}
