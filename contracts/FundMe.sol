// SPDX-License-Identifier: MIT
// Get funds from users
// Withdraw funds
// SEt a minimum funding value in USD
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author Onowu Chris
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feegs as our library
 */
contract FundMe {
    // Type declaration
    using PriceConverter for uint256;

    // State variables
    mapping(address => uint256 ) public addressToAmountFunded;
    address[] public funders;
    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        // require(i_owner == msg.sender, "Sender not owner");
        if(i_owner != msg.sender) {revert FundMe__NotOwner();}
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }


    // modifier's are like guards that are ran before a function or variable it's modifying is evaluated
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feegs as our library
     */
    function fund() public payable {
        // Waant to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract ?
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!"); // 1Eth == 1e18 == 1 * 10 ** 18
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        /* startIndex; endIndex; steps*/
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset Array
        funders = new address[](0);
        // 3 ways to Withdraw funds
        // 1. transfer
            // msg.sender is of type uint256
            // payable is of type payable
        /*
        payable( msg.sender ).transfer(address(this).balance);
        */

        // 2. send : will return a boolean for the transaction which has to be handled with the key word require
        /* 
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed !!");
        */

        //  3. call
        (bool sendSuccess,/* bytes memory dataReturned */) = payable(msg.sender).call{value: address(this).balance}("");
        require(sendSuccess, "Call failed !!");
    }

}