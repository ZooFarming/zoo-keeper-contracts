// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./ZooNFTStorage.sol";

// ZooNFT
contract ZooNFTDelegate is ERC721("ZooNFT", "ZooNFT"), Initializable, AccessControl, ZooNFTStorage {

    bytes32 public constant NFT_FACTORY_ROLE = keccak256("FARMING_CONTRACT_ROLE");

    uint public constant MULTIPLIER_SCALE = 1e12;

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(NFT_FACTORY_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function setNFTFactory(address _nftFactory) external {
        grantRole(NFT_FACTORY_ROLE, _nftFactory);
    }

    function setBaseURI(string memory _baseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setBaseURI(_baseURI);
    }

    function setNftURI(uint level, uint category, uint item, string memory URI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        nftURI[level][category][item] = URI;
    }

    function setMultiNftURI(uint[] memory levels, uint[] memory categorys, uint[] memory items, string[] memory URIs) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        for (uint i=0; i<levels.length; i++) {
            nftURI[levels[i]][categorys[i]][items[i]] = URIs[i];
        }
    }

    function getNftURI(uint level, uint category, uint item) public view returns (string memory) {
        return nftURI[level][category][item];
    }

    // Use for boosting calc: boosting = (level - 1) * a + category * b + item * c + random * d;
    // scale: 1e12
    function setScaleParams(uint _a, uint _b, uint _c, uint _d) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        scaleParams.a = _a;
        scaleParams.b = _b;
        scaleParams.c = _c;
        scaleParams.d = _d;
    }

    // Use for get boosting: boosting = (level - 1) * a + category * b + item * c + random * d;
    // scale: 1e12
    function getBoosting(uint _tokenId) external view returns (uint) {
        if (tokenInfo[_tokenId].level == 0) {
            return MULTIPLIER_SCALE;
        }
        return MULTIPLIER_SCALE.add(tokenInfo[_tokenId].level.sub(1).mul(scaleParams.a).add(tokenInfo[_tokenId].category.mul(scaleParams.b).add(tokenInfo[_tokenId].item.mul(scaleParams.c).add(tokenInfo[_tokenId].random.mul(scaleParams.d)))));
    }
    
    function mint(uint tokenId, uint _level, uint _category, uint _item, uint _random) external {
        require(hasRole(NFT_FACTORY_ROLE, msg.sender));
        _safeMint(msg.sender, tokenId);
        require(_level > 0 && _level < 5, "level must larger than 0, lesser than 5");
        tokenInfo[tokenId].level = _level;
        tokenInfo[tokenId].category = _category;
        tokenInfo[tokenId].item = _item;
        tokenInfo[tokenId].random = _random;
        _setTokenURI(tokenId, nftURI[_level][_category][_item]);
    }
}
