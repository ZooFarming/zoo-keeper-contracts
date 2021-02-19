const ZooToken = artifacts.require('ZooToken');
const assert = require('assert');

contract("ZooToken", accounts => {
  let zooToken;
  beforeEach(async ()=>{
    zooToken = await ZooToken.new();
  });

  it("should success when mint", async () => {
    await zooToken.mint(accounts[1], '1000');
    const ret = await zooToken.balanceOf(accounts[1]);
    assert.strictEqual(ret.toString(), '1000');
    await zooToken.burn('1000', {from: accounts[1]});
  });

  it("should failed when mint without permission", async () => {
    try {
      await zooToken.mint(accounts[1], '1000', {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when burn", async () => {
    await zooToken.mint(accounts[1], '1000');
    const ret = await zooToken.balanceOf(accounts[1]);
    assert.strictEqual(ret.toString(), '1000');
    await zooToken.burn('1000', {from: accounts[1]});
    assert.strictEqual((await zooToken.balanceOf(accounts[1])).toString(), '0');

  });

  it("should failed when burn out of balance", async () => {
    await zooToken.mint(accounts[1], '1000');
    const ret = await zooToken.balanceOf(accounts[1]);
    assert.strictEqual(ret.toString(), '1000');
    try {
      await zooToken.burn('10000', {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when transferOwner", async () => {
    await zooToken.transferOwnership(accounts[1]);
  });

  it("should failed when transferOwner without access", async () => {
    try {
      await zooToken.transferOwnership(accounts[1], {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });
});

/*
  try {
    assert.fail('never go here');
  } catch (e) {
    assert.ok(e.message.match(/revert/));
  }
*/