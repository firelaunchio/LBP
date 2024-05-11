// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { ContractTest } from "./Contract.t.sol";

contract CloseTest is ContractTest {
    function setUp() public {
        deploy();
        create_pool();
        pool_buy();
    }

    function test_close() public {
        pool_close();
    }

    function test_closeShares() public {
        vm.warp(pool.saleEnd());

        uint256 beforeBalanceOf = pepe.balanceOf(create);
        uint256 shares = pepe.balanceOf(address(pool)) - pool.totalPurchased() - pool.totalSwapFeesShare();

        pool.close();
        uint256 afterBalanceOf = pepe.balanceOf(create);
        assertEq(beforeBalanceOf + shares, afterBalanceOf);

        uint256 poolBalanceOf = pepe.balanceOf(address(pool));
        assertEq(pool.totalPurchased(), poolBalanceOf);
    }

    function test_closeAssets() public {
        vm.warp(pool.saleEnd());

        uint256 beforeBalanceOf = usdt.balanceOf(create);
        uint256 totalAssets = usdt.balanceOf(address(pool)) - pool.totalSwapFeesAsset();
        uint256 platformFees = totalAssets * pool.platformFee() / 1e18;
        uint256 totalAssetsMinusFees = totalAssets - platformFees;

        pool.close();
        uint256 afterBalanceOf = usdt.balanceOf(create);
        assertEq(beforeBalanceOf + totalAssetsMinusFees, afterBalanceOf);

        uint256 poolBalanceOf = usdt.balanceOf(address(pool));
        assertEq(0, poolBalanceOf);
    }

    function test_closeTreasuryShares() public {
        vm.warp(pool.saleEnd());

        uint256 beforeBalanceOf = pepe.balanceOf(owner);
        pool.close();
        uint256 afterBalanceOf = pepe.balanceOf(owner);
        assertEq(beforeBalanceOf + pool.totalSwapFeesShare(), afterBalanceOf);
    }

    function test_closeTreasuryAssets() public {
        vm.warp(pool.saleEnd());

        uint256 beforeBalanceOf = usdt.balanceOf(owner);

        uint256 totalAssets = usdt.balanceOf(address(pool)) - pool.totalSwapFeesAsset();
        uint256 platformFees = totalAssets * pool.platformFee() / 1e18;

        pool.close();
        uint256 afterBalanceOf = usdt.balanceOf(owner);
        assertEq(beforeBalanceOf + pool.totalSwapFeesAsset() + platformFees, afterBalanceOf);
    }

    function testFail_closeTime() public {
        pool.close();
    }

    function testFail_Redeem() public {
        pool_redeem();
    }
}
