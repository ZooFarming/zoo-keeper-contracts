// const Migrations = artifacts.require("Migrations");
const NFTFactoryDelegate = artifacts.require("NFTFactoryDelegate");
const ZooKeeperProxy = artifacts.require("ZooKeeperProxy");
const ZooNFTDelegate = artifacts.require('ZooNFTDelegate');
const BoostingDelegate = artifacts.require('BoostingDelegate');
const ZooToken = artifacts.require('ZooToken');
const ZooKeeperFarming = artifacts.require('ZooKeeperFarming');
const MarketplaceDelegate = artifacts.require('MarketplaceDelegate');

module.exports = async function (deployer) {
  if (deployer.network === 'development') {
    console.log('no need migration');
    return;
  }

  let deployerAddr = deployer.provider.addresses[0];
  let proxyAdmin = '0x5560af0f46d00fcea88627a9df7a4798b1b10961';
  let admin = '0x4cf0a877e906dead748a41ae7da8c220e4247d9e';
  let wanswapFarmingAddr = '0x01ecaa58733a9232ae5f1d2f74c643f2f8b3bb91';
  let waspTokenAddr = '0x830053dabd78b4ef0ab0fec936f8a1135b68da6f';
  let dividerAddr = '0xa658e95521ffa7537365cc1b01af3b174d873669';

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
    dividerAddr,
    boosting.address,
    '0x8ac7230489e80000', // 10 ZOO per block
    12358300,
    12358300 + 3600/5*24*365*2,
    wanswapFarmingAddr,
    waspTokenAddr,
    );

  let zooKeeperFarming = await ZooKeeperFarming.deployed();
  await zooKeeperFarming.transferOwnership(admin);
  await zooToken.transferOwnership(zooKeeperFarming.address);

  await nftFactory.initialize(deployerAddr, zooToken.address, zooNFT.address);
  await zooNFT.initialize(deployerAddr);
  await boosting.initialize(deployerAddr);
  await marketplace.initialize(deployerAddr);

  // init zoo boost---------------
  let pr =[];
  for (let i=1; i<=4; i++) {
    for (let c=1; c<=6; c++) {
      for (let e=1; e<=5; e++) {
        console.log('getLevelChance', i, c, e);
        let ret = await zooNFT.getLevelChance(i, c, e, {from: admin});
        pr.push(Number(Number(ret.toString())/1e10).toFixed(5));
      }
    }
  }
  
  function unique (arr) {
    return Array.from(new Set(arr))
  }

  let pn = unique(pr.sort().reverse());

  let chances = [];
  let boosts = [];
  let reduces = [];
  for(let i=0; i < pn.length; i++) {
    chances.push('0x' + Number((pn[i]*1e10).toFixed(0)).toString(16));
    boosts.push('0x' + Number(((i+1)*1e10).toFixed(0)).toString(16));
    reduces.push('0x' + Number((1e10 + i*2e9).toFixed(0)).toString(16));
  }

  await zooNFT.setBoostMap(chances, boosts, reduces);
  await zooNFT.setNFTFactory(nftFactory.address);
  await zooNFT.setNFTFactory(admin);
  //--------------------------

  // init boosting
  await boosting.setFarmingAddr(zooKeeperFarming.address);
  await boosting.setNFTAddress(zooNFT.address);


  await nftFactory.grantRole('0x00', admin);
  await nftFactory.renounceRole('0x00', deployerAddr);
  await zooNFT.grantRole('0x00', admin);
  await zooNFT.renounceRole('0x00', deployerAddr);
  await boosting.grantRole('0x00', admin);
  await boosting.renounceRole('0x00', deployerAddr);
  await marketplace.grantRole('0x00', admin);
  await marketplace.renounceRole('0x00', deployerAddr);

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
  console.log('dividerAddr:', dividerAddr);
  console.log('deployerAddr:', deployerAddr);

};
