// SPDX-License-Indentifier: MIT

pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./interface/aave/IPoolAddressesProvider.sol";

contract Constants {
    address constant AAVE_POOL_ADDRESSES_PROVIDER = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;
    address constant AAVE_POOL_DATA_PROVIDER = 0x41393e5e337606dc3821075Af65AeE84D7688CBD;
    address constant AAVE_ORACLE = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;
    address constant AAVE_A_DAI = 0x018008bfb33d285247A21d44E50697654f754e63;
    address constant AAVE_A_WETH = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    address constant AAVE_A_RETH = 0xCc9EE9483f662091a1de4795249E24aC0aC2630f;
    address constant AAVE_VAR_DEBT_DAI = 0xcF8d0c70c850859266f5C338b38F9D663181C314;
}
