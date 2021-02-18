const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');

const assert = require('assert');

contract("ZooNFTDelegate", accounts => {
  it("all", async () => {
    const zooNFTDelegate = await ZooNFTDelegate.new();
    await zooNFTDelegate.initialize(accounts[0]);
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');

    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    let ret = await zooNFTDelegate.getNftURI(1,1,1);
    assert.strictEqual(ret, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');

    await zooNFTDelegate.setNFTFactory(accounts[1]);
    await zooNFTDelegate.setNFTFactory(accounts[2]);


    try {
      await zooNFTDelegate.setNFTFactory(accounts[1], {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    await zooNFTDelegate.setScaleParams(1e11, 1e10, 1e9, 1e7);

    ret = await zooNFTDelegate.getBoosting(1);

    assert.strictEqual(ret.toString(), '1000000000000');

    try {
      await zooNFTDelegate.mint(1, 1, 1, 1, 100);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    await zooNFTDelegate.mint(1, 1, 1, 1, 100, {from: accounts[1]});

    ret = await zooNFTDelegate.tokenURI(1);
    assert.strictEqual(ret, 'https://gateway.pinata.cloud/ipfs/QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    ret = await zooNFTDelegate.getBoosting(1);
    assert.strictEqual(ret.toString(), '12000000000');

    await zooNFTDelegate.setNftURI(2, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple-pie.json');

    await zooNFTDelegate.mint(202, 2, 1, 1, 10, {from: accounts[2]});

    ret = await zooNFTDelegate.getBoosting(202);

    assert.strictEqual(ret.toString(), '111100000000');

    await zooNFTDelegate.setMultiNftURI(
      [1,2], 
      [1,1], 
      [1,1], 
      [
        'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json',
        'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple-pie.json'
      ]);

    console.log(ret.toString());
  });
});
