# ZOO KEEPER CONTRACTS

ZooKeeper mainly includes 6 contracts, Token, Farming, Boosting, NFT, NFT Factory, and Marketplace.

Among them, Token, Farming and NFT are non-upgradable contracts to guarantee the security of the user's principal.

Boosting, NFT Factory and Marketplace are upgradable contracts, which facilitate the future expansion of richer gameplay.

deploy sequence: 
1) NFT factory, proxy;
2) NFT;
3) Boosting, proxy;
4) ZooToken;
5) ZooFarming;
6) Marketplace, proxy;

# MAINNET DEPLOY

```
-------------------------------
nftFactory: 0xBCE166860F514b6134AbC6E9Aa0005CC489b6352
zooNFT: 0x38034B2E6ae3fB7FEC5D895a9Ff3474bA0c283F6
boosting: 0x1590cc5967DBa3fAC7F1A825EAE7b6442aEFc082
marketplace: 0x6b7466C38Dd007F5aC20659A71d96412840b4EFd
zooToken: 0x6e11655d6aB3781C6613db8CB1Bc3deE9a7e111F
zooKeeperFarming: 0x4E4Cb1b0b4953EA657EAF29198eD79C22d1a74A2
------------------------------
Zoo farming start block: 14174838
Zoo farming end Block: 14174838 + 3600/5*24*365*2
Zoo per block: 10 zoo per block
```

# DEVELOPMENT

```
$ yarn
$ yarn global add ganache-cli
$ ganache-cli
$ yarn test

yarn run v1.22.10
$ yarn truffle test
$ /Users/molin/workspace/dapp/ZooKeeper/zoo-keeper-contracts/node_modules/.bin/truffle test
Using network 'development'.


Compiling your contracts...
===========================
> Compiling ./contracts/Boosting/BoostingDelegate.sol
> Compiling ./contracts/Farming/ZooKeeperFarming.sol
> Compiling ./contracts/Marketplace/MarketplaceDelegate.sol
> Compiling ./contracts/NFT/ZooNFT.sol
> Compiling ./contracts/NFTFactory/NFTFactoryDelegate.sol
> Compiling ./contracts/NFTFactory/NFTFactoryStorage.sol
> Compiling ./contracts/Proxy/ZooKeeperProxy.sol
> Compiling ./contracts/test/MockERC20.sol
> Compiling ./contracts/test/WanSwapFarm.sol
> Compiling ./contracts/test/WaspToken.sol
> Artifacts written to /var/folders/6s/h8j4bzwd2qn1tkllspwsxvlh0000gn/T/test--18409-ik5JKd8cldmZ
> Compiled successfully using:
   - solc: 0.6.12+commit.27d51765.Emscripten.clang

web3-shh package will be deprecated in version 1.3.5 and will no longer be supported.
web3-bzz package will be deprecated in version 1.3.5 and will no longer be supported.


  Contract: BoostingDelegate
    ✓ should failed when initialize again (43ms)
    ✓ should success when set params (101ms)
    ✓ should failed when set params without access (168ms)
    ✓ should success when transfer admin (249ms)
    ✓ should failed when transfer admin without access
    ✓ should success when deposit no-lock (68ms)
    ✓ should failed when deposit no-lock without access (50ms)
    ✓ should success when withdraw no-lock (119ms)
    ✓ should failed when withdraw no-lock without access (113ms)
    ✓ should success when deposit with lock time (69ms)
    ✓ should failed when deposit with lock without access (69ms)
    ✓ should success when withdraw with lock time (5203ms)
    ✓ should failed when withdraw in lock time (200ms)
    ✓ should success when deposit no-lock to lock (359ms)
    ✓ should failed when deposit no-lock to lock without access (304ms)
    ✓ should success when withdraw with lock time (5241ms)
    ✓ should failed when withdraw in lock time (198ms)
    ✓ should success when deposit nft (187ms)
    ✓ should failed when deposit nft without access (104ms)
    ✓ should success when withdraw nft (343ms)
    ✓ should failed when withdraw nft without access (216ms)
    ✓ should success when deposit from no-nft to nft (1176ms)
    ✓ should failed when deposit from nft to non-nft (1122ms)
    ✓ should success when withdraw from no-nft to nft (1050ms)
    ✓ should failed when withdraw from no-nft to nft without access (184ms)
    ✓ should success when deposit lock with nft (88ms)
    ✓ should success when deposit lock with nft (6145ms)
    ✓ check getMultiplier in different nft (195ms)

  Contract: ZooKeeperFarming
    ✓ should success when transferOwner
    ✓ should failed when transferOwner without access (1146ms)
    ✓ should success when add pool (1921ms)
    ✓ should failed when add pool without access (49ms)
    ✓ should success when update pool (933ms)
    ✓ should failed when update pool without access (96ms)
    ✓ should success when enable/disable dual farming (1247ms)
    ✓ should failed when enable/disable dual farming without access (102ms)
    ✓ should success when deposit 0 (86ms)
    ✓ should success when deposit amount (117ms)
    ✓ should success when pendingZoo (926ms)
    ✓ should success when withdraw 0 (1023ms)
    ✓ should success when withdraw amount (1317ms)
    ✓ should success when farming amount (1112ms)
    ✓ should success when multi pool farming 1 (2421ms)
    ✓ should success when multi pool farming 2 (1199ms)
    ✓ should success when deposit 0 with dual farming (666ms)
    ✓ should success when deposit amount with dual farming (758ms)
    ✓ should success when pendingZoo with dual farming (255ms)
    ✓ should success when pendingWasp with dual farming (193ms)
    ✓ should success when withdraw 0 with dual farming (1117ms)
    ✓ should success when withdraw amount with dual farming (1267ms)
    ✓ should success when deposit 0 with lock-time (715ms)
    ✓ should success when deposit 0 with lock longer (913ms)
    ✓ should success when deposit amount with lock-time (1066ms)
    ✓ should success when deposit amount with lock longer (1263ms)
    ✓ should success when deposit amount no-lock to lock (931ms)
    ✓ should success when withdraw 0 with lock time (1200ms)
    ✓ should success when withdraw amount with lock time 1 (1210ms)
    ✓ should success when withdraw amount with lock time 2 (5268ms)
    ✓ should success when withdraw amount no-lock to lock 1 (1037ms)
    ✓ should success when withdraw amount no-lock to lock 2 (6090ms)
    ✓ should success when deposit 0 with NFT (120ms)
    ✓ should success when deposit amount with NFT (751ms)
    ✓ should success when deposit 0 no nft to nft (1116ms)
    ✓ should success when deposit amount no nft to nft (1192ms)
    ✓ should success when withdraw 0 with nft (1387ms)
    ✓ should success when withdraw 0 with nft (1432ms)
    ✓ deposit 0 with nft,lock-time,dual farming (982ms)
    ✓ deposit amount with nft,lock-time,dual farming (1128ms)
    ✓ withdraw 0 with nft,lock-time,dual farming (1990ms)
    ✓ withdraw amount with nft,lock-time,dual farming (8071ms)

  Contract: MarketplaceDelegate
    ✓ should success when create sell order (201ms)
    ✓ should failed when create illegal sell order (1154ms)
    ✓ should success when get order (2289ms)
    ✓ should failed when get order non
    ✓ should success when check order (2288ms)
    ✓ should failed when check order illegal
    ✓ should success when cancel order (2566ms)
    ✓ should failed when cancel others order (416ms)
    ✓ should success when order expiration cancel (2546ms)
    ✓ should failed when expiration order buy (4639ms)
    ✓ should success when clean order (4279ms)
    ✓ should success when buy order (5120ms)
    ✓ should failed when buy order token not enough (1260ms)

  Contract: ZooNFT
    ✓ should success when set factory (39ms)
    ✓ should failed when set factory without access (700ms)
    ✓ should success when setScaleParams (41ms)
    ✓ should failed when setScaleParams without access (43ms)
    ✓ should success when setURI (815ms)
    ✓ should failed when setURI without access (1548ms)
    ✓ should success when getURI (831ms)
    ✓ should empty when getURI without set (984ms)
    ✓ should success when mint (2081ms)
    ✓ should failed when mint without access (2786ms)
    ✓ should success when getBoosting (13141ms)
    ✓ should 1e12 when getBoosting non-token (415ms)
    ✓ should success when getTokenURI (3326ms)
    ✓ should failed when getTokenURI non token (374ms)
    ✓ should success when getTokenInfo (2435ms)
    ✓ should 0 when getTokenInfo non token (384ms)
    ✓ should success when setMultiNftURI (1596ms)
    ✓ should failed when setMultiNftURI without access (558ms)

  Contract: NFTFactoryDelegate
    ✓ should success when buy silver chest (28848ms)
    ✓ should failed when buy silver chest without enough zoo (2301ms)
    ✓ should success when buy golden chest (2537ms)
    ✓ should failed when buy golden chest without enough zoo (12826ms)
    ✓ should success when dynamic price config (39ms)
    ✓ should failed when dynamic price config without access (1375ms)
    ✓ should success when golden chest price config (734ms)
    ✓ should failed when golden chest price config without access (405ms)
    ✓ should success when dynamic price auto change up (8876ms)
    ✓ should success when dynamic price auto change down (33230ms)
    ✓ should success when configStakePlanCount (38ms)
    ✓ should failed when configStakePlanCount without access (1813ms)
    ✓ should success when configStakePlanInfo (1376ms)
    ✓ should failed when configStakePlanInfo without access (839ms)
    ✓ should success when stake type 0 and withdraw (7698ms)
    ✓ should failed when stake type 0 and withdraw in lock time (1405ms)
    ✓ should success when check stake (1254ms)
    ✓ should success when check claim (9143ms)

  Contract: ZooToken
    ✓ should success when mint (3890ms)
    ✓ should failed when mint without permission (43ms)
    ✓ should success when burn (2121ms)
    ✓ should failed when burn out of balance (97ms)
    ✓ should success when transferOwner (44ms)
    ✓ should failed when transferOwner without access (394ms)

  Contract: ZooKeeperProxy
    ✓ should success when upgrade (59ms)
    ✓ should failed when upgrade without access (841ms)
    ✓ should success when changeAdmin (1496ms)
    ✓ should failed when changeAdmin without access (10369ms)
    ✓ should success when call to delegate function (9576ms)
    ✓ should failed when call to delegate function without access (4624ms)


  131 passing (24m)

✨  Done in 1456.21s.

```


