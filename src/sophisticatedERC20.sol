// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title Sophisticated ERC20 Token
/// @dev An ERC20 token with burn, pause, and payable mint functionalities.
contract SophisticatedERC20 is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    uint256 public constant MINT_PRICE = 0.0001 ether;
    uint256 public immutable MINT_END_TIME;
    uint256 public constant INITIAL_OWNER_ALLOCATION = 10000 * 10 ** 18;

    /// @dev Emitted when minting is no longer allowed
    error MintingPeriodOver();

    /// @dev Emitted when insufficient Ether is sent for minting
    error InsufficientEther();

    /// @dev Emitted when the minting is attempted by the owner
    error OwnerCannotMint();

    constructor(
        address _newOwner
    ) ERC20("SophisticatedToken", "SOPH") Ownable(_newOwner) {
        MINT_END_TIME = block.timestamp + 30 days;
        _mint(msg.sender, INITIAL_OWNER_ALLOCATION);
    }

    /// @notice Accepts Ether sent to the contract
    receive() external payable {}

    // Owner functionalities

    /// @notice Pauses all token transfers
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses all token transfers
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw specified amount of Ether from the contract
    /// @param funds The amount of Ether to withdraw
    function withdraw(uint256 funds) public onlyOwner {
        (bool success, bytes memory returnedData) = payable(owner()).call{
            value: funds
        }("");
        Address.verifyCallResult(success, returnedData);
    }

    // Public functionalities

    /// @notice Allows users to mint tokens in exchange for Ether
    /// @dev Minting is allowed for a specific period and not by the owner
    function mint() public payable {
        if (block.timestamp > MINT_END_TIME) revert MintingPeriodOver();
        if (msg.value < MINT_PRICE) revert InsufficientEther();
        if (owner() == msg.sender) revert OwnerCannotMint();

        uint256 amountToMint = (msg.value / MINT_PRICE) * 10 ** 18; // Assuming 1 token per MINT_PRICE
        _mint(msg.sender, amountToMint);
    }

    // Internal functions

    /// @notice Overrides the token transfer update mechanism
    /// @dev Integrates the pausable functionality
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20, ERC20Pausable) {
        ERC20Pausable._update(from, to, value);
    }
}
