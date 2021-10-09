// const Migrations = artifacts.require("Migrations");
const NFTFactoryDelegate = artifacts.require("NFTFactoryDelegate");
const ZooKeeperProxy = artifacts.require("ZooKeeperProxy");
const ZooNFT = artifacts.require('ZooNFT');
const BoostingDelegate = artifacts.require('BoostingDelegate');
const ZooToken = artifacts.require('ZooToken');
const ZooKeeperFarming = artifacts.require('ZooKeeperFarming');
const MarketplaceDelegate = artifacts.require('MarketplaceDelegate');
const nftConfig = require('./nft_config.json');

module.exports = async function (deployer) {
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }

  // TODO: FIX
  await deployer.deploy(MarketplaceDelegate);
  return;


  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  let proxyAdmin = '0xa206e4858849f70c3d684e854e7c126ef7bab32e';
  let admin = '0x83f83439cc3274714a7dad32898d55d17f7c6611';
  let wanswapFarmingAddr = '0x7e5fe1e587a5c38b4a4a9ba38a35096f8ea35aac';
  let waspTokenAddr = '0x8b9f9f4aa70b1b0d586be8adfb19c1ac38e05e9a';
  let dividerAddr = '0x3019ed21591bee1e450874437018f39cd26a980b';

  await deployer.deploy(NFTFactoryDelegate);
  await deployer.deploy(ZooNFT);
  await deployer.deploy(BoostingDelegate);
  await deployer.deploy(MarketplaceDelegate);
  
  let nftFactoryDelegate = await NFTFactoryDelegate.deployed();
  let zooNFT = await ZooNFT.deployed()
  let boostingDelegate = await BoostingDelegate.deployed();
  let marketplaceDelegate = await MarketplaceDelegate.deployed();

  await deployer.deploy(ZooKeeperProxy, nftFactoryDelegate.address, proxyAdmin, '0x');
  let nftFactory = await NFTFactoryDelegate.at((await ZooKeeperProxy.deployed()).address);

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
    14174838, // UTC+8 2021-4-16 16:00
    14174838 + 3600/5*24*365*2,  // +2 YEAR
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
        let ret = await zooNFT.getLevelChance(i, c, e, {from: admin});
        console.log(i,c,e,ret.toString());
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

  console.log('ready to config NFT boost...');
  await zooNFT.setBoostMap(chances, boosts, reduces);
  await zooNFT.setNFTFactory(nftFactory.address);
  await zooNFT.setNFTFactory(admin);

  console.log('ready to config NFT URL...');
  await zooNFT.setMultiNftURI(nftConfig.levels.slice(0,60), nftConfig.categorys.slice(0,60), nftConfig.items.slice(0,60), nftConfig.URLs.slice(0,60));
  await zooNFT.setMultiNftURI(nftConfig.levels.slice(-60), nftConfig.categorys.slice(-60), nftConfig.items.slice(-60), nftConfig.URLs.slice(-60));
  console.log('NFT config finished.');
  //--------------------------
  // init boosting
  await boosting.setFarmingAddr(zooKeeperFarming.address);
  await boosting.setNFTAddress(zooNFT.address);


  await nftFactory.grantRole('0x00', admin);
  if (deployerAddr.toLowerCase() !== admin) {
    await nftFactory.renounceRole('0x00', deployerAddr);
  }

  await zooNFT.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin) {
    await zooNFT.renounceRole('0x00', deployerAddr);
  }

  await boosting.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin) {
    await boosting.renounceRole('0x00', deployerAddr);
  }

  await marketplace.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin) {
    await marketplace.renounceRole('0x00', deployerAddr);
  }

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
