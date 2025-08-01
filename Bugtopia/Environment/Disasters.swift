//
//  Disasters.swift
//  Bugtopia
//
//  Natural disasters that reshape terrain and create survival challenges
//

import Foundation
import SwiftUI
import Observation

// MARK: - Disaster Types

enum DisasterType: String, CaseIterable, Codable {
    case flood = "flood"
    case earthquake = "earthquake" 
    case wildfire = "wildfire"
    case volcanic = "volcanic"
    
    var icon: String {
        switch self {
        case .flood: return "🌊"
        case .earthquake: return "⚡"
        case .wildfire: return "🔥"
        case .volcanic: return "🌋"
        }
    }
    
    var name: String {
        switch self {
        case .flood: return "Flood"
        case .earthquake: return "Earthquake"
        case .wildfire: return "Wildfire"
        case .volcanic: return "Volcanic Eruption"
        }
    }
    
    var description: String {
        switch self {
        case .flood: return "Rising waters threaten to drown bugs and destroy food sources."
        case .earthquake: return "Ground tremors crack terrain and shake bugs from their paths."
        case .wildfire: return "Spreading flames consume vegetation and force mass evacuation."
        case .volcanic: return "Lava flows and ash clouds reshape the landscape permanently."
        }
    }
    
    var warningIcon: String {
        switch self {
        case .flood: return "☁️"
        case .earthquake: return "📳"
        case .wildfire: return "💨"
        case .volcanic: return "💨"
        }
    }
}

// MARK: - Disaster Effects

struct DisasterEffects {
    let movementSpeedModifier: Double
    let visionRangeModifier: Double
    let energyDrainModifier: Double
    let directDamage: Double           // Direct health damage per tick
    let terrainDamage: Double         // Chance to destroy terrain features
    let foodDestructionRate: Double   // Rate at which food is destroyed
    let spreadRate: Double            // How fast disaster spreads (0.0-1.0)
    let displacementForce: Double     // How much bugs get pushed around
    
    static let none = DisasterEffects(
        movementSpeedModifier: 1.0,
        visionRangeModifier: 1.0,
        energyDrainModifier: 1.0,
        directDamage: 0.0,
        terrainDamage: 0.0,
        foodDestructionRate: 0.0,
        spreadRate: 0.0,
        displacementForce: 0.0
    )
    
    static func forDisasterType(_ type: DisasterType, intensity: Double) -> DisasterEffects {
        let baseIntensity = max(0.1, min(1.0, intensity))
        
        switch type {
        case .flood:
            return DisasterEffects(
                movementSpeedModifier: 1.0 - (0.7 * baseIntensity),  // Severely slowed movement
                visionRangeModifier: 1.0 - (0.3 * baseIntensity),    // Reduced visibility
                energyDrainModifier: 1.0 + (0.5 * baseIntensity),    // Higher energy cost
                directDamage: 2.0 * baseIntensity,                   // Drowning damage
                terrainDamage: 0.0,                                  // Doesn't destroy terrain
                foodDestructionRate: 0.8 * baseIntensity,           // Destroys food
                spreadRate: 0.3 * baseIntensity,                    // Spreads moderately
                displacementForce: 0.4 * baseIntensity              // Pushes bugs around
            )
        case .earthquake:
            return DisasterEffects(
                movementSpeedModifier: 1.0 - (0.5 * baseIntensity),  // Unstable ground
                visionRangeModifier: 1.0 - (0.2 * baseIntensity),    // Dust clouds
                energyDrainModifier: 1.0 + (0.3 * baseIntensity),    // Balance issues
                directDamage: 1.5 * baseIntensity,                   // Falling debris
                terrainDamage: 0.9 * baseIntensity,                  // High terrain damage
                foodDestructionRate: 0.3 * baseIntensity,           // Some food destroyed
                spreadRate: 0.8 * baseIntensity,                    // Spreads quickly
                displacementForce: 1.0 * baseIntensity              // Major displacement
            )
        case .wildfire:
            return DisasterEffects(
                movementSpeedModifier: 1.0 + (0.2 * baseIntensity),  // Panic speeds up movement
                visionRangeModifier: 1.0 - (0.5 * baseIntensity),    // Heavy smoke
                energyDrainModifier: 1.0 + (0.8 * baseIntensity),    // Heat exhaustion
                directDamage: 3.0 * baseIntensity,                   // Burning damage
                terrainDamage: 0.2 * baseIntensity,                  // Burns vegetation
                foodDestructionRate: 0.95 * baseIntensity,          // Destroys almost all food
                spreadRate: 0.9 * baseIntensity,                    // Spreads very fast
                displacementForce: 0.2 * baseIntensity              // Minimal displacement
            )
        case .volcanic:
            return DisasterEffects(
                movementSpeedModifier: 1.0 - (0.6 * baseIntensity),  // Ash makes movement hard
                visionRangeModifier: 1.0 - (0.7 * baseIntensity),    // Ash clouds
                energyDrainModifier: 1.0 + (1.0 * baseIntensity),    // Toxic air
                directDamage: 4.0 * baseIntensity,                   // Lava and toxic gas
                terrainDamage: 0.3 * baseIntensity,                  // Creates/destroys terrain
                foodDestructionRate: 0.7 * baseIntensity,           // Ash kills plants
                spreadRate: 0.5 * baseIntensity,                    // Moderate spread
                displacementForce: 0.1 * baseIntensity              // Minimal displacement
            )
        }
    }
}

// MARK: - Disaster Event

struct DisasterEvent: Identifiable, Codable {
    var id = UUID()
    let type: DisasterType
    let startTime: TimeInterval
    let intensity: Double              // 0.0 to 1.0
    let epicenter: CGPoint            // Where disaster started
    let maxRadius: Double             // Maximum affected radius
    var currentRadius: Double         // Current affected radius
    let duration: Int                 // Ticks until disaster ends
    var ticksActive: Int              // How long it's been active
    var affectedTiles: Set<String>    // Tiles currently affected (encoded as "x,y")
    
    var isActive: Bool {
        return ticksActive < duration
    }
    
    var progress: Double {
        return Double(ticksActive) / Double(duration)
    }
    
    var currentEffects: DisasterEffects {
        let currentIntensity = intensity * (1.0 - progress * 0.5) // Intensity decreases over time
        return DisasterEffects.forDisasterType(type, intensity: currentIntensity)
    }
    
    // Check if a point is affected by this disaster
    func affectsPoint(_ point: CGPoint) -> Bool {
        let distance = sqrt(pow(point.x - epicenter.x, 2) + pow(point.y - epicenter.y, 2))
        return distance <= currentRadius
    }
    
    // Get disaster intensity at a specific point (decreases with distance)
    func intensityAt(_ point: CGPoint) -> Double {
        let distance = sqrt(pow(point.x - epicenter.x, 2) + pow(point.y - epicenter.y, 2))
        if distance > currentRadius { return 0.0 }
        
        let falloff = 1.0 - (distance / currentRadius)
        return intensity * falloff
    }
}

// MARK: - Disaster Manager

@Observable
class DisasterManager {
    // Current disasters
    var activeDisasters: [DisasterEvent] = []
    var recentDisasters: [DisasterEvent] = []
    var disasterHistory: [DisasterEvent] = []
    
    // Disaster timing
    private var ticksSinceLastDisaster: Int = 0
    private let minTimeBetweenDisasters: Int = 3000  // Minimum ticks between disasters
    private let maxTimeBetweenDisasters: Int = 8000  // Maximum ticks between disasters
    private var nextDisasterIn: Int = 5000           // Ticks until next disaster
    
    // World properties
    private var worldBounds: CGRect = .zero
    private var currentTick: Int = 0
    
    init() {
        reset()
    }
    
    func reset() {
        activeDisasters.removeAll()
        recentDisasters.removeAll()
        disasterHistory.removeAll()
        ticksSinceLastDisaster = 0
        nextDisasterIn = Int.random(in: minTimeBetweenDisasters...maxTimeBetweenDisasters)
        currentTick = 0
    }
    
    func setWorldBounds(_ bounds: CGRect) {
        worldBounds = bounds
    }
    
    func update(seasonalManager: SeasonalManager, weatherManager: WeatherManager) {
        currentTick += 1
        ticksSinceLastDisaster += 1
        
        // Update active disasters
        updateActiveDisasters()
        
        // Check if we should spawn a new disaster
        if shouldSpawnDisaster(seasonalManager: seasonalManager, weatherManager: weatherManager) {
            spawnRandomDisaster(seasonalManager: seasonalManager, weatherManager: weatherManager)
        }
        
        // Clean up old disasters
        cleanupOldDisasters()
    }
    
    private func updateActiveDisasters() {
        for i in 0..<activeDisasters.count {
            activeDisasters[i].ticksActive += 1
            
            // Update disaster spread
            let disaster = activeDisasters[i]
            let spreadRate = disaster.currentEffects.spreadRate
            let maxGrowth = disaster.maxRadius * 0.05 // Max 5% growth per tick
            let growth = maxGrowth * spreadRate
            
            if disaster.currentRadius < disaster.maxRadius {
                activeDisasters[i].currentRadius = min(disaster.maxRadius, disaster.currentRadius + growth)
            }
        }
        
        // Move expired disasters to recent
        let expiredDisasters = activeDisasters.filter { !$0.isActive }
        for disaster in expiredDisasters {
            recentDisasters.append(disaster)
            disasterHistory.append(disaster)
        }
        activeDisasters.removeAll { !$0.isActive }
    }
    
    private func shouldSpawnDisaster(seasonalManager: SeasonalManager, weatherManager: WeatherManager) -> Bool {
        // Basic timing check
        guard ticksSinceLastDisaster >= nextDisasterIn else { return false }
        
        // Seasonal modifiers
        let seasonalMultiplier: Double = switch seasonalManager.currentSeason {
        case .spring: 1.2  // Spring floods and storms
        case .summer: 1.5  // Summer fires and droughts
        case .fall: 0.8    // Calmer season
        case .winter: 1.0  // Winter storms and freezing
        }
        
        // Weather modifiers
        let weatherMultiplier: Double = switch weatherManager.currentWeather {
        case .drought: 2.0    // High fire risk
        case .storm: 1.8      // Can trigger floods/earthquakes
        case .rain: 1.3       // Flood risk
        case .blizzard: 1.1   // Freezing disasters
        default: 1.0
        }
        
        let totalChance = 0.1 * seasonalMultiplier * weatherMultiplier
        return Double.random(in: 0...1) < totalChance
    }
    
    private func spawnRandomDisaster(seasonalManager: SeasonalManager, weatherManager: WeatherManager) {
        // Choose disaster type based on season and weather
        let disasterWeights = calculateDisasterWeights(
            season: seasonalManager.currentSeason,
            weather: weatherManager.currentWeather
        )
        
        guard let disasterType = selectWeightedDisaster(weights: disasterWeights) else { return }
        
        // Generate disaster properties
        let epicenter = CGPoint(
            x: Double.random(in: worldBounds.minX...worldBounds.maxX),
            y: Double.random(in: worldBounds.minY...worldBounds.maxY)
        )
        
        let intensity = Double.random(in: 0.3...1.0) // Never too weak
        let maxRadius = Double.random(in: 50...200)  // Varies by size
        let duration = Int.random(in: 500...2000)    // 500-2000 ticks
        
        let disaster = DisasterEvent(
            type: disasterType,
            startTime: Date().timeIntervalSince1970,
            intensity: intensity,
            epicenter: epicenter,
            maxRadius: maxRadius,
            currentRadius: 10.0, // Starts small
            duration: duration,
            ticksActive: 0,
            affectedTiles: []
        )
        
        activeDisasters.append(disaster)
        
        // Reset timing
        ticksSinceLastDisaster = 0
        nextDisasterIn = Int.random(in: minTimeBetweenDisasters...maxTimeBetweenDisasters)
        
        print("🌋 Disaster spawned: \(disaster.type.icon) \(disaster.type.name) at (\(Int(epicenter.x)), \(Int(epicenter.y))) - Intensity: \(String(format: "%.1f", intensity)), Duration: \(duration) ticks")
    }
    
    private func calculateDisasterWeights(season: Season, weather: WeatherType) -> [DisasterType: Double] {
        var weights: [DisasterType: Double] = [:]
        
        // Base weights
        weights[.flood] = 1.0
        weights[.earthquake] = 1.0
        weights[.wildfire] = 1.0
        weights[.volcanic] = 0.5  // Rarer
        
        // Seasonal modifiers
        switch season {
        case .spring:
            weights[.flood] = 2.0      // Spring floods
            weights[.wildfire] = 0.5   // Less fire risk
        case .summer:
            weights[.wildfire] = 3.0   // High fire season
            weights[.volcanic] = 1.2   // Heat increases volcanic activity
            weights[.flood] = 0.3      // Dry season
        case .fall:
            weights[.earthquake] = 1.5 // Tectonic activity
            weights[.wildfire] = 0.7   // Lower fire risk
        case .winter:
            weights[.flood] = 0.2      // Frozen water
            weights[.wildfire] = 0.1   // Very low fire risk
            weights[.volcanic] = 0.8   // Reduced activity
        }
        
        // Weather modifiers
        switch weather {
        case .drought:
            weights[.wildfire] = (weights[.wildfire] ?? 1.0) * 2.5
            weights[.flood] = (weights[.flood] ?? 1.0) * 0.1
        case .storm:
            weights[.flood] = (weights[.flood] ?? 1.0) * 2.0
            weights[.earthquake] = (weights[.earthquake] ?? 1.0) * 1.5
        case .rain:
            weights[.flood] = (weights[.flood] ?? 1.0) * 1.8
            weights[.wildfire] = (weights[.wildfire] ?? 1.0) * 0.2
        default:
            break
        }
        
        return weights
    }
    
    private func selectWeightedDisaster(weights: [DisasterType: Double]) -> DisasterType? {
        let totalWeight = weights.values.reduce(0, +)
        guard totalWeight > 0 else { return nil }
        
        let randomValue = Double.random(in: 0...totalWeight)
        var currentWeight = 0.0
        
        for (disaster, weight) in weights {
            currentWeight += weight
            if randomValue <= currentWeight {
                return disaster
            }
        }
        
        return DisasterType.allCases.randomElement()
    }
    
    private func cleanupOldDisasters() {
        // Keep only recent disasters (last 10)
        if recentDisasters.count > 10 {
            recentDisasters = Array(recentDisasters.suffix(10))
        }
        
        // Keep disaster history (last 50)
        if disasterHistory.count > 50 {
            disasterHistory = Array(disasterHistory.suffix(50))
        }
    }
    
    // MARK: - Public Interface
    
    /// Get combined disaster effects at a specific point
    func getDisasterEffectsAt(_ point: CGPoint) -> DisasterEffects {
        var combinedEffects = DisasterEffects.none
        
        for disaster in activeDisasters {
            if disaster.affectsPoint(point) {
                let localIntensity = disaster.intensityAt(point)
                let effects = DisasterEffects.forDisasterType(disaster.type, intensity: localIntensity)
                
                // Combine effects (multiplicative for modifiers, additive for damage)
                combinedEffects = DisasterEffects(
                    movementSpeedModifier: combinedEffects.movementSpeedModifier * effects.movementSpeedModifier,
                    visionRangeModifier: combinedEffects.visionRangeModifier * effects.visionRangeModifier,
                    energyDrainModifier: combinedEffects.energyDrainModifier * effects.energyDrainModifier,
                    directDamage: combinedEffects.directDamage + effects.directDamage,
                    terrainDamage: min(1.0, combinedEffects.terrainDamage + effects.terrainDamage),
                    foodDestructionRate: min(1.0, combinedEffects.foodDestructionRate + effects.foodDestructionRate),
                    spreadRate: max(combinedEffects.spreadRate, effects.spreadRate),
                    displacementForce: combinedEffects.displacementForce + effects.displacementForce
                )
            }
        }
        
        return combinedEffects
    }
    
    /// Get neural network inputs for disaster awareness
    var disasterInputs: [Double] {
        var inputs: [Double] = []
        
        // Disaster type indicators (4 inputs)
        inputs.append(activeDisasters.contains { $0.type == .flood } ? 1.0 : 0.0)
        inputs.append(activeDisasters.contains { $0.type == .earthquake } ? 1.0 : 0.0)
        inputs.append(activeDisasters.contains { $0.type == .wildfire } ? 1.0 : 0.0)
        inputs.append(activeDisasters.contains { $0.type == .volcanic } ? 1.0 : 0.0)
        
        // Overall disaster intensity (1 input)
        let maxIntensity = activeDisasters.map { $0.intensity }.max() ?? 0.0
        inputs.append(maxIntensity)
        
        // Time until next disaster (normalized, 1 input)
        let timeProgress = 1.0 - (Double(nextDisasterIn - ticksSinceLastDisaster) / Double(nextDisasterIn))
        inputs.append(max(0.0, min(1.0, timeProgress)))
        
        return inputs
    }
    
    /// Check if food should be destroyed at a location
    func shouldDestroyFood(at point: CGPoint) -> Bool {
        for disaster in activeDisasters {
            if disaster.affectsPoint(point) {
                let localIntensity = disaster.intensityAt(point)
                let effects = DisasterEffects.forDisasterType(disaster.type, intensity: localIntensity)
                if Double.random(in: 0...1) < effects.foodDestructionRate * 0.1 { // 10% chance per tick
                    return true
                }
            }
        }
        return false
    }
    
    /// Get displacement force for a bug at a location
    func getDisplacementForce(at point: CGPoint) -> CGPoint {
        var totalForce = CGPoint.zero
        
        for disaster in activeDisasters {
            if disaster.affectsPoint(point) {
                let localIntensity = disaster.intensityAt(point)
                let effects = DisasterEffects.forDisasterType(disaster.type, intensity: localIntensity)
                
                // Force direction depends on disaster type
                let forceDirection: CGPoint = {
                    switch disaster.type {
                    case .flood, .volcanic:
                        // Away from epicenter
                        let dx = point.x - disaster.epicenter.x
                        let dy = point.y - disaster.epicenter.y
                        let distance = sqrt(dx * dx + dy * dy)
                        if distance > 0 {
                            return CGPoint(x: dx / distance, y: dy / distance)
                        } else {
                            return CGPoint(x: Double.random(in: -1...1), y: Double.random(in: -1...1))
                        }
                    case .earthquake:
                        // Random shaking
                        return CGPoint(x: Double.random(in: -1...1), y: Double.random(in: -1...1))
                    case .wildfire:
                        // Minimal displacement
                        return CGPoint.zero
                    }
                }()
                
                let forceMagnitude = effects.displacementForce * localIntensity
                totalForce.x += forceDirection.x * forceMagnitude
                totalForce.y += forceDirection.y * forceMagnitude
            }
        }
        
        return totalForce
    }
}