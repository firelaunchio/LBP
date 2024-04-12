// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@solady/src/utils/MerkleProofLib.sol";

contract WhitelistSale {
    address public governance;
    address public pendingGovernance;

    address public asset;
    address public share;
    address public addressTreasury;

    uint256 public salePrice;
    uint256 public allotment;
    uint256 public saleStart;
    uint256 public saleEnd;
    uint256 public maxPurchase;
    bytes32 public merkleRoot;

    uint256 public totalPurchase;
    bool public paused;
    bool public closed;
    mapping(address => uint256) public purchaseShares;

    error WhitelistProof();
    error AllotmentExceeded();
    error BuyDisallowed();
    error ClosingDisallowed();
    error RedeemingDisallowed();
    error EnforcedPause();
    error CallerDisallowed();
    error AlreadyInit();
    error SharesOutExceeded();

    event Purchase(address indexed account, uint256 assetsIn, uint256 sharesOut);
    event Redeem(address indexed account, uint256 shares);

    constructor() {
        governance = msg.sender;
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernance) {
            revert CallerDisallowed();
        }
        governance = msg.sender;
        pendingGovernance = address(0);
    }
    function setPendingGovernance(address pendingGovernance_) external {
        if (msg.sender != governance) {
            revert CallerDisallowed();
        }
        pendingGovernance = pendingGovernance_;
    }
    // set merkleRoot=0, the whitelist is closed
    function setWhitelisted(bytes32 merkleRoot_) external {
        if (msg.sender != governance) {
            revert CallerDisallowed();
        }
        merkleRoot = merkleRoot_;
    }
    // asset address. for example: usdt, dai
    // share address. project token
    // allotmet. the maximum quantity that users can purchase
    // salePrice. project token price. unit 1e18.
    // saleStart. project start time.
    // salePeriod. project period.
    // maxPurchase. project max Purchase
    // set up whitelist with merkleRoot
    function initialize(address asset_, address share_, address addressTreasury_, uint256 salePrice_, uint256 allotment_, uint256 saleStart_, uint256 salePeriod_, uint256 maxPurchase_, bytes32 merkleRoot_) external {
        if (msg.sender != governance) {
            revert CallerDisallowed();
        }
        if (saleEnd != 0) {
            revert AlreadyInit();
        }

        asset = asset_;
        share = share_;
        addressTreasury = addressTreasury_;

        salePrice  = salePrice_;
        allotment  = allotment_;
        saleStart  = saleStart_;
        saleEnd    = saleStart_ + salePeriod_;
        maxPurchase = maxPurchase_;
        merkleRoot  = merkleRoot_;
    }

    function purchase(uint256 assets_) external returns(uint256 sharesOut) {
        return purchase(assets_, MerkleProofLib.emptyProof());
    }

    function purchase(uint256 assets_, bytes32[] memory proof) public returns(uint256 sharesOut) {
        whenNotPaused();
        whenSaleActive();
        onlyWhitelisted(proof);

        IERC20(asset).transferFrom(msg.sender, address(this), assets_);

        sharesOut = _calculateSaleQuote(assets_);
        uint256 purchaseSharesAfter = purchaseShares[msg.sender] + sharesOut;
        if (purchaseSharesAfter > getAllotmentPerBuyer()) {
            revert AllotmentExceeded();
        }
        uint256 totalPurchaseAfter = totalPurchase + sharesOut;
        if (totalPurchaseAfter > maxPurchase) {
            revert SharesOutExceeded();
        }

        purchaseShares[msg.sender] = purchaseSharesAfter;
        totalPurchase = totalPurchaseAfter;

        emit Purchase(msg.sender, assets_, sharesOut);
    }

    // close project.
    function close() external {
        if (closed) revert ClosingDisallowed();
        if (block.timestamp < saleEnd) revert ClosingDisallowed();

        uint256 totalAssets = IERC20(asset).balanceOf(address(this));
        if (totalAssets != 0) {
            IERC20(asset).transfer(addressTreasury, totalAssets);
        }

        uint256 totalShares = IERC20(share).balanceOf(address(this));
        
        if (totalShares > totalPurchase) {
            uint256 unsoldShares = totalShares - totalPurchase;
            IERC20(share).transfer(addressTreasury, unsoldShares);
        }

        closed = true;
    }
    // user claim project token after project close.
    function redeem(address recipient) external returns (uint256 shares) {
        if (!closed) revert RedeemingDisallowed();

        shares = purchaseShares[msg.sender];
        delete purchaseShares[msg.sender];

        if (shares != 0) {
            IERC20(share).transfer(recipient, shares);
            emit Redeem(msg.sender, shares);
        }
    }
    // close IDO or open IDO.
    function togglePause() external {
        if (msg.sender != governance) {
            revert CallerDisallowed();
        }
        paused = !paused;
    }

    function whenNotPaused() internal view {
        if (paused) revert EnforcedPause();
    }

    function onlyWhitelisted(bytes32[] memory proof) internal view {
        if (merkleRoot != 0) {
            if (!MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))){
                revert WhitelistProof();
            }
        }
    }

    function whenSaleActive() internal view {
        if (block.timestamp < saleStart || block.timestamp >= saleEnd) {
            revert BuyDisallowed();
        }
    }

    function shareBalanceOf() public view returns (uint256) {
        return IERC20(share).balanceOf(address(this));
    }

    function getAllotmentPerBuyer() public view returns (uint256) {
        return allotment;
    }

    function _calculateSaleQuote(uint256 paymentAmount_) internal view returns (uint256) {
        return 1e18 * paymentAmount_ / salePrice;
    }
    // in: amount of assets
    // out: amount of shares.
    function calculateSaleQuote(uint paymentAmount_) external view returns (uint256) {
        return _calculateSaleQuote(paymentAmount_);
    }
}
