// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IBurnToken.sol";
import "./MarketplaceStorageV2.sol";

interface IZooNftInfo {
    function tokenInfo(uint _tokenId) external returns (uint level, uint category, uint item, uint random);
}

contract MarketplaceDelegate is Initializable, AccessControl, MarketplaceStorageV2 {
    using SafeERC20 for IERC20;

    uint public constant defaultPrice = 100 ether;

    address public constant blackHole = address(0xf000000000000000000000000000000000000000);

    event CreateOrder(address indexed _nftContract, uint indexed _tokenId, address indexed _token, uint _price, uint _expiration, uint _orderId);

    event CancelOrder(uint indexed _orderId);

    event BuyOrder(uint indexed _orderId, uint indexed _tokenId, address indexed _buyer, address _seller, address _nftContract, address _token, uint price);
    
    event CleanOrder(uint indexed _orderId, uint indexed _tokenId, address indexed _seller, address _nftContract, address _token, uint price);

    event BurnIllegalNFT(address indexed user, uint indexed tokenId);

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        maxExpirationTime = 1400 days;
        minExpirationTime = 1 days;
    }

    function configExpiration(uint _minExpirationTime, uint _maxExpirationTime) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        maxExpirationTime = _maxExpirationTime;
        minExpirationTime = _minExpirationTime;
    }

    function configFee(address _feeTo, uint _feeRate) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        feeTo = _feeTo;
        feeRate = _feeRate;
    }

    /// @dev createOrder is called by a seller
    /// @param _nftContract is the NFT contract address
    /// @param _tokenId is the NFT tokenId
    /// @param _expiration is the expiration of order in seconds
    /// @param _token is the pay token contract address for buyer
    /// @param _price is the amount of pay token
    function createOrder(address _nftContract, uint _tokenId, address _token, uint _price, uint _expiration) external {
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "You have no access");
        require(IERC721(_nftContract).isApprovedForAll(msg.sender, address(this)), "Must approve first");
        require(_expiration <= maxExpirationTime, "expiration too large");
        require(_expiration >= minExpirationTime, "expiration too small");
        uint orderId = uint(keccak256(abi.encode(msg.sender, _tokenId, _nftContract, _token)));
        address owner = orders[orderId].owner;
        if (owner != address(0)) {
            cancelOrder(_nftContract, _tokenId, _token);
            owner = address(0);
        }
        require(owner == address(0), "order exist");
        require(_nftContract != address(0), "_nftContract error");
        require(_tokenId != 0, "_tokenId error");
        require(_token != address(0), "_token error");
        require(_price != 0, "_price error");

        orders[orderId].owner = msg.sender;
        orders[orderId].nftContract = _nftContract;
        orders[orderId].tokenId = _tokenId;
        orders[orderId].token = _token;
        orders[orderId].price = _price;
        orders[orderId].expiration = _expiration;
        orders[orderId].createTime = block.timestamp;
        orderIds.add(orderId);

        emit CreateOrder(_nftContract, _tokenId, _token, _price, _expiration, orderId);
    }

    /// @param _nftContract is the NFT contract address
    /// @param _tokenId is the NFT tokenId
    /// @param _token is the pay token contract address for buyer
    function cancelOrder(address _nftContract, uint _tokenId, address _token) public {
        uint orderId = uint(keccak256(abi.encode(msg.sender, _tokenId, _nftContract, _token)));
        address owner = orders[orderId].owner;
        require(owner != address(0), "order not exist");
        require(owner == msg.sender, "order not yours");
        orderIds.remove(orderId);
        delete orders[orderId];

        emit CancelOrder(orderId);
    }

    function buyOrder(uint _orderId) external {
        require(checkOrderValid(_orderId), "order is not valid");
        OrderInfo memory order = orders[_orderId];

        orderIds.remove(_orderId);
        delete orders[_orderId];

        uint total = order.price;
        uint fee = total.mul(feeRate).div(1e12);

        // transfer fee
        IERC20(order.token).safeTransferFrom(msg.sender, feeTo, fee);

        IERC20(order.token).safeTransferFrom(msg.sender, order.owner, order.price.sub(fee));
        IERC721(order.nftContract).safeTransferFrom(order.owner, msg.sender, order.tokenId);

        recordZooPrice(order.nftContract, order.tokenId, order.token, order.price);

        emit BuyOrder(_orderId, order.tokenId, msg.sender, order.owner, order.nftContract, order.token, order.price);
    }

    function orderCount() public view returns (uint) {
        return orderIds.length();
    }

    function getOrderId(uint index) public view returns (uint orderId, bool isValid) {
        uint id = orderIds.at(index);
        return (id, checkOrderValid(id));
    }

    function getOrderById(uint orderId) public view returns (address owner, uint tokenId, address token, uint price, uint expiration, uint createTime) {
        OrderInfo storage info = orders[orderId];
        owner = info.owner;
        tokenId = info.tokenId;
        token = info.token;
        price = info.price;
        expiration = info.expiration;
        createTime = info.createTime;
    }

    function checkOrderValid(uint orderId) public view returns (bool) {
        OrderInfo storage info = orders[orderId];
        if (IERC721(info.nftContract).ownerOf(info.tokenId) != info.owner) {
            return false;
        }

        if (!IERC721(info.nftContract).isApprovedForAll(info.owner, address(this))) {
            return false;
        }

        // if (info.createTime + info.expiration < block.timestamp) {
        //     return false;
        // }

        // if (info.nftContract != zooNFT) {
        //     return true;
        // }

        // // fix for foridden cheaters NFT
        // if (info.tokenId >= 20 && info.tokenId <= 47) {
        //     return false;
        // }
        // if (info.tokenId == 99) {
        //     return false;
        // }
        // if (info.tokenId == 89) {
        //     return false;
        // }
        // if (info.tokenId == 86) {
        //     return false;
        // }
        // if (info.tokenId == 78) {
        //     return false;
        // }
        // if (info.tokenId == 75) {
        //     return false;
        // }

        // if (info.tokenId == 56) {
        //     return false;
        // }

        // if (info.tokenId == 52) {
        //     return false;
        // }

        // if (info.tokenId == 16) {
        //     return false;
        // }

        // if (info.tokenId == 14) {
        //     return false;
        // }

        // if (info.tokenId == 222) {
        //     return false;
        // }

        // if (info.tokenId == 252) {
        //     return false;
        // }

        return true;
    }

    function cleanInvalidOrders(int from, int to) public returns (uint) {
        require(to >= from, "to should >= from");
        uint ret = 0;
        for (int i=to; i>= from; i--) {
            uint orderId = orderIds.at(uint(i));
            if (!checkOrderValid(orderId)) {
                OrderInfo memory info = orders[orderId];
                orderIds.remove(orderId);
                delete orders[orderId];
                emit CleanOrder(orderId, info.tokenId, info.owner, info.nftContract, info.token, info.price);
                ret++;
            }
        }
        return ret;
    }

    function getInvalidOrders() public view returns (uint[] memory invalidOrders) {
        uint found;
        uint count = orderCount();
        for (uint i=0; i<count; i++) {
            uint orderId = orderIds.at(uint(i));
            if (!checkOrderValid(orderId)) {
                found++;
            }
        }
        invalidOrders = new uint[](found);
        uint index = 0;
        for (uint i=0; i<count; i++) {
            uint orderId = orderIds.at(uint(i));
            if (!checkOrderValid(orderId)) {
                invalidOrders[index] = orderId;
                index++;
            }
        }
    }

    function cleanOrders(uint[] calldata _invalidIds) public {
        int length = int(_invalidIds.length);
        for (int i=(length - 1); i>= 0; i--) {
            uint orderId = _invalidIds[uint256(i)];
            if (!checkOrderValid(orderId)) {
                OrderInfo memory info = orders[orderId];
                orderIds.remove(orderId);
                delete orders[orderId];
                emit CleanOrder(orderId, info.tokenId, info.owner, info.nftContract, info.token, info.price);
            }
        }
    }

    function configZooNFT(address _zooNFT, address _zooToken) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        zooNFT = _zooNFT;
        zooToken = _zooToken;
    }

    function burnIllegalZooNFT(uint tokenId) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        address tokenOwner = IERC721(zooNFT).ownerOf(tokenId);
        require(tokenOwner != blackHole, "Already in black hole");
        require(!Address.isContract(tokenOwner), "NFT is locked in a smart contract");

        IERC721(zooNFT).safeTransferFrom(tokenOwner, blackHole, tokenId);
        emit BurnIllegalNFT(tokenOwner, tokenId);
    }

    function configZooNFTPrice(uint level, uint category, uint item, uint price) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        zooNftPrice[level][category][item] = price;
    }

    function recordZooPrice(address tokenSC, uint tokenId, address payToken, uint price) internal {
        if (tokenSC != zooNFT || payToken != zooToken) {
            return;
        }

        uint level;
        uint category;
        uint item;
        (level, category, item,) = IZooNftInfo(zooNFT).tokenInfo(tokenId);
        zooNftPrice[level][category][item] = price;
    }

    function transferZooNFT(uint tokenId, address to) external {
        uint level;
        uint category;
        uint item;
        (level, category, item,) = IZooNftInfo(zooNFT).tokenInfo(tokenId);
        uint price = zooNftPrice[level][category][item];
        if (price == 0) {
            price = defaultPrice;
        }

        uint burnAmount = price.div(100);
        IERC20(zooToken).transferFrom(msg.sender, address(this), burnAmount);
        IBurnToken(zooToken).burn(burnAmount);

        IERC721(zooNFT).safeTransferFrom(msg.sender, to, tokenId);
    }
}

