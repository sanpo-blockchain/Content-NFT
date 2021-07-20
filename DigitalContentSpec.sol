pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Control.sol";
import "./ManagerRole.sol";


contract DigitalContentSpec is Control, ManagerRole {
    using SafeMath for uint;

    /*** DATA TYPES ***/
    struct DigitalContentSpec {
        string name; // content name
        string symbol; // content symbol
        uint256 contentType; // content type
        string mediaId; // media file id
        uint256 totalSupplyLimit; // object's total supply (0 = no limit)
        string info; // additional information by content
        uint256[] originalSpecIds;// when this spec is based on the other spec(copy right)
        string[] contractDocuments; // contract documents: URI or text
        uint256[] copyrightFeeRatio; // copyright fee ratio of each spec
        bool allowSecondaryMerket; // permission of secondary market sale

    }

    /*** STORAGE ***/
    DigitalContentSpec[] private digitalContentSpecs; //all spec list (this index is specId)
    mapping (uint256 => address) private _specOwner;
    mapping (address => mapping(uint256 => uint256)) _ownedSpecs; // owner , Sirial Number , specId
    mapping (address => uint256) private _ownedSpecsCount;
    mapping (address => uint256) private _ownedSpecsAccumulation; //Considering copyRighttransfer
    mapping (uint256 => address[]) private _pastSpecOwners;

    /*** Event ***/
    event DesignLog(
        address _msgSender,
        string _name,
        string _symbol,
        uint256 _contentType,
        string _mediaId,
        uint256 _totalSupplyLimit,
        string _info,
        uint256[] _originalSpecIds,
        string[] _contractDocuments,
        uint256[] _copyrightFeeRatio,
        bool _allowSecondaryMerket,
        uint256 _specId
    );
    
    event UpdateAllowSecondaryMerketLog(
        address _msgSender,
        bool _allowSecondaryMerket,
        uint256 _specId
    );

    // uint256 copyrightFeeRatio; //Abolished

    // event SetCopyrightFeeRatioLog(
    //     address _msgSender,
    //     uint256 copyrightFeeRatio
    // );

    /*** EXTERNAL FUNCTIONS ***/
    /// @dev Define a DigitalContentSpec.
    /// @param _name contentName
    /// @param _symbol contentSymbol
    /// @param _mediaId mediaId
    /// @param _totalSupplyLimit totalSupplyLimit
    /// @param _info additional infomation by content
    /// @param _contractDocuments contract documents
    /// @param _copyrightFeeRatio copyright fee ratio
    /// @param _allowSecondaryMerket permission of secondary market
    function design(
        string memory _name,
        string memory _symbol,
        uint256 _contentType,
        string memory _mediaId,
        uint256 _totalSupplyLimit,
        string memory _info,
        uint256[] memory _originalSpecIds,
        string[] memory _contractDocuments,
        uint256[] memory _copyrightFeeRatio,
        bool _allowSecondaryMerket
    ) public whenNotPaused {
        DigitalContentSpec memory digitalContent = DigitalContentSpec({
            name : _name,
            symbol: _symbol,
            contentType: _contentType,
            mediaId: _mediaId,
            totalSupplyLimit: _totalSupplyLimit,
            info: _info,
            originalSpecIds: _originalSpecIds,
            contractDocuments: _contractDocuments,
            copyrightFeeRatio: _copyrightFeeRatio,
            allowSecondaryMerket: _allowSecondaryMerket
        });

        digitalContentSpecs.push(digitalContent);
        uint256 specId = digitalContentSpecs.length.sub(1);
        _specOwner[specId] = msg.sender;

        uint256 len = _ownedSpecsAccumulation[msg.sender];
        _ownedSpecs[msg.sender][len] = specId;


        _ownedSpecsCount[msg.sender] += 1;
        _ownedSpecsAccumulation[msg.sender] += 1;


        emit DesignLog(
            msg.sender,
            _name,
            _symbol,
            _contentType,
            _mediaId,
            _totalSupplyLimit,
            _info,
            _originalSpecIds,
            _contractDocuments,
            _copyrightFeeRatio,
            _allowSecondaryMerket,
            specId
        );
    }


    /// @dev Update Secondary Market Permission
    /// @param _specId spec identifer
    /// @param _allowSecondaryMerket  permission
    function updateSecondaryMarketPermission(uint256 _specId, bool _allowSecondaryMerket) public {
        require(msg.sender == _specOwner[_specId], "a wrong owner");
        require(_specExists(_specId));
        digitalContentSpecs[_specId].allowSecondaryMerket = _allowSecondaryMerket;
        
        emit UpdateAllowSecondaryMerketLog(
            msg.sender,
            _allowSecondaryMerket,
            _specId
        );
    }

    /// @dev Define the Copyright Ratio.　 //Abolished
    //function setCopyrightFeeRatio(uint256 _copyrightFeeRatio) public onlyManager {
    //
    //    copyrightFeeRatio = _copyrightFeeRatio;
    //
    //    emit SetCopyrightFeeRatioLog(msg.sender, _copyrightFeeRatio);
    //}

    /// @dev Update DigitalContentSpec Owner.
    /// @param _specId spec identifer
    /// @param _to New owner address
    function copyrightTransfer(uint256 _specId, address _to) public {
        require(msg.sender == _specOwner[_specId], "a wrong owner");
        _specOwner[_specId] = _to;

        uint256 len = _ownedSpecsAccumulation[msg.sender];
        for (uint128 i = 0; i < len; i++) {
            if (_ownedSpecs[msg.sender][i] == _specId) {
                _ownedSpecs[msg.sender][i] = 0;
            }
        }

        uint256 len2 = _ownedSpecsCount[_to];
        _ownedSpecs[_to][len2] = _specId;


        _ownedSpecsCount[msg.sender] -= 1;
        _ownedSpecsCount[_to] += 1;
        _ownedSpecsAccumulation[_to] += 1;
        _pastSpecOwners[_specId].push(msg.sender);

    }

    /// @dev Get DigitalContentSpec info.
    /// @param _specId spec identifer
    /// @return specId spec id
    /// @return name spec name
    /// @return symbol spec symbol
    /// @return contentType content type
    /// @return mediaId media id
    /// @return totalSupplyLimit total supply limit
    /// @return info spec info
    /// @return originalSpecIds Original SpecId
    /// @return contractDocuments Contract Documents
    /// @return copyrightFeeRatio
    /// @return allowSecondaryMerket
    /// @return owner owner address
    function getDigitalContentSpec(uint256 _specId) public view returns (
        uint256 specId,
        string memory name,
        string memory symbol,
        uint256 contentType,
        string memory mediaId,
        uint256 totalSupplyLimit,
        string memory info,
        uint256[] memory originalSpecIds,
        string[] memory contractDocuments,
        uint256[] memory copyrightFeeRatio,
        bool allowSecondaryMerket,
        address owner
        
    ) {
        require(_specId < digitalContentSpecs.length);
        DigitalContentSpec storage digitalContentSpec = digitalContentSpecs[_specId];
        address specOwner = specOwnerOf(_specId);

        return (
            _specId,
            digitalContentSpec.name,
            digitalContentSpec.symbol,
            digitalContentSpec.contentType,
            digitalContentSpec.mediaId,
            digitalContentSpec.totalSupplyLimit,
            digitalContentSpec.info,
            digitalContentSpec.originalSpecIds,
            digitalContentSpec.contractDocuments,
            digitalContentSpec.copyrightFeeRatio,
            digitalContentSpec.allowSecondaryMerket,
            specOwner
        );
    }

    /// @dev Get Copyright Ratio. ////Abolished
    /// @return copyrightFeeRatio
    //function getCopyrightFeeRatio() public view returns (uint) {
    //    return copyrightFeeRatio;
    //}

    /// @dev Get name of DigitalContentSpec.
    /// @param _specId spec identifer
    /// @return name
    function nameOf(uint256 _specId) public view returns (string memory) {
        require(_specExists(_specId));
        return digitalContentSpecs[_specId].name;
    }

    /// @dev Get symbol of DigitalContentSpec.
    /// @param _specId spec identifer
    /// @return symbol
    function symbolOf(uint256 _specId) public view returns (string memory) {
        require(_specExists(_specId));
        return digitalContentSpecs[_specId].symbol;
    }

    /// @dev Get contentType of DigitalContentSpec.
    /// @param _specId spec identifer
    /// @return contentType
    function contentTypeOf(uint256 _specId) public view returns (uint256) {
        require(_specExists(_specId));
        return digitalContentSpecs[_specId].contentType;
    }

    /// @dev Get mediaId of DigitalContentSpec.
    /// @param _specId spec identifer
    /// @return mediaId
    function mediaIdOf(uint256 _specId) public view returns (string memory) {
        require(_specExists(_specId));
        return digitalContentSpecs[_specId].mediaId;
    }

    /// @dev Get totalSupplyLimit of DigitalContentSpec.
    /// @param _specId spec identifer
    /// @return totalSupplyLimit
    function totalSupplyLimitOf(uint256 _specId) public view returns (uint256) {
        require(_specExists(_specId));
        return digitalContentSpecs[_specId].totalSupplyLimit;
    }

    /// @dev Get info of DigitalContentSpec.
    /// @param _specId spec identifer
    /// @return info
    function infoOf(uint256 _specId) public view returns (string memory) {
        require(_specExists(_specId));
        return digitalContentSpecs[_specId].info;
    }

    /// @dev Get balance of DigitalContentSpec of a given owner.
    /// @param _owner spec owner
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return _ownedSpecsCount[_owner];
    }

    /// @dev Get owner of a given sepc ID.
    /// @param _specId spec ID
    function specOwnerOf(uint256 _specId) public view returns (address) {
        address owner = _specOwner[_specId];
        require(owner != address(0));
        require(_specId != 0);
        return owner;
    }

    /// @dev Get owner of a given sepc ID.
    /// @param _specId spec ID
    function originalSpecIdsOf(uint256 _specId) public view returns (uint256[] memory) {
        require(_specExists(_specId));
        return digitalContentSpecs[_specId].originalSpecIds;
    }

    /// @dev Get sepc IDs  of a given owner.
    /// @param _owner  owner of  a given spec
    function ownedSpecs(address _owner) public view returns(uint256[] memory) {
        require(_owner != address(0));

        uint256 len = _ownedSpecsAccumulation[_owner];
        uint256[] memory ret = new uint[](_ownedSpecsCount[_owner]);
        uint256 t = 0;

        for (uint256 i = 0; i < len; i++) {
            if (_ownedSpecs[_owner][i] != 0) {
                ret[t] = _ownedSpecs[_owner][i];
                t += 1;
            }
        }
        return ret;
    }

    /// @dev Get past owners of a given sepc ID.
    /// @param _specId spec ID
    function pastOwnersOf(uint256 _specId) public view returns (address[] memory) {
        require(_specExists(_specId));
        return _pastSpecOwners[_specId];

    }

    /*** INTERNAL FUNCTIONS ***/
    function _specExists(uint256 _id) internal view returns (bool) {
        if (_specOwner[_id] != address(0x0)) {
            return true;
        }
    }

}
