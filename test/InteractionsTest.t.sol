// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Constants} from "../src/Constants.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {IERC20} from "../src/interface/token/IERC20.sol";
import {IPool} from "../src/interface/aave/IPool.sol";
import {IPoolAddressesProvider} from "../src/interface/aave/IPoolAddressesProvider.sol";
import {
    Initializer,
    SupplyAssets,
    WithdrawAssets,
    BorrowAssests,
    RepayAssests,
    GetCollateral,
    GetDebt,
    GetHealthFactor
} from "../script/Interactions.s.sol";

contract InteractionsTest is Test, Constants {
    IERC20 constant dai = IERC20(DAI);
    IERC20 constant reth = IERC20(RETH);
    IERC20 constant weth = IERC20(WETH);
    // Using vm.addr with a private key to generate a deterministic address
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address USER = vm.addr(privateKey);

    // Aave pool
    IPool aavePool;

    // Instances for testing
    SupplyAssets supplyAssets;
    WithdrawAssets withdrawAssets;
    BorrowAssests borrowAssets;
    RepayAssests repayAssets;
    GetCollateral getCollateralInstance;
    GetDebt getDebtInstance;
    GetHealthFactor getHealthFactorInstance;

    function setUp() public {
        console.log("Setting up test...");

        // Initialize AAVE pool
        aavePool = IPool(IPoolAddressesProvider(AAVE_POOL_ADDRESSES_PROVIDER).getPool());

        // Initialize contract instances
        supplyAssets = new SupplyAssets();
        withdrawAssets = new WithdrawAssets();
        borrowAssets = new BorrowAssests();
        repayAssets = new RepayAssests();
        getCollateralInstance = new GetCollateral();
        getDebtInstance = new GetDebt();
        getHealthFactorInstance = new GetHealthFactor();

        deal(DAI, USER, 1000 * 1e19); // 1000 DAI
        deal(RETH, USER, 1 * 1e18); // 1 RETH
        deal(WETH, USER, 1 * 1e18); // 1 WETH

        // vm.startPrank(USER);
        // // Approve AAVE pool to spend tokens
        // dai.approve(address(aavePool), type(uint256).max);
        // reth.approve(address(aavePool), type(uint256).max);
        // weth.approve(address(aavePool), type(uint256).max);
        // vm.stopPrank();

        vm.label(USER, "User");
        vm.label(DAI, "DAI");
        vm.label(WETH, "WETH");
        vm.label(RETH, "RETH");
        vm.label(address(aavePool), "AavePool");
    }

    function testSupply() public {
        uint256 initialDAIBalance = dai.balanceOf(USER);
        uint256 supplyAmount = 100 * 1e18; // 100 DAI

        supplyAssets.supply(DAI, supplyAmount);

        // Check user's DAI balance decreased
        assertEq(dai.balanceOf(USER), initialDAIBalance - supplyAmount, "User DAI balance should decrease after supply");

        // Check user received aTokens as collateral
        uint256 collateral = getCollateralInstance.getCollateral(USER, DAI);
        assertGt(collateral, 0, "User should have DAI collateral after supply");
        assertApproxEqAbs(collateral, supplyAmount, 1e15, "Collateral amount should approximate supplied amount");
    }

    function testWithdraw() public {
        // First, supply some DAI
        uint256 supplyAmount = 100 * 1e18; // 100 DAI

        supplyAssets.supply(DAI, supplyAmount);

        uint256 initialDaiBalance = dai.balanceOf(USER);
        uint256 withdrawAmount = 50 * 1e18; // 50 DAI

        uint256 withdrawn = withdrawAssets.withdraw(DAI, withdrawAmount);

        // Check withdrawal
        assertEq(withdrawn, withdrawAmount, "Withdrawn amount should match requested amount");
        assertEq(
            dai.balanceOf(USER), initialDaiBalance + withdrawAmount, "User DAI balance should increase after withdrawal"
        );

        // Check collateral decreased
        uint256 collateral = getCollateralInstance.getCollateral(USER, DAI);
        assertApproxEqAbs(
            collateral, supplyAmount - withdrawAmount, 1e15, "Collateral should decrease by withdrawn amount"
        );
    }

    function testBorrow() public {
        // Supply collateral first
        uint256 supplyAmount = 1 * 1e18; // 1 WETH
        uint256 borrowAmount = 500 * 1e18; // 500 DAI

        supplyAssets.supply(WETH, supplyAmount);

        uint256 initialDaiBalance = dai.balanceOf(USER);

        borrowAssets.borrow(DAI, borrowAmount);

        // Check borrowed amount
        assertEq(
            dai.balanceOf(USER), initialDaiBalance + borrowAmount, "User DAI balance should increase after borrowing"
        );

        // Check debt
        uint256 debt = getDebtInstance.getDebt(USER, DAI);
        assertEq(debt, borrowAmount, "User should have DAI debt after borrowing");

        // Check health factor is healthy
        uint256 healthFactor = getHealthFactorInstance.getHealthFactor(USER);
        assertGt(healthFactor, 1e18, "Health factor should be greater than 1");
    }

    function testRepay() public {
        // First supply collateral and borrow
        uint256 supplyAmount = 1 * 1e18; // 1 WETH
        uint256 borrowAmount = 500 * 1e18; // 500 DAI
        uint256 repayAmount = 200 * 1e18; // 200 DAI

        supplyAssets.supply(WETH, supplyAmount);

        borrowAssets.borrow(DAI, borrowAmount);

        uint256 initialDaiBalance = dai.balanceOf(USER);

        uint256 repaid = repayAssets.repay(DAI, repayAmount);

        // Check repayment
        assertEq(repaid, repayAmount, "Repaid amount should match requested amount");
        assertEq(
            dai.balanceOf(USER), initialDaiBalance - repayAmount, "User DAI balance should decrease after repayment"
        );

        // Check debt decreased
        uint256 debt = getDebtInstance.getDebt(USER, DAI);
        assertApproxEqAbs(debt, borrowAmount - repayAmount, 100, "Debt should decrease by repaid amount");
    }

    function testGetCollateral() public {
        uint256 supplyAmount = 100 * 1e18; // 100 DAI

        supplyAssets.supply(DAI, supplyAmount);

        // Check getCollateral returns the correct amount
        uint256 collateral = getCollateralInstance.getCollateral(USER, DAI);
        assertApproxEqAbs(collateral, supplyAmount, 1e15, "Collateral should equal supplied amount");
    }

    function testGetDebt() public {
        // Supply collateral and borrow
        uint256 supplyAmount = 1 * 1e18; // 1 WETH
        uint256 borrowAmount = 500 * 1e18; // 500 DAI

        supplyAssets.supply(WETH, supplyAmount);

        borrowAssets.borrow(DAI, borrowAmount);

        // Check getDebt returns the correct amount
        uint256 debt = getDebtInstance.getDebt(USER, DAI);
        assertEq(debt, borrowAmount, "Debt should equal borrowed amount");
    }

    function testGetHealthFactor() public {
        // Supply collateral and borrow
        uint256 supplyAmount = 1 * 1e18; // 1 WETH
        uint256 borrowAmount = 500 * 1e18; // 500 DAI

        supplyAssets.supply(WETH, supplyAmount);

        borrowAssets.borrow(DAI, borrowAmount);

        // Check health factor
        uint256 healthFactor = getHealthFactorInstance.getHealthFactor(USER);
        assertGt(healthFactor, 1e18, "Health factor should be greater than 1");
    }

    // Test full supply -> borrow -> repay -> withdraw cycle
    function testFullCycle() public {
        uint256 supplyAmount = 1 * 1e18; // 1 WETH
        uint256 borrowAmount = 500 * 1e18; // 500 DAI

        // 1. Supply collateral
        supplyAssets.supply(WETH, supplyAmount);

        // 2. Borrow
        borrowAssets.borrow(DAI, borrowAmount);

        // 3. Repay full amount
        repayAssets.repay(DAI, borrowAmount);

        // 4. Withdraw full amount
        withdrawAssets.withdraw(WETH, supplyAmount);

        // Verify user has no debt
        uint256 debt = getDebtInstance.getDebt(USER, DAI);
        assertEq(debt, 0, "User should have no DAI debt after full repayment");

        // Verify user has no collateral
        uint256 collateral = getCollateralInstance.getCollateral(USER, WETH);
        assertApproxEqAbs(collateral, 0, 1e15, "User should have no WETH collateral after full withdrawal");
    }
}
