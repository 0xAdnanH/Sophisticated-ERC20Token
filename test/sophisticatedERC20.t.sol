// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "src/sophisticatedERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract GenericTest is Test {}

contract SophisticatedERC20Test is Test {
    SophisticatedERC20 token;
    address address1;

    function setUp() public {
        // Deploy the contract with the test contract as the owner
        token = new SophisticatedERC20(address(this));
        address1 = makeAddr("alice");
    }

    receive() external payable {}

    function testInitialOwnerAllocation() public {
        uint256 initialBalance = token.balanceOf(address(this));
        assertEq(
            initialBalance,
            10000 * 10 ** 18,
            "Owner should have initial allocation"
        );
    }

    function testContractNotPausedAndOwnerCanTransfer() public {
        address recipient = address(0x1);
        uint256 transferAmount = 1000 * 10 ** 18;

        token.transfer(recipient, transferAmount);

        uint256 finalOwnerBalance = token.balanceOf(address(this));
        uint256 recipientBalance = token.balanceOf(recipient);

        assertEq(
            finalOwnerBalance,
            10000 * 10 ** 18 - transferAmount,
            "Owner balance should decrease"
        );
        assertEq(
            recipientBalance,
            transferAmount,
            "Recipient should receive tokens"
        );
    }

    function testOwnerIsSetCorrectly() public {
        address expectedOwner = address(this);
        assertEq(token.owner(), expectedOwner, "Owner is not set correctly");
    }

    function testOwnerCannotMint() public {
        uint256 mintAmount = 1 ether; // Amount greater than mint price

        vm.expectRevert(SophisticatedERC20.OwnerCannotMint.selector);
        vm.prank(address(this)); // As the owner is the sender
        token.mint{value: mintAmount}();
    }

    function testUserCannotMintWithInsufficientEther() public {
        uint256 insufficientAmount = 0.00001 ether; // Less than the mint price

        vm.prank(address1);
        vm.deal(address1, 10000e18);
        vm.expectRevert(SophisticatedERC20.InsufficientEther.selector);
        token.mint{value: insufficientAmount}();
    }

    function testUserCanMintCorrectly() public {
        address user = address1;
        vm.deal(user, 10000e18);

        uint256 mintPrice = 0.0001 ether;
        uint256 correctAmount = 0.0001 ether; // Equal to the mint price
        uint256 expectedTokenAmount = ((correctAmount / mintPrice) * 10 ** 18); // Assuming 1 token per MINT_PRICE

        vm.prank(user);
        token.mint{value: correctAmount}();

        uint256 userBalance = token.balanceOf(user);
        assertEq(
            userBalance,
            expectedTokenAmount,
            "User should receive correct token amount"
        );
    }

    function testCannotMintWhenPaused() public {
        address user = address(0x3);
        vm.deal(user, 10000e18);
        uint256 correctAmount = 0.0001 ether;

        token.pause(); // Pausing the contract

        vm.expectRevert(Pausable.EnforcedPause.selector);
        vm.prank(user);
        token.mint{value: correctAmount}();
    }

    function testCannotTransferWhenPaused() public {
        address recipient = address(0x4);
        uint256 transferAmount = 100 * 10 ** 18;

        token.pause(); // Pausing the contract

        vm.expectRevert(Pausable.EnforcedPause.selector);
        vm.prank(address(this)); // Since the test contract is the owner
        token.transfer(recipient, transferAmount);
    }

    function testCanBurnAfterUnpause() public {
        address user = address(0x5);

        uint256 mintPrice = 0.0001 ether;
        uint256 mintAmount = 0.0001 ether;
        uint256 expectedTokenAmount = (mintAmount / mintPrice) * 10 ** 18;

        deal(address(token), user, expectedTokenAmount);

        token.pause();
        token.unpause();

        vm.prank(user); // User burns their tokens
        token.burn(expectedTokenAmount);

        uint256 userBalanceAfterBurn = token.balanceOf(user);
        assertEq(
            userBalanceAfterBurn,
            0,
            "User should have zero balance after burning all tokens"
        );
    }

    function testCannotMintAfterMintEndTime() public {
        address user = address(0x6);
        vm.deal(user, 10000e18);

        uint256 correctAmount = 0.0001 ether;

        // Warp to a time after the mint end time
        vm.warp(block.timestamp + 31 days); // Assuming MINT_END_TIME is 30 days from deployment

        vm.expectRevert(SophisticatedERC20.MintingPeriodOver.selector);
        vm.prank(user);
        token.mint{value: correctAmount}();
    }

    function testOwnerCanWithdrawFunds() public {
        uint256 initialContractBalance = address(token).balance;

        uint256 initialOwnerBalance = address(this).balance;

        // Owner withdraws funds from the contract
        token.withdraw(initialContractBalance);

        uint256 finalContractBalance = address(token).balance;
        uint256 finalOwnerBalance = address(this).balance;

        assertEq(finalContractBalance, 0);
        assertEq(
            initialContractBalance + initialOwnerBalance,
            finalOwnerBalance
        );
    }
}
