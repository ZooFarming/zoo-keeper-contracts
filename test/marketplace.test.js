const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const MarketplaceDelegate = artifacts.require('MarketplaceDelegate');
const ZooToken = artifacts.require('ZooToken');

const assert = require('assert');

contract("MarketplaceDelegate", ([alice, lucy, jack, tom, molin, dev]) => {
    let market;
    let zoo;
    let nft;
    beforeEach(async ()=>{
      zoo = await ZooToken.new();
      zoo.mint(alice, '1000000');
      zoo.mint(lucy, '1000000');
      zoo.mint(jack, '1000000');
      zoo.mint(tom, '1000000');
      zoo.mint(molin, '1000000');
      zoo.mint(dev, '100');
  
      nft = await ZooNFTDelegate.new();
      await nft.initialize(dev);

      market = await MarketplaceDelegate.new();
      await market.initialize(dev);
      
      zoo.approve(market.address, '10000000000000000', {from: alice});
      zoo.approve(market.address, '1000000', {from: lucy});
      zoo.approve(market.address, '1000000', {from: jack});
      zoo.approve(market.address, '1000000', {from: tom});
      zoo.approve(market.address, '1000000', {from: molin});
      zoo.approve(market.address, '1000000', {from: dev});

    //   nft.approveAll()
    });

  it("should success when create sell order", async () => { 
    await market.createOrder(nft.address, 1, zoo.address, 10000, 3600*24);
  });

  it("should failed when set factory without access", async () => {
    try {

      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

});
