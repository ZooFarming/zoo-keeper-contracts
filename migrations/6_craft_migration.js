// const Migrations = artifacts.require("Migrations");
const ElixirNFT = artifacts.require("ElixirNFT");
const Alchemy = artifacts.require('Alchemy');
const ZooKeeperProxy = artifacts.require('ZooKeeperProxy');
const RandomBeacon = artifacts.require('RandomBeacon');

module.exports = async function (deployer) {
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }
  // await deployer.deploy(KeepsakesCreatorDelegate);
  // return;

  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  //TODO: TESTNET CONFIG----------
  let proxyAdmin = '0x5560aF0F46D00FCeA88627a9DF7A4798b1b10961';
  let admin = '0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e';
  let zooToken = '0x890589dC8BD3F973dcAFcB02b6e1A133A76C8135';
  let zooNFT = '0xbCF9F4fae90dA7c4BB05DA6f9E9A9A39dc5Ce979';
  let nftFactory = '0x40B4653a2263c9A6634018365Fa5aa5a81E0b0Bd';
  let rbOperator = '0x4BD2c90F87d4880183126e24e9c2888E7DbeF17b';
  //--------------------
  //TODO: MAINNET CONFIG----------
  // let proxyAdmin = '0xa206e4858849f70c3d684e854e7C126EF7baB32e';
  // let admin = '0x83f83439Cc3274714A7dad32898d55D17f7C6611';
  //--------------------

  await deployer.deploy(ElixirNFT);
  await deployer.deploy(RandomBeacon);

  let elixirNFT = await ElixirNFT.deployed();

  let randomBeacon = await RandomBeacon.deployed();

  await randomBeacon.initialize(admin, rbOperator);

  await deployer.deploy(Alchemy);

  let alchemyDelegate = await Alchemy.deployed();

  await deployer.deploy(ZooKeeperProxy, alchemyDelegate.address, proxyAdmin, '0x');

  let alchemy = await alchemyDelegate.at((await ZooKeeperProxy.deployed()).address);
  
  // address admin,
  // address _elixirNFT,
  // address _buyToken,
  // address _priceOracle,
  // address _zooNFT,
  // address randomOracle_
  await alchemy.initialize(deployerAddr, elixirNFT.address, zooToken, nftFactory, zooNFT, randomBeacon.address);

  await elixirNFT.initialize(deployerAddr);

  await elixirNFT.setNFTFactory(alchemy.address);

  let tokenTypes = [];
  let metaJsons = [];
  for (let i=0; i<34; i++) {
    tokenTypes.push(i);
    metaJsons.push(`https://graph.wanswap.finance/ipfs/QmSkmbsimjqA3CF2BNgu9RXboxfRohDTYJcp8TXLYRFABV/${i+1}.json`);
  }
  await elixirNFT.setMultiNftURI(tokenTypes, metaJsons);

  await alchemy.grantRole('0x00', admin);
  await elixirNFT.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await alchemy.renounceRole('0x00', deployerAddr);
    await elixirNFT.renounceRole('0x00', deployerAddr);
  }

  console.log('alchemy:', alchemy.address);
  console.log('elixirNFT:', elixirNFT.address);
  console.log('randomBeacon:', randomBeacon.address);

}
