const { expectRevert, time } = require('@openzeppelin/test-helpers');
const ZooToken = artifacts.require('ZooToken');
const ZooKeeperFarming = artifacts.require('ZooKeeperFarming');
const MockERC20 = artifacts.require('MockERC20');
const BoostingDelegate = artifacts.require('BoostingDelegate');
const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const WaspToken = artifacts.require('WaspToken');
const WanSwapFarm = artifacts.require('WanSwapFarm');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const assert = require('assert');
const sleep = require('ko-sleep');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'


contract('ZooKeeperFarming', ([alice, bob, carol, dev, minter]) => {
  let zoo;
  let nft;
  let boosting;
  let farming;
  let wasp;
  let wanswapFarm;
  let lp1;
  let lp2;
  let lp3;
  let lp4;

  beforeEach(async () => {
    zoo = await ZooToken.new();
    await zoo.mint(alice, '1000000');
    await zoo.mint(bob, '1000000');
    await zoo.mint(carol, '1000000');
    await zoo.mint(dev, '1000000');
    await zoo.mint(minter, '1000000');

    lp1 = await MockERC20.new('LP', 'LP', 18, 10000000);
    lp2 = await MockERC20.new('LP', 'LP', 18, 10000000);
    lp3 = await MockERC20.new('LP', 'LP', 18, 10000000);
    lp4 = await MockERC20.new('LP', 'LP', 18, 10000000);



    boosting = await BoostingDelegate.new();
    await boosting.initialize(alice);
    

    nft = await ZooNFTDelegate.new();
    await nft.initialize(dev);
    await nft.setNFTFactory(alice, {from: dev});
    await nft.setNFTFactory(bob, {from: dev});
    // ------
    let pr =[];
    for (let i=1; i<=4; i++) {
      for (let c=1; c<=6; c++) {
        for (let e=1; e<=5; e++) {
          let ret = await nft.getLevelChance(i, c, e);
          pr.push(Number(Number(ret.toString())/1e10).toFixed(5));
        }
      }
    }
    
    function unique (arr) {
      return Array.from(new Set(arr))
    }

    let pn = unique(pr.sort().reverse());

    let chances = [];
    let boosts = [];
    let reduces = [];
    for(let i=0; i < pn.length; i++) {
      chances.push('0x' + Number((pn[i]*1e10).toFixed(0)).toString(16));
      boosts.push('0x' + Number(((i+1)*1e10).toFixed(0)).toString(16));
      reduces.push('0x' + Number((1e10 + i*2e9).toFixed(0)).toString(16));
    }

    await nft.setBoostMap(chances, boosts, reduces, {from: dev});
    // ------

    await nft.setBaseURI('https://gateway.pinata.cloud/ipfs/', {from: dev});
    await nft.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json', {from: dev});
    await nft.setNftURI(2, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json', {from: dev});
    await nft.setNftURI(3, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json', {from: dev});
    await nft.mint(1, 1, 1, 1, 100, {from: alice});
    await nft.mint(2, 2, 2, 1, 100, {from: alice});
    await nft.mint(3, 3, 1, 1, 100, {from: bob});

    wasp = await WaspToken.new();
    wanswapFarm = await WanSwapFarm.new(
      wasp.address,
      dev,
      10,
      0,
      0,
      0,
      999999
    );
    await wasp.transferOwnership(wanswapFarm.address);

    await wanswapFarm.add(100, lp1.address, true);
    await wanswapFarm.add(100, lp2.address, true);

    farming = await ZooKeeperFarming.new(
      zoo.address,
      dev,
      boosting.address,
      10,
      0,
      99999,
      wanswapFarm.address,
      wasp.address
    );

    await boosting.setFarmingAddr(farming.address);
    await boosting.setNFTAddress(nft.address);
    await boosting.setBoostScale(8 * 3600 * 24, '2000000000', '4000000000');
    await nft.setApprovalForAll(boosting.address, true, { from: alice });
    await nft.setApprovalForAll(boosting.address, true, { from: bob });

    await lp1.transfer(bob, '1000000');
    await lp1.approve(farming.address, '1000000', {from: alice});
    await lp1.approve(farming.address, '1000000', {from: bob});

    await lp2.transfer(carol, '1000000');
    await lp2.transfer(dev, '1000000');
    await lp2.approve(farming.address, '1000000', {from: carol});
    await lp2.approve(farming.address, '1000000', {from: dev});

    await lp3.transfer(minter, '1000000');
    await lp3.transfer(dev, '1000000');
    await lp3.approve(farming.address, '1000000', {from: minter});
    await lp3.approve(farming.address, '1000000', {from: dev});

    await lp4.transfer(bob, '1000000');
    await lp4.approve(farming.address, '1000000', {from: alice});
    await lp4.approve(farming.address, '1000000', {from: bob});    

    await zoo.transferOwnership(farming.address);
  });

  it("should success when transferOwner", async ()=>{
    await farming.transferOwnership(dev);
  });

  it("should failed when transferOwner without access", async ()=>{
    try {
      await farming.transferOwnership(dev, {from: dev});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when add pool", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.add(100, lp2.address, true, 1, true);
    await farming.add(100, lp3.address, false, 0, false);
    await farming.add(100, lp4.address, true, 0, false);
  });

  it("should failed when add pool without access", async ()=>{
    try {
      await farming.add(100, lp1.address, true, 0, false, {from: dev});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when update pool", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.set(0, 200, true);
    assert.strictEqual((await farming.totalAllocPoint()).toString(), '200');
  });

  it("should failed when update pool without access", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    try {
      await farming.set(0, 200, true, {from: dev});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when enable/disable dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.add(100, lp2.address, true, 0, false);
    await farming.setWaspPid(0, 0, true);
    await farming.setWaspPid(0, 0, false);
    await farming.setWaspPid(1, 1, true);
    await farming.setWaspPid(1, 1, false);
  });

  it("should failed when enable/disable dual farming without access", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    try { 
      await farming.setWaspPid(0, 0, true, {from: dev});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when deposit 0", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 0, 0, 0, {from: bob});
  });

  it("should success when deposit amount", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
  });

  it("should success when pendingZoo", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '10');
  });

  it("should success when withdraw 0", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.withdraw(0, 0);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await time.advanceBlock();
    await farming.withdraw(0, 0, {from: bob});
  });

  it("should success when withdraw amount", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '999900');
    await farming.withdraw(0, 100, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '1000000');
  });

  it("should success when farming amount", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '10');
    await farming.deposit(0, 100, 0, 0, {from: alice});
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '20');
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingZoo(0, alice)).toString(), '5');
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '25');
  });

  it("should success when multi pool farming 1", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.add(100, lp2.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await farming.deposit(1, 100, 0, 0, {from: carol});
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '5');
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '10');
    assert.strictEqual((await farming.pendingZoo(1, carol)).toString(), '5');
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '15');
    assert.strictEqual((await farming.pendingZoo(1, carol)).toString(), '10');
  });

  it("should success when multi pool farming 2", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.add(400, lp2.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await farming.deposit(1, 100, 0, 0, {from: carol});
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '2');
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '4');
    assert.strictEqual((await farming.pendingZoo(1, carol)).toString(), '8');
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '6');
    assert.strictEqual((await farming.pendingZoo(1, carol)).toString(), '16');
  });



  it("should success when deposit 0 with dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    await farming.deposit(0, 0, 0, 0, {from: bob});
  });

  it("should success when deposit amount with dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    await farming.deposit(0, 100, 0, 0, {from: bob});
  });

  it("should success when pendingZoo with dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingZoo(0, bob)).toString(), '10');
  });

  it("should success when pendingWasp with dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await farming.pendingWasp(0, bob)).toString(), '5');
  });

  it("should success when withdraw 0 with dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    await farming.withdraw(0, 0);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await time.advanceBlock();
    await farming.withdraw(0, 0, {from: bob});
  });

  it("should success when withdraw amount with dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '999900');
    assert.strictEqual((await lp1.balanceOf(farming.address)).toString(), '0');
    assert.strictEqual((await lp1.balanceOf(wanswapFarm.address)).toString(), '100');
    await farming.withdraw(0, 100, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '1000000');
    assert.strictEqual((await lp1.balanceOf(farming.address)).toString(), '0');
    assert.strictEqual((await lp1.balanceOf(wanswapFarm.address)).toString(), '0');
  });

  it("should success when deposit 0 with lock-time", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 0, 3600*24*30, 0, {from: bob});
    ret = await boosting.userInfo(0, bob);
    assert.strictEqual(ret.lockTime.toString(), '0');
  });

  it("should success when deposit 0 with lock longer", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 1000, 3600*24*30, 0, {from: bob});
    ret = await boosting.userInfo(0, bob);
    assert.strictEqual(ret.lockTime.toString(), '2592000');
    await farming.deposit(0, 0, 3600*24*60, 0, {from: bob});
    ret = await boosting.userInfo(0, bob);
    assert.strictEqual(ret.lockTime.toString(), '5184000');
  });

  it("should success when deposit amount with lock-time", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 3600*24*33, 0, {from: bob});
    ret = await boosting.userInfo(0, bob);
    assert.strictEqual(ret.lockTime.toString(), '2851200');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '11');
  });

  it("should success when deposit amount with lock longer", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 1000, 3600*24*30, 0, {from: bob});
    ret = await boosting.userInfo(0, bob);
    assert.strictEqual(ret.lockTime.toString(), '2592000');
    await farming.deposit(0, 1000, 3600*24*60, 0, {from: bob});
    await time.advanceBlock();
    ret = await boosting.userInfo(0, bob);
    assert.strictEqual(ret.lockTime.toString(), '5184000');
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '12');
  });

  it("should success when deposit amount no-lock to lock", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '10');
    await farming.deposit(0, 0, 3600*24*33, 0, {from: bob});
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '11');
  });

  it("should success when withdraw 0 with lock time", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 3600*24*33, 0, {from: bob});
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '11');
    await farming.withdraw(0, 0, {from: bob});
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '11');
  });

  it("should success when withdraw amount with lock time 1", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 3600*24*33, 0, {from: bob});
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '11');
    ret = await boosting.userInfo(0, bob);
    try { 
      await farming.withdraw(0, 100, {from: bob});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '33');
  });

  it("should success when withdraw amount with lock time 2", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 3, 0, {from: bob});
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '10');
    await sleep(5000);
    await time.advanceBlock();
    await farming.withdraw(0, 100, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '1000000');
  });

  it("should success when withdraw amount no-lock to lock 1", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await farming.deposit(0, 100, 3600*24*33, 0, {from: bob});
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '11');
    ret = await boosting.userInfo(0, bob);
    try { 
      await farming.withdraw(0, 100, {from: bob});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '33');
  });

  it("should success when withdraw amount no-lock to lock 2", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 100, 0, 0, {from: bob});
    await farming.deposit(0, 100, 3, 0, {from: bob});
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '10');
    await sleep(5000);
    await time.advanceBlock();
    await farming.withdraw(0, 200, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '1000000');
  });

  it("should success when deposit 0 with NFT", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 0, 0, 1, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '2');
  });

  it("should success when deposit amount with NFT", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 1000, 0, 1, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
  });

  it("should success when deposit 0 no nft to nft", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 1000, 0, 0, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '2');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '10');
    await farming.deposit(0, 0, 0, 2, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '11');
  });

  it("should success when deposit amount no nft to nft", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 1000, 0, 0, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '2');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '10');
    await farming.deposit(0, 1000, 0, 2, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '11');
  });

  it("should success when withdraw 0 with nft", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    await farming.deposit(0, 1000, 0, 2, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '11');
    await time.advanceBlock();
    await farming.withdraw(0, 0, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '0');
  });

  it("should success when withdraw 0 with nft", async ()=>{
    await farming.add(100, lp1.address, true, 0, false);
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '9000000');
    await farming.deposit(0, 1000, 0, 2, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '11');
    await time.advanceBlock();
    await farming.withdraw(0, 1000, {from: alice});
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '0');
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '2');
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '9000000');
  });

  it("deposit 0 with nft,lock-time,dual farming", async()=>{
    await farming.add(100, lp1.address, true, 0, true);
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '9000000');
    await farming.deposit(0, 0, 3600*24*30, 2, {from: alice});
  });

  it("deposit amount with nft,lock-time,dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '9000000');
    await farming.deposit(0, 1000, 3600*24*33, 2, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '12');
    ret = await farming.pendingWasp(0, alice);
    assert.strictEqual(ret.toString(), '5');
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '8999000');

  });

  it("withdraw 0 with nft,lock-time,dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '9000000');
    await farming.deposit(0, 1000, 3600*24*30, 2, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '11');
    ret = await farming.pendingWasp(0, alice);
    assert.strictEqual(ret.toString(), '5');
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '8999000');
    await farming.withdraw(0, 0, {from: alice});
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '0');
    ret = await farming.pendingWasp(0, alice);
    assert.strictEqual(ret.toString(), '0');
    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '1000023');
    assert.strictEqual((await wasp.balanceOf(alice)).toString(), '10');
  });

  it("withdraw amount with nft,lock-time,dual farming", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '9000000');
    await farming.deposit(0, 1000, 3, 2, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '11');
    ret = await farming.pendingWasp(0, alice);
    assert.strictEqual(ret.toString(), '5');
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '8999000');
    await farming.withdraw(0, 0, {from: alice});
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '0');
    ret = await farming.pendingWasp(0, alice);
    assert.strictEqual(ret.toString(), '0');
    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '1000022');
    assert.strictEqual((await wasp.balanceOf(alice)).toString(), '10');
    await sleep(5000);
    await farming.withdraw(0, 1000, {from: alice});
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '9000000');
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '2');
    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '1000033');
    assert.strictEqual((await wasp.balanceOf(alice)).toString(), '15');

  });

  it("team zoo test", async ()=>{
    await farming.add(100, lp1.address, true, 0, true);
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '9000000');
    await farming.deposit(0, 1000, 3600*24*30, 2, {from: alice});
    assert.strictEqual((await nft.balanceOf(alice)).toString(), '1');
    await time.advanceBlock();
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '11');
    ret = await farming.pendingWasp(0, alice);
    assert.strictEqual(ret.toString(), '5');
    assert.strictEqual((await lp1.balanceOf(alice)).toString(), '8999000');
    await farming.withdraw(0, 0, {from: alice});
    ret = await farming.pendingZoo(0, alice);
    assert.strictEqual(ret.toString(), '0');
    ret = await farming.pendingWasp(0, alice);
    assert.strictEqual(ret.toString(), '0');
    assert.strictEqual((await zoo.balanceOf(alice)).toString(), '1000023');
    assert.strictEqual((await wasp.balanceOf(alice)).toString(), '10');
    // console.log((await zoo.balanceOf(dev)).toString());
    assert.strictEqual((await zoo.balanceOf(dev)).toString(), '1000005');
  });

});
