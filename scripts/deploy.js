
let { addrList,getContractByABI,executeContract,getContract,getProxyslot,encodeFunction,sendTransaction,deploy,saveAddr,createFile,logTx,addrListAddObject } = require('./lib')
const fs = require("fs");
let configjson;
/*

*/

async function main() {
  await createFile()
  var data=fs.readFileSync('./config/config.json','utf-8');
  configjson = JSON.parse(data.toString());
  await exec()
  saveAddr(addrList)
}

async function exec() {
  let Incentive = await deploy('Incentive',0,'Incentive')
  let IncentivePorxy = await deploy('IncentivePorxy',0,'IncentivePorxy',Incentive.address)
  IncentivePorxy = await getContract('Incentive',IncentivePorxy.address)
  await executeContract("IncentivePorxy",0,IncentivePorxy,"initialize",configjson.IncentiveSigners)

  let LockValue = await deploy('LockValue',0,'LockValue')
  let LockValuePorxy = await deploy('LockValuePorxy',0,'LockValuePorxy',LockValue.address)
  LockValuePorxy = await getContract('LockValue',LockValuePorxy.address)
  await executeContract("LockValuePorxy",0,LockValuePorxy,"initialize",
      configjson.PROXY_REGISTRY,configjson.CDP_MANAGER,configjson.MCD_VAT,configjson.MCD_SPOT,configjson.MCD_JUG)

  let Rateup = await deploy('Rateup',0,'Rateup',configjson.CDP_MANAGER,configjson.MCD_VAT,configjson.MCD_JUG)


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  saveAddr(addrList)
  console.error(error);
  process.exitCode = 1;
});
