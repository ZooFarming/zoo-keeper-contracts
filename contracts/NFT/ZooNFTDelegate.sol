pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./ZooNFTStorage.sol";

// ZooNFT
contract ZooNFT is ERC721("ZooNFT", "ZooNFT"), Initializable, AccessControl, ZooNFTStorage {

    bytes32 public constant NFT_FACTORY_ROLE = keccak256("FARMING_CONTRACT_ROLE");

    uint public constant MULTIPLIER_SCALE = 1e12;

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    
}
