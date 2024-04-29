// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.7;

abstract contract Pausable {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Paused(bool);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error EnforcedPause();

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    bool public paused;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier whenNotPaused() {
        if (paused) revert EnforcedPause();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Internal Logic
    /// -----------------------------------------------------------------------

    function _togglePause() internal virtual {
        emit Paused(paused = !paused);
    }
}