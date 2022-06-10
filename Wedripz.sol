/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "https://github.com/nickyoung92/Solidity-Contracts/blob/main/Shareholders.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract WEDRIPZ is ERC721A, Shareholders {
    using Strings for uint;
    string public _baseTokenURI = ''; //need to enter prereveal URI
    uint public maxPerPresale = 5;
    uint public maxPerMint = 5;
    uint public maxPerWallet = 25;
    uint public cost = 0.0777 ether;
    uint public presaleCost = 0.069 ether; 
    uint public maxSupply = 9999;
    bool public revealed = false;
    bool public presaleOnly = true;
    bytes32 public merkleRoot; //need to enter merkleRoot

    mapping(address => uint) public addressMintedBalance;

  constructor(
    ) ERC721A("WEDRIPZ", "DRIP")payable{
        
    }

    /*Payment Splitter
        Demarco 432
        Charity 150
        Treasury 200
        Trust Me Vodka 163
        Co-Labs: 55
        Total: 1000
    */


  function publicMint(uint256 quantity) external payable
    {
        require(presaleOnly == false);
        require(quantity <= maxPerMint, "You can't mint this many at once.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You minted as many as you can already.");
        require(msg.value >= cost * quantity, "Insufficient Funds.");
        require(tx.origin == msg.sender, "No contracts!");
        _mint(msg.sender, quantity,"",true);
        addressMintedBalance[msg.sender] += quantity;
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerPresale, "You minted as many as you can already.");
        require(msg.value >= presaleCost * quantity, "Insufficient Funds.");
        require(tx.origin == msg.sender, "No contracts!");
        _mint(msg.sender, quantity,"",true);
        addressMintedBalance[msg.sender] += quantity;    
    }

    

    

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }    

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        string memory currentBaseURI = _baseURI();
        if(revealed == true) {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
        } else {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI))
            : "";
        } 
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setPresaleOnly(bool _state) external onlyOwner {
        presaleOnly = _state;
    }

    function reveal(bool _state, string memory baseURI) external onlyOwner {
        revealed = _state;
        _baseTokenURI = baseURI;
    }

}
