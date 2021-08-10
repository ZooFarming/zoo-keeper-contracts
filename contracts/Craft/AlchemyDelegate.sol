// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./AlchemyStorage.sol";

interface IBurnToken {
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
        _setupRole(DEFAULT_ADMIN_ROLE, admin);


        dropRate = 100 ether;  // 100 DROP per block
        buyPrice = 100 ether;
        elixirBaseScore = 100 ether;
        buyToken = _buyToken;
        elixirNFT = _elixirNFT;
    }

    function configDropRate(uint _dropRate) external {
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        dropRate = _dropRate;
    }

    function configElixirBaseScore(uint _baseScore) external {
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        elixirBaseScore = _baseScore;
    }


    function elixirInfo(uint tokenId) public returns (uint level, uint drops) {
        ElixirInfo storage info = elixirInfoMap[tokenId];
        return (info.level, info.drops.add(pendingDrops(tokenId)));
    }

    function maxPendingDrops(address user) public view returns (uint) {
        return 100 ether; // TODO
    }

    function pendingDrops(address _user) public returns (uint) {
        UserInfo storage user = userInfoMap[_user];
        if (block.number > lastRewardBlock && totalZooStaked != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 dropReward = multiplier.mul(dropRate);
            accDropPerShare = accDropPerShare.add(dropReward.mul(1e12).div(totalZooStaked));
        }

        uint ret = user.amount.mul(accDropPerShare).div(1e12).sub(user.rewardDebt);
        if (ret <= maxPendingDrops(user)) {
            return ret;
        }
        return maxPendingDrops(user);
    }

    function buy() external {
        IERC20(buyToken).transferFrom(msg.sender, address(this), buyPrice);
        IBurnToken(buyToken).burn(buyPrice);
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

    function updateDrops() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 dropReward = multiplier.mul(dropRate);
        accDropPerShare = accDropPerShare.add(dropReward.mul(1e12).div(totalZooStaked));
        lastRewardBlock = block.number;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from);
    }
}
