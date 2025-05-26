# AAVE-SDK

It is a smart contract project written in [Solidity](https://docs.soliditylang.org/en/latest/) using [Foundry](https://book.getfoundry.sh/).

-   It is a comprehensive SDK I developed for interacting with the AAVE protocol leveraging Foundry.
-   It consists of multiple sub-components:
    -   **FlashLev**: A leveraged position creator using AAVE's flash loan functionality
    -   **SwapHelper**: Uniswap V3 swap helper for token exchanges
    -   **Interaction Scripts**: Pre-built scripts for common AAVE operations (supply, borrow, withdraw, repay)
-   The SDK enables users to create leveraged positions by borrowing assets via flash loans, swapping them for collateral, and managing positions efficiently.
-   It implements advanced DeFi strategies including:
    -   Flash loan leveraged positions (opening and closing)
    -   Token swaps via Uniswap V3
    -   Health factor monitoring and management
    -   Automated debt and collateral management
-   Supports Ethereum Mainnet and Sepolia testnet with configurable constants for different networks.

## Getting Started

-   [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git): You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
-   [foundry](https://getfoundry.sh/): You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`
-   [make](https://www.gnu.org/software/make/manual/make.html) (optional - either you can install `make` or you can simply substitute the make commands with forge commands by referring to the available commands after including your .env file): You'll know you did it right if you can run `make --version` and you will see a response like `GNU Make 3.81...`

## Installation

-   Install AAVE-SDK

```bash
    git clone https://github.com/yug49/AAVE-SDK
    cd AAVE-SDK
```

-   Make a .env file

```bash
    touch .env
```

-   Open the .env file and fill in the details similar to:

```env
    SEPOLIA_RPC_URL=<YOUR SEPOLIA RPC URL>
    MAINNET_RPC_URL=<YOUR MAINNET RPC URL>
    ETHERSCAN_API_KEY=<YOUR ETHERSCAN API KEY>
    PRIVATE_KEY=<YOUR PRIVATE KEY>
```

-   Install dependencies and libraries

```bash
    forge install
```

-   Build Project

```bash
    forge build
```

## Configuration

### Network Setup

-   The SDK supports both Ethereum Mainnet
-   Network configuration is handled in `src/Constants.sol`
-   By default, Mainnet constants are active. To switch to Sepolia, uncomment the Sepolia section and comment out the Mainnet section

### Input Parameters

-   Modify `script/Inputs.s.sol` to configure your interaction parameters:
    -   Supply/Withdraw token addresses and amounts
    -   Borrow/Repay token addresses and amounts
    -   User addresses for queries
    -   Collateral and debt token preferences

## Core Features

### 1. Flash Loan Leveraged Positions

-   **Opening Positions**: Borrow assets via flash loans, swap for collateral, deposit as collateral
-   **Closing Positions**: Withdraw collateral, swap back to borrowed asset, repay flash loan

### 2. Token Swaps

-   **Uniswap V3**: Efficient swaps with configurable fees and optimal routing

### 3. AAVE Protocol Interactions

-   **Supply Assets**: Deposit tokens to earn yield
-   **Borrow Assets**: Borrow against your collateral
-   **Withdraw Assets**: Remove your supplied tokens
-   **Repay Debts**: Pay back borrowed amounts

## Interactions / Usage

### Basic AAVE Operations

#### Supply Assets to AAVE

```bash
    forge script script/Interactions.s.sol:SupplyAssets --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

#### Withdraw Assets from AAVE

```bash
    forge script script/Interactions.s.sol:WithdrawAssets --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

#### Borrow Assets from AAVE

```bash
    forge script script/Interactions.s.sol:BorrowAssets --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

#### Repay Borrowed Assets

```bash
    forge script script/Interactions.s.sol:RepayAssets --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Advanced Operations

#### Check User's Health Factor

```bash
    forge script script/Interactions.s.sol:GetHealthFactor --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

#### Check User's Collateral Balance

```bash
    forge script script/Interactions.s.sol:GetCollateral --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

#### Check User's Debt Balance

```bash
    forge script script/Interactions.s.sol:GetDebt --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Leveraged Position Management

#### Open a Leveraged Position

-   Configure your position parameters in the FlashLev contract
-   Use the `openLeveragedPosition` function with appropriate OpenParams

#### Close a Leveraged Position

-   Use the `closeLeveragedPosition` function with appropriate CloseParams
-   Ensure sufficient collateral to cover the flash loan repayment

## Testing

### Run All Tests

```bash
    forge test --fork-url $MAINNET_RPC_URL
```

### Run Tests with Verbosity

```bash
    forge test --fork-url $MAINNET_RPC_URL -vv
```

### Run Specific Test

```bash
    forge test --match-test testSpecificFunction --fork-url $MAINNET_RPC_URL
```

### Test Coverage

```bash
    forge coverage --fork-url $MAINNET_RPC_URL
```

## Formatting

-   To format all the solidity files:

```bash
    forge fmt
```

## Gas Optimization

-   You can analyze gas usage by running:

```bash
    forge snapshot
```

## Architecture

```
AAVE-SDK/
├── src/
│   ├── FlashLev.sol          # Main leveraged position contract
│   ├── Constants.sol         # Network and protocol constants
│   ├── helper/
│   │   └── SwapHelper.sol    # Uniswap V3 swap functionality
│   └── interface/            # Interface definitions
├── script/
│   ├── Interactions.s.sol    # Interaction scripts for AAVE operations
│   └── Inputs.s.sol          # Configuration parameters
└── test/                     # Test suite
    ├── AaveTest.t.sol        # Tests for FlashLev contract
    └── Interactions.t.sol    # Tests for interaction scripts
```

## 🔗 Links

Loved it? lets connect on:

[![twitter](https://img.shields.io/badge/twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://x.com/yugAgarwal29)
[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/yug-agarwal-8b761b255/)
