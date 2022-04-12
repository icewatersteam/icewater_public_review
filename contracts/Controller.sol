// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/FixedPoint.sol";

import "./config/Constants.sol";
import "./VirtualPool.sol";

import "./abstract/ErrorTracker.sol";
import "./abstract/RewardsManager.sol";

import "./tokens/IceToken.sol";
import "./tokens/H2OToken.sol";
import "./tokens/SteamToken.sol";

/** @title IceWater Controller to manage tokens and rewards.
    @notice A stable token H2O is managed based on a measurement token ICE and a
        control token STM.
*/
contract Controller is RewardsManager, ErrorTracker {
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    // Virtual pool for swapping H2O <-> ICE.
    VirtualPool private _icePool;

    // Virtual pool for swapping H2O <-> STM.
    VirtualPool private _stmPool;
    
    // Stores the STM initial supply.
    int256 private _dInitialSTMSupply;

    // Amount of H2O added to the system.
    uint256 private _dLastTotalH2O;

    // target ice price in H20
    uint256 private _dTargetICEPrice;

    /**
    @notice Constructor
    @param iceToken_ ERC20 Token for Ice (Token for measuring stability)
    @param h2oToken_ ERC20 Token for H2O (Stable Token)
    @param stmToken_ ERC20 Token for STM (Token for controlling stability)
    */
    constructor(IceToken iceToken_, H2OToken h2oToken_, SteamToken stmToken_)
        ErrorTracker()
        RewardsManager(iceToken_, h2oToken_, stmToken_)
    {

        // Initialize the H2O <-> ICE virtual pool.
        // NOTE: At this point the pool still doesn't have permission to perform
        // token mints/burns. See initTokenRoles().
        _icePool = new VirtualPool(
            h2oToken,
            iceToken,
            D_INITIAL_ICE_POOL_H2O_SIZE,
            D_INITIAL_ICE_POOL_H2O_SIZE.div(D_INITIAL_ICE_PRICE)
        );

        // Initialize the H2O <-> STM virtual pool.
        // NOTE: At this point the pool still doesn't have permission to perform
        // token mints/burns. See initTokenRoles().
        _stmPool = new VirtualPool(
            h2oToken,
            stmToken,
            D_INITIAL_STM_POOL_H2O_SIZE,
            D_INITIAL_STM_POOL_H2O_SIZE.div(D_INITIAL_STM_PRICE)
        );

        // Store the STM initialial supply.
        _dInitialSTMSupply = int256(uint256(stmToken.totalSupply()));

        // store the the total initial H2O amount
        _dLastTotalH2O = _totalH2O();
        
        // Set the target ICE price.
        _dTargetICEPrice = D_INITIAL_ICE_PRICE;
    }

    /**
    @notice Allows the VirtualPools to mint and burn tokens.
    @dev Grants the MINTER_BURNER_ROLE from the tokens to the VirtualPools and
        to itself. At this point the Controller must already have the
        DEFAULT_ADMIN_ROLE in the tokens, so that it can grant the
        MINTER_BURNER_ROLE to the pools. This only needs to be called once after
        deployment. Until this call the VirtualPools will not be able to perform
        token swaps.
    */
    function initTokenRoles() public {
        address icePoolAddr = address(_icePool);
        address stmPoolAddr = address(_stmPool);

        // Grant MINTER_BURNER_ROLE to the ice pool.
        iceToken.grantRole(iceToken.MINTER_BURNER_ROLE(), icePoolAddr);
        h2oToken.grantRole(h2oToken.MINTER_BURNER_ROLE(), icePoolAddr);

        // Grant MINTER_ROLE and BURNER_ROLE to the stm pool.
        h2oToken.grantRole(h2oToken.MINTER_BURNER_ROLE(), stmPoolAddr);
        stmToken.grantRole(stmToken.MINTER_BURNER_ROLE(), stmPoolAddr);

        // Grant MINTER_ROLE and BURNER_ROLE to the Controller itself so that
        // RewardsManager can mint H2O tokens.
        h2oToken.grantRole(h2oToken.MINTER_BURNER_ROLE(), address(this));
    }    

    //*** Getters for prices and virtual pool sizes ***//
    /**
    @notice Getter for the current target price in H2O for the ICE token. Protocol tries to move the price of the ICE token towards the target price.
    @return uint256 Target price for ICE token in H2O with 18 decimals.
    */
    function getTargetICEPrice() public view returns (uint256) {
        return _dTargetICEPrice;
    }

    /**
    @notice Getter for the current price in H2O of the ICE token according to the internal virtual pools.
    @return uint256 Price for ICE token in H2O with 18 decimals.
    */
    function getICEPrice() public view returns (uint256) {
        return _icePool.priceB();
    }

    /**
    @notice Getter for the current price in H2O of the STM token according to the internal virtual pools.
    @return uint256 Price for STM token in H2O with 18 decimals.
    */
    function getSTMPrice() public view returns (uint256) {
        return _stmPool.priceB();
    }

    /**
    @notice Getter for the amount of ICE in the ICE/H2O virtual pool.
    @return uint256 Amount of ICE token with 18 decimals.
    */
    function getICEPoolICESize() public view returns (uint256) {
        return _icePool.poolSizeB();
    }

    /**
    @notice Getter for the amount of H2O in the ICE/H2O virtual pool.
    @return uint256 Amount of H2O token with 18 decimals.
    */
    function getICEPoolH2OSize() public view returns (uint256) {
        return _icePool.poolSizeA();
    }

    /**
    @notice Getter for the amount of STM in the STM/H2O virtual pool.
    @return uint256 Amount of STM token with 18 decimals.
    */
    function getSTMPoolSTMSize() public view returns (uint256) {
        return _stmPool.poolSizeB();
    }

    /**
    @notice Getter for the amount of H2O in the STM/H2O virtual pool.
    @return uint256 Amount of H2O token with 18 decimals.
    */
    function getSTMPoolH2OSize() public view returns (uint256) {
        return _stmPool.poolSizeA();
    }

    //*** Token Swap Functions ***//

    /**
    @notice Previews how much ICE results from swapping H2O to ICE using the ICE/H2O virtual pool.
    @param dH2OAmount Amount of H2O token to be swapped with 18 decimals.
    @return uint256 Amount of ICE token that will be sent to user with 18 decimals.
    */
    function previewSwapH2OForICE(uint256 dH2OAmount)
        public view returns (uint256)
    {
        return _icePool.previewSwapAB(dH2OAmount);
    }

    /**
    @notice Previews how much H2O results from swapping ICE to H2O using the ICE/H2O virtual pool.
    @param dICEAmount Amount of ICE token to be swapped with 18 decimals.
    @return uint256 Amount of H2O token that will be sent to user with 18 decimals.
    */
    function previewSwapICEForH2O(uint256 dICEAmount)
        public view returns (uint256)
    {
        return _icePool.previewSwapBA(dICEAmount);
    }

    /**
    @notice Previews how much STM results from swapping H2O to STM using the STM/H2O virtual pool.
    @param dH2OAmount Amount of H2O token to be swapped with 18 decimals.
    @return uint256 Amount of STM token that will be sent to user with 18 decimals.
    */
    function previewSwapH2OForSTM(uint256 dH2OAmount)
        public view returns (uint256)
    {
        return _stmPool.previewSwapAB(dH2OAmount);
    }

    /**
    @notice Previews how much H2O results from swapping STM to H2O using the STM/H2O virtual pool.
    @param dSTMAmount Amount of STM token to be swapped with 18 decimals.
    @return uint256 Amount of H2O token that will be sent to user with 18 decimals.
    */
    function previewSwapSTMForH2O(uint256 dSTMAmount)
        public view returns (uint256)
    {
        return _stmPool.previewSwapBA(dSTMAmount);
    }

    /**
    @notice Swaps H2O for ICE using the cold virtual pool (ICE/H2O virtual pool).
    @param dH2OAmount Amount of H2O token to be swapped with 18 decimals.
    @return uint256 Amount of ICE token sent to user with 18 decimals.
    */
    //TODO: There may be a rentrancy problem here because the pools are updated before the user needs to provide tokens.
    // We should perhaps do preview, swap, swapAB and pull the require statement into this contract.
    function swapH2OForICE(uint256 dH2OAmount) public returns (uint256) {
        // Update the STM price and condensation rate
        // Note: At beginning of function to avoid flash loan attack
        updateError();

        uint256 dICEAmount = _icePool.swapAB(dH2OAmount, msg.sender);
        
        emit Swap(
            msg.sender,
            address(h2oToken), dH2OAmount,
            address(iceToken), dICEAmount);

        return dICEAmount;
    }

    /**
    @notice Swaps ICE for H2O using the cold virtual pool (ICE/H2O virtual pool).
    @param dICEAmount Amount of ICE token to be swapped with 18 decimals.
    @return uint256 Amount of H2O token sent to user with 18 decimals.
    */
    function swapICEForH2O(uint256 dICEAmount) public returns (uint256) {
        // Update the STM price and condensation rate
        // Note: At beginning of function to avoid flash loan attack
        updateError();

        uint256 dH2OAmount = _icePool.swapBA(dICEAmount, msg.sender);
        
        emit Swap(
            msg.sender,
            address(iceToken), dICEAmount,
            address(h2oToken), dH2OAmount);

        return dH2OAmount;
    }

    /**
    @notice Swaps H2O for STM using the warm virtual pool (STM/H2O virtual pool).
    @param dH2OAmount Amount of H2O token to be swapped with 18 decimals.
    @return uint256 Amount of STM token sent to user with 18 decimals.
    */
    function swapH2OForSTM(uint256 dH2OAmount) public returns (uint256) {
        uint256 dSTMAmount = _stmPool.swapAB(dH2OAmount, msg.sender);
        
        emit Swap(
            msg.sender,
            address(h2oToken), dH2OAmount,
            address(stmToken), dSTMAmount);

        return dSTMAmount;
    }

    /**
    @notice Swaps STM for H2O using the warm virtual pool (STM/H2O virtual pool).
    @param dSTMAmount Amount of STM token to be swapped with 18 decimals.
    @return uint256 Amount of H2O token sent to user with 18 decimals.
    */
    function swapSTMForH2O(uint256 dSTMAmount) public returns (uint256) {
        uint256 dH2OAmount = _stmPool.swapBA(dSTMAmount, msg.sender);
        
        emit Swap(
            msg.sender,
            address(stmToken), dSTMAmount,
            address(h2oToken), dH2OAmount);

        return dH2OAmount;
    }

    //*** Rewards Functions ***//

    /**
    @notice Calls housekeeping functions when a user claims ICE/STM rewards (e.g., change sizes of virtual pools).  Overrides RewardsManager function.
    */
    function onRewardsClaimed() internal override {
        _updatePoolSize();
    }

    //*** ErrorTracker Functions ***//

    /**
    @notice Calculates the current error as the difference between the ICE/H2O virtual pool ICE price and the target ICE price.  Overrides ErrorTracker function.
    @return int256 The calculated error with 18 decimals.
    */
    function calculateError() internal override view returns (int256) {
        return int256(_icePool.priceB()) - int256(_dTargetICEPrice);
    }

    /**
    @notice Calls functions to respond to and mitigate error between the ICE/H2O virtual pool ICE price and target ICE price.  Overrides ErrorTracker function.
    @param dError Current error between the ICE/H2O virtual pool ICE price and target ICE price with 18 decimals.
    @param dAccumError Accumulated error (integral of current error) with 18 decimals.
    @param iTimeDelta Time in seconds since the error was last calculated and applied.
    */
    function applyError(
        int256 dError,
        int256 dAccumError,
        uint256 iTimeDelta
    )
        internal override
    {
        _updateSTMPrice(dError, iTimeDelta);
        _updateCondensationRate(dAccumError, iTimeDelta);
        _updateTargetICEPrice(dError, iTimeDelta);
    }

    //*** Update Functions ***//

    /**
    @notice Scale size of ICE/H2O virtual pool and STM/H2O virtual pool when H2O is added to the system to ensure pool size keeps up with token supply.
    */
    // TODO: When we scale the pools it causes increase in total H2O, and vice
    //       versa. Will this converge to the right level?
    function _updatePoolSize() private {
        // get the total amount of H2O
        uint256 dTotalH2O = _totalH2O();

        // compute the update ratio
        uint256 dUpdateRatio = dTotalH2O.div(_dLastTotalH2O);

        // update the last total H2O variable
        _dLastTotalH2O = dTotalH2O;

        // Update ICE Pool
        _icePool.scalePools(dUpdateRatio);

        // Update STM Pool
        _stmPool.scalePools(dUpdateRatio);
    }

    /**
    @notice Determine a total amount of H2O in the system including virtual pools
    */
    function _totalH2O() private view returns (uint256){
        uint256 dTotalH2O = h2oToken.totalSupply() +
            _icePool.poolSizeA() +
            _stmPool.poolSizeA();

        return dTotalH2O;
    }

    /**
    @notice Scale a target change that is responsive to an error based on the time since the last change was made.
    @param dChange The change to be scaled with 18 decimals.
    @param iTimeDelta Time in seconds since the error was last calculated and applied.
    @param iBaseTime The time in seconds used as a base reference for the scaling.
    @return int256 The scaled change with 18 decimals.
    */
    // Convert a target change amount to a change scaled based on how much time
    // has passed.
    function _scaleChangeWithTime(
        int256 dChange,
        uint256 iTimeDelta,
        uint256 iBaseTime
    )
        internal
        pure
        returns(int256)
    {
        // don't allow changes based on time longer than the base time
        iTimeDelta = iTimeDelta.min(iBaseTime);

        // compute the time ratio
        int256 dTimeRatio = int256(iTimeDelta.toDecimal() / iBaseTime);
        return dTimeRatio.mul(dChange);
    }

    /**
    @notice Change the target ICE price to drift towards the actual ICE price based on the current error.
    @param dError Current error between the ICE/H2O virtual pool ICE price and target ICE price with 18 decimals.
    @param iTimeDelta Time in seconds since the error was last calculated and applied.
    */
    function _updateTargetICEPrice(int256 dError, uint256 iTimeDelta) private {
        // Conversions
        int256 dTargetICEPrice = int256(_dTargetICEPrice);

        // scale the price change based on the amount of time that has passed
        int256 dTargetICEPriceChangeAmount = _scaleChangeWithTime(
            dError,
            iTimeDelta,
            I_ICE_PRICE_CHANGE_PERIOD);

        // Set target ice price.
        _dTargetICEPrice = uint256(dTargetICEPrice +
            dTargetICEPriceChangeAmount);
    }

    /**
    @notice Change the STM price to add or remove H2O from the system based on the current error.
    @param dError Current error between the ICE/H2O virtual pool ICE price and target ICE price with 18 decimals.
    @param iTimeDelta Time in seconds since the error was last calculated and applied.
    */
    function _updateSTMPrice(int256 dError, uint256 iTimeDelta) private
    {
        // Conversions
        int256 dSTMPrice = int256(getSTMPrice());
        int256 dICEPrice = int256(getICEPrice());

        // Scale the change in steam price based on the config constant.
        int256 dPriceChange = dError.mul(D_STEAM_PRICE_FACTOR);

        // Scale the change based on the ratio of the steam price to the ice
        // price.
        int256 dPriceRatio = dSTMPrice.div(dICEPrice);
        dPriceChange = dPriceChange.mul(dPriceRatio);

        // Scale the change based on the the amount of time that has passed
        dPriceChange = _scaleChangeWithTime(
            dPriceChange,
            iTimeDelta,
            I_STM_PRICE_CHANGE_PERIOD);

        // calculate the target price
        uint256 dTargetSTMPrice = uint256(dSTMPrice + dPriceChange);

        // Change the STM pool size by setting the target price.
        _stmPool.setPriceB(uint256(dTargetSTMPrice));
    }

    /**
    @notice Change the STM rewards (condensation) paid in H2O based on the accumulated error.
    @param dAccumError Accumulated error (integral of current error) with 18 decimals.
    @param iTimeDelta Time in seconds since the error was last calculated and applied.
    */
    function _updateCondensationRate(
        int256 dAccumError,
        uint256 iTimeDelta
    ) 
        private
    {
        // conversions
        int256 dBaseCondensationRate = int256(D_INITIAL_CONDENSATION_RATE);
        int256 dCurrentCondensationRate = int256(condensationRate);

        //compute the change in the condensation rate
        int256 dVariableCondensationRate = dAccumError.mul(
            D_CONDENSATION_FACTOR);

        // compute the target condensation rate
        int256 dTargetCondensationRate = dBaseCondensationRate +
            dVariableCondensationRate;

        // compute the target change in condensation rate
        int dRateChange =  dTargetCondensationRate - dCurrentCondensationRate;

        //scale the change in the condensation rate based on time
        dRateChange = _scaleChangeWithTime(
            dRateChange,
            iTimeDelta,
            I_CONDENSATION_RATE_CHANGE_PERIOD);

        // compute condensation rate
        int256 dNewCondensationRate = dCurrentCondensationRate + dRateChange;

        // prevent the condensation rate from going below 0
        dNewCondensationRate = dNewCondensationRate.max(0);

        // set condensation rate
        condensationRate = uint256(dNewCondensationRate);
    }

    event Swap(address indexed account,
        address tokenFrom, uint256 amountFrom,
        address tokenTo, uint256 amountTo);
}
