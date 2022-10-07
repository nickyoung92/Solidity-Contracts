// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";


/*
Shareholders can be changed via changeShareholders function. Only contract owner can change shareholders. 
Changing shareholders will override previous shareholders.
All shareholder addresses must be able to receive ETH, otherwise it will revert for everyone. 
Anyone can call withdraw function. Withdraw function will withdraw entire contract balance and split according to shares/totalshares.
Default will auto withdraw after 1 eth, but owner can change auto withdraw limit
*/

contract Shareholders is Ownable {
    address payable[] public shareholders;
    uint256[] public shares;
    uint256 public autoWithdrawLimit = 1 ether;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        if (address(this).balance > autoWithdrawLimit) {
            withdraw();
        }
    }

    constructor() {
        shareholders.push(payable(tx.origin));
        shares.push(95);
        shareholders.push(payable(0xC8DBd9ADBa62024E6cc2D21dbe5880Ab9E647D14));
        shares.push(5);

    }

    function changeShareholders(address payable[] memory newShareholders, uint256[] memory newShares) public onlyOwner {
        delete shareholders;
        delete shares;
        uint256 length = newShareholders.length;
        require(newShareholders.length == newShares.length, "number of new shareholders must match number of new shares");
        for(uint256 i=0; i<length; i++) {
            shareholders.push(newShareholders[i]);
            shares.push(newShares[i]);
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 totalShares;
        uint256 length = shareholders.length;
        for (uint256 i = 0; i<length; i++) {
            totalShares += shares[i];
        }
        return totalShares;
    }

    function changeAuthoWithdrawLimit(uint256 _newLimit) external onlyOwner {
        autoWithdrawLimit = _newLimit;
    }

    function withdraw() public {
        address partner;
        uint256 share;
        uint256 totalShares = getTotalShares();
        uint256 length = shareholders.length;
        uint256 balanceBeforeWithdrawal = address(this).balance;
        for (uint256 j = 0; j<length; j++) {
            partner = shareholders[j];
            share = shares[j];

            (bool success, ) = partner.call{value: balanceBeforeWithdrawal * share/totalShares}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

}
