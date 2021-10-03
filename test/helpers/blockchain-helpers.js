const { time } = require('@openzeppelin/test-helpers');

async function impersonate(accounts) {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: accounts
  });
}

async function resetToBlock(blockNum, chain="mainnet"){
  let rpcUrl;
  switch(chain)
  {
    case "mainnet":
      rpcUrl = "https://eth-mainnet.alchemyapi.io/v2/" + process.env.ALCHEMY_KEY
      break;
    case "polygon":
      rpcUrl = "https://polygon-mainnet.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY_POLYGON
      break;
  }

  await hre.network.provider.request({
    method: "hardhat_reset",
    params: [{
      forking: {
        jsonRpcUrl: rpcUrl,
        blockNumber: blockNum
      }
    }]
  })
}

async function passTime(_time){
  await time.increase(_time);
  await time.advanceBlock();
}

module.exports = {
  impersonate,
  resetToBlock,
  passTime
};
