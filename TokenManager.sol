pragma solidity 0.6.5;

import "./BaseToken.sol";
import "./Control.sol";
import "./ManagerRole.sol";
import "./OwnerLinkedIdList.sol";

import "./SafeMath.sol";
import "./Address.sol";

import "./MinterRole.sol";


contract TokenManager is Control, MinterRole, ManagerRole {
    using SafeMath for uint256;
    using Address for address;

    /*** STORAGE ***/

    // All token contract addresses
    address[] public contracts;

    // Mapping from contract address to token ID
    mapping(address => uint256) internal contractToTokenId;

    // Mapping from contract address to contract issues
    mapping (address => bool) internal contractIssues;

    // Mapping from token ID to owner
    mapping(uint256 => address) internal tokenOwner;
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokenIds;

    // Mapping from holder to token Ids
    OwnerLinkedIdList private heldTokenIdList;

    // Mapping from token ID to list of Proxies
    mapping(uint256 => address[]) internal tokenProxies;

    // Mapping from token ID to list of Non-Fungible Items
    mapping(uint256 => uint256[]) internal tokenDistributionPermissions;

    /*** CONSTRUCTOR ***/
    constructor() public {
        heldTokenIdList = new OwnerLinkedIdList();
    }

    /*** Event ***/
    event IssueLog(string _name, string _symbol, uint256 tokenId);
    event MintLog(address _to, uint256 _value, uint256 tokenId);
    event TransferLog(address _from, address _to, uint256 _value, uint256 _tokenId);
    event AddProxyLog(address _proxy, uint256 _tokenId);
    event AddPermissionLog(uint256 _tokenId, uint256 _specId);

    /*** EXTERNAL FUNCTIONS ***/
    /// @dev issue the specified token in SingulaChain.
    function issue(
        address _contractAddress,
        string memory _name,
        string memory _symbol
    ) public whenNotPaused returns (bool) {

        BaseToken token = BaseToken(_contractAddress);
        token.issue(_name, _symbol);

        contracts.push(_contractAddress);
        uint256 tokenId = contracts.length.sub(1);
        contractToTokenId[_contractAddress] = tokenId;
        ownedTokenIds[msg.sender].push(tokenId);
        tokenOwner[tokenId] = msg.sender;


        emit IssueLog(_name, _symbol, tokenId);
        return true;
    }

    /// @dev Function to mint tokens
    /// @param _to The address that will receive the minted tokens.
    /// @param _value The amount of tokens to mint.
    /// @param _tokenId  token identifer.
    /// @return A boolean that indicates if the operation was successful.
    function mint(
        address _to,
        uint256 _value,
        uint256 _tokenId
    )
        public
        onlyMinter
        whenNotPaused
        returns (bool)
    {
        require(_exists(_tokenId));
        BaseToken token = BaseToken(contracts[_tokenId]);
        token.mint(_to, _value);
        _handleTokenHolder(address(0), _to, _tokenId, _value);

        emit MintLog(_to, _value, _tokenId);
        return true;
    }

    /// @dev Transfer the specified amount of token to the specified address.
    /// @param _to    Receiver address.
    /// @param _value Amount of tokens that will be transferred.
    /// @param _tokenId  token identifer.
    function transfer(
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) public whenNotPaused returns (bool) {
        require(_exists(_tokenId));
        BaseToken token = BaseToken(contracts[_tokenId]);

        require(_value <= token.balanceOf(msg.sender));
        require(_to != address(0));

        token.transferFrom(msg.sender, _to, _value);
        _handleTokenHolder(msg.sender, _to, _tokenId, _value);

        emit TransferLog(msg.sender, _to, _value, _tokenId);
        return true;
    }

    /// @dev Transfer the specified amount of token from the specified address
    /// to the specified address.
    /// @param _from  Sender address.
    /// @param _to    Receiver address.
    /// @param _value Amount of tokens that will be transferred.
    /// @param _tokenId  token identifer.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) public whenNotPaused returns (bool) {
        require(_exists(_tokenId));
        BaseToken token = BaseToken(contracts[_tokenId]);

        require(_value <= token.balanceOf(_from));
        require(_to != address(0));

        token.transferFrom(_from, _to, _value);
        _handleTokenHolder(_from, _to, _tokenId, _value);

        emit TransferLog(_from, _to, _value, _tokenId);
        return true;
    }

    /// @dev Transfer the specified amount of token from the specified address
    /// to the specified address by proxy account.
    /// @param _from  Sender address.
    /// @param _to    Receiver address.
    /// @param _value Amount of tokens that will be transferred.
    /// @param _tokenId  token identifer.
    function transferProxy(
        address _from,
        address _to,
        uint256 _value,
        uint256 _tokenId,
        uint256 _specId
    ) public returns (bool) {
        BaseToken token = BaseToken(contracts[_tokenId]);
        require(_exists(_tokenId));
        require(_value <= token.balanceOf(_from));
        require(_to != address(0));

        uint256 k = tokenProxies[_tokenId].length;
        for (uint i = 0; i < k; i++) {
            if (tokenProxies[_tokenId][i] == msg.sender) {
                uint256 m = tokenDistributionPermissions[_tokenId].length;
                for (uint j = 0; j < m; j++) {
                    if (tokenDistributionPermissions[_tokenId][j] == _specId) {
                        token.transferFrom(_from, _to, _value);
                        _handleTokenHolder(_from, _to, _tokenId, _value);
                        emit TransferLog(_from, _to, _value, _tokenId);
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /// @dev Add a proxy account for automatic distribution
    /// @param _proxy proxy account
    /// @param _tokenId automatic distribution token
    function addProxy(
        address _proxy,
        uint256 _tokenId
    ) public  returns(bool) {
        require(tokenOwner[_tokenId] == msg.sender);
        require(_exists(_tokenId));
        tokenProxies[_tokenId].push(_proxy);

        emit AddProxyLog(_proxy, _tokenId);
        return true;
    }

    /// @dev Add a proxy account for automatic distribution
    /// @param _specId Digital content spec ID
    /// @param _tokenId automatic distribution token
    function addPermission(
        uint256 _tokenId,
        uint256	_specId
    ) public returns(bool) {
        require(tokenOwner[_tokenId] == msg.sender);
        require(_exists(_tokenId));
        tokenDistributionPermissions[_tokenId].push(_specId);

        emit AddPermissionLog(_tokenId, _specId);
        return true;
    }

    /// @dev Gets contract count.
    /// @return count of contract.
    function getContractCount() public view returns(uint256) {
        return contracts.length;
    }

    /// @dev Gets the contract address of the specified token ID
    /// @return count of contract.
    function contractOf(uint256 _tokenId) public view returns(address) {
        return contracts[_tokenId];
    }

    /// @dev get tokenId from contract address.
    /// @param _contractAddress   Contract address.
    /// @return count of contract.
    function getTokenId(address _contractAddress) public view returns(uint256) {
        require(_exists(_contractAddress));

        return contractToTokenId[_contractAddress];
    }

    /// @dev Total number of tokens in existence
    /// @param _tokenId The token Iidentifer
    function totalSupplyOf(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId));
        BaseToken token = BaseToken(contracts[_tokenId]);

        return token.totalSupply();
    }

    /// @dev Returns balance of the `_owner`.
    /// @param _tokenId The token Iidentifer
    /// @param _owner   The address whose balance will be returned.
    /// @return balance Balance of the `_owner`.
    function balanceOf(uint256 _tokenId, address _owner) public view returns (uint256) {
        require(_exists(_tokenId));
        BaseToken token = BaseToken(contracts[_tokenId]);

        return token.balanceOf(_owner);
    }

    /// @dev Gets the owner of the specified token ID
    /// @param _tokenId uint256 ID of the token to query the owner of
    /// @return holders address currently marked as the owner of the given token ID
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    /// @dev Gets the token IDs of the requested owner
    /// @param _owner address owning the objects list to be accessed
    /// @return uint256 token IDs owned by the requested address
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        return ownedTokenIds[_owner];
    }

    /// @dev Gets the token IDs of the requested owner
    /// @param _holder address holding the objects list to be accessed
    /// @return uint256 token IDs held by the requested address
    function tokensOfHolder(address _holder) public view returns (uint256[] memory) {
        return heldTokenIdList.valuesOf(_holder);
    }

    /// @dev Gets the token object of the specified token ID
    /// @param _tokenId the tokenId of the token
    /// @return tokenId the tokenId of the token
    /// @return contractAddress the contractAddress of the token
    /// @return name the name of the token
    /// @return symbol the symbol of the token
    /// @return owner the owner of the token
    /// @return totalSupply the total supply of the token
    function getTokenInfo(uint256 _tokenId) public view returns(
        uint256 tokenId,
        address contractAddress,
        string memory name,
        string memory symbol,
        address owner,
        uint256 totalSupply
    ) {
        require(_exists(_tokenId));
        BaseToken token = BaseToken(contracts[_tokenId]);

        return (
            _tokenId,
            contracts[_tokenId],
            token.nameOf(),
            token.symbolOf(),
            ownerOf(_tokenId),
            token.totalSupply()
        );
    }

    /// @dev Gets the proxy of the specified token ID
    /// @param _tokenId uint256 ID of the token to query the proxy of
    /// @return proxy address list of the given token ID
    function proxyOf(uint256 _tokenId) public view returns (address[] memory) {
        return tokenProxies[_tokenId];
    }

    /// @dev Gets the permission of the specified token ID
    /// @param _tokenId uint256 ID of the token to query the permission of
    function permissionOf(uint256 _tokenId) public view returns (uint256[] memory) {
        return tokenDistributionPermissions[_tokenId];
    }

    /*** INTERNAL FUNCTIONS ***/
    /// @dev Check if it is issued contract address
    /// @param _tokenId  token id.
    /// @return A boolean that indicates if the token exists.
    function _exists(uint256 _tokenId) internal view returns (bool) {
        if (tokenOwner[_tokenId] != address(0x0)) {
            return true;
        }
    }

    /// @dev Check if it is issued contract address
    /// @param _contractAddress  token address.
    /// @return A boolean that indicates if the token exists.
    function _exists(address _contractAddress) internal view returns (bool) {
        return contractIssues[_contractAddress];
    }

    /// @dev Internal function to add a token ID to the list of a given address
    /// @param _to address representing the new owner of the given token ID
    /// @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    function _addTokenTo(address _to, uint256 _tokenId) internal {
        require(!_isRegisteredToken(_tokenId));
        ownedTokenIds[_to].push(_tokenId);
        tokenOwner[_tokenId] = _to;
    }

    /// @dev Internal function to add a token ID to the list of a given address
    /// @param _to address representing the new owner of the given token ID
    /// @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    function _addTokenHolderTo(address _to, uint256 _tokenId) internal {
        require(!_isRegisteredTokenHolder(_to, _tokenId));
        // heldTokensIndex[_to][_tokenId] = holderToTokenIds[_to].push(_tokenId);
        heldTokenIdList.add(_to, _tokenId);
    }

    /// @dev Internal function to remove a token ID from the list of a given address
    /// @param _from address representing the previous owner of the given token ID
    /// @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    function _removeTokenHolderFrom(address _from, uint256 _tokenId) internal {
        require(_isRegisteredTokenHolder(_from, _tokenId));

        heldTokenIdList.remove(_from, _tokenId);
    }

    /// @dev Internal function to handle token holder list
    /// @param _from address representing the sender
    /// @param _to address representing the reciever
    /// @param _tokenId uint256 ID of the token to be handled
    /// @param _value uint256 amount of token to be handled
    function _handleTokenHolder(address _from, address _to, uint256 _tokenId, uint256 _value) internal {
        if (_from != address(0) && BaseToken(contracts[_tokenId]).balanceOf(_from) == 0) {
            _removeTokenHolderFrom(_from, _tokenId);
        }
        if (_to != address(0) && BaseToken(contracts[_tokenId]).balanceOf(_to) == _value) {
            _addTokenHolderTo(_to, _tokenId);
        }
    }

    /// @dev Returns whether the specified token id registered
    /// @param _tokenId  token identifer.
    /// @return whether the token registered
    function _isRegisteredToken(uint256 _tokenId) internal view returns (bool) {
        return tokenOwner[_tokenId] != address(0);
    }

    /// @dev Returns whether the specified token id registered
    /// @param _to address representing the new owner of the given token ID
    /// @param _tokenId  token identifer.
    /// @return whether the token registered
    function _isRegisteredTokenHolder(address _to, uint256 _tokenId) internal view returns (bool) {
        return heldTokenIdList.exists(_to, _tokenId);
    }

}
