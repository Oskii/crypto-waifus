var ConvertLib = artifacts.require("./ConvertLib.sol");
var CryptoWaifus = artifacts.require("./CryptoWaifus.sol");
var CryptoWaifusMarket = artifacts.require("./CryptoWaifusMarket.sol");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, CryptoWaifus);
  deployer.deploy(CryptoWaifus);
  deployer.deploy(CryptoWaifusMarket);
};
