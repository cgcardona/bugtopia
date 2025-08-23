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
    var currentWorldType: WorldType3D = .continental3D
    private let maxPopulation = 25   // 🌍 PRODUCTION: Allow population growth for large world
    private let initialPopulation = 0    // 🍎 STYLING: No bugs for food styling focus
    private let maxFoodItems = 80        // 🍎 PRODUCTION: Abundant food for diverse 20-bug ecosystem
    private let baseFoodSpawnRate = 0.25 // 🍎 MODERATE: 25% chance per tick for 20-bug simulation
    
    // MARK: - Simulation Speed & Analysis
    
    /// Current simulation speed multiplier (1x = normal, 10x = fast evolution)
    var speedMultiplier: Double = 1.0
    
    /// Weight analysis logging enabled
    var enableWeightLogging: Bool = false
    
    /// Generation to start detailed logging
    var logStartGeneration: Int = 0
    
    // MARK: - Evolution Parameters
    
    let generationLength = 1500 // 🐛 SINGLE BUG DEBUG: Longer generations (50 seconds) for easier observation
    private let survivalRate = 0.3 // Fraction that survives to next generation
    private let eliteRate = 0.1 // Fraction of best bugs that survive automatically
    
    // MARK: - Statistics
    
    private(set) var statistics = SimulationStatistics()
    
    // MARK: - Neural Network Analysis
    
    /// CSV header for weight data export
    private let csvHeader = "BugID,Generation,Species,SurvivalTime,Complexity,energy_to_hidden1_n1,energy_to_hidden1_n2,age_to_hidden1_n1,age_to_hidden1_n2,food_distance_influence,food_dirX_influence,food_dirY_influence,final_to_moveX,final_to_moveY,final_to_moveZ"
    
    /// Collected weight analysis data
    private var weightAnalysisData: [String] = []
    
    // MARK: - Neural Network Analysis Methods
    
    /// Log neural network weights for detailed analysis
    private func logNeuralWeights(for bug: Bug, survivalTime: Int = 0) {
        guard enableWeightLogging && currentGeneration >= logStartGeneration else { return }
        
        let bugId = String(bug.id.uuidString.prefix(8))
        let species = bug.dna.speciesTraits.speciesType.rawValue
        let neuralNetwork = NeuralNetwork(dna: bug.dna.neuralDNA)
        
        // Log to console
        neuralNetwork.logNetworkAnalysis(bugId: bugId, generation: currentGeneration)
        
        // Collect CSV data
        let csvRow = neuralNetwork.exportWeightsCSV(
            bugId: bugId,
            generation: currentGeneration,
            species: species,
            survivalTime: survivalTime
        )
        weightAnalysisData.append(csvRow)
    }
    
    /// Log population-level neural network analytics
    private func logPopulationAnalytics() {
        guard !bugs.isEmpty else { return }
        
        let _ = bugs.map { Double($0.dna.neuralDNA.weights.count + $0.dna.neuralDNA.biases.count) }.reduce(0, +) / Double(bugs.count)
        let _ = bugs.map { Double($0.dna.neuralDNA.topology.count) }.reduce(0, +) / Double(bugs.count)
        
        let _ = bugs.reduce(into: [String: Int]()) { result, bug in
            let species = bug.dna.speciesTraits.speciesType.rawValue
            result[species, default: 0] += 1
        }
        



        
        // Every 10 generations, log weight distributions
        if currentGeneration % 10 == 0 {
            logWeightDistributions()
        }
    }
    
    /// Analyze weight distributions across the population
    private func logWeightDistributions() {
        var energyWeights: [Double] = []
        var movementWeights: [Double] = []
        
        for bug in bugs {
            let neuralNetwork = NeuralNetwork(dna: bug.dna.neuralDNA)
            let weights = neuralNetwork.getCriticalWeights()
            
            if let energyWeight = weights["energy_to_hidden1_n1"] {
                energyWeights.append(energyWeight)
            }
            if let moveXWeight = weights["final_to_moveX"] {
                movementWeights.append(moveXWeight)
            }
        }
        
        if !energyWeights.isEmpty {
            let _ = energyWeights.reduce(0, +) / Double(energyWeights.count)

        }
        
        if !movementWeights.isEmpty {
            let _ = movementWeights.reduce(0, +) / Double(movementWeights.count)

        }
    }
    
    /// Export collected weight analysis data
    func exportWeightAnalysis() -> String {
        var export = csvHeader + "\n"
        for row in weightAnalysisData {
            export += row + "\n"
        }
        return export
    }
    
    /// Clear collected weight analysis data
    func clearWeightAnalysis() {
        weightAnalysisData.removeAll()
    }
    
    // MARK: - Timer
    
    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0 / 30.0 // 30 FPS
    
    // MARK: - Initialization
    
    init(worldBounds: CGRect) {
        // 🌍 DYNAMIC WORLD TYPES: Randomly select a world type each app launch for variety
        // Uncomment if you want to randomly select a world type
        // let wordType = WorldType3D.allCases.randomElement() ?? .continental3D
        // Uncomment if you want to test a specific world type
        // let worldType = WorldType3D.abyss3D
        let worldType = WorldType3D.archipelago3D
        // let worldType = WorldType3D.canyon3D
        // let worldType = WorldType3D.cavern3D
        // let worldType = WorldType3D.continental3D
        // let worldType = WorldType3D.skylands3D
        // let worldType = WorldType3D.volcano3D
        self.currentWorldType = worldType
        
         print("🌍 Generated World Type: \(worldType.rawValue)")
         print("🌍 Expected Features:")
        switch worldType {
        case .abyss3D:
            print("   • Deep underwater trenches")
            print("   • Cold, harsh biomes (Tundra, Alpine, Wetlands)")
            print("   • Diving specialists required")
        case .archipelago3D:
            print("   • Island chains with water")
            print("   • Tropical biomes (Coastal, Rainforest, Wetlands)")
            print("   • Swimming capabilities important")
        case .canyon3D:
            print("   • Deep valleys and high mesas")
            print("   • Arid biomes (Desert, Grassland, Alpine)")
            print("   • Climbing specialists thrive")
        case .cavern3D:
            print("   • Underground cave systems")
            print("   • Limited biomes (Tundra, Alpine only)")
            print("   • Tunnel navigation required")
        case .continental3D:
            print("   • Diverse landscapes with all features")
            print("   • All biomes possible")
            print("   • Balanced ecosystem")
        case .skylands3D:
            print("   • Floating islands in the sky")
            print("   • Temperate biomes (Forest, Alpine, Grassland)")
            print("   • Flying capabilities essential")
        case .volcano3D:
            print("   • Volcanic peaks and lava flows")
            print("   • Hot biomes (Desert, Alpine, Savanna)")
            print("   • Heat-resistant species favored")
        }

        
        // 🔧 STABLE RESOLUTION: 32x32x32 for reliable performance
        // NOTE: Higher resolutions (48³+) cause rendering hangs - need async/LOD system first
        self.voxelWorld = VoxelWorld(bounds: worldBounds, worldType: worldType, resolution: 32)
        self.pathfinding = VoxelPathfinding(voxelWorld: voxelWorld)
        ecosystemManager.setWorldBounds(worldBounds)
        
        // 🔍 DEBUG: Setup minimal population for focused debugging
        bugs.removeAll()
        for i in 0..<initialPopulation {
            // 🐛 DEBUG: Spawn bug in safe zone away from boundaries
            let centerX = (voxelWorld.worldBounds.minX + voxelWorld.worldBounds.maxX) / 2
            let centerY = (voxelWorld.worldBounds.minY + voxelWorld.worldBounds.maxY) / 2
            let spawnRadius = 30.0  // Spawn within 30 units of center for more room
            let spawnAngle = Double.random(in: 0...(2 * Double.pi))
            let spawnDistance = Double.random(in: 10...spawnRadius) // At least 10 units from center
            
            let randomPosition = CGPoint(
                x: centerX + cos(spawnAngle) * spawnDistance,
                y: centerY + sin(spawnAngle) * spawnDistance
            )
            
            // 🌍 PRODUCTION: Create diverse ecosystem with all species types
            if i < 15 { // First 15 bugs get enhanced vision for better survival
                // Create diverse species distribution
                let speciesType: SpeciesType
                if i < 8 {
                    speciesType = .herbivore  // 8 herbivores (40%)
                } else if i < 12 {
                    speciesType = .carnivore  // 4 carnivores (20%)
                } else if i < 15 {
                    speciesType = .omnivore   // 3 omnivores (15%)
                } else {
                    speciesType = .scavenger  // Remaining are scavengers
                }
                
                let baseDNA = BugDNA.random()
                let speciesTraits = SpeciesTraits.forSpecies(speciesType)
                
                // Create enhanced DNA with much better vision for small world debugging
                let debugDNA = BugDNA(
                    speed: baseDNA.speed,
                    visionRadius: 300.0, // Enhanced vision for 2000x2000 world
                    energyEfficiency: baseDNA.energyEfficiency,
                    size: baseDNA.size,
                    strength: baseDNA.strength,
                    memory: baseDNA.memory,
                    stickiness: baseDNA.stickiness,
                    camouflage: baseDNA.camouflage,
                    wingSpan: baseDNA.wingSpan,
                    divingDepth: baseDNA.divingDepth,
                    climbingGrip: baseDNA.climbingGrip,
                    altitudePreference: baseDNA.altitudePreference,
                    pressureTolerance: baseDNA.pressureTolerance,
                    aggression: baseDNA.aggression,
                    curiosity: baseDNA.curiosity,
                    neuralDNA: baseDNA.neuralDNA,
                    neuralEnergyEfficiency: baseDNA.neuralEnergyEfficiency,
                    brainPlasticity: baseDNA.brainPlasticity,
                    neuralPruningTendency: baseDNA.neuralPruningTendency,
                    speciesTraits: speciesTraits,
                    communicationDNA: baseDNA.communicationDNA,
                    toolDNA: baseDNA.toolDNA,
                    colorHue: baseDNA.colorHue,
                    colorSaturation: baseDNA.colorSaturation,
                    colorBrightness: baseDNA.colorBrightness
                )
                
                let newBug = Bug(dna: debugDNA, position: randomPosition, generation: 0)
                bugs.append(newBug)
                print("🌍 [DEBUG] Created \(speciesType.rawValue) bug #\(i+1) at position: \(randomPosition)")
                print("🌍 [DEBUG] Bug #\(i+1) species: \(debugDNA.speciesTraits.speciesType.rawValue)")
                print("🌍 [DEBUG] Bug #\(i+1) vision radius: \(debugDNA.visionRadius)")
                print("🌍 [DEBUG] Bug #\(i+1) can eat plants: \(debugDNA.speciesTraits.speciesType.canEatPlants)")
                if i == 0 { print("🌍 [DEBUG] World bounds: \(voxelWorld.worldBounds)") }
            } else {
                let newBug = Bug.random(in: voxelWorld.worldBounds, generation: 0)
                bugs.append(newBug)
            }
        }
        print("🐛 [SETUP] Initial population created: \(bugs.count) bugs")
        
        // 🍎 PRODUCTION: Setup evenly distributed food across entire arena
        foods.removeAll()
        let initialFoodCount = 1   // 🍣 STYLING: Single tuna for AAA quality focus
        
        // 🍣 STYLING: Position single tuna near origin for easy camera positioning
        let tunaX = 50.0   // Close to origin but not exactly at 0,0
        let tunaY = 50.0   // Close to origin but not exactly at 0,0
        let tunaPosition = CGPoint(x: tunaX, y: tunaY)
        
        // Create single AAA-quality grilled steak
        let grilledSteak = FoodItem(position: tunaPosition, type: .grilledSteak, targetSpecies: .carnivore)
        foods.append(grilledSteak)
        
        print("🔥 [STYLING] Created single grilled steak near origin: (\(tunaX), \(tunaY))")
        print("🍣 [SETUP] Initial food created: \(foods.count) food items")
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
        // Store the current running state to restore it after reset
        let wasRunning = isRunning
        
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
        
        // 🔍 DEBUG: Setup minimal population for focused debugging (reset)
        bugs.removeAll()
        for i in 0..<initialPopulation {
            // 🐛 DEBUG: Spawn bug in safe zone away from boundaries
            let centerX = (voxelWorld.worldBounds.minX + voxelWorld.worldBounds.maxX) / 2
            let centerY = (voxelWorld.worldBounds.minY + voxelWorld.worldBounds.maxY) / 2
            let spawnRadius = 30.0  // Spawn within 30 units of center for more room
            let spawnAngle = Double.random(in: 0...(2 * Double.pi))
            let spawnDistance = Double.random(in: 10...spawnRadius) // At least 10 units from center
            
            let randomPosition = CGPoint(
                x: centerX + cos(spawnAngle) * spawnDistance,
                y: centerY + sin(spawnAngle) * spawnDistance
            )
            
            // 🌍 PRODUCTION: Create diverse ecosystem with all species types (reset)
            if i < 15 { // First 15 bugs get enhanced vision for better survival
                // Create diverse species distribution
                let speciesType: SpeciesType
                if i < 8 {
                    speciesType = .herbivore  // 8 herbivores (40%)
                } else if i < 12 {
                    speciesType = .carnivore  // 4 carnivores (20%)
                } else if i < 15 {
                    speciesType = .omnivore   // 3 omnivores (15%)
                } else {
                    speciesType = .scavenger  // Remaining are scavengers
                }
                
                let baseDNA = BugDNA.random()
                let speciesTraits = SpeciesTraits.forSpecies(speciesType)
                
                // Create enhanced DNA with much better vision for small world debugging
                let debugDNA = BugDNA(
                    speed: baseDNA.speed,
                    visionRadius: 300.0, // Enhanced vision for 2000x2000 world
                    energyEfficiency: baseDNA.energyEfficiency,
                    size: baseDNA.size,
                    strength: baseDNA.strength,
                    memory: baseDNA.memory,
                    stickiness: baseDNA.stickiness,
                    camouflage: baseDNA.camouflage,
                    wingSpan: baseDNA.wingSpan,
                    divingDepth: baseDNA.divingDepth,
                    climbingGrip: baseDNA.climbingGrip,
                    altitudePreference: baseDNA.altitudePreference,
                    pressureTolerance: baseDNA.pressureTolerance,
                    aggression: baseDNA.aggression,
                    curiosity: baseDNA.curiosity,
                    neuralDNA: baseDNA.neuralDNA,
                    neuralEnergyEfficiency: baseDNA.neuralEnergyEfficiency,
                    brainPlasticity: baseDNA.brainPlasticity,
                    neuralPruningTendency: baseDNA.neuralPruningTendency,
                    speciesTraits: speciesTraits,
                    communicationDNA: baseDNA.communicationDNA,
                    toolDNA: baseDNA.toolDNA,
                    colorHue: baseDNA.colorHue,
                    colorSaturation: baseDNA.colorSaturation,
                    colorBrightness: baseDNA.colorBrightness
                )
                
                let newBug = Bug(dna: debugDNA, position: randomPosition, generation: 0)
                bugs.append(newBug)
                print("🌱 [RESET] Created herbivore bug at position: \(randomPosition)")
                print("🌱 [RESET] Bug species: \(debugDNA.speciesTraits.speciesType.rawValue)")
                print("🌱 [RESET] Bug vision radius: \(debugDNA.visionRadius)")
                print("🌱 [RESET] Bug can eat plants: \(debugDNA.speciesTraits.speciesType.canEatPlants)")
            } else {
                let newBug = Bug.random(in: voxelWorld.worldBounds, generation: 0)
                bugs.append(newBug)
            }
        }
        print("🐛 [RESET] Population created: \(bugs.count) bugs")
        
        // 🍎 PRODUCTION: Setup evenly distributed food across entire arena (reset)
        foods.removeAll()
        let initialFoodCount = 1   // 🍣 STYLING: Single tuna for AAA quality focus
        
        // 🍣 STYLING: Position single tuna near origin for easy camera positioning
        let tunaX = 50.0   // Close to origin but not exactly at 0,0
        let tunaY = 50.0   // Close to origin but not exactly at 0,0
        let tunaPosition = CGPoint(x: tunaX, y: tunaY)
        
        // Create single AAA-quality grilled steak
        let grilledSteak = FoodItem(position: tunaPosition, type: .grilledSteak, targetSpecies: .carnivore)
        foods.append(grilledSteak)
        
        print("🔥 [STYLING] Created single grilled steak near origin: (\(tunaX), \(tunaY))")
        print("🍣 [RESET] Food created: \(foods.count) food items")
        
        // Skip spawnInitialResources for now in debug mode
        
        // Restore the previous running state - if it was running, keep it running!
        if wasRunning {
            start()
        }
    }
    
    /// Advances the simulation by one tick
    func step() {
        tick()
    }
    
    /// Forces evolution to the next generation (re-enabled for diverse ecosystem)
    func evolveNextGeneration() {
        print("🧬 [EVOLUTION] Forcing evolution to next generation")
        evolvePopulation()
    }
    
    // MARK: - Main Simulation Loop
    
    /// Executes one simulation tick
    private func tick() {
        // Apply speed multiplier - run multiple internal ticks for faster evolution
        let ticksToRun = max(1, Int(speedMultiplier))
        for _ in 0..<ticksToRun {
            performSingleTick()
        }
    }
    
    /// Perform a single simulation tick (extracted for speed control)
    private func performSingleTick() {
        tickCount += 1
        
        // Update all bugs with neural decisions first, then movement
        var newSignals: [Signal] = []
        for bug in bugs {
            // 🎯 MOVEMENT TRACKING: Capture position before update (for future use)
            let _ = bug.position3D
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
        
        // Handle reproduction (re-enabled for diverse ecosystem)
        handleReproduction()
        
        // Remove dead bugs
        let bugCountBefore = bugs.count
        bugs.removeAll { !$0.isAlive }
        let bugCountAfter = bugs.count
        
        // 🔍 DEBUG: Log population changes and prevent force-regeneration
        if bugCountBefore != bugCountAfter {
            print("🐛 [POPULATION] Bugs: \(bugCountBefore) → \(bugCountAfter)")
        }
        
        // 🔍 DEBUG: Disable any force-regeneration logic for focused debugging
        if bugs.count < 2 {
            print("🔍 [DEBUG] Population below 2 (\(bugs.count)) - force-regeneration DISABLED for debugging")
            // Normally this would trigger emergency population creation, but we're disabling it
        }
        
        // 🍎 DISABLED: Food spawning disabled for styling focus
        // spawnFood()
        
        // Remove consumed food
        removeConsumedFood()
        
        // Update seasonal system
        seasonalManager.update()
        
        // Update weather patterns
        weatherManager.update(seasonalManager: seasonalManager)
        
        // Update natural disasters
        disasterManager.update(seasonalManager: seasonalManager, weatherManager: weatherManager)
        
        // 🔍 DEBUG: Re-enable ecosystem updates to track food availability
        // Update ecosystem dynamics and resource health
        ecosystemManager.update(
            bugs: bugs,
            foods: foods,
            generationCount: currentGeneration,
            deltaTime: tickInterval
        )
        
        // Update territories and migrations (using 2D compatibility)
        // territoryManager.update(
        //     populations: speciationManager.populations,
        //     arena: createVoxelArenaAdapter(),
        //     ecosystemManager: ecosystemManager
        // )
        
        // Update populations and speciation (using 2D compatibility)
        // speciationManager.updatePopulations(bugs: bugs, generation: currentGeneration, arena: createVoxelArenaAdapter())
        
        // Clean up old speciation events every 50 ticks to prevent memory buildup
        if tickCount % 50 == 0 {
            speciationManager.cleanupOldEvents()
        }
        
        // 🔍 MEMORY LEAK DEBUG: Track array sizes every 30 ticks
        if tickCount % 30 == 0 {
            MemoryLeakTracker.shared.trackArraySizes(
                bugs: bugs.count,
                foods: foods.count,
                signals: signals.count,
                resources: resources.count,
                tools: tools.count
            )
            
            // 🐛 DEBUG: Log bug-food distances every 30 ticks for debugging
            if let firstBug = bugs.first, !foods.isEmpty {
                print("🔍 [DEBUG] Bug position: \(firstBug.position)")
                print("🔍 [DEBUG] Bug energy: \(firstBug.energy)")
                print("🔍 [DEBUG] Bug species: \(firstBug.dna.speciesTraits.speciesType.rawValue)")
                for (i, food) in foods.enumerated() {
                    let distance = sqrt(pow(firstBug.position.x - food.position.x, 2) + pow(firstBug.position.y - food.position.y, 2))
                    print("🔍 [DEBUG] Distance to food \(i) (\(food.type.rawValue)): \(String(format: "%.2f", distance))")
                }
            }
        }
        
        // 🔍 MEMORY LEAK DEBUG: Generate comprehensive memory report every 300 ticks (10 seconds)
        if tickCount % 300 == 0 {
            MemoryLeakTracker.shared.generateMemoryReport()
        }
        
        // Update statistics
        updateStatistics()
        
        // 🔍 DEBUG: Disable automatic generation evolution for focused debugging
        // Check for generation end
        // if shouldEndGeneration() {
        //     evolvePopulation()
        // }
        
        // 🔍 DEBUG: Disable automatic repopulation for focused debugging
        // 🎉 RE-ENABLED: Repopulation for full simulation with visual sync fixed
        // Only repopulate if population is extremely critically low
        // if bugs.count < 2 { // Almost never repopulate - let natural selection work
        //     repopulateFromSurvivors()
        // }
    }
    
    // MARK: - Population Management
    
    /// Sets up the initial random population using voxel world spawn points
    private func setupInitialPopulation() {
        // 🎉 FULL SIMULATION: Random spawn positions across the terrain
        bugs = (0..<initialPopulation).map { index in
            // Use voxel world to find random spawn positions across terrain
            let randomPosition3D = voxelWorld.findSpawnPosition()
            let surfacePosition = calculateSurfaceSpawnPosition(randomPosition3D)
            
            let bug = Bug(dna: BugDNA.random(), position3D: surfacePosition, generation: currentGeneration)
            logNeuralWeights(for: bug, survivalTime: 0)
            return bug
        }
        // 🎉 Bugs spawned randomly across terrain
    }
    
    /// Calculate proper surface position for spawning bugs with terrain following
    private func calculateSurfaceSpawnPosition(_ position3D: Position3D) -> Position3D {
        // 🌍 TERRAIN FOLLOWING: Use actual terrain height for proper surface positioning
        // Query the voxel world for the actual surface height at this position
        let terrainHeight = voxelWorld.getHeightAt(x: position3D.x, z: position3D.y)
        
        return Position3D(
            position3D.x,
            position3D.y,
            terrainHeight + 1.0  // Slightly above terrain surface for proper positioning
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
        let newBugsToAdd = max(0, min(newBugs.count, maxPopulation - bugs.count))
        if newBugsToAdd > 0 {
            bugs.append(contentsOf: Array(newBugs.prefix(newBugsToAdd)))
        }
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
                // 🐛 SINGLE BUG DEBUG: Position repopulated bug at world center for camera focus
                let bounds = voxelWorld.worldBounds
                let centerPosition = Position3D(bounds.midX, bounds.midY, -5.0)
                bugs.append(Bug(dna: BugDNA.random(), position3D: centerPosition, generation: currentGeneration))
                continue
            }
            
            // 🐛 SINGLE BUG DEBUG: Position mutated repopulated bug at world center
            let mutatedDNA = parent.dna.mutated(mutationRate: 0.3, mutationStrength: 0.2)
            let bounds = voxelWorld.worldBounds
            let centerPosition = Position3D(bounds.midX, bounds.midY, -5.0)
            bugs.append(Bug(dna: mutatedDNA, position3D: centerPosition, generation: currentGeneration))
        }
    }
    
    // MARK: - Evolution
    
    /// Determines if the current generation should end
    private func shouldEndGeneration() -> Bool {
        // 🎉 FULL SIMULATION: Re-enable population-based generation ending + repopulation
        return tickCount % generationLength == 0 || bugs.count < 2 // Allow natural population decline to trigger evolution
    }
    
    /// Evolves the population to the next generation
    private func evolvePopulation() {
        currentGeneration += 1
        


        
        // Always log population analytics every generation
        logPopulationAnalytics()
        
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
            // 🐛 SINGLE BUG DEBUG: PRESERVE survivor position (don't reset to world center!)
            let refreshedBug = Bug(dna: survivor.dna, position3D: survivor.position3D, generation: currentGeneration)
            refreshedBug.energy = Bug.initialEnergy
            newPopulation.append(refreshedBug)
            
            // Log neural weights for survivors
            logNeuralWeights(for: refreshedBug, survivalTime: survivor.age)
        }
        
        // Fill rest of population with offspring
        while newPopulation.count < initialPopulation {
            // Safe parent selection with fallbacks
            guard let parent1 = survivors.randomElement() else {
                // 🐛 SINGLE BUG DEBUG: Only use world center if absolutely no survivors exist
                let bounds = voxelWorld.worldBounds
                let centerPosition = Position3D(bounds.midX, bounds.midY, -5.0)
                let newBug = Bug(dna: BugDNA.random(), position3D: centerPosition, generation: currentGeneration)
                newPopulation.append(newBug)
                logNeuralWeights(for: newBug, survivalTime: 0)
                continue
            }
            
            guard let parent2 = survivors.randomElement() else {
                // 🐛 SINGLE BUG DEBUG: Position mutated bug near parent for realistic evolution
                let mutatedDNA = parent1.dna.mutated(mutationRate: 0.2, mutationStrength: 0.3)
                let newBug = Bug(dna: mutatedDNA, position3D: parent1.position3D, generation: currentGeneration)
                newPopulation.append(newBug)
                logNeuralWeights(for: newBug, survivalTime: 0)
                continue
            }
            
            // 🐛 SINGLE BUG DEBUG: Position crossover bug near parent for realistic evolution
            let childDNA = BugDNA.crossover(parent1.dna, parent2.dna).mutated()
            // Spawn near one of the parents (choose parent1)
            let newBug = Bug(dna: childDNA, position3D: parent1.position3D, generation: currentGeneration)
            newPopulation.append(newBug)
            logNeuralWeights(for: newBug, survivalTime: 0)
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
        
        // 🐛 DEBUG: Analyze terrain distribution for food spawning
        let allSurfaceVoxels = voxelWorld.getVoxelsInLayer(.surface)
        let foodVoxels = allSurfaceVoxels.filter { $0.terrainType == .food }
        let openVoxels = allSurfaceVoxels.filter { $0.terrainType == .open }
        let hillVoxels = allSurfaceVoxels.filter { $0.terrainType == .hill }
        let forestVoxels = allSurfaceVoxels.filter { $0.terrainType == .forest }
        let _ = allSurfaceVoxels.filter { $0.terrainType == .water }
        
        // print("🍎 [FOOD DEBUG] Surface voxel terrain analysis:")
        // print("📊 Total surface voxels: \(allSurfaceVoxels.count)")
        // print("🍇 Food zones: \(foodVoxels.count)")
        // print("🌾 Open areas: \(openVoxels.count)")
        // print("⛰️ Hills: \(hillVoxels.count)")
        // print("🌲 Forests: \(forestVoxels.count)")
        // print("🌊 Water: \(waterVoxels.count)")
        // print("🌱 Current season: \(seasonalManager.currentSeason.rawValue) \(seasonalManager.currentSeason.emoji)")
        
        // Original logic (reduced for focused debugging)
        let herbivoreFoodRatio = 0.8 // 80% herbivore foods for now
        
        // Spawn food in designated food zones (limited to prevent oversaturation)
        for voxel in foodVoxels.prefix(min(8, maxFoodItems / 3)) { // Allow more food zone spawning
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
        
        // Spawn majority of food distributed in open areas, hills, AND forests for better distribution
        let availableVoxels = openVoxels + hillVoxels + forestVoxels
        let targetFoodCount = maxFoodItems  // 🍎 AGGRESSIVE: Use full food capacity for 2 bugs
        // print("🎯 [FOOD DEBUG] Attempting to spawn \(targetFoodCount) foods in \(availableVoxels.count) available voxels")
        
        // DEBUG: Sample voxel positions to understand distribution
        let sampleVoxels = Array(availableVoxels.prefix(10))
        // print("📍 [FOOD DEBUG] Sample voxel positions:")
        for (i, voxel) in sampleVoxels.enumerated() {
            // print("   Voxel \(i): \(voxel.terrainType) at (\(voxel.position.x), \(voxel.position.y)) in \(voxel.biome)")
        }
        // print("🌍 [FOOD DEBUG] World bounds: \(voxelWorld.worldBounds)")
        
        // DEBUG: Analyze voxel distribution
        if !availableVoxels.isEmpty {
            let voxelX = availableVoxels.map { $0.position.x }
            let voxelY = availableVoxels.map { $0.position.y }
            // print("📊 [VOXEL DEBUG] Available voxel coordinate ranges:")
            // print("   X: \(voxelX.min()!) to \(voxelX.max()!) (span: \(voxelX.max()! - voxelX.min()!))")
            // print("   Y: \(voxelY.min()!) to \(voxelY.max()!) (span: \(voxelY.max()! - voxelY.min()!))")
        }
        
        var successfulSpawns = 0
        var edgeSkips = 0
        var foodPositions: [CGPoint] = []  // Track where food actually gets placed
        for _ in 0..<targetFoodCount { // More conservative initial food spawning
            if let voxel = availableVoxels.randomElement() {
                let randomOffset = CGPoint(
                    x: Double.random(in: -20...20),
                    y: Double.random(in: -20...20)
                )
                
                // Much more liberal food spawning - reduce edge restriction for better distribution
                let minDistanceFromEdge = 10.0  // Reduced from 30 to allow more terrain coverage
                let bounds = voxelWorld.worldBounds
                let xDistance = min(voxel.position.x - bounds.minX, bounds.maxX - voxel.position.x)
                let yDistance = min(voxel.position.y - bounds.minY, bounds.maxY - voxel.position.y)
                let edgeDistance = min(xDistance, yDistance)
                
                // Only skip if extremely close to edge
                if edgeDistance < minDistanceFromEdge {
                    edgeSkips += 1
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
                foodPositions.append(foodPosition)
                successfulSpawns += 1
            }
        }
        
        // ADDITIONAL PASS: Ensure good coverage across the entire terrain
        let additionalTargetCount = min(50, availableVoxels.count / 100)  // 1% coverage minimum
        // print("🎯 [FOOD DEBUG] Additional distribution pass: \(additionalTargetCount) more foods")
        
        for _ in 0..<additionalTargetCount {
            if let voxel = availableVoxels.randomElement() {
                let randomOffset = CGPoint(
                    x: Double.random(in: -15...15),
                    y: Double.random(in: -15...15)
                )
                let foodPosition = CGPoint(
                    x: voxel.position.x + randomOffset.x,
                    y: voxel.position.y + randomOffset.y
                )
                
                // More liberal placement for coverage
                let targetSpecies: SpeciesType = Double.random(in: 0...1) < herbivoreFoodRatio ? .herbivore : .carnivore
                let foodType = FoodType.randomFoodFor(species: targetSpecies, biome: voxel.biome, season: seasonalManager.currentSeason)
                let foodItem = FoodItem(position: foodPosition, type: foodType, targetSpecies: targetSpecies)
                newFoods.append(foodItem)
                foodPositions.append(foodPosition)
                successfulSpawns += 1
            }
        }
        
        // DEBUG: Analyze food position distribution
        // print("📍 [FOOD DEBUG] Food position analysis after main pass:")
        if !foodPositions.isEmpty {
            let minX = foodPositions.map { $0.x }.min()!
            let maxX = foodPositions.map { $0.x }.max()!
            let minY = foodPositions.map { $0.y }.min()!
            let maxY = foodPositions.map { $0.y }.max()!
            // print("   X range: \(minX) to \(maxX) (span: \(maxX - minX))")
            // print("   Y range: \(minY) to \(maxY) (span: \(maxY - minY))")
            let samplePositions = Array(foodPositions.prefix(5))
            // print("   Sample positions: \(samplePositions)")
        }
        
        // DEBUG: Analyze food type distribution
        // 🍎 Food distribution: \(newFoods.count) items spawned across \(Dictionary(grouping: newFoods, by: { $0.type }).count) food types
        
        // 🍎 Final results: \(successfulSpawns) spawns, \(edgeSkips) edge skips, \(newFoods.count) total items
        
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
        
        // 🍎 MODERATE: Spawn food more frequently when food count is low (reduced from 80% to 40%)
        let aggressiveSpawnRate = foods.count < 15 ? 0.4 : finalFoodSpawnRate // 40% chance when low food
        
        // 🔍 DEBUG: Log food spawning attempts
        if foods.count < seasonalMaxFood && Int.random(in: 1...60) == 1 { // Log every ~60 ticks
            print("🍎 [FOOD SPAWN] Current food: \(foods.count)/\(seasonalMaxFood), spawn rate: \(String(format: "%.2f", aggressiveSpawnRate))")
        }
        
        if foods.count < seasonalMaxFood && Double.random(in: 0...1) < aggressiveSpawnRate {
            // 🔍 DEBUG: Log when spawn attempt is triggered
            if Int.random(in: 1...20) == 1 { // Log 5% of attempts
                print("🍎 [FOOD SPAWN] 🎯 Spawn attempt triggered! Food: \(foods.count)/\(seasonalMaxFood)")
            }
            
            // Prevent food oversaturation in food zones - bias toward distributed spawning
            let foodZoneChance = min(0.3, 1.0 - (Double(foods.count) / Double(seasonalMaxFood))) // Reduce food zone chance as food increases
            
            if Double.random(in: 0...1) < foodZoneChance {
                // 🔍 DEBUG: Log food zone path
                if Int.random(in: 1...10) == 1 {
                    print("🍎 [FOOD SPAWN] 🏞️ Trying food zone path (chance: \(String(format: "%.2f", foodZoneChance)))")
                }
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
                // 🔍 DEBUG: Log distributed spawning path
                if Int.random(in: 1...10) == 1 {
                    print("🍎 [FOOD SPAWN] 🌍 Trying distributed spawning path")
                }
                
                let openVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == .open }
                let hillVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == .hill }
                let availableVoxels = openVoxels + hillVoxels
                
                // 🔍 DEBUG: Log voxel availability
                if Int.random(in: 1...20) == 1 {
                    print("🍎 [FOOD SPAWN] 📊 Available voxels: open=\(openVoxels.count), hill=\(hillVoxels.count), total=\(availableVoxels.count)")
                }
                
                if let voxel = availableVoxels.randomElement() {
                    // 🍎 AGGRESSIVE: Very liberal food spawning for 2-bug testing
                    let minDistanceFromEdge = 10.0 // Reduced from 30 to allow more spawning
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
                            
                            // 🔍 DEBUG: Log successful food spawning
                            if Int.random(in: 1...10) == 1 { // Log 10% of spawns
                                print("🍎 [FOOD SPAWN] ✅ Spawned \(foodType.rawValue) at \(String(format: "(%.1f, %.1f)", foodPosition.x, foodPosition.y))")
                            }
                        }
                    } else {
                        // 🔍 DEBUG: Log failed spawning due to edge distance
                        if Int.random(in: 1...30) == 1 { // Log occasionally
                            print("🍎 [FOOD SPAWN] ❌ Failed edge check: distance \(String(format: "%.1f", edgeDistance)) < \(minDistanceFromEdge)")
                        }
                    }
                } else {
                    // 🔍 DEBUG: No voxels available, try fallback spawning
                    if Int.random(in: 1...5) == 1 {
                        print("🍎 [FOOD SPAWN] ⚠️ No voxels available, trying fallback spawning")
                    }
                    
                    // 🍎 SMART FALLBACK: Spawn food near bugs to encourage exploration
                    let bounds = voxelWorld.worldBounds
                    let margin = 20.0 // Stay away from edges
                    
                    var randomPosition: CGPoint
                    
                    // 60% chance to spawn near bugs, 40% chance random for exploration
                    if !bugs.isEmpty && Double.random(in: 0...1) < 0.6 {
                        // Spawn near a random bug but not too close
                        let targetBug = bugs.randomElement()!
                        let spawnRadius = Double.random(in: 30...80) // 30-80 units from bug
                        let spawnAngle = Double.random(in: 0...(2 * Double.pi))
                        
                        randomPosition = CGPoint(
                            x: targetBug.position.x + cos(spawnAngle) * spawnRadius,
                            y: targetBug.position.y + sin(spawnAngle) * spawnRadius
                        )
                        
                        // Clamp to bounds
                        randomPosition.x = max(bounds.minX + margin, min(bounds.maxX - margin, randomPosition.x))
                        randomPosition.y = max(bounds.minY + margin, min(bounds.maxY - margin, randomPosition.y))
                    } else {
                        // Random spawning for exploration
                        randomPosition = CGPoint(
                            x: Double.random(in: (bounds.minX + margin)...(bounds.maxX - margin)),
                            y: Double.random(in: (bounds.minY + margin)...(bounds.maxY - margin))
                        )
                    }
                    
                    let herbivoreFoodTypes: [FoodType] = [.apple, .orange, .plum, .melon]
                    let randomType = herbivoreFoodTypes.randomElement() ?? .apple
                    let foodItem = FoodItem(position: randomPosition, type: randomType, targetSpecies: .herbivore)
                    foods.append(foodItem)
                    
                    // 🔍 DEBUG: Log fallback spawning
                    if Int.random(in: 1...5) == 1 {
                        print("🍎 [FOOD SPAWN] 🆘 Fallback spawned \(randomType.rawValue) at \(String(format: "(%.1f, %.1f)", randomPosition.x, randomPosition.y))")
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
        let consumedFoodPositions = bugs.compactMap { $0.consumedFood }
        
        // 🍎 PRECISION FIX: Use distance-based matching instead of exact position matching
        foods.removeAll { foodItem in
            for consumedPosition in consumedFoodPositions {
                let distance = sqrt(pow(foodItem.position.x - consumedPosition.x, 2) + 
                                  pow(foodItem.position.y - consumedPosition.y, 2))
                // If food is within 3 units of a consumed position, remove it
                if distance < 3.0 {
                    return true
                }
            }
            return false
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
    
    /// Helper function to get emoji for food types
    private func foodTypeEmoji(_ foodType: FoodType) -> String {
        switch foodType {
        case .plum: return "🍇"
        case .apple: return "🍎"
        case .orange: return "🍊"
        case .melon: return "🍈"
        case .blackberry: return "🫐"
        case .tuna: return "🍣"
        case .mediumSteak: return "🥩"
        case .rawFlesh: return "🩸"
        case .rawSteak: return "🥩"
        case .grilledSteak: return "🔥"
        case .seeds: return "🌱"
        case .nuts: return "🥜"
        }
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
