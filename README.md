# ZOO KEEPER CONTRACTS

ZooKeeper mainly includes 6 contracts, Token, Farming, Boosting, NFT, NFT Factory, and Marketplace.

Among them, Token and Farming are non-upgradable contracts to guarantee the security of the user's principal.

Boosting, NFT, NFT Factory and Marketplace are upgradable contracts, which facilitate the future expansion of richer gameplay.

deploy sequence: 
1) NFT factory, proxy;
2) NFT, proxy;
3) Boosting, proxy;
4) ZooToken;
5) ZooFarming;
6) Marketplace, proxy;

# DEVELOPMENT

```
$ yarn
$ yarn global add ganache-cli
$ yarn test

  Contract: BoostingDelegate
    ✓ should failed when initialize again (68ms)
    ✓ should success when set params (134ms)
    ✓ should failed when set params without access (123ms)
    ✓ should success when transfer admin (174ms)
    ✓ should failed when transfer admin without access (48ms)
    ✓ should success when deposit no-lock (61ms)
    ✓ should failed when deposit no-lock without access (45ms)
    ✓ should success when withdraw no-lock (118ms)
    ✓ should failed when withdraw no-lock without access (102ms)
    ✓ should success when deposit with lock time (91ms)
    ✓ should failed when deposit with lock without access (134ms)
    ✓ should success when withdraw with lock time (5148ms)
    ✓ should failed when withdraw in lock time (202ms)
    ✓ should success when deposit no-lock to lock (472ms)
    ✓ should failed when deposit no-lock to lock without access (332ms)
    ✓ should success when withdraw with lock time (5287ms)
    ✓ should failed when withdraw in lock time (238ms)
    ✓ should success when deposit nft (160ms)
    ✓ should failed when deposit nft without access (828ms)
    ✓ should success when withdraw nft (167ms)
    ✓ should failed when withdraw nft without access (139ms)
    ✓ should success when deposit from no-nft to nft (1123ms)
    ✓ should failed when deposit from nft to non-nft (706ms)
    ✓ should success when withdraw from no-nft to nft (219ms)
    ✓ should failed when withdraw from no-nft to nft without access (1073ms)
    ✓ should success when deposit lock with nft (883ms)
    ✓ should success when deposit lock with nft (7397ms)
    ✓ check getMultiplier in different nft (1006ms)

  Contract: ZooKeeperFarming
    ✓ should success when transferOwner
    ✓ should failed when transferOwner without access (635ms)
    ✓ should success when add pool (1621ms)
    ✓ should failed when add pool without access (218ms)
    ✓ should success when update pool (127ms)
    ✓ should failed when update pool without access (120ms)
    ✓ should success when enable/disable dual farming (1737ms)
    ✓ should failed when enable/disable dual farming without access (90ms)
    ✓ should success when deposit 0 (103ms)
    ✓ should success when deposit amount (146ms)
    ✓ should success when pendingZoo (983ms)
    ✓ should success when withdraw 0 (1200ms)
    ✓ should success when withdraw amount (268ms)
    ✓ should success when farming amount (1544ms)
    ✓ should success when multi pool farming 1 (1207ms)
    ✓ should success when multi pool farming 2 (1353ms)
    ✓ should success when deposit 0 with dual farming (100ms)
    ✓ should success when deposit amount with dual farming (321ms)
    ✓ should success when pendingZoo with dual farming (220ms)
    ✓ should success when pendingWasp with dual farming (992ms)
    ✓ should success when withdraw 0 with dual farming (1098ms)
    ✓ should success when withdraw amount with dual farming (1943ms)
    ✓ should success when deposit 0 with lock-time (102ms)
    ✓ should success when deposit 0 with lock longer (2694ms)
    ✓ should success when deposit amount with lock-time (2842ms)
    ✓ should success when deposit amount with lock longer (1102ms)
    ✓ should success when deposit amount no-lock to lock (1961ms)
    ✓ should success when withdraw 0 with lock time (793ms)
    ✓ should success when withdraw amount with lock time 1 (1081ms)
    ✓ should success when withdraw amount with lock time 2 (5413ms)
    ✓ should success when withdraw amount no-lock to lock 1 (1052ms)
    ✓ should success when withdraw amount no-lock to lock 2 (6689ms)
    ✓ should success when deposit 0 with NFT (124ms)
    ✓ should success when deposit amount with NFT (192ms)
    ✓ should success when deposit 0 no nft to nft (1013ms)
    ✓ should success when deposit amount no nft to nft (1206ms)
    ✓ should success when withdraw 0 with nft (1913ms)
    ✓ should success when withdraw 0 with nft (1974ms)
    ✓ deposit 0 with nft,lock-time,dual farming (140ms)
    ✓ deposit amount with nft,lock-time,dual farming (316ms)
    ✓ withdraw 0 with nft,lock-time,dual farming (1356ms)
    ✓ withdraw amount with nft,lock-time,dual farming (7971ms)

  Contract: MarketplaceDelegate
    ✓ should success when create sell order (625ms)
    ✓ should failed when create illegal sell order (1328ms)
    ✓ should success when get order (2637ms)
    ✓ should failed when get order non
    ✓ should success when check order (3513ms)
    ✓ should failed when check order illegal (371ms)
    ✓ should success when cancel order (3098ms)
    ✓ should failed when cancel others order (1811ms)
    ✓ should success when order expiration cancel (9365ms)
    ✓ should failed when expiration order buy (4849ms)
    ✓ should success when clean order (3922ms)
    ✓ should success when buy order (2563ms)
    ✓ should failed when buy order token not enough (645ms)

  Contract: ZooNFTDelegate
    ✓ should success when set factory (296ms)
    ✓ should failed when set factory without access (40ms)
    ✓ should success when setScaleParams (40ms)
    ✓ should failed when setScaleParams without access (1335ms)
    ✓ should success when setURI (796ms)
    ✓ should failed when setURI without access (209ms)
    ✓ should success when getURI (2005ms)
    ✓ should empty when getURI without set (4985ms)
    ✓ should success when mint (2203ms)
    ✓ should failed when mint without access (3388ms)
    ✓ should success when getBoosting (20820ms)
    ✓ should 1e12 when getBoosting non-token (2746ms)
    ✓ should success when getTokenURI (2147ms)
    ✓ should failed when getTokenURI non token (519ms)
    ✓ should success when getTokenInfo (1230ms)
    ✓ should 0 when getTokenInfo non token (1101ms)
    ✓ should success when setMultiNftURI (1202ms)
    ✓ should failed when setMultiNftURI without access (3139ms)

  Contract: NFTFactoryDelegate
    ✓ should success when buy silver chest (11404ms)
    ✓ should failed when buy silver chest without enough zoo (783ms)
    ✓ should success when buy golden chest (783ms)
    ✓ should failed when buy golden chest without enough zoo (1056ms)
    ✓ should success when dynamic price config (4148ms)
    ✓ should failed when dynamic price config without access (829ms)
    ✓ should success when golden chest price config (890ms)
    ✓ should failed when golden chest price config without access (9029ms)
    ✓ should success when dynamic price auto change up (4985ms)
    ✓ should success when dynamic price auto change down (4985ms)
    ✓ should success when configStakePlanCount
    ✓ should failed when configStakePlanCount without access (41ms)
    ✓ should success when configStakePlanInfo (41ms)
    ✓ should failed when configStakePlanInfo without access (2548ms)
    ✓ should success when stake type 0 and withdraw (6883ms)
    ✓ should failed when stake type 0 and withdraw in lock time (4040ms)
    ✓ should success when check stake (153ms)
    ✓ should success when check claim (5351ms)

  Contract: ZooToken
    ✓ should success when mint (4140ms)
    ✓ should failed when mint without permission (894ms)
    ✓ should success when burn (1256ms)
    ✓ should failed when burn out of balance (2749ms)
    ✓ should success when transferOwner (1935ms)
    ✓ should failed when transferOwner without access (1399ms)

  Contract: ZooKeeperProxy
    ✓ should success when upgrade (809ms)
    ✓ should failed when upgrade without access (921ms)
    ✓ should success when changeAdmin (1964ms)
    ✓ should failed when changeAdmin without access (2428ms)
    ✓ should success when call to delegate function (3703ms)
    ✓ should failed when call to delegate function without access (5331ms)


  131 passing (24m)
```


