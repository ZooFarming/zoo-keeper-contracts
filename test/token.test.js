const ZooToken = artifacts.require('ZooToken');
const assert = require('assert');

contract("ZooToken", accounts => {
  it("all", async () => {
    const zooToken = await ZooToken.new();
    await zooToken.mint(accounts[1], '1000');
    const ret = await zooToken.balanceOf(accounts[1]);
    assert.strictEqual(ret.toString(), '1000');
    await zooToken.burn('1000', {from: accounts[1]});
  });
});
