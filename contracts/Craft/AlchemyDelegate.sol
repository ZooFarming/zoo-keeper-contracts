// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IBurnToken.sol";

import "./AlchemyStorage.sol";

interface IElixirNFT {
    function mint(uint256 tokenId, uint256 tokenType) external;

    function burn(uint256 tokenId) external;
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
}

interface IGoldenOracle {
    function queryGoldenPrice() external view returns (uint256);
}

contract AlchemyDelegate is
    Initializable,
    AccessControl,
    ERC721Holder,
    AlchemyStorage
{
    using SafeERC20 for IERC20;

    uint256 public constant BOOST_SCALE = 1e12;

    uint256 public constant ELIXIR_SHAPES = 30;

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

    function initialize(
        address admin,
        address _elixirNFT,
        address _buyToken,
        address _priceOracle,
        address _zooNFT
    ) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        baseRatePerBlock = 165343915343915; // 20 DROPs per week for each user = 20e18 / 7 / 24 / 3600 * 5
        priceOracle = _priceOracle;
        buyToken = _buyToken;
        elixirNFT = _elixirNFT;
        zooNFT = _zooNFT;
        priceFactor0 = 1;
        priceFactor1 = 100; //1%
    }

    function configDropRate(uint256 _dropRate) external {
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseRatePerBlock = _dropRate;
    }

    function configPriceFactor(uint256 _factor0, uint256 _factor1) external {
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        priceFactor0 = _factor0;
        priceFactor1 = _factor1;
    }

    function getElixirPrice() public view returns (uint256) {
        uint256 goldenPrice = IGoldenOracle(priceOracle).queryGoldenPrice();
        return goldenPrice.mul(priceFactor0).div(priceFactor1);
    }

    function maxPendingDrops(address user, uint256 dropReward)
        public
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
    function getUserBoosting(address user) public view returns (uint256) {
        return BOOST_SCALE;
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

    function updateDrops(address _user) public {
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

    function buy(string calldata customName) external {
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

    function withdrawElixir() external {
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
        IERC20(buyToken).safeTransferFrom(address(this), msg.sender, amount);
        emit WithdrawZoo(msg.sender, amount);
    }

    function nftCraft(
        uint256 elixirId,
        uint256 tokenId0,
        uint256 tokenId1
    ) external {}

    function burnZooNft(uint256 tokenId) internal {
        IERC721(zooNFT).safeTransferFrom(msg.sender, address(0x0f), tokenId);
        emit BurnNFT(tokenId, zooNFT);
    }

    function getCraftProbability(uint elixirId, uint nftId0, uint nftId1) public view returns (bool can, uint score0, uint score1) {
        ElixirInfo storage info = elixirInfoMap[elixirId];
        if (bytes(info.name).length == 0 || elixirId == 0 || nftId0 == 0 || nftId1 == 0) {
            return (false, 0, 0);
        }

        ICraftNFT.TokenInfo memory t0 = ICraftNFT(zooNFT).tokenInfo(nftId0);
        ICraftNFT.TokenInfo memory t1 = ICraftNFT(zooNFT).tokenInfo(nftId1);
        if (info.level < t0.level || info.level < t1.level) {
            return (false, 0, 0);
        }

        // TODO: CHECK DROPS count

        return getLevelProbability(t0.level, t0.category, t0.item, t1.level, t1.category, t1.item);
    }

    function getLevelProbability(uint level0, uint category0, uint class0, uint level1, uint category1, uint class1) public pure returns (bool can, uint score0, uint score1) {
        if (level0 != level1) {
            return (false, 0, 0);
        }
        can = true;
        score0 = level0**2 * 100 + category0**2*200 + class0**2*200;
        score1 = level1**2 * 100 + category1**2*200 + class1**2*200;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }
}
