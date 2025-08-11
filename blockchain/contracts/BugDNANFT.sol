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
 * @title BugDNANFT
 * @dev ERC721 NFTs representing evolved bug genomes from Bugtopia simulation
 * 
 * Core Features:
 * - Automatic minting triggered by evolutionary milestones
 * - On-chain genetic trait storage with rarity calculation
 * - Breeding functionality requiring $BUG token payments
 * - Lineage tracking across generations
 * - Tournament history and performance metrics
 */
contract BugDNANFT is 
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
    
    /// @dev Maximum trait values for normalization
    uint256 public constant MAX_TRAIT_VALUE = 10000; // 100.00 with 2 decimals
    
    /// @dev Rarity thresholds
    enum Rarity { Common, Rare, Epic, Legendary, Mythic }
    
    /// @dev Species types matching Bugtopia simulation
    enum SpeciesType { Herbivore, Carnivore, Omnivore, Scavenger }
    
    /// @dev Terrain layers for 3D movement
    enum TerrainLayer { Underground, Surface, Canopy, Aerial }
    
    // ═══════════════════════════════════════════════════════════════
    // STRUCTS
    // ═══════════════════════════════════════════════════════════════
    
    /// @dev Core genetic traits (matching BugDNA.swift structure)
    struct GeneticTraits {
        uint256 speed;              // Movement speed (100-2000)
        uint256 visionRadius;       // Detection range (1000-10000) 
        uint256 energyEfficiency;   // Energy consumption (500-1500)
        uint256 size;               // Physical size (500-2000)
        uint256 strength;           // Physical power (200-1500)
        uint256 memory;             // Intelligence (100-1200)
        uint256 stickiness;         // Grip/climbing (300-1300)
        uint256 camouflage;         // Stealth ability (0-1000)
        uint256 aggression;         // Combat tendency (0-1000)
        uint256 curiosity;          // Exploration drive (0-1000)
    }
    
    /// @dev 3D movement capabilities
    struct MovementTraits {
        uint256 wingSpan;           // Flight capability (0-1000)
        uint256 divingDepth;        // Swimming ability (0-1000)  
        uint256 climbingGrip;       // Vertical movement (0-1000)
        int256 altitudePreference;  // Layer preference (-1000 to 1000)
        uint256 pressureTolerance;  // Extreme environment (0-1000)
    }
    
    /// @dev Neural network architecture
    struct NeuralArchitecture {
        uint8 layerCount;           // Number of neural layers (3-10)
        uint16 totalNeurons;        // Total neurons in network
        uint32 totalConnections;    // Total weighted connections
        uint8 complexityScore;      // Calculated complexity (0-100)
    }
    
    /// @dev Performance and lineage data
    struct PerformanceData {
        uint32 generation;          // Generation number
        uint256 fitnessScore;       // Overall fitness (0-10000)
        uint32 offspringCount;      // Number of children
        uint32 survivalTime;        // Ticks survived
        uint16 tournamentWins;      // Arena victories
        uint256 territoryControlled; // Territory size controlled
    }
    
    /// @dev Complete bug NFT data
    struct BugData {
        string name;                    // Generated bug name
        SpeciesType speciesType;        // Species classification
        Rarity rarity;                  // Calculated rarity level
        GeneticTraits genetics;         // Core genetic traits
        MovementTraits movement;        // 3D movement capabilities
        NeuralArchitecture neural;      // AI architecture
        PerformanceData performance;    // Achievements and lineage
        uint256[] parentTokenIds;       // Parent NFT token IDs
        string geneticHash;             // Unique genetic fingerprint
        uint256 mintTimestamp;          // When NFT was created
        uint256 lastUpdateTimestamp;    // Last metadata update
    }
    
    // ═══════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    /// @dev Reference to $BUG token contract
    IBugToken public immutable bugToken;
    
    /// @dev Bug data for each token ID
    mapping(uint256 => BugData) public bugs;
    
    /// @dev Authorized simulation contracts that can mint NFTs
    mapping(address => bool) public authorizedMinters;
    
    /// @dev Breeding costs in $BUG tokens
    mapping(SpeciesType => mapping(SpeciesType => uint256)) public breedingCosts;
    
    /// @dev Rarity distribution tracking
    mapping(Rarity => uint256) public rarityCount;
    
    /// @dev Generation tracking
    mapping(uint32 => uint256[]) public generationTokens;
    
    /// @dev Genetic hash to token ID mapping (prevent duplicates)
    mapping(string => uint256) public geneticHashToTokenId;
    
    /// @dev Tournament history tracking
    mapping(uint256 => uint256[]) public tournamentHistory;
    
    /// @dev Base URI for metadata
    string private _baseTokenURI;
    
    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    event BugMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string name,
        SpeciesType speciesType,
        Rarity rarity,
        uint32 generation,
        string geneticHash
    );
    
    event BugBred(
        uint256 indexed parent1TokenId,
        uint256 indexed parent2TokenId,
        uint256 indexed childTokenId,
        uint256 breedingCost,
        address breeder
    );
    
    event TournamentResult(
        uint256 indexed tokenId,
        uint256 indexed tournamentId,
        uint16 placement,
        uint256 prizePayout
    );
    
    event PerformanceUpdated(
        uint256 indexed tokenId,
        uint256 newFitnessScore,
        uint32 newOffspringCount,
        uint32 newSurvivalTime
    );
    
    event AuthorizedMinterUpdated(address indexed minter, bool authorized);
    event BreedingCostUpdated(SpeciesType species1, SpeciesType species2, uint256 newCost);
    
    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════
    
    error UnauthorizedMinter();
    error DuplicateGeneticHash();
    error InvalidTokenId();
    error InsufficientBreedingFee();
    error SameSpeciesBreeding();
    error InvalidTraitValue();
    error ParentTokensRequired();
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════
    
    constructor(
        address _bugTokenAddress,
        address _initialOwner,
        string memory _initialBaseURI
    ) 
        ERC721("Bugtopia Bug DNA", "BUGDNA") 
        Ownable(_initialOwner)
    {
        bugToken = IBugToken(_bugTokenAddress);
        _baseTokenURI = _initialBaseURI;
        
        // Initialize breeding costs (in $BUG tokens with 18 decimals)
        _initializeBreedingCosts();
        
        // Start token IDs at 1
        _tokenIdCounter.increment();
    }
    
    /**
     * @dev Initialize default breeding costs for cross-species reproduction
     */
    function _initializeBreedingCosts() internal {
        uint256 baseCost = 1000 * 10**18; // 1000 $BUG tokens
        
        // Same species breeding (not allowed via this mechanism)
        breedingCosts[SpeciesType.Herbivore][SpeciesType.Herbivore] = 0;
        breedingCosts[SpeciesType.Carnivore][SpeciesType.Carnivore] = 0;
        breedingCosts[SpeciesType.Omnivore][SpeciesType.Omnivore] = 0;
        breedingCosts[SpeciesType.Scavenger][SpeciesType.Scavenger] = 0;
        
        // Cross-species breeding costs (scaled by genetic distance)
        breedingCosts[SpeciesType.Herbivore][SpeciesType.Omnivore] = baseCost;
        breedingCosts[SpeciesType.Omnivore][SpeciesType.Herbivore] = baseCost;
        
        breedingCosts[SpeciesType.Carnivore][SpeciesType.Omnivore] = baseCost;
        breedingCosts[SpeciesType.Omnivore][SpeciesType.Carnivore] = baseCost;
        
        breedingCosts[SpeciesType.Herbivore][SpeciesType.Carnivore] = baseCost * 2;
        breedingCosts[SpeciesType.Carnivore][SpeciesType.Herbivore] = baseCost * 2;
        
        breedingCosts[SpeciesType.Scavenger][SpeciesType.Herbivore] = baseCost * 15 / 10;
        breedingCosts[SpeciesType.Herbivore][SpeciesType.Scavenger] = baseCost * 15 / 10;
        
        breedingCosts[SpeciesType.Scavenger][SpeciesType.Carnivore] = baseCost * 15 / 10;
        breedingCosts[SpeciesType.Carnivore][SpeciesType.Scavenger] = baseCost * 15 / 10;
        
        breedingCosts[SpeciesType.Scavenger][SpeciesType.Omnivore] = baseCost * 12 / 10;
        breedingCosts[SpeciesType.Omnivore][SpeciesType.Scavenger] = baseCost * 12 / 10;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MINTING FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Mint new Bug NFT triggered by evolutionary milestone
     * @param to Address to receive the NFT
     * @param bugData Complete bug data including genetics and performance
     * @return tokenId Newly minted token ID
     */
    function mintBug(
        address to,
        BugData memory bugData
    ) 
        external 
        whenNotPaused 
        nonReentrant 
        returns (uint256 tokenId) 
    {
        if (!authorizedMinters[msg.sender]) revert UnauthorizedMinter();
        if (geneticHashToTokenId[bugData.geneticHash] != 0) revert DuplicateGeneticHash();
        
        // Validate trait values
        _validateTraits(bugData.genetics, bugData.movement);
        
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        // Calculate and assign rarity
        bugData.rarity = _calculateRarity(bugData);
        
        // Set timestamps
        bugData.mintTimestamp = block.timestamp;
        bugData.lastUpdateTimestamp = block.timestamp;
        
        // Store bug data
        bugs[tokenId] = bugData;
        geneticHashToTokenId[bugData.geneticHash] = tokenId;
        
        // Update tracking
        rarityCount[bugData.rarity]++;
        generationTokens[bugData.performance.generation].push(tokenId);
        
        // Mint NFT
        _safeMint(to, tokenId);
        
        emit BugMinted(
            tokenId,
            to,
            bugData.name,
            bugData.speciesType,
            bugData.rarity,
            bugData.performance.generation,
            bugData.geneticHash
        );
        
        return tokenId;
    }
    
    /**
     * @dev Breed two bugs to create offspring NFT (requires $BUG payment)
     * @param parent1TokenId First parent NFT
     * @param parent2TokenId Second parent NFT
     * @param offspringData Pre-calculated offspring genetics from simulation
     * @return childTokenId Newly minted child NFT
     */
    function breedBugs(
        uint256 parent1TokenId,
        uint256 parent2TokenId,
        BugData memory offspringData
    ) 
        external 
        whenNotPaused 
        nonReentrant 
        returns (uint256 childTokenId) 
    {
        if (!_exists(parent1TokenId) || !_exists(parent2TokenId)) revert InvalidTokenId();
        if (geneticHashToTokenId[offspringData.geneticHash] != 0) revert DuplicateGeneticHash();
        
        BugData storage parent1 = bugs[parent1TokenId];
        BugData storage parent2 = bugs[parent2TokenId];
        
        // Require cross-species breeding
        if (parent1.speciesType == parent2.speciesType) revert SameSpeciesBreeding();
        
        // Calculate breeding cost
        uint256 breedingCost = breedingCosts[parent1.speciesType][parent2.speciesType];
        if (breedingCost == 0) revert InsufficientBreedingFee();
        
        // Process $BUG payment (includes burn mechanism)
        (uint256 burnAmount, uint256 remainingAmount) = bugToken.utilityBurn(
            msg.sender,
            "BREEDING",
            breedingCost
        );
        
        // Set parent information
        offspringData.parentTokenIds = new uint256[](2);
        offspringData.parentTokenIds[0] = parent1TokenId;
        offspringData.parentTokenIds[1] = parent2TokenId;
        
        // Mint offspring NFT
        childTokenId = mintBug(msg.sender, offspringData);
        
        // Update parent offspring counts
        parent1.performance.offspringCount++;
        parent2.performance.offspringCount++;
        parent1.lastUpdateTimestamp = block.timestamp;
        parent2.lastUpdateTimestamp = block.timestamp;
        
        emit BugBred(parent1TokenId, parent2TokenId, childTokenId, breedingCost, msg.sender);
        
        return childTokenId;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PERFORMANCE TRACKING
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Update bug performance data from simulation
     * @param tokenId Bug NFT to update
     * @param newFitnessScore Updated fitness score
     * @param newSurvivalTime Updated survival time
     * @param territorySize Updated territory control
     */
    function updatePerformance(
        uint256 tokenId,
        uint256 newFitnessScore,
        uint32 newSurvivalTime,
        uint256 territorySize
    ) 
        external 
        whenNotPaused 
    {
        if (!authorizedMinters[msg.sender]) revert UnauthorizedMinter();
        if (!_exists(tokenId)) revert InvalidTokenId();
        
        BugData storage bug = bugs[tokenId];
        
        // Update performance metrics
        bug.performance.fitnessScore = newFitnessScore;
        bug.performance.survivalTime = newSurvivalTime;
        bug.performance.territoryControlled = territorySize;
        bug.lastUpdateTimestamp = block.timestamp;
        
        // Recalculate rarity if performance significantly improved
        Rarity newRarity = _calculateRarity(bug);
        if (newRarity != bug.rarity) {
            rarityCount[bug.rarity]--;
            rarityCount[newRarity]++;
            bug.rarity = newRarity;
        }
        
        emit PerformanceUpdated(tokenId, newFitnessScore, bug.performance.offspringCount, newSurvivalTime);
    }
    
    /**
     * @dev Record tournament result for bug
     * @param tokenId Bug NFT that participated
     * @param tournamentId Tournament identifier
     * @param placement Final placement (1 = winner)
     * @param prizePayout Prize amount in $BUG tokens
     */
    function recordTournamentResult(
        uint256 tokenId,
        uint256 tournamentId,
        uint16 placement,
        uint256 prizePayout
    ) 
        external 
        whenNotPaused 
    {
        if (!authorizedMinters[msg.sender]) revert UnauthorizedMinter();
        if (!_exists(tokenId)) revert InvalidTokenId();
        
        BugData storage bug = bugs[tokenId];
        
        // Update tournament record
        if (placement == 1) {
            bug.performance.tournamentWins++;
        }
        
        tournamentHistory[tokenId].push(tournamentId);
        bug.lastUpdateTimestamp = block.timestamp;
        
        emit TournamentResult(tokenId, tournamentId, placement, prizePayout);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // RARITY CALCULATION
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Calculate rarity based on genetic traits and performance
     * @param bugData Bug data to evaluate
     * @return rarity Calculated rarity level
     */
    function _calculateRarity(BugData memory bugData) internal pure returns (Rarity) {
        uint256 score = 0;
        
        // Genetic trait scoring (40% weight)
        score += _scoreGeneticTraits(bugData.genetics);
        
        // Movement trait scoring (20% weight)  
        score += _scoreMovementTraits(bugData.movement);
        
        // Neural complexity scoring (20% weight)
        score += _scoreNeuralComplexity(bugData.neural);
        
        // Performance scoring (20% weight)
        score += _scorePerformance(bugData.performance);
        
        // Determine rarity based on total score
        if (score >= 9000) return Rarity.Mythic;      // 1% - 90%+ perfection
        if (score >= 8000) return Rarity.Legendary;   // 4% - 80%+ perfection
        if (score >= 6500) return Rarity.Epic;        // 10% - 65%+ perfection
        if (score >= 4000) return Rarity.Rare;        // 25% - 40%+ perfection
        return Rarity.Common;                          // 60% - <40% perfection
    }
    
    /**
     * @dev Score genetic traits for rarity calculation
     */
    function _scoreGeneticTraits(GeneticTraits memory traits) internal pure returns (uint256) {
        uint256 score = 0;
        
        // Exceptional single traits (max possible values)
        if (traits.speed >= 1800) score += 500;           // Very fast
        if (traits.visionRadius >= 8000) score += 500;    // Exceptional vision
        if (traits.energyEfficiency <= 600) score += 500; // Very efficient
        if (traits.strength >= 1300) score += 400;        // Very strong
        if (traits.memory >= 1000) score += 400;          // Highly intelligent
        
        // Multi-trait excellence
        uint256 excellentTraits = 0;
        if (traits.speed >= 1500) excellentTraits++;
        if (traits.visionRadius >= 6000) excellentTraits++;
        if (traits.energyEfficiency <= 800) excellentTraits++;
        if (traits.size >= 1500) excellentTraits++;
        if (traits.strength >= 1100) excellentTraits++;
        if (traits.memory >= 800) excellentTraits++;
        if (traits.camouflage >= 800) excellentTraits++;
        
        // Bonus for multiple excellent traits
        if (excellentTraits >= 5) score += 1000;
        else if (excellentTraits >= 3) score += 500;
        
        return score;
    }
    
    /**
     * @dev Score 3D movement traits for rarity calculation
     */
    function _scoreMovementTraits(MovementTraits memory traits) internal pure returns (uint256) {
        uint256 score = 0;
        
        // Advanced movement capabilities
        if (traits.wingSpan >= 700) score += 300;        // Advanced flight
        if (traits.divingDepth >= 700) score += 300;     // Deep diving
        if (traits.climbingGrip >= 700) score += 300;    // Expert climbing
        if (traits.pressureTolerance >= 800) score += 200; // Extreme environments
        
        // Multi-modal movement mastery
        uint256 masteryCount = 0;
        if (traits.wingSpan >= 500) masteryCount++;       // Can fly
        if (traits.divingDepth >= 300) masteryCount++;    // Can swim
        if (traits.climbingGrip >= 400) masteryCount++;   // Can climb
        
        if (masteryCount >= 3) score += 400; // All three movement types
        else if (masteryCount >= 2) score += 200; // Two movement types
        
        return score;
    }
    
    /**
     * @dev Score neural network complexity for rarity calculation
     */
    function _scoreNeuralComplexity(NeuralArchitecture memory neural) internal pure returns (uint256) {
        uint256 score = 0;
        
        // Deep networks
        if (neural.layerCount >= 8) score += 400;
        else if (neural.layerCount >= 6) score += 200;
        
        // Large networks
        if (neural.totalNeurons >= 200) score += 300;
        else if (neural.totalNeurons >= 100) score += 150;
        
        // Complex connectivity
        if (neural.totalConnections >= 1000) score += 300;
        else if (neural.totalConnections >= 500) score += 150;
        
        // High complexity score
        if (neural.complexityScore >= 80) score += 300;
        else if (neural.complexityScore >= 60) score += 150;
        
        return score;
    }
    
    /**
     * @dev Score performance metrics for rarity calculation
     */
    function _scorePerformance(PerformanceData memory performance) internal pure returns (uint256) {
        uint256 score = 0;
        
        // Perfect or near-perfect fitness
        if (performance.fitnessScore >= 9500) score += 800;      // 95%+ fitness
        else if (performance.fitnessScore >= 9000) score += 500; // 90%+ fitness
        else if (performance.fitnessScore >= 8000) score += 200; // 80%+ fitness
        
        // Long lineage survival
        if (performance.generation >= 200) score += 400;
        else if (performance.generation >= 100) score += 200;
        else if (performance.generation >= 50) score += 100;
        
        // Tournament success
        if (performance.tournamentWins >= 10) score += 500;
        else if (performance.tournamentWins >= 5) score += 300;
        else if (performance.tournamentWins >= 1) score += 100;
        
        // Reproductive success
        if (performance.offspringCount >= 20) score += 300;
        else if (performance.offspringCount >= 10) score += 150;
        
        // Territory control
        if (performance.territoryControlled >= 1000) score += 200;
        else if (performance.territoryControlled >= 500) score += 100;
        
        return score;
    }
    
    /**
     * @dev Validate genetic trait values are within expected ranges
     */
    function _validateTraits(
        GeneticTraits memory genetics, 
        MovementTraits memory movement
    ) internal pure {
        if (genetics.speed < 100 || genetics.speed > 2000) revert InvalidTraitValue();
        if (genetics.visionRadius < 1000 || genetics.visionRadius > 10000) revert InvalidTraitValue();
        if (genetics.energyEfficiency < 500 || genetics.energyEfficiency > 1500) revert InvalidTraitValue();
        if (genetics.size < 500 || genetics.size > 2000) revert InvalidTraitValue();
        if (genetics.strength < 200 || genetics.strength > 1500) revert InvalidTraitValue();
        
        if (movement.wingSpan > 1000) revert InvalidTraitValue();
        if (movement.divingDepth > 1000) revert InvalidTraitValue();
        if (movement.climbingGrip > 1000) revert InvalidTraitValue();
        if (movement.altitudePreference < -1000 || movement.altitudePreference > 1000) revert InvalidTraitValue();
        if (movement.pressureTolerance > 1000) revert InvalidTraitValue();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Update authorized minter contracts
     */
    function setAuthorizedMinter(address minter, bool authorized) external onlyOwner {
        authorizedMinters[minter] = authorized;
        emit AuthorizedMinterUpdated(minter, authorized);
    }
    
    /**
     * @dev Update breeding costs for species combinations
     */
    function setBreedingCost(
        SpeciesType species1, 
        SpeciesType species2, 
        uint256 newCost
    ) external onlyOwner {
        breedingCosts[species1][species2] = newCost;
        breedingCosts[species2][species1] = newCost; // Symmetric costs
        emit BreedingCostUpdated(species1, species2, newCost);
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
     * @dev Get complete bug data for token ID
     */
    function getBugData(uint256 tokenId) external view returns (BugData memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return bugs[tokenId];
    }
    
    /**
     * @dev Get rarity distribution statistics
     */
    function getRarityDistribution() external view returns (
        uint256 common,
        uint256 rare,
        uint256 epic,
        uint256 legendary,
        uint256 mythic
    ) {
        return (
            rarityCount[Rarity.Common],
            rarityCount[Rarity.Rare],
            rarityCount[Rarity.Epic],
            rarityCount[Rarity.Legendary],
            rarityCount[Rarity.Mythic]
        );
    }
    
    /**
     * @dev Get all tokens from specific generation
     */
    function getGenerationTokens(uint32 generation) external view returns (uint256[] memory) {
        return generationTokens[generation];
    }
    
    /**
     * @dev Get tournament history for bug
     */
    function getTournamentHistory(uint256 tokenId) external view returns (uint256[] memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return tournamentHistory[tokenId];
    }
    
    /**
     * @dev Check if genetic hash already exists
     */
    function geneticHashExists(string memory geneticHash) external view returns (bool) {
        return geneticHashToTokenId[geneticHash] != 0;
    }
    
    /**
     * @dev Get breeding cost for species combination
     */
    function getBreedingCost(SpeciesType species1, SpeciesType species2) external view returns (uint256) {
        return breedingCosts[species1][species2];
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
