// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../src/interface/token/IERC20.sol";
import {Pay} from "../src/helper/Pay.sol";
import {Token} from "../src/helper/Token.sol";
import {SwapHelper} from "../src/helper/SwapHelper.sol";
import {FlashLoan} from "../src/helper/FlashLoan.sol";

/**
 * @title Contract to create a Leveraged Position using AAVE-FlashLoan
 * @author Yug Agarwal
 * @notice This contract allows users to create leveraged positions using AAVE's flash loan functionality.
 */
contract FlashLev is Pay, Token, SwapHelper, FlashLoan {
    error FlashLev__HealthFactorTooLow();

    /**
     * @notice parameters for swap process
     * @param amountOutMin min amount of output token to receive
     * @param data additional data for the swap process
     */
    struct SwapParams {
        uint256 amountOutMin;
        bytes data;
    }

    /**
     * Data structure for flash loan process
     * @param coin Address of the coin being borrowed
     * @param collateral Address of the collateral token
     * @param open Boolean indicating if the position is open
     * @param caller Address of the user calling the operation
     * @param colAmount Amount of collateral supplied by the caller for opening a position
     * @param swap Swap parameters for collateral to coin swap
     */
    struct FlashLoanData {
        address coin;
        address collateral;
        bool open;
        address caller;
        uint256 colAmount;
        SwapParams swap;
    }

    /**
     * @notice Parameters for opening a leveraged position
     * @param coin Address of the coin being borrowed
     * @param collateral Address of the collateral asset
     * @param colAmount The amount of collateral to deposit
     * @param coinAmount The amount of coin to borrow via the flash loan
     * @param swap Swap parameters for collateral to coin swap
     * @param minHealthFactor The minimum health factor required for the position
     */
    struct OpenParams {
        address coin;
        address collateral;
        uint256 colAmount;
        uint256 coinAmount;
        SwapParams swap;
        uint256 minHealthFactor;
    }

    /**
     * @notice Parameters for closing a leveraged position
     * @param coin Address of the coin being borrowed
     * @param collateral Address of the collateral asset
     * @param colAmount The amount of collateral to keep after closing the position
     * @param swap Swap parameters for coin to collateral swap
     */
    struct CloseParams {
        address coin;
        address collateral;
        uint256 colAmount;
        SwapParams swap;
    }

    GetHealthFactor getHealthFactor = new GetHealthFactor();
    GetDebt getDebt = new GetDebt();
    SupplyAssets supplyAssets = new SupplyAssets();
    BorrowAssests borrowAssets = new BorrowAssests();
    Initializer initializer = new Initializer();
    RepayAssests repayAssets = new RepayAssests();
    WithdrawAssets withdrawAssets = new WithdrawAssets();

    /**
     * @notice Get maximum flash loan amount for a given collateral and base collateral amount
     * @param collateral collateral token address
     * @param baseColAmount collateral amount to use for the loan
     * @return max maxium flash loan amount that can be borrowed in usd w/ 18 decimals
     * @return price price of collateral unit in usd w/ 8 decimals
     * @return ltv loan-to-value ratio for the collateral (4 decimals)
     * @return maxLev maximum leverage factor allowed for the collateral (4 decimals)
     */
    function getMaxFlashLoanAmountUsd(address collateral, uint256 baseColAmount)
        external
        view
        returns (uint256 max, uint256 price, uint256 ltv, uint256 maxLev)
    {
        uint256 decimals;
        (decimals, ltv,,,,,,,,) = IPoolDataProvider(AAVE_POOL_DATA_PROVIDER).getReserveConfigurationData(collateral);

        price = IAaveOracle(AAVE_ORACLE).getAssetPrice(collateral);

        maxLev = ltv * 1e4 / (1e4 - ltv);

        max = baseColAmount * (10 ** (18 - decimals)) * price * ltv / (1e4 - ltv) / 1e8;
    }

    /**
     * @notice Opens a leveraged position
     * @param params parameters for opening the position
     */
    function open(OpenParams calldata params) external {
        IERC20(params.collateral).approve(address(this), params.colAmount);
        IERC20(params.collateral).transferFrom(msg.sender, address(this), params.colAmount);

        FlashLoan.run({
            token: params.coin,
            amount: params.coinAmount,
            data: abi.encode(
                FlashLoanData({
                    coin: params.coin,
                    collateral: params.collateral,
                    open: true,
                    caller: msg.sender,
                    colAmount: params.colAmount,
                    swap: params.swap
                })
            )
        });

        if (getHealthFactor.run(msg.sender) < params.minHealthFactor) {
            revert FlashLev__HealthFactorTooLow();
        }
    }

    /**
     * @notice Closes a leveraged Position
     * @param params parameters for closing the position
     */
    function close(CloseParams calldata params) external {
        uint256 coinAmount = getDebt.run(address(this), params.coin);

        FlashLoan.run({
            token: params.coin,
            amount: coinAmount,
            data: abi.encode(
                FlashLoanData({
                    coin: params.coin,
                    collateral: params.collateral,
                    open: false,
                    caller: msg.sender,
                    colAmount: params.colAmount,
                    swap: params.swap
                })
            )
        });
    }

    /**
     * @notice Callback function to handle flash loan operations
     * @param token address of the token used in the flash Loan
     * @param amount amount of tokens borrowed
     * @param fee the fee for the flash loan
     * @param params additonal parameters for the flash loan operations --> decode it into flashLoanData
     * @dev this function is executed after the flash loan is issued
     */
    function _flashLoanCallBack(address token, uint256 amount, uint256 fee, bytes memory params) internal override {
        FlashLoanData memory data = abi.decode(params, (FlashLoanData));
        uint256 repayAmount = amount + fee;
        IERC20 coin = IERC20(data.coin);
        IERC20 collateral = IERC20(data.collateral);
        address aavePool = IPoolAddressesProvider(AAVE_POOL_ADDRESSES_PROVIDER).getPool();

        if (data.open) {
            uint256 colAmountOut = swap({
                tokenIn: data.coin,
                tokenOut: data.collateral,
                amountIn: amount,
                amountOutMin: data.swap.amountOutMin,
                data: data.swap.data
            });
            uint256 colAmount = data.colAmount + colAmountOut;
            collateral.approve(address(aavePool), colAmount);
            supplyAssets.run({token: data.collateral, amount: colAmount});
            borrowAssets.run({token: data.coin, amount: repayAmount});
        } else {
            coin.approve(address(aavePool), amount);
            repayAssets.run({token: data.coin, amount: amount});

            uint256 colWithdrawn = withdrawAssets.run({token: data.collateral, amount: type(uint256).max});

            collateral.transfer(data.caller, data.colAmount);
            uint256 colAmountIn = colWithdrawn - data.colAmount;

            uint256 coinAmountOut = swap({
                tokenIn: address(collateral),
                tokenOut: address(coin),
                amountIn: colAmountIn,
                amountOutMin: data.swap.amountOutMin,
                data: data.swap.data
            });

            if (coinAmountOut < repayAmount) {
                coin.transferFrom(data.caller, address(this), repayAmount - coinAmountOut);
            } else {
                coin.transfer(data.caller, coinAmountOut - repayAmount);
            }
        }

        coin.approve(address(aavePool), repayAmount);
    }
}
