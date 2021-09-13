const ZooToken = artifacts.require('ZooToken');
const ZooNFT = artifacts.require('ZooNFT');
const ElixirNFT = artifacts.require('ElixirNFT');
const AlchemyDelegate = artifacts.require('AlchemyDelegate');
const TestGoldenPriceOracle = artifacts.require('TestGoldenPriceOracle');
const RandomBeacon = artifacts.require('RandomBeacon');

const { expectRevert, expectEvent, time } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');


const assert = require('assert');
const koSleep = require('ko-sleep');

contract("craft", ([alice, lucy, jack, tom, molin, dev]) => {
  let zooNft;
  let zooToken;
  let elixirNft;
  let alchemy;
  let randomBeacon;
  beforeEach(async ()=>{
    zooToken = await ZooToken.new();
    zooToken.mint(alice, '1000000');
    zooToken.mint(lucy, '1000000');
    zooToken.mint(jack, '1000000');
    zooToken.mint(tom, '1000000');
    zooToken.mint(molin, '1000000');
    zooToken.mint(dev, '100');

    zooNft = await ZooNFT.new();
    await zooNft.initialize(dev);

    elixirNft = await ElixirNFT.new();
    await elixirNft.initialize(dev);

    alchemy = await AlchemyDelegate.new();

    let goldenOracle = await TestGoldenPriceOracle.new();

    randomBeacon = await RandomBeacon.new();
    await randomBeacon.initialize(dev, dev);

    // address admin,
    // address _elixirNFT,
    // address _buyToken,
    // address _priceOracle,
    // address _zooNFT,
    // address randomOracle_
    await alchemy.initialize(dev, elixirNft.address, zooToken.address, goldenOracle.address, zooNft.address, randomBeacon.address);
    await zooNft.setNFTFactory(alchemy.address, {from: dev}); 
    await zooNft.setNFTFactory(dev, {from: dev}); 

    await elixirNft.setNFTFactory(alchemy.address, {from: dev});

    zooToken.approve(alchemy.address, '10000000000000000', {from: alice});
    zooToken.approve(alchemy.address, '1000000', {from: lucy});
    zooToken.approve(alchemy.address, '1000000', {from: jack});
    zooToken.approve(alchemy.address, '1000000', {from: tom});
    zooToken.approve(alchemy.address, '1000000', {from: molin});
    zooToken.approve(alchemy.address, '1000000', {from: dev});
  });

  const buy = async () => {
    let price = await alchemy.getElixirPrice();
    assert.strictEqual(price.toString(), '10', 1);
    let ret = await alchemy.buy("Big Bottle", {from: alice});
    expectEvent(ret, 'MintElixir', {tokenId: '1', name: 'Big Bottle'});
    assert.strictEqual((await zooToken.balanceOf(alice)).toString(), '999990', 2);

    ret = await alchemy.buy("Middle Bottle", {from: alice});
    expectEvent(ret, 'MintElixir', {tokenId: '2', name: 'Middle Bottle'});
    assert.strictEqual((await zooToken.balanceOf(alice)).toString(), '999980', 2);

    ret = await alchemy.buy("Small Bottle", {from: alice});
    expectEvent(ret, 'MintElixir', {tokenId: '3', name: 'Small Bottle'});
    assert.strictEqual((await zooToken.balanceOf(alice)).toString(), '999970', 2);
  }

  it("should success when buy Elixir", async ()=>{
    await buy();
  });

  const depositElixir = async () => {
    await elixirNft.setApprovalForAll(alchemy.address, true, {from: alice});
    let ret = await alchemy.depositElixir(1, {from: alice});
    expectEvent(ret, 'DepositElixir', {user: alice, tokenId: '1'});
    expectRevert(alchemy.depositElixir(2, {from: alice}), "already exist one Elixir");
  }

  it("should success when deposit elixir", async ()=>{
    await buy();
    await depositElixir();
  });

  const withdrawElixir = async () => {
    let ret = await alchemy.withdrawElixir({from: alice});
    expectEvent(ret, 'WithdrawElixir', {user: alice, tokenId: '1'});
    expectRevert(alchemy.withdrawElixir({from: alice}), "no Elixir");
  }

  it("should success when withdrawElixir", async () => {
    await buy();
    await depositElixir();
    await withdrawElixir();
  });

  it("should success when pendingDrops", async ()=>{
    await buy();
    await depositElixir();
    let ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), '165343915343915', 3);
    await time.advanceBlock();
    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), (('165343915343915')*2).toString(), 4);
    await time.advanceBlock();
    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), (('165343915343915')*3).toString(), 5);
    await time.advanceBlock();
    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), (('165343915343915')*4).toString(), 6);

    ret = await alchemy.elixirInfoMap(1);
    assert.strictEqual(ret.drops.toString(), '0', 7);
    ret = await alchemy.withdrawElixir({from: alice});
    expectEvent(ret, 'WithdrawElixir', {user: alice, tokenId: '1'});
    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), '0', 8);
    ret = await alchemy.elixirInfoMap(1);
    assert.strictEqual(ret.drops.toString(), (('165343915343915')*5).toString(), 9);
  });

  it("should success when pending full", async () => {
    await buy();
    await alchemy.configDropRate('0x' + Number(10e18).toString(16), {from: dev});
    await depositElixir();

    for (let i=0; i<20; i++) {
      await time.advanceBlock();
    }

    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), '100000000000000000000', 10);
    ret = await alchemy.withdrawElixir({from: alice});
    expectEvent(ret, 'WithdrawElixir', {user: alice, tokenId: '1'});
    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), '0', 11);
    ret = await alchemy.elixirInfoMap(1);
    assert.strictEqual(ret.drops.toString(), '100000000000000000000', 12);

    // deposit full exlixir again
    await depositElixir();

    for (let i=0; i<20; i++) {
      await time.advanceBlock();
    }

    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), '0', 13);

    ret = await alchemy.withdrawElixir({from: alice});
    expectEvent(ret, 'WithdrawElixir', {user: alice, tokenId: '1'});
    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), '0', 11);
    ret = await alchemy.elixirInfoMap(1);
    assert.strictEqual(ret.drops.toString(), '100000000000000000000', 12);


  });

  it.only("should success when upgrade elixir", async () => {
    await buy();
    await alchemy.configDropRate('0x' + Number(10e18).toString(16), {from: dev});
    await depositElixir();

    expectRevert(alchemy.upgradeElixir({from: alice}), 'Elixir not fullfill');

    for (let i=0; i<20; i++) {
      await time.advanceBlock();
    }

    let ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), '100000000000000000000', 10);

    ret = await alchemy.upgradeElixir({from: alice});
    expectEvent(ret, 'UpgradeElixir', {user: alice, levelFrom: '0', levelTo: '1'});

    ret = await alchemy.withdrawElixir({from: alice});
    expectEvent(ret, 'WithdrawElixir', {user: alice, tokenId: '1'});
    ret = await alchemy.pendingDrops(alice);
    assert.strictEqual(ret.toString(), '0', 11);

    ret = await alchemy.elixirInfoMap(1);
    assert.strictEqual(ret.level.toString(), '1', 12);

    await depositElixir();

    for (let i=0; i<10; i++) {
      await time.advanceBlock();
    }

    ret = await alchemy.upgradeElixir({from: alice});
    expectEvent(ret, 'UpgradeElixir', {user: alice, levelFrom: '1', levelTo: '2'});

    for (let i=0; i<10; i++) {
      await time.advanceBlock();
    }

    ret = await alchemy.upgradeElixir({from: alice});
    expectEvent(ret, 'UpgradeElixir', {user: alice, levelFrom: '2', levelTo: '3'});

    for (let i=0; i<10; i++) {
      await time.advanceBlock();
    }

    ret = await alchemy.upgradeElixir({from: alice});
    expectEvent(ret, 'UpgradeElixir', {user: alice, levelFrom: '3', levelTo: '4'});

    for (let i=0; i<10; i++) {
      await time.advanceBlock();
    }

    expectRevert(alchemy.upgradeElixir({from: alice}), 'Already Level max');
  });

});

