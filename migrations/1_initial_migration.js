// const Migrations = artifacts.require("Migrations");
const NFTFactoryDelegate = artifacts.require("NFTFactoryDelegate");
const ZooKeeperProxy = artifacts.require("ZooKeeperProxy");
const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const BoostingDelegate = artifacts.require('BoostingDelegate');
const ZooToken = artifacts.require('ZooToken');
const ZooKeeperFarming = artifacts.require('ZooKeeperFarming');
const MarketplaceDelegate = artifacts.require('MarketplaceDelegate');

module.exports = async function (deployer) {
  let proxyAdmin = '0x5560af0f46d00fcea88627a9df7a4798b1b10961';
  let admin = '0x4cf0a877e906dead748a41ae7da8c220e4247d9e';
  let wanswapFarmingAddr = '0x01ecaa58733a9232ae5f1d2f74c643f2f8b3bb91';
  let waspTokenAddr = '0x830053dabd78b4ef0ab0fec936f8a1135b68da6f';

  await deployer.deploy(NFTFactoryDelegate);
  await deployer.deploy(ZooNFTDelegate);
  await deployer.deploy(BoostingDelegate);
  await deployer.deploy(MarketplaceDelegate);
  
  let nftFactoryDelegate = await NFTFactoryDelegate.deployed();
  let zooNFTDelegate = await ZooNFTDelegate.deployed()
  let boostingDelegate = await BoostingDelegate.deployed();
  let marketplaceDelegate = await MarketplaceDelegate.deployed();

  await deployer.deploy(ZooKeeperProxy, nftFactoryDelegate.address, proxyAdmin, '0x');
  let nftFactory = await NFTFactoryDelegate.at((await ZooKeeperProxy.deployed()).address);

  await deployer.deploy(ZooKeeperProxy, zooNFTDelegate.address, proxyAdmin, '0x');
  let zooNFT = await ZooNFTDelegate.at((await ZooKeeperProxy.deployed()).address);

  await deployer.deploy(ZooKeeperProxy, boostingDelegate.address, proxyAdmin, '0x');
  let boosting = await BoostingDelegate.at((await ZooKeeperProxy.deployed()).address);

  await deployer.deploy(ZooKeeperProxy, marketplaceDelegate.address, proxyAdmin, '0x');
  let marketplace = await MarketplaceDelegate.at((await ZooKeeperProxy.deployed()).address);

  await deployer.deploy(ZooToken);
  let zooToken = await ZooToken.deployed();

  await deployer.deploy(ZooKeeperFarming,
    zooToken.address,
    admin,
    boosting.address,
    '0x8ac7230489e80000', // 10 ZOO per block
    12358300,
    12358300 + 3600/5*24*365*2,
    wanswapFarmingAddr,
    waspTokenAddr,
    );

  let zooKeeperFarming = await ZooKeeperFarming.deployed();
  
  await zooToken.transferOwnership(zooKeeperFarming.address);
  await nftFactory.initialize(admin, zooToken.address, zooNFT.address);
  await zooNFT.initialize(admin);
  await boosting.initialize(admin);
  await marketplace.initialize(admin);

  console.log('-------------------------------');
  console.log('nftFactory:', nftFactory.address);
  console.log('zooNFT:', zooNFT.address);
  console.log('boosting:', boosting.address);
  console.log('marketplace:', marketplace.address);
  console.log('zooToken:', zooToken.address);
  console.log('zooKeeperFarming:', zooKeeperFarming.address);
  console.log('------------------------------')
  console.log('proxy admin:', proxyAdmin);
  console.log('control admin:', admin);
  console.log('waspToken:', waspTokenAddr);
  console.log('wanswapFarmingAddr:', wanswapFarmingAddr);

};
