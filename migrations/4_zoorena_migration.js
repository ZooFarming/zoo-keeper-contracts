// const Migrations = artifacts.require("Migrations");
const ZoorenaDelegate = artifacts.require("ZoorenaDelegate");
const ZooKeeperProxy = artifacts.require("ZooKeeperProxy");

module.exports = async function (deployer) {
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }

  // TODO: DEBUG
  await deployer.deploy(ZoorenaDelegate);
  return;

  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  //TODO: MAINNET CONFIG----------
  let proxyAdmin = '0xa206e4858849f70c3d684e854e7C126EF7baB32e';
  let admin = '0x83f83439Cc3274714A7dad32898d55D17f7C6611';
  let robot = '0x840e14f597627b4d7aa77bc4001e2d0318c5bd7c';
  let zooToken = '0x6e11655d6aB3781C6613db8CB1Bc3deE9a7e111F';
  let nftFactory = '0xBCE166860F514b6134AbC6E9Aa0005CC489b6352';
  let zooNFT = '0x38034B2E6ae3fB7FEC5D895a9Ff3474bA0c283F6';
  let posRandom = '0x0000000000000000000000000000000000000262';
  //--------------------

  await deployer.deploy(ZoorenaDelegate);

  let zoorenaDelegate = await ZoorenaDelegate.deployed();
  await deployer.deploy(ZooKeeperProxy, zoorenaDelegate.address, proxyAdmin, '0x');

  let zoorena = await ZoorenaDelegate.at((await ZooKeeperProxy.deployed()).address);
  
  await zoorena.initialize(deployerAddr, zooToken, nftFactory, zooNFT, posRandom);

  await zoorena.configRobot(robot);

  await zoorena.configEventOptions(0, 2);
  await zoorena.configEventOptions(1, 2);
  await zoorena.configEventOptions(2, 3);
  await zoorena.configEventOptions(3, 4);
  await zoorena.configEventOptions(4, 4);
  await zoorena.configEventOptions(5, 6);
  await zoorena.configEventOptions(6, 6);
  await zoorena.configEventOptions(7, 8);
  await zoorena.configEventOptions(8, 10);
  await zoorena.configEventOptions(9, 12);

  // baseTime: UTC 2021-8-2 00:00:00
  // round time: 7 days
  // close time: every Sunday UTC 14:00
  await zoorena.configTime(1627862400, 7*24*3600, (14+24*6)*3600);

  await zoorena.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await zoorena.renounceRole('0x00', deployerAddr);
  }

  console.log('zoorena:', zoorena.address);

}