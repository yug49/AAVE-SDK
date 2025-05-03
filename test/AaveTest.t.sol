//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {FlashLev} from "../script/FlashLev.s.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";
import {Constants} from "../src/Constants.sol";
import {IERC20} from "../src/interface/token/IERC20.sol";
import {IPoolAddressesProvider} from "../src/interface/aave/IPoolAddressesProvider.sol";
import {IPool} from "../src/interface/aave/IPool.sol";


contract AaveTest is Test, Constants {
    FlashLev flashLev;
    IERC20 constant dai = IERC20(DAI);
    IERC20 constant weth = IERC20(WETH);
    IPoolAddressesProvider poolAddressProvider = IPoolAddressesProvider(AAVE_POOL_ADDRESSES_PROVIDER);


    function setUp() public {
        console.log("Setting up test...");
        flashLev = new FlashLev();
        console.log("0");
        address pool = poolAddressProvider.getPool();
        console.log("1");

        // Using vm.addr with a private key to generate a deterministic address
        uint256 privateKey = 1;
        console.log("2");
        address USER = vm.addr(privateKey);

        deal(DAI, USER, 1000 * 1e19); // 1000 DAI
        deal(WETH, USER, 1 * 1e18); // 1 WETH

        vm.startPrank(USER);
        dai.approve(address(this), type(uint256).max);
        weth.approve(address(this), type(uint256).max);
        vm.stopPrank();

        vm.label(address(flashLev), "FlashLev");
        vm.label(pool, "Pool");
        vm.label(USER, "User");
        vm.label(DAI, "DAI");
        vm.label(WETH, "WETH");
    }

    struct Info {
        uint256 hf;
        uint256 col;
        uint256 debt;
        uint256 available;
    }

    function getInfo(address user) public view returns (Info memory) {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = IPool(poolAddressProvider.getPool()).getUserAccountData(user);

        console.log("Collateral USD: %e", totalCollateralBase);
        console.log("Debt USD: %e", totalDebtBase);
        console.log("Available to borrow USD: %e", availableBorrowsBase);
        console.log("LTV: %e", ltv);
        console.log("Liquidation threshold: %e", currentLiquidationThreshold);
        console.log("Health factor: %e", healthFactor);

        return Info({
            hf: healthFactor,
            col: totalCollateralBase,
            debt: totalDebtBase,
            available: availableBorrowsBase
        });
    }

    function test_getMaxFlashLoanAmountUsd() public view {
        uint256 colAmount = IERC20(WETH).balanceOf(address(this));

        (uint256 max, uint256 price, uint256 ltv, uint256 maxLev) =
            flashLev.getMaxFlashLoanAmountUsd(WETH, colAmount);
        
        console.log("Max flash loan USD: %e", max);
        console.log("Collateral price: %e", price);
        console.log("LTV: %e", ltv);
        console.log("Max leverage: %e", maxLev);

        // Checks
        assertGt(price, 0);
        assertGe(max, colAmount * price / 1e8);
        assertGt(ltv, 0);
        assertLe(ltv, 1e4);
        assertGt(maxLev, 0);
        assertLe(maxLev, 1e4);
    }
}
