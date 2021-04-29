// const Migrations = artifacts.require("Migrations");
const SafariDelegate = artifacts.require("SafariDelegate");
const ZooKeeperProxy = artifacts.require("ZooKeeperProxy");

module.exports = async function (deployer) {
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }


  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  //TODO: TESTNET CONFIG----------
  let proxyAdmin = '0x5560aF0F46D00FCeA88627a9DF7A4798b1b10961';
  let admin = '0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e';
  let zooToken = '0x890589dC8BD3F973dcAFcB02b6e1A133A76C8135';
  let WWAN = '0x916283CC60FDAF05069796466Af164876E35D21F';
  //--------------------

  await deployer.deploy(SafariDelegate);

  let safariDelegate = await SafariDelegate.deployed();
  await deployer.deploy(ZooKeeperProxy, safariDelegate.address, proxyAdmin, '0x');

  let safari = await SafariDelegate.at((await ZooKeeperProxy.deployed()).address);
  
  await safari.initialize(admin, WWAN);

  await safari.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await safari.renounceRole('0x00', deployerAddr);
  }

  console.log('safari:', safari.address);

}