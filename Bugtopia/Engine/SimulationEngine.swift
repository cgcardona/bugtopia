//
//  SimulationEngine.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI
import Combine

/// Manages the entire evolutionary simulation including population, food, and evolution cycles
@Observable
class SimulationEngine {
    
    // MARK: - Simulation State
    
    var bugs: [Bug] = []
    var foods: [FoodItem] = []
    var signals: [Signal] = []     // Active signals in the world
    var groups: [BugGroup] = []    // Active bug groups
    var tools: [Tool] = []         // Constructed tools in the world
    var resources: [Resource] = [] // Resource nodes for gathering
    var blueprints: [ToolBlueprint] = [] // Construction projects in progress
    var speciationManager = SpeciationManager() // Population and speciation tracking
    var seasonalManager = SeasonalManager()     // Dynamic seasonal system
    var weatherManager = WeatherManager()       // Dynamic weather patterns
    var disasterManager = DisasterManager()     // Natural disasters and terrain reshaping
    var ecosystemManager = EcosystemManager()   // Resource depletion and ecosystem cycles
    var territoryManager = TerritoryManager()   // Migration and territorial behaviors
    var isRunning = false
    var currentGeneration = 0
    var tickCount = 0
    
    // MARK: - World Configuration
    
    let voxelWorld: VoxelWorld
    let pathfinding: VoxelPathfinding
    private let maxPopulation = 800  // MASSIVE INCREASE: 4.4x more bugs for extensive debugging
    private let initialPopulation = 20    // 🐛 DEBUG: Drastically reduced population for easier debugging
    private let maxFoodItems = 5000  // MASSIVE INCREASE: 4.2x more food to eliminate food scarcity
    private let baseFoodSpawnRate = 0.99 // MAXIMUM: Near-constant food spawning for abundant resources
    
    // MARK: - Evolution Parameters
    
    let generationLength = 500 // Ticks per generation (public for UI)
    private let survivalRate = 0.3 // Fraction that survives to next generation
    private let eliteRate = 0.1 // Fraction of best bugs that survive automatically
    
    // MARK: - Statistics
    
    private(set) var statistics = SimulationStatistics()
    
    // MARK: - Timer
    
    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0 / 30.0 // 30 FPS
    
    // MARK: - Initialization
    
    init(worldBounds: CGRect) {
        // 🎯 HARDCODED CONTINENTAL WORLD: Focus on perfecting one world type first
        let worldType = WorldType3D.continental3D

        
        // 🔧 STABLE RESOLUTION: 32x32x32 for reliable performance
        // NOTE: Higher resolutions (48³+) cause rendering hangs - need async/LOD system first
        self.voxelWorld = VoxelWorld(bounds: worldBounds, worldType: worldType, resolution: 32)
        self.pathfinding = VoxelPathfinding(voxelWorld: voxelWorld)
        ecosystemManager.setWorldBounds(worldBounds)
        setupInitialPopulation()
        spawnInitialFood()
    }
    
    // MARK: - Simulation Control
    
    /// Starts the simulation
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            self.tick()
        }
    }
    
    /// Pauses the simulation
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    /// Resets the simulation to initial state
    func reset() {
        pause()
        bugs.removeAll()
        foods.removeAll()
        signals.removeAll()
        groups.removeAll()
        tools.removeAll()
        resources.removeAll()
        blueprints.removeAll()
        speciationManager = SpeciationManager() // Reset speciation tracking
        seasonalManager.reset() // Reset seasonal cycle
        weatherManager.reset() // Reset weather patterns
        disasterManager.reset() // Reset disaster system
        disasterManager.setWorldBounds(voxelWorld.worldBounds) // Set disaster spawn area
        ecosystemManager.reset() // Reset ecosystem state
        ecosystemManager.setWorldBounds(voxelWorld.worldBounds) // Set world bounds for population density
        // Ecosystem now uses VoxelWorld directly - no legacy Arena needed
        territoryManager.reset() // Reset territorial data
        // Set territory boundaries using voxel world bounds
        let minPos = Position3D(voxelWorld.worldBounds.minX, voxelWorld.worldBounds.minY, -50.0)
        let maxPos = Position3D(voxelWorld.worldBounds.maxX, voxelWorld.worldBounds.maxY, 50.0)
        territoryManager.setWorldBounds3D(min: minPos, max: maxPos)
        currentGeneration = 0
        tickCount = 0
        statistics = SimulationStatistics()
        
        setupInitialPopulation()
        spawnInitialFood()
        spawnInitialResources()
    }
    
    /// Advances the simulation by one tick
    func step() {
        tick()
    }
    
    /// Forces evolution to the next generation
    func evolveNextGeneration() {
        evolvePopulation()
    }
    
    // MARK: - Main Simulation Loop
    
    /// Executes one simulation tick
    private func tick() {
        tickCount += 1
        
        // Update all bugs with neural decisions first, then movement
        var newSignals: [Signal] = []
        for bug in bugs {
            // 🧠 FIRST: Make neural network decisions and update behaviors
            bug.update(
                in: createVoxelArenaAdapter(),
                foods: foods,
                otherBugs: bugs,
                seasonalManager: seasonalManager,
                weatherManager: weatherManager,
                disasterManager: disasterManager,
                ecosystemManager: ecosystemManager,
                territoryManager: territoryManager
            )
            
            // 🚶 SECOND: Use fresh neural decisions for voxel-based movement
            // 🔧 CONTINENTAL WORLD FIX: Disable voxel pathfinding to prevent Z-axis conflicts
            // For Continental world, use only the 2D movement system in bug.update()
            // bug.updateVoxelPosition(in: voxelWorld, pathfinding: pathfinding, decision: bug.lastDecision ?? BugOutputs.zero)
            
            // Let bug generate signals
            if let signal = bug.generateSignals(in: createVoxelArenaAdapter(), foods: foods, otherBugs: bugs) {
                newSignals.append(signal)
            }
        }
        
        // Add new signals to the world
        signals.append(contentsOf: newSignals)
        
        // Distribute signals to nearby bugs
        distributeSignals()
        
        // Clean up expired signals
        cleanupSignals()
        
        // Update tools and construction
        updateToolsAndConstruction()
        
        // Handle reproduction
        handleReproduction()
        
        // Remove dead bugs
        bugs.removeAll { !$0.isAlive }
        
        // Spawn food
        spawnFood()
        
        // Remove consumed food
        removeConsumedFood()
        
        // Update seasonal system
        seasonalManager.update()
        
        // Update weather patterns
        weatherManager.update(seasonalManager: seasonalManager)
        
        // Update natural disasters
        disasterManager.update(seasonalManager: seasonalManager, weatherManager: weatherManager)
        
        // Update ecosystem dynamics and resource health
        ecosystemManager.update(
            bugs: bugs,
            foods: foods,
            generationCount: currentGeneration,
            deltaTime: tickInterval
        )
        
        // Update territories and migrations (using 2D compatibility)
        territoryManager.update(
            populations: speciationManager.populations,
            arena: createVoxelArenaAdapter(),
            ecosystemManager: ecosystemManager
        )
        
        // Update populations and speciation (using 2D compatibility)
        speciationManager.updatePopulations(bugs: bugs, generation: currentGeneration, arena: createVoxelArenaAdapter())
        
        // Clean up old speciation events every 50 ticks to prevent memory buildup
        if tickCount % 50 == 0 {
            speciationManager.cleanupOldEvents()
        }
        
        // Update statistics
        updateStatistics()
        
        // Check for generation end
        if shouldEndGeneration() {
            evolvePopulation()
        }
        
        // Only repopulate if population is extremely critically low
        if bugs.count < 2 { // Almost never repopulate - let natural selection work
            repopulateFromSurvivors()
        }
    }
    
    // MARK: - Population Management
    
    /// Sets up the initial random population using voxel world spawn points
    private func setupInitialPopulation() {
        // SimulationEngine: Creating initial population
        bugs = (0..<initialPopulation).map { index in
            let spawnPosition3D = voxelWorld.findSpawnPosition()
            let surfacePosition = calculateSurfaceSpawnPosition(spawnPosition3D)
            let bug = Bug(dna: BugDNA.random(), position3D: surfacePosition, generation: 0)
            if index < 3 {
                // Bug spawned at surface position
            }
            return bug
        }
        // SimulationEngine: Created bugs successfully
    }
    
    /// Calculate proper surface position for spawning bugs
    private func calculateSurfaceSpawnPosition(_ position3D: Position3D) -> Position3D {
        // 🔧 CONTINENTAL WORLD FIX: Use consistent fixed height to prevent terrain jumping
        // Variable terrain heights (-18 to +21) were causing visual jumping behavior
        return Position3D(
            position3D.x,
            position3D.y,
            8.0  // Fixed height matching visual positioning - eliminates terrain-induced jumping
        )
    }
    
    /// Handles reproduction between compatible bugs with speciation constraints (seasonally adjusted)
    private func handleReproduction() {
        let reproducableBugs = bugs.filter { $0.canReproduce(seasonalManager: seasonalManager) }
        var newBugs: [Bug] = []
        
        for i in 0..<reproducableBugs.count {
            let bug1 = reproducableBugs[i]
            
            // Find nearby compatible partners
            let nearbyPartners = reproducableBugs[(i+1)...].filter { bug2 in
                bug1.distance(to: bug2.position) < 50.0
            }
            
            // Filter partners by reproductive compatibility
            let compatiblePartners = nearbyPartners.filter { bug2 in
                let compatibility = speciationManager.getReproductiveCompatibility(bug1: bug1, bug2: bug2)
                return compatibility > 0.3 // Minimum compatibility threshold
            }
            
            // Choose partner based on compatibility (higher compatibility = higher chance)
            if let partner = selectMateByCompatibility(compatiblePartners, for: bug1) {
                if let offspring = bug1.reproduce(with: partner, seasonalManager: seasonalManager) {
                    newBugs.append(offspring)
                }
            }
        }
        
        // Add new bugs if population allows
        let newBugsToAdd = min(newBugs.count, maxPopulation - bugs.count)
        bugs.append(contentsOf: Array(newBugs.prefix(newBugsToAdd)))
    }
    
    /// Select a mate based on reproductive compatibility
    private func selectMateByCompatibility(_ candidates: [Bug], for bug: Bug) -> Bug? {
        guard !candidates.isEmpty else { return nil }
        
        // Calculate compatibility scores
        let compatibilityScores = candidates.map { mate in
            speciationManager.getReproductiveCompatibility(bug1: bug, bug2: mate)
        }
        
        // Weighted random selection based on compatibility
        let totalCompatibility = compatibilityScores.reduce(0, +)
        guard totalCompatibility > 0 else { return candidates.randomElement() }
        
        let randomValue = Double.random(in: 0...totalCompatibility)
        var runningSum = 0.0
        
        for (index, compatibility) in compatibilityScores.enumerated() {
            runningSum += compatibility
            if randomValue <= runningSum {
                return candidates[index]
            }
        }
        
        return candidates.last
    }
    
    /// Repopulates from survivors when population gets too low
    private func repopulateFromSurvivors() {
        guard !bugs.isEmpty else {
            setupInitialPopulation()
            return
        }
        
        let survivors = bugs.sorted { $0.energy > $1.energy }
        let neededBugs = max(10, (initialPopulation - bugs.count) / 2) // Less aggressive repopulation
        
        for _ in 0..<neededBugs {
            // Safe random parent selection with fallback to random DNA
            let parent: Bug
            if let randomSurvivor = survivors.randomElement() {
                parent = randomSurvivor
            } else {
                // If no survivors, create completely new bug
                let spawnPosition3D = voxelWorld.findSpawnPosition()
                let surfacePosition = calculateSurfaceSpawnPosition(spawnPosition3D)
                bugs.append(Bug(dna: BugDNA.random(), position3D: surfacePosition, generation: currentGeneration))
                continue
            }
            
            let mutatedDNA = parent.dna.mutated(mutationRate: 0.3, mutationStrength: 0.2)
            let spawnPosition3D = voxelWorld.findSpawnPosition()
            let surfacePosition = calculateSurfaceSpawnPosition(spawnPosition3D)
            bugs.append(Bug(dna: mutatedDNA, position3D: surfacePosition, generation: currentGeneration))
        }
    }
    
    // MARK: - Evolution
    
    /// Determines if the current generation should end
    private func shouldEndGeneration() -> Bool {
        return tickCount % generationLength == 0 || bugs.count < 2 // Allow much more natural population decline
    }
    
    /// Evolves the population to the next generation
    private func evolvePopulation() {
        currentGeneration += 1
        
        // Calculate fitness for all bugs
        let bugsWithFitness = bugs.map { bug in
            (bug, calculateFitness(for: bug))
        }.sorted { $0.1 > $1.1 } // Sort by fitness descending
        
        // Determine survivors
        let eliteCount = max(1, Int(Double(bugs.count) * eliteRate))
        let survivalCount = max(eliteCount, Int(Double(bugs.count) * survivalRate))
        
        // Elite bugs survive automatically
        let elites = Array(bugsWithFitness.prefix(eliteCount)).map { $0.0 }
        
        // Tournament selection for remaining survivors
        var survivors = elites
        for _ in eliteCount..<survivalCount {
            let tournament = Array(bugsWithFitness.shuffled().prefix(3))
            if let winner = tournament.max(by: { $0.1 < $1.1 }) {
                survivors.append(winner.0)
            } else if let fallback = bugsWithFitness.first {
                // If tournament fails, use the best available bug
                survivors.append(fallback.0)
            }
        }
        
        // Generate new population from survivors
        var newPopulation: [Bug] = []
        
        // Add survivors with refreshed energy and reset age
        for survivor in survivors {
            let refreshedBug = Bug(dna: survivor.dna, position3D: survivor.position3D, generation: currentGeneration)
            refreshedBug.energy = Bug.initialEnergy
            newPopulation.append(refreshedBug)
        }
        
        // Fill rest of population with offspring
        while newPopulation.count < initialPopulation {
            // Safe parent selection with fallbacks
            guard let parent1 = survivors.randomElement() else {
                // If no survivors, create random bug
                let randomPosition3D = voxelWorld.findSpawnPosition()
                let surfacePosition = calculateSurfaceSpawnPosition(randomPosition3D)
                newPopulation.append(Bug(dna: BugDNA.random(), position3D: surfacePosition, generation: currentGeneration))
                continue
            }
            
            guard let parent2 = survivors.randomElement() else {
                // If only one survivor, use asexual reproduction (mutation only)
                let mutatedDNA = parent1.dna.mutated(mutationRate: 0.2, mutationStrength: 0.3)
                let childPosition3D = voxelWorld.findSpawnPosition()
                let surfacePosition = calculateSurfaceSpawnPosition(childPosition3D)
                newPopulation.append(Bug(dna: mutatedDNA, position3D: surfacePosition, generation: currentGeneration))
                continue
            }
            
            let childDNA = BugDNA.crossover(parent1.dna, parent2.dna).mutated()
            let childPosition3D = voxelWorld.findSpawnPosition()
            let surfacePosition = calculateSurfaceSpawnPosition(childPosition3D)
            
            newPopulation.append(Bug(dna: childDNA, position3D: surfacePosition, generation: currentGeneration))
        }
        
        bugs = newPopulation
        
        // Update statistics for new generation
        updateGenerationStatistics()
        
                    // Generation evolved
    }
    
    /// Calculates enhanced fitness score considering terrain adaptation
    private func calculateFitness(for bug: Bug) -> Double {
        let survivalBonus = Double(bug.age) / Double(Bug.maxAge) * 100
        let energyBonus = bug.energy
        let reproductionBonus = Double(max(0, bug.age - 100)) * 0.1
        let geneticBonus = bug.dna.geneticFitness * 10
        
        // Terrain adaptation bonus
        // Get terrain at bug position using VoxelWorld
        let position3D = Position3D(bug.position.x, bug.position.y, 0.0) // Surface level
        let currentTerrain = voxelWorld.getVoxel(at: position3D)?.terrainType ?? .open
        let terrainBonus = bug.dna.terrainFitness(for: currentTerrain) * 5
        
        // Exploration bonus for bugs that have been in different terrain types
        let explorationBonus = calculateExplorationBonus(for: bug)
        
        // Neural energy efficiency bonus - reward energy-efficient brains
        let neuralCost = NeuralEnergyManager.calculateNeuralEnergyCost(
            for: bug.dna.neuralDNA, 
            efficiency: bug.dna.neuralEnergyEfficiency
        )
        let intelligence = NeuralEnergyManager.calculateIntelligenceScore(
            for: bug.dna.neuralDNA, 
            efficiency: bug.dna.neuralEnergyEfficiency
        )
        let neuralEfficiencyBonus = (intelligence / max(0.001, neuralCost * 100)) * 2 // Reward intelligence per energy cost
        
        return survivalBonus + energyBonus + reproductionBonus + geneticBonus + terrainBonus + explorationBonus + neuralEfficiencyBonus
    }
    
    /// Calculates bonus for bugs that successfully navigate different terrains
    private func calculateExplorationBonus(for bug: Bug) -> Double {
        // This is a simplified version - in a full implementation, you'd track
        // which terrain types each bug has successfully traversed
        let curiosityBonus = bug.dna.curiosity * 10
        let memoryBonus = bug.dna.memory * 8
        return curiosityBonus + memoryBonus
    }
    
    // MARK: - Compatibility Methods
    
    /// Creates a lightweight Arena adapter that uses VoxelWorld internally
    /// This eliminates duplicate terrain generation while maintaining Bug API compatibility
    private func createVoxelArenaAdapter() -> Arena {
        return VoxelWorldArenaAdapter(voxelWorld: voxelWorld)
    }
    
    // MARK: - Food Management
    
    /// Spawns initial food distribution with diverse food types based on species population
    private func spawnInitialFood() {
        var newFoods: [FoodItem] = []
        
        // Determine dominant species for food type distribution
        let herbivoreFoodRatio = 0.8 // 80% herbivore foods for now
        
        // Spawn food in designated food zones (limited to prevent oversaturation)
        let foodVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == .food }
        for voxel in foodVoxels.prefix(min(20, maxFoodItems / 20)) { // Much more conservative initial food zone spawning
            let randomOffset = CGPoint(
                x: Double.random(in: -15...15),
                y: Double.random(in: -15...15)
            )
            let foodPosition = CGPoint(
                x: voxel.position.x + randomOffset.x,
                y: voxel.position.y + randomOffset.y
            )
            
            // Generate biome and season appropriate food type
            let targetSpecies: SpeciesType = Double.random(in: 0...1) < herbivoreFoodRatio ? .herbivore : .carnivore
            let foodType = FoodType.randomFoodFor(species: targetSpecies, biome: voxel.biome, season: seasonalManager.currentSeason)
            let foodItem = FoodItem(position: foodPosition, type: foodType, targetSpecies: targetSpecies)
            newFoods.append(foodItem)
        }
        
        // Spawn majority of food distributed in open areas AND hills for better distribution
        let openVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == .open }
        let hillVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == .hill }
        let availableVoxels = openVoxels + hillVoxels
        for _ in 0..<(maxFoodItems * 4 / 5) { // Most food spawns in distributed areas
            if let voxel = availableVoxels.randomElement() {
                let randomOffset = CGPoint(
                    x: Double.random(in: -20...20),
                    y: Double.random(in: -20...20)
                )
                
                // Much more liberal food spawning - only avoid very close to edges
                let minDistanceFromEdge = 30.0
                let bounds = voxelWorld.worldBounds
                let xDistance = min(voxel.position.x - bounds.minX, bounds.maxX - voxel.position.x)
                let yDistance = min(voxel.position.y - bounds.minY, bounds.maxY - voxel.position.y)
                let edgeDistance = min(xDistance, yDistance)
                
                // Only skip if extremely close to edge
                if edgeDistance < minDistanceFromEdge {
                    continue
                }
                let foodPosition = CGPoint(
                    x: voxel.position.x + randomOffset.x,
                    y: voxel.position.y + randomOffset.y
                )
                
                // Generate biome and season appropriate food type
                let targetSpecies: SpeciesType = Double.random(in: 0...1) < herbivoreFoodRatio ? .herbivore : .carnivore
                let foodType = FoodType.randomFoodFor(species: targetSpecies, biome: voxel.biome, season: seasonalManager.currentSeason)
                let foodItem = FoodItem(position: foodPosition, type: foodType, targetSpecies: targetSpecies)
                newFoods.append(foodItem)
            }
        }
        
        foods = newFoods
    }
    
    /// Strategically spawns new food in appropriate areas (seasonally and disaster adjusted)
    private func spawnFood() {
        // TOOL-FOOD INTEGRATION: Generate food from tools first
        generateFoodFromTools()
        
        let seasonalFoodSpawnRate = seasonalManager.adjustedFoodSpawnRate(baseRate: baseFoodSpawnRate)
        let weatherAdjustedSpawnRate = seasonalFoodSpawnRate * weatherManager.currentEffects.foodSpawnRateModifier
        // Ecosystem-adjusted spawn rate (resource depletion affects food availability)
        let finalFoodSpawnRate = weatherAdjustedSpawnRate * ecosystemManager.foodSpawnModifier
        // Cap seasonal max to prevent oversaturation - seasons affect spawn rate, not total capacity
        let seasonalMaxFood = maxFoodItems  // Use base limit, let spawn rate handle seasonal effects
        
        if foods.count < seasonalMaxFood && Double.random(in: 0...1) < finalFoodSpawnRate {
            // Prevent food oversaturation in food zones - bias toward distributed spawning
            let foodZoneChance = min(0.3, 1.0 - (Double(foods.count) / Double(seasonalMaxFood))) // Reduce food zone chance as food increases
            
            if Double.random(in: 0...1) < foodZoneChance {
                let foodVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == .food }
                
                // Count existing food near each food zone to prevent oversaturation
                let availableFoodVoxels = foodVoxels.filter { voxel in
                    let nearbyFood = foods.filter { food in
                        let dx = food.position.x - voxel.position.x
                        let dy = food.position.y - voxel.position.y
                        return sqrt(dx * dx + dy * dy) < 60.0  // 60 pixel radius
                    }
                    return nearbyFood.count < 8  // Max 8 food items per zone
                }
                
                if let voxel = availableFoodVoxels.randomElement() {
                    let randomOffset = CGPoint(
                        x: Double.random(in: -15...15),
                        y: Double.random(in: -15...15)
                    )
                    let foodPosition = CGPoint(
                        x: voxel.position.x + randomOffset.x,
                        y: voxel.position.y + randomOffset.y
                    )
                    // Check if disasters would destroy this food immediately
                    if !disasterManager.shouldDestroyFood(at: foodPosition) {
                        // Generate biome and season appropriate food type with higher herbivore ratio
                        let herbivoreFoodRatio = 0.8 // 80% herbivore foods
                        let targetSpecies: SpeciesType = Double.random(in: 0...1) < herbivoreFoodRatio ? .herbivore : .carnivore
                        let foodType = FoodType.randomFoodFor(species: targetSpecies, biome: voxel.biome, season: seasonalManager.currentSeason)
                        let foodItem = FoodItem(position: foodPosition, type: foodType, targetSpecies: targetSpecies)
                        foods.append(foodItem)
                    }
                }
            } else {
                let openVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == .open }
                let hillVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == .hill }
                let availableVoxels = openVoxels + hillVoxels
                if let voxel = availableVoxels.randomElement() {
                    // Much more liberal food spawning
                    let minDistanceFromEdge = 30.0
                    let bounds = voxelWorld.worldBounds
                    let xDistance = min(voxel.position.x - bounds.minX, bounds.maxX - voxel.position.x)
                    let yDistance = min(voxel.position.y - bounds.minY, bounds.maxY - voxel.position.y)
                    let edgeDistance = min(xDistance, yDistance)
                    
                    // Only spawn food if far enough from edges
                    if edgeDistance >= minDistanceFromEdge {
                        let randomOffset = CGPoint(
                            x: Double.random(in: -20...20),
                            y: Double.random(in: -20...20)
                        )
                        let foodPosition = CGPoint(
                            x: voxel.position.x + randomOffset.x,
                            y: voxel.position.y + randomOffset.y
                        )
                        // Check if disasters would destroy this food immediately
                        if !disasterManager.shouldDestroyFood(at: foodPosition) {
                            // Generate biome and season appropriate food type with higher herbivore ratio
                            let herbivoreFoodRatio = 0.8 // 80% herbivore foods
                            let targetSpecies: SpeciesType = Double.random(in: 0...1) < herbivoreFoodRatio ? .herbivore : .carnivore
                            let foodType = FoodType.randomFoodFor(species: targetSpecies, biome: voxel.biome, season: seasonalManager.currentSeason)
                            let foodItem = FoodItem(position: foodPosition, type: foodType, targetSpecies: targetSpecies)
                            foods.append(foodItem)
                        }
                    }
                }
            }
        }
        
        // Destroy existing food due to disasters
        let foodCountBefore = foods.count
        foods.removeAll { foodItem in
            disasterManager.shouldDestroyFood(at: foodItem.position)
        }
        
        if foods.count < foodCountBefore {
            let destroyed = foodCountBefore - foods.count
            if destroyed > 0 {
                // Disasters destroyed food items
            }
        }
    }
    
    // MARK: - Tool-Food Integration
    
    /// Generates food from tools that have food generation capabilities
    private func generateFoodFromTools() {
        for i in 0..<tools.count {
            guard tools[i].canGenerateFood else { continue }
            
            // Get biome from voxel world at tool position
            let toolPosition3D = Position3D(from: tools[i].position)
            let voxel = voxelWorld.getVoxel(at: toolPosition3D) 
            let biome = voxel?.biome ?? .temperateForest
            let season = seasonalManager.currentSeason
            
            if let generatedFood = tools[i].generateFood(biome: biome, season: season) {
                // Check if food should be stored in tool or released to world
                if tools[i].canStoreFood && tools[i].hasStorageSpace {
                    // Store food in the tool for later retrieval
                    _ = tools[i].storeFood(generatedFood)
                } else {
                    // Release food to the world if tool can't store or is full
                    foods.append(generatedFood)
                }
            }
        }
    }
    
    /// Calculate cultivation multiplier at a given position based on nearby cultivation tools
    private func getCultivationMultiplier(at position: CGPoint) -> Double {
        var maxMultiplier = 1.0
        
        for tool in tools {
            guard tool.canCultivateFood else { continue }
            
            let distance = sqrt(pow(position.x - tool.position.x, 2) + pow(position.y - tool.position.y, 2))
            if distance <= tool.cultivationRadius {
                // Use the highest cultivation multiplier in range
                maxMultiplier = max(maxMultiplier, tool.cultivationMultiplier)
            }
        }
        
        return maxMultiplier
    }

    /// Removes food that has been consumed - FIXED: Only remove food that was actually consumed
    private func removeConsumedFood() {
        let consumedFoodPositions = Set(bugs.compactMap { $0.consumedFood })
        
        foods.removeAll { foodItem in
            // Only remove if this specific food item position was consumed by a bug
            consumedFoodPositions.contains(foodItem.position)
        }
    }
    
    // MARK: - Communication Management
    
    /// Distributes signals to bugs within range
    private func distributeSignals() {
        let currentTime = Date().timeIntervalSince1970
        
        for signal in signals {
            guard signal.isActive(at: currentTime) else { continue }
            
            // Find bugs within signal range
            for bug in bugs {
                if signal.emitterId != bug.id, // Don't send signal back to sender
                   signal.canReach(position: bug.position, at: currentTime) {
                    bug.receiveSignal(signal)
                }
            }
        }
    }
    
    /// Removes expired signals from the world
    private func cleanupSignals() {
        let currentTime = Date().timeIntervalSince1970
        signals.removeAll { !$0.isActive(at: currentTime) }
        
        // Limit total signals to prevent memory issues
        if signals.count > 200 {
            signals = Array(signals.suffix(200))
        }
    }
    
    // MARK: - Tool & Construction Management
    
    /// Updates tools, resources, and construction projects
    private func updateToolsAndConstruction() {
        // Degrade tools over time
        for i in 0..<tools.count {
            tools[i].degrade()
        }
        
        // Remove broken tools
        tools.removeAll { !$0.isUsable }
        
        // Regenerate resources
        for i in 0..<resources.count {
            resources[i].regenerate()
        }
        
        // Update construction projects
        updateConstructionProjects()
        
        // Handle tool usage by bugs
        handleToolInteractions()
        
        // Handle resource gathering
        handleResourceGathering()
    }
    
    /// Updates construction projects and completes finished ones
    private func updateConstructionProjects() {
        var completedProjects: [ToolBlueprint] = []
        
        for i in 0..<blueprints.count {
            let blueprint = blueprints[i]
            
            // Find bugs working on this project
            let workers = bugs.filter { bug in
                bug.distance(to: blueprint.position) < 30.0 &&
                (bug.id == blueprint.builderId || bug.dna.toolDNA.collaborationTendency > 0.6)
            }
            
            // Add work from nearby bugs
            for worker in workers {
                if blueprints[i].hasAllResources {
                    _ = worker.workOnConstruction(&blueprints[i])
                }
            }
            
            // Check if construction is complete
            if blueprints[i].isComplete {
                completedProjects.append(blueprints[i])
            }
        }
        
        // Complete finished projects
        for project in completedProjects {
            completeConstruction(project)
            blueprints.removeAll { $0.builderId == project.builderId && $0.position == project.position }
        }
    }
    
    /// Completes a construction project by creating the tool
    private func completeConstruction(_ blueprint: ToolBlueprint) {
        let newTool = Tool(
            type: blueprint.type,
            position: blueprint.position,
            creatorId: blueprint.builderId,
            creationTime: Date().timeIntervalSince1970,
            durability: 1.0,
            uses: 0,
            generation: currentGeneration
        )
        
        tools.append(newTool)
        
        // Notify the builder
        if let builder = bugs.first(where: { $0.id == blueprint.builderId }) {
            builder.currentProject = nil
        }
    }
    
    /// Handles bugs interacting with tools
    private func handleToolInteractions() {
        for bug in bugs {
            // Find nearby tools
            let nearbyTools = tools.filter { bug.distance(to: $0.position) < 50.0 }
            
            for i in 0..<tools.count {
                if nearbyTools.contains(where: { $0.id == tools[i].id }) {
                    _ = bug.useTool(&tools[i], in: createVoxelArenaAdapter())
                }
            }
        }
    }
    
    /// Handles bugs gathering resources from nodes
    private func handleResourceGathering() {
        for bug in bugs {
            guard bug.canCarryMore else { continue }
            
            // Find nearby resources
            for i in 0..<resources.count {
                if bug.distance(to: resources[i].position) < 20.0 {
                    _ = bug.gatherResource(from: &resources[i])
                    break // Only gather from one resource per tick
                }
            }
            
            // Contribute to nearby construction projects
            for i in 0..<blueprints.count {
                if bug.distance(to: blueprints[i].position) < 30.0 {
                    _ = bug.contributeToConstruction(&blueprints[i])
                }
            }
        }
    }
    
    /// Spawns initial resource nodes around the arena
    private func spawnInitialResources() {
        let resourceCount = 50 // Adjusted for reduced population - balanced resource availability
        
        for _ in 0..<resourceCount {
            let resourceType = ResourceType.allCases.randomElement() ?? .stick
            let position = voxelWorld.findSpawnPosition().position2D
            
            let resource = Resource(
                type: resourceType,
                position: position,
                quantity: Int.random(in: 5...10),
                respawnRate: Double.random(in: 0.01...0.05), // Resources respawn slowly
                lastHarvest: Date().timeIntervalSince1970
            )
            
            resources.append(resource)
        }
    }
    
    // MARK: - Statistics
    
    /// Updates simulation statistics
    private func updateStatistics() {
        statistics.totalBugs = bugs.count
        statistics.aliveBugs = bugs.filter { $0.isAlive }.count
        statistics.averageEnergy = bugs.isEmpty ? 0 : bugs.map { $0.energy }.reduce(0, +) / Double(bugs.count)
        statistics.averageAge = bugs.isEmpty ? 0 : Double(bugs.map { $0.age }.reduce(0, +)) / Double(bugs.count)
        statistics.currentGeneration = currentGeneration
        statistics.totalFood = foods.count
    }
    
    /// Updates generation-specific statistics including new traits
    private func updateGenerationStatistics() {
        guard !bugs.isEmpty else {
            // Reset all averages to 0 when no bugs exist
            statistics.averageSpeed = 0
            statistics.averageVision = 0
            statistics.averageEfficiency = 0
            statistics.averageAggression = 0
            statistics.averageStrength = 0
            statistics.averageMemory = 0
            statistics.averageStickiness = 0
            statistics.averageCamouflage = 0
            statistics.averageCuriosity = 0
            return
        }
        
        let speeds = bugs.map { $0.dna.speed }
        let visions = bugs.map { $0.dna.visionRadius }
        let efficiencies = bugs.map { $0.dna.energyEfficiency }
        let aggressions = bugs.map { $0.dna.aggression }
        let strengths = bugs.map { $0.dna.strength }
        let memories = bugs.map { $0.dna.memory }
        let stickiness = bugs.map { $0.dna.stickiness }
        let camouflages = bugs.map { $0.dna.camouflage }
        let curiosities = bugs.map { $0.dna.curiosity }
        
        let count = Double(bugs.count)
        statistics.averageSpeed = speeds.reduce(0, +) / count
        statistics.averageVision = visions.reduce(0, +) / count
        statistics.averageEfficiency = efficiencies.reduce(0, +) / count
        statistics.averageAggression = aggressions.reduce(0, +) / count
        statistics.averageStrength = strengths.reduce(0, +) / count
        statistics.averageMemory = memories.reduce(0, +) / count
        statistics.averageStickiness = stickiness.reduce(0, +) / count
        statistics.averageCamouflage = camouflages.reduce(0, +) / count
        statistics.averageCuriosity = curiosities.reduce(0, +) / count
    }
}

// MARK: - Statistics Structure

struct SimulationStatistics {
    var totalBugs: Int = 0
    var aliveBugs: Int = 0
    var averageEnergy: Double = 0
    var averageAge: Double = 0
    var currentGeneration: Int = 0
    var totalFood: Int = 0
    
    // Original genetic averages
    var averageSpeed: Double = 0
    var averageVision: Double = 0
    var averageEfficiency: Double = 0
    var averageAggression: Double = 0
    
    // New environmental adaptation averages
    var averageStrength: Double = 0
    var averageMemory: Double = 0
    var averageStickiness: Double = 0
    var averageCamouflage: Double = 0
    var averageCuriosity: Double = 0
}