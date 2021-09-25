// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IBurnToken.sol";
import "../RandomBeacon/RandomBase.sol";

interface IElixirNFT {
    function mint(uint256 tokenId, uint256 tokenType) external;

    // function burn(uint256 tokenId) external;
}

interface ICraftNFT {
    // scaled 1e12
    // function getBoosting(uint256 _tokenId) external view returns (uint256);

    struct TokenInfo {
        uint256 level;
        uint256 category;
        uint256 item;
        uint256 random;
    }

    // tokenId => tokenInfo
    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (TokenInfo memory);
    
    function mint(uint tokenId, uint _level, uint _category, uint _item, uint _random) external;
    function totalSupply() external view returns (uint);
}

interface IGoldenOracle {
    function queryGoldenPrice() external view returns (uint256);
}

contract AlchemyV1 is
    Initializable,
    AccessControl,
    ERC721Holder,
    RandomBase
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public baseRatePerBlock; // drops per block

    address public elixirNFT;

    uint256 public totalMint;

    uint256 public totalBurn;

    uint256 public priceFactor0;

    uint256 public priceFactor1;

    uint256 public maxBoosting;

    uint256 public maxStakeZoo;

    uint256 public dropCostPerLevel;

    address public priceOracle;

    address public buyToken;

    address public zooNFT;

    struct ElixirInfo {
        uint256 level; // current level
        uint256 drops; // current drops in bottle
        uint256 color; // color of the elixir
        uint256 shape; // shape of the elixir
        string name; // name of the elixir
    }

    struct UserInfo {
        uint256 amount;
        uint256 lastRewardBlock; // Last block number that drops distribution occurs.
    }

    struct CraftInfo {
        uint256 elixirId;
        uint256 tokenId0;
        uint256 tokenId1;
    }

    // tokenId => ElixirInfo
    mapping(uint256 => ElixirInfo) public elixirInfoMap;

    // user => tokenId
    mapping(address => uint256) public userElixirMap;

    // user => UserInfo
    mapping(address => UserInfo) public userInfoMap;

    // user => CraftInfo
    mapping(address => CraftInfo) public pendingCraft;

    uint256 public elixirBaseScore;

    uint256 public constant BOOST_SCALE = 1e12;

    uint256 public constant ELIXIR_SHAPES = 34;

    uint256 public constant FULL_DROPS = 100 ether;

    event MintElixir(
        uint256 indexed tokenId,
        string name,
        uint256 color,
        uint256 shape
    );

    event DepositElixir(address indexed user, uint256 indexed tokenId);

    event DepositZoo(address indexed user, uint256 amount);

    event UpgradeElixir(
        address indexed user,
        uint256 indexed levelFrom,
        uint256 indexed levelTo
    );

    event WithdrawElixir(address indexed user, uint256 indexed tokenId);

    event WithdrawZoo(address indexed user, uint256 amount);

    event BurnNFT(uint256 indexed tokenId, address indexed nftToken);

    event RequestCraft(address indexed user, uint256 elixirId, uint256 tokenId0, uint tokenId1);

    event CraftDone(address indexed user, uint256 elixirId, uint256 tokenId0, uint tokenId1, uint newTokenId, uint newLevel, uint newCategory, uint newItem);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin");
        _;
    }

    function initialize(
        address admin,
        address _elixirNFT,
        address _buyToken,
        address _priceOracle,
        address _zooNFT,
        address randomOracle_
    ) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        initRandomOracle(randomOracle_);

        baseRatePerBlock = 165343915343915; // 20 DROPs per week for each user = 20e18 / 7 / 24 / 3600 * 5
        priceOracle = _priceOracle;
        buyToken = _buyToken;
        elixirNFT = _elixirNFT;
        zooNFT = _zooNFT;
        priceFactor0 = 1;
        priceFactor1 = 100; //1%

        maxBoosting = 200 * BOOST_SCALE;
        maxStakeZoo = 1000000 ether;

        dropCostPerLevel = 30 ether;
    }

    function configDropRate(uint256 _dropRate) external onlyAdmin {
        baseRatePerBlock = _dropRate;
    }

    function configPriceFactor(uint256 _factor0, uint256 _factor1) external onlyAdmin {
        priceFactor0 = _factor0;
        priceFactor1 = _factor1;
    }

    function getElixirPrice() public view returns (uint256) {
        // get golden price from NFTFactory
        uint256 goldenPrice = IGoldenOracle(priceOracle).queryGoldenPrice();
        return goldenPrice.mul(priceFactor0).div(priceFactor1);
    }

    function maxPendingDrops(address user, uint256 dropReward)
        internal
        view
        returns (uint256)
    {
        if (userElixirMap[user] == 0) {
            return 0;
        }

        ElixirInfo storage info = elixirInfoMap[userElixirMap[user]];
        if (info.drops + dropReward <= FULL_DROPS) {
            return dropReward;
        }

        return FULL_DROPS - info.drops;
    }

    // scaled 1e12
    function getUserBoosting(address _user) public view returns (uint256) {
        UserInfo storage user = userInfoMap[_user];
        uint staked = user.amount;
        if (staked > maxStakeZoo) {
            staked = maxStakeZoo;
        }

        uint extra = staked.mul(maxBoosting).div(maxStakeZoo);

        return BOOST_SCALE.add(extra);
    }

    function pendingDrops(address _user) public view returns (uint256) {
        UserInfo storage user = userInfoMap[_user];
        if (block.number > user.lastRewardBlock) {
            uint256 multiplier = getMultiplier(
                user.lastRewardBlock,
                block.number
            );
            uint256 boost = getUserBoosting(_user);
            uint256 dropReward = multiplier
                .mul(baseRatePerBlock)
                .mul(boost)
                .div(BOOST_SCALE);

            return maxPendingDrops(_user, dropReward);
        }
        return 0;
    }

    function updateDrops(address _user) internal {
        uint256 pending = pendingDrops(_user);
        uint256 tokenId = userElixirMap[_user];
        if (tokenId != 0) {
            ElixirInfo storage info = elixirInfoMap[tokenId];
            info.drops = info.drops.add(pending);
            if (info.drops > FULL_DROPS) {
                info.drops = FULL_DROPS;
            }
        }

        UserInfo storage user = userInfoMap[_user];
        user.lastRewardBlock = block.number;
    }

    function buy(string memory customName) internal {
        require(bytes(customName).length <= 128, "name too long");
        require(bytes(customName).length > 0, "name too short");

        IERC20(buyToken).safeTransferFrom(
            msg.sender,
            address(this),
            getElixirPrice()
        );
        IBurnToken(buyToken).burn(getElixirPrice());
        totalMint = totalMint.add(1);

        uint256 randomSeed = uint256(
            keccak256(
                abi.encode(msg.sender, blockhash(block.number - 30), totalMint)
            )
        );

        uint256 tokenShape = randomSeed.mod(ELIXIR_SHAPES);
        IElixirNFT(elixirNFT).mint(totalMint, tokenShape);
        IERC721(elixirNFT).safeTransferFrom(
            address(this),
            msg.sender,
            totalMint
        );

        uint256 color = randomSeed.mod(0x1000000);
        elixirInfoMap[totalMint].level = 1;
        elixirInfoMap[totalMint].name = customName;
        elixirInfoMap[totalMint].color = color;
        elixirInfoMap[totalMint].shape = tokenShape;

        emit MintElixir(totalMint, customName, color, tokenShape);
    }

    function depositElixir(uint256 tokenId) public {
        require(userElixirMap[msg.sender] == 0, "already exist one Elixir");

        IERC721(elixirNFT).safeTransferFrom(msg.sender, address(this), tokenId);

        userElixirMap[msg.sender] = tokenId;
        UserInfo storage user = userInfoMap[msg.sender];
        user.lastRewardBlock = block.number;

        emit DepositElixir(msg.sender, tokenId);
    }

    function depositZoo(uint256 amount) public {
        require(userElixirMap[msg.sender] != 0, "no Elixir");
        updateDrops(msg.sender);

        IERC20(buyToken).safeTransferFrom(msg.sender, address(this), amount);
        UserInfo storage user = userInfoMap[msg.sender];
        user.amount = user.amount.add(amount);

        emit DepositZoo(msg.sender, amount);
    }

    function depositElixirAndZoo(uint256 tokenId, uint256 zooAmount) external {
        depositElixir(tokenId);
        depositZoo(zooAmount);
    }

    function upgradeElixir() external {
        require(userElixirMap[msg.sender] != 0, "no Elixir");
        updateDrops(msg.sender);
        uint256 tokenId = userElixirMap[msg.sender];
        ElixirInfo storage info = elixirInfoMap[tokenId];
        require(info.drops == FULL_DROPS, "Elixir not fullfill");
        require(info.level < 5, "Already Level max");
        info.level = info.level.add(1);
        info.drops = 0;
        emit UpgradeElixir(msg.sender, info.level - 1, info.level);
    }

    function withdrawElixir() public {
        require(userElixirMap[msg.sender] != 0, "no Elixir");
        updateDrops(msg.sender);
        uint256 tokenId = userElixirMap[msg.sender];
        userElixirMap[msg.sender] = 0;
        IERC721(elixirNFT).safeTransferFrom(address(this), msg.sender, tokenId);
        emit WithdrawElixir(msg.sender, tokenId);
    }

    function withdrawZoo() public {
        UserInfo storage user = userInfoMap[msg.sender];
        require(user.amount > 0, "No zoo to withdraw");
        updateDrops(msg.sender);
        uint256 amount = user.amount;
        user.amount = 0;
        IERC20(buyToken).safeTransfer(msg.sender, amount);
        emit WithdrawZoo(msg.sender, amount);
    }

    function withdrawElixirAndZoo() external {
        if (userElixirMap[msg.sender] != 0) {
            withdrawElixir();
        }
        
        UserInfo storage user = userInfoMap[msg.sender];
        if (user.amount > 0) {
            withdrawZoo();
        }
    }

    function nftCraft(
        uint256 elixirId,
        uint256 tokenId0,
        uint256 tokenId1
    ) external {
        // check NFT
        IERC721(zooNFT).safeTransferFrom(msg.sender, address(this), tokenId0);
        IERC721(zooNFT).safeTransferFrom(msg.sender, address(this), tokenId1);
        IERC721(elixirNFT).safeTransferFrom(msg.sender, address(this), elixirId);
        // check elixir
        updateDrops(msg.sender);

        bool can;
        (can,,) = getCraftProbability(elixirId, tokenId0, tokenId1, msg.sender);
        require(can, "can not craft NFT");


        pendingCraft[msg.sender].elixirId = elixirId;
        pendingCraft[msg.sender].tokenId0 = tokenId0;
        pendingCraft[msg.sender].tokenId1 = tokenId1;
        requestRandom(address(this), uint(msg.sender));
        emit RequestCraft(msg.sender, elixirId, tokenId0, tokenId1);
    }

    function burnZooNft(uint256 tokenId) internal {
        IERC721(zooNFT).safeTransferFrom(address(this), address(0x0f), tokenId);
        emit BurnNFT(tokenId, zooNFT);
    }

    function getCraftProbability(uint elixirId, uint nftId0, uint nftId1, address _user) public view returns (bool can, uint score0, uint score1) {
        ElixirInfo storage info = elixirInfoMap[elixirId];
        if (bytes(info.name).length == 0 || elixirId == 0 || nftId0 == 0 || nftId1 == 0 || nftId0 == nftId1) {
            return (false, 0, 1);
        }

        ICraftNFT.TokenInfo memory t0 = ICraftNFT(zooNFT).tokenInfo(nftId0);
        ICraftNFT.TokenInfo memory t1 = ICraftNFT(zooNFT).tokenInfo(nftId1);
        if (info.level < t0.item || info.level < t1.item || t0.level != t1.level || t0.level >= 4) {
            return (false, 1, info.level*10+t0.level);
        }

        uint drops = info.drops + pendingDrops(_user);
        uint need = 10 ether + dropCostPerLevel.mul(t0.level);
        if (need > drops) {
            return (false, 2, need);
        }

        return getLevelProbability(t0.level, t0.category, t0.item, t1.level, t1.category, t1.item);
    }

    function useDrops(uint elixirId, uint tokenId) internal {
        ElixirInfo storage info = elixirInfoMap[elixirId];
        ICraftNFT.TokenInfo memory t0 = ICraftNFT(zooNFT).tokenInfo(tokenId);
        uint need = 10 ether + dropCostPerLevel.mul(t0.level);
        info.drops = info.drops.sub(need);
    }

    function getLevelProbability(uint level0, uint category0, uint class0, uint level1, uint category1, uint class1) internal pure returns (bool can, uint score0, uint score1) {
        if (level0 != level1) {
            return (false, 3, 0);
        }
        can = true;
        score0 = level0**2 * 100 + category0**2*200 + class0**2*200;
        score1 = level1**2 * 100 + category1**2*200 + class1**2*200;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        internal
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    function randomCallback(uint256 _id, uint256 _randomSeed) external override onlyRandomOracle {
        address user = address(_id);
        CraftInfo storage ci = pendingCraft[user];
        require(ci.elixirId != 0 && ci.tokenId0 != 0 && ci.tokenId1 != 0, "user not found");

        updateDrops(user);

        bool can;
        uint score0;
        uint score1;
        (can, score0, score1) = getCraftProbability(ci.elixirId, ci.tokenId0, ci.tokenId1, user);
        require(can, "can not craft NFT");

        useDrops(ci.elixirId, ci.tokenId0);

        uint random = uint(keccak256(abi.encode(_randomSeed)));
        random = random.mod(score0.add(score1));

        ICraftNFT.TokenInfo memory t0 = ICraftNFT(zooNFT).tokenInfo(ci.tokenId0);
        ICraftNFT.TokenInfo memory t1 = ICraftNFT(zooNFT).tokenInfo(ci.tokenId1);

        uint level = t0.level + 1;
        uint category;
        uint item;
        
        if (random < score0) {
            category = t1.category;
            item = t1.item;
        } else {
            category = t0.category;
            item = t0.item;
        }

        uint totalSupply = ICraftNFT(zooNFT).totalSupply();
        totalSupply = totalSupply + 1;

        burnZooNft(ci.tokenId0);
        burnZooNft(ci.tokenId1);

        ICraftNFT(zooNFT).mint(totalSupply, level, category, item, random.mod(300));
        IERC721(zooNFT).safeTransferFrom(address(this), user, totalSupply);
        IERC721(elixirNFT).safeTransferFrom(address(this), user, ci.elixirId);

        // finish clear
        delete pendingCraft[user];

        emit CraftDone(user, ci.elixirId, ci.tokenId0, ci.tokenId1, totalSupply, level, category, item);
    }
}
