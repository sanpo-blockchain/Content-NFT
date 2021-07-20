pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./DigitalContentSpec.sol";
import "./SafeMath.sol";

/// @title RightsDigitalConentObject

contract DigitalContentObject is DigitalContentSpec {
    using SafeMath for uint;

    /*** DATA TYPES ***/
    struct DigitalContentObject {
        uint256 specId; // content spec id
        string mediaId; // media file id
        string info; //content's additional information
    }

    /*** STORAGE ***/
    DigitalContentObject[] private digitalContentObjects; // all object list (this index is objectId)

    // Mapping from object ID to owner
    mapping (uint256 => address) private _objectOwner;

    // Mapping from object ID to approved address
    mapping (uint256 => address) private _objectApprovals;

    // Mapping from owner to list of owned object IDs
    mapping(address => uint256[]) private _ownedObjects;

    // Mapping from owner to number of owned object
    mapping (address => uint256) private _ownedObjectsCount;

    // Mapping from spec ID to index of the minted objects list
    mapping(uint256 => uint256[]) private mintedObjects;

    // Mapping from object id to position in the minted objects array
    mapping(uint256 => uint256) private mintedObjectsIndex;

    // Array with all object ids, used for enumeration
    uint256[] private _allObjects;

    /*** Event ***/
    event MintLog(
        address owner,
        uint256 objectId,
        string mediaId,
        string info,
        uint256 specId
    );

    event SetMediaIdLog(
        address owner,
        uint256 objectId,
        string mediaId
    );

    event TransferLog(
        address from,
        address to,
        uint256 objectId
    );

    event ApprovalLog(
        address owner,
        address to,
        uint256 objectId
    );

    event SetInfoLog(
        address owner,
        uint256 objectId,
        string info
    );

    /*** EXTERNAL FUNCTIONS ***/
    /**
    * @dev Mint a DigitalContent.
    * @param _to The address that will own the minted object
    * @param _specId spec identifer
    * @param _mediaId mediaId
    * @param _info info
    */
    function mint(
        address _to,
        uint256 _specId,
        string memory _mediaId,
        string memory _info
    ) public whenNotPaused {
        require(specOwnerOf(_specId) == msg.sender);

        // check total supply count
        require(
            totalSupplyLimitOf(_specId) >= mintedObjects[_specId].length
            || totalSupplyLimitOf(_specId) == 0
        );

        require(
            keccak256(abi.encodePacked(_mediaId)) == keccak256(abi.encodePacked(mediaIdOf(_specId)))
        );

        DigitalContentObject memory digitalContentObject = DigitalContentObject({
            specId : _specId,
            mediaId: _mediaId,
            info: _info
        });

        digitalContentObjects.push(digitalContentObject);
        uint256 objectId = digitalContentObjects.length.sub(1);
        _mint(_to, objectId);
        _addObjectTo(_specId, objectId);

        emit MintLog(
            _to,
            objectId,
            _mediaId,
            _info,
            digitalContentObject.specId
        );
    }

    /**
    * @dev Set MediaId
    * @param _objectId object identifer
    * @param _mediaId mediaId
    */
    function setMediaId(uint256 _objectId, string memory _mediaId) public whenNotPaused {
        require(_objectExists(_objectId));
        DigitalContentObject storage digitalContent = digitalContentObjects[_objectId];

        require(specOwnerOf(digitalContent.specId) == msg.sender);
        require(keccak256(abi.encodePacked(digitalContent.mediaId)) == keccak256(abi.encodePacked("")));

        // set mediaId
        digitalContent.mediaId = _mediaId;

        emit SetMediaIdLog(msg.sender, _objectId, digitalContent.mediaId);
    }

    function setInfo(uint256 _objectId, string memory _info) public whenNotPaused {
        require(_objectExists(_objectId));
        DigitalContentObject storage digitalContent = digitalContentObjects[_objectId];

        require(objectOwnerOf(_objectId) == msg.sender);

        // set
        digitalContent.info = _info;

        emit SetInfoLog(msg.sender, _objectId, digitalContent.info);
    }

    /**
    * @dev Get DigitalContent.
    * @param _objectId object identifer
    * @return objectId object id
    * @return specId spec id
    * @return mediaId media id
    * @return info info
    * @return owner owner address
    * @return objectIndex object index
    */
    function getDigitalContentObject(uint256 _objectId) public view returns (
        uint256 objectId,
        uint256 specId,
        string memory mediaId,
        string memory info,
        address owner,
        uint256 objectIndex
    ) {
        require(_objectExists(_objectId));
        DigitalContentObject storage digitalContent = digitalContentObjects[_objectId];
        address objectOwner = objectOwnerOf(_objectId);

        return (
            _objectId,
            digitalContent.specId,
            digitalContent.mediaId,
            digitalContent.info,
            objectOwner,
            mintedObjectsIndex[_objectId]
        );
    }

    /**
    * @dev Get specId of DigitalContent.
    * @param _objectId object identifer
    * @return specId
    */
    function specIdOf(uint256 _objectId) public view returns (uint256) {
        require(_objectExists(_objectId));
        return digitalContentObjects[_objectId].specId;
    }

    /**
    * @dev Get mediaId of DigitalContent.
    * @param _objectId object identifer
    * @return mediaId
    */
    function objectMediaIdOf(uint256 _objectId) public view returns (string memory) {
        require(_objectExists(_objectId));
        return digitalContentObjects[_objectId].mediaId;
    }

    /**
    * @dev Get info of DigitalContent.
    * @param _objectId object identifer
    * @return info
    */
    function objectInfoOf(uint256 _objectId) public view returns (string memory) {
        require(_objectExists(_objectId));
        return digitalContentObjects[_objectId].info;
    }

    /**
    * @dev Gets the total amount of objects stored by the contract per spec
    * @param _specId spec identifer
    * @return uint256 representing the total amount of objects per spec
    */
    function totalSupplyOf(uint256 _specId) public view returns (uint256) {
        require(specOwnerOf(_specId) != address(0));
        return mintedObjects[_specId].length;
    }

     /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function objectBalanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedObjectsCount[owner];
    }

    /**
    * @dev Get objectIndex of DigitalContent.
    * @param _objectId object identifer
    * @return objectIndex
    */
    function objectIndexOf(uint256 _objectId) public view returns (uint256) {
        require(_objectExists(_objectId));
        return mintedObjectsIndex[_objectId];
    }

    /**
     * @dev Gets the owner of the specified object ID.
     * @param _objectId uint256 ID of the object to query the owner of
     * @return address currently marked as the owner of the given object ID
     */
    function objectOwnerOf(uint256 _objectId) public view returns (address) {
        address owner = _objectOwner[_objectId];
        require(owner != address(0), "ERC721: owner query for nonexistent object");

        return owner;
    }

    /**
     * @dev Transfers the ownership of a given object ID to another address.
     * @param _to address to receive the ownership of the given object ID
     * @param _objectId uint256 ID of the object to be transferred
     */
    function transfer(address _to, uint256 _objectId) public {

        _transfer(msg.sender, _to, _objectId);
    }

    /**
     * @dev Transfers the ownership of a given object ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param _from current owner of the object
     * @param _to address to receive the ownership of the given object ID
     * @param _objectId uint256 ID of the object to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _objectId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, _objectId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(_from, _to, _objectId);
    }

    /**
     * @dev Approves another address to transfer the given object ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per object at a given time.
     * Can only be called by the object owner or an approved operator.
     * @param to address to be approved for the given object ID
     * @param _objectId uint256 ID of the object to be approved
     */
    function approve(address to, uint256 _objectId) public {
        address owner = objectOwnerOf(_objectId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner,
            "ERC721: approve caller is not owner nor approved for all"
        );

        _objectApprovals[_objectId] = to;
        emit ApprovalLog(owner, to, _objectId);
    }

    /**
     * @dev Gets the approved address for a object ID, or zero if no address set
     * Reverts if the object ID does not exist.
     * @param _objectId uint256 ID of the object to query the approval of
     * @return address currently approved for the given object ID
     */
    function getApproved(uint256 _objectId) public view returns (address) {
        require(_objectExists(_objectId), "ERC721: approved query for nonexistent object");

        return _objectApprovals[_objectId];
    }

    /*** INTERNAL FUNCTIONS ***/
    /**
     * @dev Internal function to mint a new object.
     * Reverts if the given object ID already exists.
     * @param _to address the beneficiary that will own the minted object
     * @param _objectId uint256 ID of the object to be minted
     */
    function _mint(address _to, uint256 _objectId) internal {

        _ownedObjects[_to].push(_objectId);
        _objectOwner[_objectId] = _to;
        _ownedObjectsCount[_to] += 1;

    }

    /**
    * @dev Internal function to add a object ID to the list of the spec
    * @param _specId uint256 ID of the spec
    * @param _objectId uint256 ID of the object to be added to the objects list of the given address
    */
    function _addObjectTo(uint256 _specId, uint256 _objectId) internal {
        mintedObjects[_specId].push(_objectId);
        mintedObjectsIndex[_objectId] = mintedObjects[_specId].length;
    }

    /**
     * @dev Internal function to transfer ownership of a given object ID to another address.
     * @param _to address to receive the ownership of the given object ID
     * @param _objectId uint256 ID of the object to be transferred
     */
    function _transfer(address _sender, address _to, uint256 _objectId) internal {
        require(objectOwnerOf(_objectId) == _sender, "ERC721: transfer of object that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(_objectId);

        _ownedObjectsCount[_sender] -= 1;
        _ownedObjectsCount[_to] += 1;

        _objectOwner[_objectId] = _to;

        emit TransferLog(_sender, _to, _objectId);
    }

    /**
     * @dev Internal function to transfer ownership of a given object ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param _from current owner of the object
     * @param _to address to receive the ownership of the given object ID
     * @param _objectId uint256 ID of the object to be transferred
     */
    function _transferFrom(address _from, address _to, uint256 _objectId) internal {
        require(objectOwnerOf(_objectId) == _from, "ERC721: transfer of object that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(_objectId);

        _ownedObjectsCount[_from] -= 1;
        _ownedObjectsCount[_to] += 1;

        _objectOwner[_objectId] = _to;

        emit TransferLog(_from, _to, _objectId);
    }

    /**
     * @dev Returns whether the given spender can transfer a given object ID.
     * @param _spender address of the spender to query
     * @param _objectId uint256 ID of the object to be transferred
     * @return bool whether the msg.sender is approved for the given object ID,
     * is an operator of the owner, or is the owner of the object
     */
    function _isApprovedOrOwner(address _spender, uint256 _objectId) internal view returns (bool) {
        require(_objectExists(_objectId), "ERC721: operator query for nonexistent object");
        address owner = objectOwnerOf(_objectId);
        return (_spender == owner || getApproved(_objectId) == _spender);
    }

    /**
     * @dev Private function to confirm exist of a agiven object ID.
     * @param _objectId uint256 ID of the object
     */
    function _objectExists(uint256 _objectId) internal view returns (bool) {
        if (objectOwnerOf(_objectId) != address(0)) {
            return true;
        }
    }

    /**
     * @dev Private function to clear current approval of a given object ID.
     * @param _objectId uint256 ID of the object to be transferred
     */
    function _clearApproval(uint256 _objectId) private {
        if (_objectApprovals[_objectId] != address(0)) {
            _objectApprovals[_objectId] = address(0);
        }
    }


}
