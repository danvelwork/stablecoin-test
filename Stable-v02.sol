// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleStablecoin is ERC20 {
    AggregatorV3Interface internal priceFeed;

    constructor() ERC20("Simple Stablecoin", "STABLE") {
        _setupDecimals(6); // Set decimals to 6 for USD representation
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD price feed address
    }

    // Get the latest ETH price in USD, scaled to 8 decimals
    function getLatestPrice() public view returns (uint256) {
        (, int price, , ,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price returned");
        return uint256(price); // Price has 8 decimals from Chainlink
    }

    // Calculate and mint the USD stablecoin amount based on deposited ETH
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH to mint stablecoins");

        uint256 ethPriceInUsd = getLatestPrice(); // ETH price in USD with 8 decimals
        uint256 stablecoinAmount = (msg.value * ethPriceInUsd) / 1e8; // Calculate stablecoin amount with 6 decimals

        _mint(msg.sender, stablecoinAmount); // Mint the calculated amount of stablecoins
    }

    // Redeem stablecoins for ETH
    function redeem(uint256 stablecoinAmount) external {
        require(balanceOf(msg.sender) >= stablecoinAmount, "Insufficient balance");

        uint256 ethPriceInUsd = getLatestPrice(); // Get the latest ETH/USD price
        uint256 ethAmount = (stablecoinAmount * 1e8) / ethPriceInUsd; // Convert stablecoins to ETH

        require(address(this).balance >= ethAmount, "Insufficient contract balance");

        _burn(msg.sender, stablecoinAmount); // Burn the stablecoins
        payable(msg.sender).transfer(ethAmount); // Transfer ETH to the user
    }

    // Fallback function to receive ETH directly
    receive() external payable {}
}
