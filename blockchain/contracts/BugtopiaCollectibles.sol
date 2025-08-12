// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BugtopiaL1.sol";

/**
 * @title BugtopiaCollectibles
 * @dev ERC-1155 contract for all Bugtopia NFTs: Bug DNA, Territories, Artifacts, etc.
 * 
 * Token ID Structure:
 * - 1-999,999: Bug DNA NFTs
 * - 1,000,000-1,999,999: Territory NFTs  
 * - 2,000,000-2,999,999: Artifact NFTs
 * - 3,000,000-3,999,999: Achievement NFTs
 * - 4,000,000+: Future categories
 */
contract BugtopiaCollectibles is ERC1155, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    
    // ============= CONSTANTS =============
    
    uint256 public constant BUG_DNA_CATEGORY = 0;
    uint256 public constant TERRITORY_CATEGORY = 1000000;
    uint256 public constant ARTIFACT_CATEGORY = 2000000;
    uint256 public constant ACHIEVEMENT_CATEGORY = 3000000;
    
    // ============= STATE VARIABLES =============
    
    /// @dev Reference to Bugtopia L1 contract for fee payments
    BugtopiaL1 public immutable bugtopiaL1;
    
    /// @dev Token counters for each category
    mapping(uint256 => uint256) public categoryCounters;
    
    /// @dev Authorized minters (simulation engine, admins)
    mapping(address => bool) public authorizedMinters;
    
    /// @dev Token metadata
    mapping(uint256 => TokenMetadata) public tokenMetadata;
    
    /// @dev Staking for territories (tokenId => staker => amount)
    mapping(uint256 => mapping(address => uint256)) public territoryStakes;
    mapping(uint256 => uint256) public totalTerritoryStakes;
    
    // ============= STRUCTS =============
    
    struct TokenMetadata {
        uint256 category;
        uint256 rarity; // 0-100
        uint256 generation;
        string name;
        string description;
        string externalUrl;
        mapping(string => string) attributes;
        string[] attributeKeys;
    }
    
    struct BugDNAData {
        uint256 species;
        uint256 neuralLayers;
        uint256 fitness;
        uint256 arenaWins;
        uint256 lineage;
        uint256 biomeSpecialization;
        uint256 parentId1;
        uint256 parentId2;
        bytes32 geneticHash;
        uint256 birthTimestamp;
        uint256 survivalDays;
    }
    
    struct TerritoryData {
        uint256 minX;
        uint256 maxX;
        uint256 minY;
        uint256 maxY;
        uint256 minZ;
        uint256 maxZ;
        uint256 biomeType;
        uint256 resourceAbundance;
        uint256 safetyRating;
        uint256 carryingCapacity;
        uint256 populationCount;
        address[] stakeholders;
    }
    
    // ============= EVENTS =============
    
    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 category,
        string name,
        uint256 rarity
    );
    
    event TerritoryStaked(
        address indexed staker,
        uint256 indexed tokenId,
        uint256 amount
    );
    
    event TerritoryUnstaked(
        address indexed staker,
        uint256 indexed tokenId,
        uint256 amount
    );
    
    event RevenueDistributed(
        uint256 indexed tokenId,
        uint256 totalAmount,
        uint256 stakeholderCount
    );
    
    // ============= CONSTRUCTOR =============
    
    constructor(
        address payable _bugtopiaL1,
        string memory _uri
    ) ERC1155(_uri) Ownable(msg.sender) {
        bugtopiaL1 = BugtopiaL1(_bugtopiaL1);
        authorizedMinters[msg.sender] = true;
    }
    
    // ============= MODIFIERS =============
    
    modifier onlyAuthorizedMinter() {
        require(authorizedMinters[msg.sender], "Not authorized to mint");
        _;
    }
    
    // ============= MINTING FUNCTIONS =============
    
    /**
     * @dev Mint Bug DNA NFT
     * @param to Recipient address
     * @param bugData Bug genetic and performance data
     * @return tokenId Minted token ID
     */
    function mintBugDNA(
        address to,
        BugDNAData calldata bugData
    ) external payable onlyAuthorizedMinter nonReentrant returns (uint256) {
        // Pay minting fee to L1 contract
        bugtopiaL1.payUtilityFee{value: msg.value}("nft_minting");
        
        uint256 tokenId = BUG_DNA_CATEGORY + categoryCounters[BUG_DNA_CATEGORY];
        categoryCounters[BUG_DNA_CATEGORY]++;
        
        // Calculate rarity based on genetics and performance
        uint256 rarity = _calculateBugRarity(bugData);
        
        // Set metadata
        TokenMetadata storage metadata = tokenMetadata[tokenId];
        metadata.category = BUG_DNA_CATEGORY;
        metadata.rarity = rarity;
        metadata.generation = bugData.lineage;
        metadata.name = string(abi.encodePacked("Bug #", tokenId.toString()));
        metadata.description = _generateBugDescription(bugData);
        
        // Set attributes
        _setBugAttributes(tokenId, bugData);
        
        // Mint token
        _mint(to, tokenId, 1, "");
        
        emit NFTMinted(to, tokenId, BUG_DNA_CATEGORY, metadata.name, rarity);
        return tokenId;
    }
    
    /**
     * @dev Mint Territory NFT
     * @param to Recipient address
     * @param territoryData Territory boundaries and characteristics
     * @return tokenId Minted token ID
     */
    function mintTerritory(
        address to,
        TerritoryData calldata territoryData
    ) external payable onlyAuthorizedMinter nonReentrant returns (uint256) {
        // Pay minting fee
        bugtopiaL1.payUtilityFee{value: msg.value}("territory_minting");
        
        uint256 tokenId = TERRITORY_CATEGORY + categoryCounters[TERRITORY_CATEGORY];
        categoryCounters[TERRITORY_CATEGORY]++;
        
        // Calculate territory value/rarity
        uint256 rarity = _calculateTerritoryRarity(territoryData);
        
        // Set metadata
        TokenMetadata storage metadata = tokenMetadata[tokenId];
        metadata.category = TERRITORY_CATEGORY;
        metadata.rarity = rarity;
        metadata.name = string(abi.encodePacked("Territory #", tokenId.toString()));
        metadata.description = _generateTerritoryDescription(territoryData);
        
        // Set attributes
        _setTerritoryAttributes(tokenId, territoryData);
        
        // Mint token
        _mint(to, tokenId, 1, "");
        
        emit NFTMinted(to, tokenId, TERRITORY_CATEGORY, metadata.name, rarity);
        return tokenId;
    }
    
    /**
     * @dev Batch mint multiple NFTs (gas efficient)
     * @param to Recipient address
     * @param categories Array of token categories
     * @param amounts Array of amounts to mint
     * @param data Additional data for each mint
     */
    function batchMint(
        address to,
        uint256[] calldata categories,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) external payable onlyAuthorizedMinter nonReentrant {
        require(categories.length == amounts.length, "Array length mismatch");
        
        // Pay batch minting fee
        bugtopiaL1.payUtilityFee{value: msg.value}("batch_minting");
        
        uint256[] memory tokenIds = new uint256[](categories.length);
        
        for (uint256 i = 0; i < categories.length; i++) {
            uint256 category = categories[i];
            uint256 tokenId = category + categoryCounters[category];
            categoryCounters[category] += amounts[i];
            tokenIds[i] = tokenId;
            
            // Set basic metadata
            TokenMetadata storage metadata = tokenMetadata[tokenId];
            metadata.category = category;
            metadata.name = string(abi.encodePacked("Token #", tokenId.toString()));
        }
        
        _mintBatch(to, tokenIds, amounts, "");
    }
    
    // ============= TERRITORY STAKING =============
    
    /**
     * @dev Stake BUG tokens on territory for revenue sharing
     * @param tokenId Territory token ID
     */
    function stakeOnTerritory(uint256 tokenId) external payable nonReentrant {
        require(tokenMetadata[tokenId].category == TERRITORY_CATEGORY, "Not a territory");
        require(msg.value > 0, "Must stake some BUG");
        
        territoryStakes[tokenId][msg.sender] += msg.value;
        totalTerritoryStakes[tokenId] += msg.value;
        
        emit TerritoryStaked(msg.sender, tokenId, msg.value);
    }
    
    /**
     * @dev Unstake BUG tokens from territory
     * @param tokenId Territory token ID
     * @param amount Amount to unstake
     */
    function unstakeFromTerritory(uint256 tokenId, uint256 amount) 
        external 
        nonReentrant 
    {
        require(territoryStakes[tokenId][msg.sender] >= amount, "Insufficient stake");
        
        territoryStakes[tokenId][msg.sender] -= amount;
        totalTerritoryStakes[tokenId] -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit TerritoryUnstaked(msg.sender, tokenId, amount);
    }
    
    /**
     * @dev Distribute revenue to territory stakeholders
     * @param tokenId Territory token ID
     * @param stakeholders Array of stakeholder addresses
     * @param amounts Array of revenue amounts
     */
    function distributeRevenue(
        uint256 tokenId,
        address[] calldata stakeholders,
        uint256[] calldata amounts
    ) external payable onlyAuthorizedMinter nonReentrant {
        require(stakeholders.length == amounts.length, "Array length mismatch");
        
        uint256 totalDistribution = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalDistribution += amounts[i];
            if (amounts[i] > 0) {
                payable(stakeholders[i]).transfer(amounts[i]);
            }
        }
        
        emit RevenueDistributed(tokenId, totalDistribution, stakeholders.length);
    }
    
    // ============= METADATA FUNCTIONS =============
    
    /**
     * @dev Generate Bug DNA description
     */
    function _generateBugDescription(BugDNAData calldata bugData) 
        internal 
        pure 
        returns (string memory) 
    {
        return string(abi.encodePacked(
            "A unique digital organism from the Bugtopia ecosystem. ",
            "Generation ", bugData.lineage.toString(), 
            " with ", bugData.arenaWins.toString(), " arena victories. ",
            "Survived ", bugData.survivalDays.toString(), " days in the wild."
        ));
    }
    
    /**
     * @dev Generate Territory description
     */
    function _generateTerritoryDescription(TerritoryData calldata territoryData) 
        internal 
        pure 
        returns (string memory) 
    {
        return string(abi.encodePacked(
            "A 3D territory in the Bugtopia world with ",
            territoryData.resourceAbundance.toString(), "% resource abundance. ",
            "Supports up to ", territoryData.carryingCapacity.toString(), " organisms. ",
            "Safety rating: ", territoryData.safetyRating.toString(), "/100."
        ));
    }
    
    /**
     * @dev Calculate Bug DNA rarity
     */
    function _calculateBugRarity(BugDNAData calldata bugData) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 rarity = 50; // Base rarity
        
        // Fitness contribution (0-25 points)
        rarity += bugData.fitness / 4;
        
        // Arena wins contribution (0-20 points)
        rarity += (bugData.arenaWins * 20) / 100;
        
        // Survival contribution (0-15 points)
        rarity += (bugData.survivalDays * 15) / 365;
        
        // Neural complexity (0-10 points)
        rarity += bugData.neuralLayers > 3 ? 10 : (bugData.neuralLayers * 3);
        
        return rarity > 100 ? 100 : rarity;
    }
    
    /**
     * @dev Calculate Territory rarity
     */
    function _calculateTerritoryRarity(TerritoryData calldata territoryData) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 rarity = 30; // Base rarity
        
        // Resource abundance (0-30 points)
        rarity += (territoryData.resourceAbundance * 30) / 100;
        
        // Safety rating (0-25 points)  
        rarity += (territoryData.safetyRating * 25) / 100;
        
        // Carrying capacity (0-15 points)
        rarity += (territoryData.carryingCapacity * 15) / 1000;
        
        return rarity > 100 ? 100 : rarity;
    }
    
    /**
     * @dev Set Bug DNA attributes
     */
    function _setBugAttributes(uint256 tokenId, BugDNAData calldata bugData) internal {
        TokenMetadata storage metadata = tokenMetadata[tokenId];
        
        metadata.attributes["Species"] = bugData.species.toString();
        metadata.attributes["Neural Layers"] = bugData.neuralLayers.toString();
        metadata.attributes["Fitness"] = bugData.fitness.toString();
        metadata.attributes["Arena Wins"] = bugData.arenaWins.toString();
        metadata.attributes["Generation"] = bugData.lineage.toString();
        metadata.attributes["Survival Days"] = bugData.survivalDays.toString();
        
        metadata.attributeKeys = [
            "Species", "Neural Layers", "Fitness", 
            "Arena Wins", "Generation", "Survival Days"
        ];
    }
    
    /**
     * @dev Set Territory attributes
     */
    function _setTerritoryAttributes(uint256 tokenId, TerritoryData calldata territoryData) internal {
        TokenMetadata storage metadata = tokenMetadata[tokenId];
        
        metadata.attributes["Biome Type"] = territoryData.biomeType.toString();
        metadata.attributes["Resource Abundance"] = territoryData.resourceAbundance.toString();
        metadata.attributes["Safety Rating"] = territoryData.safetyRating.toString();
        metadata.attributes["Carrying Capacity"] = territoryData.carryingCapacity.toString();
        metadata.attributes["Size X"] = (territoryData.maxX - territoryData.minX).toString();
        metadata.attributes["Size Y"] = (territoryData.maxY - territoryData.minY).toString();
        metadata.attributes["Size Z"] = (territoryData.maxZ - territoryData.minZ).toString();
        
        metadata.attributeKeys = [
            "Biome Type", "Resource Abundance", "Safety Rating",
            "Carrying Capacity", "Size X", "Size Y", "Size Z"
        ];
    }
    
    // ============= ADMIN FUNCTIONS =============
    
    /**
     * @dev Add authorized minter
     */
    function addAuthorizedMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = true;
    }
    
    /**
     * @dev Remove authorized minter
     */
    function removeAuthorizedMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = false;
    }
    
    /**
     * @dev Update URI
     */
    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }
    
    /**
     * @dev Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // ============= VIEW FUNCTIONS =============
    
    /**
     * @dev Get token metadata
     */
    function getTokenMetadata(uint256 tokenId) 
        external 
        view 
        returns (
            uint256 category,
            uint256 rarity,
            uint256 generation,
            string memory name,
            string memory description
        ) 
    {
        TokenMetadata storage metadata = tokenMetadata[tokenId];
        return (
            metadata.category,
            metadata.rarity,
            metadata.generation,
            metadata.name,
            metadata.description
        );
    }
    
    /**
     * @dev Get token attributes
     */
    function getTokenAttributes(uint256 tokenId) 
        external 
        view 
        returns (string[] memory keys, string[] memory values) 
    {
        TokenMetadata storage metadata = tokenMetadata[tokenId];
        keys = metadata.attributeKeys;
        values = new string[](keys.length);
        
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = metadata.attributes[keys[i]];
        }
    }
    
    /**
     * @dev Get territory stake info
     */
    function getTerritoryStake(uint256 tokenId, address staker) 
        external 
        view 
        returns (uint256 stakedAmount, uint256 totalStaked) 
    {
        return (territoryStakes[tokenId][staker], totalTerritoryStakes[tokenId]);
    }
    
    // ============= OVERRIDES =============
    
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override whenNotPaused {
        super._update(from, to, ids, values);
    }
}
