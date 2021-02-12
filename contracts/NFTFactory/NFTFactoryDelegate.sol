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

interface IZooNFT {
    function mint(uint tokenId, uint _level, uint _category, uint _item, uint _random) external;
    function totalSupply() external view returns (uint);
}

// NFTFactory
contract NFTFactoryDelegate is Initializable, AccessControl, NFTFactoryStorage {
    using SafeERC20 for IERC20;

    function initialize(address admin, address _zooToken, address _zooNFT) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        randomNFTPrice = 30000 ether;
        stakeUnitPeriod = 30 days;
        stakeUnitAmount =  10000 ether;
        maxNFTLevel = 1;
        maxNFTCategory = 6;
        zooToken = _zooToken;
        zooNFT = _zooNFT;
    }

    function setRandomNFTPrice(uint _price) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        randomNFTPrice = _price;
    }

    function setStakeUnitPeriod(uint _period) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        stakeUnitPeriod = _period;
    }

    function setStakeUnitAmount(uint _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        stakeUnitAmount = _amount;
    }

    function setZooToken(address _zooToken) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        zooToken = _zooToken;
    }

    function setZooNFT(address _nft) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        zooNFT = _nft;
    }

    function setMaxNFTLevel(uint maxLevel) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        maxNFTLevel = maxLevel;
    }

    function buyRandomNFT() external {
        IERC20(zooToken).transferFrom(msg.sender, address(this), randomNFTPrice);
        IZooToken(zooToken).burn(randomNFTPrice);
        uint tokenId;
        uint level;
        uint category;
        uint item;
        uint random;
        (tokenId, level, category, item, random) = randomNFT();

        mint(tokenId, level, category, item, random);
        IERC721(zooNFT).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function randomNFT() public view returns (uint tokenId, uint level, uint category, uint item, uint random) {
        uint totalSupply = IZooNFT(zooNFT).totalSupply();
        tokenId = uint(keccak256(abi.encode("ZOO_KEEPER_NFT", totalSupply)));
        uint random1 = uint(keccak256(abi.encode(tokenId, msg.sender, blockhash(block.number - 1), block.timestamp, totalSupply)));
        uint random2 = uint(keccak256(abi.encode(random1)));
        uint random3 = uint(keccak256(abi.encode(random2)));
        uint random4 = uint(keccak256(abi.encode(random3)));
        uint random5 = uint(keccak256(abi.encode(random4)));

        //TODO
        level = random5.mod(maxLevel);
    }
}
