pragma solidity ^0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract RNGContract {
    using SafeMath for uint;

    // The RNG function that generates a random number
    function randomNumber() public pure returns (uint) {
        // Generate a random seed using the current block hash and a salt value
        bytes32 seed = keccak256(abi.encodePacked(block.difficulty, now, 8));

        // Hash the seed using SHA-256 to generate a random number
        return uint(sha256(seed)) % 100;
    }

    // The contract function that calls the RNG function and returns the result
    function getRandomNumber() public view returns (uint) {
        // Call the RNG function and return the result
        return randomNumber();
    }
}
