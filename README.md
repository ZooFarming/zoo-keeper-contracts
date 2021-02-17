# ZOO KEEPER CONTRACTS

ZooKeeper mainly includes 6 contracts, Token, Farming, Boosting, NFT, NFT Factory, and Marketplace.

Among them, Token and Farming are non-upgradable contracts to guarantee the security of the user's principal.

Boosting, NFT, NFT Factory and Marketplace are upgradable contracts, which facilitate the future expansion of richer gameplay.

# DEVELOPMENT

```
$ yarn
$ yarn truffle compile
$ yarn truffle test
```

deploy sequence: 
1) NFT factory, proxy;
2) NFT, proxy;
3) Boosting, proxy;
4) ZooToken;
5) ZooFarming;
6) Marketplace, proxy;
