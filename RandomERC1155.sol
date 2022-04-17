/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

Multi Tier Random Mint Pass. 

**/
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "https://github.com/nickyoung92/Solidity-Contracts/blob/main/Shareholders.sol";

contract MintPass is ERC1155, Shareholders {
    using Strings for uint256;
    uint256 nonce;

    
    uint256[] public tokenIds = [1,2,3,4];

    
    uint256 maxMintsPerWallet = 2;
    uint256 mintPrice = 0.1 ether;
    string public baseUri;
    mapping(address => uint256) public addressMintedBalance;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public maxSupply;
    
    address private newContract;
    string private baseURI;
    
    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseURI, uint[] memory _tokenIDs, uint[] memory _tokenSupply) ERC1155(_baseURI) {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
        for (uint i = 0; i<_tokenIDs.length; i++) {
            maxSupply[_tokenIDs[i]] = _tokenSupply[i];
        }
        
    }

    function mintOne()
        external
        payable
    {
        require(msg.value >= mintPrice, "Insufficient funds.");
        require(addressMintedBalance[msg.sender] <= maxMintsPerWallet, "You cannot mint any more Mint Passes.");
        uint256 randomTier = random();
        _mint(msg.sender, randomTier, 1, "");
        addressMintedBalance[msg.sender]++;
        updateSupply(randomTier);
    }

    function updateSupply(uint randomTier) internal {
        totalSupply[randomTier]++;
        uint count = 0;
        if (totalSupply[randomTier] == maxSupply[randomTier]) {
            uint length = tokenIds.length;
            uint[] memory TokenIdsArray = new uint[](length-1);
            for (uint i = 0; i<length; i++) {
                
                if(randomTier != tokenIds[i]) {
                    TokenIdsArray[count] = tokenIds[i];
                    count++;
                } 
            }
            for (uint j = 0; j<TokenIdsArray.length; j++) {
                tokenIds[j] = TokenIdsArray[j];
            }
            tokenIds.pop();          
        }
    }

    function getRemainingMints(uint _tokenID) public view returns (uint) {
        uint remainingMints = maxSupply[_tokenID] - totalSupply[_tokenID];
        return remainingMints;
    }

    function random() internal returns (uint) {
        uint length = tokenIds.length;
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 99; //returns a "random" number between 0 and 99
        randomnumber = randomnumber + 1; //changes result to add 1, resulting in a random number between 1 and 100.
        nonce += 1;
        if(length == 4) {
            if (randomnumber <= 65) { //65% chance
                return tokenIds[0]; 
            } else if (randomnumber <= 85) { //20% chance
                return tokenIds[1];
            } else if (randomnumber <= 95) { //10% chance
                return tokenIds[2];
            } else { //5% chance
                return tokenIds[3];
            }
        } else if (length == 3) {
            if (randomnumber <= 75) { //75% chance
                return tokenIds[0];
            } else if (randomnumber <= 95) { //20% chance
                return tokenIds[1]; 
            } else { //5% chance
                return tokenIds[2];
            }
        } else if (length == 2) {
            if (randomnumber <= 85) { //85% chance
                return tokenIds[0];
            } else { //15% chance
                return tokenIds[1];
            }
        } else if (length == 1) {
            return tokenIds[0];
        } else {
            revert("Mint Passes sold out. Transaction reverted.");
        }
    }

    function getTokenIdsNotSoldOut() public view returns (uint[] memory) {
        uint length = tokenIds.length;
        uint[] memory TokenIdsArray = new uint[](length);
        for (uint i = 0; i<length; i++) {
            TokenIdsArray[i] = tokenIds[i];
        }
        return TokenIdsArray;
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 _tierID)
        public
        view
        override             
        returns (string memory)
    {
        
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tierID.toString()))
                : baseURI;
    }
}
