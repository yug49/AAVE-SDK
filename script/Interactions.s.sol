// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "../lib/forge-std/src/Script.sol";
import {IPool} from "../src/interface/aave/IPool.sol";
import {IAaveOracle} from "../src/interface/aave/IAaveOracle.sol";
import {IPoolDataProvider} from "../src/interface/aave/IPoolDataProvider.sol";
import {Constants} from "../src/Constants.sol";
import {IPoolAddressesProvider} from "../src/interface/aave/IPoolAddressesProvider.sol";
import {IERC20} from "../src/interface/token/IERC20.sol";

/**
 * @title AAVE Interactions Contract
 * @author Yug Agarwal
 * @notice This contract allows interaction with the AAVE protocol for various operations.
 */
contract Initializer is Constants {
    IPool public immutable i_aavePool = IPool(IPoolAddressesProvider(AAVE_POOL_ADDRESSES_PROVIDER).getPool());
    IPoolDataProvider internal constant DATA_PROVIDER = IPoolDataProvider(AAVE_POOL_DATA_PROVIDER);
    IAaveOracle internal constant PRICE_ORACLE = IAaveOracle(AAVE_ORACLE);
}

contract SupplyAssets is Script, Initializer {
    /**
     *
     * @param token the address of the erc20 token to supply
     * @param amount the amount of tokens to supply
     * @notice This function supplies the specified amount of tokens to the AAVE pool.
     * @dev The function uses the AAVE pool's supply function to deposit the tokens on behalf of the sender.
     * @dev The function requires the caller to have approved the AAVE pool to spend the specified amount of tokens.
     */
    function run(address token, uint256 amount) public {

        // Supply the tokens to the AAVE pool
        i_aavePool.supply({asset: token, amount: amount, onBehalfOf: msg.sender, referralCode: 0});
    }
}

contract WithdrawAssets is Script, Initializer {
    /**
     *
     * @param token the address of the erc20 token to withdraw
     * @param amount the amount of tokens to withdraw
     * @notice This function withdraws the specified amount of tokens from the AAVE pool.
     * @dev The function uses the AAVE pool's withdraw function to transfer the tokens to the caller.
     * @return withdrawn The actual amount withdrawn. This may be less than the specified amount if the user has a smaller balance.
     */
    function run(address token, uint256 amount) public returns (uint256 withdrawn) {
        // Withdraw the specified amount of tokens from the AAVE pool
        withdrawn = i_aavePool.withdraw({asset: token, amount: amount, to: msg.sender});
        return withdrawn;
    }
}

contract BorrowAssests is Script, Initializer {
    /**
     *
     * @param token the address of the erc20 token to borrow
     * @param amount the amount of tokens to borrow
     * @notice This function borrows the specified amount of tokens from the AAVE pool.
     * @dev The function uses the AAVE pool's borrow function to transfer the tokens to the caller.
     */
    function run(address token, uint256 amount) public {
        i_aavePool.borrow({
            asset: token,
            amount: amount,
            interestRateMode: 2, // Variable rate
            referralCode: 0,
            onBehalfOf: msg.sender
        });
    }
}

contract RepayAssests is Script, Initializer {
    /**
     *
     * @param token the address of the erc20 token to repay
     * @param amount the amount of tokens to repay
     * @notice This function repays the specified amount of tokens to the AAVE pool.
     * @dev The function uses the AAVE pool's repay function to transfer the tokens from the caller to the pool.
     * @dev The function requires the caller to have approved the AAVE pool to spend the specified amount of tokens.
     * @return repaid The actual amount repaid. This may be less than the specified amount if the user has a smaller debt.
     */
    function run(address token, uint256 amount) public returns (uint256 repaid) {
        // Repay the specified amount of tokens to the AAVE pool
        repaid = i_aavePool.repay({
            asset: token,
            amount: amount,
            interestRateMode: 2, // Variable rate
            onBehalfOf: msg.sender
        });
        return repaid;
    }
}

contract GetCollateral is Script, Initializer {
    /**
     * 
     * @param user the address of the user
     * @param token the address of the token
     * @return The amount of collateral the user has for the specified token.
     * @dev This function retrieves the balance of the specified token collateral for the user.
     */
    function run(address user, address token) public view returns (uint256) {
        IPool.ReserveData memory reserve = i_aavePool.getReserveData(token);
        return IERC20(reserve.aTokenAddress).balanceOf(user);
    }
}

contract GetDebt is Script, Initializer {
    /**
     *
     * @param user the address of the user
     * @param token the address of the token
     * @return The amount of debt the user has for the specified token.
     */
    function run(address user, address token) public view returns (uint256) {
        IPool.ReserveData memory reserve = i_aavePool.getReserveData(token);
        return IERC20(reserve.variableDebtTokenAddress).balanceOf(user);
    }
}

contract GetHealthFactor is Script, Initializer {
    /**
     *
     * @param user the address of the user
     * @return The health factor of the user.
     */
    function run(address user) public view returns (uint256) {
        (,,,,, uint256 healthFactor) = i_aavePool.getUserAccountData(user);

        return healthFactor;
    }
}
