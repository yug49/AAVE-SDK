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


contract AaveTest is Test, Constants {
    FlashLev flashLev;
    Proxy proxy;
    IERC20 constant dai = IERC20(DAI);
    IERC20 constant reth = IERC20(RETH);
    // Using vm.addr with a private key to generate a deterministic address
    uint256 privateKey = 1;
    address USER = vm.addr(privateKey);
    IPoolAddressesProvider poolAddressProvider = IPoolAddressesProvider(AAVE_POOL_ADDRESSES_PROVIDER);


    function setUp() public {
        console.log("Setting up test...");
        flashLev = new FlashLev();
        proxy = new Proxy(USER);
        console.log("0");
        address pool = poolAddressProvider.getPool();
        console.log("1");


        deal(DAI, USER, 1000 * 1e19); // 1000 DAI
        deal(RETH, USER, 1 * 1e18); // 1 WETH

        vm.startPrank(USER);
        dai.approve(address(proxy), type(uint256).max);
        reth.approve(address(proxy), type(uint256).max);
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
    }

    function test_flashLev() public {
        uint256 colAmount = 1e18;

        (uint256 max, uint256 price, uint256 ltv, uint256 maxLev) =
            flashLev.getMaxFlashLoanAmountUsd(WETH, colAmount);
        console.log("Max flash loan USD: %e", max);
        console.log("Collateral price: %e", price);
        console.log("LTV: %e", ltv);
        console.log("Max leverage %e", maxLev);

        console.log("---------open------------");

        // assumes 1 coin = 1 usd
        uint256 coinAmount = max * 98/100; // 50% of max flash loan

        vm.prank(USER);
        proxy.execute(
            address(flashLev),
            abi.encodeCall(
                flashLev.open,
                (
                    FlashLev.OpenParams({
                        coin: DAI,
                        collateral: RETH,
                        colAmount: colAmount,
                        coinAmount: coinAmount,
                        swap: FlashLev.SwapParams({
                            amountOutMin: coinAmount * 1e8 / price * 98 / 100,
                            data: abi.encode(
                                true,
                                UNISWAP_V3_POOL_FEE_DAI_WETH,
                                BALANCER_POOL_ID_RETH_WETH
                            )
                        }),
                        minHealthFactor: 1.01 * 1e18
                    })
                )
            )
        );

        Info memory info;
        info = getInfo(address(proxy));

        assertGt(info.col, 0);
        assertGt(info.debt, 0);
        assertGt(info.hf, 1e18);
        assertLt(info.hf, 1.1 * 1e18);
    }
}
