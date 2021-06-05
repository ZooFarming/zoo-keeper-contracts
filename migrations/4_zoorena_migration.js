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
  //TODO: TESTNET CONFIG----------
  let proxyAdmin = '0x5560aF0F46D00FCeA88627a9DF7A4798b1b10961';
  let admin = '0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e';
  let robot = '0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e';
  let zooToken = '0x890589dC8BD3F973dcAFcB02b6e1A133A76C8135';
  let nftFactory = '0x40B4653a2263c9A6634018365Fa5aa5a81E0b0Bd';
  let zooNFT = '0xbCF9F4fae90dA7c4BB05DA6f9E9A9A39dc5Ce979';
  let posRandom = '0x0000000000000000000000000000000000000262';
  //--------------------

  await deployer.deploy(ZoorenaDelegate);

  let zoorenaDelegate = await ZoorenaDelegate.deployed();
  await deployer.deploy(ZooKeeperProxy, zoorenaDelegate.address, proxyAdmin, '0x');

  let zoorena = await ZoorenaDelegate.at((await ZooKeeperProxy.deployed()).address);
  
  await zoorena.initialize(deployerAddr, zooToken, nftFactory, zooNFT, posRandom);

  await zoorena.configRobot(robot);

  await zoorena.configEventOptions(0, 2);
  await zoorena.configEventOptions(1, 4);
  await zoorena.configEventOptions(2, 8);
  await zoorena.configEventOptions(3, 4);
  await zoorena.configEventOptions(4, 2);
  await zoorena.configEventOptions(5, 4);
  await zoorena.configEventOptions(6, 8);
  await zoorena.configEventOptions(7, 10);
  await zoorena.configEventOptions(8, 3);

  await zoorena.configTime(1622851200, 24*3600, 15*3600);

  await zoorena.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await zoorena.renounceRole('0x00', deployerAddr);
  }

  console.log('zoorena:', zoorena.address);

}