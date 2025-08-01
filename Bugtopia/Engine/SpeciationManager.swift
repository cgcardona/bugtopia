//
//  SpeciationManager.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

/// Manages population tracking and speciation events in the simulation
@Observable
class SpeciationManager {
    
    // MARK: - State
    
    var populations: [Population] = []
    var speciationEvents: [SpeciationEvent] = []
    var currentGeneration: Int = 0
    
    // MARK: - Configuration
    
    private let minPopulationSize = 3           // Minimum size to maintain a population
    private let maxPopulations = 8              // Maximum number of populations to track
    private let splitThreshold = 15             // Population size at which splitting can occur
    private let isolationThreshold = 0.4        // Genetic distance threshold for isolation
    private let extinctionRisk = 0.1            // Chance per generation for small populations to go extinct
    
    // MARK: - Initialization
    
    init() {
        // Start with a single ancestral population
        let ancestralPopulation = Population(
            id: UUID(),
            name: "Ancestral Population",
            foundingGeneration: 0,
            currentGeneration: 0,
            bugIds: Set<UUID>(),
            territories: Set<CGPoint>(),
            specializationTendencies: SpecializationProfile()
        )
        populations.append(ancestralPopulation)
    }
    
    // MARK: - Population Management
    
    /// Update populations with current bug information
    func updatePopulations(bugs: [Bug], generation: Int, arena: Arena) {
        currentGeneration = generation
        
        // Update existing populations
        updateExistingPopulations(bugs: bugs, arena: arena)
        
        // Check for speciation events
        checkForSpeciationEvents(bugs: bugs, arena: arena)
        
        // Clean up extinct populations
        cleanupExtinctPopulations()
        
        // Assign unassigned bugs to populations
        assignUnassignedBugs(bugs: bugs, arena: arena)
    }
    
    /// Update existing populations with current bug data
    private func updateExistingPopulations(bugs: [Bug], arena: Arena) {
        let bugLocations = Dictionary(uniqueKeysWithValues: bugs.map { ($0.id, $0.position) })
        
        for i in 0..<populations.count {
            // Remove dead bugs
            let aliveBugIds = Set(bugs.map { $0.id })
            populations[i].bugIds = populations[i].bugIds.intersection(aliveBugIds)
            
            // Update territories
            populations[i].updateTerritories(bugLocations: bugLocations)
            populations[i].currentGeneration = currentGeneration
            
            // Update specialization profile
            let populationBugs = bugs.filter { populations[i].bugIds.contains($0.id) }
            populations[i].specializationTendencies.updateFromBugs(populationBugs)
        }
    }
    
    /// Check for various speciation events
    private func checkForSpeciationEvents(bugs: [Bug], arena: Arena) {
        checkForPopulationSplits(bugs: bugs, arena: arena)
        checkForExtinctions(bugs: bugs)
        checkForMigrations(bugs: bugs, arena: arena)
        checkForHybridization(bugs: bugs)
    }
    
    /// Check if large populations should split
    private func checkForPopulationSplits(bugs: [Bug], arena: Arena) {
        for population in populations {
            guard population.size >= splitThreshold,
                  populations.count < maxPopulations else { continue }
            
            let populationBugs = bugs.filter { population.bugIds.contains($0.id) }
            
            // Check if population shows geographic clustering
            if shouldSplitGeographically(bugs: populationBugs, arena: arena) {
                performGeographicSplit(population: population, bugs: populationBugs, arena: arena)
            }
            // Check if population shows genetic divergence
            else if shouldSplitGenetically(bugs: populationBugs) {
                performGeneticSplit(population: population, bugs: populationBugs)
            }
        }
    }
    
    /// Check for population extinctions
    private func checkForExtinctions(bugs: [Bug]) {
        var extinctionEvents: [SpeciationEvent] = []
        
        for population in populations {
            guard population.size > 0 else { continue } // Already handled
            
            var extinctionCause: ExtinctionCause? = nil
            
            // Small population risk
            if population.size < minPopulationSize && Double.random(in: 0...1) < extinctionRisk {
                extinctionCause = .smallPopulation
            }
            
            // Genetic bottleneck (all bugs too similar)
            let populationBugs = bugs.filter { population.bugIds.contains($0.id) }
            if populationBugs.count > 1 {
                let avgGeneticDiversity = calculateGeneticDiversity(populationBugs)
                if avgGeneticDiversity < 0.1 && Double.random(in: 0...1) < 0.05 {
                    extinctionCause = .geneticBottleneck
                }
            }
            
            if let cause = extinctionCause {
                let event = SpeciationEvent.extinction(populationId: population.id, cause: cause)
                extinctionEvents.append(event)
            }
        }
        
        speciationEvents.append(contentsOf: extinctionEvents)
    }
    
    /// Check for population migrations
    private func checkForMigrations(bugs: [Bug], arena: Arena) {
        for i in 0..<populations.count {
            let population = populations[i]
            let oldCentroid = population.centroid
            
            // Update territories first
            let bugLocations = Dictionary(uniqueKeysWithValues: bugs.map { ($0.id, $0.position) })
            populations[i].updateTerritories(bugLocations: bugLocations)
            
            let newCentroid = populations[i].centroid
            let migrationDistance = sqrt(pow(newCentroid.x - oldCentroid.x, 2) + pow(newCentroid.y - oldCentroid.y, 2))
            
            // Significant migration detected
            if migrationDistance > 100.0 {
                let event = SpeciationEvent.migration(
                    populationId: population.id,
                    fromTerritory: oldCentroid,
                    toTerritory: newCentroid
                )
                speciationEvents.append(event)
            }
        }
    }
    
    /// Check for hybridization between populations
    private func checkForHybridization(bugs: [Bug]) {
        guard populations.count >= 2 else { return }
        
        for i in 0..<populations.count {
            for j in (i+1)..<populations.count {
                let pop1 = populations[i]
                let pop2 = populations[j]
                
                let pop1Bugs = bugs.filter { pop1.bugIds.contains($0.id) }
                let pop2Bugs = bugs.filter { pop2.bugIds.contains($0.id) }
                
                // Check if populations are close enough geographically
                let distance = sqrt(pow(pop1.centroid.x - pop2.centroid.x, 2) + pow(pop1.centroid.y - pop2.centroid.y, 2))
                
                if distance < 150.0 {
                    // Check genetic compatibility
                    let geneticDistance = pop1.specializationTendencies.geneticDistance(to: pop2.specializationTendencies)
                    
                    // Close enough genetically to hybridize
                    if geneticDistance < 0.3 && Double.random(in: 0...1) < 0.02 {
                        performHybridization(population1: pop1, population2: pop2, bugs: bugs)
                    }
                }
            }
        }
    }
    
    /// Assign bugs that don't belong to any population
    private func assignUnassignedBugs(bugs: [Bug], arena: Arena) {
        let assignedBugIds = Set(populations.flatMap { $0.bugIds })
        let unassignedBugs = bugs.filter { !assignedBugIds.contains($0.id) }
        
        for bug in unassignedBugs {
            assignBugToPopulation(bug, arena: arena)
        }
    }
    
    /// Clean up populations that have gone extinct
    private func cleanupExtinctPopulations() {
        populations.removeAll { $0.size == 0 }
        
        // Ensure we always have at least one population
        if populations.isEmpty {
            let newPopulation = Population(
                id: UUID(),
                name: "Survivor Population",
                foundingGeneration: currentGeneration,
                currentGeneration: currentGeneration,
                bugIds: Set<UUID>(),
                territories: Set<CGPoint>(),
                specializationTendencies: SpecializationProfile()
            )
            populations.append(newPopulation)
        }
    }
    
    // MARK: - Speciation Logic
    
    /// Determine if a population should split geographically
    private func shouldSplitGeographically(bugs: [Bug], arena: Arena) -> Bool {
        guard bugs.count >= splitThreshold else { return false }
        
        // Calculate geographic clustering
        let positions = bugs.map { $0.position }
        let clusters = findGeographicClusters(positions: positions)
        
        return clusters.count >= 2 && clusters.allSatisfy { $0.count >= minPopulationSize }
    }
    
    /// Determine if a population should split genetically
    private func shouldSplitGenetically(bugs: [Bug]) -> Bool {
        guard bugs.count >= splitThreshold else { return false }
        
        // Calculate genetic diversity
        let geneticDiversity = calculateGeneticDiversity(bugs)
        
        // High diversity suggests potential for splitting
        return geneticDiversity > 0.4
    }
    
    /// Perform a geographic population split
    private func performGeographicSplit(population: Population, bugs: [Bug], arena: Arena) {
        let positions = bugs.map { $0.position }
        let clusters = findGeographicClusters(positions: positions)
        
        guard clusters.count >= 2 else { return }
        
        // Create new populations for the largest clusters
        let sortedClusters = clusters.sorted { $0.count > $1.count }
        
        let cluster1Bugs = Array(sortedClusters[0])
        let cluster2Bugs = Array(sortedClusters[1])
        
        let dominantTerrain1 = findDominantTerrain(positions: cluster1Bugs, arena: arena)
        let dominantTerrain2 = findDominantTerrain(positions: cluster2Bugs, arena: arena)
        
        let newPop1 = createNewPopulation(
            name: PopulationNamer.generateName(for: population, dominantTerrain: dominantTerrain1),
            bugs: bugs.filter { cluster1Bugs.contains($0.position) }
        )
        
        let newPop2 = createNewPopulation(
            name: PopulationNamer.generateName(for: population, dominantTerrain: dominantTerrain2),
            bugs: bugs.filter { cluster2Bugs.contains($0.position) }
        )
        
        // Replace original population with new ones
        if let index = populations.firstIndex(where: { $0.id == population.id }) {
            populations.remove(at: index)
        }
        populations.append(newPop1)
        populations.append(newPop2)
        
        let event = SpeciationEvent.populationSplit(
            parentId: population.id,
            offspring1Id: newPop1.id,
            offspring2Id: newPop2.id
        )
        speciationEvents.append(event)
    }
    
    /// Perform a genetic population split
    private func performGeneticSplit(population: Population, bugs: [Bug]) {
        // Split based on genetic similarity
        let midpoint = bugs.count / 2
        
        // Sort by a key genetic trait (e.g., aggression) to create meaningful splits
        let sortedBugs = bugs.sorted { $0.dna.aggression < $1.dna.aggression }
        
        let group1 = Array(sortedBugs.prefix(midpoint))
        let group2 = Array(sortedBugs.suffix(bugs.count - midpoint))
        
        let newPop1 = createNewPopulation(
            name: "Passive \(population.name)",
            bugs: group1
        )
        
        let newPop2 = createNewPopulation(
            name: "Aggressive \(population.name)",
            bugs: group2
        )
        
        // Replace original population
        if let index = populations.firstIndex(where: { $0.id == population.id }) {
            populations.remove(at: index)
        }
        populations.append(newPop1)
        populations.append(newPop2)
        
        let event = SpeciationEvent.populationSplit(
            parentId: population.id,
            offspring1Id: newPop1.id,
            offspring2Id: newPop2.id
        )
        speciationEvents.append(event)
    }
    
    /// Perform hybridization between two populations
    private func performHybridization(population1: Population, population2: Population, bugs: [Bug]) {
        let pop1Bugs = bugs.filter { population1.bugIds.contains($0.id) }
        let pop2Bugs = bugs.filter { population2.bugIds.contains($0.id) }
        let allBugs = pop1Bugs + pop2Bugs
        
        let hybridPopulation = createNewPopulation(
            name: "Hybrid \(population1.name.components(separatedBy: " ").last ?? "Population")",
            bugs: allBugs
        )
        
        // Remove original populations
        populations.removeAll { $0.id == population1.id || $0.id == population2.id }
        populations.append(hybridPopulation)
        
        let event = SpeciationEvent.hybridization(
            population1Id: population1.id,
            population2Id: population2.id,
            hybridId: hybridPopulation.id
        )
        speciationEvents.append(event)
    }
    
    /// Assign a bug to the most appropriate population
    private func assignBugToPopulation(_ bug: Bug, arena: Arena) {
        guard !populations.isEmpty else { return }
        
        var bestPopulation = populations[0]
        var bestScore = -1.0
        
        for population in populations {
            let score = calculatePopulationFit(bug: bug, population: population)
            if score > bestScore {
                bestScore = score
                bestPopulation = population
            }
        }
        
        // Add bug to best fitting population
        if let index = populations.firstIndex(where: { $0.id == bestPopulation.id }) {
            populations[index].addBug(bug.id, at: bug.position)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Find geographic clusters in a set of positions
    private func findGeographicClusters(positions: [CGPoint]) -> [[CGPoint]] {
        guard positions.count >= 2 else { return [positions] }
        
        var clusters: [[CGPoint]] = []
        var unassigned = positions
        
        while !unassigned.isEmpty {
            var currentCluster = [unassigned.removeFirst()]
            
            var added = true
            while added {
                added = false
                
                for (index, position) in unassigned.enumerated().reversed() {
                    let minDistance = currentCluster.map { pos in
                        sqrt(pow(pos.x - position.x, 2) + pow(pos.y - position.y, 2))
                    }.min() ?? Double.infinity
                    
                    if minDistance < 80.0 { // Clustering threshold
                        currentCluster.append(position)
                        unassigned.remove(at: index)
                        added = true
                    }
                }
            }
            
            clusters.append(currentCluster)
        }
        
        return clusters
    }
    
    /// Calculate genetic diversity within a population
    private func calculateGeneticDiversity(_ bugs: [Bug]) -> Double {
        guard bugs.count >= 2 else { return 0.0 }
        
        var totalDistance = 0.0
        var comparisons = 0
        
        for i in 0..<bugs.count {
            for j in (i+1)..<bugs.count {
                let distance = ReproductiveCompatibility.compatibility(between: bugs[i], and: bugs[j], populations: populations)
                totalDistance += (1.0 - distance) // Convert compatibility to distance
                comparisons += 1
            }
        }
        
        return totalDistance / Double(comparisons)
    }
    
    /// Find the dominant terrain type for a set of positions
    private func findDominantTerrain(positions: [CGPoint], arena: Arena) -> TerrainType? {
        let terrainCounts = positions.reduce(into: [TerrainType: Int]()) { counts, position in
            let terrain = arena.terrainAt(position)
            counts[terrain, default: 0] += 1
        }
        
        return terrainCounts.max { $0.value < $1.value }?.key
    }
    
    /// Calculate how well a bug fits into a population
    private func calculatePopulationFit(bug: Bug, population: Population) -> Double {
        let averages = population.specializationTendencies.averageTraits
        
        // Calculate genetic similarity
        let traitDifferences = [
            abs(bug.dna.speed - averages.speed),
            abs(bug.dna.visionRadius - averages.visionRadius) / 100.0,
            abs(bug.dna.energyEfficiency - averages.energyEfficiency),
            abs(bug.dna.size - averages.size),
            abs(bug.dna.strength - averages.strength),
            abs(bug.dna.memory - averages.memory),
            abs(bug.dna.stickiness - averages.stickiness),
            abs(bug.dna.camouflage - averages.camouflage),
            abs(bug.dna.aggression - averages.aggression),
            abs(bug.dna.curiosity - averages.curiosity)
        ]
        
        let geneticSimilarity = 1.0 - (traitDifferences.reduce(0, +) / Double(traitDifferences.count))
        
        // Calculate geographic proximity
        let distance = sqrt(pow(bug.position.x - population.centroid.x, 2) + pow(bug.position.y - population.centroid.y, 2))
        let geographicSimilarity = max(0.0, 1.0 - (distance / 200.0))
        
        // Combined fit score
        return (geneticSimilarity * 0.7 + geographicSimilarity * 0.3)
    }
    
    /// Create a new population from a group of bugs
    private func createNewPopulation(name: String, bugs: [Bug]) -> Population {
        var population = Population(
            id: UUID(),
            name: name,
            foundingGeneration: currentGeneration,
            currentGeneration: currentGeneration,
            bugIds: Set(bugs.map { $0.id }),
            territories: Set(bugs.map { $0.position }),
            specializationTendencies: SpecializationProfile()
        )
        
        population.specializationTendencies.updateFromBugs(bugs)
        
        return population
    }
    
    // MARK: - Reproductive Compatibility
    
    /// Get reproductive compatibility between two bugs
    func getReproductiveCompatibility(bug1: Bug, bug2: Bug) -> Double {
        return ReproductiveCompatibility.compatibility(between: bug1, and: bug2, populations: populations)
    }
    
    /// Get the population a bug belongs to
    func getPopulation(for bugId: UUID) -> Population? {
        return populations.first { $0.bugIds.contains(bugId) }
    }
    
    /// Get recent speciation events
    func getRecentEvents(limit: Int = 10) -> [SpeciationEvent] {
        return Array(speciationEvents.suffix(limit))
    }
    
    /// Clear old events to prevent memory buildup
    func cleanupOldEvents(maxEvents: Int = 100) {
        if speciationEvents.count > maxEvents {
            speciationEvents = Array(speciationEvents.suffix(maxEvents))
        }
    }
}