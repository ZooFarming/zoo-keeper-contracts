// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ZoorenaStorage.sol";

interface IPosRandom {
    function getRandomNumberByEpochId(uint256) external view returns(uint256);
}

interface INftFactory {
    function queryGoldenPrice() external view returns (uint);
}

contract ZoorenaDelegate is Initializable, AccessControl, ZoorenaStorage {
    
    // pos random contract address
    address public constant POS_RANDOM_ADDRESS = address(0x262);

    // scale of power point
    uint public constant POWER_SCALE = 1e12;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    bytes32 public constant ROBOT_ROLE = keccak256("ROBOT_ROLE");

    address public constant playToken = address(0x6e11655d6aB3781C6613db8CB1Bc3deE9a7e111F);

    address public constant nftFactory = address(0xBCE166860F514b6134AbC6E9Aa0005CC489b6352);

    // 9.  0: join clan, 1:....
    uint public constant eventCount = 9;

    function initialize(address admin) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ROBOT_ROLE, DEFAULT_ADMIN_ROLE);

        // 60%, 30%, 5%, 1%
        LEVEL_MASK.push(60);
        LEVEL_MASK.push(90);
        LEVEL_MASK.push(95);
        LEVEL_MASK.push(96);

        // 40%, 33%, 17%, 7%, 2%, 1%
        CATEGORY_MASK.push(40);
        CATEGORY_MASK.push(73);
        CATEGORY_MASK.push(90);
        CATEGORY_MASK.push(97);
        CATEGORY_MASK.push(99);
        CATEGORY_MASK.push(100);

        // 35%, 30%, 20%, 10%, 5%
        ITEM_MASK.push(35);
        ITEM_MASK.push(65);
        ITEM_MASK.push(85);
        ITEM_MASK.push(95);
        ITEM_MASK.push(100);
    }

    function configOracle(address oracle) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(ORACLE_ROLE, oracle);
        _foundationSeed = uint(keccak256(abi.encode(msg.sender, blockhash(block.number - 1), block.coinbase)));
    }

    function inputSeed(uint seed_) external {
        require(hasRole(ORACLE_ROLE, msg.sender));
        _foundationSeed = seed_;
    }

    function configRobot(address robot) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(ROBOT_ROLE, robot);
    }


    function bet(uint eventId, uint selection) external {
        require(selection != 0 && selection != 100, "selection error");
        require(eventId < 9, "event Id error");
        uint goldenPrice = INftFactory(nftFactory).queryGoldenPrice();
        uint silverPrice = goldenPrice.div(10);
    }

    function fightStart() external {
        require(hasRole(ROBOT_ROLE, msg.sender));
        // TODO:
    }

    function claimEvent(uint roundId, uint eventId) external {

    }

    function claimJackpot(uint roundId) external {

    }

    function currentRoundId() public view returns(uint) {
        return 0;
    }

    // return values: 
    // status: 0: pause, 1: betting, 2: waiting, 3: fighting, 4: waitingJackpot
    // function getRoundInfo(uint roundId) public view 
    //     returns(
    //         uint status,
    //         uint jackpot,
    //         uint leftUserCount,
    //         uint leftNftCount,
    //         uint leftPower,
    //         uint[] memory leftLife,
    //         uint rightUserCount,
    //         uint rightNftCount,
    //         uint rightPower,
    //         uint[] memory rightLife,
    //         uint[] memory eventResult,
    //         address[] memory jackpotResult
    //     ) {
    // }

    // TODO: NEED MODIFY
    // function randomNFT(bool golden) private view returns (uint tokenId, uint level, uint category, uint item, uint random) {
    //     uint totalSupply = IZooNFTMint(zooNFT).totalSupply();
    //     tokenId = totalSupply + 1;
    //     uint random1 = uint(keccak256(abi.encode(tokenId, msg.sender, blockhash(block.number - 1), block.coinbase, block.timestamp, _foundationSeed)));
    //     uint random2 = uint(keccak256(abi.encode(random1)));
    //     uint random3 = uint(keccak256(abi.encode(random2)));
    //     uint random4 = uint(keccak256(abi.encode(random3)));
    //     uint random5 = uint(keccak256(abi.encode(random4)));

    //     // mod 100 -> 96 is used for fix the total chance is 96% not 100% issue.
    //     level = getMaskValue(random5.mod(96), LEVEL_MASK) + 1;
    //     category = getMaskValue(random4.mod(100), CATEGORY_MASK) + 1;
    //     if (golden) {
    //         item = getMaskValue(random3.mod(100), ITEM_MASK) + 1;
    //     } else {
    //         item = getMaskValue(random2.mod(85), ITEM_MASK) + 1;
    //     }
    //     random = random1.mod(maxNFTRandom) + 1;
    // }

    // function getMaskValue(uint random, uint[] memory mask) private pure returns (uint) {
    //     for (uint i=0; i<mask.length; i++) {
    //         if (random < mask[i]) {
    //             return i;
    //         }
    //     }
    // }
}
