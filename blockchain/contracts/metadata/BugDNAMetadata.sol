// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title BugDNAMetadata
 * @dev On-chain metadata generation for Bug DNA NFTs
 * 
 * Generates OpenSea-compatible metadata directly from genetic data
 * Includes rarity scoring, trait display, and evolutionary history
 */
library BugDNAMetadata {
    
    using Strings for uint256;
    
    // ═══════════════════════════════════════════════════════════════
    // STRUCTS (matching BugDNANFT.sol)
    // ═══════════════════════════════════════════════════════════════
    
    struct GeneticTraits {
        uint256 speed;
        uint256 visionRadius;
        uint256 energyEfficiency;
        uint256 size;
        uint256 strength;
        uint256 memoryCapacity;
        uint256 stickiness;
        uint256 camouflage;
        uint256 aggression;
        uint256 curiosity;
    }
    
    struct MovementTraits {
        uint256 wingSpan;
        uint256 divingDepth;
        uint256 climbingGrip;
        int256 altitudePreference;
        uint256 pressureTolerance;
    }
    
    struct NeuralArchitecture {
        uint8 layerCount;
        uint16 totalNeurons;
        uint32 totalConnections;
        uint8 complexityScore;
    }
    
    struct PerformanceData {
        uint32 generation;
        uint256 fitnessScore;
        uint32 offspringCount;
        uint32 survivalTime;
        uint16 tournamentWins;
        uint256 territoryControlled;
    }
    
    enum SpeciesType { Herbivore, Carnivore, Omnivore, Scavenger }
    enum Rarity { Common, Rare, Epic, Legendary, Mythic }
    
    // ═══════════════════════════════════════════════════════════════
    // METADATA GENERATION
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Generate complete JSON metadata for Bug DNA NFT
     * @param tokenId Token ID
     * @param name Bug name
     * @param description Bug description
     * @param speciesType Species classification
     * @param rarity Calculated rarity tier
     * @param genetics Core genetic traits
     * @param movement 3D movement capabilities
     * @param neural Neural network architecture
     * @param performance Achievement data
     * @param parentTokenIds Parent NFT IDs
     * @param geneticHash Unique genetic fingerprint
     * @param imageURI IPFS URI for bug visualization
     * @return metadata Base64-encoded JSON metadata
     */
    function generateMetadata(
        uint256 tokenId,
        string memory name,
        string memory description,
        SpeciesType speciesType,
        Rarity rarity,
        GeneticTraits memory genetics,
        MovementTraits memory movement,
        NeuralArchitecture memory neural,
        PerformanceData memory performance,
        uint256[] memory parentTokenIds,
        string memory geneticHash,
        string memory imageURI
    ) external pure returns (string memory) {
        
        string memory attributes = _generateAttributes(
            speciesType,
            rarity,
            genetics,
            movement,
            neural,
            performance
        );
        
        string memory lineageInfo = _generateLineageInfo(parentTokenIds, performance.generation);
        
        string memory json = string(abi.encodePacked(
            '{"name":"', name, '",',
            '"description":"', description, '",',
            '"image":"', imageURI, '",',
            '"external_url":"https://bugtopia.io/bug/', tokenId.toString(), '",',
            '"attributes":[', attributes, '],',
            '"evolutionary_data":{',
                '"genetic_hash":"', geneticHash, '",',
                '"generation":', uint256(performance.generation).toString(), ',',
                '"species_type":"', _getSpeciesName(speciesType), '",',
                '"rarity_tier":"', _getRarityName(rarity), '",',
                lineageInfo,
                '"neural_complexity":', uint256(neural.complexityScore).toString(),
            '},',
            '"stats":{',
                '"fitness_score":', performance.fitnessScore.toString(), ',',
                '"tournament_wins":', uint256(performance.tournamentWins).toString(), ',',
                '"offspring_count":', uint256(performance.offspringCount).toString(), ',',
                '"survival_time":', uint256(performance.survivalTime).toString(), ',',
                '"territory_controlled":', performance.territoryControlled.toString(),
            '}}'
        ));
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }
    
    /**
     * @dev Generate OpenSea-compatible attributes array
     */
    function _generateAttributes(
        SpeciesType speciesType,
        Rarity rarity,
        GeneticTraits memory genetics,
        MovementTraits memory movement,
        NeuralArchitecture memory neural,
        PerformanceData memory performance
    ) internal pure returns (string memory) {
        
        string memory attrs = string(abi.encodePacked(
            // Core classification
            '{"trait_type":"Species","value":"', _getSpeciesName(speciesType), '"},',
            '{"trait_type":"Rarity","value":"', _getRarityName(rarity), '"},',
            '{"trait_type":"Generation","value":', uint256(performance.generation).toString(), '},',
            
            // Core genetic traits (normalized to 0-100 for display)
            '{"trait_type":"Speed","value":', _normalizeTraitValue(genetics.speed, 100, 2000).toString(), ',"max_value":100},',
            '{"trait_type":"Vision Radius","value":', _normalizeTraitValue(genetics.visionRadius, 1000, 10000).toString(), ',"max_value":100},',
            '{"trait_type":"Energy Efficiency","value":', _normalizeTraitValue(1500 - genetics.energyEfficiency + 500, 0, 1000).toString(), ',"max_value":100},'
        ));
        
        attrs = string(abi.encodePacked(attrs,
            '{"trait_type":"Size","value":', _normalizeTraitValue(genetics.size, 500, 2000).toString(), ',"max_value":100},',
            '{"trait_type":"Strength","value":', _normalizeTraitValue(genetics.strength, 200, 1500).toString(), ',"max_value":100},',
            '{"trait_type":"Intelligence","value":', _normalizeTraitValue(genetics.memoryCapacity, 100, 1200).toString(), ',"max_value":100},',
            '{"trait_type":"Stealth","value":', _normalizeTraitValue(genetics.camouflage, 0, 1000).toString(), ',"max_value":100},',
            '{"trait_type":"Aggression","value":', _normalizeTraitValue(genetics.aggression, 0, 1000).toString(), ',"max_value":100},'
        ));
        
        // 3D Movement capabilities
        attrs = string(abi.encodePacked(attrs,
            '{"trait_type":"Flight Capability","value":', _normalizeTraitValue(movement.wingSpan, 0, 1000).toString(), ',"max_value":100},',
            '{"trait_type":"Swimming Ability","value":', _normalizeTraitValue(movement.divingDepth, 0, 1000).toString(), ',"max_value":100},',
            '{"trait_type":"Climbing Skill","value":', _normalizeTraitValue(movement.climbingGrip, 0, 1000).toString(), ',"max_value":100},',
            '{"trait_type":"Pressure Tolerance","value":', _normalizeTraitValue(movement.pressureTolerance, 0, 1000).toString(), ',"max_value":100},'
        ));
        
        // Neural network architecture
        attrs = string(abi.encodePacked(attrs,
            '{"trait_type":"Neural Layers","value":', uint256(neural.layerCount).toString(), ',"max_value":10},',
            '{"trait_type":"Total Neurons","value":', uint256(neural.totalNeurons).toString(), '},',
            '{"trait_type":"Neural Complexity","value":', uint256(neural.complexityScore).toString(), ',"max_value":100},'
        ));
        
        // Performance metrics
        attrs = string(abi.encodePacked(attrs,
            '{"trait_type":"Fitness Score","value":', _normalizeTraitValue(performance.fitnessScore, 0, 10000).toString(), ',"display_type":"boost_percentage","max_value":100},',
            '{"trait_type":"Tournament Victories","value":', uint256(performance.tournamentWins).toString(), '},',
            '{"trait_type":"Offspring Count","value":', uint256(performance.offspringCount).toString(), '}'
        ));
        
        // Movement specializations (boolean traits)
        if (movement.wingSpan >= 500) {
            attrs = string(abi.encodePacked(attrs, ',{"trait_type":"Can Fly","value":"Yes"}'));
        }
        if (movement.divingDepth >= 300) {
            attrs = string(abi.encodePacked(attrs, ',{"trait_type":"Can Swim","value":"Yes"}'));
        }
        if (movement.climbingGrip >= 400) {
            attrs = string(abi.encodePacked(attrs, ',{"trait_type":"Can Climb","value":"Yes"}'));
        }
        
        // Altitude preference
        if (movement.altitudePreference > 500) {
            attrs = string(abi.encodePacked(attrs, ',{"trait_type":"Preferred Layer","value":"Aerial"}'));
        } else if (movement.altitudePreference > 0) {
            attrs = string(abi.encodePacked(attrs, ',{"trait_type":"Preferred Layer","value":"Canopy"}'));
        } else if (movement.altitudePreference > -500) {
            attrs = string(abi.encodePacked(attrs, ',{"trait_type":"Preferred Layer","value":"Surface"}'));
        } else {
            attrs = string(abi.encodePacked(attrs, ',{"trait_type":"Preferred Layer","value":"Underground"}'));
        }
        
        return attrs;
    }
    
    /**
     * @dev Generate lineage information for metadata
     */
    function _generateLineageInfo(
        uint256[] memory parentTokenIds,
        uint32 generation
    ) internal pure returns (string memory) {
        
        if (parentTokenIds.length == 0) {
            return '"lineage_type":"Genesis","parent_count":0,';
        }
        
        if (parentTokenIds.length == 1) {
            return string(abi.encodePacked(
                '"lineage_type":"Asexual","parent_count":1,',
                '"parent_1":', parentTokenIds[0].toString(), ','
            ));
        }
        
        if (parentTokenIds.length == 2) {
            return string(abi.encodePacked(
                '"lineage_type":"Sexual","parent_count":2,',
                '"parent_1":', parentTokenIds[0].toString(), ',',
                '"parent_2":', parentTokenIds[1].toString(), ','
            ));
        }
        
        return string(abi.encodePacked('"lineage_type":"Complex","parent_count":', uint256(parentTokenIds.length).toString(), ','));
    }
    
    // ═══════════════════════════════════════════════════════════════
    // HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @dev Normalize trait value to 0-100 scale for consistent display
     * @param value Current trait value
     * @param minValue Minimum possible value
     * @param maxValue Maximum possible value
     * @return normalized Normalized value (0-100)
     */
    function _normalizeTraitValue(
        uint256 value,
        uint256 minValue,
        uint256 maxValue
    ) internal pure returns (uint256) {
        if (value <= minValue) return 0;
        if (value >= maxValue) return 100;
        
        return ((value - minValue) * 100) / (maxValue - minValue);
    }
    
    /**
     * @dev Get human-readable species name
     */
    function _getSpeciesName(SpeciesType speciesType) internal pure returns (string memory) {
        if (speciesType == SpeciesType.Herbivore) return "Herbivore";
        if (speciesType == SpeciesType.Carnivore) return "Carnivore";
        if (speciesType == SpeciesType.Omnivore) return "Omnivore";
        if (speciesType == SpeciesType.Scavenger) return "Scavenger";
        return "Unknown";
    }
    
    /**
     * @dev Get human-readable rarity name
     */
    function _getRarityName(Rarity rarity) internal pure returns (string memory) {
        if (rarity == Rarity.Common) return "Common";
        if (rarity == Rarity.Rare) return "Rare";
        if (rarity == Rarity.Epic) return "Epic";
        if (rarity == Rarity.Legendary) return "Legendary";
        if (rarity == Rarity.Mythic) return "Mythic";
        return "Unknown";
    }
    
    /**
     * @dev Generate species emoji for visual identification
     */
    function _getSpeciesEmoji(SpeciesType speciesType) internal pure returns (string memory) {
        if (speciesType == SpeciesType.Herbivore) return unicode"🌱";
        if (speciesType == SpeciesType.Carnivore) return unicode"🦁";
        if (speciesType == SpeciesType.Omnivore) return unicode"🐻";
        if (speciesType == SpeciesType.Scavenger) return unicode"🦅";
        return unicode"🐛";
    }
    
    /**
     * @dev Generate rarity color for UI display
     */
    function _getRarityColor(Rarity rarity) internal pure returns (string memory) {
        if (rarity == Rarity.Common) return "#9CA3AF";      // Gray
        if (rarity == Rarity.Rare) return "#3B82F6";       // Blue
        if (rarity == Rarity.Epic) return "#8B5CF6";       // Purple
        if (rarity == Rarity.Legendary) return "#F59E0B";  // Orange
        if (rarity == Rarity.Mythic) return "#EF4444";     // Red
        return "#6B7280";
    }
    
    /**
     * @dev Calculate approximate market value based on traits and rarity
     * @param rarity Bug rarity tier
     * @param performance Performance metrics
     * @param neural Neural architecture
     * @return estimatedValue Estimated value in $BUG tokens (18 decimals)
     */
    function calculateEstimatedValue(
        Rarity rarity,
        PerformanceData memory performance,
        NeuralArchitecture memory neural
    ) external pure returns (uint256 estimatedValue) {
        
        uint256 baseValue = 100 * 10**18; // 100 $BUG base value
        
        // Rarity multipliers
        if (rarity == Rarity.Mythic) baseValue *= 50;          // 5000 $BUG
        else if (rarity == Rarity.Legendary) baseValue *= 20;  // 2000 $BUG
        else if (rarity == Rarity.Epic) baseValue *= 8;        // 800 $BUG
        else if (rarity == Rarity.Rare) baseValue *= 3;        // 300 $BUG
        // Common stays at 100 $BUG
        
        // Performance bonuses
        if (performance.fitnessScore >= 9500) baseValue = (baseValue * 150) / 100; // +50% for 95%+ fitness
        if (performance.tournamentWins >= 10) baseValue = (baseValue * 130) / 100; // +30% for tournament champions
        if (performance.generation >= 100) baseValue = (baseValue * 120) / 100;    // +20% for ancient lineages
        
        // Neural complexity bonus
        if (neural.complexityScore >= 80) baseValue = (baseValue * 115) / 100;     // +15% for advanced AI
        
        return baseValue;
    }
    
    /**
     * @dev Generate dynamic description based on bug characteristics
     */
    function generateDescription(
        string memory name,
        SpeciesType speciesType,
        Rarity rarity,
        PerformanceData memory performance,
        MovementTraits memory movement
    ) external pure returns (string memory) {
        
        string memory description = string(abi.encodePacked(
            name, " is a ", _getRarityName(rarity), " ", _getSpeciesName(speciesType),
            " from Generation ", uint256(performance.generation).toString(), 
            " of the Bugtopia evolutionary simulation."
        ));
        
        // Add movement capabilities
        string memory capabilities = "";
        if (movement.wingSpan >= 500) capabilities = string(abi.encodePacked(capabilities, " Flight"));
        if (movement.divingDepth >= 300) capabilities = string(abi.encodePacked(capabilities, " Swimming"));
        if (movement.climbingGrip >= 400) capabilities = string(abi.encodePacked(capabilities, " Climbing"));
        
        if (bytes(capabilities).length > 0) {
            description = string(abi.encodePacked(
                description, " Specialized in:", capabilities, "."
            ));
        }
        
        // Add performance highlights
        if (performance.tournamentWins > 0) {
            description = string(abi.encodePacked(
                description, " Tournament victories: ", uint256(performance.tournamentWins).toString(), "."
            ));
        }
        
        if (performance.fitnessScore >= 9000) {
            description = string(abi.encodePacked(
                description, " Exceptional fitness score: ", performance.fitnessScore.toString(), "/10000."
            ));
        }
        
        return description;
    }
}
