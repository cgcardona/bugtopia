# 🌱 Ecosystem Health System

> **Advanced environmental management with resource zones, population dynamics, and ecological cycles that create realistic ecosystem pressure and drive evolutionary adaptation.**

## 🌟 Overview

The Ecosystem Health System manages the long-term health and sustainability of the Bugtopia world through sophisticated resource management, population pressure tracking, and ecological cycles. This system creates realistic environmental challenges that drive evolutionary adaptation and ensures the simulation maintains ecological balance over extended periods.

### ✨ Key Features

- **🌱 Resource Zone Management**: Dynamic resource zones with health, depletion, and regeneration cycles
- **👥 Population Density Tracking**: Real-time population pressure mapping across the world
- **🌍 Global Ecosystem Metrics**: Health indicators, carrying capacity utilization, and stress detection
- **🔄 Ecological Cycles**: Major environmental shifts that reshape resource availability
- **🧠 Neural Integration**: Ecosystem awareness inputs for bug decision-making
- **⚖️ Environmental Balance**: Automatic resource regeneration and population pressure management

## 🏗️ System Architecture

### Core Components

#### ResourceZone
```swift
struct ResourceZone {
    let position: CGPoint
    let radius: Double
    var health: Double        // 0.0 = depleted, 1.0 = fully productive
    var depletion: Double     // 0.0 = pristine, 1.0 = exhausted
    var regenerationRate: Double
    var lastActivityTime: TimeInterval
}
```

#### EcosystemManager
```swift
@Observable
class EcosystemManager {
    private(set) var resourceZones: [ResourceZone] = []
    private var populationDensityGrid: [[Double]] = []
    private(set) var globalResourceHealth: Double = 1.0
    private(set) var averagePopulationPressure: Double = 0.0
    private(set) var carryingCapacityUtilization: Double = 0.0
    private(set) var ecosystemAge: Int = 0
}
```

## 🌱 Resource Zone System

### Zone Characteristics

| Property | Range | Description |
|----------|-------|-------------|
| **Health** | 0.0 - 1.0 | Current productivity (0 = depleted, 1 = fully productive) |
| **Depletion** | 0.0 - 1.0 | Resource exhaustion level (0 = pristine, 1 = exhausted) |
| **Radius** | 40-70 units | Zone coverage area |
| **Regeneration Rate** | 0.001+ | Natural recovery speed per tick |

### Resource Zone Lifecycle

#### 1. **Initialization**
```swift
// Zones created from food terrain tiles
func initializeResourceZones(from arena: Arena) {
    for tile in arena.tiles where tile.terrain == .food {
        let zone = ResourceZone(position: tile.position, radius: 60.0)
        resourceZones.append(zone)
    }
}
```

#### 2. **Harvesting Pressure**
```swift
// Bugs feeding in zone apply pressure
mutating func harvest(intensity: Double = 0.1) {
    depletion = min(1.0, depletion + intensity)
    health = max(0.0, 1.0 - depletion)
}
```

#### 3. **Natural Regeneration**
```swift
// Zones recover over time
mutating func regenerate(deltaTime: TimeInterval) {
    if depletion > 0.0 {
        let regeneration = regenerationRate * deltaTime
        depletion = max(0.0, depletion - regeneration)
        health = min(1.0, 1.0 - depletion)
    }
}
```

### Zone Quality Assessment

| Health Level | Status | Food Spawn Rate | Bug Attraction |
|--------------|--------|-----------------|----------------|
| **0.8 - 1.0** | Excellent | 100% | High |
| **0.6 - 0.8** | Good | 80% | Medium |
| **0.4 - 0.6** | Fair | 60% | Low |
| **0.2 - 0.4** | Poor | 40% | Minimal |
| **0.0 - 0.2** | Depleted | 20% | None |

## 👥 Population Dynamics

### Density Grid System

The ecosystem uses a **20x20 grid** to track population density across the world:

```swift
private var populationDensityGrid: [[Double]] = []
private let gridResolution: Int = 20
```

#### Grid Calculation
```swift
private func updatePopulationDensity(bugs: [Bug]) {
    // Reset grid
    populationDensityGrid = Array(repeating: Array(repeating: 0.0, count: gridResolution), count: gridResolution)
    
    // Count bugs in each cell
    for bug in bugs {
        let gridX = Int(bug.position.x / 800.0 * Double(gridResolution))
        let gridY = Int(bug.position.y / 600.0 * Double(gridResolution))
        populationDensityGrid[gridY][gridX] += 1.0
    }
}
```

### Population Pressure Metrics

| Metric | Description | Impact |
|--------|-------------|---------|
| **Average Population Pressure** | Global density across all grid cells | Affects survival rates |
| **Carrying Capacity Utilization** | Current population vs. base capacity (200) | Determines stress levels |
| **Local Population Pressure** | Density at specific locations | Influences territory quality |

### Pressure Effects

#### High Population Pressure (>1.0)
- **Reduced survival rates** for all bugs
- **Increased competition** for resources
- **Migration triggers** for populations
- **Territory quality degradation**

#### Low Population Pressure (<0.5)
- **Improved survival rates**
- **Abundant resources**
- **Population growth opportunities**
- **Territory expansion potential**

## 🌍 Global Ecosystem Metrics

### Health Indicators

#### Global Resource Health
```swift
private(set) var globalResourceHealth: Double = 1.0
```
- **1.0**: All zones fully productive
- **0.5**: Half of zones depleted
- **0.0**: All zones exhausted

#### Ecosystem Stress Detection
```swift
var isEcosystemStressed: Bool {
    return globalResourceHealth < 0.5 || carryingCapacityUtilization > 1.2
}
```

### Environmental Modifiers

#### Food Spawn Modifier
```swift
var foodSpawnModifier: Double {
    return max(0.1, globalResourceHealth)
}
```
- **1.0**: Normal food spawning
- **0.5**: Reduced food availability
- **0.1**: Minimal food spawning

#### Survival Pressure Modifier
```swift
var survivalPressureModifier: Double {
    if carryingCapacityUtilization > 1.0 {
        return 1.0 + (carryingCapacityUtilization - 1.0) * 0.5
    }
    return 1.0
}
```
- **1.0**: Normal survival pressure
- **1.5**: 50% increased survival difficulty
- **2.0**: Double survival difficulty

## 🔄 Ecological Cycles

### Major Ecological Events

The ecosystem undergoes **major cycles every 50-100 generations** that reshape resource availability:

```swift
private func checkForMajorCycles() {
    let cycleLength = Int.random(in: 50...100)
    if ecosystemAge - lastMajorCycle >= cycleLength {
        triggerMajorEcologicalCycle()
    }
}
```

#### Cycle Effects

| Effect | Probability | Impact |
|--------|-------------|---------|
| **Resource Zone Changes** | 100% | Health ±30%, regeneration rate ±40% |
| **New Zone Creation** | 30% | Adds new resource zone |
| **Zone Removal** | Auto | Removes zones with <10% health |

### Cycle Triggers

#### Natural Cycles
- **Time-based**: Every 50-100 generations
- **Random variation**: Prevents predictable patterns
- **Cumulative effects**: Long-term ecosystem evolution

#### Stress-Induced Cycles
- **High population pressure** (>1.5x capacity)
- **Resource depletion** (<30% global health)
- **Extreme weather events** (disaster interactions)

## 🧠 Neural Network Integration

### Ecosystem Inputs

The ecosystem provides **6 neural inputs** to help bugs make environmentally-aware decisions:

```swift
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
```

### Input Interpretation

| Input | Range | Meaning |
|-------|-------|---------|
| **Global Resource Health** | 0.0-1.0 | Overall resource availability |
| **Population Pressure** | 0.0-1.0 | Local competition intensity |
| **Carrying Capacity** | 0.0-2.0+ | Population density vs. capacity |
| **Ecosystem Stress** | 0.0 or 1.0 | Binary stress indicator |
| **Food Modifier** | 0.1-1.0 | Food availability multiplier |
| **Survival Pressure** | 0.0-1.0+ | Additional survival difficulty |

### Behavioral Responses

#### High Resource Health (>0.7)
- **Increased exploration** for food sources
- **Territory expansion** attempts
- **Reproductive behavior** activation
- **Social cooperation** enhancement

#### Low Resource Health (<0.3)
- **Conservation behavior** activation
- **Migration triggers** for populations
- **Reduced reproduction** rates
- **Competitive aggression** increase

#### High Population Pressure (>1.0)
- **Territory defense** intensification
- **Migration behavior** activation
- **Resource hoarding** strategies
- **Social hierarchy** formation

## 🔧 Configuration

### System Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Base Carrying Capacity** | 200 | Maximum sustainable population |
| **Depletion Threshold** | 0.7 | Resource exhaustion trigger |
| **Regeneration Boost Factor** | 2.0 | Recovery rate multiplier |
| **Grid Resolution** | 20 | Population density tracking precision |
| **Zone Radius Range** | 40-70 | Resource zone size variation |

### Performance Optimization

#### Grid-Based Calculations
- **Efficient density tracking** with 20x20 grid
- **Spatial indexing** for resource zone queries
- **Cached calculations** for frequently accessed metrics

#### Update Frequency
- **Population density**: Every simulation tick
- **Resource zones**: Every simulation tick
- **Global metrics**: Every simulation tick
- **Major cycles**: Every 50-100 generations

## 📊 Monitoring & Analytics

### Real-Time Metrics

#### Resource Health Dashboard
- **Global resource health** percentage
- **Active resource zones** count
- **Average zone health** by region
- **Depletion rates** by zone

#### Population Pressure Map
- **Density heatmap** visualization
- **Pressure hotspots** identification
- **Migration patterns** tracking
- **Territory quality** correlation

### Long-Term Trends

#### Ecosystem Evolution
- **Resource zone lifecycle** tracking
- **Population pressure** trends
- **Carrying capacity** utilization history
- **Major cycle** frequency analysis

#### Adaptation Patterns
- **Bug behavior changes** in response to ecosystem stress
- **Territory quality** evolution
- **Migration frequency** correlation with resource health
- **Survival rate** correlation with ecosystem metrics

## 🎯 Use Cases

### Educational Applications
- **Ecology visualization**: Show resource depletion and regeneration
- **Population dynamics**: Demonstrate carrying capacity effects
- **Environmental cycles**: Illustrate long-term ecosystem changes
- **Adaptation pressure**: Show how environmental stress drives evolution

### Research Applications
- **Ecosystem modeling**: Study resource management systems
- **Population dynamics**: Analyze density-dependent effects
- **Environmental cycles**: Research ecological stability
- **Adaptation patterns**: Study evolutionary responses to environmental change

### Development Applications
- **System testing**: Validate ecosystem balance
- **Performance optimization**: Monitor resource usage
- **Feature development**: Test new environmental mechanics
- **User experience**: Ensure engaging ecosystem dynamics

## 🔮 Future Expansions

### Planned Features
- **Seasonal resource cycles**: Different availability by season
- **Weather resource effects**: Weather impacts on zone health
- **Disaster resource destruction**: Catastrophic events affect zones
- **Species-specific resource preferences**: Different bugs prefer different zones

### Advanced Mechanics
- **Resource competition**: Direct competition between populations
- **Territory resource claims**: Exclusive resource access
- **Resource specialization**: Different zone types for different resources
- **Ecosystem succession**: Long-term environmental evolution

---

**🌱 The Ecosystem Health System creates realistic environmental pressure that drives evolutionary adaptation while maintaining ecological balance and long-term sustainability.** 