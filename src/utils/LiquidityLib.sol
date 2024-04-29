// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import "./WeightedMathLib.sol";

struct Pool {
    address asset;
    address share;
    uint256 assets;
    uint256 shares;
    uint256 virtualAssets;
    uint256 virtualShares;
    uint256 weightStart;
    uint256 weightEnd;
    uint256 saleStart;
    uint256 saleEnd;
    uint256 totalPurchased;
    uint256 maxSharePrice;
    uint8 assetDecimals;
    uint8 shareDecimals;
}

library LiquidityLib {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using WeightedMathLib for uint256;

    using FixedPointMathLib for uint256;

    /// -----------------------------------------------------------------------
    /// Swap Helpers
    /// -----------------------------------------------------------------------

    function computeReservesAndWeights(Pool memory args)
        internal
        view
        returns (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight)
    {
        assetReserve = args.assets + args.virtualAssets;

        shareReserve = args.shares + args.virtualShares - args.totalPurchased;

        uint256 totalSeconds = args.saleEnd - args.saleStart;

        uint256 secondsElapsed = 0;
        if (block.timestamp > args.saleStart) {
            secondsElapsed = block.timestamp - args.saleStart;
        }

        assetWeight = WeightedMathLib.linearInterpolation({
            x: args.weightStart,
            y: args.weightEnd,
            i: secondsElapsed,
            n: totalSeconds
        });

        shareWeight = uint256(1e18).rawSub(assetWeight);
    }

    function getPrice(Pool memory args, uint256 sharesOut) internal view returns (uint256 price) {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) = scaledReserves(args, assetReserve, shareReserve);
        uint256 sharesOutScaled = scaleTokenBefore(sharesOut, args.shareDecimals);

        uint256 assetsIn = sharesOutScaled.getAmountIn(assetReserveScaled, shareReserveScaled, assetWeight, shareWeight);

        price = assetsIn.divWad(sharesOutScaled);
        if (price > args.maxSharePrice) {
            price = args.maxSharePrice;
        }
    }

    function previewAssetsIn(Pool memory args, uint256 sharesOut) internal view returns (uint256 assetsIn) {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) = scaledReserves(args, assetReserve, shareReserve);
        uint256 sharesOutScaled = scaleTokenBefore(sharesOut, args.shareDecimals);

        assetsIn = sharesOutScaled.getAmountIn(assetReserveScaled, shareReserveScaled, assetWeight, shareWeight);

        if (assetsIn.divWad(sharesOutScaled) > args.maxSharePrice) {
            assetsIn = sharesOutScaled.divWad(args.maxSharePrice);
        }

        assetsIn = scaleTokenAfter(assetsIn, args.assetDecimals);
    }

    function previewSharesOut(Pool memory args, uint256 assetsIn) internal view returns (uint256 sharesOut) {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) = scaledReserves(args, assetReserve, shareReserve);
        uint256 assetsInScaled = scaleTokenBefore(assetsIn, args.assetDecimals);

        sharesOut = assetsInScaled.getAmountOut(assetReserveScaled, shareReserveScaled, assetWeight, shareWeight);

        if (assetsInScaled.divWad(sharesOut) > args.maxSharePrice) {
            sharesOut = assetsInScaled.mulWad(args.maxSharePrice);
        }

        sharesOut = scaleTokenAfter(sharesOut, args.shareDecimals);
    }

    function previewSharesIn(Pool memory args, uint256 assetsOut) internal view returns (uint256 sharesIn) {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) = scaledReserves(args, assetReserve, shareReserve);
        uint256 assetsOutScaled = scaleTokenBefore(assetsOut, args.assetDecimals);

        sharesIn = assetsOutScaled.getAmountIn(shareReserveScaled, assetReserveScaled, shareWeight, assetWeight);

        if (assetsOutScaled.divWad(sharesIn) > args.maxSharePrice) {
            sharesIn = assetsOutScaled.divWad(args.maxSharePrice);
        }

        sharesIn = scaleTokenAfter(sharesIn, args.shareDecimals);
    }

    function previewAssetsOut(Pool memory args, uint256 sharesIn) internal view returns (uint256 assetsOut) {
        (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) =
            computeReservesAndWeights(args);

        (uint256 assetReserveScaled, uint256 shareReserveScaled) = scaledReserves(args, assetReserve, shareReserve);
        uint256 sharesInScaled = scaleTokenBefore(sharesIn, args.shareDecimals);

        assetsOut = sharesInScaled.getAmountOut(shareReserveScaled, assetReserveScaled, shareWeight, assetWeight);

        if (assetsOut.divWad(sharesInScaled) > args.maxSharePrice) {
            assetsOut = sharesInScaled.mulWad(args.maxSharePrice);
        }

        assetsOut = scaleTokenAfter(assetsOut, args.assetDecimals);
    }

    function scaledReserves(
        Pool memory args,
        uint256 assetReserve,
        uint256 shareReserve
    )
        internal
        pure
        returns (uint256, uint256)
    {
        return (scaleTokenBefore(assetReserve, args.assetDecimals), scaleTokenBefore(shareReserve, args.shareDecimals));
    }

    function scaleTokenBefore(uint256 amount, uint8 decimals) internal pure returns (uint256 scaledAmount) {
        scaledAmount = amount;

        if (decimals < 18) {
            uint256 decDiff = uint256(18).rawSub(uint256(decimals));
            scaledAmount = amount * (10 ** decDiff);
        } else if (decimals > 18) {
            uint256 decDiff = uint256(decimals).rawSub(uint256(18));
            scaledAmount = amount / (10 ** decDiff);
        }
    }

    function scaleTokenAfter(uint256 amount, uint8 decimals) internal pure returns (uint256 scaledAmount) {
        scaledAmount = amount;

        if (decimals < 18) {
            uint256 decDiff = uint256(18).rawSub(uint256(decimals));
            scaledAmount = amount / (10 ** decDiff);
        } else if (decimals > 18) {
            uint256 decDiff = uint256(decimals).rawSub(uint256(18));
            scaledAmount = amount * (10 ** decDiff);
        }
    }
}
