const IceToken = artifacts.require("IceToken");
const H2OToken = artifacts.require("H2OToken");
const SteamToken = artifacts.require("SteamToken");


module.exports = async function (deployer, network, accounts) {

  // The account that is deploying the contracts, which will be set as the admin
  // of the tokens.
  const deployAddr = accounts[0];

  // Deploy IceToken
  await deployer.deploy(IceToken, deployAddr);

  // Deploy H2OToken
  await deployer.deploy(H2OToken, deployAddr);

  // Deploy SteamToken
  await deployer.deploy(SteamToken, deployAddr);
};
