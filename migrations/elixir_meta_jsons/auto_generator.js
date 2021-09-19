const one = require('./1.json');
const fs = require('fs');

for (let i=0; i<33; i++) {
  let item = Object.assign({}, one);
  item.name = "ZooKeeper Elixir type " + (i + 2);
  item.image = "https://graph.wanswap.finance/ipfs/QmT7UZGbF1eB2TCwWSMaLGWawgaXyBvbVABjrccHnZBbbu/"+(i+2)+".png";
  item.attributes[0].value = i+2;
  fs.writeFileSync('./' + (i+2) + '.json', JSON.stringify(item, null, 4), 'utf-8');
}
