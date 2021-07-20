pragma solidity 0.6.5;


contract OwnerLinkedIdList {

    /*** STORAGE ***/

    // Mapping from owner to the values
    mapping(address => uint256[]) private ownerTargetValues;
    // Mapping from owner to index of the token
    mapping(address => mapping(uint256 => uint256)) private ownerTargetValuesIndex;
    // Mapping from owner to registration status of token
    mapping(address => mapping(uint256 => bool)) private ownedStatus;

    /*** External Functions ***/
    /// @dev Aadd a id to the list of a given owner
    /// @param _owner owner of the values list
    /// @param _targetId id of the token to be added to the values list of the given owner
    function add(
        address _owner,
        uint256 _targetId
    ) public {
        require(!exists(_owner, _targetId));

        // set id
        ownerTargetValues[_owner].push(_targetId);
        ownerTargetValuesIndex[_owner][_targetId] = ownerTargetValues[_owner].length - 1;
        ownedStatus[_owner][_targetId] = true;
    }

    /// @dev Remove a ID from the list of ths specified owner
    /// @param _owner owner of the values list
    /// @param _targetId id of the token to be added to the values list of the given owner
    function remove(address _owner, uint256 _targetId) public {
        require(exists(_owner, _targetId));

        uint256 targetIndex = ownerTargetValuesIndex[_owner][_targetId];
        uint256 lastIndex = ownerTargetValues[_owner].length - 1;
        uint256 lastTargetId = ownerTargetValues[_owner][lastIndex];

        ownedStatus[_owner][_targetId] = false;
        ownerTargetValues[_owner][targetIndex] = lastTargetId;
        ownerTargetValues[_owner].pop();

        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedvalues list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list
        ownerTargetValuesIndex[_owner][lastTargetId] = targetIndex;
        ownerTargetValuesIndex[_owner][_targetId] = 0;
    }

    /// @dev Get key target ids of the specified owner
    /// @param _owner owner of the token id list
    /// @param _index index of the token to be added to the values list of the given key id
    /// @return values
    function valueOf(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerTargetValues[_owner].length);
        return ownerTargetValues[_owner][_index];
    }

    /// @dev Get address target ids of the specified owner
    /// @param _owner owner of the token id list
    /// @return specIds
    function valuesOf(address _owner) external view returns (uint256[] memory) {
        return ownerTargetValues[_owner];
    }

    /// @dev Get ids count of the specified owner
    /// @return specIds
    function totalOf(address _owner) external view returns (uint256) {
        return ownerTargetValues[_owner].length;
    }

    /// @dev Returns whether the specified owner registered
    /// @param _owner owner of the token id list
    /// @param _targetId id of the token to be added to the token id list of the given owner
    /// @return whether the token registered
    function exists(address _owner, uint256 _targetId) public view returns (bool) {
        return ownedStatus[_owner][_targetId];
    }
}
