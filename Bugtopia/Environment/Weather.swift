//
//  Weather.swift
//  Bugtopia
//
//  Dynamic weather patterns that create survival challenges and drive evolution
//

import Foundation
import SwiftUI
import Observation

/// Types of weather conditions
enum WeatherType: String, CaseIterable, Codable {
    case clear = "clear"
    case rain = "rain"
    case drought = "drought"
    case blizzard = "blizzard"
    case storm = "storm"
    case fog = "fog"
    
    /// Weather emoji for UI display
    var emoji: String {
        switch self {
        case .clear: return "☀️"
        case .rain: return "🌧️"
        case .drought: return "🏜️"
        case .blizzard: return "❄️"
        case .storm: return "⛈️"
        case .fog: return "🌫️"
        }
    }
    
    /// Weather name
    var name: String {
        switch self {
        case .clear: return "Clear"
        case .rain: return "Rain"
        case .drought: return "Drought"
        case .blizzard: return "Blizzard"
        case .storm: return "Storm"
        case .fog: return "Fog"
        }
    }
    
    /// Weather color for UI effects
    var color: Color {
        switch self {
        case .clear: return .yellow
        case .rain: return .blue
        case .drought: return .orange
        case .blizzard: return .white
        case .storm: return .purple
        case .fog: return .gray
        }
    }
    
    /// Typical duration in ticks (varies by weather)
    var baseDuration: Int {
        switch self {
        case .clear: return 800  // Longest stable weather
        case .rain: return 300   // Moderate duration
        case .drought: return 600 // Long-lasting scarcity
        case .blizzard: return 200 // Short but intense
        case .storm: return 150   // Brief but dramatic
        case .fog: return 250     // Reduces visibility
        }
    }
    
    /// Weather intensity (0.0 to 1.0)
    var intensity: Double {
        switch self {
        case .clear: return 0.0
        case .rain: return 0.4
        case .drought: return 0.7
        case .blizzard: return 0.9
        case .storm: return 1.0
        case .fog: return 0.3
        }
    }
}

/// Weather effects on the environment and bugs
struct WeatherEffects {
    // Movement effects
    let movementSpeedModifier: Double    // Multiplier for bug movement speed
    let energyDrainModifier: Double      // Additional energy drain per tick
    let visionRangeModifier: Double      // Multiplier for vision range
    
    // Environmental effects
    let foodSpawnRateModifier: Double    // Multiplier for food spawning
    let constructionSpeedModifier: Double // Building speed modifier
    let resourceGatheringModifier: Double // Resource collection speed
    
    // Survival challenges
    let coldDamage: Double              // Energy loss from cold
    let heatDamage: Double              // Energy loss from heat
    let wetnessPenalty: Double          // Movement penalty from wet conditions
    
    // Behavioral recommendations
    let behaviorRecommendation: String
}

extension WeatherType {
    /// Get the environmental effects of this weather
    var effects: WeatherEffects {
        switch self {
        case .clear:
            return WeatherEffects(
                movementSpeedModifier: 1.0,
                energyDrainModifier: 1.0,
                visionRangeModifier: 1.0,
                foodSpawnRateModifier: 1.0,
                constructionSpeedModifier: 1.0,
                resourceGatheringModifier: 1.0,
                coldDamage: 0.0,
                heatDamage: 0.0,
                wetnessPenalty: 0.0,
                behaviorRecommendation: "Ideal conditions for exploration and growth"
            )
            
        case .rain:
            return WeatherEffects(
                movementSpeedModifier: 0.8,     // Slippery conditions
                energyDrainModifier: 1.1,       // Staying warm costs energy
                visionRangeModifier: 0.7,       // Rain obscures vision
                foodSpawnRateModifier: 1.3,     // Plants love rain
                constructionSpeedModifier: 0.6, // Hard to build in rain
                resourceGatheringModifier: 0.8, // Wet resources harder to collect
                coldDamage: 0.05,               // Getting cold and wet
                heatDamage: 0.0,
                wetnessPenalty: 0.1,            // Movement penalty
                behaviorRecommendation: "Seek shelter, but food is abundant"
            )
            
        case .drought:
            return WeatherEffects(
                movementSpeedModifier: 0.9,     // Slightly sluggish
                energyDrainModifier: 1.4,       // Dehydration stress
                visionRangeModifier: 1.1,       // Clear, dry air
                foodSpawnRateModifier: 0.3,     // Very limited food
                constructionSpeedModifier: 1.1, // Good building weather
                resourceGatheringModifier: 0.7, // Dry resources are brittle
                coldDamage: 0.0,
                heatDamage: 0.15,               // Heat exhaustion
                wetnessPenalty: 0.0,
                behaviorRecommendation: "Conserve energy, compete fiercely for food"
            )
            
        case .blizzard:
            return WeatherEffects(
                movementSpeedModifier: 0.4,     // Nearly immobilized
                energyDrainModifier: 1.8,       // Extreme cold
                visionRangeModifier: 0.3,       // Whiteout conditions
                foodSpawnRateModifier: 0.1,     // Almost no food available
                constructionSpeedModifier: 0.2, // Nearly impossible to build
                resourceGatheringModifier: 0.3, // Resources buried in snow
                coldDamage: 0.3,                // Severe hypothermia risk
                heatDamage: 0.0,
                wetnessPenalty: 0.2,            // Deep snow
                behaviorRecommendation: "Survival mode: seek shelter, huddle together"
            )
            
        case .storm:
            return WeatherEffects(
                movementSpeedModifier: 0.5,     // Fighting strong winds
                energyDrainModifier: 1.6,       // Exhausting conditions
                visionRangeModifier: 0.4,       // Dark storm clouds
                foodSpawnRateModifier: 0.8,     // Some disruption
                constructionSpeedModifier: 0.3, // Dangerous to build
                resourceGatheringModifier: 0.5, // Wind blows resources around
                coldDamage: 0.1,                // Wind chill
                heatDamage: 0.0,
                wetnessPenalty: 0.15,           // Driving rain
                behaviorRecommendation: "Take cover immediately, avoid open areas"
            )
            
        case .fog:
            return WeatherEffects(
                movementSpeedModifier: 0.7,     // Cautious movement
                energyDrainModifier: 1.05,      // Slight navigation stress
                visionRangeModifier: 0.4,       // Very limited visibility
                foodSpawnRateModifier: 0.9,     // Slight reduction
                constructionSpeedModifier: 0.8, // Hard to see what you're building
                resourceGatheringModifier: 0.7, // Hard to find resources
                coldDamage: 0.02,               // Cool, damp conditions
                heatDamage: 0.0,
                wetnessPenalty: 0.05,           // Moist conditions
                behaviorRecommendation: "Navigate carefully, stay close to known areas"
            )
        }
    }
}

/// Manages dynamic weather patterns and their effects
@Observable
class WeatherManager {
    // Current weather state
    var currentWeather: WeatherType = .clear
    var weatherIntensity: Double = 0.0
    var weatherDuration: Int = 0
    var weatherProgress: Double = 0.0
    
    // Weather history and prediction
    var recentWeatherEvents: [WeatherEvent] = []
    private var ticksSinceWeatherChange: Int = 0
    private var maxWeatherDuration: Int = 800
    
    // Weather probability modifiers
    private var seasonalWeatherBias: [WeatherType: Double] = [:]
    
    init() {
        generateInitialWeather()
    }
    
    /// Reset weather system to initial state
    func reset() {
        currentWeather = .clear
        weatherIntensity = 0.0
        weatherDuration = 0
        weatherProgress = 0.0
        ticksSinceWeatherChange = 0
        recentWeatherEvents.removeAll()
        generateInitialWeather()
    }
    
    /// Update weather system each simulation tick
    func update(seasonalManager: SeasonalManager) {
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.ticksSinceWeatherChange += 1
            
            // Update progress and remaining duration
            if self.maxWeatherDuration > 0 {
                self.weatherProgress = Double(self.ticksSinceWeatherChange) / Double(self.maxWeatherDuration)
                self.weatherDuration = max(0, self.maxWeatherDuration - self.ticksSinceWeatherChange)
            }
            
            // Check if weather should change
            if self.shouldChangeWeather() {
                self.changeWeather(seasonalManager: seasonalManager)
            }
            
            // Update weather intensity based on progress
            self.updateWeatherIntensity()
            
            // Clean up old weather events
            self.cleanupOldWeatherEvents()
        }
    }
    
    /// Determine if weather should change
    private func shouldChangeWeather() -> Bool {
        // Always change when duration expires
        if ticksSinceWeatherChange >= maxWeatherDuration {
            return true
        }
        
        // Small chance of early weather change for variety
        if ticksSinceWeatherChange > maxWeatherDuration / 2 {
            return Double.random(in: 0...1) < 0.005 // 0.5% chance per tick
        }
        
        return false
    }
    
    /// Change to new weather pattern
    private func changeWeather(seasonalManager: SeasonalManager) {
        let previousWeather = currentWeather
        
        // Calculate seasonal weather preferences
        updateSeasonalBias(for: seasonalManager.currentSeason)
        
        // Select new weather based on seasonal bias and current conditions
        currentWeather = selectNewWeather(current: previousWeather)
        
        // Set new duration with some randomness
        let baseDuration = currentWeather.baseDuration
        maxWeatherDuration = Int(Double(baseDuration) * Double.random(in: 0.7...1.4))
        weatherDuration = maxWeatherDuration
        
        // Reset progress
        ticksSinceWeatherChange = 0
        weatherProgress = 0.0
        
        // Record weather event
        let event = WeatherEvent(
            type: currentWeather,
            startTime: Date(),
            estimatedDuration: maxWeatherDuration,
            seasonContext: seasonalManager.currentSeason
        )
        recentWeatherEvents.append(event)
        
        // Weather changed
    }
    
    /// Update seasonal weather bias
    private func updateSeasonalBias(for season: Season) {
        switch season {
        case .spring:
            seasonalWeatherBias = [
                .clear: 0.4,
                .rain: 0.35,    // Spring showers
                .fog: 0.15,     // Morning fog
                .storm: 0.08,   // Spring storms
                .drought: 0.02,
                .blizzard: 0.0
            ]
            
        case .summer:
            seasonalWeatherBias = [
                .clear: 0.5,
                .drought: 0.25,  // Hot, dry spells
                .storm: 0.15,    // Summer thunderstorms
                .rain: 0.08,
                .fog: 0.02,
                .blizzard: 0.0
            ]
            
        case .fall:
            seasonalWeatherBias = [
                .clear: 0.3,
                .rain: 0.25,     // Autumn rains
                .fog: 0.2,       // Misty mornings
                .storm: 0.15,    // Fall storms
                .drought: 0.08,
                .blizzard: 0.02  // Early winter weather
            ]
            
        case .winter:
            seasonalWeatherBias = [
                .blizzard: 0.3,  // Winter storms
                .clear: 0.25,    // Cold, clear days
                .fog: 0.2,       // Winter fog
                .drought: 0.15,  // Dry winter air
                .storm: 0.08,
                .rain: 0.02      // Rare in winter
            ]
        }
    }
    
    /// Select new weather based on bias and current conditions
    private func selectNewWeather(current: WeatherType) -> WeatherType {
        // Avoid immediate repeats (except clear weather)
        var availableWeather = seasonalWeatherBias
        if current != .clear {
            availableWeather[current] = availableWeather[current]! * 0.2
        }
        
        // Create weighted selection
        let totalWeight = availableWeather.values.reduce(0, +)
        let randomValue = Double.random(in: 0...totalWeight)
        
        var cumulative = 0.0
        for (weather, weight) in availableWeather {
            cumulative += weight
            if randomValue <= cumulative {
                return weather
            }
        }
        
        return .clear // Fallback
    }
    
    /// Update weather intensity based on progress through weather event
    private func updateWeatherIntensity() {
        let baseIntensity = currentWeather.intensity
        
        // Create intensity curve: build up, sustain, fade out
        let progress = weatherProgress
        
        if progress < 0.2 {
            // Building up (0-20%)
            weatherIntensity = baseIntensity * (progress / 0.2)
        } else if progress < 0.8 {
            // Sustained (20-80%)
            weatherIntensity = baseIntensity
        } else {
            // Fading out (80-100%)
            let fadeProgress = (progress - 0.8) / 0.2
            weatherIntensity = baseIntensity * (1.0 - fadeProgress)
        }
        
        // Ensure intensity stays within bounds
        weatherIntensity = max(0.0, min(1.0, weatherIntensity))
    }
    
    /// Generate initial weather conditions
    private func generateInitialWeather() {
        currentWeather = .clear
        maxWeatherDuration = 400
        weatherDuration = maxWeatherDuration
        ticksSinceWeatherChange = 0
        weatherIntensity = 0.0
    }
    
    /// Clean up old weather events to prevent memory bloat
    private func cleanupOldWeatherEvents() {
        let cutoffTime = Date().addingTimeInterval(-1800) // Keep 30 minutes of history
        recentWeatherEvents.removeAll { $0.startTime < cutoffTime }
    }
    
    /// Get current weather effects modified by intensity
    var currentEffects: WeatherEffects {
        let baseEffects = currentWeather.effects
        let intensity = weatherIntensity
        
        return WeatherEffects(
            movementSpeedModifier: 1.0 - (1.0 - baseEffects.movementSpeedModifier) * intensity,
            energyDrainModifier: 1.0 + (baseEffects.energyDrainModifier - 1.0) * intensity,
            visionRangeModifier: 1.0 - (1.0 - baseEffects.visionRangeModifier) * intensity,
            foodSpawnRateModifier: 1.0 + (baseEffects.foodSpawnRateModifier - 1.0) * intensity,
            constructionSpeedModifier: 1.0 - (1.0 - baseEffects.constructionSpeedModifier) * intensity,
            resourceGatheringModifier: 1.0 - (1.0 - baseEffects.resourceGatheringModifier) * intensity,
            coldDamage: baseEffects.coldDamage * intensity,
            heatDamage: baseEffects.heatDamage * intensity,
            wetnessPenalty: baseEffects.wetnessPenalty * intensity,
            behaviorRecommendation: baseEffects.behaviorRecommendation
        )
    }
    
    /// Get weather inputs for neural networks (6 inputs)
    var weatherInputs: [Double] {
        let effects = currentEffects
        return [
            weatherIntensity,                           // Overall intensity
            effects.movementSpeedModifier,              // Movement effects
            effects.visionRangeModifier,                // Vision effects
            effects.energyDrainModifier,                // Energy effects
            effects.foodSpawnRateModifier,              // Food availability
            Double(ticksSinceWeatherChange) / Double(max(maxWeatherDuration, 1)) // Weather progress
        ]
    }
}

/// Record of a weather event
struct WeatherEvent: Identifiable {
    let id = UUID()
    let type: WeatherType
    let startTime: Date
    let estimatedDuration: Int
    let seasonContext: Season
    
    var isActive: Bool {
        let elapsed = Date().timeIntervalSince(startTime)
        return elapsed < Double(estimatedDuration) / 10.0 // Assuming 10 ticks per second
    }
}