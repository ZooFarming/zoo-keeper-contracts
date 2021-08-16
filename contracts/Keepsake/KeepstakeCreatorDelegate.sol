// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


import "./KeepstakeCreatorStorage.sol";

interface IKeepsakeNFT {
    function mint(uint256 tokenId, string calldata uri, address _creator) external;
    function totalSupply() external view returns (uint256);
}

contract KeepstakeCreatorDelegate is
    Initializable,
    AccessControl,
    ERC721Holder,
    KeepstakeCreatorStorage
{

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin");
        _;
    }

    modifier onlyAuthor() {
        require(authorList.contains(msg.sender), "only author");
        _;
    }

    function initialize(address _admin, address _nftAddress)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        keepsakeNFT = _nftAddress;
    }

    function getAuthorList() public view returns (address[] memory) {
        uint length = authorList.length();
        address[] memory authors = new address[](length);
        for(uint i=0; i<length; i++) {
            authors[i] = authorList.at(i);
        }
        return authors;
    }

    function addAuthor(address _author) external onlyAdmin {
        require(!authorList.contains(_author), "already exisit");
        authorList.add(_author);
    }

    function removeAuthor(address _author) external onlyAdmin {
        require(authorList.contains(_author), "not exisit");
        authorList.remove(_author);
    }

    function mint(string calldata uri, address to) public onlyAuthor {
        uint newTokenId = IKeepsakeNFT(keepsakeNFT).totalSupply() + 1;
        IKeepsakeNFT(keepsakeNFT).mint(newTokenId, uri, msg.sender);
        IERC721(keepsakeNFT).safeTransferFrom(address(this), to, newTokenId);
    }

    function airDrop(string calldata uri, address[] calldata users) external {
        uint count = users.length;
        for (uint i=0; i<count; i++) {
            mint(uri, users[i]);
        }
    }
}
