pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./ZooNFTStorage.sol";

// ZooNFT
contract ZooNFT is ERC721("ZooNFT", "ZooNFT"), Initializable, AccessControl, ZooNFTStorage {

}
