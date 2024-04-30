// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { ContractTest } from "./Contract.t.sol";

error InvalidInput();

contract TreasuryTest is ContractTest {
    function setUp() public {
        deploy();
    }

    function test_updateRecipients() public {
        vm.startPrank(owner);
        address[] memory recipients = new address[](2);
        recipients[0] = address(0x12);
        recipients[1] = address(0x13);
        uint256[] memory percentages = new uint256[](2);
        percentages[0] = 4e17;
        percentages[1] = 6e17;
        treasury.updateRecipients(recipients, percentages);
        vm.stopPrank();
    }

    function test_updateRecipients10() public {
        vm.startPrank(owner);
        address[] memory recipients = new address[](10);
        recipients[0] = address(0x10);
        recipients[1] = address(0x11);
        recipients[2] = address(0x12);
        recipients[3] = address(0x13);
        recipients[4] = address(0x14);
        recipients[5] = address(0x15);
        recipients[6] = address(0x16);
        recipients[7] = address(0x17);
        recipients[8] = address(0x18);
        recipients[9] = address(0x19);
        uint256[] memory percentages = new uint256[](10);
        percentages[0] = 1e17;
        percentages[1] = 1e17;
        percentages[2] = 1e17;
        percentages[3] = 1e17;
        percentages[4] = 1e17;
        percentages[5] = 1e17;
        percentages[6] = 1e17;
        percentages[7] = 1e17;
        percentages[8] = 1e17;
        percentages[9] = 1e17;
        treasury.updateRecipients(recipients, percentages);
        vm.stopPrank();
    }

    function testFail_updateRecipients() public {
        vm.startPrank(owner);
        address[] memory recipients = new address[](2);
        recipients[0] = address(0x12);
        recipients[1] = address(0x13);
        uint256[] memory percentages = new uint256[](3);
        percentages[0] = 4e17;
        percentages[1] = 6e17;

        treasury.updateRecipients(recipients, percentages);
        vm.stopPrank();
    }
}
