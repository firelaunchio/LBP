// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import {console} from "forge-std/Test.sol";
import {ContractTest} from "./Contract.t.sol";

contract SellTest is ContractTest {
    function setUp() public {
         deploy();
         create_pool();
         pool_buy();
    }

    function test_swapExactSharesForAssets() public {
        vm.startPrank(user);

        uint256 beforeBalanceOf = usdt.balanceOf(user);
        uint256 beforeShares = pool.purchasedShares(user);

        uint256 sharesIn = 10e18;
        uint256 minAssetsOut = pool.previewAssetsOut(sharesIn);
        uint256 assetsOut = pool.swapExactSharesForAssets(sharesIn, minAssetsOut, user);

        uint256 afterBalanceOf = usdt.balanceOf(user);
        uint256 afterShares = pool.purchasedShares(user);
        vm.stopPrank();

        console.log("beforeShares:%d", beforeShares);
        console.log("afterShares:%d", afterShares);
        console.log("assetsOut:%d", assetsOut);
        assertEq(beforeBalanceOf +  assetsOut, afterBalanceOf);
        assertEq(beforeShares, afterShares + sharesIn);
    }

    function testFail_sellOutShare() public {
        vm.startPrank(user);

        uint256 beforeBalanceOf = usdt.balanceOf(user);
        uint256 beforeShares = pool.purchasedShares(user);

        uint256 sharesIn = beforeShares + 1;
        uint256 minAssetsOut = pool.previewAssetsOut(sharesIn);
        uint256 assetsOut = pool.swapExactSharesForAssets(sharesIn, minAssetsOut, user);

        uint256 afterBalanceOf = usdt.balanceOf(user);
        uint256 afterShares = pool.purchasedShares(user);
        vm.stopPrank();

        console.log("beforeShares:%d", beforeShares);
        console.log("afterShares:%d", afterShares);
        console.log("assetsOut:%d", assetsOut);
        assertEq(beforeBalanceOf +  assetsOut, afterBalanceOf);
        assertEq(beforeShares, afterShares + sharesIn);
    }

    function test_swapSharesForExactAssets() public {
        vm.startPrank(user);

        uint256 beforeBalanceOf = usdt.balanceOf(user);
        uint256 beforeShares = pool.purchasedShares(user);

        vm.warp((pool.saleStart() + pool.saleEnd()) / 2);
        uint256 assetsOut = 10e18;
        uint256 maxSharesIn = pool.previewSharesIn(assetsOut);
        uint256 sharesIn = pool.swapSharesForExactAssets(assetsOut, maxSharesIn, user);

        uint256 afterBalanceOf = usdt.balanceOf(user);
        uint256 afterShares = pool.purchasedShares(user);
        vm.stopPrank();

        console.log("beforeShares:%d", beforeShares);
        console.log("afterShares:%d", afterShares);
        console.log("assetsOut:%d", assetsOut);
        assertEq(beforeBalanceOf +  assetsOut, afterBalanceOf);
        assertEq(beforeShares, afterShares + sharesIn);
    }

}
