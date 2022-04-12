const IceToken = artifacts.require("IceToken");
const H2OToken = artifacts.require("H2OToken");
const SteamToken = artifacts.require("SteamToken");
const Controller = artifacts.require("Controller");


module.exports = async function (deployer, network, accounts) {

  // The account that is deploying the contracts
  const deployAddr = accounts[0];

  // Get the deployed tokens
  const ice = await IceToken.deployed();
  const h2o = await H2OToken.deployed();
  const stm = await SteamToken.deployed();

  // Get the tokens' DEFAULT_ADMIN_ROLE role
  const ICE_DEFAULT_ADMIN_ROLE = await ice.DEFAULT_ADMIN_ROLE.call();
  const H2O_DEFAULT_ADMIN_ROLE = await h2o.DEFAULT_ADMIN_ROLE.call();
  const STM_DEFAULT_ADMIN_ROLE = await stm.DEFAULT_ADMIN_ROLE.call();

  // Deploy Controller
  await deployer.deploy(Controller, ice.address, h2o.address, stm.address);
  const controller = await Controller.deployed();

  // TODO: the deploy process involves many separate transactions to set the
  //       different roles. After the Tokens and controller are deployed, the
  //       process of setting the roles could be moved into a single transaction
  //       of a Deploy contract - a one use contract that could self destroy
  //       after doing its job. For now we leave all these steps as separate
  //       transactions.

  // Add the Controller as an admin of the token contracts.
  await ice.grantRole(ICE_DEFAULT_ADMIN_ROLE, controller.address, {from:deployAddr});
  await h2o.grantRole(H2O_DEFAULT_ADMIN_ROLE, controller.address, {from:deployAddr});
  await stm.grantRole(STM_DEFAULT_ADMIN_ROLE, controller.address, {from:deployAddr});

  // Make sure the deploy account renounces the admin role. Only the controller
  // will be the admin of the tokens after this.
  await ice.renounceRole(ICE_DEFAULT_ADMIN_ROLE, deployAddr, {from:deployAddr});
  await h2o.renounceRole(H2O_DEFAULT_ADMIN_ROLE, deployAddr, {from:deployAddr});
  await stm.renounceRole(STM_DEFAULT_ADMIN_ROLE, deployAddr, {from:deployAddr});
  
  // Give the internal VirtualPools the appropriate roles to mint/burn the
  // tokens, now that the Controller has the admin role.
  await controller.initTokenRoles();

  
  // At the end, just check if all the roles are correctly set.
  if (await ice.getRoleMemberCount.call(ICE_DEFAULT_ADMIN_ROLE) != 1) {
    throw 'Invalid number of admins in IceToken after Controller deployment!';
  }

  if (await ice.getRoleMember.call(ICE_DEFAULT_ADMIN_ROLE, 0) != controller.address) {
    throw 'Invalid admins in IceToken after Controller deployment!';
  }

  if (await h2o.getRoleMemberCount.call(H2O_DEFAULT_ADMIN_ROLE) != 1) {
    throw 'Invalid number of admins in H2OToken after Controller deployment!';
  }

  if (await h2o.getRoleMember.call(H2O_DEFAULT_ADMIN_ROLE, 0) != controller.address) {
    throw 'Invalid admin in H2OToken after Controller deployment!';
  }

  if (await stm.getRoleMemberCount.call(STM_DEFAULT_ADMIN_ROLE) != 1) {
    throw 'Invalid number of admins in StmToken after Controller deployment!';
  }

  if (await stm.getRoleMember.call(STM_DEFAULT_ADMIN_ROLE, 0) != controller.address) {
    throw 'Invalid admin in StmToken after Controller deployment!';
  }


};
