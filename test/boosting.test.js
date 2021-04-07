const { expectRevert, time } = require('@openzeppelin/test-helpers');

const ZooToken = artifacts.require('ZooToken');
const ZooKeeperFarming = artifacts.require('ZooKeeperFarming');
const MockERC20 = artifacts.require('MockERC20');
const ZooNFT = artifacts.require('ZooNFT');
const BoostingDelegate = artifacts.require('BoostingDelegate');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

const sleep = require('ko-sleep');

const assert = require('assert');

contract("BoostingDelegate", ([alice, bob, carol, dev, minter]) => {
  let nft;
  let zoo;
  let boosting;
  let ret;

  beforeEach(async () => {
    zoo = await ZooToken.new();
    nft = await ZooNFT.new();
    await nft.initialize(alice);
    await nft.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await nft.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    await nft.setNFTFactory(bob);
    //---
    // config boost
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

    await nft.setBoostMap(chances, boosts, reduces);
    //---
    await nft.mint(1, 1, 1, 1, 100, { from: bob });
    ret = await nft.getBoosting(1);
    assert.strictEqual(ret.toString(), '1011000000000');
    boosting = await BoostingDelegate.new();
    await boosting.initialize(alice);
    await boosting.setFarmingAddr(carol);
    await boosting.setNFTAddress(nft.address);
    await boosting.setBoostScale(8 * 3600 * 24, '2000000000', '4000000000');
    await nft.setApprovalForAll(boosting.address, true, { from: bob });
  });

  it("should failed when initialize again", async () => {
    try {
      await boosting.initialize(alice);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  })

  it("should success when set params", async () => {
    await boosting.setFarmingAddr(carol);
    await boosting.setNFTAddress(nft.address);
    await boosting.setBoostScale(8 * 3600 * 24, '2000000000', '4000000000');
  });

  it("lock time boost", async () => {
    const getLockTimeBoost = (lockTime) => {
      var boosting = 1e12;
      var baseBoost = 2e9;
      var increaseBoost = 4e9;
      var minLockDays = 8 * 3600 * 24;
      if (lockTime >= minLockDays) {
        boosting = boosting + (baseBoost) + (lockTime - minLockDays) / (3600 * 24) * increaseBoost;
      }
      return boosting;
    }

    for (let i = 0; i <= 180; i++) {
      let ret = await boosting.getLockTimeBoost(i * 3600 * 24);
      assert.strictEqual(ret.toString(), getLockTimeBoost(i*3600*24).toString());
    }
  });

  it("should failed when set params without access", async () => {
    try {
      await boosting.setFarmingAddr(carol, { from: bob });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    try {
      await boosting.setNFTAddress(nft.address, { from: bob });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    try {
      await boosting.setBoostScale(8 * 3600 * 24, '2000000000', '4000000000', { from: bob });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  })

  it("should success when transfer admin", async () => {
    await boosting.grantRole('0x00', dev);
    await boosting.renounceRole('0x00', alice);
    await boosting.setBoostScale(8 * 3600 * 24, '2000000000', '4000000000', { from: dev });
    try {
      await boosting.setBoostScale(8 * 3600 * 24, '2000000000', '4000000000', { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should failed when transfer admin without access", async () => {
    try {
      await boosting.grantRole('0x00', dev, { from: bob });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when deposit no-lock", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');
  });

  it("should failed when deposit no-lock without access", async () => {
    try {
      await boosting.deposit(0, bob, 0, 0, { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when withdraw no-lock", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    await boosting.withdraw(0, bob, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');
  });

  it("should failed when withdraw no-lock without access", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    await time.advanceBlock();

    try {
      await boosting.withdraw(0, bob, { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when deposit with lock time", async () => {
    await boosting.deposit(0, bob, 3600 * 24 * 30, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1090000000000');
  });

  it("should failed when deposit with lock without access", async () => {
    try {
      await boosting.deposit(0, bob, 5, 0, { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when withdraw with lock time", async () => {
    await boosting.deposit(0, bob, 3, 0, { from: carol });
    await sleep(5000);
    await time.advanceBlock();
    await boosting.withdraw(0, bob, { from: carol });
  });

  it("should failed when withdraw in lock time", async () => {
    await boosting.deposit(0, bob, 30, 0, { from: carol });
    await time.advanceBlock();
    try {
      await boosting.withdraw(0, bob, { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when deposit no-lock to lock", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');
    await boosting.deposit(0, bob, 30 * 24 * 3600, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1090000000000');
  });

  it("should failed when deposit no-lock to lock without access", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');
    try {
      await boosting.deposit(0, bob, 30 * 24 * 3600, 0, { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when withdraw with lock time", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    await boosting.deposit(0, bob, 3, 0, { from: carol });
    await sleep(5000);
    await time.advanceBlock();
    await boosting.withdraw(0, bob, { from: carol });
  });

  it("should failed when withdraw in lock time", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    await boosting.deposit(0, bob, 30, 0, { from: carol });
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    await time.advanceBlock();
    try {
      await boosting.withdraw(0, bob, { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when deposit nft", async () => {
    await boosting.deposit(0, bob, 0, 1, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1011000000000');
  });

  it("should failed when deposit nft without access", async () => {
    try {
      await boosting.deposit(0, alice, 0, 1, { from: carol });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when withdraw nft", async () => {
    await boosting.deposit(0, bob, 0, 1, { from: carol });
    assert.strictEqual((await nft.balanceOf(bob)).toString(), '0');
    await boosting.withdraw(0, bob, { from: carol });
    assert.strictEqual((await nft.balanceOf(bob)).toString(), '1');
  });

  it("should failed when withdraw nft without access", async () => {
    await boosting.deposit(0, bob, 0, 1, { from: carol });
    assert.strictEqual((await nft.balanceOf(bob)).toString(), '0');
    try {
      await boosting.withdraw(0, bob, { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when deposit from no-nft to nft", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');

    await boosting.deposit(0, bob, 0, 1, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1011000000000');

    await boosting.withdraw(0, bob, { from: carol });

    await boosting.deposit(0, bob, 3600, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');

    await boosting.deposit(0, bob, 0, 1, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1011000000000');
  });

  it("should failed when deposit from nft to non-nft", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');

    await boosting.deposit(0, bob, 0, 1, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1011000000000');

    await boosting.deposit(0, bob, 0, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1011000000000');
  })

  it("should success when withdraw from no-nft to nft", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');

    await boosting.deposit(0, bob, 0, 1, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1011000000000');

    await boosting.withdraw(0, bob, { from: carol });
  })

  it("should failed when withdraw from no-nft to nft without access", async () => {
    await boosting.deposit(0, bob, 0, 0, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1000000000000');

    await boosting.deposit(0, bob, 0, 1, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1011000000000');

    try {
      await boosting.withdraw(0, bob, { from: alice });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when deposit lock with nft", async () => {
    await boosting.deposit(0, bob, 60 * 24 * 3600, 1, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1221000000000');
  });

  it("should success when deposit lock with nft", async () => {
    await boosting.deposit(0, bob, 3, 1, { from: carol });
    assert.strictEqual((await nft.balanceOf(bob)).toString(), '0');
    await sleep(5000);
    await time.advanceBlock();
    await boosting.withdraw(0, bob, { from: carol });
    assert.strictEqual((await nft.balanceOf(bob)).toString(), '1');
  });

  it("check getMultiplier in different nft", async () => {
    await nft.setNftURI(3, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    await nft.mint(2, 3, 1, 1, 300, { from: bob });
    await boosting.deposit(0, bob, 0, 2, { from: carol });
    ret = await boosting.getMultiplier(0, bob);
    assert.strictEqual(ret.toString(), '1253000000000');
  });
});
