const ZooKeeperProxy = artifacts.require('ZooKeeperProxy');
const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');

const assert = require('assert');

contract("ZooKeeperProxy", accounts => {
  it("all", async () => {
    const zooNFTDelegate = await ZooNFTDelegate.new();
    const zooNFTProxy = await ZooKeeperProxy.new(zooNFTDelegate.address, accounts[1], '0x');

    const zoo = await ZooNFTDelegate.at(zooNFTProxy.address);

    await zoo.initialize(accounts[0]);

    const zooNFTDelegate2 = await ZooNFTDelegate.new();

    await zooNFTProxy.upgradeTo(zooNFTDelegate2.address, {from: accounts[1]});

    await zooNFTProxy.changeAdmin(accounts[2], {from: accounts[1]});

    const zooNFTDelegate3 = await ZooNFTDelegate.new();

    await zooNFTProxy.upgradeTo(zooNFTDelegate3.address, {from: accounts[2]});

    // await zoo.changeAdmin(accounts[3], {from: accounts[0]});
    let ret = await zoo.getRoleMember('0x00', 0);
    assert.strictEqual(accounts[0], ret);
    await zoo.grantRole('0x00', accounts[3]);
    ret = await zoo.getRoleMember('0x00', 1);
    assert.strictEqual(accounts[3], ret);
    await zoo.renounceRole('0x00', accounts[0]);
    ret = await zoo.getRoleMember('0x00', 0);
    assert.strictEqual(accounts[3], ret);

    console.log(ret);
  });
});

