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
    var foods: [CGPoint] = []
    var isRunning = false
    var currentGeneration = 0
    var tickCount = 0
    
    // MARK: - World Configuration
    
    let arena: Arena
    private let maxPopulation = 100
    private let initialPopulation = 30
    private let maxFoodItems = 200  // Increased from 150
    private let foodSpawnRate = 0.5 // Increased from 0.3 to 0.5 (15 food/sec instead of 9)
    
    // MARK: - Evolution Parameters
    
    private let generationLength = 2000 // Ticks per generation
    private let survivalRate = 0.3 // Fraction that survives to next generation
    private let eliteRate = 0.1 // Fraction of best bugs that survive automatically
    
    // MARK: - Statistics
    
    private(set) var statistics = SimulationStatistics()
    
    // MARK: - Timer
    
    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0 / 30.0 // 30 FPS
    
    // MARK: - Initialization
    
    init(worldBounds: CGRect) {
        self.arena = Arena(bounds: worldBounds)
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
        currentGeneration = 0
        tickCount = 0
        statistics = SimulationStatistics()
        
        setupInitialPopulation()
        spawnInitialFood()
    }
    
    // MARK: - Main Simulation Loop
    
    /// Executes one simulation tick
    private func tick() {
        tickCount += 1
        
        // Update all bugs with arena awareness
        for bug in bugs {
            bug.update(in: arena, foods: foods, otherBugs: bugs)
        }
        
        // Handle reproduction
        handleReproduction()
        
        // Remove dead bugs
        bugs.removeAll { !$0.isAlive }
        
        // Spawn food
        spawnFood()
        
        // Remove consumed food
        removeConsumedFood()
        
        // Update statistics
        updateStatistics()
        
        // Check for generation end
        if shouldEndGeneration() {
            evolvePopulation()
        }
        
        // Ensure minimum population
        if bugs.count < 5 {
            repopulateFromSurvivors()
        }
    }
    
    // MARK: - Population Management
    
    /// Sets up the initial random population using arena spawn points
    private func setupInitialPopulation() {
        bugs = (0..<initialPopulation).map { _ in
            let spawnPosition = arena.findSpawnPosition()
            return Bug(dna: BugDNA.random(), position: spawnPosition, generation: 0)
        }
    }
    
    /// Handles bug reproduction
    private func handleReproduction() {
        let reproducableBugs = bugs.filter { $0.canReproduce }
        var newBugs: [Bug] = []
        
        for i in 0..<reproducableBugs.count {
            let bug1 = reproducableBugs[i]
            
            // Find nearby compatible partner
            for j in (i+1)..<reproducableBugs.count {
                let bug2 = reproducableBugs[j]
                
                if let offspring = bug1.reproduce(with: bug2) {
                    newBugs.append(offspring)
                    break // One reproduction per bug per tick
                }
            }
        }
        
        // Add new bugs if population allows
        let newBugsToAdd = min(newBugs.count, maxPopulation - bugs.count)
        bugs.append(contentsOf: Array(newBugs.prefix(newBugsToAdd)))
    }
    
    /// Repopulates from survivors when population gets too low
    private func repopulateFromSurvivors() {
        guard !bugs.isEmpty else {
            setupInitialPopulation()
            return
        }
        
        let survivors = bugs.sorted { $0.energy > $1.energy }
        let neededBugs = max(15, initialPopulation - bugs.count)
        
        for _ in 0..<neededBugs {
            // Safe random parent selection with fallback to random DNA
            let parent: Bug
            if let randomSurvivor = survivors.randomElement() {
                parent = randomSurvivor
            } else {
                // If no survivors, create completely new bug
                let spawnPosition = arena.findSpawnPosition()
                bugs.append(Bug(dna: BugDNA.random(), position: spawnPosition, generation: currentGeneration))
                continue
            }
            
            let mutatedDNA = parent.dna.mutated(mutationRate: 0.3, mutationStrength: 0.2)
            let spawnPosition = arena.findSpawnPosition()
            bugs.append(Bug(dna: mutatedDNA, position: spawnPosition, generation: currentGeneration))
        }
    }
    
    // MARK: - Evolution
    
    /// Determines if the current generation should end
    private func shouldEndGeneration() -> Bool {
        return tickCount % generationLength == 0 || bugs.count < 3
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
            let refreshedBug = Bug(dna: survivor.dna, position: survivor.position, generation: currentGeneration)
            refreshedBug.energy = Bug.initialEnergy
            newPopulation.append(refreshedBug)
        }
        
        // Fill rest of population with offspring
        while newPopulation.count < initialPopulation {
            // Safe parent selection with fallbacks
            guard let parent1 = survivors.randomElement() else {
                // If no survivors, create random bug
                let randomPosition = arena.findSpawnPosition()
                newPopulation.append(Bug(dna: BugDNA.random(), position: randomPosition, generation: currentGeneration))
                continue
            }
            
            guard let parent2 = survivors.randomElement() else {
                // If only one survivor, use asexual reproduction (mutation only)
                let mutatedDNA = parent1.dna.mutated(mutationRate: 0.2, mutationStrength: 0.3)
                let childPosition = arena.findSpawnPosition()
                newPopulation.append(Bug(dna: mutatedDNA, position: childPosition, generation: currentGeneration))
                continue
            }
            
            let childDNA = BugDNA.crossover(parent1.dna, parent2.dna).mutated()
            let childPosition = arena.findSpawnPosition()
            
            newPopulation.append(Bug(dna: childDNA, position: childPosition, generation: currentGeneration))
        }
        
        bugs = newPopulation
        
        // Update statistics for new generation
        updateGenerationStatistics()
        
        print("🧬 Generation \(currentGeneration) - \(bugs.count) bugs evolved")
    }
    
    /// Calculates enhanced fitness score considering terrain adaptation
    private func calculateFitness(for bug: Bug) -> Double {
        let survivalBonus = Double(bug.age) / Double(Bug.maxAge) * 100
        let energyBonus = bug.energy
        let reproductionBonus = Double(max(0, bug.age - 100)) * 0.1
        let geneticBonus = bug.dna.geneticFitness * 10
        
        // Terrain adaptation bonus
        let currentTerrain = arena.terrainAt(bug.position)
        let terrainBonus = bug.dna.terrainFitness(for: currentTerrain) * 5
        
        // Exploration bonus for bugs that have been in different terrain types
        let explorationBonus = calculateExplorationBonus(for: bug)
        
        return survivalBonus + energyBonus + reproductionBonus + geneticBonus + terrainBonus + explorationBonus
    }
    
    /// Calculates bonus for bugs that successfully navigate different terrains
    private func calculateExplorationBonus(for bug: Bug) -> Double {
        // This is a simplified version - in a full implementation, you'd track
        // which terrain types each bug has successfully traversed
        let curiosityBonus = bug.dna.curiosity * 10
        let memoryBonus = bug.dna.memory * 8
        return curiosityBonus + memoryBonus
    }
    
    // MARK: - Food Management
    
    /// Spawns initial food distribution, prioritizing food zones and open areas
    private func spawnInitialFood() {
        var newFoods: [CGPoint] = []
        
        // Spawn food in designated food zones
        let foodTiles = arena.tilesOfType(.food)
        for tile in foodTiles.prefix(maxFoodItems / 3) {
            let randomOffset = CGPoint(
                x: Double.random(in: -15...15),
                y: Double.random(in: -15...15)
            )
            let foodPosition = CGPoint(
                x: tile.position.x + randomOffset.x,
                y: tile.position.y + randomOffset.y
            )
            newFoods.append(foodPosition)
        }
        
        // Spawn additional food in open areas
        let openTiles = arena.tilesOfType(.open)
        for _ in 0..<(maxFoodItems / 2) {
            if let tile = openTiles.randomElement() {
                let randomOffset = CGPoint(
                    x: Double.random(in: -20...20),
                    y: Double.random(in: -20...20)
                )
                let foodPosition = CGPoint(
                    x: tile.position.x + randomOffset.x,
                    y: tile.position.y + randomOffset.y
                )
                newFoods.append(foodPosition)
            }
        }
        
        foods = newFoods
    }
    
    /// Strategically spawns new food in appropriate areas
    private func spawnFood() {
        if foods.count < maxFoodItems && Double.random(in: 0...1) < foodSpawnRate {
            // 60% chance to spawn in food zones, 40% chance in open areas
            if Double.random(in: 0...1) < 0.6 {
                let foodTiles = arena.tilesOfType(.food)
                if let tile = foodTiles.randomElement() {
                    let randomOffset = CGPoint(
                        x: Double.random(in: -15...15),
                        y: Double.random(in: -15...15)
                    )
                    let newFood = CGPoint(
                        x: tile.position.x + randomOffset.x,
                        y: tile.position.y + randomOffset.y
                    )
                    foods.append(newFood)
                }
            } else {
                let openTiles = arena.tilesOfType(.open)
                if let tile = openTiles.randomElement() {
                    let randomOffset = CGPoint(
                        x: Double.random(in: -20...20),
                        y: Double.random(in: -20...20)
                    )
                    let newFood = CGPoint(
                        x: tile.position.x + randomOffset.x,
                        y: tile.position.y + randomOffset.y
                    )
                    foods.append(newFood)
                }
            }
        }
    }
    
    /// Removes food that has been consumed
    private func removeConsumedFood() {
        foods.removeAll { food in
            bugs.contains { bug in
                let dx = bug.position.x - food.x
                let dy = bug.position.y - food.y
                let distance = sqrt(dx * dx + dy * dy)
                return distance < bug.visualRadius
            }
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