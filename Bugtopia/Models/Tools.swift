//
//  Tools.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

// MARK: - Tool System

/// Types of tools bugs can create and use
enum ToolType: String, CaseIterable, Codable, Equatable, Hashable {
    case bridge = "bridge"           // Spans water or gaps
    case tunnel = "tunnel"           // Goes through hills/walls
    case shelter = "shelter"         // Provides protection/energy, stores food
    case trap = "trap"               // Captures prey or resources, generates food
    case marker = "marker"           // Navigation/territory marker, marks fertile areas
    case lever = "lever"             // Moves heavy objects, cultivates soil
    case ramp = "ramp"               // Helps climb steep terrain
    case nest = "nest"               // Group reproduction site, food cache
    
    /// Visual representation
    var emoji: String {
        switch self {
        case .bridge: return "🌉"
        case .tunnel: return "🕳️"
        case .shelter: return "🏠"
        case .trap: return "🪤"
        case .marker: return "🚩"
        case .lever: return "🔧"
        case .ramp: return "📐"
        case .nest: return "🪺"
        }
    }
    
    /// Color for rendering
    var color: Color {
        switch self {
        case .bridge: return .brown
        case .tunnel: return .black.opacity(0.8)
        case .shelter: return .gray
        case .trap: return .red.opacity(0.7)
        case .marker: return .purple
        case .lever: return .orange
        case .ramp: return .yellow.opacity(0.8)
        case .nest: return .green.opacity(0.6)
        }
    }
    
    /// Cost to create (energy required)
    var energyCost: Double {
        switch self {
        case .marker: return 5.0
        case .trap: return 10.0
        case .ramp: return 15.0
        case .bridge: return 20.0
        case .shelter: return 25.0
        case .lever: return 30.0
        case .nest: return 35.0
        case .tunnel: return 40.0
        }
    }
    
    /// Time to construct (in ticks)
    var constructionTime: Int {
        switch self {
        case .marker: return 30      // 1 second at 30 FPS
        case .trap: return 60        // 2 seconds
        case .ramp: return 90        // 3 seconds
        case .bridge: return 120     // 4 seconds
        case .shelter: return 150    // 5 seconds
        case .lever: return 180      // 6 seconds
        case .nest: return 210       // 7 seconds
        case .tunnel: return 300     // 10 seconds
        }
    }
}

/// A tool created by bugs in the world
struct Tool: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let type: ToolType
    let position: CGPoint
    let creatorId: UUID
    let creationTime: TimeInterval
    var durability: Double         // 0.0 to 1.0, decreases over time
    var uses: Int                  // Number of times used
    let generation: Int            // Generation when created
    var storedFood: [FoodItem] = []  // Food items stored in this tool
    var lastFoodGeneration: TimeInterval = 0.0  // When food was last generated
    
    /// Size of the tool for collision detection
    var size: CGSize {
        switch type {
        case .marker:
            return CGSize(width: 8, height: 8)
        case .trap, .ramp:
            return CGSize(width: 20, height: 20)
        case .bridge:
            return CGSize(width: 40, height: 20)
        case .tunnel:
            return CGSize(width: 30, height: 30)
        case .shelter, .nest:
            return CGSize(width: 50, height: 50)
        case .lever:
            return CGSize(width: 15, height: 25)
        }
    }
    
    /// Bounding rectangle for the tool
    var bounds: CGRect {
        return CGRect(
            x: position.x - size.width/2,
            y: position.y - size.height/2,
            width: size.width,
            height: size.height
        )
    }
    
    /// Whether the tool is still functional
    var isUsable: Bool {
        return durability > 0.1
    }
    
    /// Degrades the tool over time
    mutating func degrade(by amount: Double = 0.001) {
        durability = max(0.0, durability - amount)
    }
    
    /// Use the tool (increases usage, may degrade)
    mutating func use() {
        uses += 1
        // Tools degrade with use
        let usageDecay = type.energyCost / 1000.0 // More expensive tools decay slower per use
        durability = max(0.0, durability - usageDecay)
    }
    
    /// Whether this tool can generate food automatically
    var canGenerateFood: Bool {
        switch type {
        case .trap, .nest, .shelter: return true
        default: return false
        }
    }
    
    /// Food generation rate (food items per 100 ticks, when applicable)
    var foodGenerationRate: Double {
        guard canGenerateFood else { return 0.0 }
        let baseRate = durability * 0.8 // Higher durability = better food generation
        switch type {
        case .trap: return baseRate * 0.15      // Traps catch prey/insects for meat
        case .nest: return baseRate * 0.25      // Nests cultivate nearby food sources
        case .shelter: return baseRate * 0.10   // Shelters store and preserve food
        default: return 0.0
        }
    }
    
    /// Whether this tool can store food for later use
    var canStoreFood: Bool {
        switch type {
        case .shelter, .nest: return true
        default: return false
        }
    }
    
    /// Maximum food storage capacity
    var foodStorageCapacity: Int {
        guard canStoreFood else { return 0 }
        switch type {
        case .shelter: return 8  // Shelters can store moderate amounts
        case .nest: return 12    // Nests are specialized for resource management
        default: return 0
        }
    }
    
    /// Whether this tool can cultivate food sources (enhance nearby food spawn rates)
    var canCultivateFood: Bool {
        switch type {
        case .lever, .marker: return true
        default: return false
        }
    }
    
    /// Cultivation radius (area where food spawn rate is enhanced)
    var cultivationRadius: Double {
        guard canCultivateFood else { return 0.0 }
        switch type {
        case .lever: return 80.0   // Levers till soil in a wide area
        case .marker: return 40.0  // Markers identify fertile zones
        default: return 0.0
        }
    }
    
    /// Food spawn rate multiplier in cultivation area
    var cultivationMultiplier: Double {
        guard canCultivateFood else { return 1.0 }
        let efficiency = durability * 0.9 // Better durability = better cultivation
        switch type {
        case .lever: return 1.0 + (efficiency * 1.5)  // Up to 2.5x food spawn rate
        case .marker: return 1.0 + (efficiency * 0.8)  // Up to 1.8x food spawn rate
        default: return 1.0
        }
    }
    
    // MARK: - Food Management
    
    /// Whether this tool has space to store more food
    var hasStorageSpace: Bool {
        guard canStoreFood else { return false }
        return storedFood.count < foodStorageCapacity
    }
    
    /// Store a food item in this tool (returns true if successful)
    mutating func storeFood(_ food: FoodItem) -> Bool {
        guard hasStorageSpace else { return false }
        storedFood.append(food)
        return true
    }
    
    /// Retrieve a stored food item (returns nil if empty)
    mutating func retrieveFood() -> FoodItem? {
        guard !storedFood.isEmpty else { return nil }
        return storedFood.removeFirst()
    }
    
    /// Generate food based on tool type and generation rate
    mutating func generateFood(biome: BiomeType, season: Season) -> FoodItem? {
        guard canGenerateFood else { return nil }
        
        let currentTime = Date().timeIntervalSince1970
        let timeSinceLastGeneration = currentTime - lastFoodGeneration
        
        // Check if enough time has passed for food generation (stochastic based on rate)
        let generationInterval = 100.0 / max(0.01, foodGenerationRate) // Ticks between generations
        guard timeSinceLastGeneration > generationInterval else { return nil }
        
        // Random chance for food generation
        guard Double.random(in: 0...1) < (foodGenerationRate / 100.0) else { return nil }
        
        // Generate appropriate food type based on tool
        let (foodType, targetSpecies) = generateFoodTypeForTool(biome: biome, season: season)
        
        // Create slight position offset for the generated food
        let offsetPosition = CGPoint(
            x: position.x + Double.random(in: -15...15),
            y: position.y + Double.random(in: -15...15)
        )
        
        lastFoodGeneration = currentTime
        
        return FoodItem(position: offsetPosition, type: foodType, targetSpecies: targetSpecies)
    }
    
    /// Determines appropriate food type based on tool type and environment
    private func generateFoodTypeForTool(biome: BiomeType, season: Season) -> (FoodType, SpeciesType) {
        switch type {
        case .trap:
            // Traps catch prey - primarily meat and fish
            let targetSpecies: SpeciesType = Double.random(in: 0...1) < 0.8 ? .carnivore : .scavenger
            let foodType = FoodType.randomFoodFor(species: targetSpecies, biome: biome, season: season)
            return (foodType, targetSpecies)
            
        case .nest:
            // Nests cultivate diverse food sources - all types
            let allSpecies: [SpeciesType] = [.herbivore, .omnivore, .carnivore, .scavenger]
            let targetSpecies = allSpecies.randomElement() ?? .herbivore
            let foodType = FoodType.randomFoodFor(species: targetSpecies, biome: biome, season: season)
            return (foodType, targetSpecies)
            
        case .shelter:
            // Shelters preserve food - primarily long-lasting foods
            let targetSpecies: SpeciesType = Double.random(in: 0...1) < 0.7 ? .herbivore : .omnivore
            let foodType = FoodType.randomFoodFor(species: targetSpecies, biome: biome, season: season)
            return (foodType, targetSpecies)
            
        default:
            // Fallback
            let foodType = FoodType.randomFoodFor(species: .herbivore, biome: biome, season: season)
            return (foodType, .herbivore)
        }
    }
}

// MARK: - Resource System

/// Materials that bugs can collect and use
enum ResourceType: String, CaseIterable, Codable, Equatable, Hashable {
    case stick = "stick"             // Basic construction material
    case stone = "stone"             // Heavy-duty construction
    case mud = "mud"                 // Moldable material
    case fiber = "fiber"             // Flexible material
    case food = "food"               // Stored energy
    
    /// Visual representation
    var emoji: String {
        switch self {
        case .stick: return "🪵"
        case .stone: return "🪨" 
        case .mud: return "🟤"
        case .fiber: return "🧵"
        case .food: return "🫘"
        }
    }
    
    /// Color for rendering
    var color: Color {
        switch self {
        case .stick: return .brown
        case .stone: return .gray
        case .mud: return .brown.opacity(0.7)
        case .fiber: return .green
        case .food: return .orange
        }
    }
    
    /// Weight (affects carrying capacity)
    var weight: Double {
        switch self {
        case .fiber: return 0.5
        case .food: return 1.0
        case .stick: return 1.5
        case .mud: return 2.0
        case .stone: return 3.0
        }
    }
}

/// A resource node in the world
struct Resource: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let type: ResourceType
    let position: CGPoint
    var quantity: Int              // How much resource is available
    let respawnRate: Double        // How fast it regenerates (per tick)
    var lastHarvest: TimeInterval  // When it was last harvested
    
    /// Whether the resource can be harvested
    var isAvailable: Bool {
        return quantity > 0
    }
    
    /// Harvest some of the resource
    mutating func harvest(amount: Int = 1) -> Int {
        let harvested = min(amount, quantity)
        quantity -= harvested
        lastHarvest = Date().timeIntervalSince1970
        return harvested
    }
    
    /// Regenerate resource over time
    mutating func regenerate() {
        let currentTime = Date().timeIntervalSince1970
        let timePassed = currentTime - lastHarvest
        let maxQuantity = 10 // Maximum resource at any location
        
        if quantity < maxQuantity {
            let regeneration = timePassed * respawnRate
            quantity = min(maxQuantity, quantity + Int(regeneration))
        }
    }
}

// MARK: - Construction System

/// Blueprint for tools before they're built
struct ToolBlueprint: Codable, Equatable, Hashable {
    let type: ToolType
    let position: CGPoint
    let requiredResources: [ResourceType: Int]  // What materials are needed
    var gatheredResources: [ResourceType: Int]  // What has been collected
    let builderId: UUID
    let startTime: TimeInterval
    var workProgress: Int          // Construction progress in ticks
    
    /// Whether enough resources have been gathered
    var hasAllResources: Bool {
        for (resourceType, required) in requiredResources {
            let gathered = gatheredResources[resourceType] ?? 0
            if gathered < required {
                return false
            }
        }
        return true
    }
    
    /// Whether construction is complete
    var isComplete: Bool {
        return hasAllResources && workProgress >= type.constructionTime
    }
    
    /// Progress as a percentage
    var completionPercentage: Double {
        let resourceProgress = hasAllResources ? 0.5 : 0.0
        let buildProgress = min(0.5, Double(workProgress) / Double(type.constructionTime) * 0.5)
        return resourceProgress + buildProgress
    }
    
    /// Add resources to the blueprint
    mutating func addResource(type: ResourceType, amount: Int) {
        let current = gatheredResources[type] ?? 0
        let required = requiredResources[type] ?? 0
        gatheredResources[type] = min(required, current + amount)
    }
    
    /// Work on construction
    mutating func addWork(ticks: Int = 1) {
        if hasAllResources {
            workProgress += ticks
        }
    }
}

// MARK: - Tool Use DNA

/// Genetic traits for tool creation and use
struct ToolDNA: Codable, Equatable, Hashable {
    /// How well this bug can create tools (0.0 to 1.0)
    let toolCrafting: Double
    
    /// How efficiently this bug can use tools (0.0 to 1.0)
    let toolProficiency: Double
    
    /// How far this bug can see tool opportunities (0.0 to 1.0)
    let toolVision: Double
    
    /// How much this bug values building vs other activities (0.0 to 1.0)
    let constructionDrive: Double
    
    /// How well this bug can carry resources (affects carrying capacity)
    let carryingCapacity: Double
    
    /// How efficiently this bug can gather resources (0.0 to 1.0)
    let resourceGathering: Double
    
    /// How well this bug can plan complex constructions (0.0 to 1.0)
    let engineeringIntelligence: Double
    
    /// How willing this bug is to cooperate on construction projects (0.0 to 1.0)
    let collaborationTendency: Double
    
    // MARK: - Generation
    
    static func random() -> ToolDNA {
        return ToolDNA(
            toolCrafting: Double.random(in: 0.0...1.0),
            toolProficiency: Double.random(in: 0.0...1.0),
            toolVision: Double.random(in: 0.0...1.0),
            constructionDrive: Double.random(in: 0.0...1.0),
            carryingCapacity: Double.random(in: 0.2...2.0), // Wider range for capacity
            resourceGathering: Double.random(in: 0.0...1.0),
            engineeringIntelligence: Double.random(in: 0.0...1.0),
            collaborationTendency: Double.random(in: 0.0...1.0)
        )
    }
    
    // MARK: - Genetic Operations
    
    func mutated(mutationRate: Double = 0.1, mutationStrength: Double = 0.2) -> ToolDNA {
        return ToolDNA(
            toolCrafting: mutateValue(toolCrafting, rate: mutationRate, strength: mutationStrength),
            toolProficiency: mutateValue(toolProficiency, rate: mutationRate, strength: mutationStrength),
            toolVision: mutateValue(toolVision, rate: mutationRate, strength: mutationStrength),
            constructionDrive: mutateValue(constructionDrive, rate: mutationRate, strength: mutationStrength),
            carryingCapacity: mutateValue(carryingCapacity, rate: mutationRate, strength: mutationStrength, min: 0.2, max: 2.0),
            resourceGathering: mutateValue(resourceGathering, rate: mutationRate, strength: mutationStrength),
            engineeringIntelligence: mutateValue(engineeringIntelligence, rate: mutationRate, strength: mutationStrength),
            collaborationTendency: mutateValue(collaborationTendency, rate: mutationRate, strength: mutationStrength)
        )
    }
    
    static func crossover(parent1: ToolDNA, parent2: ToolDNA) -> ToolDNA {
        return ToolDNA(
            toolCrafting: Double.random(in: 0...1) < 0.5 ? parent1.toolCrafting : parent2.toolCrafting,
            toolProficiency: Double.random(in: 0...1) < 0.5 ? parent1.toolProficiency : parent2.toolProficiency,
            toolVision: Double.random(in: 0...1) < 0.5 ? parent1.toolVision : parent2.toolVision,
            constructionDrive: Double.random(in: 0...1) < 0.5 ? parent1.constructionDrive : parent2.constructionDrive,
            carryingCapacity: Double.random(in: 0...1) < 0.5 ? parent1.carryingCapacity : parent2.carryingCapacity,
            resourceGathering: Double.random(in: 0...1) < 0.5 ? parent1.resourceGathering : parent2.resourceGathering,
            engineeringIntelligence: Double.random(in: 0...1) < 0.5 ? parent1.engineeringIntelligence : parent2.engineeringIntelligence,
            collaborationTendency: Double.random(in: 0...1) < 0.5 ? parent1.collaborationTendency : parent2.collaborationTendency
        )
    }
    
    // MARK: - Helper
    
    private func mutateValue(_ value: Double, rate: Double, strength: Double, min: Double = 0.0, max: Double = 1.0) -> Double {
        guard Double.random(in: 0...1) < rate else { return value }
        let mutation = Double.random(in: -strength...strength)
        return Swift.max(min, Swift.min(max, value + mutation))
    }
}

// MARK: - Construction Recipe System

/// Defines what resources are needed for each tool type
struct ToolRecipes {
    static let recipes: [ToolType: [ResourceType: Int]] = [
        .marker: [.stick: 1],
        .trap: [.stick: 2, .fiber: 1],
        .ramp: [.mud: 2, .stone: 1],
        .bridge: [.stick: 3, .fiber: 2],
        .shelter: [.stick: 2, .stone: 2, .mud: 1],
        .lever: [.stone: 2, .stick: 1],
        .nest: [.stick: 3, .fiber: 3, .mud: 2],
        .tunnel: [.stone: 4, .mud: 3]
    ]
    
    static func requiredResources(for toolType: ToolType) -> [ResourceType: Int] {
        return recipes[toolType] ?? [:]
    }
}

// MARK: - Tool Effects

/// Handles the effects of tools on the environment and bugs
struct ToolEffects {
    
    /// Check if a tool affects movement at a position
    static func getMovementModifier(at position: CGPoint, tools: [Tool], for bug: BugDNA) -> Double {
        for tool in tools {
            if tool.bounds.contains(position) && tool.isUsable {
                switch tool.type {
                case .bridge:
                    return 1.2 // Faster movement over water/gaps
                case .ramp:
                    return 1.1 // Easier hill climbing
                case .tunnel:
                    return 1.0 // Normal movement through walls
                default:
                    continue
                }
            }
        }
        return 1.0 // No effect
    }
    
    /// Check if tools allow passage through normally impassable terrain
    static func isPassageAllowed(at position: CGPoint, tools: [Tool]) -> Bool {
        for tool in tools {
            if tool.bounds.contains(position) && tool.isUsable {
                switch tool.type {
                case .bridge, .tunnel:
                    return true // These tools allow passage
                default:
                    continue
                }
            }
        }
        return false
    }
    
    /// Get energy bonus from tools (shelters, nests)
    static func getEnergyBonus(at position: CGPoint, tools: [Tool]) -> Double {
        for tool in tools {
            if tool.bounds.contains(position) && tool.isUsable {
                switch tool.type {
                case .shelter:
                    return 2.0 // Energy recovery bonus
                case .nest:
                    return 1.5 // Breeding energy bonus
                default:
                    continue
                }
            }
        }
        return 0.0
    }
}