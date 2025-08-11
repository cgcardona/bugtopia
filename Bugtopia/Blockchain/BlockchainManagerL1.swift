//
//  BlockchainManagerL1.swift
//  Bugtopia
//
//  Avalanche L1 Blockchain Manager for native BUG token and ERC-1155 NFTs
//

import Foundation
import Combine
import SwiftUI

/// Manages blockchain integration for Bugtopia on Avalanche L1
@Observable
class BlockchainManagerL1 {
    
    // MARK: - Configuration
    
    /// Avalanche L1 network configuration
    struct L1NetworkConfig {
        let chainId: Int
        let rpcUrl: String
        let nativeToken: String
        let explorerUrl: String
        let contractAddresses: ContractAddresses
    }
    
    /// Smart contract addresses on L1
    struct ContractAddresses {
        let bugtopiaL1: String      // Native token economics
        let collectibles: String     // ERC-1155 for all NFTs
        let governance: String       // DAO governance
    }
    
    // MARK: - State
    
    /// Current L1 network configuration
    private var networkConfig: L1NetworkConfig
    
    /// Native BUG token balance
    var bugBalance: Double = 0.0
    
    /// Connection status to L1
    var isConnected: Bool = false
    
    /// Gas price in BUG (native token)
    var gasPrice: Double = 25_000_000_000 // 25 gwei equivalent
    
    /// Queue for blockchain operations
    private let operationQueue = DispatchQueue(label: "bugtopia.l1.operations", qos: .utility)
    
    /// Pending operations
    private var pendingOperations: [L1Operation] = []
    
    /// Last sync with L1
    var lastSyncTime: Date = Date()
    
    // MARK: - Operation Types
    
    enum L1Operation {
        case mintBugDNA(bug: Bug, recipient: String)
        case mintTerritory(population: Population, recipient: String)
        case stakeOnTerritory(tokenId: UInt256, amount: Double)
        case payUtilityFee(type: String, amount: Double)
        case distributeRevenue(tokenId: UInt256, recipients: [String], amounts: [Double])
        case burnBug(amount: Double, reason: String)
    }
    
    // MARK: - NFT Categories
    
    enum NFTCategory: UInt256 {
        case bugDNA = 0
        case territory = 1000000
        case artifact = 2000000
        case achievement = 3000000
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize with local L1 configuration
        self.networkConfig = L1NetworkConfig(
            chainId: 68420,
            rpcUrl: "http://127.0.0.1:9650/ext/bc/bugtopia-l1/rpc",
            nativeToken: "BUG",
            explorerUrl: "http://127.0.0.1:9650/ext/bc/bugtopia-l1",
            contractAddresses: ContractAddresses(
                bugtopiaL1: "", // Will be set after deployment
                collectibles: "",
                governance: ""
            )
        )
        
        connectToL1()
        startOperationProcessor()
    }
    
    // MARK: - L1 Connection
    
    /// Connect to Bugtopia L1
    private func connectToL1() {
        operationQueue.async { [weak self] in
            // Simulate L1 connection
            sleep(1)
            
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.lastSyncTime = Date()
                print("🔗 Connected to Bugtopia L1 (Chain ID: 68420)")
                self?.refreshBugBalance()
            }
        }
    }
    
    /// Refresh native BUG balance
    private func refreshBugBalance() {
        operationQueue.async { [weak self] in
            // In real implementation, query L1 for balance
            let mockBalance = 1000.0 // Simulated BUG balance
            
            DispatchQueue.main.async {
                self?.bugBalance = mockBalance
            }
        }
    }
    
    // MARK: - NFT Minting (ERC-1155)
    
    /// Mint Bug DNA NFT (ERC-1155)
    func mintBugDNA(for bug: Bug, to recipient: String) {
        let operation = L1Operation.mintBugDNA(bug: bug, recipient: recipient)
        queueOperation(operation)
    }
    
    /// Mint Territory NFT (ERC-1155)
    func mintTerritory(for population: Population, to recipient: String) {
        let operation = L1Operation.mintTerritory(population: population, recipient: recipient)
        queueOperation(operation)
    }
    
    /// Batch mint multiple NFTs (gas efficient with ERC-1155)
    func batchMintNFTs(operations: [L1Operation]) {
        for operation in operations {
            queueOperation(operation)
        }
    }
    
    // MARK: - Native Token Operations
    
    /// Pay utility fee in native BUG
    func payUtilityFee(type: String, amount: Double) {
        let operation = L1Operation.payUtilityFee(type: type, amount: amount)
        queueOperation(operation)
    }
    
    /// Burn BUG tokens (deflationary mechanism)
    func burnBug(amount: Double, reason: String) {
        let operation = L1Operation.burnBug(amount: amount, reason: reason)
        queueOperation(operation)
    }
    
    /// Transfer native BUG tokens
    func transferBug(to recipient: String, amount: Double) -> Bool {
        guard bugBalance >= amount else {
            print("❌ Insufficient BUG balance: \(bugBalance) < \(amount)")
            return false
        }
        
        operationQueue.async { [weak self] in
            // Simulate native token transfer
            print("💰 Transferring \(amount) BUG to \(recipient)")
            
            DispatchQueue.main.async {
                self?.bugBalance -= amount
            }
        }
        
        return true
    }
    
    // MARK: - Territory Staking
    
    /// Stake BUG tokens on territory for revenue sharing
    func stakeOnTerritory(tokenId: UInt256, amount: Double) {
        guard bugBalance >= amount else {
            print("❌ Insufficient BUG for staking: \(bugBalance) < \(amount)")
            return
        }
        
        let operation = L1Operation.stakeOnTerritory(tokenId: tokenId, amount: amount)
        queueOperation(operation)
    }
    
    /// Distribute revenue to territory stakeholders
    func distributeRevenue(tokenId: UInt256, recipients: [String], amounts: [Double]) {
        let operation = L1Operation.distributeRevenue(tokenId: tokenId, recipients: recipients, amounts: amounts)
        queueOperation(operation)
    }
    
    // MARK: - Operation Processing
    
    /// Queue blockchain operation for processing
    private func queueOperation(_ operation: L1Operation) {
        pendingOperations.append(operation)
        processNextOperation()
    }
    
    /// Start the operation processor
    private func startOperationProcessor() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.processNextOperation()
        }
    }
    
    /// Process the next pending operation
    private func processNextOperation() {
        guard !pendingOperations.isEmpty, isConnected else { return }
        
        let operation = pendingOperations.removeFirst()
        
        operationQueue.async { [weak self] in
            self?.executeOperation(operation)
        }
    }
    
    /// Execute a blockchain operation
    private func executeOperation(_ operation: L1Operation) {
        switch operation {
        case .mintBugDNA(let bug, let recipient):
            executeMintBugDNA(bug: bug, recipient: recipient)
            
        case .mintTerritory(let population, let recipient):
            executeMintTerritory(population: population, recipient: recipient)
            
        case .stakeOnTerritory(let tokenId, let amount):
            executeStakeOnTerritory(tokenId: tokenId, amount: amount)
            
        case .payUtilityFee(let type, let amount):
            executePayUtilityFee(type: type, amount: amount)
            
        case .distributeRevenue(let tokenId, let recipients, let amounts):
            executeDistributeRevenue(tokenId: tokenId, recipients: recipients, amounts: amounts)
            
        case .burnBug(let amount, let reason):
            executeBurnBug(amount: amount, reason: reason)
        }
    }
    
    // MARK: - Operation Implementations
    
    private func executeMintBugDNA(bug: Bug, recipient: String) {
        print("🧬 Minting Bug DNA NFT for \(bug.id)")
        
        // Calculate minting fee
        let mintingFee = calculateNFTMintingFee(rarity: calculateBugRarity(bug))
        
        // In real implementation, call smart contract
        // collectibles.mintBugDNA(to: recipient, bugData: bugData)
        
        DispatchQueue.main.async { [weak self] in
            self?.bugBalance -= mintingFee
            print("✅ Bug DNA NFT minted! Fee: \(mintingFee) BUG")
        }
    }
    
    private func executeMintTerritory(population: Population, recipient: String) {
        print("🏔️ Minting Territory NFT for population \(population.id)")
        
        let mintingFee = 0.01 // Fixed territory minting fee
        
        DispatchQueue.main.async { [weak self] in
            self?.bugBalance -= mintingFee
            print("✅ Territory NFT minted! Fee: \(mintingFee) BUG")
        }
    }
    
    private func executeStakeOnTerritory(tokenId: UInt256, amount: Double) {
        print("🏦 Staking \(amount) BUG on Territory #\(tokenId)")
        
        DispatchQueue.main.async { [weak self] in
            self?.bugBalance -= amount
            print("✅ Staked \(amount) BUG on territory")
        }
    }
    
    private func executePayUtilityFee(type: String, amount: Double) {
        print("💳 Paying \(amount) BUG for \(type)")
        
        // Native token fees automatically go to validators/network
        DispatchQueue.main.async { [weak self] in
            self?.bugBalance -= amount
            print("✅ Utility fee paid: \(amount) BUG")
        }
    }
    
    private func executeDistributeRevenue(tokenId: UInt256, recipients: [String], amounts: [Double]) {
        let totalAmount = amounts.reduce(0, +)
        print("💰 Distributing \(totalAmount) BUG revenue for Territory #\(tokenId)")
        
        // In real implementation, send to each recipient
        print("✅ Revenue distributed to \(recipients.count) stakeholders")
    }
    
    private func executeBurnBug(amount: Double, reason: String) {
        print("🔥 Burning \(amount) BUG - Reason: \(reason)")
        
        DispatchQueue.main.async { [weak self] in
            self?.bugBalance -= amount
            print("✅ \(amount) BUG burned permanently")
        }
    }
    
    // MARK: - Utility Functions
    
    /// Calculate Bug DNA rarity (0-100)
    private func calculateBugRarity(_ bug: Bug) -> Double {
        var rarity = 50.0 // Base rarity
        
        // Fitness contribution
        rarity += bug.fitness / 4.0
        
        // Age contribution
        rarity += min(bug.age / 1000.0 * 15.0, 15.0)
        
        // Neural complexity
        if let neuralDNA = bug.dna.neuralDNA {
            rarity += Double(neuralDNA.layers.count) * 2.0
        }
        
        return min(rarity, 100.0)
    }
    
    /// Calculate NFT minting fee based on rarity
    private func calculateNFTMintingFee(rarity: Double) -> Double {
        let baseFee = 0.001 // 0.001 BUG base
        let rarityMultiplier = 1.0 + (rarity / 100.0) // 1x to 2x based on rarity
        return baseFee * rarityMultiplier
    }
    
    /// Check if bug should be minted as NFT
    func shouldMintBugNFT(for bug: Bug) -> Bool {
        let rarity = calculateBugRarity(bug)
        let generation = bug.dna.generation
        
        // Mint criteria:
        // - High rarity (>80)
        // - Milestone generations (every 10th)
        // - Exceptional fitness (>90)
        // - Long survival (>500 age)
        
        return rarity > 80 || 
               generation % 10 == 0 ||
               bug.fitness > 90 ||
               bug.age > 500
    }
    
    // MARK: - Integration with Simulation
    
    /// Process evolutionary events for NFT opportunities
    func processEvolutionEvent(_ event: EvolutionEvent, bug: Bug) {
        switch event {
        case .generationMilestone(let generation):
            if generation % 10 == 0 {
                mintBugDNA(for: bug, to: "default_address")
            }
            
        case .perfectFitness:
            mintBugDNA(for: bug, to: "default_address")
            
        case .speciesFormation:
            // Mint special commemorative NFT
            mintBugDNA(for: bug, to: "default_address")
            
        case .exceptionalTrait:
            let rarity = calculateBugRarity(bug)
            if rarity > 85 {
                mintBugDNA(for: bug, to: "default_address")
            }
        }
    }
    
    /// Handle territory events
    func processPopulationEvent(_ population: Population) {
        if population.isViableSpecies && population.members.count > 50 {
            mintTerritory(for: population, to: "default_address")
        }
    }
    
    // MARK: - Network Management
    
    /// Switch to different network (local, fuji, mainnet)
    func switchNetwork(to network: String) {
        switch network.lowercased() {
        case "local":
            networkConfig = L1NetworkConfig(
                chainId: 68420,
                rpcUrl: "http://127.0.0.1:9650/ext/bc/bugtopia-l1/rpc",
                nativeToken: "BUG",
                explorerUrl: "http://127.0.0.1:9650/ext/bc/bugtopia-l1",
                contractAddresses: networkConfig.contractAddresses
            )
            
        case "fuji":
            networkConfig = L1NetworkConfig(
                chainId: 68420,
                rpcUrl: "https://api.avax-test.network/ext/bc/bugtopia-l1/rpc",
                nativeToken: "BUG",
                explorerUrl: "https://testnet.snowtrace.io",
                contractAddresses: networkConfig.contractAddresses
            )
            
        case "mainnet":
            networkConfig = L1NetworkConfig(
                chainId: 68420,
                rpcUrl: "https://api.avax.network/ext/bc/bugtopia-l1/rpc",
                nativeToken: "BUG",
                explorerUrl: "https://snowtrace.io",
                contractAddresses: networkConfig.contractAddresses
            )
            
        default:
            print("❌ Unknown network: \(network)")
            return
        }
        
        print("🔄 Switched to \(network) network")
        connectToL1()
    }
    
    /// Get current network info
    func getNetworkInfo() -> (chainId: Int, rpcUrl: String, nativeToken: String) {
        return (networkConfig.chainId, networkConfig.rpcUrl, networkConfig.nativeToken)
    }
    
    /// Set contract addresses after deployment
    func setContractAddresses(bugtopiaL1: String, collectibles: String, governance: String) {
        networkConfig = L1NetworkConfig(
            chainId: networkConfig.chainId,
            rpcUrl: networkConfig.rpcUrl,
            nativeToken: networkConfig.nativeToken,
            explorerUrl: networkConfig.explorerUrl,
            contractAddresses: ContractAddresses(
                bugtopiaL1: bugtopiaL1,
                collectibles: collectibles,
                governance: governance
            )
        )
        
        print("📝 Contract addresses updated:")
        print("   BugtopiaL1: \(bugtopiaL1)")
        print("   Collectibles: \(collectibles)")
        print("   Governance: \(governance)")
    }
}

// MARK: - Evolution Events

enum EvolutionEvent {
    case generationMilestone(Int)
    case perfectFitness
    case speciesFormation
    case exceptionalTrait
}

// MARK: - Type Aliases

typealias UInt256 = UInt
