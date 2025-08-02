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

/// 3D Territory volume with layer-specific claims
struct Territory3D: Identifiable, Equatable {
    let id: UUID
    let populationId: UUID
    var bounds3D: (min: Position3D, max: Position3D)  // 3D bounding box
    var dominantLayer: TerrainLayer  // Primary layer of control
    var layerQualities: [TerrainLayer: Double]  // Quality per layer (0.0 to 1.0)
    var verticalRange: ClosedRange<Double>  // Z-axis range of control
    var lastDefended: TimeInterval
    var contestedLayers: Set<TerrainLayer>  // Layers under dispute
    
    init(populationId: UUID, bounds3D: (min: Position3D, max: Position3D), dominantLayer: TerrainLayer) {
        self.id = UUID()
        self.populationId = populationId
        self.bounds3D = bounds3D
        self.dominantLayer = dominantLayer
        self.layerQualities = [dominantLayer: 0.5]  // Start with medium quality
        self.verticalRange = bounds3D.min.z...bounds3D.max.z
        self.lastDefended = Date().timeIntervalSince1970
        self.contestedLayers = []
    }
    
    /// Check if a 3D position is within this territory
    func contains(_ position: Position3D) -> Bool {
        return position.x >= bounds3D.min.x && position.x <= bounds3D.max.x &&
               position.y >= bounds3D.min.y && position.y <= bounds3D.max.y &&
               position.z >= bounds3D.min.z && position.z <= bounds3D.max.z
    }
    
    /// Get territory quality at a specific layer
    func qualityAt(layer: TerrainLayer) -> Double {
        return layerQualities[layer] ?? 0.0
    }
    
    /// Get overall territory quality (weighted by layer importance)
    var overallQuality: Double {
        let weights: [TerrainLayer: Double] = [
            .aerial: 0.2,     // Sky territories are valuable but limited
            .canopy: 0.3,     // Rich in resources
            .surface: 0.4,    // Most important layer
            .underground: 0.1  // Limited but safe
        ]
        
        return layerQualities.reduce(0.0) { total, entry in
            let (layer, quality) = entry
            let weight = weights[layer] ?? 0.25
            return total + (quality * weight)
        }
    }
    
    /// Get the 2D projection for backward compatibility
    var area2D: CGRect {
        return CGRect(
            x: bounds3D.min.x,
            y: bounds3D.min.y,
            width: bounds3D.max.x - bounds3D.min.x,
            height: bounds3D.max.y - bounds3D.min.y
        )
    }
    
    /// Custom Equatable implementation
    static func == (lhs: Territory3D, rhs: Territory3D) -> Bool {
        return lhs.id == rhs.id &&
               lhs.populationId == rhs.populationId &&
               lhs.bounds3D.min == rhs.bounds3D.min &&
               lhs.bounds3D.max == rhs.bounds3D.max &&
               lhs.dominantLayer == rhs.dominantLayer &&
               lhs.layerQualities == rhs.layerQualities &&
               lhs.verticalRange == rhs.verticalRange &&
               lhs.lastDefended == rhs.lastDefended &&
               lhs.contestedLayers == rhs.contestedLayers
    }
}

/// Manages population territories and migration behaviors
@Observable
class TerritoryManager {
    
    // MARK: - Properties
    
    private(set) var territories: [Territory] = []
    private(set) var territories3D: [Territory3D] = []  // NEW: 3D territorial system
    private var worldBounds: CGRect = .zero
    private var worldBounds3D: (min: Position3D, max: Position3D) = (
        min: Position3D(-500, -500, -100),
        max: Position3D(500, 500, 200)
    )
    
    // MARK: - Configuration
    
    private let territoryGridResolution = 20 // For quality assessment
    private let minTerritoryQuality: Double = 0.3 // Minimum quality to be considered valuable
    private let migrationUrgencyThreshold: Double = 0.8 // How bad things must get before migrating
    
    // MARK: - Core Functionality
    
    func reset() {
        territories.removeAll()
        territories3D.removeAll()
    }
    
    func setWorldBounds(_ bounds: CGRect) {
        self.worldBounds = bounds
    }
    
    func setWorldBounds3D(min: Position3D, max: Position3D) {
        self.worldBounds3D = (min: min, max: max)
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
        // Population migrating
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
    
    // MARK: - 3D Territory Management
    
    /// Update 3D territories for populations with bugs that have 3D capabilities
    func update3DTerritories(
        populations: [Population],
        bugs: [Bug],  // Need actual bug instances for 3D positions
        arena3D: Arena3D?,
        ecosystemManager: EcosystemManager
    ) {
        // Remove territories of extinct populations
        territories3D.removeAll { territory in
            !populations.contains { $0.id == territory.populationId }
        }
        
        // Update or create 3D territories for existing populations
        for pop in populations {
            let populationBugs = bugs.filter { bug in
                pop.bugIds.contains(bug.id)
            }
            
            guard !populationBugs.isEmpty else { continue }
            
            // Calculate 3D territory bounds based on bug positions and capabilities
            let territory3D = calculate3DTerritoryBounds(
                bugs: populationBugs,
                populationId: pop.id,
                arena3D: arena3D
            )
            
            // Evaluate territory quality across all layers
            let layerQualities = evaluate3DTerritoryQuality(
                territory: territory3D,
                arena3D: arena3D,
                ecosystemManager: ecosystemManager
            )
            
            // Update existing or create new 3D territory
            if let index = territories3D.firstIndex(where: { $0.populationId == pop.id }) {
                territories3D[index].bounds3D = territory3D.bounds3D
                territories3D[index].layerQualities = layerQualities
                territories3D[index].dominantLayer = findDominantLayer(qualities: layerQualities)
                territories3D[index].contestedLayers = findContestedLayers(
                    territory: territories3D[index],
                    otherTerritories: territories3D
                )
            } else {
                var newTerritory = territory3D
                newTerritory.layerQualities = layerQualities
                newTerritory.dominantLayer = findDominantLayer(qualities: layerQualities)
                territories3D.append(newTerritory)
            }
        }
        
        // Handle territorial conflicts
        resolve3DTerritorialConflicts()
    }
    
    /// Calculate 3D territory bounds based on bug positions and movement capabilities
    private func calculate3DTerritoryBounds(
        bugs: [Bug],
        populationId: UUID,
        arena3D: Arena3D?
    ) -> Territory3D {
        guard !bugs.isEmpty else {
            // Fallback territory
            let center = Position3D(0, 0, 0)
            let size = 50.0
            return Territory3D(
                populationId: populationId,
                bounds3D: (
                    min: Position3D(center.x - size, center.y - size, center.z - size),
                    max: Position3D(center.x + size, center.y + size, center.z + size)
                ),
                dominantLayer: .surface
            )
        }
        
        // Find the bounds of all bug positions
        let positions = bugs.map { $0.position3D }
        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x }.max() ?? 0
        let minY = positions.map { $0.y }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 0
        let minZ = positions.map { $0.z }.min() ?? 0
        let maxZ = positions.map { $0.z }.max() ?? 0
        
        // Expand territory based on population capabilities and size
        let populationSize = bugs.count
        let expansionFactor = min(3.0, 1.0 + Double(populationSize) / 10.0)
        let baseExpansion = 30.0 * expansionFactor
        
        // Vertical expansion based on movement capabilities
        let canFly = bugs.contains { $0.canFly }
        let canSwim = bugs.contains { $0.canSwim }
        let canClimb = bugs.contains { $0.canClimb }
        
        let verticalExpansion = baseExpansion * (
            (canFly ? 1.5 : 1.0) * 
            (canSwim ? 1.3 : 1.0) * 
            (canClimb ? 1.2 : 1.0)
        )
        
        let bounds3D = (
            min: Position3D(
                max(worldBounds3D.min.x, minX - baseExpansion),
                max(worldBounds3D.min.y, minY - baseExpansion),
                max(worldBounds3D.min.z, minZ - verticalExpansion)
            ),
            max: Position3D(
                min(worldBounds3D.max.x, maxX + baseExpansion),
                min(worldBounds3D.max.y, maxY + baseExpansion),
                min(worldBounds3D.max.z, maxZ + verticalExpansion)
            )
        )
        
        // Determine dominant layer based on bug preferences
        let layerPreferences = bugs.map { $0.getPreferredLayer() }
        let dominantLayer = layerPreferences.mostCommon() ?? .surface
        
        return Territory3D(
            populationId: populationId,
            bounds3D: bounds3D,
            dominantLayer: dominantLayer
        )
    }
    
    /// Evaluate territory quality across all terrain layers
    private func evaluate3DTerritoryQuality(
        territory: Territory3D,
        arena3D: Arena3D?,
        ecosystemManager: EcosystemManager
    ) -> [TerrainLayer: Double] {
        var layerQualities: [TerrainLayer: Double] = [:]
        
        for layer in TerrainLayer.allCases {
            var totalQuality: Double = 0
            let samplePoints = 25  // Sample points per layer
            
            for _ in 0..<samplePoints {
                // Sample random points within the territory at this layer's height
                let randomX = Double.random(in: territory.bounds3D.min.x...territory.bounds3D.max.x)
                let randomY = Double.random(in: territory.bounds3D.min.y...territory.bounds3D.max.y)
                let layerHeight = layer.heightRange.lowerBound + 
                                 (layer.heightRange.upperBound - layer.heightRange.lowerBound) / 2
                
                let samplePoint = Position3D(randomX, randomY, layerHeight)
                let point2D = CGPoint(x: randomX, y: randomY)
                
                // Base quality from ecosystem
                let resourceHealth = ecosystemManager.getResourceHealth(at: point2D)
                let populationPressure = ecosystemManager.getPopulationPressure(at: point2D)
                let baseQuality = resourceHealth * (1.0 - min(1.0, populationPressure / 10.0))
                
                // Layer-specific quality modifiers
                let layerModifier = getLayerQualityModifier(layer: layer, position: samplePoint)
                
                totalQuality += baseQuality * layerModifier
            }
            
            layerQualities[layer] = totalQuality / Double(samplePoints)
        }
        
        return layerQualities
    }
    
    /// Get quality modifier for specific terrain layers
    private func getLayerQualityModifier(layer: TerrainLayer, position: Position3D) -> Double {
        switch layer {
        case .aerial:
            // High altitude is risky but offers great visibility and escape routes
            return 0.8 + (position.z > 150 ? 0.3 : 0.0)
        case .canopy:
            // Rich in resources, good protection
            return 1.2
        case .surface:
            // Most balanced layer
            return 1.0
        case .underground:
            // Safe but limited resources
            return 0.6 + (position.z < -50 ? 0.2 : 0.0)  // Deeper = safer
        }
    }
    
    /// Find the dominant layer (highest quality)
    private func findDominantLayer(qualities: [TerrainLayer: Double]) -> TerrainLayer {
        return qualities.max { $0.value < $1.value }?.key ?? .surface
    }
    
    /// Find layers that are contested by other populations
    private func findContestedLayers(
        territory: Territory3D,
        otherTerritories: [Territory3D]
    ) -> Set<TerrainLayer> {
        var contested: Set<TerrainLayer> = []
        
        for otherTerritory in otherTerritories {
            guard otherTerritory.populationId != territory.populationId else { continue }
            
            // Check for overlapping bounds
            let overlaps = territory.bounds3D.min.x < otherTerritory.bounds3D.max.x &&
                          territory.bounds3D.max.x > otherTerritory.bounds3D.min.x &&
                          territory.bounds3D.min.y < otherTerritory.bounds3D.max.y &&
                          territory.bounds3D.max.y > otherTerritory.bounds3D.min.y &&
                          territory.bounds3D.min.z < otherTerritory.bounds3D.max.z &&
                          territory.bounds3D.max.z > otherTerritory.bounds3D.min.z
            
            if overlaps {
                // Find which layers are contested
                for layer in TerrainLayer.allCases {
                    let layerRange = layer.heightRange
                    let territoryHasLayer = territory.verticalRange.overlaps(layerRange)
                    let otherHasLayer = otherTerritory.verticalRange.overlaps(layerRange)
                    
                    if territoryHasLayer && otherHasLayer {
                        contested.insert(layer)
                    }
                }
            }
        }
        
        return contested
    }
    
    /// Resolve territorial conflicts through quality-based dominance
    private func resolve3DTerritorialConflicts() {
        // Group territories by overlapping regions
        var conflictGroups: [[Territory3D]] = []
        
        for territory in territories3D {
            if !territory.contestedLayers.isEmpty {
                // Find existing conflict group or create new one
                var addedToGroup = false
                for i in 0..<conflictGroups.count {
                    if conflictGroups[i].contains(where: { $0.populationId == territory.populationId }) {
                        continue  // Already in this group
                    }
                    
                    // Check if this territory conflicts with any in the group
                    let hasConflict = conflictGroups[i].contains { other in
                        !territory.contestedLayers.intersection(other.contestedLayers).isEmpty
                    }
                    
                    if hasConflict {
                        conflictGroups[i].append(territory)
                        addedToGroup = true
                        break
                    }
                }
                
                if !addedToGroup {
                    conflictGroups.append([territory])
                }
            }
        }
        
        // Resolve each conflict group
        for conflictGroup in conflictGroups {
            resolveConflictGroup(conflictGroup)
        }
    }
    
    /// Resolve conflicts within a group of overlapping territories
    private func resolveConflictGroup(_ conflictingTerritories: [Territory3D]) {
        guard conflictingTerritories.count > 1 else { return }
        
        // For each contested layer, determine the winner based on quality and capabilities
        var layerOwnership: [TerrainLayer: UUID] = [:]
        
        for layer in TerrainLayer.allCases {
            let contenders = conflictingTerritories.filter { territory in
                territory.contestedLayers.contains(layer) || territory.dominantLayer == layer
            }
            
            if let winner = contenders.max(by: { 
                ($0.qualityAt(layer: layer) + ($0.dominantLayer == layer ? 0.2 : 0.0)) < 
                ($1.qualityAt(layer: layer) + ($1.dominantLayer == layer ? 0.2 : 0.0))
            }) {
                layerOwnership[layer] = winner.populationId
            }
        }
        
        // Update territories based on conflict resolution
        for i in 0..<territories3D.count {
            let populationId = territories3D[i].populationId
            
            // Remove contested status for layers this population won
            let wonLayers = layerOwnership.compactMap { (layer, winner) in
                winner == populationId ? layer : nil
            }
            
            for wonLayer in wonLayers {
                territories3D[i].contestedLayers.remove(wonLayer)
            }
            
            // Reduce quality for lost layers
            let lostLayers = layerOwnership.compactMap { (layer, winner) in
                winner != populationId && territories3D[i].contestedLayers.contains(layer) ? layer : nil
            }
            
            for lostLayer in lostLayers {
                territories3D[i].layerQualities[lostLayer] = 
                    (territories3D[i].layerQualities[lostLayer] ?? 0.0) * 0.3  // Significant penalty
                territories3D[i].contestedLayers.remove(lostLayer)
            }
        }
    }
    
    /// Get 3D territory inputs for neural networks (enhanced version)
    func get3DTerritoryInputs(at position: Position3D, for populationId: UUID?) -> [Double] {
        var inputs: [Double] = Array(repeating: 0.0, count: 12)  // 12 3D territory inputs
        
        guard let popId = populationId else { return inputs }
        
        // Find own 3D territory
        if let ownTerritory = territories3D.first(where: { $0.populationId == popId }) {
            inputs[0] = ownTerritory.overallQuality  // Overall territory quality
            inputs[1] = ownTerritory.contains(position) ? 1.0 : 0.0  // Inside own territory
            
            // Layer-specific qualities (4 inputs)
            inputs[2] = ownTerritory.qualityAt(layer: .aerial)
            inputs[3] = ownTerritory.qualityAt(layer: .canopy)
            inputs[4] = ownTerritory.qualityAt(layer: .surface)
            inputs[5] = ownTerritory.qualityAt(layer: .underground)
            
            // Territory size indicator
            let territoryVolume = (ownTerritory.bounds3D.max.x - ownTerritory.bounds3D.min.x) *
                                 (ownTerritory.bounds3D.max.y - ownTerritory.bounds3D.min.y) *
                                 (ownTerritory.bounds3D.max.z - ownTerritory.bounds3D.min.z)
            inputs[6] = min(1.0, territoryVolume / 1000000.0)  // Normalize by large volume
            
            // Contested layers indicator
            inputs[7] = Double(ownTerritory.contestedLayers.count) / 4.0  // Max 4 layers
        }
        
        // Foreign territory detection
        let foreignTerritories = territories3D.filter { $0.populationId != popId && $0.contains(position) }
        if let strongestForeign = foreignTerritories.max(by: { $0.overallQuality < $1.overallQuality }) {
            inputs[8] = 1.0  // Foreign territory detected
            inputs[9] = strongestForeign.overallQuality  // Foreign territory quality
            
            // Determine current layer for context
            let currentLayer = TerrainLayer.allCases.first { layer in
                layer.heightRange.contains(position.z)
            } ?? .surface
            
            inputs[10] = strongestForeign.qualityAt(layer: currentLayer)  // Foreign quality at current layer
            inputs[11] = strongestForeign.contestedLayers.contains(currentLayer) ? 1.0 : 0.0  // Is current layer contested
        }
        
        return inputs
    }
}

// MARK: - Helper Extensions

extension Array where Element: Hashable {
    /// Find the most common element in the array
    func mostCommon() -> Element? {
        let counts = Dictionary(grouping: self, by: { $0 }).mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key
    }
}
