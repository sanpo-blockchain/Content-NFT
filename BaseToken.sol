pragma solidity 0.6.5;

import "./SafeMath.sol";
import "./ManagerRole.sol";


contract BaseToken is ManagerRole {

    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    event IssueLog(string _name, string _symbol);
    event MintLog(address indexed to, uint256 amount);
    event TransferLog(address indexed from, address indexed to, uint256 value);

    function issue(
        string memory _name,
        string memory _symbol
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = 8;
        _totalSupply = 0;
    }

    function mint(
        address _to,
        uint256 _value
    ) external returns (bool) {
        _balances[_to] = _balances[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit MintLog(_to, _value);
        return true;
    }

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit TransferLog(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[_from]);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit TransferLog(_from, _to, _value);
        return true;
    }

    function nameOf() external view returns (string memory) {
        return name;
    }

    function symbolOf() external view returns (string memory) {
        return symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

}
