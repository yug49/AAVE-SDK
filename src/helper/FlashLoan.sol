//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Initializer} from "../../script/Interactions.s.sol";

abstract contract FlashLoan is Script, Initializer {

    function run(address token, uint256 amount, bytes memory data) public {
        flashLoan(token, amount, data);
    }

    /**
     *
     * @param token the address of the erc20 token to borrow
     * @param amount the amount of tokens to borrow
     * @param data arbitrary data to pass to the flash loan callback function
     * @notice This function initiates a flash loan from the AAVE pool.
     * @dev The function uses the AAVE pool's flashLoan function to borrow the specified amount of tokens.
     */
    function flashLoan(address token, uint256 amount, bytes memory data) public {
        i_aavePool.flashLoanSimple({
            receiverAddress: msg.sender,
            asset: token,
            amount: amount,
            params: data,
            referralCode: 0
        });
    }

    /**
     *
     * @param token token address
     * @param amount amount of tokens to borrow
     * @param fee the fee for the flash loan
     * @param initiator the address that initiated the flash loan
     * @param params arbitrary data to pass to the flash loan callback function
     * @dev ensures the sender is the aave pool and the initiator of the flash loan is this contract
     * @return true if the operation was successful
     */
    function executeOperation(address token, uint256 amount, uint256 fee, address initiator, bytes calldata params)
        external
        returns (bool)
    {
        require(msg.sender == address(i_aavePool), "not authorized");
        require(initiator == address(this), "invalid initiator");

        _flashLoanCallBack(token, amount, fee, params);

        return true;
    }

    /**
     *
     * @param token the address of the erc20 token to borrow
     * @param amount the amount of tokens to borrow
     * @param fee the fee for the flash loan
     * @param params arbitrary data to pass to the flash loan callback function
     * @notice This function is called back after a flash loan is executed.
     * @dev The function should be overridden in the derived contract to implement custom logic.
     */
    function _flashLoanCallBack(address token, uint256 amount, uint256 fee, bytes memory params) internal virtual;
}