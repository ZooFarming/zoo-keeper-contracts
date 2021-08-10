// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./AlchemyStorage.sol";

interface IZooToken {
    function burn(uint256 _amount) external;
}

interface IElixirNFT {
    function mint(uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

contract AlchemyDelegate is Initializable, AccessControl, ERC721Holder, AlchemyStorage {
    using SafeERC20 for IERC20;

    function initialize(address admin, address _elixirNFT, address _buyToken) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        dropRate = 100 ether;  // 100 DROP per block
        buyPrice = 100 ether;
        buyToken = _buyToken;
        elixirNFT = _elixirNFT;
    }

    function elixirInfo(uint tokenId) public returns (uint level, uint drops) {
        ElixirInfo storage info = elixirInfoMap[tokenId];
        return (info.level, info.drops.add(pendingDrops(tokenId)));
    }

    function pendingDrops(uint tokenId) public return (uint) {
        return 0; // TODO
    }

    function buy() external {
        IERC20(buyToken).transferFrom(msg.sender, address(this), buyPrice);
        IZooToken(buyToken).burn(buyPrice);
        totalMint = totalMint.add(1);
        IElixirNFT(elixirNFT).mint(totalMint);
        IERC721(elixirNFT).safeTransferFrom(address(this), msg.sender, totalMint);
    }

    function depositElixir(uint tokenId) public {

    }

    function depositZoo(uint amount) public {

    }

    function depositElixirAndZoo(uint tokenId, uint zooAmount) external {
        depositElixir(tokenId);
        depositZoo(zooAmount);
    }

    function upgradeElixir() external {

    }

    function withdrawElixirAndZoo() external {

    }

    function withdrawZoo(uint amount) public {

    }

    function nftCraft(uint tokenId0, uint tokenId1) external {

    }

    function nftUpgradeCraft(uint tokenId0, uint tokenId1) public {

    }

    function burnZooNft(uint tokenId) internal {
        
    }
}
