// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import {Test} from "forge-std/Test.sol";
import {LiquidityPool} from "../src/LiquidityPool.sol";
import {LiquidityPoolFactory, PoolSettings} from "../src/LiquidityPoolFactory.sol";
import {Treasury} from "../src/Treasury.sol";
import {Moon} from "./utils/Moon.sol";

contract ContractTest is Test {
    LiquidityPool public pool;
    Treasury public treasury;
    LiquidityPoolFactory public factory;

    Moon public usdt;
    Moon public pepe;

    address public owner = address(0x01);
    address public create = address(0x02);
    address public user = address(0x03);
    address public other = address(0xFF);
    address internal sablier = address(0xd4300c5bC0B9e27c73eBAbDc747ba990B1B570Db);

    uint256 blockTime = 1714521600; // 2024-05-01 00:00:00

    function deploy() public {
        usdt = new Moon("usdt coin", "USDT");
        pepe = new Moon("pepe coin", "PEPE");

        LiquidityPool implementation = new LiquidityPool(sablier);
        treasury = new Treasury(owner);
        factory = new LiquidityPoolFactory(address(implementation), owner, address(treasury), 300, 0, 200);
        vm.warp(blockTime);
    }

    function create_pool() internal {
        uint256 assets = 10000e18;
        uint256 shares = 10000e18;

        uint40 saleStart = uint40(blockTime) + 86400;
        uint40 saleEnd = saleStart + 86400 * 3;
        pool = LiquidityPool(create_pool(saleStart, saleEnd, assets, shares));
    }

    function pool_buy() internal {
        vm.warp((pool.saleStart() + pool.saleEnd()) / 2);
        vm.startPrank(user);
        uint256 sharesOut = 100e18;
        uint256 maxAssetsIn = pool.previewAssetsIn(sharesOut);
        usdt.mint(user, maxAssetsIn);
        usdt.approve(address(pool), maxAssetsIn);
        pool.swapAssetsForExactShares(sharesOut, maxAssetsIn, user);
        vm.stopPrank();
    }

    function pool_close() internal {
        vm.warp(pool.saleEnd());
        pool.close();
    }

    function pool_redeem() internal {
        vm.startPrank(user);
        pool.redeem(user, false);
        vm.stopPrank();
    }

    function create_pool(uint40 saleStart, uint40 saleEnd, uint256 assets, uint256 shares) internal returns (address iPool) {
        vm.startPrank(create);

        usdt.mint(create, assets);
        usdt.approve(address(factory), assets);

        pepe.mint(create, shares);
        pepe.approve(address(factory), shares);

        PoolSettings memory args = PoolSettings({
          asset: address(usdt),
          share: address(pepe),
          creator: create,
          virtualAssets: 0,
          virtualShares: 0,
          maxSharePrice: 309485009821345068724781055,
          maxSharesOut: 309485009821345068724781055,
          maxAssetsIn: 309485009821345068724781055,
          weightStart: 1e16,
          weightEnd: 60e16,
          saleStart: saleStart,
          saleEnd: saleEnd,
          vestCliff: 0,
          vestEnd: 0,
          sellingAllowed: true,
          whitelistMerkleRoot: 0
        });

        iPool = factory.createLiquidityPool(args, assets, shares, "0");
        vm.stopPrank();
    }

}
