// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

// ZooNFT
contract ZooNFT is
    ERC721("ZooNFT", "ZooNFT"),
    Initializable,
    AccessControl
{
    using SafeMath for uint256;

    struct TokenInfo {
        uint256 level;
        uint256 category;
        uint256 item;
        uint256 random;
    }

    // tokenId => tokenInfo
    mapping(uint => TokenInfo) public tokenInfo;

    // level => category => item => tokenURI
    mapping(uint => mapping(uint => mapping(uint => string))) public nftURI;

    // chance scaled 1e12
    // level => chance
    mapping(uint => uint) public LEVEL_CHANCE;         // 60%, 30%, 5%, 1%

    mapping(uint => uint) public CATEGORY_CHANCE;      // 40%, 33%, 17%, 7%, 2%, 1%

    mapping(uint => uint) public ITEM_CHANCE;          // 35%, 30%, 20%, 10%, 5%

    // chance => boost
    mapping(uint => uint) public boostMap;

    // chance => lockTime reduce
    mapping(uint => uint) public reduceMap;

    // NFT item's total supply
    mapping(uint => mapping(uint => mapping(uint => uint))) public itemSupply;

    bytes32 public constant NFT_FACTORY_ROLE =
        keccak256("FARMING_CONTRACT_ROLE");

    uint256 public constant MULTIPLIER_SCALE = 1e12;

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(NFT_FACTORY_ROLE, DEFAULT_ADMIN_ROLE);

        // 60%, 30%, 5%, 1%
        LEVEL_CHANCE[0] = 6e11;
        LEVEL_CHANCE[1] = 3e11;
        LEVEL_CHANCE[2] = 5e10;
        LEVEL_CHANCE[3] = 1e10;

        // 40%, 33%, 17%, 7%, 2%, 1%
        CATEGORY_CHANCE[0] = 4e11;
        CATEGORY_CHANCE[1] = 33e10;
        CATEGORY_CHANCE[2] = 17e10;
        CATEGORY_CHANCE[3] = 7e10;
        CATEGORY_CHANCE[4] = 2e10;
        CATEGORY_CHANCE[5] = 1e10;

        // 35%, 30%, 20%, 10%, 5%
        ITEM_CHANCE[0] = 35e10;
        ITEM_CHANCE[1] = 3e11;
        ITEM_CHANCE[2] = 2e11;
        ITEM_CHANCE[3] = 1e11;
        ITEM_CHANCE[4] = 5e10;
    }

    function setNFTFactory(address _nftFactory) external {
        grantRole(NFT_FACTORY_ROLE, _nftFactory);
    }

    function setBaseURI(string memory _baseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setBaseURI(_baseURI);
    }

    function setNftURI(
        uint256 level,
        uint256 category,
        uint256 item,
        string memory URI
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        nftURI[level][category][item] = URI;
    }

    function setMultiNftURI(
        uint256[] memory levels,
        uint256[] memory categorys,
        uint256[] memory items,
        string[] memory URIs
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        for (uint256 i = 0; i < levels.length; i++) {
            nftURI[levels[i]][categorys[i]][items[i]] = URIs[i];
        }
    }

    function getNftURI(
        uint256 level,
        uint256 category,
        uint256 item
    ) public view returns (string memory) {
        return nftURI[level][category][item];
    }

    function setBoostMap(
        uint256[] memory chances,
        uint256[] memory boosts,
        uint256[] memory reduces
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        for (uint256 i = 0; i < chances.length; i++) {
            boostMap[chances[i]] = boosts[i];
            reduceMap[chances[i]] = reduces[i];
        }
    }

    // Use for get boosting
    // scale: 1e12
    function getBoosting(uint256 _tokenId) external view returns (uint256) {
        uint256 chance = getTokenChance(_tokenId);
        uint256 boosting = boostMap[chance];
        uint256 random = tokenInfo[_tokenId].random;
        uint256 base = MULTIPLIER_SCALE;
        return base.add(boosting).add(random.mul(1e7));
    }

    function getLockTimeReduce(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        uint256 chance = getTokenChance(_tokenId);
        uint256 reduce = reduceMap[chance];
        uint256 random = tokenInfo[_tokenId].random;
        uint256 base = MULTIPLIER_SCALE;
        return base.sub(reduce).sub(random.mul(1e7));
    }

    function mint(
        uint256 tokenId,
        uint256 _level,
        uint256 _category,
        uint256 _item,
        uint256 _random
    ) external {
        require(hasRole(NFT_FACTORY_ROLE, msg.sender));
        _safeMint(msg.sender, tokenId);
        require(
            _level > 0 && _level < 5,
            "level must larger than 0, lesser than 5"
        );
        tokenInfo[tokenId].level = _level;
        tokenInfo[tokenId].category = _category;
        tokenInfo[tokenId].item = _item;
        tokenInfo[tokenId].random = _random;
        _setTokenURI(tokenId, nftURI[_level][_category][_item]);
        itemSupply[_level][_category][_item]++;
    }

    function getTokenChance(uint256 tokenId)
        public
        view
        returns (uint256 chance)
    {
        return
            getLevelChance(
                tokenInfo[tokenId].level,
                tokenInfo[tokenId].category,
                tokenInfo[tokenId].item
            );
    }

    function getLevelChance(
        uint256 level,
        uint256 category,
        uint256 item
    ) public view returns (uint256 chance) {
        if (level == 0 || category == 0 || item == 0) {
            return 0;
        }
        return
            LEVEL_CHANCE[level - 1]
                .mul(CATEGORY_CHANCE[category - 1]).div(1e12)
                .mul(ITEM_CHANCE[item - 1]).div(1e12);
    }
}
