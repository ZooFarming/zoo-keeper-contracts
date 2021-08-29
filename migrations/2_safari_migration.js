// const Migrations = artifacts.require("Migrations");
const SafariDelegate = artifacts.require("SafariDelegate");
const SafariDelegateV2 = artifacts.require("SafariDelegateV2");
const ZooKeeperProxy = artifacts.require("ZooKeeperProxy");

module.exports = async function (deployer) {
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }

  // TODO: DEBUG
  await deployer.deploy(SafariDelegateV2);
  return;

  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  //TODO:  CONFIG----------
  let proxyAdmin = '0xa206e4858849f70c3d684e854e7C126EF7baB32e';
  let admin = '0x83f83439Cc3274714A7dad32898d55D17f7C6611';
  let zooToken = '0x6e11655d6aB3781C6613db8CB1Bc3deE9a7e111F';
  let WWAN = '0xdabd997ae5e4799be47d6e69d9431615cba28f48';
  //--------------------

  await deployer.deploy(SafariDelegate);

  let safariDelegate = await SafariDelegate.deployed();
  await deployer.deploy(ZooKeeperProxy, safariDelegate.address, proxyAdmin, '0x');

  let safari = await SafariDelegate.at((await ZooKeeperProxy.deployed()).address);
  
  await safari.initialize(deployerAddr, WWAN);

  await safari.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await safari.renounceRole('0x00', deployerAddr);
  }

  console.log('safari:', safari.address);

}