// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IBugToken
 * @dev Interface for the $BUG token contract
 */
interface IBugToken is IERC20 {
    
    /**
     * @dev Burn tokens for utility function usage
     * @param user Address paying the utility fee
     * @param utilityType Type of utility function
     * @param amount Total amount being spent
     * @return burnAmount Amount of tokens burned
     * @return remainingAmount Amount of tokens available for other purposes
     */
    function utilityBurn(
        address user,
        bytes32 utilityType,
        uint256 amount
    ) external returns (uint256 burnAmount, uint256 remainingAmount);
    
    /**
     * @dev Mint emission rewards for staking participants
     * @param recipient Address receiving the emission rewards
     * @param amount Amount of emission rewards to mint
     */
    function mintEmissionRewards(address recipient, uint256 amount) external;
    
    /**
     * @dev Get burn rate for specific utility type
     * @param utilityType Utility function type
     * @return burnRate Burn rate in basis points
     */
    function getBurnRate(bytes32 utilityType) external view returns (uint256);
    
    /**
     * @dev Calculate burn amount for given utility and amount
     * @param utilityType Utility function type
     * @param amount Total amount being spent
     * @return burnAmount Amount that would be burned
     * @return remainingAmount Amount that would remain
     */
    function calculateBurnAmount(
        bytes32 utilityType, 
        uint256 amount
    ) external view returns (uint256 burnAmount, uint256 remainingAmount);
    
    /**
     * @dev Get current circulating supply
     * @return circulatingSupply Current circulating supply
     */
    function circulatingSupply() external view returns (uint256);
    
    /**
     * @dev Get total tokens burned
     * @return totalBurned Total amount burned
     */
    function totalBurned() external view returns (uint256);
}
