pragma solidity 0.5.0;

import "./Control.sol";

import "./ERC20.sol";
import "./MinterRole.sol";
import "./Pausable.sol";


contract ERC20Token is Control, ERC20, MinterRole {
    function transfer(
        address to,
        uint256 value
    )
    public
    whenNotPaused
    returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    public
    whenNotPaused
    returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    function approve(
        address spender,
        uint256 value
    )
    public
    whenNotPaused
    returns (bool)
    {
        return super.approve(spender, value);
    }

    function increaseAllowance(
        address spender,
        uint addedValue
    )
    public
    whenNotPaused
    returns (bool success)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(
        address spender,
        uint subtractedValue
    )
    public
    whenNotPaused
    returns (bool success)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}
