// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/IERC721A.sol";


contract Council {
    address public Admin;
    address[] public CouncilMembers; //List of collections on the Council. Council membership is permanent.
    uint256 public votingPeriod = 10 days; //How long proposals have to receive enough votes to pass
    uint256 public votesRequiredDenominator = 2; //Denominator for votes required (total outstanding votes divided by 2)
    uint256 public proposalCooldown = 1 days; //Cooldown period to submit proposals

    struct NewCouncilMemberProposals {
        address _contract;
        bool _voteComplete;
        bool _proposalPassed;
        uint256 _startingTime;
        uint256 _endingTime;
        uint256 _votesCast;
        uint256 _votesToPass;
    }

    struct MultipleChoice {
        bool _voteComplete;
        string _winner;
        uint256 _startingTime;
        uint256 _endingTime;
        string[] _options;
        uint256[] _votesCast;
    }

    NewCouncilMemberProposals[] internal councilProposals;
    MultipleChoice[] internal multipleChoice;
    mapping(address => mapping(uint256 => uint256)) internal votesCastCouncil;
    mapping(address => mapping(uint256 => uint256)) internal votesCastMultipleChoice;
    mapping(address => uint256) public lastProposal;

    constructor() {
        Admin = msg.sender;
        //Add founding Council Members
        CouncilMembers.push(0x0fC5025C764cE34df352757e82f7B5c4Df39A836);
    }


    /*
    
    MODIFIERS
    
    */

    //checks if msg.sender is a holder of any of the Council Collections or Admin
    modifier isCouncilHolder() {
        if (msg.sender != Admin) {
            require(getVotes(msg.sender) > 0, "You must be a council member.");
        }
        _;
    }

    //checks if msg.sender is admin
    modifier onlyAdmin() {
        require(msg.sender == Admin, "This is an admin only function.");
        _;
    }


    /*
    
    VERIFICATION FUNCTIONS
    
    */


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

    //Makes sure contract is valid ERC721 contract with necessary functions
    function isValid(address _contract) internal view returns (bool) {
        IERC721A collection = IERC721A(_contract);
        if (collection.totalSupply() > 0) { //ensure contract has totalSupply function and is not zero
            uint balanceCheck = collection.balanceOf(address(this)); //unused variable to ensure contract has balanceOf function
            return true;
        } else {
            revert("This contract is not compatible.");
        }
    }


    /*
    
    VOTE TALLY FUNCTIONS
    
    */


    //Gets total voting power of a specific wallet address
    function getVotes(address _address) internal view returns (uint256) {
        uint256 votes = 0;
        for(uint i = 0; i<CouncilMembers.length;i++) {
            IERC721A collection = IERC721A(CouncilMembers[i]);
            votes += collection.balanceOf(_address);
        }
        return votes;
    }

    //Gets total voting power of all council members combined based on total supply of each collection
    function getTotalVotes() internal view returns (uint256) {
        uint256 totalVotes = 0;
        for(uint i = 0; i<CouncilMembers.length;i++) {
            IERC721A collection = IERC721A(CouncilMembers[i]);
            totalVotes += collection.totalSupply();
        }
        return totalVotes;
    }
    
    //Calculates the number of votes required to pass a proposal
    function getVotesRequired() internal view returns (uint256) {
        uint256 totalVotes = getTotalVotes();
        uint256 votesRequired = (totalVotes / votesRequiredDenominator);
        return votesRequired + 1;
    }

    //Gets the number of votes cast by a single address towards a specific new council member proposal
    function getVotesCastCouncil(address _address, uint _proposalID) external view returns (uint256 _votesCast) {
        return votesCastCouncil[_address][_proposalID];
    }

    //Gets the number of votes cast by a single address towards a specific multiple choice proposal
    function getVotesCastMultipleChoice(address _address, uint _proposalID) external view returns (uint256 _votesCast) {
        return votesCastMultipleChoice[_address][_proposalID];
    }


    /*

    PROPOSAL FUNCTIONS

    */

    
    //function to propose a new collection to the Council. Can only be proposed by a current council member holder.
    function proposeNewCouncilMember(address _contract) external isCouncilHolder {
        require(block.timestamp > lastProposal[msg.sender]+proposalCooldown, "You must wait before submitting another proposal.");
        require(isCouncilMember(_contract) == false, "This contract is already on the council.");
        require(isValid(_contract) == true, "This contract is not compatible.");
        uint256 votesRequired = getVotesRequired();
        NewCouncilMemberProposals memory new_proposal = NewCouncilMemberProposals(_contract, false, false, block.timestamp, (block.timestamp + votingPeriod), 0, votesRequired);
        councilProposals.push(new_proposal);
        lastProposal[msg.sender] = block.timestamp;
    }

    //create multiple choice proposal
    function proposeMultipleChoice(string[] memory _options) external isCouncilHolder {
        require(block.timestamp > lastProposal[msg.sender]+proposalCooldown, "You must wait before submitting another proposal.");
        uint256 length = _options.length;
        uint256[] memory _votes = new uint256[](length);
        MultipleChoice memory new_proposal = MultipleChoice(false, "", block.timestamp, (block.timestamp + votingPeriod), _options, _votes);
        multipleChoice.push(new_proposal);
    }


    /*

    VOTING FUNCTIONS

    */


    //function to vote on a proposal to add a new collection to the Council. Applies all available votes and triggers the close and result of the proposal.
    function voteOnMultipleChoiceProposal(uint256 _proposalID, uint256 _selection) external isCouncilHolder {
        require(multipleChoice[_proposalID]._voteComplete == false, "Voting has closed.");
        if(block.timestamp < multipleChoice[_proposalID]._endingTime) {
            uint256 votes = getVotes(msg.sender);
            uint256 votesUsed = votesCastMultipleChoice[msg.sender][_proposalID];
            uint256 unusedVotes = votes - votesUsed;
            multipleChoice[_proposalID]._votesCast[_selection] += unusedVotes;
            votesCastMultipleChoice[msg.sender][_proposalID] += unusedVotes;
        } else {
            multipleChoice[_proposalID]._voteComplete = true;
            uint256 largest = 0; 
            uint256 i;
            for(i=0;i<multipleChoice[_proposalID]._options.length;i++) {
                if(multipleChoice[_proposalID]._votesCast[i] > largest) {
                    largest = multipleChoice[_proposalID]._votesCast[i]; 
                    multipleChoice[_proposalID]._winner = multipleChoice[_proposalID]._options[i];  
                } 
            }
                 
        }   
    }

    //function to vote on a proposal to add a new collection to the Council. Applies all available votes and triggers the close and result of the proposal.
    function voteOnNewCouncilMemberProposal(uint256 _proposalID) external isCouncilHolder {
        require(councilProposals[_proposalID]._voteComplete == false, "Voting has closed.");
        if(block.timestamp < councilProposals[_proposalID]._endingTime) {
            uint256 votes = getVotes(msg.sender);
            uint256 votesUsed = votesCastCouncil[msg.sender][_proposalID];
            uint256 unusedVotes = votes - votesUsed;
            councilProposals[_proposalID]._votesCast += unusedVotes;
            votesCastCouncil[msg.sender][_proposalID] += unusedVotes;
            if(councilProposals[_proposalID]._votesCast >= councilProposals[_proposalID]._votesToPass) {
                passNewCouncilMemberProposal(_proposalID);
            }
        } else {
            councilProposals[_proposalID]._voteComplete = true;
        }
        

    }


    /*
    
    HELPERS
    
    */


    //Internal function to pass proposal and add collection to list of council members if votes cast meets votes required
    function passNewCouncilMemberProposal(uint256 _proposalID) internal {
        councilProposals[_proposalID]._voteComplete = true;
        councilProposals[_proposalID]._proposalPassed = true;
        CouncilMembers.push(councilProposals[_proposalID]._contract);
    }

    //Internal function to pass proposal and close voting
    function passMultipleChoiceProposal(uint256 _proposalID) internal {
        multipleChoice[_proposalID]._voteComplete = true;
    }


    /*
    
    INFORMATIONAL FUNCTIONS
    
    */


    //Returns details of a specific proposal
    function getNewCouncilMemberProposalData(uint256 _proposalID) external view returns (
        address _contract,
        bool _voteComplete,
        bool _votePassed,
        uint256 _startingTime,
        uint256 _endingTime,
        uint256 _votesCast,
        uint256 _votesToPass
    ) {
        return (
            councilProposals[_proposalID]._contract,
            councilProposals[_proposalID]._voteComplete,
            councilProposals[_proposalID]._proposalPassed,
            councilProposals[_proposalID]._startingTime,
            councilProposals[_proposalID]._endingTime,
            councilProposals[_proposalID]._votesCast,
            councilProposals[_proposalID]._votesToPass
        );
    }

    function getMultipleChoiceProposalData(uint256 _proposalID) external view returns (
        bool _voteComplete,
        string memory _winner,
        uint256 _startingTime,
        uint256 _endingTime,
        string[] memory _options,
        uint256[] memory _votesCast
    ) {
        return (
            multipleChoice[_proposalID]._voteComplete,
            multipleChoice[_proposalID]._winner,
            multipleChoice[_proposalID]._startingTime,
            multipleChoice[_proposalID]._endingTime,
            multipleChoice[_proposalID]._options,
            multipleChoice[_proposalID]._votesCast
        );
    }


    /*
    
    ADMIN FUNCTIONS
    
    */


    function transferAdmin(address _newAdmin) external onlyAdmin {
        Admin = _newAdmin;
    }

    function updateRequiredDenominator(uint256 _newDenominator) external onlyAdmin {
        votesRequiredDenominator = _newDenominator;
    }

    function updateVotingPeriod(uint256 _newVotingPeriodInSeconds) external onlyAdmin {
        votingPeriod = _newVotingPeriodInSeconds;
    }

    function updateProposalCooldown(uint256 _newCooldownInSeconds) external onlyAdmin {
        proposalCooldown = _newCooldownInSeconds;
    }

    
}


