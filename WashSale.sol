/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
Smart contract to record a washsale on NFTs. "Sell" your NFT to the contract for whatever you want and buy it back for the same amount
plus a wash fee of 0.001 ETH, all in the same transaction. Gas fees paid will add to loss. Only catch is you need to have enough ETH to fund the purchase and sale.
Example: If you want to sell your NFT for 1 ETH, you need to send 1 ETH (plus the wash fee) with the NFT. You will get your 1 ETH back in the same transaction.
Only works 1 token at a time. No batch washing at this time. Maybe in a future version if there's enough demand for it.
No guarantee that this will hold up in an audit, but it's definitely better than nothing and you get to keep your NFT.

The tax position being taken here is that you are loaning the contract at 0% interest, and then selling the contract your NFT.
The contract then pays back your loan in full, and you buy your NFT back for the same price you sold it for.
The ETH and NFT is first transferred to the contract, and in the same transaction sent back to the original sender.
Worth noting this is a completed transaction and not a failed transaction reverting.

This is currently experimental and not for use on mainnet.
**/


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "https://github.com/nickyoung92/Solidity-Contracts/blob/main/Shareholders.sol";



contract Wash is IERC721Receiver, ERC1155Receiver, Shareholders{
    IERC721 private NFT721;
    IERC1155 private NFT1155;
    uint washFee = 0.001 ether; //0.001 Ether fee per trade.

    //You can only wash one token at a time.
    function wash721Token(address _smartContract, uint _tokenId, uint _newBasisInWei) external payable {
        NFT721 = ERC721(_smartContract);
        address payable msgSender = payable(msg.sender);
        require(msg.value == _newBasisInWei+washFee, "insufficient funds");
        require(NFT721.ownerOf(_tokenId)==msg.sender, "You don't own the NFT you are trying to wash.");
        NFT721.safeTransferFrom(msg.sender, address(this), _tokenId, "0x00");
        msgSender.transfer(_newBasisInWei);
        NFT721.safeTransferFrom(address(this), msg.sender, _tokenId, "0x00");            
    }

    //You can wash multiple amounts of the same tokenID at once. Basis input is total amount, not per quantity.
    function wash1155Token(address _smartContract, uint _tokenId, uint _quantity, uint _newBasisInWei) external payable {
        NFT1155 = ERC1155(_smartContract);
        address payable msgSender = payable(msg.sender);
        require(msg.value == _newBasisInWei+washFee, "insufficient funds");
        require(NFT1155.balanceOf(msg.sender, _tokenId) >= _quantity, "You don't own enough of this tokenID.");
        NFT1155.safeTransferFrom(msg.sender, address(this), _tokenId, _quantity, "0x00");
        msgSender.transfer(_newBasisInWei);
        NFT1155.safeTransferFrom(address(this), msg.sender, _tokenId, _quantity, "0x00");
    }

    function onERC721Received(address, address, uint, bytes memory) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
