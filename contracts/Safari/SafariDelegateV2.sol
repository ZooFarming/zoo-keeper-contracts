// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "./SafariDelegate.sol";

interface INftCreator {
    function nftCreator(uint tokenId) external view returns(address);
}

contract SafariDelegateV2 is SafariDelegate, ERC721Holder {
    // v2 add
    address public keepsakesNft;
    address public phxCreator;
    mapping(address => uint) public nftBank; // user => tokenId

    function configNftInfo(address _keepsakesNft, address _phxCreator) external {
        keepsakesNft = _keepsakesNft;
        phxCreator = _phxCreator;
    }

    function depositWithNft(uint256 _pid, uint256 _amount, uint256 tokenId) public {
        address creator = INftCreator(keepsakesNft).nftCreator(tokenId);
        require(creator == phxCreator, "Not phx NFT");
        require(nftBank[msg.sender] == 0, "NFT exist");
        IERC721(keepsakesNft).safeTransferFrom(msg.sender, address(this), tokenId);
        nftBank[msg.sender] = tokenId;
        deposit(_pid, _amount);
    }

    function withdrawWithNft(uint256 _pid) public {
        uint tokenId = nftBank[msg.sender];
        require(tokenId != 0, "NFT not exist");
        UserInfo storage user = userInfo[_pid][msg.sender];
        withdraw(_pid, user.amount);
        nftBank[msg.sender] = 0;
        IERC721(keepsakesNft).safeTransferFrom(address(this), msg.sender, tokenId);
    }
}
