// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ZooHelperStorage.sol";

interface IZooSafari {
    function poolLength() external view returns (uint256);
    function pendingReward(uint256 _pid, address _user) external view returns (uint256,uint256);
}

interface IWanswapPair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface IWaspFarm {
    function userInfo(uint, address) external view returns (uint256, uint256);
    function poolLength() external view returns (uint256);
    function pendingWasp(uint256 _pid, address _user) external view returns (uint256);
}

interface IZooFarming {
    function poolLength() external view returns (uint256);
    function pendingZoo(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256, uint256);
}

interface IZooExpedition {
    function stakePlanCount() external view returns (uint256);
    function stakeInfo(address user, uint256 id) external view returns (uint256, uint256, uint256);
}

contract ZooHelperDelegate is Initializable, AccessControl, ZooHelperStorage {

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function config(address _zooToken, address _zooFarming, address _zooPair, address _nftFactory, address _safari) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        zooToken = _zooToken;
        zooFarming = _zooFarming;
        zooPair = _zooPair;
        nftFactory = _nftFactory;
        safari = _safari;
    }

    function getTotalScore(address user) public view returns (uint256) {
        uint total = 0;
        // wallet balance
        total = total.add(IERC20(zooToken).balanceOf(user));

        // pending zoo
        total = total.add(getPendingZoo(user));

        // farming zoo in zoo/wasp pool
        total = total.add(getFarmingZoo(user));

        // expedition zoo
        total = total.add(getExpeditionZoo(user));

        // safari zoo
        total = total.add(getSafariZoo(user));

        return total;
    }

    function getPendingZoo(address user) public view returns (uint256) {
        if(zooFarming == address(0)) {
            return 0;
        }
        uint total = 0;
        uint poolLength = IZooFarming(zooFarming).poolLength();
        for (uint i=0; i<poolLength; i++) {
            total = total.add(IZooFarming(zooFarming).pendingZoo(i, user));
        }
        return total;
    }

    function getSafariZoo(address user) public view returns (uint256) {
        if (safari == address(0)) {
            return 0;
        }
        uint total = 0;
        uint poolLength = IZooSafari(zooFarming).poolLength();
        uint amount;
        for (uint i=0; i<poolLength; i++) {
            (amount, ) = IZooSafari(zooFarming).pendingReward(i, user);
            total = total.add(amount);
        }
        return total;
    }

    function getExpeditionZoo(address user) public view returns (uint256) {
        if (nftFactory == address(0)) {
            return 0;
        }

        uint total = 0;
        uint length = IZooExpedition(nftFactory).stakePlanCount();
        uint stakeAmount;
        for (uint i=0; i<length; i++) {
            (, , stakeAmount) = IZooExpedition(nftFactory).stakeInfo(user, i);
            total = total.add(stakeAmount);
        }
        return total;
    }

    function getFarmingZoo(address user) public view returns (uint256) {
        if (zooFarming == address(0)) {
            return 0;
        }
        uint total = 0;
        uint amount;
        (amount,,) = IZooFarming(zooFarming).userInfo(7, user);
        if (amount > 0) {
            uint lpTotal = IERC20(zooPair).totalSupply();
            uint reserve0;
            (reserve0, , ) = IWanswapPair(zooPair).getReserves();
            total = total.add(amount.mul(reserve0).div(lpTotal));
        }

        return total;
    }
}

