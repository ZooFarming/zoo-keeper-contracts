// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ZoorenaStorage.sol";

interface IPosRandom {
    function getRandomNumberByEpochId(uint256) external view returns(uint256);
}

interface INftFactory {
    function queryGoldenPrice() external view returns (uint);
}

interface IZooToken {
    function burn(uint256 _amount) external;
}

interface IZooNFTBoost {
    // scaled 1e12
    function getBoosting(uint _tokenId) external view returns (uint);
}

contract ZoorenaDelegate is Initializable, AccessControl, ERC721Holder, ZoorenaStorage {
    
    // pos random contract address
    address public constant POS_RANDOM_ADDRESS = address(0x262);

    // scale of power point
    uint public constant POWER_SCALE = 1e10;

    bytes32 public constant ROBOT_ROLE = keccak256("ROBOT_ROLE");

    // 9.  0: join clan, 1:....
    uint public constant eventCount = 9;

    // time for each event
    uint public constant eventBlock = 6;

    uint public constant personPower = 10;

    // init power point for both
    uint public constant initPower = 10000;

    event Bet(address indexed user, uint indexed roundId, uint indexed eventId, uint selection);

    event FightStart(uint indexed roundId, uint indexed fightStartBlock);

    function initialize(address admin, address _playToken, address _nftFactory, address _zooNFT) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(ROBOT_ROLE, DEFAULT_ADMIN_ROLE);

        playToken = _playToken;
        nftFactory = _nftFactory;
        zooNFT = _zooNFT;

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

    function halt(bool _pause) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        pause = _pause;
    }

    function configRobot(address robot) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(ROBOT_ROLE, robot);
    }

    function configEventOptions(uint eventId, uint optionCount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        eventOptions[eventId] = optionCount;
    }

    function configTime(uint _baseTime, uint _roundTime, uint _closeTime) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        baseTime = _baseTime;
        roundTime = _roundTime;
        closeTime = _closeTime;
    }

    function bet(uint eventId, uint selection) external {
        require(selection != 0 && selection != 100, "selection error");
        require(eventId < 9, "event Id error");
        require(getStatus() == 1, "betting closed");

        uint roundId = currentRoundId();
        
        require(userEvent[roundId][msg.sender][eventId] == 0, "already selected");

        // select clan
        if (eventId == 0) {
            joinClan(eventId, selection, roundId);
        } else {
            betEvent(eventId, selection, roundId);
        }

        emit Bet(msg.sender, roundId, eventId, selection);
    }

    // side: left:1, right:2
    function depositNFT(uint side, uint tokenId) external {
        require(getStatus() == 1, "betting closed");
        require(side >=1 && side <= 2, "side error");
        require(tokenId != 0, "NFT error");
        require(userNft[msg.sender] == 0, "need withdraw first");
        uint roundId = currentRoundId();

        IERC721(zooNFT).safeTransferFrom(msg.sender, address(this), tokenId);
        uint boost = IZooNFTBoost(zooNFT).getBoosting(tokenId);
        if (side == 1) {
            roundInfo[roundId].leftPower = roundInfo[roundId].leftPower.add(boost);
        } else {
            roundInfo[roundId].rightPower = roundInfo[roundId].rightPower.add(boost);
        }

        userNft[msg.sender] = tokenId;
    }

    function withdrawNFT() external {
        require(getStatus() == 1, "betting closed");
        uint roundId = currentRoundId();
        uint tokenId = userNft[msg.sender];
        require(tokenId != 0, "no NFT found");
        uint boost = IZooNFTBoost(zooNFT).getBoosting(tokenId);

        if (userEvent[roundId][msg.sender][0] == 1) {
            roundInfo[roundId].leftPower = roundInfo[roundId].leftPower.sub(boost);
        }

        if (userEvent[roundId][msg.sender][0] == 2) {
            roundInfo[roundId].rightPower = roundInfo[roundId].rightPower.sub(boost);
        }

        userNft[msg.sender] = 0;

        IERC721(zooNFT).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function fightStart(uint roundId, uint fightStartBlock) external {
        require(hasRole(ROBOT_ROLE, msg.sender));
        
        roundInfo[roundId].fightStartBlock = fightStartBlock;

        emit FightStart(roundId, fightStartBlock);
    }

    function claimEvent(uint roundId, uint eventId) external {

    }

    function claimJackpot(uint roundId) external {

    }

    function currentRoundId() public view returns(uint) {
        return (block.timestamp - baseTime) / roundTime;
    }

    function betEvent(uint eventId, uint selection, uint roundId) internal {
        require(selection > 0, "selection out of range");
        bool golden = false;
        if (selection > 100) {
            golden = true;
            require(selection <= (eventOptions[eventId] + 100), "selection out of range");
        } else {
            require(selection <= eventOptions[eventId], "selection out of range");
        }

        userEvent[roundId][msg.sender][eventId] = selection;
        uint goldenPrice = INftFactory(nftFactory).queryGoldenPrice();
        uint silverPrice = goldenPrice.div(10);
        uint ticket;
        if (golden) {
            ticket = goldenPrice.div(eventOptions[eventId]).add(goldenPrice.div(20));
        } else {
            ticket = silverPrice.div(eventOptions[eventId]).add(silverPrice.div(20));
        }

        // cost 55% zoo to get a silver chest
        IERC20(playToken).transferFrom(msg.sender, address(this), ticket);
        // burn 50%
        IZooToken(playToken).burn(ticket.div(2));
        
        roundInfo[roundId].jackpot = roundInfo[roundId].jackpot.add(ticket.div(2));
    }

    function joinClan(uint eventId, uint selection, uint roundId) internal {
        require(selection > 0 && selection <3, "selection out of range");
        userEvent[roundId][msg.sender][eventId] = selection;

        uint goldenPrice = INftFactory(nftFactory).queryGoldenPrice();
        uint silverPrice = goldenPrice.div(10);
        uint ticket = silverPrice.div(2).add(silverPrice.div(20));

        // cost 55% zoo to get a silver chest
        IERC20(playToken).transferFrom(msg.sender, address(this), ticket);
        // burn 50%
        IZooToken(playToken).burn(ticket.div(2));
        
        roundInfo[roundId].jackpot = roundInfo[roundId].jackpot.add(ticket.div(2));
        uint boost = 0;
        uint tokenId = userNft[msg.sender];
        if (tokenId != 0) {
            boost = IZooNFTBoost(zooNFT).getBoosting(tokenId);
        }

        if (selection == 1) {
            roundInfo[roundId].leftUserCount++;
            roundInfo[roundId].leftPower = roundInfo[roundId].leftPower.add(personPower.mul(POWER_SCALE)).add(tokenId);
        } else {
            roundInfo[roundId].rightUserCount++;
            roundInfo[roundId].rightPower = roundInfo[roundId].rightPower.add(personPower.mul(POWER_SCALE)).add(tokenId);
        }
    }

    // status: 0: pause, 1: betting, 2: waiting, 3: fighting, 4: waitingJackpot, 5: end
    function getStatus() public view returns (uint) {
        if (pause || block.timestamp < baseTime) {
            return 0;
        }

        uint pastTime = block.timestamp - baseTime;
        uint roundId = currentRoundId();
        uint roundStart = roundId * roundTime;
        if ( (pastTime - roundStart) < closeTime ) {
            return 1;
        }

        if (block.number < roundInfo[roundId].fightStartBlock) {
            return 2;
        }

        if (block.number < (roundInfo[roundId].fightStartBlock + eventBlock * (eventCount * 2 - 1))) {
            return 3;
        }

        uint posRandom = IPosRandom(POS_RANDOM_ADDRESS).getRandomNumberByEpochId(block.timestamp / 3600 / 24 + 1);
        if (posRandom == 0) {
            return 4;
        }

        return 5;
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
