// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";

import "./NFTFactoryStorageV3.sol";

interface IZooToken {
    function burn(uint256 _amount) external;
}

interface IZooNFTMint {
    function mint(uint tokenId, uint _level, uint _category, uint _item, uint _random) external;
    function totalSupply() external view returns (uint);
    function itemSupply(uint _level, uint _category, uint _item) external view returns (uint);
}

interface IPrivateOracle {
    function inputSeed(uint seed_) external;
}

// NFTFactory
contract NFTFactoryDelegate is Initializable, AccessControl, ERC721Holder, NFTFactoryStorageV3 {
    using SafeERC20 for IERC20;

    event MintNFT(uint indexed level, uint indexed category, uint indexed item, uint random, uint tokenId, uint itemSupply);

    event GoldenBuy(address indexed user, uint price);
    
    event SilverBuy(address indexed user, uint price);

    event ZooStake(address indexed user, uint price, uint _type);

    event ZooClaim(address indexed user, uint price, uint _type, uint tokenId);

    event MintFinish(address indexed user);

    function initialize(address admin, address _zooToken, address _zooNFT) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        goldenChestPrice = 25000 ether;
        maxNFTLevel = 4;
        maxNFTCategory = 6;
        maxNFTItem = 5;
        maxNFTRandom = 300;
        zooToken = _zooToken;
        zooNFT = _zooNFT;
        priceUp0 = 101;
        priceUp1 = 100;
        priceDown0 = 99;
        priceDown1 = 100;
        dynamicPriceTimeUnit = 1 hours;
        dynamicMinPrice = 1000 ether;
        dynamicMaxPrice = 50000 ether;
        lastOrderTimestamp = block.timestamp;
        lastPrice = goldenChestPrice;
        stakePlanCount = 3;
        stakePlan[0].priceMul = 10;
        stakePlan[0].priceDiv = 1;
        stakePlan[0].lockTime = 48 hours;
        stakePlan[1].priceMul = 1;
        stakePlan[1].priceDiv = 1;
        stakePlan[1].lockTime = 15 days;
        stakePlan[2].priceMul = 1;
        stakePlan[2].priceDiv = 2;
        stakePlan[2].lockTime = 30 days;

        // 60%, 30%, 5%, 1%
        LEVEL_MASK.push(60);
        LEVEL_MASK.push(90);
        LEVEL_MASK.push(95);
        LEVEL_MASK.push(100);

        // 40%, 33%, 17%, 7%, 2%, 1%
        CATEGORY_MASK.push(40);
        CATEGORY_MASK.push(73);
        CATEGORY_MASK.push(90);
        CATEGORY_MASK.push(97);
        CATEGORY_MASK.push(99);
        CATEGORY_MASK.push(100);

        // 35%, 30%, 20%, 10%, 5%
        ITEM_MASK.push(35);
        ITEM_MASK.push(65);
        ITEM_MASK.push(85);
        ITEM_MASK.push(95);
        ITEM_MASK.push(100);
    }

    function configOracle(address oracle) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        grantRole(ORACLE_ROLE, oracle);
        _foundationSeed = uint(keccak256(abi.encode(msg.sender, blockhash(block.number - 1), block.coinbase)));
    }

    function inputSeed(uint seed_) external {
        require(hasRole(ORACLE_ROLE, msg.sender));
        _foundationSeed = seed_;
    }

    function configTokenAddress(address _zooToken, address _zooNFT) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        zooToken = _zooToken;
        zooNFT = _zooNFT;
    }

    function configChestPrice(uint _golden) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        goldenChestPrice = _golden;
        lastOrderTimestamp = block.timestamp;
        lastPrice = goldenChestPrice;
    }

    function configDynamicPrice(uint _dynamicPriceTimeUnit, uint _dynamicMinPrice, uint _dynamicMaxPrice) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        dynamicPriceTimeUnit = _dynamicPriceTimeUnit;
        dynamicMinPrice = _dynamicMinPrice;
        dynamicMaxPrice = _dynamicMaxPrice;
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

    function configStakePlanCount(uint _stakePlanCount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        stakePlanCount = _stakePlanCount;
    }

    function configStakePlanInfo(uint id, uint priceMul, uint priceDiv, uint lockTime) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        stakePlan[id].priceMul = priceMul;
        stakePlan[id].priceDiv = priceDiv;
        stakePlan[id].lockTime = lockTime;
    }

    function buyGoldenChest() public {
        require(msg.sender == tx.origin, "can not call from contract");
        uint currentPrice = queryGoldenPrice();
        lastOrderTimestamp = block.timestamp;
        priceRaise(currentPrice);

        IERC20(zooToken).transferFrom(msg.sender, address(this), currentPrice);
        IZooToken(zooToken).burn(currentPrice);
        
        requestMint(true, currentPrice);
    }

    function buySilverChest() public {
        require(msg.sender == tx.origin, "can not call from contract");
        uint currentPrice = queryGoldenPrice();
        lastOrderTimestamp = block.timestamp;
        // every 1 order, the price goes up 1%
        priceRaise(currentPrice);

        // silver chest price is 1/10 golden chest price
        currentPrice = currentPrice.div(10);

        IERC20(zooToken).transferFrom(msg.sender, address(this), currentPrice);
        IZooToken(zooToken).burn(currentPrice);

        requestMint(false, currentPrice);
    }

    function queryGoldenPrice() public view returns (uint) {
        if (lastOrderTimestamp == 0) {
            return goldenChestPrice;
        }

        uint hourPassed = (block.timestamp - lastOrderTimestamp).div(dynamicPriceTimeUnit);
        if (hourPassed == 0) {
            return lastPrice;
        }

        // every 1 hour idle, price goes down 1%
        uint newPrice = lastPrice;
        for (uint i=0; i<hourPassed; i++) {
            newPrice = newPrice.mul(priceDown0).div(priceDown1);
            if (newPrice < dynamicMinPrice) {
                return dynamicMinPrice;
            }
        }
        return newPrice;
    }

    function priceRaise(uint currentPrice) private {
        if (currentPrice.mul(priceUp0).div(priceUp1) > dynamicMaxPrice) {
            lastPrice = dynamicMaxPrice;
        } else {
            lastPrice = currentPrice.mul(priceUp0).div(priceUp1);
        }
    }

    /// @dev Stake ZOO to get NFT
    /// @param _type value: 
    /// 0: lock x10 48 hours to get golden chest
    /// 1: lock x1 15 days to get golden chest
    /// 2: lock x0.5 30 days to get golden chest
    function stakeZoo(uint _type) public {
        require(isStakeFinished(_type), "There is still pending stake");
        require(_type < stakePlanCount, "_type error");

        uint currentPrice = queryGoldenPrice();
        lastOrderTimestamp = block.timestamp;
        // every 1 order, the price goes up 1%
        priceRaise(currentPrice);

        stakeInfo[msg.sender][_type].startTime = block.timestamp;

        uint stakePrice = currentPrice.mul(stakePlan[_type].priceMul).div(stakePlan[_type].priceDiv);
        stakeInfo[msg.sender][_type].stakeAmount = stakePrice;
        stakeInfo[msg.sender][_type].lockTime = stakePlan[_type].lockTime;

        IERC20(zooToken).transferFrom(msg.sender, address(this), stakePrice);

        stakedAmount[_type] = stakedAmount[_type].add(stakePrice);

        emit ZooStake(msg.sender, stakePrice, _type);
    }

    /// @dev must have no stake in it
    function isStakeable(uint _type) public view returns (bool) {
        if (_type >= stakePlanCount) {
            return false;
        }

        return stakeInfo[msg.sender][_type].stakeAmount == 0;
    }

    function stakeClaim(uint _type) public {
        require(msg.sender == tx.origin, "can not call from contract");
        require(_type < stakePlanCount, "_type error");
        require(isStakeFinished(_type), "There is still pending stake");

        uint amount = stakeInfo[msg.sender][_type].stakeAmount;
        require(amount > 0, "no stake");

        delete stakeInfo[msg.sender][_type];

        //mint NFT
        requestMint(true, amount);
    }

    function isStakeFinished(uint _type) public view returns (bool) {
        return block.timestamp > (stakeInfo[msg.sender][_type].startTime.add(stakeInfo[msg.sender][_type].lockTime));
    }

    function isSilverSuccess() private returns (bool) {
        uint totalSupply = IZooNFTMint(zooNFT).totalSupply();
        uint random1 = uint(keccak256(abi.encode(msg.sender, blockhash(block.number - 1), block.coinbase, block.timestamp, totalSupply, getRandomSeed())));
        uint random2 = uint(keccak256(abi.encode(random1)));
        uint random3 = uint(keccak256(abi.encode(random2)));
        if (random2.mod(1000).add(random3.mod(1000)).mod(10) == 6) {
            return true;
        }
        return false;
    } 

    // mint special level NFT
    function mintLeveledNFT(uint _level) private returns (uint tokenId, uint level, uint category, uint item, uint random) {
        uint totalSupply = IZooNFTMint(zooNFT).totalSupply();
        tokenId = totalSupply + 1;
        uint random1 = uint(keccak256(abi.encode(tokenId, msg.sender, blockhash(block.number - 1), block.coinbase, block.timestamp, getRandomSeed())));
        uint random2 = uint(keccak256(abi.encode(random1)));
        uint random3 = uint(keccak256(abi.encode(random2)));
        uint random4 = uint(keccak256(abi.encode(random3)));

        level = _level;
        category = getMaskValue(random4.mod(100), CATEGORY_MASK) + 1;
        item = getMaskValue(random3.mod(100), ITEM_MASK) + 1;
        random = random1.mod(maxNFTRandom) + 1;
    }

    function randomNFT(address user, bool golden) private returns (uint tokenId, uint level, uint category, uint item, uint random) {
        uint totalSupply = IZooNFTMint(zooNFT).totalSupply();
        tokenId = totalSupply + 1;
        uint random1 = uint(keccak256(abi.encode(tokenId, user, blockhash(block.number - 1), block.coinbase, block.timestamp, getRandomSeed())));
        uint random2 = uint(keccak256(abi.encode(random1)));
        uint random3 = uint(keccak256(abi.encode(random2)));
        uint random4 = uint(keccak256(abi.encode(random3)));
        uint random5 = uint(keccak256(abi.encode(random4)));

        // mod 100 -> 96 is used for fix the total chance is 96% not 100% issue.
        level = getMaskValue(random5.mod(96), LEVEL_MASK) + 1;
        category = getMaskValue(random4.mod(100), CATEGORY_MASK) + 1;
        if (golden) {
            item = getMaskValue(random3.mod(100), ITEM_MASK) + 1;
        } else {
            item = getMaskValue(random2.mod(85), ITEM_MASK) + 1;
        }
        random = random1.mod(maxNFTRandom) + 1;
    }

    function getMaskValue(uint random, uint[] memory mask) private pure returns (uint) {
        for (uint i=0; i<mask.length; i++) {
            if (random < mask[i]) {
                return i;
            }
        }
    }

    function getRandomSeed() internal returns (uint) {
        return _foundationSeed;
    }

    function openGoldenChest(address user, uint price) internal {
        uint tokenId;
        uint level;
        uint category;
        uint item;
        uint random;
        (tokenId, level, category, item, random) = randomNFT(user, true);

        IZooNFTMint(zooNFT).mint(tokenId, level, category, item, random);
        IERC721(zooNFT).safeTransferFrom(address(this), user, tokenId);

        uint itemSupply = IZooNFTMint(zooNFT).itemSupply(level, category, item);
        emit MintNFT(level, category, item, random, tokenId, itemSupply);
        emit GoldenBuy(user, price);
    }

    function openSilverChest(address user, uint price) internal {
        bool success = false;
        if (emptyTimes[user] >= 9) {
            success = true;
        } else {
            success = isSilverSuccess();
        }

        emit SilverBuy(user, price);

        if (!success) {
            emptyTimes[user]++;
            emit MintNFT(0, 0, 0, 0, 0, 0);
            return;
        }

        emptyTimes[user] = 0;

        uint tokenId;
        uint level;
        uint category;
        uint item;
        uint random;
        (tokenId, level, category, item, random) = randomNFT(user, false);

        IZooNFTMint(zooNFT).mint(tokenId, level, category, item, random);
        IERC721(zooNFT).safeTransferFrom(address(this), user, tokenId);
        uint itemSupply = IZooNFTMint(zooNFT).itemSupply(level, category, item);
        emit MintNFT(level, category, item, random, tokenId, itemSupply);
    }

    function requestMint(bool golden, uint _price) internal {
        mintRequestInfo[currentRequestCount].user = msg.sender;
        mintRequestInfo[currentRequestCount].price = _price;
        mintRequestInfo[currentRequestCount].golden = golden;
        currentRequestCount = currentRequestCount.add(1);
    }

    // for robot to get current waiting mint count
    function getWaitingMintCount() public view returns (uint) {
        if (currentRequestCount > doneRequestCount) {
            return currentRequestCount - doneRequestCount;
        }
        return 0;
    }

    function agentMint(uint _seed) external {
        require(getWaitingMintCount() > 0, "no mint request");
        require(hasRole(ORACLE_ROLE, msg.sender));
        _foundationSeed = _seed;

        uint i = doneRequestCount;
        if (mintRequestInfo[i].golden) {
            openGoldenChest(mintRequestInfo[i].user, mintRequestInfo[i].price);
        } else {
            openSilverChest(mintRequestInfo[i].user, mintRequestInfo[i].price);
        }

        doneRequestCount = doneRequestCount.add(1);
        emit MintFinish(mintRequestInfo[i].user);
    }
}
