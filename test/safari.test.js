const { expectRevert, time } = require('@openzeppelin/test-helpers');
const ZooToken = artifacts.require('ZooToken');
const MockERC20 = artifacts.require('MockERC20');
const WaspToken = artifacts.require('WaspToken');
const WWAN = artifacts.require('WWAN');
const SafariDelegate = artifacts.require('SafariDelegate');
const assert = require('assert');
const sleep = require('ko-sleep');


contract('Safari', ([alice, bob, carol, dev, minter]) => {
  let zoo;
  let wwan;
  let wasp;
  let safari;
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

    wwan = await WWAN.new();
    wasp = await WaspToken.new();

    safari = await SafariDelegate.new();
    await safari.initialize(alice, wwan.address);

    await lp1.transfer(safari.address, 10000);
    await lp2.transfer(safari.address, 10000);
    await lp3.transfer(safari.address, 10000);
    await lp4.transfer(safari.address, 10000);
  });

  it("should success when add pool", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await safari.add(zoo.address, 0, 1000000, 20, lp2.address);
    await safari.add(zoo.address, 0, 1000000, 30, lp3.address);
    await safari.add(zoo.address, 0, 1000000, 40, lp4.address);
  });

  it("should failed when add pool without access", async ()=>{
    try {
      await safari.add(zoo.address, 0, 1000000, 10, lp1.address, {from:bob});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when set pool 1", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await safari.set(0, 20, 2000, true);
    assert.strictEqual((await safari.poolInfo(0)).rewardPerBlock.toString(), '20');
    assert.strictEqual((await safari.poolInfo(0)).bonusEndBlock.toString(), '2000');
  });

  it("should success when set pool 2", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '10');
    await safari.set(0, 20, 20000000, true);
    assert.strictEqual((await safari.poolInfo(0)).rewardPerBlock.toString(), '20');
    assert.strictEqual((await safari.poolInfo(0)).bonusEndBlock.toString(), '20000000');
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '40');
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '60');
    await safari.withdraw(0, 1000, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '80');
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '1000000');
  });


  it("should failed when set pool without access", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    try {
      await safari.set(0, 20, 2000, true, {from: bob});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when deposit 0", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await safari.deposit(0, 0, {from: bob});
  });
  
  it("should success when deposit amount", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
  });

  it("should success when pendingReward", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '10');
  });

  it("should success when withdraw 0", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '10');
    assert.strictEqual((await safari.pendingReward(0, bob))[0].toString(), '1000');

    await safari.withdraw(0, 0, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '20');
  });

  it("should success when withdraw amount", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '10');
    await safari.withdraw(0, 1000, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '20');
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '1000000');
    
  });

  it("should success when farming amount", async ()=>{
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '10');
    await safari.withdraw(0, 1000, {from: bob});
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '20');
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '1000000');

    await safari.add(zoo.address, 0, 1000000, 10, lp2.address);
    await zoo.approve(safari.address, 1000, {from: carol});
    await safari.deposit(1, 1000, {from: carol});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(1, carol))[1].toString(), '10');
    await safari.withdraw(1, 1000, {from: carol});
    assert.strictEqual((await lp2.balanceOf(carol)).toString(), '20');
    assert.strictEqual((await zoo.balanceOf(carol)).toString(), '1000000');

    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});

    await zoo.approve(safari.address, 1000, {from: carol});

    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '10');

    await safari.deposit(0, 1000, {from: carol});

    await time.advanceBlock();

    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '25');
    assert.strictEqual((await safari.pendingReward(0, carol))[1].toString(), '5');
    await safari.withdraw(0, 500, {from: bob});
    await safari.withdraw(0, 500, {from: carol});
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '3');
    assert.strictEqual((await safari.pendingReward(0, carol))[1].toString(), '0');
    await safari.withdraw(0, 500, {from: bob});
    await safari.withdraw(0, 500, {from: carol});
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '0');
    assert.strictEqual((await safari.pendingReward(0, carol))[1].toString(), '0');

    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '58');
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '1000000');

    assert.strictEqual((await lp1.balanceOf(carol)).toString(), '31');
    assert.strictEqual((await zoo.balanceOf(carol)).toString(), '1000000');
  });

  it("should success when farming amount 2", async ()=>{ 
    await safari.add(zoo.address, 0, 1000000, 10, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '10');
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '50');
    await safari.withdraw(0, 1000, {from: bob});
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '0');
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '60');
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '1000000');
  });

  it("should success when farming not start", async ()=>{
    await safari.add(zoo.address, 2000000, 2100000, 10, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '0');
    await safari.withdraw(0, 1000, {from: bob});

    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '0');
    await safari.withdraw(0, 1000, {from: bob});
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '1000000');
  });

  it("should success when emergencyWithdraw", async ()=>{ 
    await safari.add(zoo.address, 0, 1000000, 1000000, lp1.address);
    await zoo.approve(safari.address, 1000, {from: bob});
    await safari.deposit(0, 1000, {from: bob});
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '1000000');
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '5000000');
    await safari.emergencyWithdraw(0, {from: bob});
    assert.strictEqual((await safari.pendingReward(0, bob))[1].toString(), '0');
    assert.strictEqual((await lp1.balanceOf(bob)).toString(), '0');
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '1000000');
  });

});
