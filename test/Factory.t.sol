// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { ContractTest } from "./Contract.t.sol";

contract FactoryTest is ContractTest {
    function setUp() public {
        deploy();
    }

    function test_feeRecipient() public {
        vm.startPrank(owner);
        factory.setFeeRecipient(other);
        vm.stopPrank();
    }

    function test_platformFee() public {
        vm.startPrank(owner);
        factory.setPlatformFee(200);
        vm.stopPrank();
    }

    function test_referrerFee() public {
        vm.startPrank(owner);
        factory.setReferrerFee(200);
        vm.stopPrank();
    }

    function test_swapFee() public {
        vm.startPrank(owner);
        factory.setSwapFee(200);
        vm.stopPrank();
    }

    function testFail_feeRecipient() public {
        factory.setFeeRecipient(other);
    }

    function testFail_platformFee() public {
        vm.startPrank(user);
        factory.setPlatformFee(200);
        vm.stopPrank();
    }

    function testFail_referrerFee() public {
        vm.startPrank(owner);
        factory.setReferrerFee(1001);
        vm.stopPrank();
    }

    function testFail_swapFee() public {
        factory.setSwapFee(200);
    }
}
