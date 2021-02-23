const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const MarketplaceDelegate = artifacts.require('MarketplaceDelegate');
const ZooToken = artifacts.require('ZooToken');

const { time } = require('@openzeppelin/test-helpers');
const assert = require('assert');
const sleep = require('ko-sleep');

contract("MarketplaceDelegate", ([alice, lucy, jack, tom, molin, dev]) => {
    let market;
    let zoo;
    let nft;
    beforeEach(async ()=>{
      zoo = await ZooToken.new();
      await zoo.mint(alice, '1000000');
      await zoo.mint(lucy, '1000000');
      await zoo.mint(jack, '1000000');
      await zoo.mint(tom, '1000000');
      await zoo.mint(molin, '1000000');
      await zoo.mint(dev, '100');
  
      nft = await ZooNFTDelegate.new();
      await nft.initialize(dev);
      await nft.setNFTFactory(alice, {from: dev});
      await nft.setBaseURI('https://gateway.pinata.cloud/ipfs/', {from: dev});
      await nft.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json', {from: dev});
      await nft.setNftURI(2, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json', {from: dev});
      await nft.setNftURI(3, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json', {from: dev});
      await nft.mint(1, 1, 1, 1, 100, { from: alice });
      await nft.mint(2, 2, 1, 1, 100, { from: alice });
      await nft.mint(3, 3, 1, 1, 100, { from: alice });


      market = await MarketplaceDelegate.new();
      await market.initialize(dev);
      
      await zoo.approve(market.address, '10000000000000000', {from: alice});
      await zoo.approve(market.address, '1000000', {from: lucy});
      await zoo.approve(market.address, '1000000', {from: jack});
      await zoo.approve(market.address, '100', {from: tom});
      await zoo.approve(market.address, '1000000', {from: molin});
      await zoo.approve(market.address, '1000000', {from: dev});

      await nft.setApprovalForAll(market.address, true, {from: alice});
      await nft.setApprovalForAll(market.address, true, {from: lucy});
      await nft.setApprovalForAll(market.address, true, {from: jack});
      await nft.setApprovalForAll(market.address, true, {from: tom});
      await nft.setApprovalForAll(market.address, true, {from: molin});
      await nft.setApprovalForAll(market.address, true, {from: dev});
    });

  it("should success when create sell order", async () => { 
    await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 2, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 3, zoo.address, 10000, 3600*24);
  });

  it("should failed when create illegal sell order", async () => {
    try {
      await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*23);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    try {
      await market.createOrder(nft.address, 200, zoo.address, 10000, 3600*24);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    try {
      await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24*365);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    try {
      await market.createOrder(zoo.address, 1, zoo.address, 10000, 3600*24);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    try {
      await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24, {from: lucy});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }

    await market.configExpiration(1, 10, {from: dev});

    try {
      await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
    
  });

  it("should success when get order", async () => { 
    await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 2, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 3, zoo.address, 10000, 3600*24);

    let ret = await market.orderCount();
    assert.strictEqual(ret.toString(), '3');
    let ret1 = await market.getOrderId(0);
    let ret2 = await market.getOrderId(1);
    let ret3 = await market.getOrderId(2);
    let id1 = ret1[0];
    let id2 = ret2[0];
    let id3 = ret3[0];
    let v1 = ret1[1];
    let v2 = ret2[1];
    let v3 = ret3[1];

    assert.strictEqual(v1, true);
    assert.strictEqual(v2, true);
    assert.strictEqual(v3, true);

    let info1 = await market.getOrderById(id1);
    let info2 = await market.getOrderById(id2);
    let info3 = await market.getOrderById(id3);

    assert.strictEqual(info1.tokenId.toString(), '1');
    assert.strictEqual(info2.tokenId.toString(), '2');
    assert.strictEqual(info3.tokenId.toString(), '3');

    assert.strictEqual(info1.token, zoo.address);
    assert.strictEqual(info2.token, zoo.address);
    assert.strictEqual(info3.token, zoo.address);

    assert.strictEqual(info1.owner, alice);
    assert.strictEqual(info2.owner, alice);
    assert.strictEqual(info3.owner, alice);

  });

  it("should failed when get order non", async () => {
    try {
      let ret1 = await market.getOrderId(0);
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when check order", async () => { 
    await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 2, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 3, zoo.address, 10000, 3600*24);

    let ret = await market.orderCount();
    assert.strictEqual(ret.toString(), '3');
    let ret1 = await market.getOrderId(0);
    let ret2 = await market.getOrderId(1);
    let ret3 = await market.getOrderId(2);
    let id1 = ret1[0];
    let id2 = ret2[0];
    let id3 = ret3[0];
    let v1 = ret1[1];
    let v2 = ret2[1];
    let v3 = ret3[1];

    assert.strictEqual(v1, true);
    assert.strictEqual(v2, true);
    assert.strictEqual(v3, true);

    assert.strictEqual(await market.checkOrderValid(id1), true);
  });

  it("should failed when check order illegal", async () => {
    try {
      await market.checkOrderValid('0xe83d12d3adbb7f68195911497f036f4a2885fb16618de1b01b7f65893db938de');
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when cancel order", async () => { 
    await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 2, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 3, zoo.address, 10000, 3600*24);
    let ret = await market.orderCount();
    assert.strictEqual(ret.toString(), '3');
    await market.cancelOrder(nft.address, 1, zoo.address);
    await market.cancelOrder(nft.address, 2, zoo.address);
    await market.cancelOrder(nft.address, 3, zoo.address);
    ret = await market.orderCount();
    assert.strictEqual(ret.toString(), '0');
  });
  it("should failed when cancel others order", async () => {
    await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
    try {
      await market.cancelOrder(nft.address, 1, zoo.address, {from: dev});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when order expiration cancel", async () => { 
    await market.configExpiration(1, 10, {from: dev});
    await market.createOrder(nft.address, 1, zoo.address, 10000, 1);
    await sleep(2000);
    await market.cancelOrder(nft.address, 1, zoo.address);
  });

  it("should failed when expiration order buy", async () => {
    await market.configExpiration(1, 10, {from: dev});
    await market.createOrder(nft.address, 1, zoo.address, 10000, 2);
    let ret = await market.getOrderId(0);
    let id = ret.orderId;

    await sleep(3000);
    await time.advanceBlock();
    await time.advanceBlock();

    try {
      await market.buyOrder(id, {from: lucy});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when clean order", async () => { 
    await market.configExpiration(1, 10, {from: dev});
    await market.createOrder(nft.address, 1, zoo.address, 10000, 1);
    await market.createOrder(nft.address, 2, zoo.address, 10000, 10);
    assert.strictEqual((await market.orderCount()).toString(), '2');
    await sleep(2000);
    await market.cleanInvalidOrders(0, 1);
    assert.strictEqual((await market.orderCount()).toString(), '1');
  });

  it("should success when buy order", async () => { 
    await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 2, zoo.address, 10000, 3600*24);
    await market.createOrder(nft.address, 3, zoo.address, 10000, 3600*24);
    let ret = await market.orderCount();
    assert.strictEqual(ret.toString(), '3');
    let ret1 = await market.getOrderId(0);
    let ret2 = await market.getOrderId(1);
    let ret3 = await market.getOrderId(2);
    let id1 = ret1[0];
    let id2 = ret2[0];
    let id3 = ret3[0];
    let v1 = ret1[1];
    let v2 = ret2[1];
    let v3 = ret3[1];

    await market.buyOrder(id1, {from: lucy});
    await market.buyOrder(id2, {from: lucy});
    await market.buyOrder(id3, {from: lucy});

    ret = await market.orderCount();
    assert.strictEqual(ret.toString(), '0');

    assert.strictEqual((await nft.balanceOf(lucy)).toString(), '3');
  });

  it("should failed when buy order token not enough", async () => {
    await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
    let ret1 = await market.getOrderId(0);
    let id1 = ret1[0];

    try {
      await market.buyOrder(id1, {from: tom});

      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });
});
