const ZooKeeperFarming = artifacts.require('ZooKeeperFarming');
const ZooToken = artifacts.require('ZooToken');
const assert = require('assert');
const { expectRevert, time } = require('@openzeppelin/test-helpers');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

contract("ZooKeeperFarming", accounts => {
  it("basic farming", async () => {
    const zooToken = await ZooToken.new();
    const wslp = await ZooToken.new();
    wslp.mint(accounts[0], '1000000000000000000');

    const zooKeeperFarming = await ZooKeeperFarming.new(
      zooToken.address,
      accounts[1],
      ZERO_ADDRESS,
      '10000000000000000000',
      0,
      99999999,
      ZERO_ADDRESS,
      ZERO_ADDRESS
    );
    await zooToken.transferOwnership(zooKeeperFarming.address);
    await zooKeeperFarming.add(100, wslp.address, true, 0);
    await wslp.approve(zooKeeperFarming.address, '0xf000000000000000000000000000000000000000');
    await zooKeeperFarming.deposit(0, 1000, 0, 0);
    await time.advanceBlock();
    let ret = await zooKeeperFarming.pendingZoo(0, accounts[0]);
    
    console.log(ret.toString());
  });
});

