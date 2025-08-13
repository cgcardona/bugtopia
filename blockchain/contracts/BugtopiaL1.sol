// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title BugtopiaL1
 * @dev Core contract for Bugtopia L1 native token economics
 * 
 * Since BUG is the native gas token on this L1:
 * - All transaction fees are paid in BUG
 * - Validator rewards are distributed in BUG
 * - This contract manages BUG economics beyond basic transfers
 */
contract BugtopiaL1 is Ownable, ReentrancyGuard, Pausable {
    
    // ============= EVENTS =============
    
    event BugBurned(address indexed burner, uint256 amount, string reason);
    event StakingRewardsDistributed(uint256 totalAmount, uint256 recipientCount);
    event UtilityFeePaid(address indexed payer, uint256 amount, string utilityType);
    event EconomicParameterUpdated(string parameter, uint256 oldValue, uint256 newValue);
    
    // ============= STATE VARIABLES =============
    
    /// @dev Total BUG burned (deflationary mechanism)
    uint256 public totalBugBurned;
    
    /// @dev Utility fee rates (basis points, 10000 = 100%)
    mapping(string => uint256) public utilityFees;
    
    /// @dev Burn rates for different activities (basis points)
    mapping(string => uint256) public burnRates;
    
    /// @dev Treasury for ecosystem development
    address public treasury;
    
    /// @dev Staking rewards pool
    uint256 public stakingRewardsPool;
    
    /// @dev Fee distribution ratios (basis points)
    uint256 public treasuryRatio = 3000; // 30%
    uint256 public stakingRatio = 4000;  // 40%
    uint256 public burnRatio = 3000;     // 30%
    
    // ============= CONSTRUCTOR =============
    
    constructor(address _treasury) Ownable(msg.sender) {
        treasury = _treasury;
        
        // Initialize utility fees (in wei, ~$0.001 equivalent)
        utilityFees["breeding"] = 0.001 ether;
        utilityFees["neural_boost"] = 0.0005 ether;
        utilityFees["arena_entry"] = 0.002 ether;
        utilityFees["governance_proposal"] = 0.01 ether;
        utilityFees["artifact_crafting"] = 0.003 ether;
        utilityFees["mutation_catalyst"] = 0.0015 ether;
        
        // Initialize burn rates (basis points)
        burnRates["breeding"] = 1500;        // 15%
        burnRates["neural_boost"] = 2000;    // 20%
        burnRates["arena_entry"] = 1000;     // 10%
        burnRates["governance"] = 2500;      // 25%
        burnRates["artifact_crafting"] = 3000; // 30%
        burnRates["mutation_catalyst"] = 2000; // 20%
    }
    
    // ============= CORE ECONOMICS =============
    
    /**
     * @dev Pay utility fee with automatic burning and distribution
     * @param utilityType Type of utility being paid for
     */
    function payUtilityFee(string memory utilityType) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
    {
        uint256 requiredFee = utilityFees[utilityType];
        require(msg.value >= requiredFee, "Insufficient fee payment");
        
        // Calculate distributions
        uint256 burnAmount = (msg.value * burnRates[utilityType]) / 10000;
        uint256 treasuryAmount = (msg.value * treasuryRatio) / 10000;
        uint256 stakingAmount = msg.value - burnAmount - treasuryAmount;
        
        // Execute distributions
        if (burnAmount > 0) {
            _burnBug(burnAmount, utilityType);
        }
        
        if (treasuryAmount > 0) {
            payable(treasury).transfer(treasuryAmount);
        }
        
        if (stakingAmount > 0) {
            stakingRewardsPool += stakingAmount;
        }
        
        // Refund excess
        if (msg.value > requiredFee) {
            payable(msg.sender).transfer(msg.value - requiredFee);
        }
        
        emit UtilityFeePaid(msg.sender, requiredFee, utilityType);
    }
    
    /**
     * @dev Burn BUG tokens (deflationary mechanism)
     * @param amount Amount to burn
     * @param reason Reason for burning
     */
    function burnBug(uint256 amount, string memory reason) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
    {
        require(msg.value >= amount, "Insufficient BUG to burn");
        _burnBug(amount, reason);
        
        // Refund excess
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }
    
    /**
     * @dev Internal burn function
     * @param amount Amount to burn
     * @param reason Reason for burning
     */
    function _burnBug(uint256 amount, string memory reason) internal {
        // On Avalanche L1, "burning" means sending to dead address
        // since we can't actually destroy native tokens
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        payable(deadAddress).transfer(amount);
        
        totalBugBurned += amount;
        emit BugBurned(msg.sender, amount, reason);
    }
    
    // ============= STAKING REWARDS =============
    
    /**
     * @dev Distribute staking rewards to validators/delegators
     * @param recipients List of reward recipients
     * @param amounts List of reward amounts
     */
    function distributeStakingRewards(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner nonReentrant {
        require(recipients.length == amounts.length, "Array length mismatch");
        
        uint256 totalDistribution = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalDistribution += amounts[i];
        }
        
        require(stakingRewardsPool >= totalDistribution, "Insufficient rewards pool");
        
        stakingRewardsPool -= totalDistribution;
        
        for (uint256 i = 0; i < recipients.length; i++) {
            if (amounts[i] > 0) {
                payable(recipients[i]).transfer(amounts[i]);
            }
        }
        
        emit StakingRewardsDistributed(totalDistribution, recipients.length);
    }
    
    // ============= ADMIN FUNCTIONS =============
    
    /**
     * @dev Update utility fee for specific utility type
     * @param utilityType Type of utility
     * @param newFee New fee amount in wei
     */
    function updateUtilityFee(string memory utilityType, uint256 newFee) 
        external 
        onlyOwner 
    {
        uint256 oldFee = utilityFees[utilityType];
        utilityFees[utilityType] = newFee;
        emit EconomicParameterUpdated(
            string(abi.encodePacked("utilityFee_", utilityType)), 
            oldFee, 
            newFee
        );
    }
    
    /**
     * @dev Update burn rate for specific activity
     * @param activity Activity type
     * @param newRate New burn rate in basis points
     */
    function updateBurnRate(string memory activity, uint256 newRate) 
        external 
        onlyOwner 
    {
        require(newRate <= 5000, "Burn rate too high"); // Max 50%
        uint256 oldRate = burnRates[activity];
        burnRates[activity] = newRate;
        emit EconomicParameterUpdated(
            string(abi.encodePacked("burnRate_", activity)), 
            oldRate, 
            newRate
        );
    }
    
    /**
     * @dev Update fee distribution ratios
     * @param _treasuryRatio New treasury ratio (basis points)
     * @param _stakingRatio New staking ratio (basis points) 
     * @param _burnRatio New burn ratio (basis points)
     */
    function updateFeeDistribution(
        uint256 _treasuryRatio,
        uint256 _stakingRatio,
        uint256 _burnRatio
    ) external onlyOwner {
        require(_treasuryRatio + _stakingRatio + _burnRatio == 10000, "Ratios must sum to 100%");
        
        treasuryRatio = _treasuryRatio;
        stakingRatio = _stakingRatio;
        burnRatio = _burnRatio;
    }
    
    /**
     * @dev Update treasury address
     * @param newTreasury New treasury address
     */
    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        treasury = newTreasury;
    }
    
    /**
     * @dev Emergency pause
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // ============= VIEW FUNCTIONS =============
    
    /**
     * @dev Get utility fee for specific type
     * @param utilityType Type of utility
     * @return Fee amount in wei
     */
    function getUtilityFee(string memory utilityType) external view returns (uint256) {
        return utilityFees[utilityType];
    }
    
    /**
     * @dev Get burn rate for specific activity
     * @param activity Activity type
     * @return Burn rate in basis points
     */
    function getBurnRate(string memory activity) external view returns (uint256) {
        return burnRates[activity];
    }
    
    /**
     * @dev Get current economic parameters
     * @return totalBurned Total BUG burned
     * @return rewardsPool Current staking rewards pool
     * @return treasuryAddr Treasury address
     */
    function getEconomicState() external view returns (
        uint256 totalBurned,
        uint256 rewardsPool,
        address treasuryAddr
    ) {
        return (totalBugBurned, stakingRewardsPool, treasury);
    }
    
    // ============= FALLBACK =============
    
    /**
     * @dev Accept BUG deposits to staking rewards pool
     */
    receive() external payable {
        stakingRewardsPool += msg.value;
    }
}
