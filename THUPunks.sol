//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
* 限量发售，分为presale和public sale，价格分别是0.06TETH和0.1TETH
* 预售每个账户最多买2个，公售每个账户每笔交易最多买3个、总量不限
*/
contract ThuPunk is ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    /// 静态变量
    address payable contractOwner;
    uint256 public constant thuPunkPrice_pub = 100000000000000000; //0.1 TETH
    uint256 public constant thuPunkPrice_pre = 60000000000000000;   //0.06 TETH
    uint public constant maxPunkPurchase_pre = 2;
    uint public constant maxPunkPurchase_public_singleTx = 3;
    uint256 public MAX_PUNKS = 10000;
    uint256 public MAX_WHITELIST = 1000;
    uint256 internal RESERVE_PUNKS = 30;

    ///白名单
    mapping(address => bool) whitelist;

    ///状态变量
    uint256 whiteListNum = 0;
    uint256 totalNum = 0;
    mapping(address => uint256) _balances;
    bool public presaleIsActive = false;
    bool public pubFlag = false; //防止公售在预售之前被误触
    bool public pubsaleIsActive = false;

    
    

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        contractOwner = payable(msg.sender);
    }

    /// 合约管理者获得所有资金
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        contractOwner.transfer(balance);
    }

    /// 增添白名单成员
    function addWhitelist(address wlAddress) public onlyOwner {
        require(whiteListNum + 1 <= MAX_WHITELIST);
        whiteListNum += 1;
        whitelist[wlAddress] = true;
    }

    /// 预留部分thupunks给社区贡献者
    function reservePunks() public onlyOwner {        
        uint supply = totalNum;
        uint i;
        for (i = 0; i < RESERVE_PUNKS; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

   
    
    // 反转presaleIsActive和pubsaleIsActive的状态
    function flipPrealeState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
        pubFlag = true;
    }

    function flipPublicSaleState() public onlyOwner {
        require(pubFlag = true, "Presale should be opened before public Sale");
        pubsaleIsActive = !pubsaleIsActive;
    }

    // 预售
    function premintPunk(uint numberOfTokens) public payable {
        require(presaleIsActive, "Presale is not open");
        require(whitelist[msg.sender], "Sorry, You are not qualified with the presale");
        require(_balances[msg.sender] + numberOfTokens <= maxPunkPurchase_pre, "Sorry, You can only mint 2 THUPunks");
        require(thuPunkPrice_pre.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            if (totalNum < MAX_PUNKS) {
                totalNum += 1;
                uint256 mintIndex = totalNum;
                _safeMint(msg.sender, mintIndex);
                _balances[msg.sender] += 1;
            }
        }

    }

    // 公售
    function pubmintPunk(uint numberOfTokens) public payable {
        require(pubsaleIsActive, "Public sale is not open");
        require(numberOfTokens <= maxPunkPurchase_public_singleTx, "Sorry, You can only mint 3 THUPunks at a time");
        require(thuPunkPrice_pub.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            if (totalNum < MAX_PUNKS) {
                totalNum += 1;
                uint256 mintIndex = totalNum;
                _safeMint(msg.sender, mintIndex);
                _balances[msg.sender] += 1;
            }
        }
    }

}
