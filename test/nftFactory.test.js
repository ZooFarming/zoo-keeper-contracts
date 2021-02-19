const NFTFactoryDelegate = artifacts.require('NFTFactoryDelegate');
const ZooToken = artifacts.require('ZooToken');
const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const assert = require('assert');
const sleep = require('ko-sleep');

contract("NFTFactoryDelegate", ([alice, lucy, jack, tom, molin, dev]) => {
  let nftFactory;
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
    nftFactory = await NFTFactoryDelegate.new();
    await nftFactory.initialize(dev, zoo.address, nft.address);
    
    zoo.approve(nftFactory.address, '1000000', {from: alice});
    zoo.approve(nftFactory.address, '1000000', {from: lucy});
    zoo.approve(nftFactory.address, '1000000', {from: jack});
    zoo.approve(nftFactory.address, '1000000', {from: tom});
    zoo.approve(nftFactory.address, '1000000', {from: molin});
    zoo.approve(nftFactory.address, '1000000', {from: dev});

    await nftFactory.configChestPrice('30000', {from: dev});
    await nftFactory.configDynamicPrice(10, 20000, 40000, {from: dev});
  });

  it("should success when buy silver chest", async () => { 
    let ret = await nftFactory.buySilverChest({from: alice});
    console.log(ret.logs[0].args.level.toString());
    for (let i=0; i<10; i++) {
      ret = await nftFactory.buySilverChest({from: alice});
      console.log(i, ret.logs[0].args.level.toString());
    }
  });

  it("should failed when buy silver chest without enough zoo", async () => {
    try {
      let ret = await nftFactory.buySilverChest({from: dev});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });
});
