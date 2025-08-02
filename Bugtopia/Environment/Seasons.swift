//
//  Seasons.swift
//  Bugtopia
//
//  Created by AI Assistant on Phase 6 Implementation
//

import Foundation
import SwiftUI

// MARK: - Seasonal System

/// Represents the four seasons with their unique environmental effects
enum Season: String, CaseIterable, Codable {
    case spring = "spring"
    case summer = "summer" 
    case fall = "fall"
    case winter = "winter"
    
    /// Visual representation
    var emoji: String {
        switch self {
        case .spring: return "🌱"
        case .summer: return "☀️"
        case .fall: return "🍂"
        case .winter: return "❄️"
        }
    }
    
    /// Color theme for UI
    var color: Color {
        switch self {
        case .spring: return .green
        case .summer: return .yellow
        case .fall: return .orange
        case .winter: return .cyan
        }
    }
    
    /// Duration of each season in ticks
    var duration: Int {
        switch self {
        case .spring: return 1500  // Growth and renewal
        case .summer: return 2000  // Peak activity period
        case .fall: return 1200    // Preparation time
        case .winter: return 800   // Harsh survival period
        }
    }
    
    /// Food abundance multiplier
    var foodAbundance: Double {
        switch self {
        case .spring: return 1.4   // Abundant new growth
        case .summer: return 1.6   // Peak food availability
        case .fall: return 1.0     // Normal harvest time
        case .winter: return 0.3   // Scarce resources
        }
    }
    
    /// Reproduction rate modifier
    var reproductionModifier: Double {
        switch self {
        case .spring: return 1.3   // Breeding season
        case .summer: return 1.5   // Optimal conditions
        case .fall: return 0.8     // Preparing for winter
        case .winter: return 0.4   // Survival mode
        }
    }
    
    /// Energy drain multiplier (cold = more energy needed)
    var energyDrainModifier: Double {
        switch self {
        case .spring: return 0.9   // Mild conditions
        case .summer: return 0.8   // Efficient metabolism
        case .fall: return 1.0     // Normal conditions
        case .winter: return 1.4   // Cold = more energy needed
        }
    }
    
    /// Resource regeneration rate
    var resourceRegeneration: Double {
        switch self {
        case .spring: return 1.5   // Fast regrowth
        case .summer: return 1.2   // Continued growth
        case .fall: return 0.8     // Slowing down
        case .winter: return 0.3   // Minimal regeneration
        }
    }
    
    /// Movement speed modifier (weather effects)
    var movementModifier: Double {
        switch self {
        case .spring: return 1.1   // Pleasant weather
        case .summer: return 1.0   // Normal conditions
        case .fall: return 0.95    // Getting colder
        case .winter: return 0.7   // Snow and ice slow movement
        }
    }
    
    /// Tool construction efficiency (weather affects building)
    var constructionModifier: Double {
        switch self {
        case .spring: return 1.2   // Good building weather
        case .summer: return 1.3   // Optimal conditions
        case .fall: return 1.1     // Still decent
        case .winter: return 0.6   // Harsh building conditions
        }
    }
    
    /// Next season in the cycle
    var next: Season {
        switch self {
        case .spring: return .summer
        case .summer: return .fall
        case .fall: return .winter
        case .winter: return .spring
        }
    }
}

/// Manages the seasonal cycle and environmental changes
@Observable
class SeasonalManager {
    
    // MARK: - State
    
    /// Current season
    var currentSeason: Season = .spring
    
    /// Ticks elapsed in current season
    var seasonalTicks: Int = 0
    
    /// Total seasonal cycles completed
    var yearCount: Int = 0
    
    /// Whether seasons change automatically
    var automaticSeasonalProgression: Bool = true
    
    // MARK: - Seasonal Progression
    
    /// Updates the seasonal system each tick
    func update() {
        guard automaticSeasonalProgression else { return }
        
        seasonalTicks += 1
        
        // Check if season should change
        if seasonalTicks >= currentSeason.duration {
            advanceToNextSeason()
        }
    }
    
    /// Manually advance to the next season
    func advanceToNextSeason() {
        let oldSeason = currentSeason
        currentSeason = currentSeason.next
        seasonalTicks = 0
        
        // Increment year when returning to spring
        if currentSeason == .spring {
            yearCount += 1
        }
        
        // Season changed
    }
    
    /// Reset seasonal system
    func reset() {
        currentSeason = .spring
        seasonalTicks = 0
        yearCount = 0
    }
    
    // MARK: - Seasonal Effects
    
    /// Get food spawn rate adjusted for current season
    func adjustedFoodSpawnRate(baseRate: Double) -> Double {
        return baseRate * currentSeason.foodAbundance
    }
    
    /// Get reproduction threshold adjusted for current season
    func adjustedReproductionThreshold(baseThreshold: Double) -> Double {
        return baseThreshold / currentSeason.reproductionModifier
    }
    
    /// Get energy drain adjusted for current season
    func adjustedEnergyDrain(baseDrain: Double) -> Double {
        return baseDrain * currentSeason.energyDrainModifier
    }
    
    /// Get resource regeneration adjusted for current season
    func adjustedResourceRegeneration(baseRegen: Double) -> Double {
        return baseRegen * currentSeason.resourceRegeneration
    }
    
    /// Get movement speed adjusted for current season
    func adjustedMovementSpeed(baseSpeed: Double) -> Double {
        return baseSpeed * currentSeason.movementModifier
    }
    
    /// Get construction rate adjusted for current season
    func adjustedConstructionRate(baseRate: Double) -> Double {
        return baseRate * currentSeason.constructionModifier
    }
    
    // MARK: - Season Detection for AI
    
    /// Neural network input representing current season (0.0 to 1.0 for each season)
    var seasonalInputs: [Double] {
        return Season.allCases.map { season in
            season == currentSeason ? 1.0 : 0.0
        }
    }
    
    /// Progress through current season (0.0 to 1.0)
    var seasonProgress: Double {
        return Double(seasonalTicks) / Double(currentSeason.duration)
    }
    
    /// Days until next season (for advanced AI planning)
    var ticksUntilNextSeason: Int {
        return currentSeason.duration - seasonalTicks
    }
    
    // MARK: - Seasonal Behaviors
    
    /// Whether bugs should prioritize reproduction (spring/summer)
    var isBreedingSeason: Bool {
        return currentSeason.reproductionModifier > 1.0
    }
    
    /// Whether bugs should hoard resources (fall/winter approaching)
    var isHoardingSeason: Bool {
        return currentSeason == .fall || ticksUntilNextSeason < 200
    }
    
    /// Whether bugs should seek shelter (winter)
    var isShelterSeason: Bool {
        return currentSeason == .winter
    }
    
    /// Whether bugs should explore and build (spring/summer)
    var isExpansionSeason: Bool {
        return currentSeason == .spring || currentSeason == .summer
    }
}

// MARK: - Seasonal Events

/// Special events that can occur during specific seasons
enum SeasonalEvent: String, CaseIterable {
    case springFlood = "spring_flood"           // Spring: melting creates floods
    case summerDrought = "summer_drought"       // Summer: extreme heat, water scarce
    case fallMigration = "fall_migration"       // Fall: resource locations shift
    case winterBlizzard = "winter_blizzard"     // Winter: severe movement penalties
    
    var season: Season {
        switch self {
        case .springFlood: return .spring
        case .summerDrought: return .summer
        case .fallMigration: return .fall
        case .winterBlizzard: return .winter
        }
    }
    
    var probability: Double {
        switch self {
        case .springFlood: return 0.15      // 15% chance each spring
        case .summerDrought: return 0.20    // 20% chance each summer
        case .fallMigration: return 0.25    // 25% chance each fall
        case .winterBlizzard: return 0.30   // 30% chance each winter
        }
    }
    
    var duration: Int {
        switch self {
        case .springFlood: return 300       // 300 ticks
        case .summerDrought: return 500     // 500 ticks
        case .fallMigration: return 100     // 100 ticks (instant resource shift)
        case .winterBlizzard: return 400    // 400 ticks
        }
    }
    
    var description: String {
        switch self {
        case .springFlood: return "🌊 Spring floods reshape the landscape"
        case .summerDrought: return "🏜️ Severe drought reduces food sources"
        case .fallMigration: return "🦋 Resources migrate to new locations"
        case .winterBlizzard: return "🌨️ Blizzard severely hampers movement"
        }
    }
}