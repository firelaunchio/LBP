// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { console } from "forge-std/Test.sol";
import { ContractTest } from "./Contract.t.sol";

contract BuyTest is ContractTest {
    function setUp() public {
        deploy();
        create_pool();
    }

    function test_buy() public {
        pool_buy();
    }

    function testFail_swapDisallowedStart() public {
        vm.warp(pool.saleStart() - 1);
        vm.startPrank(user);
        uint256 assetsIn = 100e18;
        usdt.mint(user, assetsIn);
        usdt.approve(address(pool), assetsIn);

        uint256 minSharesOut = pool.previewSharesOut(assetsIn);
        pool.swapExactAssetsForShares(assetsIn, minSharesOut, user);
        vm.stopPrank();
    }

    function testFail_swapDisallowedEnd() public {
        vm.warp(pool.saleEnd());
        vm.startPrank(user);
        uint256 assetsIn = 100e18;
        usdt.mint(user, assetsIn);
        usdt.approve(address(pool), assetsIn);

        uint256 minSharesOut = pool.previewSharesOut(assetsIn);
        pool.swapExactAssetsForShares(assetsIn, minSharesOut, user);
        vm.stopPrank();
    }

    function test_swapExactAssetsForShares() public {
        vm.startPrank(user);
        uint256 beforeBalanceOf = pepe.balanceOf(user);
        uint256 beforeShares = pool.purchasedShares(user);

        vm.warp(pool.saleStart());
        uint256 assetsIn = 100e18;
        usdt.mint(user, assetsIn);

        usdt.approve(address(pool), assetsIn);

        uint256 minSharesOut = pool.previewSharesOut(assetsIn);
        uint256 sharesOut = pool.swapExactAssetsForShares(assetsIn, minSharesOut, user);
        uint256 afterBalanceOf = pepe.balanceOf(user);
        uint256 afterShares = pool.purchasedShares(user);
        vm.stopPrank();

        console.log("beforeShares:%d", beforeShares);
        console.log("sharesOut:%d", sharesOut);
        console.log("afterShares:%d", afterShares);
        assertEq(beforeBalanceOf, afterBalanceOf);
        assertEq(beforeShares + sharesOut, afterShares);
    }

    function test_swapAssetsForExactShares() public {
        vm.startPrank(user);

        uint256 beforeShares = pool.purchasedShares(user);

        vm.warp((pool.saleStart() + pool.saleEnd()) / 2);
        uint256 sharesOut = 1e18;
        uint256 maxAssetsIn = pool.previewAssetsIn(sharesOut);
        usdt.mint(user, maxAssetsIn);
        usdt.approve(address(pool), maxAssetsIn);

        uint256 beforeBalanceOf = usdt.balanceOf(user);
        uint256 assetsIn = pool.swapAssetsForExactShares(sharesOut, maxAssetsIn, user);

        uint256 afterBalanceOf = usdt.balanceOf(user);
        uint256 afterShares = pool.purchasedShares(user);
        vm.stopPrank();

        console.log("beforeShares:%d", beforeShares);
        console.log("afterShares:%d", afterShares);
        console.log("assetsIn:%d", assetsIn);
        assertEq(beforeBalanceOf, afterBalanceOf + assetsIn);
        assertEq(beforeShares + sharesOut, afterShares);
    }
}
