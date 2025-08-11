// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBugToken.sol";

/**
 * @title TerritoryNFT
 * @dev ERC721 NFTs representing territorial control in Bugtopia's 3D world
 * 
 * Core Features:
 * - 3D territory ownership with multi-layer bounds
 * - Staking mechanism for territory claims ($BUG token required)
 * - Revenue sharing from biome activities
 * - Territory quality assessment and valuation
 * - Population migration and territorial conflicts
 */
contract TerritoryNFT is 
    ERC721, 
    ERC721Enumerable, 
    ERC721URIStorage, 
    Ownable, 
    Pausable, 
    ReentrancyGuard 
{
    using Counters for Counters.Counter;
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS & ENUMS
    // ═══════════════════════════════════════════════════════════════
    
    /// @dev Biome types matching Bugtopia simulation
    enum BiomeType { 
        Desert, Forest, Mountain, Volcanic, Archipelago, 
        Wetland, Grassland, Tundra, Coastal 
    }
    
    /// @dev Terrain layers for 3D territories
    enum TerrainLayer { Underground, Surface, Canopy, Aerial }
    
    /// @dev Territory quality tiers
    enum QualityTier { Poor, Fair, Good, Excellent, Prime }
    
    // ═══════════════════════════════════════════════════════════════
    // STRUCTS  
    // ═══════════════════════════════════════════════════════════════
    
    /// @dev 3D coordinate system
    struct Coordinate3D {
        int256 x;
        int256 y;
        int256 z;
    }
    
    /// @dev Territory boundaries in 3D space
    struct TerritoryBounds {
        Coordinate3D minBounds;     // Minimum coordinates (x, y, z)
        Coordinate3D maxBounds;     // Maximum coordinates (x, y, z)
        uint256 totalVolume;        // Calculated 3D volume
        TerrainLayer primaryLayer;  // Dominant terrain layer
        TerrainLayer[] accessibleLayers; // All accessible layers
    }
    
    /// @dev Resource abundance in territory
    struct ResourceData {
        uint256 vegetation;         // Plant matter availability (0-10000)
        uint256 minerals;           // Stone/metal resources (0-10000)
        uint256 water;              // Water sources (0-10000)
        uint256 insects;            // Micro-fauna density (0-10000)
        uint256 nectar;             // Floral resources (0-10000)
        uint256 seeds;              // Plantable resources (0-10000)
        uint256 fungi;              // Decomposer density (0-10000)
        uint256 detritus;           // Organic waste (0-10000)
    }
    
    /// @dev Territory quality metrics
    struct QualityMetrics {
        QualityTier overallTier;        // Overall quality assessment
        uint256 resourceAbundance;      // Total resource score (0-10000)
        uint256 safetyRating;           // Predator/disaster safety (0-10000)
        uint256 carryingCapacity;       // Max sustainable population
        uint256 accessibility;          // Movement difficulty (0-10000)
        uint256 strategicValue;         // Location advantage (0-10000)
        uint256 lastAssessment;         // Timestamp of last quality update
    }
    
    /// @dev Population activity tracking
    struct PopulationData {
        uint256 currentPopulation;      // Active bug count
        uint256 maxPopulation;          // Historical peak
        uint256 populationPressure;     // Overcrowding metric (0-10000)
        uint256 migrationRate;          // In/out migration rate
        uint256 breedingActivity;       // Reproductive events
        uint256 territorialConflicts;   // Border disputes
        string dominantSpecies;         // Most common species name
    }
    
    /// @dev Revenue and staking data
    struct StakingData {
        uint256 stakedAmount;           // $BUG tokens staked
        uint256 stakingTimestamp;       // When staking began
        uint256 accumulatedRewards;     // Unclaimed rewards
        uint256 revenueGenerated;       // Total revenue from territory
        uint256 lastRewardClaim;        // Last reward claim timestamp
        bool isActive;                  // Whether staking is active
    }
    
    /// @dev Complete territory data
    struct TerritoryData {
        string name;                    // Territory name
        BiomeType biomeType;            // Primary biome
        TerritoryBounds bounds;         // 3D spatial boundaries
        ResourceData resources;         // Resource availability
        QualityMetrics quality;         // Quality assessment
        PopulationData population;      // Population statistics
        StakingData staking;            // Revenue and staking info
        uint256 mintTimestamp;          // NFT creation time
        uint256 lastUpdateTimestamp;    // Last data update
        string[] connectedTerritories;  // Adjacent territory names
    }
    
    // ═══════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    /// @dev Reference to $BUG token contract
    IBugToken public immutable bugToken;
    
    /// @dev Territory data for each token ID
    mapping(uint256 => TerritoryData) public territories;
    
    /// @dev Authorized simulation contracts
    mapping(address => bool) public authorizedUpdaters;
    
    /// @dev Staking requirements by biome type (in $BUG tokens)
    mapping(BiomeType => uint256) public stakingRequirements;
    
    /// @dev Revenue share rates by biome type (basis points)
    mapping(BiomeType => uint256) public revenueShareRates;
    
    /// @dev Biome activity revenue pools
    mapping(BiomeType => uint256) public biomeRevenuePools;
    
    /// @dev Territory name to token ID mapping
    mapping(string => uint256) public territoryNameToTokenId;
    
    /// @dev Quality tier distribution
    mapping(QualityTier => uint256) public qualityTierCount;
    
    /// @dev Total staked tokens per biome
    mapping(BiomeType => uint256) public totalStakedPerBiome;
    
    /// @dev Base URI for metadata
    string private _baseTokenURI;
    
    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    event TerritoryMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string name,
        BiomeType biomeType,
        QualityTier qualityTier,
        uint256 volume
    );
    
    event TerritoryStaked(
        uint256 indexed tokenId,
        address indexed staker,
        uint256 amount,
        BiomeType biomeType
    );
    
    event TerritoryUnstaked(
        uint256 indexed tokenId,
        address indexed staker,
        uint256 amount,
        uint256 rewards
    );
    
    event RevenueDistributed(
        BiomeType indexed biomeType,
        uint256 totalRevenue,
        uint256 distributedAmount,
        uint256 stakeholderCount
    );
    
    event QualityUpdated(
        uint256 indexed tokenId,
        QualityTier oldTier,
        QualityTier newTier,
        uint256 newResourceScore
    );
    
    event PopulationUpdated(
        uint256 indexed tokenId,
        uint256 newPopulation,
        uint256 populationPressure,
        string dominantSpecies
    );
    
    event AuthorizedUpdaterChanged(address indexed updater, bool authorized);
    event StakingRequirementUpdated(BiomeType biomeType, uint256 newRequirement);
    event RevenueShareRateUpdated(BiomeType biomeType, uint256 newRate);
    
    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════
    
    error UnauthorizedUpdater();
    error InvalidTokenId();
    error TerritoryNameTaken();
    error InsufficientStaking();
    error NotStaked();
    error NoRewardsToClaim();
    error InvalidBiomeType();
    error InvalidCoordinates();
    error InvalidQualityData();
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════
    
    constructor(
        address _bugTokenAddress,
        address _initialOwner,
        string memory _initialBaseURI
    ) 
        ERC721("Bugtopia Territory", "TERRITORY") 
        Ownable(_initialOwner)
    {
        bugToken = IBugToken(_bugTokenAddress);
        _baseTokenURI = _initialBaseURI;
        
        // Initialize staking requirements and revenue rates
        _initializeStakingParameters();
        
        // Start token IDs at 1
        _tokenIdCounter.increment();
    }
    
    /**
     * @dev Initialize staking requirements and revenue share rates
     */
    function _initializeStakingParameters() internal {
        // Staking requirements (in $BUG tokens with 18 decimals)
        uint256 baseStake = 1000 * 10**18; // 1000 $BUG base
        
        stakingRequirements[BiomeType.Desert] = baseStake;
        stakingRequirements[BiomeType.Grassland] = baseStake * 12 / 10;  // 1200
        stakingRequirements[BiomeType.Forest] = baseStake * 25 / 10;     // 2500
        stakingRequirements[BiomeType.Wetland] = baseStake * 35 / 10;    // 3500
        stakingRequirements[BiomeType.Mountain] = baseStake * 5;         // 5000
        stakingRequirements[BiomeType.Archipelago] = baseStake * 75 / 10; // 7500
        stakingRequirements[BiomeType.Volcanic] = baseStake * 10;        // 10000
        stakingRequirements[BiomeType.Coastal] = baseStake * 45 / 10;    // 4500
        stakingRequirements[BiomeType.Tundra] = baseStake * 3;           // 3000
        
        // Revenue share rates (basis points - percentage of biome activity fees)
        revenueShareRates[BiomeType.Desert] = 500;      // 5%
        revenueShareRates[BiomeType.Grassland] = 600;   // 6%
        revenueShareRates[BiomeType.Forest] = 700;      // 7%
        revenueShareRates[BiomeType.Wetland] = 900;     // 9%
        revenueShareRates[BiomeType.Mountain] = 1000;   // 10%
        revenueShareRates[BiomeType.Archipelago] = 1200; // 12%
        revenueShareRates[BiomeType.Volcanic] = 1500;   // 15%
        revenueShareRates[BiomeType.Coastal] = 1100;    // 11%
        revenueShareRates[BiomeType.Tundra] = 800;      // 8%
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MINTING & TERRITORY CREATION
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Mint new territory NFT from simulation data
     * @param to Address to receive the NFT
     * @param territoryData Complete territory information
     * @return tokenId Newly minted token ID
     */
    function mintTerritory(
        address to,
        TerritoryData memory territoryData
    ) 
        external 
        whenNotPaused 
        nonReentrant 
        returns (uint256 tokenId) 
    {
        if (!authorizedUpdaters[msg.sender]) revert UnauthorizedUpdater();
        if (territoryNameToTokenId[territoryData.name] != 0) revert TerritoryNameTaken();
        
        // Validate territory data
        _validateTerritoryData(territoryData);
        
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        // Set timestamps
        territoryData.mintTimestamp = block.timestamp;
        territoryData.lastUpdateTimestamp = block.timestamp;
        
        // Store territory data
        territories[tokenId] = territoryData;
        territoryNameToTokenId[territoryData.name] = tokenId;
        
        // Update tracking
        qualityTierCount[territoryData.quality.overallTier]++;
        
        // Mint NFT
        _safeMint(to, tokenId);
        
        emit TerritoryMinted(
            tokenId,
            to,
            territoryData.name,
            territoryData.biomeType,
            territoryData.quality.overallTier,
            territoryData.bounds.totalVolume
        );
        
        return tokenId;
    }
    
    /**
     * @dev Validate territory data before minting
     */
    function _validateTerritoryData(TerritoryData memory data) internal pure {
        // Validate coordinates
        if (data.bounds.minBounds.x >= data.bounds.maxBounds.x ||
            data.bounds.minBounds.y >= data.bounds.maxBounds.y ||
            data.bounds.minBounds.z >= data.bounds.maxBounds.z) {
            revert InvalidCoordinates();
        }
        
        // Validate resource values
        if (data.resources.vegetation > 10000 || 
            data.resources.minerals > 10000 ||
            data.resources.water > 10000) {
            revert InvalidQualityData();
        }
        
        // Validate quality metrics
        if (data.quality.resourceAbundance > 10000 ||
            data.quality.safetyRating > 10000 ||
            data.quality.accessibility > 10000) {
            revert InvalidQualityData();
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // STAKING MECHANISM
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Stake $BUG tokens to claim territory and earn revenue
     * @param tokenId Territory NFT to stake on
     * @param amount Amount of $BUG tokens to stake
     */
    function stakeTerritory(
        uint256 tokenId,
        uint256 amount
    ) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        if (!_exists(tokenId)) revert InvalidTokenId();
        
        TerritoryData storage territory = territories[tokenId];
        BiomeType biomeType = territory.biomeType;
        
        // Check minimum staking requirement
        uint256 requiredStake = stakingRequirements[biomeType];
        if (amount < requiredStake) revert InsufficientStaking();
        
        // Transfer $BUG tokens from user
        require(
            bugToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        
        // Update staking data
        territory.staking.stakedAmount += amount;
        territory.staking.stakingTimestamp = block.timestamp;
        territory.staking.lastRewardClaim = block.timestamp;
        territory.staking.isActive = true;
        territory.lastUpdateTimestamp = block.timestamp;
        
        // Update global tracking
        totalStakedPerBiome[biomeType] += amount;
        
        // Transfer NFT to staker if not already owned
        if (ownerOf(tokenId) != msg.sender) {
            _transfer(ownerOf(tokenId), msg.sender, tokenId);
        }
        
        emit TerritoryStaked(tokenId, msg.sender, amount, biomeType);
    }
    
    /**
     * @dev Unstake $BUG tokens and claim accumulated rewards
     * @param tokenId Territory NFT to unstake
     */
    function unstakeTerritory(uint256 tokenId) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (ownerOf(tokenId) != msg.sender) revert("Not owner");
        
        TerritoryData storage territory = territories[tokenId];
        
        if (!territory.staking.isActive || territory.staking.stakedAmount == 0) {
            revert NotStaked();
        }
        
        // Calculate accumulated rewards
        uint256 pendingRewards = _calculatePendingRewards(tokenId);
        uint256 totalReturn = territory.staking.stakedAmount + pendingRewards;
        
        // Update state
        BiomeType biomeType = territory.biomeType;
        totalStakedPerBiome[biomeType] -= territory.staking.stakedAmount;
        
        uint256 stakedAmount = territory.staking.stakedAmount;
        territory.staking.stakedAmount = 0;
        territory.staking.accumulatedRewards = 0;
        territory.staking.isActive = false;
        territory.lastUpdateTimestamp = block.timestamp;
        
        // Transfer tokens back to user
        require(bugToken.transfer(msg.sender, totalReturn), "Transfer failed");
        
        emit TerritoryUnstaked(tokenId, msg.sender, stakedAmount, pendingRewards);
    }
    
    /**
     * @dev Claim accumulated staking rewards without unstaking
     * @param tokenId Territory NFT to claim rewards for
     */
    function claimRewards(uint256 tokenId) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (ownerOf(tokenId) != msg.sender) revert("Not owner");
        
        TerritoryData storage territory = territories[tokenId];
        
        if (!territory.staking.isActive) revert NotStaked();
        
        uint256 pendingRewards = _calculatePendingRewards(tokenId);
        if (pendingRewards == 0) revert NoRewardsToClaim();
        
        // Update reward tracking
        territory.staking.accumulatedRewards = 0;
        territory.staking.lastRewardClaim = block.timestamp;
        territory.lastUpdateTimestamp = block.timestamp;
        
        // Transfer rewards
        require(bugToken.transfer(msg.sender, pendingRewards), "Transfer failed");
    }
    
    /**
     * @dev Calculate pending rewards for staked territory
     * @param tokenId Territory NFT to calculate rewards for
     * @return pendingRewards Amount of pending rewards
     */
    function _calculatePendingRewards(uint256 tokenId) internal view returns (uint256) {
        TerritoryData storage territory = territories[tokenId];
        
        if (!territory.staking.isActive) return 0;
        
        // Time-based rewards (simplified calculation)
        uint256 timeStaked = block.timestamp - territory.staking.lastRewardClaim;
        uint256 baseReward = (territory.staking.stakedAmount * revenueShareRates[territory.biomeType]) / 10000;
        
        // Annual yield: ~8-15% APY based on biome
        uint256 annualReward = (baseReward * timeStaked) / 365 days;
        
        // Add territory-specific bonuses
        uint256 qualityBonus = _calculateQualityBonus(territory.quality.overallTier);
        uint256 bonusReward = (annualReward * qualityBonus) / 10000;
        
        return territory.staking.accumulatedRewards + annualReward + bonusReward;
    }
    
    /**
     * @dev Calculate quality bonus for staking rewards
     */
    function _calculateQualityBonus(QualityTier tier) internal pure returns (uint256) {
        if (tier == QualityTier.Prime) return 2000;     // 20% bonus
        if (tier == QualityTier.Excellent) return 1000; // 10% bonus
        if (tier == QualityTier.Good) return 500;       // 5% bonus
        if (tier == QualityTier.Fair) return 200;       // 2% bonus
        return 0; // Poor quality gets no bonus
    }
    
    // ═══════════════════════════════════════════════════════════════
    // REVENUE DISTRIBUTION
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Distribute revenue from biome activities to stakeholders
     * @param biomeType Biome that generated revenue
     * @param totalRevenue Total revenue to distribute
     */
    function distributeRevenue(
        BiomeType biomeType,
        uint256 totalRevenue
    ) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        if (!authorizedUpdaters[msg.sender]) revert UnauthorizedUpdater();
        if (totalRevenue == 0) return;
        
        // Add to biome revenue pool
        biomeRevenuePools[biomeType] += totalRevenue;
        
        // Calculate distribution amount
        uint256 shareRate = revenueShareRates[biomeType];
        uint256 distributionAmount = (totalRevenue * shareRate) / 10000;
        
        // Track total staked in this biome
        uint256 totalStaked = totalStakedPerBiome[biomeType];
        if (totalStaked == 0) return; // No stakeholders to reward
        
        // Distribute proportionally to all staked territories in this biome
        uint256 stakeholderCount = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i)) {
                TerritoryData storage territory = territories[i];
                if (territory.biomeType == biomeType && territory.staking.isActive) {
                    uint256 stakingShare = (territory.staking.stakedAmount * distributionAmount) / totalStaked;
                    territory.staking.accumulatedRewards += stakingShare;
                    territory.staking.revenueGenerated += stakingShare;
                    stakeholderCount++;
                }
            }
        }
        
        emit RevenueDistributed(biomeType, totalRevenue, distributionAmount, stakeholderCount);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // TERRITORY UPDATES
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Update territory quality metrics from simulation
     * @param tokenId Territory to update
     * @param newResources Updated resource data
     * @param newQuality Updated quality metrics
     */
    function updateTerritoryQuality(
        uint256 tokenId,
        ResourceData memory newResources,
        QualityMetrics memory newQuality
    ) 
        external 
        whenNotPaused 
    {
        if (!authorizedUpdaters[msg.sender]) revert UnauthorizedUpdater();
        if (!_exists(tokenId)) revert InvalidTokenId();
        
        TerritoryData storage territory = territories[tokenId];
        QualityTier oldTier = territory.quality.overallTier;
        
        // Update data
        territory.resources = newResources;
        territory.quality = newQuality;
        territory.quality.lastAssessment = block.timestamp;
        territory.lastUpdateTimestamp = block.timestamp;
        
        // Update tier tracking if changed
        if (newQuality.overallTier != oldTier) {
            qualityTierCount[oldTier]--;
            qualityTierCount[newQuality.overallTier]++;
            
            emit QualityUpdated(tokenId, oldTier, newQuality.overallTier, newQuality.resourceAbundance);
        }
    }
    
    /**
     * @dev Update population data from simulation
     * @param tokenId Territory to update
     * @param populationData Updated population statistics
     */
    function updatePopulation(
        uint256 tokenId,
        PopulationData memory populationData
    ) 
        external 
        whenNotPaused 
    {
        if (!authorizedUpdaters[msg.sender]) revert UnauthorizedUpdater();
        if (!_exists(tokenId)) revert InvalidTokenId();
        
        TerritoryData storage territory = territories[tokenId];
        
        // Update population data
        territory.population = populationData;
        territory.lastUpdateTimestamp = block.timestamp;
        
        emit PopulationUpdated(
            tokenId,
            populationData.currentPopulation,
            populationData.populationPressure,
            populationData.dominantSpecies
        );
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Update authorized updater contracts
     */
    function setAuthorizedUpdater(address updater, bool authorized) external onlyOwner {
        authorizedUpdaters[updater] = authorized;
        emit AuthorizedUpdaterChanged(updater, authorized);
    }
    
    /**
     * @dev Update staking requirements for biome
     */
    function setStakingRequirement(BiomeType biomeType, uint256 newRequirement) external onlyOwner {
        stakingRequirements[biomeType] = newRequirement;
        emit StakingRequirementUpdated(biomeType, newRequirement);
    }
    
    /**
     * @dev Update revenue share rate for biome
     */
    function setRevenueShareRate(BiomeType biomeType, uint256 newRate) external onlyOwner {
        require(newRate <= 2000, "Rate too high"); // Max 20%
        revenueShareRates[biomeType] = newRate;
        emit RevenueShareRateUpdated(biomeType, newRate);
    }
    
    /**
     * @dev Update base URI for metadata
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }
    
    /**
     * @dev Emergency pause
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Emergency unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Get complete territory data
     */
    function getTerritoryData(uint256 tokenId) external view returns (TerritoryData memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return territories[tokenId];
    }
    
    /**
     * @dev Get pending rewards for territory
     */
    function getPendingRewards(uint256 tokenId) external view returns (uint256) {
        return _calculatePendingRewards(tokenId);
    }
    
    /**
     * @dev Get staking information for territory
     */
    function getStakingInfo(uint256 tokenId) external view returns (
        uint256 stakedAmount,
        uint256 pendingRewards,
        uint256 totalRevenueGenerated,
        bool isActive
    ) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        
        TerritoryData storage territory = territories[tokenId];
        return (
            territory.staking.stakedAmount,
            _calculatePendingRewards(tokenId),
            territory.staking.revenueGenerated,
            territory.staking.isActive
        );
    }
    
    /**
     * @dev Get quality tier distribution
     */
    function getQualityDistribution() external view returns (
        uint256 poor,
        uint256 fair,
        uint256 good,
        uint256 excellent,
        uint256 prime
    ) {
        return (
            qualityTierCount[QualityTier.Poor],
            qualityTierCount[QualityTier.Fair],
            qualityTierCount[QualityTier.Good],
            qualityTierCount[QualityTier.Excellent],
            qualityTierCount[QualityTier.Prime]
        );
    }
    
    /**
     * @dev Get biome statistics
     */
    function getBiomeStats(BiomeType biomeType) external view returns (
        uint256 stakingRequirement,
        uint256 revenueShareRate,
        uint256 totalStaked,
        uint256 revenuePool
    ) {
        return (
            stakingRequirements[biomeType],
            revenueShareRates[biomeType],
            totalStakedPerBiome[biomeType],
            biomeRevenuePools[biomeType]
        );
    }
    
    // ═══════════════════════════════════════════════════════════════
    // OVERRIDES
    // ═══════════════════════════════════════════════════════════════
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
