// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Constants used to initialize the Tokens and Controller contracts.

// The percentage of ICE that is lost when you make a transfer of ICE
uint256 constant D_ICE_TRANSFER_TAX = 2e16;

// Token Initial supplies.
uint256 constant D_INITIAL_ICE_SUPPLY = 10000e18;
uint256 constant D_INITIAL_H2O_SUPPLY = 10000000e18;
uint256 constant D_INITIAL_STM_SUPPLY = 1000000e18;

// Token initial Prices in H2O/

//todo decide initial pool size
uint256 constant D_INITIAL_ICE_POOL_H2O_SIZE = 1000000e18;
uint256 constant D_INITIAL_ICE_PRICE = 25e18;

//todo decide initial pool size
uint256 constant D_INITIAL_STM_POOL_H2O_SIZE = 1000000e18;
uint256 constant D_INITIAL_STM_PRICE = 5e18;

// The relationship between the accumulated error and the condensation rate
int256 constant D_CONDENSATION_FACTOR = 2e7 / int256(1 days);

// The relationships between the error and the steam price adjustment
int256 constant D_STEAM_PRICE_FACTOR = 1e18;

// How long it takes for the current steam price to adjust to the target steam price
uint256 constant I_STM_PRICE_CHANGE_PERIOD = 10 days;

// How long it takes for the current condensation to adjust to the target condensation rate
uint256 constant I_CONDENSATION_RATE_CHANGE_PERIOD = 1 days;

// How long it takes for the target ice price to adjust to the current ice price
uint256 constant I_ICE_PRICE_CHANGE_PERIOD = uint256(100 days);

// Inital melt and condensation rates in H2O per reward (Ice*second) per second.
uint256 constant D_INITIAL_MELT_RATE = 1e18 / uint256(365 days);
uint256 constant D_INITIAL_CONDENSATION_RATE = 1e17 / uint256(365 days);

// Vent Withdrawal Period
uint256 constant I_VENT_WITHDRAWAL_PERIOD = 2 * uint256(365 days);