pragma solidity 0.6.5;

import "./Ownable.sol";


contract Control is Ownable {

    /*** STORAGE ***/

    /// @dev Requested new address to change owner address.
    address public requestedOwner = address(0);
    /// @dev Drafter to change owner address.
    address public requestDrafter = address(0);
    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked.
    bool public paused = false;

    // The Distributed addresses of the accounts that can execute actions.
    address public melchiorAddress;
    address public balthasarAddress;
    address public casperAddress;

    /*** MODIFIER ***/
    /// @dev Access modifier for MAGIs-only functionality
    modifier onlyMAGIs() {
        require(
            msg.sender == melchiorAddress ||
            msg.sender == balthasarAddress ||
            msg.sender == casperAddress
        );
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /*** External Functions ***/
    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) public override onlyMAGIs {
        require(newOwner != address(0));

        // if 2 of 3 MAGIs agreed
        if (requestedOwner != address(0) && requestDrafter != msg.sender && newOwner == requestedOwner) {
            // changes owner address to new address
            _transferOwnership(newOwner);
            requestedOwner = address(0);
            requestDrafter = address(0);
        } else {
            // requets to change owner address to new address
            requestedOwner = newOwner;
            requestDrafter = msg.sender;
        }
    }

    /// @dev Assigns a new address to act as the MelchiorMAGI. Only available to the current MelchiorMAGI.
    /// @param _newMelchior The address of the new Melchior
    function setMelchiorMAGI(address _newMelchior) external onlyOwner {
        require(_newMelchior != address(0));
        require(_newMelchior != owner());
        require(requestDrafter == melchiorAddress || requestDrafter == address(0));

        melchiorAddress = _newMelchior;
    }

    /// @dev Assigns a new address to act as the BalthasarMAGI. Only available to the current BalthasarMAGI.
    /// @param _newBalthasar The address of the new Balthasar
    function setBalthasarMAGI(address _newBalthasar) external onlyOwner {
        require(_newBalthasar != address(0));
        require(_newBalthasar != owner());
        require(requestDrafter == balthasarAddress || requestDrafter == address(0));

        balthasarAddress = _newBalthasar;
    }

    /// @dev Assigns a new address to act as the CasperMAGI. Only available to the current CasperMAGI.
    /// @param _newCasper The address of the new Casper
    function setCasperMAGI(address _newCasper) external onlyOwner {
        require(_newCasper != address(0));
        require(_newCasper != owner());
        require(requestDrafter == casperAddress || requestDrafter == address(0));

        casperAddress = _newCasper;
    }

    /// @dev Called by owner to pause the contract.
    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    /// @dev Called by owner to unpause the contract.
    function unpause() external onlyOwner whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }

}
