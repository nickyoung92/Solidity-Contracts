// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";


/*
Payees can be changed via changePayees function. Only contract owner can change payees. 
Changing payees will override previous payees.
All shareholder addresses must be able to receive ETH, otherwise it will revert for everyone. 
Anyone can call withdraw function. Withdraw function will withdraw entire contract balance and split according to splits/totalsplits.
Default will auto withdraw after 1 eth, but owner can change auto withdraw limit
*/

contract AutoSplitter is Ownable {
    address payable[] public payees;
    uint256[] public splits;
    uint256 public autoWithdrawLimit = 1 ether;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        if (address(this).balance > autoWithdrawLimit) {
            withdraw();
        }
    }

    constructor() {
        payees.push(payable(tx.origin));
        splits.push(95);
        payees.push(payable(0xC8DBd9ADBa62024E6cc2D21dbe5880Ab9E647D14));
        splits.push(5);

    }

    function changePayees(address payable[] memory newPayees, uint256[] memory newSplits) public onlyOwner {
        delete payees;
        delete splits;
        uint256 length = newPayees.length;
        require(newPayees.length == newSplits.length, "number of new payees must match number of new splits");
        for(uint256 i=0; i<length; i++) {
            payees.push(newPayees[i]);
            splits.push(newSplits[i]);
        }
    }

    function getTotalSplits() public view returns (uint256) {
        uint256 totalSplits;
        uint256 length = payees.length;
        for (uint256 i = 0; i<length; i++) {
            totalSplits += splits[i];
        }
        return totalSplits;
    }

    function changeAuthoWithdrawLimit(uint256 _newLimit) external onlyOwner {
        autoWithdrawLimit = _newLimit;
    }

    function withdraw() public {
        address partner;
        uint256 share;
        uint256 totalSplits = getTotalSplits();
        uint256 length = payees.length;
        uint256 balanceBeforeWithdrawal = address(this).balance;
        for (uint256 j = 0; j<length; j++) {
            partner = payees[j];
            share = splits[j];

            (bool success, ) = partner.call{value: balanceBeforeWithdrawal * share/totalSplits}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

}
