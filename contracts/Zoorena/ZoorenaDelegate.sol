// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ZoorenaStorage.sol";

interface INftFactory {
    function queryGoldenPrice() external view returns (uint);
    function externalRequestMint(address user, uint chestType, uint _price) external;
}

interface IZooTokenBurn {
    function burn(uint256 _amount) external;
}

interface IZooNFTBoost {
    // scaled 1e12
    function getBoosting(uint _tokenId) external view returns (uint);
    function mint(uint tokenId, uint _level, uint _category, uint _item, uint _random) external;
    function totalSupply() external view returns (uint);
    function itemSupply(uint _level, uint _category, uint _item) external view returns (uint);
}

interface IPrivateSeedOracle {
    function inputSeed(uint seed_) external;
}

contract ZoorenaDelegate is Initializable, AccessControl, ERC721Holder, ZoorenaStorage {
    
    // scale of power point, 10000 point = 10000e10
    uint public constant POWER_SCALE = 1e10;

    bytes32 public constant ROBOT_ROLE = keccak256("ROBOT_ROLE");

    // 9.  0: join clan, 1:....
    uint public constant eventCount = 9;

    // time for each event
    uint public constant eventBlock = 8;

    uint public constant personPower = 10;

    // init power point for both
    uint public constant initPower = 0;

    event Bet(address indexed user, uint indexed roundId, uint indexed eventId, uint selection);

    event FightStart(uint indexed roundId, uint indexed fightStartBlock);

    event MintNFT(uint indexed level, uint indexed category, uint indexed item, uint random, uint tokenId, uint itemSupply, address user);

    event ClaimEvent(address indexed user, uint indexed roundId, uint indexed eventId);

    event ClaimJackpot(address indexed user, uint indexed roundId, uint indexed amount);

    event AddTicket(uint indexed roundId, address indexed user, uint indexed side, uint ticket);

    // _posRandomSC should be address(0x262)
    function initialize(address admin, address _playToken, address _nftFactory, address _zooNFT, address _posRandomSC) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(ROBOT_ROLE, DEFAULT_ADMIN_ROLE);

        playToken = _playToken;
        nftFactory = _nftFactory;
        zooNFT = _zooNFT;
        POS_RANDOM_ADDRESS = _posRandomSC;

        discount0 = 5000;
        discount1 = 10000;
    }

    function halt(bool _pause) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        pause = _pause;
    }

    function configRobot(address robot) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(ROBOT_ROLE, robot);
    }

    function configDiscount(uint _discount0, uint _discount1) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        discount0 = _discount0;
        discount1 = _discount1;
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
        require(tx.origin == msg.sender, "not allow contract call");
        require(!pause, "game paused");
        require(selection != 0 && selection != 100, "selection error");
        require(eventId <= eventCount, "event Id error");
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
        require(tx.origin == msg.sender, "not allow contract call");
        require(!pause, "game paused");
        require(getStatus() == 1, "betting closed");
        require(side >=1 && side <= 2, "side error");
        require(tokenId != 0, "NFT error");
        require(userNft[msg.sender] == 0, "need withdraw first");
        uint roundId = currentRoundId();

        IERC721(zooNFT).safeTransferFrom(msg.sender, address(this), tokenId);
        uint boost = IZooNFTBoost(zooNFT).getBoosting(tokenId);
        if (side == 1) {
            roundInfo[roundId].leftPower = roundInfo[roundId].leftPower.add(boost);
            roundInfo[roundId].leftNftCount++;
        } else {
            roundInfo[roundId].rightPower = roundInfo[roundId].rightPower.add(boost);
            roundInfo[roundId].rightNftCount++;
        }

        userNft[msg.sender] = tokenId;
    }

    function withdrawNFT() external {
        require(tx.origin == msg.sender, "not allow contract call");
        require(!pause, "game paused");
        uint status = getStatus();
        require(status != 2 && status != 3, "can not withdraw in fighting");
        uint roundId = currentRoundId();
        uint tokenId = userNft[msg.sender];
        require(tokenId != 0, "no NFT found");
        uint boost = IZooNFTBoost(zooNFT).getBoosting(tokenId);

        if (userEvent[roundId][msg.sender][0] == 1 && status == 1) {
            roundInfo[roundId].leftPower = roundInfo[roundId].leftPower.sub(boost);
            if (roundInfo[roundId].leftNftCount > 0) {
                roundInfo[roundId].leftNftCount--;
            }
        }

        if (userEvent[roundId][msg.sender][0] == 2 && status == 1) {
            roundInfo[roundId].rightPower = roundInfo[roundId].rightPower.sub(boost);
            if (roundInfo[roundId].rightNftCount > 0) {
                roundInfo[roundId].rightNftCount--;
            }
        }

        userNft[msg.sender] = 0;

        IERC721(zooNFT).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // called by robot
    function fightStart(uint roundId, uint fightStartBlock, uint _seed) external {
        require(hasRole(ROBOT_ROLE, msg.sender));
        require(!pause, "game paused");
        
        roundInfo[roundId].fightStartBlock = fightStartBlock;

        uint randomSeed = uint(keccak256(abi.encode(blockhash(block.number - 1), blockhash(block.number - 2), blockhash(block.number - 3), block.coinbase, block.timestamp, _seed)));

        roundInfo[roundId].randomSeed = randomSeed;

        roundInfo[roundId].timestamp = block.timestamp;

        emit FightStart(roundId, fightStartBlock);
    }

    // event from 0 to 8
    // returns: 0: result waiting, 1~10 the right event
    function getEventResult(uint roundId, uint eventId) public view returns(uint) {
        uint startBlock = roundInfo[roundId].fightStartBlock;
        uint randomSeed = roundInfo[roundId].randomSeed;
        // fight not start
        if (startBlock == 0 || roundInfo[roundId].randomSeed == 0) {
            return 0;
        }

        // out of range
        if (eventId > eventCount) {
            return 0;
        }

        // fight result
        if (eventId == 0) {
            return getFightResult(roundId);
        }

        uint eventRunBlock = startBlock + (eventId*2 - 1) * eventBlock;

        if (block.number < eventRunBlock) {
            return 0;
        }

        uint random = uint(keccak256(abi.encode(eventRunBlock, eventRunBlock * 66, randomSeed)));
        uint opCnt = eventOptions[eventId];
        return random.mod(opCnt).add(1); 
    }

    function getFightingReport(uint roundId, uint reportId) public view returns(bool done, uint leftDown, uint rightDown) {
        (done, leftDown, rightDown) =  _getFightingReport(roundId, reportId);
        if (reportId == eventCount - 1 && done) {
            uint16 totalLeft;
            uint16 totalRight;
            (totalLeft, totalRight) = getTotalHpDown(roundId, reportId);

            if ((totalLeft + leftDown) == (totalRight + rightDown)) {
                uint finalRandom = uint(keccak256(abi.encode(totalLeft, totalRight, leftDown, rightDown))).mod(2);
                if (finalRandom == 0) {
                    leftDown = leftDown + 1;
                } else {
                    rightDown = rightDown + 1;
                }
            }
        } 
    }

    function _getFightingReport(uint roundId, uint reportId) public view returns(bool done, uint leftDown, uint rightDown) {
        uint startBlock = roundInfo[roundId].fightStartBlock;
        uint randomSeed = roundInfo[roundId].randomSeed;
        // fight not start
        if (startBlock == 0 || roundInfo[roundId].randomSeed == 0) {
            done = false;
            return (done, leftDown, rightDown);
        }

        // out of range
        if (reportId >= eventCount) {
            done = false;
            return (done, leftDown, rightDown);
        }

        uint fightBlock = startBlock + (reportId*2) * eventBlock;

        if (block.number < fightBlock) {
            done = false;
            return (done, leftDown, rightDown);
        }

        uint random = uint(keccak256(abi.encode(fightBlock, fightBlock * 55, randomSeed)));

        uint _initPower = initPower;
        if (roundId <= 4) {
            _initPower = 10000;
        }

        uint leftPower = roundInfo[roundId].leftPower.add(_initPower.mul(POWER_SCALE));
        uint rightPower = roundInfo[roundId].rightPower.add(_initPower.mul(POWER_SCALE));
        uint winnerCode = random.mod(leftPower.add(rightPower));

        uint baseDamage = uint(keccak256(abi.encode(random))).mod(5);
        uint damageDifference = uint(keccak256(abi.encode(random, baseDamage))).mod(5);

        done = true;
        
        // right win
        if (winnerCode >= leftPower) {
            leftDown = baseDamage + damageDifference;
            rightDown = baseDamage;
        } else { // left win
            leftDown = baseDamage;
            rightDown = baseDamage + damageDifference;
        }

        return (done, leftDown, rightDown);
    }

    function getTotalHpDown(uint roundId, uint reportId) public view returns (uint16 totalLeft, uint16 totalRight) {
        uint _leftDown = 0;
        uint _rightDown = 0;
        for (uint i=0; i<reportId; i++) {
            (, _leftDown, _rightDown) = getFightingReport(roundId, i);
            totalLeft = totalLeft + uint8(_leftDown);
            totalRight = totalRight + uint8(_rightDown);
        }
    }

    function getFightResult(uint roundId) public view returns (uint) {
        uint leftLife = 100;
        uint rightLife = 100;
        uint leftDown;
        uint rightDown;
        bool done = false;
        for (uint i=0; i<eventCount; i++) {
            (done, leftDown, rightDown) = getFightingReport(roundId, i);

            if (!done) {
                return 0;
            }

            if (leftLife > leftDown) {
                leftLife = leftLife - leftDown;
            } else {
                leftLife = 0;
            }

            if (rightLife > rightDown) {
                rightLife = rightLife - rightDown;
            } else {
                rightLife = 0;
            }
        }

        if (leftLife > rightLife) {
            return 1;
        } else {
            return 2;
        }
    }

    function claimEvent(uint roundId, uint eventId, address user) external {
        require(tx.origin == msg.sender, "not allow contract call");
        require(!pause, "game paused");

        uint userSelection = userEvent[roundId][user][eventId];
        require(userSelection > 0, "User not bet");
        bool golden = false;
        if (userSelection > 100) {
            golden = true;
            userSelection = userSelection - 100;
        }

        uint eventResult = getEventResult(roundId, eventId);
        require(userSelection == eventResult, "User bet error");

        require(!eventClaimed[roundId][user][eventId], "Already claimed");

        eventClaimed[roundId][user][eventId] = true;

        uint price = userBetPrice[roundId][user][eventId];

        if (golden) {
            INftFactory(nftFactory).externalRequestMint(user, 2, price);
        } else {
            INftFactory(nftFactory).externalRequestMint(user, 3, price);
        }

        emit ClaimEvent(user, roundId, eventId);
    }

    function getJackpot(uint roundId) public view returns(bool done, uint[] memory winners) {
        uint calcTime = 0;
        if (roundId == 0) {
            calcTime = baseTime + roundTime*roundId;
        } else {
            calcTime = roundInfo[roundId].timestamp;
        }

        uint posRandom = getRandomByEpochId(calcTime / 3600 / 24 + 1);
        if (posRandom == 0) {
            return (done, winners);
        }

        uint fightResult = getFightResult(roundId);
        if (fightResult == 0) {
            return (done, winners);
        }

        winners = new uint[](3);

        // left win
        if (fightResult == 1) {
            uint leftCnt = leftTicketCount[roundId];
            if (leftCnt == 0) {
                return (done, winners);
            } 

            done = true;

            if (leftCnt == 1) {
                winners[0] = leftTickets[roundId][0];
                winners[1] = leftTickets[roundId][0];
                winners[2] = leftTickets[roundId][0];
                return (done, winners);
            }

            if (leftCnt == 2) {
                winners[0] = leftTickets[roundId][0];
                winners[1] = leftTickets[roundId][1];
                winners[2] = 0;
                return (done, winners);
            }

            if (leftCnt == 3) {
                winners[0] = leftTickets[roundId][0];
                winners[1] = leftTickets[roundId][1];
                winners[2] = leftTickets[roundId][2];
                return (done, winners);
            }

            winners[0] = leftTickets[roundId][posRandom.mod(leftCnt)];

            for (uint i=0; i<100; i++) {
                winners[1] = leftTickets[roundId][uint(keccak256(abi.encode(posRandom))).mod(leftCnt)];
                if (winners[1] != winners[0]) {
                    break;
                }
            }

            for (uint i=0; i<100; i++) {
                winners[2] = leftTickets[roundId][uint(keccak256(abi.encode(posRandom, posRandom))).mod(leftCnt)];
                if (winners[2] != winners[0] && winners[2] != winners[1]) {
                    break;
                }
            }

        } else {
            uint rightCnt = rightTicketCount[roundId];
            if (rightCnt == 0) {
                return (done, winners);
            } 

            done = true;

            if (rightCnt == 1) {
                winners[0] = rightTickets[roundId][0];
                winners[1] = rightTickets[roundId][0];
                winners[2] = rightTickets[roundId][0];
                return (done, winners);
            }

            if (rightCnt == 2) {
                winners[0] = rightTickets[roundId][0];
                winners[1] = rightTickets[roundId][1];
                winners[2] = 0;
                return (done, winners);
            }

            if (rightCnt == 3) {
                winners[0] = rightTickets[roundId][0];
                winners[1] = rightTickets[roundId][1];
                winners[2] = rightTickets[roundId][2];
                return (done, winners);
            }

            winners[0] = rightTickets[roundId][posRandom.mod(rightCnt)];

            for (uint i=0; i<100; i++) {
                winners[1] = rightTickets[roundId][uint(keccak256(abi.encode(posRandom))).mod(rightCnt)];
                if (winners[1] != winners[0]) {
                    break;
                }
            }

            for (uint i=0; i<100; i++) {
                winners[2] = rightTickets[roundId][uint(keccak256(abi.encode(posRandom, posRandom))).mod(rightCnt)];
                if (winners[2] != winners[0] && winners[2] != winners[1]) {
                    break;
                }
            }
        }
    }

    function claimJackpot(uint roundId) external {
        require(tx.origin == msg.sender, "not allow contract call");
        require(!pause, "game paused");
        require(roundId <= currentRoundId(), "not arrived");
        bool done;
        uint[] memory winners;
        (done, winners) = getJackpot(roundId);
        require(done, "Not finish");
        uint balance = IERC20(playToken).balanceOf(address(this));
        uint amount = balance.div(3);

        for (uint i=0; i<3; i++) {
            uint ticket = winners[i];
            if (ticket != 0 && !jackpotClaimed[roundId][ticket]) {
                jackpotClaimed[roundId][ticket] = true;
                IERC20(playToken).transfer(ticketOwner[ticket], amount);
                emit ClaimJackpot(ticketOwner[ticket], roundId, amount);
            }
        }
    }

    function currentRoundId() public view returns(uint) {
        return (block.timestamp - baseTime) / roundTime;
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

        if (block.number < roundInfo[roundId].fightStartBlock || roundInfo[roundId].fightStartBlock == 0) {
            return 2;
        }

        if (block.number < (roundInfo[roundId].fightStartBlock + eventBlock * (eventCount * 2))) {
            return 3;
        }

        uint posRandom = getRandomByEpochId(block.timestamp / 3600 / 24 + 1);
        if (posRandom == 0) {
            return 4;
        }

        return 5;
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

        // discount
        goldenPrice = goldenPrice.mul(discount0).div(discount1);

        uint silverPrice = goldenPrice.div(10);
        uint _bet;
        if (golden) {
            _bet = goldenPrice.div(eventOptions[eventId]).add(goldenPrice.div(20));
        } else {
            _bet = silverPrice.div(eventOptions[eventId]).add(silverPrice.div(20));
        }

        // cost 55% zoo to get a silver chest
        IERC20(playToken).transferFrom(msg.sender, address(this), _bet);
        // burn 50%
        IZooTokenBurn(playToken).burn(_bet.div(2));

        userBetPrice[roundId][msg.sender][eventId] = _bet;
        
        roundInfo[roundId].jackpot = roundInfo[roundId].jackpot.add(_bet.div(2));

        uint ticketCount = 120 / eventOptions[eventId];
        if (golden) {
            addTicket(roundId, userEvent[roundId][msg.sender][0], msg.sender, ticketCount);
        } else {
            if (ticketCount >= 20) {
                ticketCount = ticketCount / 10;
            } else if (ticketCount == 15) {
                ticketCount = 2;
            } else {
                ticketCount = 1;
            }
            addTicket(roundId, userEvent[roundId][msg.sender][0], msg.sender, ticketCount);
        }
    }

    function joinClan(uint eventId, uint selection, uint roundId) internal {
        require(selection > 0 && selection <3, "selection out of range");
        userEvent[roundId][msg.sender][eventId] = selection;

        uint goldenPrice = INftFactory(nftFactory).queryGoldenPrice();

        // discount
        goldenPrice = goldenPrice.mul(discount0).div(discount1);

        uint silverPrice = goldenPrice.div(10);
        uint ticket = silverPrice.div(5);

        // cost 55% zoo to get a silver chest
        IERC20(playToken).transferFrom(msg.sender, address(this), ticket);
        // burn 50%
        IZooTokenBurn(playToken).burn(ticket.div(2));

        userBetPrice[roundId][msg.sender][0] = ticket;
        
        roundInfo[roundId].jackpot = roundInfo[roundId].jackpot.add(ticket.div(2));
        uint boost = 0;
        uint tokenId = userNft[msg.sender];
        if (tokenId != 0) {
            boost = IZooNFTBoost(zooNFT).getBoosting(tokenId);
        }

        if (selection == 1) {
            leftUser[roundId][roundInfo[roundId].leftUserCount] = msg.sender;
            roundInfo[roundId].leftUserCount++;
            roundInfo[roundId].leftPower = roundInfo[roundId].leftPower.add(personPower.mul(POWER_SCALE)).add(boost);
            if (tokenId != 0) {
                roundInfo[roundId].leftNftCount++;
            }
        } else {
            rightUser[roundId][roundInfo[roundId].rightUserCount] = msg.sender;
            roundInfo[roundId].rightUserCount++;
            roundInfo[roundId].rightPower = roundInfo[roundId].rightPower.add(personPower.mul(POWER_SCALE)).add(boost);
            if (tokenId != 0) {
                roundInfo[roundId].rightNftCount++;
            }
        }

        addTicket(roundId, selection, msg.sender, 3);
    }

    function addTicket(uint roundId, uint side, address user, uint count) private {
        uint currentCount;
        uint ticket;
        for (uint i=0; i<count; i++) {
            if (side == 1) {
                currentCount = leftTicketCount[roundId];
                // roundId * 1e6 + side * 1e5 + count
                ticket = roundId.mul(1e6).add(side.mul(1e5)).add(currentCount);
                leftTickets[roundId][currentCount] = ticket;
                ticketOwner[ticket] = user;
                leftTicketCount[roundId]++;
            } else {
                currentCount = rightTicketCount[roundId];
                // roundId * 1e6 + side * 1e5 + count
                ticket = roundId.mul(1e6).add(side.mul(1e5)).add(currentCount);
                rightTickets[roundId][currentCount] = ticket;
                ticketOwner[ticket] = user;
                rightTicketCount[roundId]++;
            }

            userTickets[roundId][user][userTicketCount[roundId][user]] = ticket;
            userTicketCount[roundId][user]++;

            emit AddTicket(roundId, user, side, ticket);
        }
    }

    function getRandomByEpochId(uint256 epochId)
        public
        view
        returns (uint256)
    {
        (bool success, bytes memory data) = address(POS_RANDOM_ADDRESS).staticcall(abi.encodeWithSignature("getRandomNumberByEpochId(uint256)", epochId));
        if (success) {
            return uint256(abi.decode(data, (uint)));
        } else {
            return 0;
        }
    }
}
