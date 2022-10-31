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
  mapping(address => uint256) private s_addressToAmountFunded;
  address[] private s_funders;
  address private immutable i_owner;
  uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
  AggregatorV3Interface private s_priceFeed;

  modifier onlyOwner() {
    require(msg.sender == i_owner, "Sender not owner");
    // if(msg.sender != i_owner) {revert FundMe__NotOwner();}
    _;
  }

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
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
    require(
      msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
      "You need to spend more ETH!"
    ); // 1Eth == 1e18 == 1 * 10 ** 18
    s_addressToAmountFunded[msg.sender] += msg.value;
    s_funders.push(msg.sender);
  }

  function withdraw() public payable onlyOwner {
    /* startIndex; endIndex; steps*/
    for (
      uint256 funderIndex = 0;
      funderIndex < s_funders.length;
      funderIndex++
    ) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }

    // reset Array
    s_funders = new address[](0);
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
    (
      bool sendSuccess, /* bytes memory dataReturned */

    ) = payable(msg.sender).call{value: address(this).balance}("");
    require(sendSuccess, "Transfer failed !!");
  }

  function cheaperWithdrawer() public payable onlyOwner {
    address[] memory funders = s_funders;
    // mappings can't be in memory
    for (uint256 funderIndex = 0;
      funderIndex < funders.length;
      funderIndex++
      ) {
        address funder = funders[funderIndex];
        s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
    (bool success, ) = i_owner.call{value: address(this).balance}("");
    require(success);
  }

  // view / pure functions
  
  function getOwner() public view returns (address) {
    return i_owner;
  }

  function getFunder(uint256 index) public view returns (address) {
    return s_funders[index];
  }

  function getAddressToAmountFunded(address funder) public view returns (uint256) {
    return s_addressToAmountFunded[funder];
  }

  function getPriceFeed() public view returns (AggregatorV3Interface) {
    return s_priceFeed;
  }
}
