const NFTFactoryDelegate = artifacts.require('NFTFactoryDelegate');
const ZooToken = artifacts.require('ZooToken');
const ZooNFT = artifacts.require('ZooNFT');
const ZoorenaDelegate = artifacts.require('ZoorenaDelegate');
const TestOracle = artifacts.require('TestOracle');
const TestPosRandom = artifacts.require('TestPosRandom');

const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');


const assert = require('assert');
const koSleep = require('ko-sleep');

async function shouldFailed(func) {
  try {
    let ret = await func;
    assert.fail('never go here');
  } catch (e) {
    assert.ok(e.message.match(/revert/));
  }
}

contract("Zoorena", ([alice, lucy, jack, tom, molin, dev, robot]) => {
  let zoorena;
  let nft;
  let zoo;
  beforeEach(async ()=>{
    zoo = await ZooToken.new();
    zoo.mint(alice, '1000000');
    zoo.mint(lucy, '1000000');
    zoo.mint(jack, '1000000');
    zoo.mint(tom, '1000000');
    zoo.mint(molin, '1000000');
    zoo.mint(dev, '100');

    nft = await ZooNFT.new();
    await nft.initialize(dev);
    nftFactory = await NFTFactoryDelegate.new();
    await nftFactory.initialize(dev, zoo.address, nft.address);
    await nft.setNFTFactory(nftFactory.address, {from: dev});

    let posRandom = await TestPosRandom.new();
    zoorena = await ZoorenaDelegate.new();
    await zoorena.initialize(dev, zoo.address, nftFactory.address, nft.address, posRandom.address);
    await nft.setNFTFactory(zoorena.address, {from: dev});
    
    zoo.approve(zoorena.address, '10000000000000000', {from: alice});
    zoo.approve(zoorena.address, '1000000', {from: lucy});
    zoo.approve(zoorena.address, '1000000', {from: jack});
    zoo.approve(zoorena.address, '1000000', {from: tom});
    zoo.approve(zoorena.address, '1000000', {from: molin});
    zoo.approve(zoorena.address, '1000000', {from: dev});

    await nftFactory.configChestPrice('3000', {from: dev});
    await nftFactory.configDynamicPrice(10, 2000, 4000, {from: dev});

    await zoorena.configRobot(robot, {from: dev});
    let oracle = await TestOracle.new();
    await zoorena.configOracle(oracle.address, {from: dev});

    await zoorena.configEventOptions(0, 2, {from: dev});
    await zoorena.configEventOptions(1, 4, {from: dev});
    await zoorena.configEventOptions(2, 8, {from: dev});
    await zoorena.configEventOptions(3, 4, {from: dev});
    await zoorena.configEventOptions(4, 2, {from: dev});
    await zoorena.configEventOptions(5, 4, {from: dev});
    await zoorena.configEventOptions(6, 8, {from: dev});
    await zoorena.configEventOptions(7, 10, {from: dev});
    await zoorena.configEventOptions(8, 3, {from: dev});
  });

  it("should success when config time", async ()=>{
    await zoorena.configTime(parseInt(Date.now()/1000), 100, 30, {from: dev});
  });

  it("should success when bet in correct time", async ()=>{
    await zoorena.configTime(parseInt(Date.now()/1000), 100, 30, {from: dev});
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(0, 1);
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(1, 1);
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(2, 1);
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(3, 1);
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(4, 1);
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(5, 1);
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(6, 1);
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(7, 1);
    console.log((await zoo.balanceOf(alice)).toString());
    await zoorena.bet(8, 1);
  });

  it("should success when call fightStart from robot", async ()=>{
    await zoorena.configTime(parseInt(Date.now()/1000) + 3, 100, 5, {from: dev});
    let blockNumber = await web3.eth.getBlockNumber();
    await zoorena.fightStart(0, blockNumber+3, {from: robot});
  });

  it("should failed when call fightStart from not robot", async ()=>{
    await zoorena.configTime(parseInt(Date.now()/1000) + 3, 100, 5, {from: dev});
    let blockNumber = await web3.eth.getBlockNumber();
    shouldFailed(zoorena.fightStart(0, blockNumber+3));
  });

  it("should failed when bet in closed time", async ()=>{
    await zoorena.configTime(parseInt(Date.now()/1000) + 3, 100, 5, {from: dev});
    let blockNumber = await web3.eth.getBlockNumber();
    await zoorena.fightStart(0, blockNumber+20, {from: robot});
    let balance = (await zoo.balanceOf(alice)).toString();
    for (let i=0; i<30; i++) {
      await koSleep(1000);
      await time.advanceBlock();
      console.log((await zoorena.getStatus()).toString());
    }

    shouldFailed(zoorena.bet(0, 1));
    shouldFailed(zoorena.bet(1, 1));
    shouldFailed(zoorena.bet(2, 1));
    shouldFailed(zoorena.bet(3, 1));
    shouldFailed(zoorena.bet(4, 1));
    shouldFailed(zoorena.bet(5, 1));
    shouldFailed(zoorena.bet(6, 1));
    shouldFailed(zoorena.bet(7, 1));
    shouldFailed(zoorena.bet(8, 1));
    assert.strictEqual(balance, (await zoo.balanceOf(alice)).toString());
  });

});

