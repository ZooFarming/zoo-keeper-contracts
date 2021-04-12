const { expectRevert, time } = require('@openzeppelin/test-helpers');
const ZooToken = artifacts.require('ZooToken');
const MockERC20 = artifacts.require('MockERC20');
const WaspToken = artifacts.require('WaspToken');
const WWAN = artifacts.require('WWAN');
const SafariDelegate = artifacts.require('SafariDelegate');
const assert = require('assert');
const sleep = require('ko-sleep');


contract('ZooKeeperFarming', ([alice, bob, carol, dev, minter]) => {
  let zoo;
  let wwan;
  let wasp;
  let safari;
  let lp1;
  let lp2;
  let lp3;
  let lp4;

  beforeEach(async () => {
    zoo = await ZooToken.new();
    await zoo.mint(alice, '1000000');
    await zoo.mint(bob, '1000000');
    await zoo.mint(carol, '1000000');
    await zoo.mint(dev, '1000000');
    await zoo.mint(minter, '1000000');

    lp1 = await MockERC20.new('LP', 'LP', 18, 10000000);
    lp2 = await MockERC20.new('LP', 'LP', 18, 10000000);
    lp3 = await MockERC20.new('LP', 'LP', 18, 10000000);
    lp4 = await MockERC20.new('LP', 'LP', 18, 10000000);

    wwan = await WWAN.new();
    wasp = await WaspToken.new();

    safari = await SafariDelegate.new();
    await safari.initialize(alice, wwan.address);
  });

  

});
