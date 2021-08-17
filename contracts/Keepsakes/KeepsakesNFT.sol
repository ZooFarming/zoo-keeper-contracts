// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

// KeepsakeNFT
contract KeepsakesNFT is ERC721Burnable, Initializable, AccessControl {
    bytes32 public constant NFT_FACTORY_ROLE =
        keccak256("FARMING_CONTRACT_ROLE");

    mapping(uint => address) public nftCreator;

    mapping(address => uint) public creatorSupply;

    constructor() public ERC721("ZooKeeper Keepsakes NFT", "KEEPSAKES") {}

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function setNFTFactory(address _nftFactory) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(NFT_FACTORY_ROLE, _nftFactory);
    }

    function mint(uint256 tokenId, string calldata uri, address _creator) external {
        require(hasRole(NFT_FACTORY_ROLE, msg.sender));
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        nftCreator[tokenId] = _creator;
        creatorSupply[_creator] = creatorSupply[_creator] + 1;
    }

    function setNftURI(uint256 tokenId, string calldata uri) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setTokenURI(tokenId, uri);
    }

    function setBaseURI(string calldata baseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setBaseURI(baseURI);
    }
}
