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

    function setBoostMap(uint[] memory chances, uint[] memory boosts, uint[] memory reduces) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        for (uint i=0; i<chances.length; i++) {
            boostMap[chances[i]] = boosts[i];
            reduceMap[chances[i]] = reduces[i];
        }
    }

    // Use for get boosting
    // scale: 1e12
    function getBoosting(uint _tokenId) external view returns (uint) {
        uint chance = getTokenChance(_tokenId);
        uint boosting = boostMap[chance];
        uint random = tokenInfo[_tokenId].random;
        uint base = MULTIPLIER_SCALE;
        return base.add(boosting).add(random.mul(1e7));
    }

    function getLockTimeReduce(uint _tokenId) external view returns (uint) {
        uint chance = getTokenChance(_tokenId);
        uint reduce = reduceMap[chance];
        uint random = tokenInfo[_tokenId].random;
        uint base = MULTIPLIER_SCALE;
        return base.sub(reduce).sub(random.mul(1e7));
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

    function getTokenChance(uint tokenId) public view returns (uint chance) {
        return getLevelChance(tokenInfo[tokenId].level, tokenInfo[tokenId].category, tokenInfo[tokenId].item);
    }

    function getLevelChance(uint level, uint category, uint item) public view returns (uint chance) {
        if (level == 0 || category == 0 || item == 0) {
            return 0;
        }
        return LEVEL_CHANCE[level - 1].mul(CATEGORY_CHANCE[category - 1]).mul(ITEM_CHANCE[item - 1]).div(1e12).div(1e12);
    }
}
