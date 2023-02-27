// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
Payees can be changed via changePayees function. Only contract owner can change payees. 
Changing payees will override previous payees.
All shareholder addresses must be able to receive ETH, otherwise it will revert for everyone. 
Anyone can call withdraw function. Withdraw function will withdraw entire contract balance and split according to shares/totalshares.

*/
contract PaymentSplitter is Ownable {
    IERC20 internal tokenContract;
    address payable[] public payees;
    uint256[] public shares;
    uint256 public autoWithdrawLimit = 1 ether;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        if (address(this).balance > autoWithdrawLimit) {
            withdraw();
        }
    }

    constructor() { //6% Royalties Total
        payees.push(payable(0xDB6FfD47E81deb48360C4f73d169Fbb743Be0E26)); //Graeme 1.5%/6%
        shares.push(250);
        payees.push(payable(0x376776aA01c0B4f714A2B36F7258E79DA0307188)); //Dan 1.5%/6%
        shares.push(250);
        payees.push(payable(0x37fb006F219781b42D50bd1efDb3C3449E3FEB1A)); //Ryan 1.5%/6%
        shares.push(250);
        payees.push(payable(0x7159EeaCa4e04A40557A1F0d8c460893Fa3E3B5a)); //Josh 0.5/6
        shares.push(83);
        payees.push(payable(0xcA6282A6cCbd1Ec9608f269c2556b6D5738c4ad2)); //Lucas 0.5/6
        shares.push(83);
        payees.push(payable(0x25E1c3272f2268AFC42e9896Aa3eC96cD6ef4826)); //DUCO 0.5/6
        shares.push(84);
        

    }

    function changePayees(address payable[] memory newPayees, uint256[] memory newShares) public onlyOwner {
        delete payees;
        delete shares;
        uint256 length = newPayees.length;
        require(newPayees.length == newShares.length, "number of new payees must match number of new shares");
        for(uint256 i=0; i<length; i++) {
            payees.push(newPayees[i]);
            shares.push(newShares[i]);
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 totalShares;
        uint256 length = payees.length;
        for (uint256 i = 0; i<length; i++) {
            totalShares += shares[i];
        }
        return totalShares;
    }

    function changeAutoWithdrawLimit(uint256 _newLimit) external onlyOwner {
        autoWithdrawLimit = _newLimit;
    }

    function withdraw() public {
        address partner;
        uint256 share;
        uint256 totalShares = getTotalShares();
        uint256 length = payees.length;
        uint256 balanceBeforeWithdrawal = address(this).balance;
        for (uint256 j = 0; j<length; j++) {
            partner = payees[j];
            share = shares[j];
            (bool success, ) = partner.call{value: balanceBeforeWithdrawal * share/totalShares}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    function rescueERC20(address _tokenAddress) external onlyOwner {
        tokenContract = IERC20(_tokenAddress);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transferFrom(address(this), msg.sender, balance);
    }

   

}
