// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract Incentive is OwnableUpgradeable{
    bytes32 public DOMAIN_SEPARATOR;
    uint256 public nodeNum;
    mapping(address => uint256) nodeAddrIndex;
    mapping(uint256 => address) public nodeIndexAddr;
    mapping(address => bool) public nodeAddrSta;
    bool public pause;
    mapping(address => uint256) public nonce;
    mapping(address => mapping(uint256 => uint256)) public withdrawAmounts;

    event AddNodeAddr(address[] nodeAddrs);
    event DeleteNodeAddr(address[] nodeAddrs);
    event WithdrawToken(address indexed _userAddr, uint256 _nonce, address _tokenAddr, uint256 _amount);

    struct Data {
        address userAddr;
        address contractAddr;
        uint256 amount;
        uint256 expiration;
    }

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    modifier onlyGuard() {
        require(!pause, "IncentiveContracts: The system is suspended");
        _;
    }

    function initialize(address[] calldata _nodeAddrs) external initializer(){
        __Ownable_init_unchained();
        __Incentive_init_unchained(_nodeAddrs);
    }

    function __Incentive_init_unchained(address[] calldata _nodeAddrs) internal onlyInitializing() {
        _addNodeAddr(_nodeAddrs);
        uint chainId;
        assembly {
            chainId := chainId
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(uint256 chainId,address verifyingContract)'),
                chainId,
                address(this)
            )
        );
    }

    receive() payable external{

    }

    function  updatePause(bool _sta) external onlyOwner{
        pause = _sta;
    }

    function addNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        _addNodeAddr(_nodeAddrs);
    }

    function deleteNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(nodeAddrSta[_nodeAddr], "This node is not a pledge node");
            nodeAddrSta[_nodeAddr] = false;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex > 0){
                uint256 _nodeNum = nodeNum;
                address _lastNodeAddr = nodeIndexAddr[_nodeNum];
                nodeAddrIndex[_lastNodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _lastNodeAddr;
                nodeAddrIndex[_nodeAddr] = 0;
                nodeIndexAddr[_nodeNum] = address(0x0);
                nodeNum--;
            }
        }
        emit DeleteNodeAddr(_nodeAddrs);
    }

     function withdrawToken(
        address[2] calldata addrs,
        uint256[2] calldata uints,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    )
        external
        onlyGuard
    {
        require(addrs[0] == msg.sender, "IncentiveContracts: Signing users are not the same as trading users");
        require( block.timestamp<= uints[1], "IncentiveContracts: The transaction exceeded the time limit");
        uint256 len = vs.length;
        uint256 counter;
        uint256 _nonce = nonce[addrs[0]]++;
        require(len*2 == rssMetadata.length, "IncentiveContracts: Signature parameter length mismatch");
        bytes32 digest = getDigest(Data( addrs[0], addrs[1], uints[0], uints[1]), _nonce);
        for (uint256 i = 0; i < len; i++) {
            bool result = verifySign(
                digest,
                Sig(vs[i], rssMetadata[i*2], rssMetadata[i*2+1])
            );
            if (result){
                counter++;
            }
            if (counter > nodeNum/2){
                break;
            }
        }
        require(
            counter > nodeNum/2,
            "The number of signed accounts did not reach the minimum threshold"
        );
        withdrawAmounts[addrs[0]][_nonce] =  uints[0];
        IERC20 token = IERC20(addrs[1]);
        require(
            token.transfer(addrs[0],uints[0]),
            "Token transfer failed"
        );
        emit WithdrawToken(addrs[0], _nonce, addrs[1], uints[0]);
    }

    function queryNodes() external view returns(address[] memory){
        address[] memory nodes = new address[](nodeNum);
        for (uint256 i = 1; i <= nodeNum; i++) {
            nodes[i-1] = nodeIndexAddr[i];
        }
        return nodes;
    }

    function _addNodeAddr(address[] calldata _nodeAddrs) internal{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(!nodeAddrSta[_nodeAddr], "This node is already a node address");
            nodeAddrSta[_nodeAddr] = true;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex == 0){
                _nodeAddrIndex = ++nodeNum;
                nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
            }
        }
        emit AddNodeAddr(_nodeAddrs);
    }

    function verifySign(bytes32 _digest,Sig memory _sig) internal view returns (bool)  {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _digest));
        address _accessAccount = ecrecover(hash, _sig.v, _sig.r, _sig.s);
        return nodeAddrSta[_accessAccount];
    }

    function getDigest(Data memory _data, uint256 _nonce) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(_data.userAddr, _data.contractAddr,  _data.amount, _data.expiration, _nonce))
            )
        );
    }
}

