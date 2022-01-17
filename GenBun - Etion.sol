// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract GenBunEtion is Ownable, ERC721Burnable, ERC721Pausable, ERC721Enumerable{
    //using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenCounter; // the counter for NFT supply

    IERC20 public token; // interface of ERC20 WETH

    string private _baseTokenUri;
    string public placeholder;

    uint256 public maxGenBun = 1777;
    uint256 public maxWhitelistSale = 50;
    uint256 public maxAirdrop = 50;
    uint256 public genBunPrice = 1 * 10 ** 16;
    uint256 public genBunPriceWhitelist = 8 * 10 ** 15;
    uint256 public mintTimeout = 300;
    uint256 public whitelistSaleEnd;

    bool public publicSale = false;
    bool public airdropStatus = false;
    bool public isRevealed = false;
    
    address financeAddress = 0x79E9412e42585606481C3c451B891Bdf2af17e94;
    // address financeAddress = 0xe17D01db63fCe85918656663E352564c8513b856; 
    address private signer;
    address[] public whitelist;
    address[] public airdropList;

    mapping(address => uint256) public lastMintedTime;
    mapping(address => bool) public isWhitelisted;

    event mintGenBun(uint256 indexed id, address minter);

    constructor(string memory baseUri, address _signer, IERC20 _token) ERC721("GenBun: Etion", "GENBUN-E"){
        setBaseUri(baseUri);
        pause(true);
        signer = _signer;
        token = _token;
    }

    //returns the total supply of NFT
    // function totalSupply() public view returns(uint){
    //     return _tokenCounter.current();
    // }
    
    //returns the base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!isRevealed){
            return placeholder;
        }
        //string memory baseURI = _baseURI();
        return bytes(_baseTokenUri).length > 0 ? string(abi.encodePacked(_baseTokenUri, tokenId.toString())) : "";
    }

    //returns the last time that the user minted in unix timestamp
    function getLastMintedTime()public view returns(uint256){
        return lastMintedTime[msg.sender];
    }

    //returns if the user is whitelisted or not
    function getWhitelist() public view returns(bool){
        return isWhitelisted[msg.sender];
    }

    function setRevealed(bool _isRevealed)public onlyOwner{
        isRevealed = _isRevealed;
        return;
    }

    //sets the the signer that is used for minting
    function setSigner(address _signer)public onlyOwner{
        signer = _signer;
        return;
    }

    function setPublicSale(bool _publicSale)public onlyOwner{
        publicSale = _publicSale;
        return;
    }

    function setWhitelistSaleEnd(uint256 _whitelistSaleEnd)public onlyOwner{
        whitelistSaleEnd = _whitelistSaleEnd;
        return;
    }

    //sets the address for whitelist
    function setWhitelist(address[] memory _whitelist) public{
        for(uint256 index=0; index < _whitelist.length; index++){
            isWhitelisted[_whitelist[index]] = true;
        }
        return;
    }

    function setAirdropAddress(address[] memory _airdropList) public onlyOwner{
        for(uint256 index=0; index < _airdropList.length; index++){
            airdropList.push(_airdropList[index]);
        }
    } 

    function executeAirDrop()public onlyOwner{
        require(!airdropStatus, "GenBun: Airdop already done!");
        for(uint256 index=0; index < airdropList.length; index++){
            _safeMint(airdropList[index], totalSupply());
            //_tokenCounter.increment();
        }
        airdropStatus = true;
        return;
    }

    //function for minting an NFT
    function mint(uint256 payment) public{
        require(totalSupply() <= 1777, "GenBun: Quantity of minting exceeds public sale!"); // ensures that minting will not exceed max number of NFT.
        require(payment >= (genBunPrice), "GenBun: Payment is below the Price!"); // ensures that the price given is not less than the set minting price.

        if(lastMintedTime[msg.sender] == 0){ // this is for those who are first time minting.
            lastMintedTime[msg.sender] = block.timestamp;

            token.transferFrom(msg.sender, financeAddress, payment);
            //_mintAGenBun(msg.sender, _tokenCounter.current());
            _safeMint(msg.sender, totalSupply());
            //_tokenCounter.increment();
            return;
        }
        
        uint256 timeDiff = block.timestamp - lastMintedTime[msg.sender];
        require(timeDiff > mintTimeout, "GenBun: Mint still on timeout!"); //ensures that the user can only mint for every 5 minutes

        token.transferFrom(msg.sender, financeAddress, payment);
        _safeMint(msg.sender, totalSupply());
        //_tokenCounter.increment();
        return;
    }

    function whitelistMint(uint256 payment) public{
        require(!publicSale, "GenBun: Whitelist sale has ended!");
        require(isWhitelisted[msg.sender], "GenBun: Address not whitelisted!");
        require(totalSupply() < 1777, "GenBun: Quantity of minting exceeds public sale!"); // ensures that minting will not exceed max number of NFT.
        require(payment >= (genBunPriceWhitelist), "GenBun: Payment is below the Price!"); // ensures that the price given is not less than the set minting price.

        if(lastMintedTime[msg.sender] == 0){ // this is for those who are first time minting.
            lastMintedTime[msg.sender] = block.timestamp;

            token.transferFrom(msg.sender, financeAddress, payment);
            //_mintAGenBun(msg.sender, _tokenCounter.current());
            _safeMint(msg.sender, totalSupply());
            //_tokenCounter.increment();
            return;
        }

        uint256 timeDiff = block.timestamp - lastMintedTime[msg.sender];
        require(timeDiff > mintTimeout, "GenBun: Mint still on timeout!"); //ensures that the user can only mint for every 5 minutes

        token.transferFrom(msg.sender, financeAddress, payment);
        _safeMint(msg.sender, totalSupply());
        //_tokenCounter.increment();
        
    }

    //sets the base URI for the NFT metadata.
    function setBaseUri(string memory baseUri) public onlyOwner{
        _baseTokenUri = baseUri;
    }

    //flip switch for minting of NFT.
    function pause(bool isPaused)public onlyOwner{
        if(isPaused == true){
            _pause();
            return;
        }
        
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}