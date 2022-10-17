// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/IERC721A.sol";


contract Council {
    address[] public CouncilMembers; //List of collections on the Council. Council membership is permanent.
    uint256 public votingPeriod = 10 days; //How long proposals have to receive enough votes to pass
    uint256 public votesRequiredDenominator = 2; //Denominator for votes required (total outstanding votes divided by 2)

    struct NewCouncilMemberProposals {
        address _contract;
        bool _voteComplete;
        bool _proposalPassed;
        uint256 _startingTime;
        uint256 _endingTime;
        uint256 _votesCast;
        uint256 _votesToPass;
    }

    struct StandardProposals {
        string _proposal;
        bool _voteComplete;
        bool _proposalPassed;
        uint256 _startingTime;
        uint256 _endingTime;
        uint256 _votesCast;
        uint256 _votesToPass;
    }

    NewCouncilMemberProposals[] internal councilProposals;
    StandardProposals[] internal standardProposals;
    mapping(address => mapping(uint256 => uint256)) internal votesCast;
    
    constructor() {
        //Add founding Council Members
        CouncilMembers.push(0xd9145CCE52D386f254917e481eB44e9943F39138);
    }

    //checks if msg.sender is a holder of any of the Council Collections
    modifier isCouncilHolder() {
        require(getVotesInternal(msg.sender) > 0, "You must be a council member.");
        _;
    }

    //Checks if a contract address is already on the council or not.
    function isCouncilMember(address _contract) internal view returns (bool) {
        bool onTheCouncil = false;
        for(uint i = 0; i<CouncilMembers.length;i++) {
            if(_contract == CouncilMembers[i]) {
                onTheCouncil = true;
            }
        }
        return onTheCouncil;
    }

    //Gets total voting power of a specific wallet address
    function getVotesInternal(address _address) internal view returns (uint256) {
        uint256 votes = 0;
        for(uint i = 0; i<CouncilMembers.length;i++) {
            IERC721A collection = IERC721A(CouncilMembers[i]);
            votes += collection.balanceOf(_address);
        }
        return votes;
    }

    //Gets total voting power of a specific wallet address
    function getVotes(address _address) external view returns (uint256 _votingPowerOfAddress) {
        uint256 votes = 0;
        for(uint i = 0; i<CouncilMembers.length;i++) {
            IERC721A collection = IERC721A(CouncilMembers[i]);
            votes += collection.balanceOf(_address);
        }
        return votes;
    }

    //Gets total voting power of all council members combined based on total supply of each collection
    function getTotalVotesInternal() internal view returns (uint256) {
        uint256 totalVotes = 0;
        for(uint i = 0; i<CouncilMembers.length;i++) {
            IERC721A collection = IERC721A(CouncilMembers[i]);
            totalVotes += collection.totalSupply();
        }
        return totalVotes;
    }
    
    //Gets total voting power of all council members combined based on total supply of each collection
    function getTotalVotes() external view returns (uint256 _totalVotingPower) {
        uint256 totalVotes = 0;
        for(uint i = 0; i<CouncilMembers.length;i++) {
            IERC721A collection = IERC721A(CouncilMembers[i]);
            totalVotes += collection.totalSupply();
        }
        return totalVotes;
    }

    //Calculates the number of votes required to pass a proposal
    function getVotesRequiredInternal() internal view returns (uint256) {
        uint256 totalVotes = getTotalVotesInternal();
        uint256 votesRequired = (totalVotes / votesRequiredDenominator);
        return votesRequired + 1;
    }

    //Calculates the number of votes required to pass a proposal
    function getVotesRequired() external view returns (uint256 _votesToPass) {
        uint256 totalVotes = getTotalVotesInternal();
        uint256 votesRequired = (totalVotes / votesRequiredDenominator);
        return votesRequired + 1;
    }

    //Gets the number of votes cast by a single address towards a specific proposal
    function getVotesCast(address _address, uint _proposalID) external view returns (uint256 _votesCast) {
        return votesCast[_address][_proposalID];
    }

    //function to propose a new collection to the Council. Can only be proposed by a current council member holder.
    function proposeNewCouncilMember(address _contract) external isCouncilHolder {
        require(isCouncilMember(_contract) == false, "This contract is already on the council.");
        uint256 votesRequired = getVotesRequiredInternal();
        NewCouncilMemberProposals memory new_proposal = NewCouncilMemberProposals(_contract, false, false, block.timestamp, (block.timestamp + votingPeriod), 0, votesRequired);
        councilProposals.push(new_proposal);
    }

    //create standard proposal with a string message
    function standardProposal(string memory _proposal) external isCouncilHolder {
        uint256 votesRequired = getVotesRequiredInternal();
        StandardProposals memory new_proposal = StandardProposals(_proposal, false, false, block.timestamp, (block.timestamp + votingPeriod), 0, votesRequired);
        standardProposals.push(new_proposal);
    }

    //function to vote on a proposal to add a new collection to the Council. Applies all available votes and triggers the close and result of the proposal.
    function voteOnStandardProposal(uint256 _proposalID) external isCouncilHolder {
        require(standardProposals[_proposalID]._voteComplete == false, "Voting has closed.");
        if(block.timestamp < standardProposals[_proposalID]._endingTime) {
            uint256 votes = getVotesInternal(msg.sender);
            uint256 votesUsed = votesCast[msg.sender][_proposalID];
            uint256 unusedVotes = votes - votesUsed;
            standardProposals[_proposalID]._votesCast += unusedVotes;
            votesCast[msg.sender][_proposalID] += unusedVotes;
            if(standardProposals[_proposalID]._votesCast >= standardProposals[_proposalID]._votesToPass) {
                passStandardProposal(_proposalID);
            }
        } else {
            standardProposals[_proposalID]._voteComplete = true;
        }
        

    }

    //function to vote on a proposal to add a new collection to the Council. Applies all available votes and triggers the close and result of the proposal.
    function voteOnNewCouncilMemberProposal(uint256 _proposalID) external isCouncilHolder {
        require(councilProposals[_proposalID]._voteComplete == false, "Voting has closed.");
        if(block.timestamp < councilProposals[_proposalID]._endingTime) {
            uint256 votes = getVotesInternal(msg.sender);
            uint256 votesUsed = votesCast[msg.sender][_proposalID];
            uint256 unusedVotes = votes - votesUsed;
            councilProposals[_proposalID]._votesCast += unusedVotes;
            votesCast[msg.sender][_proposalID] += unusedVotes;
            if(councilProposals[_proposalID]._votesCast >= councilProposals[_proposalID]._votesToPass) {
                passNewCouncilMemberProposal(_proposalID);
            }
        } else {
            councilProposals[_proposalID]._voteComplete = true;
        }
        

    }

    //Internal function to pass proposal and add collection to list of council members if votes cast meets votes required
    function passNewCouncilMemberProposal(uint256 _proposalID) internal {
        councilProposals[_proposalID]._voteComplete = true;
        councilProposals[_proposalID]._proposalPassed = true;
        CouncilMembers.push(councilProposals[_proposalID]._contract);
    }

    //Internal function to pass proposal and close voting
    function passStandardProposal(uint256 _proposalID) internal {
        standardProposals[_proposalID]._voteComplete = true;
        standardProposals[_proposalID]._proposalPassed = true;

    }

    //Returns details of a specific proposal
    function getNewCouncilMemberProposalData(uint256 _proposalID) external view returns (
        address _contract,
        bool _voteComplete,
        bool _votePassed,
        uint256 _startingTime,
        uint256 _endingTime,
        uint256 _votesCast,
        uint256 _votesToPass) {
        return (
            councilProposals[_proposalID]._contract,
            councilProposals[_proposalID]._voteComplete,
            councilProposals[_proposalID]._proposalPassed,
            councilProposals[_proposalID]._startingTime,
            councilProposals[_proposalID]._endingTime,
            councilProposals[_proposalID]._votesCast,
            councilProposals[_proposalID]._votesToPass);
    }

    
}


