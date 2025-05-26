//SPDX-License-Indentifier: MIT

pragma solidity ^0.8.0;

contract Inputs {
    // Supply Assets
    address internal constant SUPPLY_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    uint256 internal constant SUPPLY_AMOUNT = 1e18; // 1 Token

    // Withdraw Assets
    address internal constant WITHDRAW_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    uint256 internal constant WITHDRAW_AMOUNT = 1e17; // 0.5 tokens

    // Borrow Assests
    address internal constant BORROW_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
    uint256 internal constant BORROW_AMOUNT = 10e18; // 10 tokens

    // Repay Assests
    address internal constant REPAY_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
    uint256 internal constant REPAY_AMOUNT = 10e18; // 10 tokens

    // Get Collateral
    address internal constant COL_USER = 0xFF7290D664603D7564718800A987A161BedC4A6D; //address of the user
    address internal constant COL_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH - addresso of the token collateral you want to know of the user

    // Get Debt
    address internal constant DEBT_USER = 0xFF7290D664603D7564718800A987A161BedC4A6D; //address of the user
    address internal constant DEBT_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI - addresso of the token debt you want to know of the user

    // Get Health Factor
    address internal constant HF_USER = 0xFF7290D664603D7564718800A987A161BedC4A6D; // address of the user you want to know the health factor of
}
