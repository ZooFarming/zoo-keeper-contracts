const { expectRevert, time } = require('@openzeppelin/test-helpers');

const ZooToken = artifacts.require('ZooToken');
const ZooKeeperFarming = artifacts.require('ZooKeeperFarming');
const MockERC20 = artifacts.require('MockERC20');
const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const BoostingDelegate = artifacts.require('BoostingDelegate');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

const sleep = require('ko-sleep');

const assert = require('assert');

contract("BoostingDelegate", ([alice, bob, carol, dev, minter]) => {
  it.only("all", async () => {
    const zooNFTDelegate = await ZooNFTDelegate.new();
    await zooNFTDelegate.initialize(alice);
    await zooNFTDelegate.setBaseURI('https://gateway.pinata.cloud/ipfs/');
    await zooNFTDelegate.setNftURI(1, 1, 1, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    let ret = await zooNFTDelegate.getNftURI(1, 1, 1);
    assert.strictEqual(ret, 'QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    await zooNFTDelegate.setNFTFactory(bob);
    await zooNFTDelegate.setNFTFactory(carol);

    await zooNFTDelegate.setScaleParams(1e11, 1e10, 1e9, 1e7);
    ret = await zooNFTDelegate.getBoosting(1);
    assert.strictEqual(ret.toString(), '1000000000000');
    await zooNFTDelegate.mint(1, 1, 1, 1, 100, { from: bob });

    ret = await zooNFTDelegate.tokenURI(1);
    assert.strictEqual(ret, 'https://gateway.pinata.cloud/ipfs/QmZ7ddzc9ZFF4dsZxfYhu26Hp3bh1Pq2koxYWkBY6vbeoN/apple.json');
    ret = await zooNFTDelegate.getBoosting(1);
    assert.strictEqual(ret.toString(), '12000000000');

    const boostingDelegate = await BoostingDelegate.new();
    await boostingDelegate.initialize(alice);

    try {
      await boostingDelegate.setFarmingAddr(minter, {from: bob});
      assert.fail('never go here');
    } catch (e) { 
      assert.ok(e.message.match(/revert/));
    }

    const zoo = await ZooToken.new({ from: alice });
    const farm = await ZooKeeperFarming.new(zoo.address, dev,
      boostingDelegate.address,
      '100',
      0,
      99999999,
      ZERO_ADDRESS,
      ZERO_ADDRESS, { from: alice });
    await zoo.transferOwnership(farm.address, { from: alice });

    await boostingDelegate.setFarmingAddr(farm.address);

    await boostingDelegate.setNFTAddress(zooNFTDelegate.address);

    let lp = await MockERC20.new('LPToken', 'LP', 18, '10000000000', { from: minter });
    await farm.add('100', lp.address, true, 0, false);

    await lp.transfer(alice, '1000', { from: minter });
    await lp.transfer(bob, '1000', { from: minter });
    await lp.transfer(carol, '1000', { from: minter });

    await lp.approve(farm.address, '1000', { from: alice });
    await lp.approve(farm.address, '1000', { from: bob });
    await lp.approve(farm.address, '1000', { from: carol });

    await farm.deposit(0, '100', 0, 0, { from: bob });
    await time.advanceBlock();
    ret = await farm.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '100');
    await zooNFTDelegate.approve(boostingDelegate.address, 1, {from: bob});
    await farm.deposit(0, '100', 0, 1, { from: bob });
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '300');
    for (let i=0; i<10; i++) {
      await time.advanceBlock();
    }
    ret = await farm.pendingZoo(0, bob);
    assert.strictEqual(ret.toString(), '1012');

    await farm.withdraw(0, 0, {from: bob});
    ret = await farm.pendingZoo(0, bob);
    assert.strictEqual((await zoo.balanceOf(bob)).toString(), '1413');
    assert.strictEqual((await zoo.balanceOf(dev)).toString(), '395');

    await farm.deposit(0, '200', 0, 0, { from: alice });
    await time.advanceBlock();

    assert.strictEqual('50', (await farm.pendingZoo(0, alice)).toString());
    assert.strictEqual('151', (await farm.pendingZoo(0, bob)).toString());

    await farm.deposit(0, '0', 3600*24*30, 0, { from: alice });
    await farm.withdraw(0, '0', { from: bob });
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();

    console.log('alice', (await farm.pendingZoo(0, alice)).toString());
    console.log('bob', (await farm.pendingZoo(0, bob)).toString());
    assert.strictEqual('220', (await farm.pendingZoo(0, alice)).toString());
    assert.strictEqual('151', (await farm.pendingZoo(0, bob)).toString());

    try {
      await farm.withdraw(0, '100', { from: alice });
      assert.fail('never go here');
    } catch (e) { 
      console.log(e);
      assert.ok(e.message.match(/revert/));
    }
    await farm.withdraw(0, '0', { from: alice });
    await farm.withdraw(0, '200', { from: bob });


    console.log('alice zoo', (await zoo.balanceOf(alice)).toString());
    console.log('bob lp', (await lp.balanceOf(bob)).toString());
    console.log('bob zoo', (await zoo.balanceOf(bob)).toString());


    // assert.strictEqual('430', (await zoo.balanceOf(alice)).toString());

    await farm.deposit(0, '100', 10, 0, { from: carol });
    console.log('carol zoo', (await zoo.balanceOf(carol)).toString());
    console.log('carol lp', (await lp.balanceOf(carol)).toString());
    try {
      await farm.withdraw(0, '100', { from: carol });
      console.log('never go here.');
      assert.fail('never go here');
    } catch (e) { 
      assert.ok(e.message.match(/revert/));
    }
    await sleep(6000);
    await time.advanceBlock();
    await sleep(6000);
    await time.advanceBlock();
    console.log('carol zoo', (await zoo.balanceOf(carol)).toString());
    console.log('carol lp', (await lp.balanceOf(carol)).toString());
    await farm.withdraw(0, '10', { from: carol });
    console.log('carol zoo', (await zoo.balanceOf(carol)).toString());
    console.log('carol lp', (await lp.balanceOf(carol)).toString());


    console.log(ret.toString());
  });
});
