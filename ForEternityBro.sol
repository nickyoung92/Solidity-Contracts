/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "https://github.com/nickyoung92/Solidity-Contracts/blob/main/Shareholders.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTContract is ERC721A, Shareholders {
    IERC721 public genesisContract = ERC721A(0x14C82e83490fE667cdDA3C31b3b9DB090899f87d); //mainnet address 0x14C82e83490fE667cdDA3C31b3b9DB090899f87d
    IERC721 public mainContract = ERC721A(0xA3332d74bBF2a4B93d2Cac74A5573e105aE268C4); //mainnet address 0xA3332d74bBF2a4B93d2Cac74A5573e105aE268C4
    using Strings for uint;
    string public _baseTokenURI;
    uint public maxPerPresaleMint = 2;
    uint public maxPerMint = 3;
    uint public maxPerWallet = 6;
    uint public cost = 0.0 ether; //0.05
    uint public mainClaimPrice = 0.0 ether; //0.02
    uint public presaleCost = 0.0 ether; //0.05
    uint public maxSupply = 10;  //10000
    uint public unclaimedGenesis = 3; //2898
    uint public unclaimedMain = 4; //4101
    bool public revealed = false;
    bool public presaleOnly = true;
    bool public claimActive = true;
    bytes32 public merkleRoot;

    mapping(uint => bool) public claimedGenesis;
    mapping(uint => bool) public claimedMain;
    mapping(address => uint) public addressMintedBalance;

  constructor(
      string memory name_,
      string memory symbol_,
      string memory baseUri_
      ) ERC721A(name_, symbol_)payable{
          _baseTokenURI = baseUri_;
  }

  function genesisClaim(uint[] memory _tokenIds) external payable {
      uint length = _tokenIds.length;
      require(claimActive = true, "Claim is no longer active.");
      for(uint i = 0; i < length; i++) {
          require(msg.sender == genesisContract.ownerOf(_tokenIds[i]), "You don't own one or more of the NFTs you are trying to claim with.");
          require(claimedGenesis[_tokenIds[i]] = false, "One or more of the NFTs you are trying to claim have already been claimed.");
          claimedGenesis[_tokenIds[i]] = true;
      }
      _mint(msg.sender, length,"",true);
      unclaimedGenesis -= length;
  }

  function mainClaim(uint[] memory _tokenIds) external payable {
      uint length = _tokenIds.length;
      require(msg.value == mainClaimPrice * length, "Insufficient Funds.");
      require(claimActive = true, "Claim is no longer active.");
      for(uint i = 0; i < length; i++) {
          require(msg.sender == mainContract.ownerOf(_tokenIds[i]), "You don't own one or more of the NFTs you are trying to claim with.");
          require(claimedMain[_tokenIds[i]] = false, "One or more of the NFTs you are trying to claim have already been claimed.");
          claimedMain[_tokenIds[i]] = true;
      }
      _mint(msg.sender, length,"",true);
      unclaimedMain -= length;
  }

  function publicMint(uint256 quantity) external payable
    {
        require(presaleOnly == false);
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You minted as many as you can already.");
        if (claimActive = true) {
            require((totalSupply() + quantity) <= (maxSupply - unclaimedGenesis - unclaimedMain), "Cannot exceed max supply");
        } else {
            require((totalSupply() + quantity) <= (maxSupply), "Cannot exceed max supply");
        }
        
        require(msg.value >= cost * quantity, "Insufficient Funds.");
        require(tx.origin == msg.sender, "No contracts!");
        _mint(msg.sender, quantity,"",true);
        addressMintedBalance[msg.sender] += quantity;
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable
    {
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You minted as many as you can already.");
        // overflow checks here
        if (claimActive = true) {
            require((totalSupply() + quantity) <= (maxSupply - unclaimedGenesis - unclaimedMain), "Cannot exceed max supply");
        } else {
            require((totalSupply() + quantity) <= (maxSupply), "Cannot exceed max supply");
        }
        require(msg.value >= cost * quantity, "Insufficient Funds.");
        require(tx.origin == msg.sender, "No contracts!");

        // Prove to contract that sender was in snapshot
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");

                _mint(msg.sender, quantity,"",true);
                addressMintedBalance[msg.sender] += quantity;
             
        
    }

    

    function _baseURI() internal view virtual override returns (string memory) 
    {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _baseTokenURI = baseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) 
    {
        return _exists(tokenId);
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) 
    {
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

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner 
    {
    merkleRoot = _newMerkleRoot;
    }

    function setClaimActive(bool _state) external onlyOwner 
    {
    claimActive = _state;
    }

    function setPresaleOnly(bool _state) external onlyOwner 
    {
    presaleOnly = _state;
    }

    function reveal(bool _state) external onlyOwner 
    {
    revealed = _state;
    }

}
