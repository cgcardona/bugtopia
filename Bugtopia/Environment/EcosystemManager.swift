//
//  EcosystemManager.swift
//  Bugtopia
//
//  Created by Assistant on 8/1/25.
//

import Foundation
import SwiftUI

/// Represents the health and productivity of a resource zone
struct ResourceZone {
    let id = UUID()
    let position: CGPoint
    let radius: Double
    var health: Double // 0.0 = depleted, 1.0 = fully productive
    var depletion: Double // 0.0 = pristine, 1.0 = exhausted
    var regenerationRate: Double
    var lastActivityTime: TimeInterval
    
    init(position: CGPoint, radius: Double = 50.0) {
        self.position = position
        self.radius = radius
        self.health = 1.0
        self.depletion = 0.0
        self.regenerationRate = 0.001 // Base regeneration per tick
        self.lastActivityTime = Date().timeIntervalSince1970
    }
    
    /// Calculate distance from a point to this resource zone
    func distanceTo(_ point: CGPoint) -> Double {
        let dx = point.x - position.x
        let dy = point.y - position.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Check if a point is within this resource zone
    func contains(_ point: CGPoint) -> Bool {
        return distanceTo(point) <= radius
    }
    
    /// Apply harvesting pressure to this zone
    mutating func harvest(intensity: Double = 0.1) {
        depletion = min(1.0, depletion + intensity)
        health = max(0.0, 1.0 - depletion)
        lastActivityTime = Date().timeIntervalSince1970
    }
    
    /// Natural regeneration over time
    mutating func regenerate(deltaTime: TimeInterval) {
        if depletion > 0.0 {
            let regeneration = regenerationRate * deltaTime
            depletion = max(0.0, depletion - regeneration)
            health = min(1.0, 1.0 - depletion)
        }
    }
}

/// Tracks long-term ecosystem health and resource cycles
@Observable
class EcosystemManager {
    
    // MARK: - Properties
    
    /// Resource zones across the world
    private(set) var resourceZones: [ResourceZone] = []
    
    /// Population density tracking
    private var populationDensityGrid: [[Double]] = []
    private let gridResolution: Int = 20
    
    /// Ecosystem health metrics
    private(set) var globalResourceHealth: Double = 1.0
    private(set) var averagePopulationPressure: Double = 0.0
    private(set) var carryingCapacityUtilization: Double = 0.0
    
    /// Cycle tracking
    private(set) var ecosystemAge: Int = 0 // Generations since start
    private(set) var lastMajorCycle: Int = 0
    
    /// Configuration
    private let baseCarryingCapacity: Int = 200
    private let depletionThreshold: Double = 0.7
    private let regenerationBoostFactor: Double = 2.0
    private var worldBounds: CGRect?
    
    // MARK: - Initialization
    
    init() {
        reset()
    }
    
    // MARK: - Core Functionality
    
    /// Reset ecosystem to initial state
    /// Sets the world bounds for population density calculations
    func setWorldBounds(_ bounds: CGRect) {
        worldBounds = bounds
    }
    
    func reset() {
        resourceZones.removeAll()
        populationDensityGrid = Array(repeating: Array(repeating: 0.0, count: gridResolution), count: gridResolution)
        globalResourceHealth = 1.0
        averagePopulationPressure = 0.0
        carryingCapacityUtilization = 0.0
        ecosystemAge = 0
        lastMajorCycle = 0
    }
    
    /// Initialize resource zones based on arena food zones
    func initializeResourceZones(from arena: Arena) {
        resourceZones.removeAll()
        
        // Find all food terrain tiles and create resource zones
        for row in 0..<arena.tiles.count {
            for col in 0..<arena.tiles[row].count {
                let tile = arena.tiles[row][col]
                if tile.terrain == .food {
                    // Check if this position is already covered by an existing zone
                    let alreadyCovered = resourceZones.contains { zone in
                        zone.contains(tile.position)
                    }
                    
                    if !alreadyCovered {
                        let zone = ResourceZone(position: tile.position, radius: 60.0)
                        resourceZones.append(zone)
                    }
                }
            }
        }
        
        // EcosystemManager: Initialized resource zones
    }
    
    /// Update ecosystem dynamics each simulation tick
    func update(
        bugs: [Bug],
        foods: [FoodItem],
        generationCount: Int,
        deltaTime: TimeInterval = 1.0/30.0
    ) {
        ecosystemAge = generationCount
        
        // Update population density
        updatePopulationDensity(bugs: bugs)
        
        // Update resource zones
        updateResourceZones(bugs: bugs, foods: foods, deltaTime: deltaTime)
        
        // Update global resource health based on food availability
        updateGlobalResourceHealth(foods: foods, bugs: bugs)
        
        // Calculate global metrics
        calculateGlobalMetrics(bugs: bugs)
        
        // Check for major ecological cycles
        checkForMajorCycles()
    }
    
    // MARK: - Population Dynamics
    
    private func updatePopulationDensity(bugs: [Bug]) {
        // Reset density grid
        populationDensityGrid = Array(repeating: Array(repeating: 0.0, count: gridResolution), count: gridResolution)
        
        // Count bugs in each grid cell - use actual world bounds instead of hardcoded values
        guard let worldBounds = worldBounds else { return }
        
        for bug in bugs {
            let normalizedX = (bug.position.x - worldBounds.minX) / worldBounds.width
            let normalizedY = (bug.position.y - worldBounds.minY) / worldBounds.height
            let gridX = max(0, min(gridResolution - 1, Int(normalizedX * Double(gridResolution))))
            let gridY = max(0, min(gridResolution - 1, Int(normalizedY * Double(gridResolution))))
            populationDensityGrid[gridY][gridX] += 1.0
        }
        
        // Calculate average pressure
        let totalPressure = populationDensityGrid.flatMap { $0 }.reduce(0, +)
        averagePopulationPressure = totalPressure / Double(gridResolution * gridResolution)
        
        // Calculate carrying capacity utilization
        carryingCapacityUtilization = Double(bugs.count) / Double(baseCarryingCapacity)
    }
    
    private func updateResourceZones(bugs: [Bug], foods: [FoodItem], deltaTime: TimeInterval) {
        for i in 0..<resourceZones.count {
            var zone = resourceZones[i]
            
            // Count bugs actively feeding in this zone
            let feedingBugs = bugs.filter { bug in
                zone.contains(bug.position) && bug.isNearFood(foods)
            }
            
            // Apply harvesting pressure based on feeding activity
            if !feedingBugs.isEmpty {
                let harvestIntensity = Double(feedingBugs.count) * 0.02 // Configurable harvesting rate
                zone.harvest(intensity: harvestIntensity)
            }
            
            // Natural regeneration
            zone.regenerate(deltaTime: deltaTime)
            
            resourceZones[i] = zone
        }
        
        // Calculate global resource health
        if !resourceZones.isEmpty {
            globalResourceHealth = resourceZones.map { $0.health }.reduce(0, +) / Double(resourceZones.count)
        }
    }
    
    private func updateGlobalResourceHealth(foods: [FoodItem], bugs: [Bug]) {
        // Calculate food availability ratio (food per bug)
        let foodPerBug = bugs.isEmpty ? Double(foods.count) : Double(foods.count) / Double(bugs.count)
        
        // Ideal ratio is about 10 food items per bug for healthy ecosystem
        let idealFoodPerBug = 10.0
        let foodAvailabilityRatio = min(1.0, foodPerBug / idealFoodPerBug)
        
        // Combine resource zone health with food availability
        let zoneHealth = resourceZones.isEmpty ? 1.0 : resourceZones.map { $0.health }.reduce(0, +) / Double(resourceZones.count)
        
        // Weight food availability more heavily for immediate ecosystem health
        globalResourceHealth = (foodAvailabilityRatio * 0.7) + (zoneHealth * 0.3)
    }
    
    private func calculateGlobalMetrics(bugs: [Bug]) {
        // Calculate carrying capacity utilization
        carryingCapacityUtilization = Double(bugs.count) / Double(baseCarryingCapacity)
        
        // Calculate average population pressure
        let totalPressure = populationDensityGrid.flatMap { $0 }.reduce(0, +)
        let gridCells = Double(gridResolution * gridResolution)
        averagePopulationPressure = totalPressure / gridCells
    }
    
    private func checkForMajorCycles() {
        // Major ecological shifts every 50-100 generations
        let cycleLength = Int.random(in: 50...100)
        
        if ecosystemAge - lastMajorCycle >= cycleLength {
            triggerMajorEcologicalCycle()
            lastMajorCycle = ecosystemAge
        }
    }
    
    private func triggerMajorEcologicalCycle() {
        // Major Ecological Cycle triggered
        
        // Randomly boost or reduce resource zones
        for i in 0..<resourceZones.count {
            let change = Double.random(in: -0.3...0.5)
            resourceZones[i].health = max(0.1, min(1.0, resourceZones[i].health + change))
            resourceZones[i].regenerationRate *= Double.random(in: 0.8...1.4)
        }
        
        // Occasionally add new resource zones or remove depleted ones
        if Double.random(in: 0...1) < 0.3 {
            // Add new resource zone in a random location
            let newPosition = CGPoint(
                x: Double.random(in: 50...750),
                y: Double.random(in: 50...550)
            )
            let newZone = ResourceZone(position: newPosition, radius: Double.random(in: 40...70))
            resourceZones.append(newZone)
        }
        
        // Remove severely depleted zones
        resourceZones.removeAll { $0.health < 0.1 }
    }
    
    // MARK: - Query Methods
    
    /// Get resource health at a specific location
    func getResourceHealth(at position: CGPoint) -> Double {
        for zone in resourceZones {
            if zone.contains(position) {
                return zone.health
            }
        }
        return 1.0 // Default health for areas without resource zones
    }
    
    /// Get population pressure at a specific location
    func getPopulationPressure(at position: CGPoint) -> Double {
        let gridX = max(0, min(gridResolution - 1, Int(position.x / 800.0 * Double(gridResolution))))
        let gridY = max(0, min(gridResolution - 1, Int(position.y / 600.0 * Double(gridResolution))))
        return populationDensityGrid[gridY][gridX]
    }
    
    /// Check if the ecosystem is under stress
    var isEcosystemStressed: Bool {
        return globalResourceHealth < 0.5 || carryingCapacityUtilization > 1.2
    }
    
    /// Get food spawn rate modifier based on resource health
    var foodSpawnModifier: Double {
        return max(0.1, globalResourceHealth)
    }
    
    /// Get survival pressure modifier based on ecosystem stress
    var survivalPressureModifier: Double {
        if carryingCapacityUtilization > 1.0 {
            return 1.0 + (carryingCapacityUtilization - 1.0) * 0.5
        }
        return 1.0
    }
    
    // MARK: - Ecosystem Inputs for Neural Networks
    
    /// Generate ecosystem-aware inputs for bug neural networks
    var ecosystemInputs: [Double] {
        return [
            globalResourceHealth,                    // Global resource availability
            averagePopulationPressure / 10.0,      // Normalized population pressure
            carryingCapacityUtilization,            // How close to carrying capacity
            isEcosystemStressed ? 1.0 : 0.0,       // Ecosystem stress indicator
            foodSpawnModifier,                      // Food availability modifier
            survivalPressureModifier - 1.0,        // Additional survival pressure
        ]
    }
}

// MARK: - Bug Extension for Resource Awareness

extension Bug {
    /// Check if bug is currently near food sources
    func isNearFood(_ foods: [FoodItem]) -> Bool {
        return foods.contains { food in
            let dx = position.x - food.position.x
            let dy = position.y - food.position.y
            return sqrt(dx * dx + dy * dy) < 30.0
        }
    }
}