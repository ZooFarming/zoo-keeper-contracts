const ZooHelperDelegate = artifacts.require("ZooHelperDelegate");
const ZooKeeperProxy = artifacts.require("ZooKeeperProxy");

module.exports = async function (deployer) {
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }


  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  //TODO: MAINNET CONFIG----------
  let proxyAdmin = '0xa206e4858849f70c3d684e854e7C126EF7baB32e';
  let admin = '0x83f83439Cc3274714A7dad32898d55D17f7C6611';
  let zooToken = '0x6e11655d6aB3781C6613db8CB1Bc3deE9a7e111F';
  let zooFarming = '0x4E4Cb1b0b4953EA657EAF29198eD79C22d1a74A2';
  let zooPair = '0xa0cf1f16994ecd6d4613024b3ebb61b9f9c06f06';
  let nftFactory = '0xBCE166860F514b6134AbC6E9Aa0005CC489b6352';
  let safari =     '0x0000000000000000000000000000000000000000';

  //--------------------

  await deployer.deploy(ZooHelperDelegate);

  let helperDelegate = await ZooHelperDelegate.deployed();
  await deployer.deploy(ZooKeeperProxy, helperDelegate.address, proxyAdmin, '0x');

  let helper = await ZooHelperDelegate.at((await ZooKeeperProxy.deployed()).address);
  console.log('ready to initialize');
  await helper.initialize(deployerAddr);

  console.log('ready to config');
  await helper.config(zooToken, zooFarming, zooPair, nftFactory, safari, {from: deployerAddr, gas: 1e7});

  console.log('ready to grantRole');
  await helper.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await helper.renounceRole('0x00', deployerAddr);
  }

  console.log('helper:', helper.address);

}
