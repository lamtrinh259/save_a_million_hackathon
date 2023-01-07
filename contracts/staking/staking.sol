//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract saveAMillion{

    address private owner;
    IERC20 public stakingToken;
    uint256 public totalSupply;
    uint256 public ticketStakingThreshold = 10 * 10**18;

    receive() external payable {}
    fallback() external payable {}

    struct stakerInfo{
        uint stakingAmount;
        uint tickets;
        mapping(uint => uint) ticketInfo;
        uint rewards;
        bool isWinner;
    }

    mapping(address => uint256) public stakingBalances;
    mapping(address => bool) public isStakingMap;

    mapping(address => uint256) public rewards;
    mapping(address => bool) public isRewared;

    address[] public stakerList;

    mapping(uint => uint) numberOccurrence;
    mapping(address => stakerInfo) StakerList;

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can execute");
        _;
    }

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
        owner = msg.sender;
    }

    function isStaking(address user) internal view returns(bool){
        return isStakingMap[user];
    }

    function setRewardStakingThreshold(uint _threshold) external onlyOwner{
        ticketStakingThreshold = _threshold;
    }

    function stake(uint256 amount) external {
        // keep track of how much this user has staked
        // keep track of how much token we have total
        // transfer the tokens to this contract
        // stakingBalances[msg.sender] += amount;
        StakerList[msg.sender].stakingAmount += amount;
        totalSupply += amount;

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success,"Staking fails");
        if (isStakingMap[msg.sender] == false){
            isStakingMap[msg.sender] = true;
        }

        updateTickets(msg.sender);

    }

    function unstake(uint256 amount) external {
        require(StakerList[msg.sender].stakingAmount > amount, "not enough amount to unstake");

        StakerList[msg.sender].stakingAmount -= amount;
        // stakingBalances[msg.sender] -= amount;
        totalSupply -= amount;
        // emit event

        bool success = stakingToken.transfer(msg.sender, amount);
        require(success,"Unstaking fails");
        if (StakerList[msg.sender].stakingAmount == 0){
            isStakingMap[msg.sender] = false;
        }

        updateTickets(msg.sender);
    }

    function updateTickets(address user) internal{
        StakerList[user].tickets += StakerList[user].stakingAmount / ticketStakingThreshold;
    }

    function randomTicketNumber(address user) internal{
        for (uint i = 0; i < StakerList[user].tickets; i++){

            // Hardcode number ticket
            StakerList[user].ticketInfo[i] = 42;
            numberOccurrence[42] += 1;
        }
    }


    // function issueReward(uint rewardAmount, uint winningNumber) external onlyOwner{
        
    //     for (uint i = 0; i < winners.length; i ++){
    //         if (isStakingMap[winners[i]] == false){
    //             continue;
    //         }
    //         StakerList[winners[i]].rewards = amounts[i];
    //         // rewards[winners[i]] = amounts[i];
    //     }
    // }

    function claim() external view returns (uint) {

        // bool check = isRewarded(msg.sender);
        uint _claimAmount = StakerList[msg.sender].rewards;
        require(_claimAmount > 0, "no rewards to claim");

        return _claimAmount;
    }
}