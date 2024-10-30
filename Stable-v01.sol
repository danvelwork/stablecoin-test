// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract USDXToken is ERC20 {
    AggregatorV3Interface internal priceFeed; // Chainlink price feed for ETH/USD

    mapping(address => uint256) public collateralDeposits; // Track user deposits

    constructor() ERC20("USDX Stablecoin", "USDX") {
        // Chainlink ETH/USD price feed address (make sure it's correct for your network)
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // Replace with appropriate address
    }

    // Mint USDX by providing ETH as collateral
    function mint(uint256 amount) external payable {
        uint256 requiredAmount = requiredCollateral(amount);
        require(msg.value >= requiredAmount, "Insufficient collateral");
        collateralDeposits[msg.sender] += msg.value;
        _mint(msg.sender, amount);
    }

    // Redeem USDX for collateral
    function redeem(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient USDX balance");
        uint256 collateralToReturn = (amount * getWeiPerUSD()); // Amount of collateral in wei
        require(collateralDeposits[msg.sender] >= collateralToReturn, "Insufficient collateral for redemption");
        
        collateralDeposits[msg.sender] -= collateralToReturn;
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(collateralToReturn);
    }

    // Helper: get latest ETH/USD price, scaled to 18 decimals
    function getLatestPrice() public view returns (uint256) {
        (, int price, , ,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price returned");
        
        // Convert price to 18 decimals (ETH price in wei)
        return uint256(price) * 1e10; // This returns the price of 1 ETH in wei
    }

   // Get the value of 1 USD in wei
function getWeiPerUSD() public view returns (uint256) {
    uint256 ethPriceInWei = getLatestPrice(); // Get ETH price in wei
    require(ethPriceInWei > 0, "ETH price must be greater than zero");
    
    // Calculate how much 1 USD is worth in wei
    // Avoiding overflow and ensuring we get a meaningful value
    return (1e18 * 1e10) / ethPriceInWei; // Scale to 18 decimals
}


    // Calculate required collateral based on amount of USDX to mint
    function requiredCollateral(uint256 amount) public view returns (uint256) {
        return (amount * getWeiPerUSD()*10e7); // Amount of collateral required in wei
    }
}
