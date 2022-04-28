/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
Anyone can create an event with a set amount of tickets and set price per ticket, with a payee address to receive ticket sales proceeds.
Anyone can buy a ticket from an event once it's created. 
Event number is mapped to host. i.e. The creator of an event.
use balanceOfTicketholder to verify ownership of ticket. Inputs(event number, host address, ticket owner address)

Tickets can not be sold or transferred and are non refundable.
*/

contract TicketBooth {
    address public feeReceiver = 0xfD74E361244a2E4eb807583969943EEc01b60FFC;
    uint public createEventFee = 0.05 ether;
    mapping(address => uint) public eventNumberOfHost;
    mapping(uint => mapping(address => uint)) public ticketPriceOfEvent;
    mapping(uint => mapping(address => uint)) public totalTicketsOfEvent;
    mapping(uint => mapping(address => uint)) public soldTicketsOfEvent;
    mapping(address => mapping(uint => address)) public payeeOfEvent;
    mapping(uint => mapping(address => mapping(address => uint))) public balanceOfTicketholder;


    function createEvent(uint _numberOfTickets, uint _pricePerTicket, address _payee) external payable {
        require(msg.value == createEventFee, "You have to pay a fee to create a ticketed event.");
        eventNumberOfHost[msg.sender]++;
        ticketPriceOfEvent[eventNumberOfHost[msg.sender]][msg.sender] = _pricePerTicket;
        payeeOfEvent[msg.sender][eventNumberOfHost[msg.sender]] = _payee;
        totalTicketsOfEvent[eventNumberOfHost[msg.sender]][msg.sender] = _numberOfTickets;
        (bool a, ) = feeReceiver.call{value: createEventFee}("");
        require(a, "Address: unable to send value, recipient may have reverted");

    }

    function buyTicket(uint _quantity, address _eventHost, uint _eventNumber) external payable {
        uint totalTicketPrice = _quantity * ticketPriceOfEvent[_eventNumber][_eventHost];
        uint soldTickets = soldTicketsOfEvent[eventNumberOfHost[_eventHost]][_eventHost];
        uint totalTickets = totalTicketsOfEvent[eventNumberOfHost[_eventHost]][_eventHost];
        address payee = payeeOfEvent[_eventHost][_eventNumber];
        require(msg.value == totalTicketPrice, "insufficient funds");
        require(soldTickets < totalTickets, "Tickets are sold out");
        require(_quantity + soldTickets <= totalTickets, "Not enough tickets left for sale. Try buying less.");
        soldTicketsOfEvent[eventNumberOfHost[_eventHost]][_eventHost] += _quantity;
        balanceOfTicketholder[_eventNumber][_eventHost][msg.sender] += _quantity;
        (bool a, ) = payee.call{value: totalTicketPrice}("");
        require(a, "Address: unable to send value, recipient may have reverted");

    }
}
