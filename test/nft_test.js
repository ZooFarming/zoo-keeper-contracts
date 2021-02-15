const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const assert = require('assert');

contract("ZooNFTDelegate", accounts => {
  it("all", async () => {
    const zooNFTDelegate = await ZooNFTDelegate.new(accounts[0]);

  });
});
