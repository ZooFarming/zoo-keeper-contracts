const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');

const assert = require('assert');

contract("ZooNFTDelegate", accounts => {
  let zooNFTDelegate;
  beforeEach(async ()=>{
    zooNFTDelegate = await ZooNFTDelegate.new();
    await zooNFTDelegate.initialize(accounts[0]);
  });

  it("should success when set factory", async () => { 
    await zooNFTDelegate.setNFTFactory(accounts[1]);

  });

  it("should failed when set factory without access", async () => {
    try {
      await zooNFTDelegate.setNFTFactory(accounts[1], {from: accounts[2]});

      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when setScaleParams", async () => { 
    await zooNFTDelegate.setScaleParams(1e11, 1e10, 1e9, 1e7);

  });

  it("should failed when setScaleParams without access", async () => {
    try {
    await zooNFTDelegate.setScaleParams(1e11, 1e10, 1e9, 1e7, {from: accounts[2]});

      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when setURI", async () => { 
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
  });

  it("should failed when setURI without access", async () => {
    try {
      await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/', {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    try {
      await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json', {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when getURI", async () => { 
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    let ret = await zooNFTDelegate.getNftURI(1, 1, 1);
    assert.strictEqual(ret, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
  });

  it("should empty when getURI without set", async () => {
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    let ret = await zooNFTDelegate.getNftURI(3, 1, 1);
    assert.strictEqual(ret, '');
  });

  it("should success when mint", async () => { 
    await zooNFTDelegate.setNFTFactory(accounts[1]);
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    await zooNFTDelegate.mint(1, 1, 1, 1, 100, { from: accounts[1] });
  });

  it("should failed when mint without access", async () => {
    await zooNFTDelegate.setNFTFactory(accounts[1]);
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    try {
      await zooNFTDelegate.mint(1, 1, 1, 1, 100, { from: accounts[2] });
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when getBoosting", async () => { 
    await zooNFTDelegate.setNFTFactory(accounts[1]);
    await zooNFTDelegate.setNFTFactory(accounts[2]);
    await zooNFTDelegate.setScaleParams(1e11, 1e10, 1e9, 1e7);

    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    await zooNFTDelegate.mint(1, 1, 1, 1, 100, { from: accounts[1] });
    ret = await zooNFTDelegate.getBoosting(1);
    assert.strictEqual(ret.toString(), '1012000000000');
    await zooNFTDelegate.setNftURI(2, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple-pie.json');
    await zooNFTDelegate.mint(202, 2, 1, 1, 10, { from: accounts[2] });
    ret = await zooNFTDelegate.getBoosting(202);
    assert.strictEqual(ret.toString(), '1111100000000');
  });

  it("should 1e12 when getBoosting non-token", async () => {
    await zooNFTDelegate.setScaleParams(1e11, 1e10, 1e9, 1e7);
    ret = await zooNFTDelegate.getBoosting(1);
    assert.strictEqual(ret.toString(), '1000000000000');
  });

  it("should success when getTokenURI", async () => {
    await zooNFTDelegate.setNFTFactory(accounts[1]);
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    await zooNFTDelegate.mint(1, 1, 1, 1, 100, { from: accounts[1] });
    ret = await zooNFTDelegate.tokenURI(1);
    assert.strictEqual(ret, 'https://gateway.pinata.cloud/ipfs/QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
   });

  it("should failed when getTokenURI non token", async () => {
    try {
      ret = await zooNFTDelegate.tokenURI(1);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when getTokenInfo", async () => { 
    await zooNFTDelegate.setNFTFactory(accounts[1]);
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    await zooNFTDelegate.mint(1, 1, 1, 1, 100, { from: accounts[1] });
    ret = await zooNFTDelegate.tokenInfo(1);
    assert.strictEqual(ret.level.toString(), '1');
    assert.strictEqual(ret.category.toString(), '1');
    assert.strictEqual(ret.item.toString(), '1');
    assert.strictEqual(ret.random.toString(), '100');
  });

  it("should 0 when getTokenInfo non token", async () => {
    ret = await zooNFTDelegate.tokenInfo(1);
    assert.strictEqual(ret.level.toString(), '0');
    assert.strictEqual(ret.category.toString(), '0');
    assert.strictEqual(ret.item.toString(), '0');
    assert.strictEqual(ret.random.toString(), '0');
  });

  it("should success when setMultiNftURI", async () => {
    await zooNFTDelegate.setMultiNftURI(
      [1, 2],
      [1, 1],
      [1, 1],
      [
        'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json',
        'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple-pie.json'
      ]);
  });

  it("should failed when setMultiNftURI without access", async () => {
    try {
      await zooNFTDelegate.setMultiNftURI(
        [1, 2],
        [1, 1],
        [1, 1],
        [
          'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json',
          'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple-pie.json'
        ], {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });
});
