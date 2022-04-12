// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/FixedPoint.sol";
import "./abstract/ERC20MintableBurnable.sol";

/** @title Virtual pool contract.
    @notice Creates a virtual pool that behaves like a typical constant product
        pool, but tokens are minted/burned during trades rather than being
        swapped with liquidity providers.
    @dev This is designed to be used inside another contract that should be set
        as its owner.
*/
contract VirtualPool is ReentrancyGuard, Ownable
{
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    ERC20MintableBurnable public tokenA;
    ERC20MintableBurnable public tokenB;

    uint256 public poolSizeA;
    uint256 public poolSizeB;

    /**
    @notice Constructor
    @param tokenA_ Token for first side of virtual pool.
    @param tokenB_ Token for second side of virtual pool.
    @param dPoolSizeA Amount of A tokens in the virtual pool with 18 decimals.
    @param dPoolSizeB Amount of B tokens in the virtual pool with 18 decimals.
    */
    constructor(
        ERC20MintableBurnable tokenA_,
        ERC20MintableBurnable tokenB_,
        uint256 dPoolSizeA,
        uint256 dPoolSizeB)
    {
        tokenA = tokenA_;
        tokenB = tokenB_;
        poolSizeA = dPoolSizeA;
        poolSizeB = dPoolSizeB;
    }

    /**
    @notice Returns the spot price of A tokens in the virtual pool in terms of B tokens.
    @return uint256 Price of A tokens with 18 decimals.
    */
    function priceA() public view returns(uint256) {
        return poolSizeB.div(poolSizeA);
    }
    
    /**
    @notice Changes the spot price of A tokens in the virtual pool by changing the amount of A tokens in the virtual pool.
    @param dPrice Price of A tokens in terms of B tokens with 18 decimals.
    */
    function setPriceA(uint256 dPrice) public onlyOwner {
        // Update the pool A size to achieve this price.
        poolSizeA = poolSizeB.div(dPrice);
    }

    /**
    @notice Returns the spot price of B tokens in the virtual pool in terms of A tokens.
    @return uint256 Price of B tokens with 18 decimals.
    */
    function priceB() public view returns(uint256) {
        return poolSizeA.div(poolSizeB);
    }

    /**
    @notice Changes the spot price of B tokens in the virtual pool by changing the amount of B tokens in the virtual pool.
    @param dPrice Price of B tokens in terms of A tokens with 18 decimals.
    */
    function setPriceB(uint256 dPrice) public onlyOwner {
        // Update the pool B size to achieve this price.
        poolSizeB = poolSizeA.div(dPrice);
    }

    /**
    @notice Changes the size of pools (for example to account for changes in the token supplies).
    @param dFactor Multiple by which to scale the pools with 18 decimals.
    */
    function scalePools(uint256 dFactor) public onlyOwner {
        poolSizeA = poolSizeA.mul(dFactor);
        poolSizeB = poolSizeB.mul(dFactor);
    }

    /**
    @notice Previews how many tokens would be sent to the user when swapping from A to B using the virtual pool.
    @param dAmountA Amount of token A to be swapped by the user with 18 decimals.
    @return uint256 Amount of token B to be sent to the user from the swap with 18 decimals.
    */
    function previewSwapAB(uint256 dAmountA) public view returns (uint256) {
        return calcSwapAmount(poolSizeA, poolSizeB, dAmountA);
    }

    /**
    @notice Updates pool sizes during a swap of token A for token B using the virtual pool.
    @param dAmountA Amount of token A to be swapped by the user with 18 decimals.
    @param sender Address of the person swapping the tokens.
    @return uint256 Amount of token B to be sent to by the user from the swap with 18 decimals.
    */
    function swapAB(uint256 dAmountA, address sender)
        public nonReentrant onlyOwner returns (uint256)
    {
        require (tokenA.balanceOf(sender) >= dAmountA,
            "Not enough token A for this swap.");

        // Calculate the swap return amount.
        uint256 dAmountB = calcSwapAmount(poolSizeA, poolSizeB, dAmountA);

        // Mint and Burn.
        swap(tokenA, tokenB, dAmountA, dAmountB, sender);

        // TODO: run this before or after the swap?
        // Update the pool sizes
        require(dAmountB < poolSizeB, "Resulting swap amount larger than vpool");
        poolSizeA += dAmountA;
        poolSizeB -= dAmountB;

        return dAmountB;
    }

    /**
    @notice Previews how many tokens would be sent to teh user when swapping from B to A using the virtual pool.
    @param dAmountB Amount of token B to be swapped by the user with 18 decimals.
    @return uint256 Amount of token A to be sent to the user from the swap with 18 decimals.
    */    
    function previewSwapBA(uint256 dAmountB) public view returns (uint256) {
        return calcSwapAmount(poolSizeB, poolSizeA, dAmountB);
    }

    /**
    @notice Updates pool sizes during a swap of token B for token A using the virtual pool.
    @param dAmountB Amount of token B to be swapped by the user with 18 decimals.
    @param sender Address of the person swapping the tokens.
    @return uint256 Amount of token A to be sent to the user from the swap with 18 decimals.
    */
    function swapBA(uint256 dAmountB, address sender)
        public nonReentrant onlyOwner returns (uint256)
    {
        require (tokenB.balanceOf(sender) >= dAmountB,
           "Not enough token B for this swap.");

        // Calculate the swap return amount.
        uint256 dAmountA = calcSwapAmount(poolSizeB, poolSizeA, dAmountB);

        // Mint and Burn.
        swap(tokenB, tokenA, dAmountB, dAmountA, sender);

        // TODO: run this before or after the swap?
        // Update the pool sizes
        require(dAmountA < poolSizeA, "Resulting swap amount larged than vpool");
        poolSizeA -= dAmountA;
        poolSizeB += dAmountB;

        return dAmountA;
    }

    /**
    @notice Calculates how many tokens should be swapped according to a constant product curve.
    @param dPoolX Size of the pool for the token being swapped with 18 decimals.
    @param dPoolY Size of the pool for the token being sent to the user with 18 decimals.
    @param dChangeX Amount of the token to be swapped by the user with 18 decimals.
    @return uint256 Amount of the token to be sent to the user from the swap with 18 decimals.
    */
    function calcSwapAmount(
        uint256 dPoolX,
        uint256 dPoolY,
        uint256 dChangeX
    )
        private
        pure
        returns (uint256)
    {
        // Give up dChangeX in exchange for dChangeY
        //   dChangeY = (dPoolY * dChangeX) / (dPoolX + dChangeX)
        return dPoolY.mul(dChangeX).div(dPoolX + dChangeX);
    }

    /**
    @notice Swap tokens using a virtual pool by burning/minting specified tokens.
    @param tokenX ERC20 token to be swapped into virtual pool (burned).
    @param tokenY ERC20 token to be sent to user from virtual pool (minted).
    @param dAmountX Amount of tokenX to be swapped with 18 decimals.
    @param dAmountY Amount of tokenY to be sent to user with 18 decimals.
    */
    function swap(
        ERC20MintableBurnable tokenX,
        ERC20MintableBurnable tokenY,
        uint256 dAmountX,
        uint256 dAmountY,
        address sender
    )
        private
    {
        tokenX.burn(sender, dAmountX);
        tokenY.mint(sender, dAmountY);
    }

}
