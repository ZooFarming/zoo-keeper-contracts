// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

// ElixirNFT
contract ElixirNFT is ERC721Burnable, Initializable, AccessControl {
    // tokenType => URI
    mapping(uint256 => string) public nftURI;

    bytes32 public constant NFT_FACTORY_ROLE =
        keccak256("FARMING_CONTRACT_ROLE");

    constructor() public ERC721("ElixirNFT", "ElixirNFT") {}

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function setNFTFactory(address _nftFactory) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(NFT_FACTORY_ROLE, _nftFactory);
    }

    // tokenType: ELIXIR_SHAPES total 30
    function mint(uint256 tokenId, uint256 tokenType) external {
        require(hasRole(NFT_FACTORY_ROLE, msg.sender));
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, nftURI[tokenType]);
    }

    function setNftURI(uint256 tokenId, string calldata uri) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setTokenURI(tokenId, uri);
    }

    function setBaseURI(string calldata baseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setBaseURI(baseURI);
    }

    function getNftURI(uint256 tokenType) public view returns (string memory) {
        return nftURI[tokenType];
    }

    function setMultiNftURI(
        uint256[] calldata tokenTypes,
        string[] calldata URIs
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            nftURI[tokenTypes[i]] = URIs[i];
        }
    }
}
