// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title BugToken ($BUG)
 * @dev ERC20 token powering the Bugtopia evolutionary economy
 * 
 * Core Features:
 * - Deflationary tokenomics with multiple burn mechanisms
 * - Staking rewards for ecosystem participation
 * - Gas-optimized for high-frequency game transactions
 * - Multi-utility token (breeding, staking, governance, premium features)
 */
contract BugToken is ERC20, ERC20Burnable, Ownable, Pausable, ReentrancyGuard {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS & CONFIGURATION
    // ═══════════════════════════════════════════════════════════════
    
    /// @dev Total supply: 1 billion tokens with 18 decimals
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;
    
    /// @dev Annual emission rate for staking rewards (2%)
    uint256 public constant ANNUAL_EMISSION_RATE = 200; // 2% = 200/10000
    
    /// @dev Emission rate denominator for precise calculations
    uint256 public constant EMISSION_DENOMINATOR = 10_000;
    
    /// @dev Maximum burn rate to prevent excessive deflation (50%)
    uint256 public constant MAX_BURN_RATE = 5000; // 50% = 5000/10000
    
    // ═══════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════
    
    /// @dev Authorized contracts that can burn tokens (utility functions)
    mapping(address => bool) public authorizedBurners;
    
    /// @dev Authorized contracts that can mint emission rewards
    mapping(address => bool) public authorizedMinters;
    
    /// @dev Track total tokens burned for economic analysis
    uint256 public totalBurned;
    
    /// @dev Last emission timestamp for annual rewards calculation
    uint256 public lastEmissionTime;
    
    /// @dev Total emission tokens minted (for supply tracking)
    uint256 public totalEmissionMinted;
    
    /// @dev Burn rates for different utility functions (basis points)
    mapping(bytes32 => uint256) public burnRates;
    
    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    event AuthorizedBurnerUpdated(address indexed burner, bool authorized);
    event AuthorizedMinterUpdated(address indexed minter, bool authorized);
    event BurnRateUpdated(bytes32 indexed utilityType, uint256 newRate);
    event UtilityBurn(address indexed user, bytes32 indexed utilityType, uint256 amount, uint256 burnAmount);
    event EmissionMinted(address indexed recipient, uint256 amount);
    
    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════
    
    error UnauthorizedBurner();
    error UnauthorizedMinter();
    error ExcessiveBurnRate();
    error InsufficientBalance();
    error InvalidAmount();
    error EmissionTooSoon();
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════
    
    constructor(
        address _initialOwner,
        uint256 _initialSupply
    ) 
        ERC20("Bugtopia", "BUG") 
        Ownable(_initialOwner)
    {
        require(_initialSupply <= MAX_SUPPLY, "Exceeds max supply");
        
        // Mint initial supply to owner for distribution
        _mint(_initialOwner, _initialSupply);
        
        // Initialize emission timestamp
        lastEmissionTime = block.timestamp;
        
        // Set default burn rates for utility functions
        burnRates["BREEDING"] = 1500;      // 15% for cross-species breeding
        burnRates["NEURAL_BOOST"] = 2500;  // 25% for AI acceleration  
        burnRates["ARENA_ENTRY"] = 1000;   // 10% for tournament entry
        burnRates["GOVERNANCE"] = 500;     // 5% for DAO proposals
        burnRates["ARTIFACTS"] = 2000;     // 20% for artifact crafting
        burnRates["MUTATION"] = 3000;      // 30% for forced mutations
    }
    
    // ═══════════════════════════════════════════════════════════════
    // UTILITY FUNCTIONS (BURN MECHANISMS)
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Burn tokens for utility function usage with configurable burn rates
     * @param user Address paying the utility fee
     * @param utilityType Type of utility function (breeding, arena, etc.)
     * @param amount Total amount being spent
     * @return burnAmount Amount of tokens burned
     * @return remainingAmount Amount of tokens available for other purposes
     */
    function utilityBurn(
        address user,
        bytes32 utilityType,
        uint256 amount
    ) 
        external 
        whenNotPaused 
        nonReentrant 
        returns (uint256 burnAmount, uint256 remainingAmount) 
    {
        if (!authorizedBurners[msg.sender]) revert UnauthorizedBurner();
        if (amount == 0) revert InvalidAmount();
        if (balanceOf(user) < amount) revert InsufficientBalance();
        
        // Calculate burn amount based on utility type
        uint256 burnRate = burnRates[utilityType];
        burnAmount = (amount * burnRate) / EMISSION_DENOMINATOR;
        remainingAmount = amount - burnAmount;
        
        // Transfer total amount from user to this contract
        _transfer(user, address(this), amount);
        
        // Burn the calculated amount
        if (burnAmount > 0) {
            _burn(address(this), burnAmount);
            totalBurned += burnAmount;
        }
        
        emit UtilityBurn(user, utilityType, amount, burnAmount);
        
        return (burnAmount, remainingAmount);
    }
    
    /**
     * @dev Batch utility burn for multiple operations (gas optimization)
     * @param users Array of user addresses
     * @param utilityTypes Array of utility types
     * @param amounts Array of amounts
     * @return totalBurnAmount Total amount burned across all operations
     */
    function batchUtilityBurn(
        address[] calldata users,
        bytes32[] calldata utilityTypes,
        uint256[] calldata amounts
    ) 
        external 
        whenNotPaused 
        nonReentrant 
        returns (uint256 totalBurnAmount) 
    {
        if (!authorizedBurners[msg.sender]) revert UnauthorizedBurner();
        require(
            users.length == utilityTypes.length && 
            users.length == amounts.length, 
            "Array length mismatch"
        );
        
        for (uint256 i = 0; i < users.length; i++) {
            (uint256 burnAmount,) = _singleUtilityBurn(users[i], utilityTypes[i], amounts[i]);
            totalBurnAmount += burnAmount;
        }
        
        return totalBurnAmount;
    }
    
    /**
     * @dev Internal function for single utility burn (used in batch operations)
     */
    function _singleUtilityBurn(
        address user,
        bytes32 utilityType,
        uint256 amount
    ) internal returns (uint256 burnAmount, uint256 remainingAmount) {
        if (balanceOf(user) < amount) revert InsufficientBalance();
        
        uint256 burnRate = burnRates[utilityType];
        burnAmount = (amount * burnRate) / EMISSION_DENOMINATOR;
        remainingAmount = amount - burnAmount;
        
        _transfer(user, address(this), amount);
        
        if (burnAmount > 0) {
            _burn(address(this), burnAmount);
            totalBurned += burnAmount;
        }
        
        emit UtilityBurn(user, utilityType, amount, burnAmount);
        
        return (burnAmount, remainingAmount);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // STAKING EMISSION SYSTEM
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Mint emission rewards for staking participants
     * @param recipient Address receiving the emission rewards
     * @param amount Amount of emission rewards to mint
     */
    function mintEmissionRewards(
        address recipient,
        uint256 amount
    ) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        if (!authorizedMinters[msg.sender]) revert UnauthorizedMinter();
        if (amount == 0) revert InvalidAmount();
        
        // Check if we can mint emission (respects annual emission rate)
        uint256 timeElapsed = block.timestamp - lastEmissionTime;
        uint256 maxEmission = _calculateMaxEmission(timeElapsed);
        
        require(amount <= maxEmission, "Exceeds emission limit");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        // Mint emission rewards
        _mint(recipient, amount);
        totalEmissionMinted += amount;
        
        // Update last emission time proportionally
        uint256 emissionUsed = (amount * 365 days) / _calculateAnnualEmission();
        lastEmissionTime += emissionUsed;
        
        emit EmissionMinted(recipient, amount);
    }
    
    /**
     * @dev Calculate maximum emission allowed based on time elapsed
     * @param timeElapsed Time elapsed since last emission
     * @return maxEmission Maximum emission amount allowed
     */
    function _calculateMaxEmission(uint256 timeElapsed) internal view returns (uint256 maxEmission) {
        uint256 annualEmission = _calculateAnnualEmission();
        maxEmission = (annualEmission * timeElapsed) / 365 days;
        return maxEmission;
    }
    
    /**
     * @dev Calculate annual emission based on current total supply
     * @return annualEmission Annual emission amount
     */
    function _calculateAnnualEmission() internal view returns (uint256 annualEmission) {
        annualEmission = (totalSupply() * ANNUAL_EMISSION_RATE) / EMISSION_DENOMINATOR;
        return annualEmission;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Update authorized burner contracts
     * @param burner Address to update authorization for
     * @param authorized Whether the address is authorized to burn
     */
    function setAuthorizedBurner(address burner, bool authorized) external onlyOwner {
        authorizedBurners[burner] = authorized;
        emit AuthorizedBurnerUpdated(burner, authorized);
    }
    
    /**
     * @dev Update authorized minter contracts  
     * @param minter Address to update authorization for
     * @param authorized Whether the address is authorized to mint emissions
     */
    function setAuthorizedMinter(address minter, bool authorized) external onlyOwner {
        authorizedMinters[minter] = authorized;
        emit AuthorizedMinterUpdated(minter, authorized);
    }
    
    /**
     * @dev Update burn rate for specific utility type
     * @param utilityType Utility function type
     * @param newRate New burn rate in basis points (max 50%)
     */
    function setBurnRate(bytes32 utilityType, uint256 newRate) external onlyOwner {
        if (newRate > MAX_BURN_RATE) revert ExcessiveBurnRate();
        
        burnRates[utilityType] = newRate;
        emit BurnRateUpdated(utilityType, newRate);
    }
    
    /**
     * @dev Emergency pause function
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Emergency unpause function
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Withdraw remaining utility tokens for specific purposes
     * @param recipient Address to receive tokens
     * @param amount Amount to withdraw
     */
    function withdrawUtilityTokens(address recipient, uint256 amount) external onlyOwner {
        require(balanceOf(address(this)) >= amount, "Insufficient contract balance");
        _transfer(address(this), recipient, amount);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Get current circulating supply (total supply - burned tokens)
     * @return circulatingSupply Current circulating supply
     */
    function circulatingSupply() external view returns (uint256) {
        return totalSupply();
    }
    
    /**
     * @dev Get deflation rate based on burn vs emission
     * @return deflationRate Current deflation rate (positive = deflationary)
     */
    function getDeflationRate() external view returns (int256 deflationRate) {
        uint256 annualBurn = totalBurned; // Simplified calculation
        uint256 annualEmission = _calculateAnnualEmission();
        
        if (annualBurn > annualEmission) {
            deflationRate = int256(annualBurn - annualEmission);
        } else {
            deflationRate = -int256(annualEmission - annualBurn);
        }
        
        return deflationRate;
    }
    
    /**
     * @dev Get utility burn rate for specific function
     * @param utilityType Utility function type
     * @return burnRate Burn rate in basis points
     */
    function getBurnRate(bytes32 utilityType) external view returns (uint256) {
        return burnRates[utilityType];
    }
    
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
    ) external view returns (uint256 burnAmount, uint256 remainingAmount) {
        uint256 burnRate = burnRates[utilityType];
        burnAmount = (amount * burnRate) / EMISSION_DENOMINATOR;
        remainingAmount = amount - burnAmount;
        return (burnAmount, remainingAmount);
    }
}
