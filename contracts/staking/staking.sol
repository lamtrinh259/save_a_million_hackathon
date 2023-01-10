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

    mapping(address => bool) public isStakingMapping;

    address[] public stakerAddress;

    mapping(uint => uint) numberOccurrence;
    mapping(uint => bool) existingTicketNumber;
    mapping(address => stakerInfo) StakerList;

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can execute");
        _;
    }

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
        owner = msg.sender;
    }

    function setRewardStakingThreshold(uint _threshold) external onlyOwner{
        ticketStakingThreshold = _threshold;
    }

    // get user Info
    function getUserInfo(address user) external view
    returns(
        uint stakingAmount,
        uint tickets,
        uint rewards,
        bool isWinner
    ){
        require(isStakingMapping[user],"user has not staked");
        return (
            StakerList[user].stakingAmount,
            StakerList[user].tickets,
            StakerList[user].rewards,
            StakerList[user].isWinner);
    }

    // query user ticket number
    function getUserTicketNumber(address user, uint index) external view returns(uint){
        require(isStakingMapping[user],"user has not staked");
        require(index < StakerList[user].tickets - 1,"user has not staked");
        return  StakerList[user].ticketInfo[index];
    }

    // staker staking amount of token
    function stake(uint256 amount) external {
        // keep track of how much this user has staked
        // keep track of how much token we have total
        // transfer the tokens to this contract
                
        StakerList[msg.sender].stakingAmount += amount;
        stakerAddress.push(msg.sender);
        totalSupply += amount;

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success,"Staking fails");
        if (isStakingMapping[msg.sender] == false){
            isStakingMapping[msg.sender] = true;
        }

        updateTickets(msg.sender);

    }

    // staker unstaking amount of token
    function unstake(uint256 amount) external {
        require(StakerList[msg.sender].stakingAmount > amount, "not enough amount to unstake");

        StakerList[msg.sender].stakingAmount -= amount;
        // stakingBalances[msg.sender] -= amount;
        totalSupply -= amount;
        // emit event

        bool success = stakingToken.transfer(msg.sender, amount);
        require(success,"Unstaking fails");
        if (StakerList[msg.sender].stakingAmount == 0){
            isStakingMapping[msg.sender] = false;
        }

        updateTickets(msg.sender);
    }

    // update staker number of ticket
    function updateTickets(address user) internal{
        StakerList[user].tickets += StakerList[user].stakingAmount / ticketStakingThreshold;
        randomTicketNumber(user);
    }

    // RNG
    function randomTicketNumber(address user) internal{
        for (uint i = 0; i < StakerList[user].tickets; i++){

            // Hardcode number ticket
            uint temp = uint(keccak256(abi.encode(user, block.coinbase, i)));
            uint rng = randomNumber(temp);
            StakerList[user].ticketInfo[i] = rng;
            numberOccurrence[rng] += 1;
            if (existingTicketNumber[rng] == false){
                existingTicketNumber[rng] = true;
            }
        }
    }


    // The RNG function that generates a random number
    function randomNumber(uint preSeed) internal view returns (uint) {
        // Generate a random seed using the current block hash and a salt value
        bytes32 seed = keccak256(abi.encodePacked(block.difficulty, block.timestamp, uint(preSeed)));

        bytes memory seedBytes = abi.encodePacked(seed);
        // Hash the seed using SHA-256 to generate a random number
        return uint(sha256(seedBytes)) % 100;
    }

    // staker claiming rewards
    function claim() external view returns (uint) {

        // bool check = isRewarded(msg.sender);
        uint _claimAmount = StakerList[msg.sender].rewards;
        require(_claimAmount > 0, "no rewards to claim");

        return _claimAmount;
    }

    // issue reward for each staker having winning ticket number
    function issueReward(uint winningNumber) external{
        require(existingTicketNumber[winningNumber],"no user has winning ticket number");
        uint splitAmount = totalSupply / numberOccurrence[winningNumber];
        for (uint i = 0; i < stakerAddress.length;i++){
            address temp_address = stakerAddress[i];
            for (uint j = 0; j < StakerList[temp_address].tickets-1;j++){
                if (StakerList[temp_address].ticketInfo[j] == winningNumber){
                    StakerList[temp_address].rewards = splitAmount;
                }
            }
        }
    }
}