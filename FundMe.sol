// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//the import statement above would import all of the interface code below
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract FundMe 
{
  //uses import statement above to make sure there is no overflow and that int256 does not wrap around
  using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() public          // things in contructor get initialized right away when deployed
    {
      owner = msg.sender;
    }

    function fund() public payable 
    {
        uint256 minimumUSD = 50 * 10 ** 18; //$50 (x 10^18 for gwei) minimum
        require(getConversionRate(msg.value) >= minimumUSD, "Not Enough ETH, Minimum is $50 USD!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        //ETH -> USD conversion rate
    }

    function getVersion() public view returns (uint256)
    {
        //eth->usd address below found at: https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        priceFeed.version();
    }

    function getPrice() public view returns(uint256)
    {
        AggregatorV3Interface priceFeed =  AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (uint80 roundId,
         int256 answer,
         uint256 startedAt,
         uint256 updatedAt,               //5 diffrent variables set for priceFeed, only need answer
         uint80 answeredInRound)
         = priceFeed.latestRoundData();
         return uint256(answer * 10000000000);           //typecast
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function withdraw() payable public
    {
        //if you only want contract owner to be able to withdraw funds:
        require(msg.sender == owner, "Only Owner of the Contract can Withdraw ETH!");
        msg.sender.transfer(address(this).balance);
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++)
        {
          address funder = funders[funderIndex];
          addressToAmountFunded[funder] = 0;   //resets the values each funder funded
        }
        funders = new address[](0);     // resets funder array by setting it to a new blamk array
    }
}