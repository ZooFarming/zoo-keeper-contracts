const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');

const assert = require('assert');

contract("ZooNFTDelegate", accounts => {
  it.only("all", async () => {
    const zooNFTDelegate = await ZooNFTDelegate.new(accounts[0]);
    await zooNFTDelegate.initialize(accounts[0]);
    await zooNFTDelegate.setNftURI(1, 1, 1, 'https://gateway.pinata.cloud/ipfs/QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    let ret = await zooNFTDelegate.getNftURI(1,1,1);
    console.log('ret', ret);
  });
});
