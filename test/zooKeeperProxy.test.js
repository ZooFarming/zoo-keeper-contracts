const ZooKeeperProxy = artifacts.require('ZooKeeperProxy');
const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');

const assert = require('assert');

contract("ZooKeeperProxy", accounts => {
  let zooNFTProxy;
  let zooNFTDelegate;
  let zooNFTDelegate2;

  beforeEach(async ()=>{
    zooNFTDelegate = await ZooNFTDelegate.new();
    zooNFTDelegate2 = await ZooNFTDelegate.new();
    zooNFTProxy = await ZooKeeperProxy.new(zooNFTDelegate.address, accounts[1], '0x');
  });

  it("should success when upgrade", async () => {
    await zooNFTProxy.upgradeTo(zooNFTDelegate2.address, {from: accounts[1]});
  });

  it("should failed when upgrade without access", async () => {
    try {
      await zooNFTProxy.upgradeTo(zooNFTDelegate2.address, {from: accounts[0]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when changeAdmin", async () => {
    await zooNFTProxy.changeAdmin(accounts[2], {from: accounts[1]});

  });

  it("should failed when changeAdmin without access", async () => {

    try {
    await zooNFTProxy.changeAdmin(accounts[2], {from: accounts[3]});

      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when call to delegate function", async () => {
    const zoo = await ZooNFTDelegate.at(zooNFTProxy.address);
    await zoo.initialize(accounts[0]);
    let ret = await zoo.getRoleMember('0x00', 0);
    assert.strictEqual(accounts[0], ret);
    await zoo.grantRole('0x00', accounts[3]);
    ret = await zoo.getRoleMember('0x00', 1);
    assert.strictEqual(accounts[3], ret);
    await zoo.renounceRole('0x00', accounts[0]);
    ret = await zoo.getRoleMember('0x00', 0);
    assert.strictEqual(accounts[3], ret);
  });

  it("should failed when call to delegate function without access", async () => {
    try {
      const zoo = await ZooNFTDelegate.at(zooNFTProxy.address);
      await zoo.initialize(accounts[0], {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });
});

