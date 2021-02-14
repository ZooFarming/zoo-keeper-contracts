pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./NFTFactoryStorage.sol";

interface IZooToken {
    function burn(uint256 _amount) external;
}

interface IZooNFTMint {
    function mint(uint tokenId, uint _level, uint _category, uint _item, uint _random) external;
    function totalSupply() external view returns (uint);
}

// NFTFactory
contract NFTFactoryDelegate is Initializable, AccessControl, NFTFactoryStorage {
    using SafeERC20 for IERC20;

    event MintNFT(uint indexed level, uint indexed category, uint indexed item, uint random, uint tokenId);

    function initialize(address admin, address _zooToken, address _zooNFT) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        goldenChestPrice = 30000 ether;
        maxNFTLevel = 1;
        maxNFTCategory = 6;
        maxNFTItem = 5;
        maxNFTRandom = 300;
        zooToken = _zooToken;
        zooNFT = _zooNFT;
        priceUp0 = 101;
        priceUp1 = 100;
        priceDown0 = 99;
        priceDown1 = 100;
    }

    function configTokenAddress(address _zooToken, address _zooNFT) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        zooToken = _zooToken;
        zooNFT = _zooNFT;
    }

    function configChestPrice(uint _golden) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        goldenChestPrice = _golden;
    }

    function configNFTParams(uint _maxLevel, uint _maxNFTCategory, uint _maxNFTItem, uint _maxNFTRandom) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        maxNFTLevel = _maxLevel;
        maxNFTCategory = _maxNFTCategory;
        maxNFTItem = _maxNFTItem;
        maxNFTRandom = _maxNFTRandom;
    }

    function configPriceUpDownParams(uint _up0, uint _up1, uint _down0, uint _down1) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        priceUp0 = _up0;
        priceUp1 = _up1;
        priceDown0 = _down0;
        priceDown1 = _down1;
    }

    function buyGoldenChest() public {
        uint currentPrice = queryGoldenPrice();
        lastOrderTimestamp = block.timestamp;
        lastPrice = currentPrice.mul(priceUp0).div(priceUp1);

        IERC20(zooToken).transferFrom(msg.sender, address(this), currentPrice);
        IZooToken(zooToken).burn(currentPrice);
        uint tokenId;
        uint level;
        uint category;
        uint item;
        uint random;
        (tokenId, level, category, item, random) = randomNFT(true);

        IZooNFTMint(zooNFT).mint(tokenId, level, category, item, random);
        IERC721(zooNFT).safeTransferFrom(address(this), msg.sender, tokenId);
        emit MintNFT(level, category, item, random, tokenId);
    }

    function buySilverChest() public {
        uint currentPrice = queryGoldenPrice();
        lastOrderTimestamp = block.timestamp;
        // every 1 order, the price goes up 1%
        lastPrice = currentPrice.mul(priceUp0).div(priceUp1);

        // silver chest price is 1/10 golden chest price
        currentPrice = currentPrice.div(10);

        IERC20(zooToken).transferFrom(msg.sender, address(this), currentPrice);
        IZooToken(zooToken).burn(currentPrice);

        bool success = false;
        if (userInfo[msg.sender].emptyTimes >= 9) {
            success = true;
        } else {
            success = isSilverSuccess();
        }

        if (!success) {
            userInfo[msg.sender].emptyTimes++;
            emit MintNFT(0, 0, 0, 0, 0);
            return;
        }

        uint tokenId;
        uint level;
        uint category;
        uint item;
        uint random;
        (tokenId, level, category, item, random) = randomNFT(false);

        IZooNFTMint(zooNFT).mint(tokenId, level, category, item, random);
        IERC721(zooNFT).safeTransferFrom(address(this), msg.sender, tokenId);
        emit MintNFT(level, category, item, random, tokenId);
    }

    function queryGoldenPrice() public view returns (uint) {
        if (lastOrderTimestamp == 0) {
            return goldenChestPrice;
        }

        uint hourPassed = (block.timestamp - lastOrderTimestamp).div(1 hours);
        if (hourPassed == 0) {
            return lastPrice;
        }

        // every 1 hour idle, price goes down 1%
        return lastPrice.mul(priceDown0**hourPassed).div(priceDown1**hourPassed);
    }

    function isSilverSuccess() private view returns (bool) {
        uint totalSupply = IZooNFTMint(zooNFT).totalSupply();
        uint random1 = uint(keccak256(abi.encode(msg.sender, blockhash(block.number - 1), block.timestamp, totalSupply)));
        uint random2 = uint(keccak256(abi.encode(random1)));
        uint random3 = uint(keccak256(abi.encode(random2)));
        if (random2.add(random3).mod(10) == 6) {
            return true;
        }
        return false;
    } 

    function randomNFT(bool golden) private view returns (uint tokenId, uint level, uint category, uint item, uint random) {
        uint totalSupply = IZooNFTMint(zooNFT).totalSupply();
        tokenId = totalSupply + 1;
        uint random1 = uint(keccak256(abi.encode(tokenId, msg.sender, blockhash(block.number - 1), block.timestamp)));
        uint random2 = uint(keccak256(abi.encode(random1)));
        uint random3 = uint(keccak256(abi.encode(random2)));
        uint random4 = uint(keccak256(abi.encode(random3)));
        uint random5 = uint(keccak256(abi.encode(random4)));

        level = random5.mod(maxNFTLevel) + 1;
        category = random4.mod(maxNFTCategory) + 1;
        if (golden) {
            item = random3.mod(maxNFTItem) + 1;
        } else {
            item = random2.mod(3) + 1;
        }
        random = random1.mod(maxNFTRandom) + 1;
    }
}
