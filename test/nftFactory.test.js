const NFTFactoryDelegate = artifacts.require('NFTFactoryDelegate');
const ZooToken = artifacts.require('ZooToken');
const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const assert = require('assert');
const { expectRevert, time } = require('@openzeppelin/test-helpers');
const sleep = require('ko-sleep');
const { strictEqual } = require('assert');

contract("NFTFactoryDelegate", ([alice, lucy, jack, tom, molin, dev]) => {
  let nftFactory;
  let zoo;
  let nft;
  beforeEach(async ()=>{
    zoo = await ZooToken.new();
    zoo.mint(alice, '1000000');
    zoo.mint(lucy, '1000000');
    zoo.mint(jack, '1000000');
    zoo.mint(tom, '1000000');
    zoo.mint(molin, '1000000');
    zoo.mint(dev, '100');

    nft = await ZooNFTDelegate.new();
    await nft.initialize(dev);
    nftFactory = await NFTFactoryDelegate.new();
    await nftFactory.initialize(dev, zoo.address, nft.address);
    await nft.setNFTFactory(nftFactory.address, {from: dev});
    
    zoo.approve(nftFactory.address, '10000000000000000', {from: alice});
    zoo.approve(nftFactory.address, '1000000', {from: lucy});
    zoo.approve(nftFactory.address, '1000000', {from: jack});
    zoo.approve(nftFactory.address, '1000000', {from: tom});
    zoo.approve(nftFactory.address, '1000000', {from: molin});
    zoo.approve(nftFactory.address, '1000000', {from: dev});

    await nftFactory.configChestPrice('30000', {from: dev});
    await nftFactory.configDynamicPrice(10, 20000, 40000, {from: dev});
  });

  it("should success when buy silver chest", async () => { 
    let ret;
    let total = 0;
    let price = '3000';
    for (let i=0; i<10; i++) {
      ret = await nftFactory.buySilverChest({from: alice});
      total += Number(ret.logs[1].args.level.toString());
      // console.log('tokenId', ret.logs[1].args.tokenId.toString(), 'level', ret.logs[1].args.level.toString(), 'price', ret.logs[0].args.price.toString());
      price = (price * 1.01).toFixed(0);
    }

    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '968618');

    assert.ok(Number(await nft.balanceOf(alice)) >= 1);

    assert.ok(total >= 1, "nft level error");

    // console.log(total, Number(await nft.balanceOf(alice)));
  });

  it("should failed when buy silver chest without enough zoo", async () => {
    try {
      let ret = await nftFactory.buySilverChest({from: dev});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when buy golden chest", async () => { 
    let ret;
    let price = '30000';
    await nftFactory.configChestPrice(price, {from: dev});
    ret = await nftFactory.buyGoldenChest({from: alice});
    assert.ok(Number(ret.logs[0].args.level.toString()) >= 1);
    assert.strictEqual(ret.logs[1].args.price.toString(), price);
    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '970000');
    assert.ok(Number(await nft.balanceOf(alice)) == 1);
  });

  it("should failed when buy golden chest without enough zoo", async () => {
    try {
      let ret = await nftFactory.buyGoldenChest({from: dev});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when dynamic price config", async () => { 
    await nftFactory.configDynamicPrice(10, 20000, 40000, {from: dev});
  });

  it("should failed when dynamic price config without access", async () => {
    try {
      await nftFactory.configDynamicPrice(10, 20000, 40000, {from: alice});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when golden chest price config", async () => { 
    await nftFactory.configChestPrice('10000', {from: dev});
    ret = await nftFactory.buyGoldenChest({from: alice});
    assert.strictEqual(ret.logs[1].args.price.toString(), '10000');
  });

  it("should failed when golden chest price config without access", async () => {
    try {
      await nftFactory.configChestPrice('30000', {from: alice});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when dynamic price auto change up", async () => { 
    let ret;
    let price = '30000';
    await nftFactory.configChestPrice('30000', {from: dev});
    await nftFactory.configDynamicPrice(100, 29000, 31000, {from: dev});

    for (let i=0; i<6; i++) {
      ret = await nftFactory.buyGoldenChest({from: alice});
      assert.ok(Number(ret.logs[0].args.level.toString()) >= 1);
      // console.log(ret.logs[1].args.price.toString(), price);
      assert.strictEqual(ret.logs[1].args.price.toString(), price);
      price = Math.floor(price * 1.01).toString();
      if (Number(price) > 31000) {
        price = '31000';
      }
    }
    // console.log((await zoo.balanceOf(alice)).toString());
    assert.ok(Number(await nft.balanceOf(alice)) == 6);
  });

  it("should success when dynamic price auto change down", async () => {
    await nftFactory.configChestPrice('30000', {from: dev});
    await nftFactory.configDynamicPrice(3, 29000, 31000, {from: dev});
    let price = '30000';
    await sleep(1500);
    for (let i=0; i<6; i++) {
      // console.log((await nftFactory.queryGoldenPrice()).toString(), price);
      assert.strictEqual((await nftFactory.queryGoldenPrice()).toString(), price);
      await time.advanceBlock();
      await sleep(3000);
      price = Math.floor(price*0.99).toString();
      if (Number(price)<29000) {
        price = '29000';
      }
    }
  });

  it("should success when configStakePlanCount", async () => { 
    await nftFactory.configStakePlanCount('1', {from: dev});
  });

  it("should failed when configStakePlanCount without access", async () => {
    try {
      await nftFactory.configStakePlanCount('1', {from: alice});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when configStakePlanInfo", async () => { 
    await nftFactory.configStakePlanInfo('0', 10, 1, 3600, {from: dev});
  });

  it("should failed when configStakePlanInfo without access", async () => {
    try {
      await nftFactory.configStakePlanInfo('0', 10, 1, 3600, {from: alice});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when stake type 0 and withdraw", async () => { 
    await nftFactory.configStakePlanInfo('0', 10, 1, 3, {from: dev});
    await nftFactory.stakeZoo('0', {from: alice});
    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '700000');
    assert.strictEqual((await zoo.balanceOf(nftFactory.address)).toString(), '300000');

    await sleep(4000);

    let ret = await nftFactory.stakeClaim('0', {from: alice});
    // console.log(JSON.stringify(ret.logs[1], null, 2));
    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '1000000');
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    
  });

  it("should failed when stake type 0 and withdraw in lock time", async () => {
    await nftFactory.configStakePlanInfo('0', 10, 1, 3, {from: dev});
    await nftFactory.stakeZoo('0', {from: alice});
    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '700000');
    assert.strictEqual((await zoo.balanceOf(nftFactory.address)).toString(), '300000');

    try {
      let ret = await nftFactory.stakeClaim('0', {from: alice});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when check stake", async () => { 
    assert.strictEqual(await nftFactory.isStakeable(0), true);
    await nftFactory.stakeZoo('0', {from: alice});
    assert.strictEqual(await nftFactory.isStakeable(0), false);
  });

  it("should success when check claim", async () => { 
    await nftFactory.configStakePlanInfo('0', 10, 1, 3, {from: dev});
    assert.strictEqual(await nftFactory.isStakeFinished(0), true);
    await nftFactory.stakeZoo('0', {from: alice});
    assert.strictEqual(await nftFactory.isStakeFinished(0), false);
    await sleep(4000);
    await time.advanceBlock();
    assert.strictEqual(await nftFactory.isStakeFinished(0), true);
  });
});
