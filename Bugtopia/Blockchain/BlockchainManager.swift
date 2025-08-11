//
//  BlockchainManager.swift
//  Bugtopia
//
//  Created by AI Agent on 1/4/25.
//

import Foundation
import Combine
import SwiftUI

/// Manages blockchain integration for Bugtopia tokenomics
@Observable
class BlockchainManager {
    
    // MARK: - Configuration
    
    /// Blockchain network configuration
    struct NetworkConfig {
        let chainId: Int
        let rpcUrl: String
        let explorerUrl: String
        let contractAddresses: ContractAddresses
    }
    
    /// Smart contract addresses
    struct ContractAddresses {
        let bugToken: String
        let bugDNANFT: String
        let territoryNFT: String
        let stakingPool: String
        let governance: String
    }
    
    // MARK: - State
    
    /// Current network configuration
    private var networkConfig: NetworkConfig
    
    /// Queue for blockchain operations to prevent overwhelming the network
    private let operationQueue = DispatchQueue(label: "blockchain.operations", qos: .utility)
    
    /// Pending operations that need to be processed
    private var pendingOperations: [BlockchainOperation] = []
    
    /// Connection status
    var isConnected: Bool = false
    
    /// Last sync timestamp
    var lastSyncTime: Date = Date()
    
    // MARK: - Blockchain Operations
    
    /// Types of blockchain operations
    enum BlockchainOperation {
        case mintBugNFT(Bug, evolutionEvent: EvolutionEvent?)
        case updateBugPerformance(tokenId: String, Bug)
        case mintTerritoryNFT(Population, territoryData: TerritoryData)
        case updateTerritoryData(tokenId: String, Population)
        case distributeRevenue(biome: BiomeType, amount: Double)
        case recordTournamentResult(bugId: UUID, tournamentId: String, placement: Int, payout: Double)
        case burnTokensForUtility(userId: String, utilityType: String, amount: Double)
    }
    
    /// Evolution events that trigger NFT minting
    enum EvolutionEvent {
        case generationMilestone(Int)
        case speciationEvent(SpeciationEvent)
        case perfectFitness(Double)
        case tournamentVictory(String)
        case lineageFounder
    }
    
    /// Territory data structure for blockchain
    struct TerritoryData {
        let name: String
        let biomeType: BiomeType
        let bounds: Territory3DBounds
        let resourceData: ResourceAbundance
        let qualityMetrics: TerritoryQuality
        let populationData: PopulationStats
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize with development/testnet configuration
        self.networkConfig = NetworkConfig(
            chainId: 43113, // Avalanche Fuji Testnet
            rpcUrl: "https://api.avax-test.network/ext/bc/C/rpc",
            explorerUrl: "https://testnet.snowtrace.io",
            contractAddresses: ContractAddresses(
                bugToken: "0x...", // Will be populated after deployment
                bugDNANFT: "0x...",
                territoryNFT: "0x...",
                stakingPool: "0x...",
                governance: "0x..."
            )
        )
        
        // Start background processing
        startOperationProcessing()
    }
    
    // MARK: - Bug NFT Operations
    
    /// Queue bug NFT minting for evolutionary milestone
    func triggerBugNFTMinting(for bug: Bug, event: EvolutionEvent? = nil) {
        let operation = BlockchainOperation.mintBugNFT(bug, evolutionEvent: event)
        queueOperation(operation)
    }
    
    /// Queue bug performance update
    func updateBugPerformance(tokenId: String, bug: Bug) {
        let operation = BlockchainOperation.updateBugPerformance(tokenId: tokenId, bug)
        queueOperation(operation)
    }
    
    /// Check if bug qualifies for NFT minting
    func shouldMintBugNFT(for bug: Bug) -> Bool {
        // Generation milestones
        if bug.generation >= 50 && bug.generation % 50 == 0 {
            return true
        }
        
        // Perfect or near-perfect fitness
        if let fitness = calculateFitness(for: bug), fitness >= 0.95 {
            return true
        }
        
        // Exceptional genetic traits
        if hasExceptionalTraits(bug.dna) {
            return true
        }
        
        // Tournament victories (would need tournament system)
        // if bug.tournamentWins >= 1 { return true }
        
        return false
    }
    
    /// Calculate comprehensive fitness score for bug
    private func calculateFitness(for bug: Bug) -> Double? {
        // Comprehensive fitness calculation based on:
        // - Survival time vs generation average
        // - Energy efficiency
        // - Reproductive success
        // - Territory control
        // - Neural network performance
        
        guard bug.age > 0 else { return nil }
        
        let ageFitness = min(1.0, Double(bug.age) / Double(Bug.maxAge))
        let energyFitness = bug.energy / Bug.maxEnergy
        
        // Genetic trait fitness (normalized)
        let speedFitness = (bug.dna.speed - 0.1) / (2.0 - 0.1)
        let visionFitness = (bug.dna.visionRadius - 10) / (100 - 10)
        let efficiencyFitness = (1.5 - bug.dna.energyEfficiency) / (1.5 - 0.5)
        
        // 3D movement fitness
        let movementFitness = (bug.dna.wingSpan + bug.dna.divingDepth + bug.dna.climbingGrip) / 3.0
        
        // Weighted average fitness
        let totalFitness = (
            ageFitness * 0.2 +
            energyFitness * 0.2 +
            speedFitness * 0.15 +
            visionFitness * 0.15 +
            efficiencyFitness * 0.15 +
            movementFitness * 0.15
        )
        
        return max(0.0, min(1.0, totalFitness))
    }
    
    /// Check if bug has exceptional genetic traits
    private func hasExceptionalTraits(_ dna: BugDNA) -> Bool {
        // Exceptional individual traits
        if dna.speed >= 1.8 { return true }
        if dna.visionRadius >= 80 { return true }
        if dna.energyEfficiency <= 0.6 { return true }
        if dna.strength >= 1.3 { return true }
        if dna.memory >= 1.0 { return true }
        
        // Advanced 3D movement
        if dna.wingSpan >= 0.8 { return true }
        if dna.divingDepth >= 0.8 { return true }
        if dna.climbingGrip >= 0.8 { return true }
        
        // Multi-trait excellence
        let excellentTraits = [
            dna.speed >= 1.5,
            dna.visionRadius >= 60,
            dna.energyEfficiency <= 0.8,
            dna.strength >= 1.1,
            dna.memory >= 0.8,
            dna.wingSpan >= 0.5,
            dna.divingDepth >= 0.5,
            dna.climbingGrip >= 0.5
        ].filter { $0 }.count
        
        return excellentTraits >= 5
    }
    
    // MARK: - Territory NFT Operations
    
    /// Queue territory NFT minting for population
    func triggerTerritoryNFTMinting(for population: Population, territoryData: TerritoryData) {
        let operation = BlockchainOperation.mintTerritoryNFT(population, territoryData: territoryData)
        queueOperation(operation)
    }
    
    /// Queue territory data update
    func updateTerritoryData(tokenId: String, population: Population) {
        let territoryData = generateTerritoryData(from: population)
        let operation = BlockchainOperation.updateTerritoryData(tokenId: tokenId, population)
        queueOperation(operation)
    }
    
    /// Generate territory data from population
    private func generateTerritoryData(from population: Population) -> TerritoryData {
        // Extract territory bounds from population territories
        let bounds = Territory3DBounds(
            minX: population.territories.map { $0.x }.min() ?? 0,
            maxX: population.territories.map { $0.x }.max() ?? 0,
            minY: population.territories.map { $0.y }.min() ?? 0,
            maxY: population.territories.map { $0.y }.max() ?? 0,
            minZ: -10, // Underground layer
            maxZ: 50   // Aerial layer
        )
        
        // Calculate resource abundance (simplified)
        let resourceData = ResourceAbundance(
            vegetation: 0.7,
            minerals: 0.5,
            water: 0.8,
            insects: 0.6,
            nectar: 0.4,
            seeds: 0.5,
            fungi: 0.3,
            detritus: 0.4
        )
        
        // Assess territory quality
        let qualityMetrics = TerritoryQuality(
            overallTier: assessQualityTier(population: population),
            resourceAbundance: calculateResourceScore(resourceData),
            safetyRating: 0.7, // Simplified
            carryingCapacity: UInt32(population.size * 3),
            accessibility: 0.8,
            strategicValue: 0.6
        )
        
        // Population statistics
        let populationData = PopulationStats(
            currentPopulation: UInt32(population.size),
            maxPopulation: UInt32(population.size),
            dominantSpecies: population.name
        )
        
        return TerritoryData(
            name: population.name,
            biomeType: determineBiomeType(from: population),
            bounds: bounds,
            resourceData: resourceData,
            qualityMetrics: qualityMetrics,
            populationData: populationData
        )
    }
    
    /// Assess territory quality tier
    private func assessQualityTier(population: Population) -> QualityTier {
        if population.size >= 20 && population.isViableSpecies {
            return .prime
        } else if population.size >= 15 {
            return .excellent
        } else if population.size >= 10 {
            return .good
        } else if population.size >= 5 {
            return .fair
        } else {
            return .poor
        }
    }
    
    /// Calculate resource abundance score
    private func calculateResourceScore(_ resources: ResourceAbundance) -> Double {
        return (resources.vegetation + resources.minerals + resources.water + 
                resources.insects + resources.nectar + resources.seeds + 
                resources.fungi + resources.detritus) / 8.0
    }
    
    /// Determine biome type from population data
    private func determineBiomeType(from population: Population) -> BiomeType {
        // Simplified biome determination based on territory location
        // In a real implementation, this would analyze the actual terrain
        let centroid = population.centroid
        
        if centroid.x < -50 {
            return .desert
        } else if centroid.x > 50 {
            return .temperateForest
        } else if abs(centroid.y) > 50 {
            return .alpine
        } else {
            return .temperateGrassland
        }
    }
    
    // MARK: - Economic Operations
    
    /// Distribute revenue from biome activities
    func distributeRevenue(biome: BiomeType, amount: Double) {
        let operation = BlockchainOperation.distributeRevenue(biome: biome, amount: amount)
        queueOperation(operation)
    }
    
    /// Burn tokens for utility function usage
    func burnTokensForUtility(userId: String, utilityType: String, amount: Double) {
        let operation = BlockchainOperation.burnTokensForUtility(userId: userId, utilityType: utilityType, amount: amount)
        queueOperation(operation)
    }
    
    /// Record tournament result
    func recordTournamentResult(bugId: UUID, tournamentId: String, placement: Int, payout: Double) {
        let operation = BlockchainOperation.recordTournamentResult(
            bugId: bugId, 
            tournamentId: tournamentId, 
            placement: placement, 
            payout: payout
        )
        queueOperation(operation)
    }
    
    // MARK: - Operation Processing
    
    /// Queue blockchain operation for processing
    private func queueOperation(_ operation: BlockchainOperation) {
        operationQueue.async {
            self.pendingOperations.append(operation)
        }
    }
    
    /// Start background operation processing
    private func startOperationProcessing() {
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.processOperations()
        }
    }
    
    /// Process pending blockchain operations
    private func processOperations() {
        operationQueue.async {
            guard !self.pendingOperations.isEmpty else { return }
            
            // Process operations in batches to optimize gas usage
            let batchSize = min(5, self.pendingOperations.count)
            let batch = Array(self.pendingOperations.prefix(batchSize))
            self.pendingOperations.removeFirst(batchSize)
            
            for operation in batch {
                self.executeOperation(operation)
            }
            
            self.lastSyncTime = Date()
        }
    }
    
    /// Execute individual blockchain operation
    private func executeOperation(_ operation: BlockchainOperation) {
        switch operation {
        case .mintBugNFT(let bug, let event):
            executeBugNFTMinting(bug: bug, event: event)
            
        case .updateBugPerformance(let tokenId, let bug):
            executeUpdateBugPerformance(tokenId: tokenId, bug: bug)
            
        case .mintTerritoryNFT(let population, let territoryData):
            executeTerritoryNFTMinting(population: population, territoryData: territoryData)
            
        case .updateTerritoryData(let tokenId, let population):
            executeUpdateTerritoryData(tokenId: tokenId, population: population)
            
        case .distributeRevenue(let biome, let amount):
            executeRevenueDistribution(biome: biome, amount: amount)
            
        case .recordTournamentResult(let bugId, let tournamentId, let placement, let payout):
            executeRecordTournamentResult(bugId: bugId, tournamentId: tournamentId, placement: placement, payout: payout)
            
        case .burnTokensForUtility(let userId, let utilityType, let amount):
            executeBurnTokensForUtility(userId: userId, utilityType: utilityType, amount: amount)
        }
    }
    
    // MARK: - Operation Execution (Simplified for now)
    
    private func executeBugNFTMinting(bug: Bug, event: EvolutionEvent?) {
        // In production, this would make actual blockchain calls
        print("🧬 Minting Bug NFT for \(bug.id) - Generation \(bug.generation)")
        
        // Simulate blockchain transaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("✅ Bug NFT minted successfully - Token ID: \(UInt64.random(in: 1000...9999))")
        }
    }
    
    private func executeUpdateBugPerformance(tokenId: String, bug: Bug) {
        print("📊 Updating performance for Bug NFT \(tokenId)")
    }
    
    private func executeTerritoryNFTMinting(population: Population, territoryData: TerritoryData) {
        print("🌍 Minting Territory NFT for \(population.name)")
    }
    
    private func executeUpdateTerritoryData(tokenId: String, population: Population) {
        print("🗺️ Updating territory data for \(tokenId)")
    }
    
    private func executeRevenueDistribution(biome: BiomeType, amount: Double) {
        print("💰 Distributing \(amount) revenue for \(biome)")
    }
    
    private func executeRecordTournamentResult(bugId: UUID, tournamentId: String, placement: Int, payout: Double) {
        print("🏆 Recording tournament result for \(bugId) - Placement: \(placement)")
    }
    
    private func executeBurnTokensForUtility(userId: String, utilityType: String, amount: Double) {
        print("🔥 Burning \(amount) tokens for \(utilityType)")
    }
    
    // MARK: - Integration with Simulation
    
    /// Hook into simulation engine for automatic blockchain updates
    func attachToSimulation(_ simulationEngine: SimulationEngine) {
        // Store reference for monitoring (simplified approach)
        // In a real implementation, you would add delegate protocols or observers
        print("🔗 BlockchainManager attached to simulation engine")
    }
    
    /// Manually check and handle generation changes (called from simulation)
    func handleGenerationChange(_ generation: Int, bugs: [Bug]) {
        // Check each bug for NFT minting eligibility
        for bug in bugs {
            if shouldMintBugNFT(for: bug) {
                let event: EvolutionEvent = .generationMilestone(generation)
                triggerBugNFTMinting(for: bug, event: event)
            }
        }
    }
    
    /// Handle speciation events (called from simulation)
    func handleSpeciationEvent(_ event: SpeciationEvent) {
        print("🧬 Speciation event detected: \(event.description)")
        // Trigger ultra-rare NFT minting for speciation events
        // Future implementation would mint based on specific event type
    }
    
    /// Handle territory changes (called from simulation)
    func handleTerritoryChange(_ population: Population) {
        if population.isViableSpecies {
            let territoryData = generateTerritoryData(from: population)
            triggerTerritoryNFTMinting(for: population, territoryData: territoryData)
        }
    }
}

// MARK: - Supporting Data Structures

enum QualityTier: String, CaseIterable {
    case poor, fair, good, excellent, prime
}

struct Territory3DBounds {
    let minX, maxX, minY, maxY, minZ, maxZ: Double
}

struct ResourceAbundance {
    let vegetation, minerals, water, insects, nectar, seeds, fungi, detritus: Double
}

struct TerritoryQuality {
    let overallTier: QualityTier
    let resourceAbundance: Double
    let safetyRating: Double
    let carryingCapacity: UInt32
    let accessibility: Double
    let strategicValue: Double
}

struct PopulationStats {
    let currentPopulation: UInt32
    let maxPopulation: UInt32
    let dominantSpecies: String
}
