//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding
{
    mapping(address=>uint256) public contributors;
    address public manager;
    uint256 public minContribution;
    uint256 public deadline;
    uint256 public target;
    uint256 public raisedAmt;
    uint256 public noOfContributors;

    constructor(uint256 _target,uint256 _deadline) //manager will initialize the contract, so the senders address will become his address.
    {
        target=_target;
        deadline= block.timestamp + _deadline;
        minContribution= 100 wei;
        manager= msg.sender;
    }

    mapping(uint256=>Request) public requests; //maps request number to the request.
    uint256 public numRequests; //incrementation is not possible in mapping (above mapping) hence this variable.
    
    struct Request
    {
        string description;
        address payable recipient;
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping (address=>bool) voters; //which of the contributors are contributing to this cause.
    }

    //All that contributors can do
    function sendEth() public payable //contributors are sending money to the contract.
    {
        require(block.timestamp<deadline,"Deadline has passed.");
        require(msg.value>=minContribution,"Minimum contribution is not  met.");
        if(contributors[msg.sender]==0)
        {
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmt+=msg.value;
    }

    function getContractBalance() public view returns(uint256)
    {
        return address(this).balance;
    }

    function refund() public
    {
        require(block.timestamp>deadline && raisedAmt<target, "You are not eligible");
        require(contributors[msg.sender]>0);
        address payable user= payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;

    }

    //All that manager can do

    modifier onlyManager()
    {
        require(msg.sender==manager,"Only the MANAGER can call this function.");
        _;
    }
    function createRequests(string memory _description, address payable _recipient,uint256 _value) public onlyManager
    {
        Request storage newRequest= requests[numRequests];
        numRequests++;
        newRequest.description= _description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;

    }
    function voteRequest(uint256 _requestNo) public
    {
        require(contributors[msg.sender]>0,"You must be a contributor to vote.");
        Request storage thisRequest= requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;

    }
    function makePayment(uint256 _requestNo) public onlyManager
    {
        require(raisedAmt>target,"Insufficient Money");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false, "This request has been completed.");
        require(thisRequest.noOfVoters>noOfContributors/2);
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }

}
