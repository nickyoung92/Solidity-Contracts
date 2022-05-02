
/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

Organizer creates a gift basket on behalf of a recipient. People can make gifts until the claim date.
If the recipient does not claim by the expiration date, gifters can request a refund.

**/

import "@openzeppelin/contracts/access/Ownable.sol";

contract GiftBasket is Ownable {
    
    struct giftBasket {
        address _recipient;
        address _organizer;
        uint _claimDate;
        uint _expirationDate;
        uint _index;
        uint _balance;
        bool _claimed;
    }
    
    giftBasket[] public giftBaskets;
    mapping(address => uint[]) internal _indexesOfReceiver;
    mapping(address => uint[]) internal _indexesOfOrganizer;
    mapping(address => mapping(uint => uint)) public giftsByAddressAndBasket;


    uint public minimumDateOffset = 3 days;
    uint public basketIndex;
    uint internal contractFee = 0.01 ether;


    //creates a gift basket for people to gift eth to. 
    function createGiftBasket(address _recipient, uint _claimDate, uint _expirationDate, uint _startingGift ) external payable {
        require(_claimDate <= _expirationDate - minimumDateOffset, "The expiration date must be at least 3 days later than the delivery date." );
        require(msg.value == _startingGift + contractFee, "insufficient funds.");
        giftBasket memory newBasket = giftBasket(_recipient, msg.sender, _claimDate, _expirationDate, basketIndex, _startingGift, false);
        giftBaskets.push(newBasket);
        giftsByAddressAndBasket[msg.sender][basketIndex] += _startingGift;
        _indexesOfReceiver[_recipient].push(basketIndex);
        _indexesOfOrganizer[msg.sender].push(basketIndex);
        basketIndex++;
    }

    //make a gift to a specific gift basket
    function makeGift(uint _giftBasket, uint _gift) external payable {
        require(block.timestamp < giftBaskets[_giftBasket]._claimDate, "This basket is no longer accepting gifts.");
        require(msg.value == _gift, "insufficient funds.");
        giftBaskets[_giftBasket]._balance += _gift;
        giftsByAddressAndBasket[msg.sender][basketIndex] += _gift;
    }


    //claims entire balance of gift basket.
    function claimGift(uint _giftBasket) external payable {
        require(giftBaskets[_giftBasket]._claimed = false, "This gift basket has already been claimed.");
        require(block.timestamp >= giftBaskets[_giftBasket]._claimDate, "You cannot claim this gift yet.");
        require(msg.sender == giftBaskets[_giftBasket]._recipient, "You are not eligible to claim from this gift basket.");
        uint claimAmount = giftBaskets[_giftBasket]._balance;
        (bool success, ) = msg.sender.call{value: claimAmount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        giftBaskets[_giftBasket]._balance -= claimAmount;
        giftBaskets[_giftBasket]._claimed = true;
    }

    //refunds entire amount of gift made by message sender.
    function refundGift(uint _giftBasket) external payable {
        require(giftBaskets[_giftBasket]._claimed = false, "The gift was claimed.");
        require(block.timestamp >= giftBaskets[_giftBasket]._expirationDate, "You cannot claim a refund yet.");
        require(giftsByAddressAndBasket[msg.sender][basketIndex] > 0, "There is nothing to refund!");
        uint refund =  giftsByAddressAndBasket[msg.sender][basketIndex];
        (bool success, ) = msg.sender.call{value: refund}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        giftsByAddressAndBasket[msg.sender][basketIndex] -= refund;
    }

    function getOrganizerBaskets(address _organizer) external view returns (uint[] memory) {
        return _indexesOfOrganizer[_organizer];
    }

    function getRecipientBaskets(address _recipient) external view returns (uint[] memory) {
        return _indexesOfReceiver[_recipient];
    }

    function changeFee(uint _newFee) external onlyOwner {
        contractFee = _newFee;
    }

    function emergencyWithdraw(uint _amount) external onlyOwner {
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



}
