//
//  TerritoryManager.swift
//  Bugtopia
//
//  Created by Assistant on 8/1/25.
//

import Foundation
import SwiftUI

/// Represents a territory claimed by a bug population
struct Territory: Identifiable, Equatable {
    let id: UUID
    let populationId: UUID
    var area: CGRect
    var quality: Double // 0.0 to 1.0, based on resources, safety, etc.
    var lastDefended: TimeInterval
    
    init(populationId: UUID, area: CGRect, quality: Double) {
        self.id = UUID()
        self.populationId = populationId
        self.area = area
        self.quality = quality
        self.lastDefended = Date().timeIntervalSince1970
    }
}

/// Manages population territories and migration behaviors
@Observable
class TerritoryManager {
    
    // MARK: - Properties
    
    private(set) var territories: [Territory] = []
    private var worldBounds: CGRect = .zero
    
    // MARK: - Configuration
    
    private let territoryGridResolution = 20 // For quality assessment
    private let minTerritoryQuality: Double = 0.3 // Minimum quality to be considered valuable
    private let migrationUrgencyThreshold: Double = 0.8 // How bad things must get before migrating
    
    // MARK: - Core Functionality
    
    func reset() {
        territories.removeAll()
    }
    
    func setWorldBounds(_ bounds: CGRect) {
        self.worldBounds = bounds
    }
    
    func update(
        populations: [Population],
        arena: Arena,
        ecosystemManager: EcosystemManager
    ) {
        updateTerritories(populations: populations, arena: arena, ecosystemManager: ecosystemManager)
        triggerMigrations(populations: populations, ecosystemManager: ecosystemManager)
    }
    
    // MARK: - Territory Management
    
    private func updateTerritories(
        populations: [Population],
        arena: Arena,
        ecosystemManager: EcosystemManager
    ) {
        // Remove territories of extinct populations
        territories.removeAll { territory in
            !populations.contains { $0.id == territory.populationId }
        }
        
        // Update or create territories for existing populations
        for pop in populations {
            let territoryArea = calculatePopulationArea(bugs: Array(pop.bugIds), in: arena)
            let quality = evaluateTerritoryQuality(area: territoryArea, arena: arena, ecosystemManager: ecosystemManager)
            
            if var existingTerritory = territories.first(where: { $0.populationId == pop.id }) {
                existingTerritory.area = territoryArea
                existingTerritory.quality = quality
            } else {
                let newTerritory = Territory(populationId: pop.id, area: territoryArea, quality: quality)
                territories.append(newTerritory)
            }
        }
    }
    
    private func calculatePopulationArea(bugs: [UUID], in arena: Arena) -> CGRect {
        // Get actual bug positions from the simulation engine
        // For now, we'll create a more realistic territory based on population size
        let populationSize = bugs.count
        
        if populationSize == 0 {
            return CGRect.zero
        }
        
        // Calculate territory size based on population size
        let baseRadius = 40.0 // Smaller base territory radius
        let sizeMultiplier = min(2.5, Double(populationSize) / 8.0) // Scale with population size
        let territoryRadius = baseRadius * sizeMultiplier
        
        // Create territories in different areas of the arena based on population ID
        // This creates more realistic, distributed territories
        let populationHash = abs(bugs.first?.hashValue ?? 0)
        let seedX = Double(populationHash % 1000) / 1000.0
        let seedY = Double((populationHash + 12345) % 1000) / 1000.0
        
        let centerX = arena.bounds.minX + (arena.bounds.width * seedX)
        let centerY = arena.bounds.minY + (arena.bounds.height * seedY)
        
        return CGRect(
            x: centerX - territoryRadius,
            y: centerY - territoryRadius,
            width: territoryRadius * 2,
            height: territoryRadius * 2
        )
    }
    
    private func evaluateTerritoryQuality(
        area: CGRect,
        arena: Arena,
        ecosystemManager: EcosystemManager
    ) -> Double {
        var totalQuality: Double = 0
        let samplePoints = 100
        
        for _ in 0..<samplePoints {
            let randomPoint = CGPoint(
                x: Double.random(in: area.minX...area.maxX),
                y: Double.random(in: area.minY...area.maxY)
            )
            
            let resourceHealth = ecosystemManager.getResourceHealth(at: randomPoint)
            let populationPressure = ecosystemManager.getPopulationPressure(at: randomPoint)
            
            // Quality is high when resources are abundant and pressure is low
            let quality = resourceHealth * (1.0 - min(1.0, populationPressure / 10.0))
            totalQuality += quality
        }
        
        return totalQuality / Double(samplePoints)
    }
    
    // MARK: - Migration Logic
    
    private func triggerMigrations(
        populations: [Population],
        ecosystemManager: EcosystemManager
    ) {
        for pop in populations {
            guard let territory = territories.first(where: { $0.populationId == pop.id }) else { continue }
            
            let urgency = calculateMigrationUrgency(territory: territory, ecosystemManager: ecosystemManager)
            
            if urgency > migrationUrgencyThreshold {
                // Find a better territory and initiate migration
                if let newTarget = findBetterTerritory(for: pop, currentTerritory: territory) {
                    initiateMigration(for: pop, to: newTarget)
                }
            }
        }
    }
    
    private func calculateMigrationUrgency(
        territory: Territory,
        ecosystemManager: EcosystemManager
    ) -> Double {
        let resourceDepletion = 1.0 - territory.quality
        let overpopulation = max(0, ecosystemManager.carryingCapacityUtilization - 1.0)
        
        return max(resourceDepletion, overpopulation)
    }
    
    private func findBetterTerritory(for population: Population, currentTerritory: Territory) -> CGPoint? {
        // Search for a promising new location (simplified)
        for _ in 0..<20 { // Try 20 random locations
            let newPos = CGPoint(
                x: Double.random(in: worldBounds.minX...worldBounds.maxX),
                y: Double.random(in: worldBounds.minY...worldBounds.maxY)
            )
            
            // Placeholder: A more sophisticated quality check would be needed here
            return newPos
        }
        return nil
    }
    
    private func initiateMigration(for population: Population, to target: CGPoint) {
        // This would set a migration target for all bugs in the population
        print("🌍 Population \(population.name) is migrating to \(target)!")
    }
    
    // MARK: - Neural Network Inputs
    
    func getTerritoryInputs(at position: CGPoint, for populationId: UUID?) -> [Double] {
        var inputs: [Double] = [0, 0, 0, 0] // own territory quality, foreign territory presence, etc.
        
        if let popId = populationId, let ownTerritory = territories.first(where: { $0.populationId == popId }) {
            inputs[0] = ownTerritory.quality
            inputs[1] = ownTerritory.area.contains(position) ? 1.0 : 0.0
        }
        
        let foreignTerritory = territories.first { $0.populationId != populationId && $0.area.contains(position) }
        if let foreign = foreignTerritory {
            inputs[2] = 1.0 // Foreign territory detected
            inputs[3] = foreign.quality
        }
        
        return inputs
    }
}
