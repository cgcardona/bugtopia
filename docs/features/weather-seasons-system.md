# 🌦️ Weather & Seasons System Documentation

## Overview

The Weather & Seasons System creates **dynamic environmental challenges** that drive evolutionary adaptation in Bugtopia. This dual-layer system combines predictable seasonal cycles with unpredictable weather patterns, creating both long-term strategic pressures and immediate survival challenges that bugs must adapt to survive and thrive.

## Seasonal System

### The Four Seasons

Bugtopia follows a **realistic seasonal cycle** with distinct characteristics and evolutionary pressures:

| Season | Icon | Duration | Key Characteristics | Evolutionary Pressure |
|--------|------|----------|-------------------|---------------------|
| **🌱 Spring** | Green | 1,500 ticks | Growth, renewal, breeding | Reproduction optimization |
| **☀️ Summer** | Yellow | 2,000 ticks | Peak activity, abundance | Competition, territory |
| **🍂 Fall** | Orange | 1,200 ticks | Preparation, resource gathering | Efficiency, hoarding |
| **❄️ Winter** | Cyan | 800 ticks | Harsh survival conditions | Energy conservation |

### Seasonal Effects

#### Food Availability
```swift
var foodAbundance: Double {
    switch self {
    case .spring: return 1.4   // 40% more food
    case .summer: return 1.6   // 60% more food (peak)
    case .fall: return 1.0     // Normal food levels
    case .winter: return 0.3   // 70% less food (scarcity)
    }
}
```

#### Reproduction Rates
```swift
var reproductionModifier: Double {
    switch self {
    case .spring: return 1.3   // 30% easier reproduction
    case .summer: return 1.5   // 50% easier (optimal)
    case .fall: return 0.8     // 20% harder
    case .winter: return 0.4   // 60% harder (survival mode)
    }
}
```

#### Energy Requirements
```swift
var energyDrainModifier: Double {
    switch self {
    case .spring: return 0.9   // 10% less energy needed
    case .summer: return 0.8   // 20% less energy (efficient)
    case .fall: return 1.0     // Normal energy needs
    case .winter: return 1.4   // 40% more energy (cold)
    }
}
```

#### Movement & Construction
```swift
var movementModifier: Double {
    switch self {
    case .spring: return 1.1   // 10% faster movement
    case .summer: return 1.0   // Normal speed
    case .fall: return 0.95    // 5% slower
    case .winter: return 0.7   // 30% slower (snow/ice)
    }
}

var constructionModifier: Double {
    switch self {
    case .spring: return 1.2   // 20% faster building
    case .summer: return 1.3   // 30% faster (optimal)
    case .fall: return 1.1     // 10% faster
    case .winter: return 0.6   // 40% slower (harsh conditions)
    }
}
```

### Seasonal Progression

#### Automatic Cycling
```swift
class SeasonalManager {
    var currentSeason: Season = .spring
    var seasonalTicks: Int = 0
    var yearCount: Int = 0
    
    func update() {
        seasonalTicks += 1
        
        if seasonalTicks >= currentSeason.duration {
            advanceToNextSeason()
        }
    }
}
```

#### Season Transitions
- **Spring → Summer**: Abundance increases, breeding peaks
- **Summer → Fall**: Preparation mode, resource hoarding
- **Fall → Winter**: Survival mode, energy conservation
- **Winter → Spring**: Recovery, new growth cycle

### Neural Network Integration

#### Seasonal Awareness (8 inputs)
```swift
var seasonalInputs: [Double] {
    // One-hot encoding for current season
    return Season.allCases.map { season in
        season == currentSeason ? 1.0 : 0.0
    }
    // Returns: [spring, summer, fall, winter] with current = 1.0
}

// Additional seasonal inputs
let seasonProgress = Double(seasonalTicks) / Double(currentSeason.duration)  // 0.0-1.0
let foodAbundance = currentSeason.foodAbundance                              // Environmental pressure
let energyDrainModifier = currentSeason.energyDrainModifier                 // Energy requirements
let reproductionModifier = currentSeason.reproductionModifier               // Breeding opportunity
```

### Seasonal Behaviors

#### Breeding Season Detection
```swift
var isBreedingSeason: Bool {
    return currentSeason.reproductionModifier > 1.0  // Spring & Summer
}
```

#### Resource Hoarding
```swift
var isHoardingSeason: Bool {
    return currentSeason == .fall || ticksUntilNextSeason < 200
}
```

#### Shelter Seeking
```swift
var isShelterSeason: Bool {
    return currentSeason == .winter
}
```

#### Expansion Activities
```swift
var isExpansionSeason: Bool {
    return currentSeason == .spring || currentSeason == .summer
}
```

## Weather System

### Weather Types

Bugtopia features **6 distinct weather patterns** with varying intensities and effects:

| Weather | Icon | Intensity | Duration | Primary Effects |
|---------|------|-----------|----------|-----------------|
| **☀️ Clear** | Yellow | 0.0 | 800 ticks | Optimal conditions |
| **🌧️ Rain** | Blue | 0.4 | 300 ticks | Movement/vision reduction |
| **🏜️ Drought** | Orange | 0.7 | 600 ticks | Food scarcity, heat damage |
| **❄️ Blizzard** | White | 0.9 | 200 ticks | Severe movement penalty, cold |
| **⛈️ Storm** | Purple | 1.0 | 150 ticks | Maximum disruption |
| **🌫️ Fog** | Gray | 0.3 | 250 ticks | Vision impairment |

### Weather Effects

#### Movement & Mobility
```swift
struct WeatherEffects {
    let movementSpeedModifier: Double    // Speed multiplier
    let energyDrainModifier: Double      // Energy cost increase
    let visionRangeModifier: Double      // Vision reduction
}

// Example: Storm effects
WeatherEffects(
    movementSpeedModifier: 0.4,  // 60% slower movement
    energyDrainModifier: 1.8,    // 80% more energy drain
    visionRangeModifier: 0.3     // 70% vision reduction
)
```

#### Environmental Impact
```swift
let foodSpawnRateModifier: Double    // Food availability change
let constructionSpeedModifier: Double // Building speed change
let resourceGatheringModifier: Double // Resource collection change

// Example: Drought effects
foodSpawnRateModifier: 0.2      // 80% less food spawning
constructionSpeedModifier: 0.7  // 30% slower construction
resourceGatheringModifier: 0.5  // 50% slower resource gathering
```

#### Survival Challenges
```swift
let coldDamage: Double     // Energy loss from cold exposure
let heatDamage: Double     // Energy loss from heat exposure
let wetnessPenalty: Double // Movement penalty from wet conditions

// Example: Blizzard damage
coldDamage: 2.0           // 2 energy loss per tick
heatDamage: 0.0           // No heat damage
wetnessPenalty: 0.8       // 80% movement penalty
```

### Dynamic Weather Changes

#### Weather Transitions
```swift
class WeatherManager {
    var currentWeather: WeatherType = .clear
    var weatherIntensity: Double = 0.0
    var ticksSinceWeatherChange: Int = 0
    
    func update() {
        ticksSinceWeatherChange += 1
        
        // Check for weather change
        if shouldChangeWeather() {
            transitionToNewWeather()
        }
        
        // Update intensity (can vary within weather type)
        updateWeatherIntensity()
    }
}
```

#### Weather Probability System
- **Clear Weather**: 40% probability (most common)
- **Rain**: 25% probability (moderate frequency)
- **Fog**: 15% probability (occasional)
- **Drought**: 10% probability (seasonal preference)
- **Storm**: 7% probability (dramatic but rare)
- **Blizzard**: 3% probability (rare, winter-biased)

#### Seasonal Weather Bias
```swift
// Weather probability modified by season
func weatherProbability(for weather: WeatherType, in season: Season) -> Double {
    switch (weather, season) {
    case (.blizzard, .winter): return baseProbability * 3.0  // 3x more likely
    case (.drought, .summer): return baseProbability * 2.5   // 2.5x more likely
    case (.rain, .spring): return baseProbability * 1.8     // 1.8x more likely
    case (.fog, .fall): return baseProbability * 1.5        // 1.5x more likely
    default: return baseProbability
    }
}
```

### Neural Network Integration

#### Weather Awareness (6 inputs)
```swift
var weatherInputs: [Double] {
    let effects = currentEffects
    return [
        weatherIntensity,                    // Overall weather severity (0-1)
        effects.movementSpeedModifier,       // Movement capability (0-1)
        effects.visionRangeModifier,         // Vision capability (0-1)
        effects.energyDrainModifier,         // Energy requirements (1+)
        effects.foodSpawnRateModifier,       // Food availability (0-2)
        weatherProgress                      // Weather duration progress (0-1)
    ]
}
```

## Combined System Effects

### Seasonal-Weather Interactions

#### Amplified Effects
```swift
// Winter + Blizzard = Extreme survival challenge
let combinedEnergyDrain = season.energyDrainModifier * weather.energyDrainModifier
// Winter (1.4x) + Blizzard (1.8x) = 2.52x energy drain

// Summer + Drought = Resource scarcity despite good season
let combinedFoodAvailability = season.foodAbundance * weather.foodSpawnRateModifier
// Summer (1.6x) + Drought (0.2x) = 0.32x food availability
```

#### Seasonal Weather Events
```swift
enum SeasonalEvent: String, CaseIterable {
    case springFlood = "spring_flood"      // 15% chance, 300 ticks
    case summerDrought = "summer_drought"  // 20% chance, 500 ticks
    case fallMigration = "fall_migration"  // 25% chance, 100 ticks
    case winterBlizzard = "winter_blizzard" // 30% chance, 400 ticks
}
```

### Evolutionary Pressures

#### Short-term Adaptations (Weather)
- **Storm Survival**: Enhanced energy efficiency and shelter-seeking
- **Drought Resistance**: Water conservation and heat tolerance
- **Cold Adaptation**: Insulation and metabolic efficiency
- **Vision Optimization**: Enhanced sensors for fog/rain conditions

#### Long-term Adaptations (Seasons)
- **Breeding Timing**: Reproduction synchronized with favorable seasons
- **Energy Storage**: Fat reserves for winter survival
- **Migration Patterns**: Movement to better seasonal territories
- **Resource Hoarding**: Collection and storage behaviors

## Behavioral Adaptations

### Weather-Responsive Behaviors

#### Storm Response
```swift
if currentWeather == .storm && weatherIntensity > 0.7 {
    // Seek shelter behavior
    prioritizeShelter = true
    reduceMovement = true
    conserveEnergy = true
}
```

#### Drought Response
```swift
if currentWeather == .drought {
    // Water and food conservation
    increaseFoodSearchRadius = true
    reduceEnergyExpenditure = true
    prioritizeShade = true
}
```

#### Cold Weather Response
```swift
if currentWeather == .blizzard || (currentWeather.coldDamage > 0) {
    // Cold adaptation behaviors
    seekWarmTerrain = true
    increaseMetabolicRate = true
    groupForWarmth = true
}
```

### Seasonal Behavioral Patterns

#### Spring Behaviors
- **Increased Exploration**: Take advantage of good weather
- **Breeding Focus**: Prioritize reproduction during optimal season
- **Territory Expansion**: Claim new areas during growth season
- **Social Activity**: Enhanced communication and cooperation

#### Summer Behaviors
- **Peak Activity**: Maximum movement and construction
- **Resource Gathering**: Build reserves for harder seasons
- **Territorial Defense**: Protect valuable summer territories
- **Breeding Continuation**: Extended reproductive period

#### Fall Behaviors
- **Resource Hoarding**: Prepare for winter scarcity
- **Efficiency Focus**: Optimize energy usage
- **Migration Preparation**: Move to winter-suitable areas
- **Social Coordination**: Group formation for winter survival

#### Winter Behaviors
- **Survival Mode**: Minimize energy expenditure
- **Shelter Seeking**: Prioritize protected areas
- **Group Huddling**: Social warmth and protection
- **Resource Conservation**: Careful use of stored resources

## Environmental Integration

### Terrain Interactions

#### Weather-Terrain Combinations
```swift
// Water terrain + Rain = Flooding effects
if terrain == .water && weather == .rain {
    movementPenalty *= 1.5
    energyCost *= 1.3
}

// Hill terrain + Blizzard = Extreme cold exposure
if terrain == .hill && weather == .blizzard {
    coldDamage *= 1.8
    visionReduction *= 1.4
}

// Open terrain + Drought = Heat exposure
if terrain == .open && weather == .drought {
    heatDamage *= 1.6
    foodScarcity *= 1.3
}
```

#### Seasonal Terrain Changes
```swift
// Winter terrain modifications
if currentSeason == .winter {
    waterTerrain.freezeChance = 0.6     // 60% chance to freeze
    hillTerrain.snowCover = true        // Snow reduces movement
    openTerrain.frozenGround = true     // Harder resource gathering
}
```

### Ecosystem Interactions

#### Food System Integration
```swift
// Combined seasonal and weather effects on food
let finalFoodSpawnRate = baseFoodSpawnRate * 
                        seasonalManager.currentSeason.foodAbundance * 
                        weatherManager.currentEffects.foodSpawnRateModifier

// Example: Winter + Drought
// Base (1.0) * Winter (0.3) * Drought (0.2) = 0.06x food spawning
```

#### Population Dynamics
```swift
// Environmental pressure affects population
let environmentalPressure = (2.0 - season.foodAbundance) * weather.intensity
let populationStress = environmentalPressure * populationDensity

// High stress = increased competition, lower reproduction
if populationStress > 1.5 {
    reproductionThreshold *= 1.4
    aggressionModifier *= 1.3
}
```

## Performance & Balance

### System Parameters

#### Seasonal Timing
```swift
// Season durations (total cycle = 5,500 ticks)
let springDuration = 1500    // 27% of year
let summerDuration = 2000    // 36% of year (longest)
let fallDuration = 1200      // 22% of year
let winterDuration = 800     // 15% of year (shortest, harshest)
```

#### Weather Frequency
```swift
// Weather change probability per tick
let baseWeatherChangeChance = 0.002  // 0.2% per tick
let minWeatherDuration = 50          // Minimum 50 ticks
let maxWeatherDuration = 1000        // Maximum 1000 ticks
```

#### Effect Intensities
```swift
// Maximum effect ranges
let maxMovementReduction = 0.6       // 60% slower maximum
let maxVisionReduction = 0.7         // 70% vision loss maximum
let maxEnergyIncrease = 2.0          // 200% energy drain maximum
let maxFoodReduction = 0.8           // 80% food reduction maximum
```

### Balancing Mechanisms

#### Compensation Systems
```swift
// Good weather compensates for bad seasons
if season == .winter && weather == .clear {
    energyDrainModifier *= 0.8       // 20% energy bonus
    movementModifier *= 1.2          // 20% speed bonus
}

// Bad weather less likely during bad seasons
if season == .winter {
    stormProbability *= 0.3          // 70% less storm chance
    droughtProbability *= 0.1        // 90% less drought chance
}
```

#### Adaptation Incentives
```swift
// Reward environmental adaptation
let adaptationBonus = calculateEnvironmentalAdaptation(bug)
let survivalBonus = 1.0 + (adaptationBonus * 0.3)

// Well-adapted bugs get survival advantages
energyEfficiency *= survivalBonus
reproductionSuccess *= survivalBonus
```

## Evolutionary Outcomes

### Weather Adaptations

#### Storm Specialists
- **Enhanced Energy Efficiency**: Lower baseline energy consumption
- **Improved Shelter Detection**: Better at finding protected areas
- **Storm Prediction**: Neural networks learn to anticipate weather changes
- **Group Coordination**: Enhanced social behaviors for storm survival

#### Drought Survivors
- **Heat Tolerance**: Reduced heat damage from genetic adaptation
- **Water Conservation**: More efficient metabolism
- **Extended Foraging**: Larger search radius for food
- **Resource Storage**: Behavioral hoarding of food resources

#### Cold Adapted
- **Insulation**: Genetic traits that reduce cold damage
- **Metabolic Efficiency**: Better energy usage in cold conditions
- **Group Warmth**: Social clustering behaviors
- **Winter Activity**: Ability to remain active in harsh conditions

### Seasonal Specialists

#### Spring Breeders
- **Optimal Timing**: Reproduction synchronized with resource abundance
- **Territory Claiming**: Aggressive expansion during growth season
- **Rapid Development**: Fast maturation to exploit seasonal windows
- **Social Coordination**: Enhanced breeding cooperation

#### Summer Maximizers
- **Peak Performance**: Maximum activity during optimal conditions
- **Resource Accumulation**: Efficient gathering during abundance
- **Territorial Defense**: Strong protection of valuable summer areas
- **Construction Focus**: Building and tool use optimization

#### Fall Preparers
- **Hoarding Behavior**: Resource collection and storage
- **Migration Timing**: Movement to winter-suitable territories
- **Efficiency Focus**: Optimized energy usage patterns
- **Social Organization**: Group formation for winter survival

#### Winter Survivors
- **Extreme Efficiency**: Minimal energy expenditure
- **Shelter Expertise**: Advanced hiding and protection behaviors
- **Group Survival**: Cooperative warmth and resource sharing
- **Emergency Reserves**: Genetic and behavioral energy storage

## Configuration & Tuning

### Seasonal Parameters
```swift
// Seasonal effect ranges
let foodAbundanceRange = 0.3...1.6    // Winter scarcity to summer abundance
let reproductionRange = 0.4...1.5     // Winter difficulty to summer ease
let energyDrainRange = 0.8...1.4      // Summer efficiency to winter cost
let movementRange = 0.7...1.1         // Winter slowdown to spring boost
let constructionRange = 0.6...1.3     // Winter difficulty to summer optimal
```

### Weather Parameters
```swift
// Weather effect ranges
let movementSpeedRange = 0.4...1.0    // Storm slowdown to clear optimal
let energyDrainRange = 1.0...1.8      // Clear normal to storm extreme
let visionRange = 0.3...1.0           // Storm blindness to clear optimal
let foodSpawnRange = 0.2...1.4        // Drought scarcity to rain abundance
```

### Balance Targets
```swift
// Desired survival rates by season
let springSurvivalTarget = 0.85       // 85% survival (growth season)
let summerSurvivalTarget = 0.90       // 90% survival (optimal season)
let fallSurvivalTarget = 0.75         // 75% survival (preparation)
let winterSurvivalTarget = 0.60       // 60% survival (harsh season)
```

## Future Enhancements

### Planned Features
- **Climate Change**: Long-term environmental shifts
- **Extreme Weather**: Rare but devastating weather events
- **Micro-Climates**: Terrain-specific weather variations
- **Weather Prediction**: Advanced AI weather forecasting

### Research Applications
- **Climate Adaptation**: Study of species response to environmental change
- **Behavioral Ecology**: Seasonal and weather-driven behavior patterns
- **Population Dynamics**: Environmental effects on population cycles
- **Evolutionary Biology**: Adaptation to cyclical and stochastic environments

---

*The Weather & Seasons System creates a rich, dynamic environment that challenges bugs to adapt both to predictable seasonal cycles and unpredictable weather events, driving the evolution of sophisticated survival strategies and behavioral patterns.*