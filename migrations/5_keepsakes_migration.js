// const Migrations = artifacts.require("Migrations");
const KeepsakesNFT = artifacts.require("KeepsakesNFT");
const KeepsakesCreatorDelegate = artifacts.require("KeepsakesCreatorDelegate");
const ZooKeeperProxy = artifacts.require('ZooKeeperProxy');

module.exports = async function (deployer) {
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }
  await deployer.deploy(KeepsakesCreatorDelegate);
  return;

  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  //TODO: TESTNET CONFIG----------
  // let proxyAdmin = '0x5560aF0F46D00FCeA88627a9DF7A4798b1b10961';
  // let admin = '0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e';
  //--------------------
  //TODO: MAINNET CONFIG----------
  let proxyAdmin = '0xa206e4858849f70c3d684e854e7C126EF7baB32e';
  let admin = '0x83f83439Cc3274714A7dad32898d55D17f7C6611';
  //--------------------

  await deployer.deploy(KeepsakesNFT);

  let nft = await KeepsakesNFT.deployed();


  await deployer.deploy(KeepsakesCreatorDelegate);

  let creatorDelegate = await KeepsakesCreatorDelegate.deployed();

  await deployer.deploy(ZooKeeperProxy, creatorDelegate.address, proxyAdmin, '0x');

  let creator = await KeepsakesCreatorDelegate.at((await ZooKeeperProxy.deployed()).address);
  
  await creator.initialize(deployerAddr, nft.address);

  await nft.initialize(deployerAddr);

  await nft.setNFTFactory(creator.address);

  // TODO:
  await creator.addAuthor('0xd3fe1259A31285786F59Fb80c4c7065403071591'); // PHX creator

  await creator.grantRole('0x00', admin);
  await nft.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await creator.renounceRole('0x00', deployerAddr);
    await nft.renounceRole('0x00', deployerAddr);
  }

  console.log('keepsakes creator:', creator.address);

}
