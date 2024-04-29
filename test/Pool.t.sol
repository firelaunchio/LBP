// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { ContractTest } from "./Contract.t.sol";

contract PoolTest is ContractTest {
    function setUp() public {
        deploy();
    }

    function test_create() public {
        create_pool();
    }

    function testFail_createExist() public {
        uint256 assets = 10_000e18;
        uint256 shares = 10_000e18;

        uint40 saleStart = uint40(blockTime);
        uint40 saleEnd = saleStart + 86_400 * 3;
        create_pool(saleStart, saleEnd, assets, shares);
        create_pool(saleStart, saleEnd, assets, shares);
    }

    function testFail_createTime() public {
        uint256 assets = 10_000e18;
        uint256 shares = 10_000e18;

        uint40 saleStart = uint40(blockTime);
        uint40 saleEnd = saleStart + 86_400 - 1;
        create_pool(saleStart, saleEnd, assets, shares);
    }
}
