pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./MarketplaceStorage.sol";


contract MarketplaceDelegate is Initializable, AccessControl, ERC721Holder, MarketplaceStorage {

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        maxExpirationTime = 14 days;
        minExpirationTime = 1 days;
    }

    function createOrder(address nftContract, uint _tokenId, uint _expiration, uint _token, uint _price, uint expiration) external {
        require(IERC721(info.nftContract).ownerOf(tokenId) == msg.sender, "You have no access");
        require(IERC721(info.nftContract).isApprovedForAll(info.owner, address(this)), "Must approve first");
        require(expiration <= maxExpirationTime, "expiration too large");
        require(expiration >= minExpirationTime, "expiration too small");
        uint orderId = uint(keccak256(abi.encode(block.timestamp, msg.sender, _tokenId)));
        address owner;
        (owner,,,,,) = getOrderById(orderId);
    }

    function cancelOrder() external {

    }

    function buyOrder(uint _tokenId) external {

    }

    function orderCount() public view returns (uint) {
        return orderIds.length();
    }

    function getOrderId(uint index) public view returns (uint) {
        return orderIds.at(index);
    }

    function getOrderById(uint orderId) public view returns (address owner, uint tokenId, address token, address price, uint expiration, uint createTime) {
        OrderInfo storage info = orders[id];
        owner = info.owner;
        tokenId = info.tokenId;
        token = info.token;
        price = info.price;
        expiration = info.expiration;
        createTime = info.createTime;
    }

    function checkOrderValid(uint orderId) public view returns (bool) {
        OrderInfo storage info = orders[id];
        if (IERC721(info.nftContract).ownerOf(tokenId) != info.owner) {
            return false;
        }

        if (!IERC721(info.nftContract).isApprovedForAll(info.owner, address(this))) {
            return false;
        }

        if (info.createTime + info.expiration < block.timestamp) {
            return false;
        }

        return true;
    }

    function cleanInvalidOrders(uint from, uint to) public {
        // TODO
    }
}

