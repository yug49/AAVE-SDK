//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {FlashLev} from "../src/FlashLev.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";
import {Constants} from "../src/Constants.sol";
import {IERC20} from "../src/interface/token/IERC20.sol";
import {IPoolAddressesProvider} from "../src/interface/aave/IPoolAddressesProvider.sol";
import {IPool} from "../src/interface/aave/IPool.sol";
import {Proxy} from "../src/Proxy.sol";
import {GetDebt} from "../script/Interactions.s.sol";

contract AaveTest is Test, Constants {
    FlashLev flashLev;
    Proxy proxy;
    GetDebt getDebtInstance;
    IERC20 constant iUSDC = IERC20(USDC);
    IERC20 constant iWETH = IERC20(WETH);
    // Using vm.addr with a private key to generate a deterministic address
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address USER = vm.addr(privateKey);
    IPoolAddressesProvider poolAddressProvider = IPoolAddressesProvider(AAVE_POOL_ADDRESSES_PROVIDER);

    function setUp() public {
        console.log("Setting up test...");
        flashLev = new FlashLev();
        proxy = new Proxy(USER);
        getDebtInstance = new GetDebt();
        console.log("0");
        address pool = poolAddressProvider.getPool();
        console.log("1");

        deal(USDC, USER, 1000 * 1e6); // 1000 USDC
        deal(WETH, USER, 1 * 1e18); // 1 WETH

        vm.startPrank(USER);
        iUSDC.approve(address(flashLev), type(uint256).max);
        iWETH.approve(address(flashLev), type(uint256).max);
        vm.stopPrank();

        vm.label(address(flashLev), "FlashLev");
        vm.label(pool, "Pool");
        vm.label(USER, "User");
        vm.label(USDC, "USDC");
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

        return Info({hf: healthFactor, col: totalCollateralBase, debt: totalDebtBase, available: availableBorrowsBase});
    }

    function test_getMaxFlashLoanAmountUsd() public view {
        uint256 colAmount = IERC20(WETH).balanceOf(address(this));

        (uint256 max, uint256 price, uint256 ltv, uint256 maxLev) = flashLev.getMaxFlashLoanAmountUsd(WETH, colAmount);

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
    }

    function test_flashLev() public {
        uint256 colAmount = 1e18;

        (uint256 max, uint256 price, uint256 ltv, uint256 maxLev) = flashLev.getMaxFlashLoanAmountUsd(WETH, colAmount);
        console.log("Max flash loan USD: %e", max);
        console.log("Collateral price: %e", price);
        console.log("LTV: %e", ltv);
        console.log("Max leverage %e", maxLev);

        console.log("--------- open ------------");

        // assumes 1 coin = 1 usd
        uint256 coinAmount = (max * 98 / 100) / (10 ** (18 - 6));

        vm.prank(USER);
        IERC20(WETH).approve(address(flashLev), type(uint256).max);
        vm.prank(USER);
        flashLev.open(
            FlashLev.OpenParams({
                coin: USDC,
                collateral: WETH,
                colAmount: colAmount,
                coinAmount: coinAmount,
                swap: FlashLev.SwapParams({amountOutMin: 1, data: abi.encode(true, UNISWAP_V3_POOL_FEE_USDC_WETH)}),
                minHealthFactor: 1.01 * 1e18
            })
        );

        Info memory info;
        info = getInfo(address(flashLev));

        assertGt(info.col, 0);
        assertGt(info.debt, 0);
        assertGt(info.hf, 1e18);
        assertLt(info.hf, 1.1 * 1e18);

        console.log("--------- close ------------");
        uint256 coinBalBefore = iUSDC.balanceOf(address(flashLev));

        uint256 coinDebt = getDebtInstance.getDebt(address(flashLev), USDC);

        // vm.prank(USER);
        // IERC20(USDC).approve(address(flashLev), type(uint256).max);
        vm.prank(USER);
        flashLev.close(
            FlashLev.CloseParams({
                coin: USDC,
                collateral: WETH,
                colAmount: colAmount,
                swap: FlashLev.SwapParams({
                    amountOutMin: coinDebt * 98 / 100,
                    data: abi.encode(false, UNISWAP_V3_POOL_FEE_USDC_WETH)
                })
            })
        );

        uint256 coinBalAfter = iUSDC.balanceOf(address(flashLev));

        info = getInfo(address(flashLev));

        assertEq(info.col, 0);
        assertEq(info.debt, 0);
        assertGt(info.hf, 1e18);

        if (coinBalAfter >= coinBalBefore) {
            console.log("Profit: %e", coinBalAfter - coinBalBefore);
        } else {
            console.log("Loss: %e", coinBalBefore - coinBalAfter);
        }

        uint256 colBal = IERC20(WETH).balanceOf(USER);
        console.log("Collateral: %e", colBal);

        assertEq(colBal, colAmount);
    }
}
