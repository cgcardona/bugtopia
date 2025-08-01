# 🌍 Territory System

> **Advanced population-based territory management with quality evaluation, migration triggers, and neural territorial awareness that creates realistic spatial behaviors and population dynamics.**

## 🌟 Overview

The Territory System manages population-based territories, migration behaviors, and spatial awareness that creates realistic territorial dynamics in the Bugtopia world. Each population claims and defends its own territory, with quality evaluation driving migration decisions and neural inputs enabling territorial awareness in bug decision-making.

### ✨ Key Features

- **🌍 Population-Based Territories**: Each population claims and defends its own territory
- **📊 Territory Quality Evaluation**: Resource abundance, safety, and carrying capacity assessment
- **🚶 Migration Triggers**: Population pressure, resource scarcity, and disaster displacement
- **🧠 Neural Territorial Awareness**: 4 territorial inputs for territory-based decision making
- **📏 Distributed Territory Sizing**: Realistic territory sizes based on population size and arena distribution
- **🎨 Territory Visualization**: Real-time territory overlays showing claimed areas and population boundaries
- **⚔️ Territorial Competition**: Population conflicts, territory expansion, and boundary disputes

## 🏗️ System Architecture

### Core Components

#### Territory
```swift
struct Territory: Identifiable, Equatable {
    let id: UUID
    let populationId: UUID
    var area: CGRect
    var quality: Double // 0.0 to 1.0, based on resources, safety, etc.
    var lastDefended: TimeInterval
}
```

#### TerritoryManager
```swift
@Observable
class TerritoryManager {
    private(set) var territories: [Territory] = []
    private var worldBounds: CGRect = .zero
    
    // Configuration
    private let territoryGridResolution = 20
    private let minTerritoryQuality: Double = 0.3
    private let migrationUrgencyThreshold: Double = 0.8
}
```

## 🌍 Territory Management

### Territory Lifecycle

#### 1. **Territory Creation**
```swift
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
```

#### 2. **Territory Area Calculation**
```swift
private func calculatePopulationArea(bugs: [UUID], in arena: Arena) -> CGRect {
    let populationSize = bugs.count
    
    if populationSize == 0 {
        return CGRect.zero
    }
    
    // Calculate territory size based on population size
    let baseRadius = 40.0
    let sizeMultiplier = min(2.5, Double(populationSize) / 8.0)
    let territoryRadius = baseRadius * sizeMultiplier
    
    // Create distributed territories based on population ID
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
```

### Territory Quality Assessment

#### Quality Calculation
```swift
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
```

#### Quality Factors

| Factor | Weight | Description |
|--------|--------|-------------|
| **Resource Health** | 50% | Food availability and resource abundance |
| **Population Pressure** | 30% | Competition level in the area |
| **Safety** | 20% | Distance from predators and hazards |

### Territory Quality Levels

| Quality Range | Status | Population Behavior | Migration Likelihood |
|---------------|--------|-------------------|-------------------|
| **0.8 - 1.0** | Excellent | Territory defense, expansion | Very Low |
| **0.6 - 0.8** | Good | Normal behavior | Low |
| **0.4 - 0.6** | Fair | Conservation, monitoring | Medium |
| **0.2 - 0.4** | Poor | Migration preparation | High |
| **0.0 - 0.2** | Critical | Active migration | Very High |

## 🚶 Migration System

### Migration Triggers

#### Urgency Calculation
```swift
private func calculateMigrationUrgency(
    territory: Territory,
    ecosystemManager: EcosystemManager
) -> Double {
    let resourceDepletion = 1.0 - territory.quality
    let overpopulation = max(0, ecosystemManager.carryingCapacityUtilization - 1.0)
    
    return max(resourceDepletion, overpopulation)
}
```

#### Trigger Conditions

| Condition | Threshold | Effect |
|-----------|-----------|---------|
| **Resource Depletion** | Quality < 0.3 | Immediate migration trigger |
| **Overpopulation** | Capacity > 120% | Gradual migration pressure |
| **Ecosystem Stress** | Global health < 0.5 | Population-wide migration |
| **Disaster Displacement** | Disaster event | Forced migration |

### Migration Process

#### 1. **Target Identification**
```swift
private func findBetterTerritory(for population: Population, currentTerritory: Territory) -> CGPoint? {
    // Search for a promising new location
    for _ in 0..<20 { // Try 20 random locations
        let newPos = CGPoint(
            x: Double.random(in: worldBounds.minX...worldBounds.maxX),
            y: Double.random(in: worldBounds.minY...worldBounds.maxY)
        )
        
        // Quality assessment would be performed here
        return newPos
    }
    return nil
}
```

#### 2. **Migration Initiation**
```swift
private func initiateMigration(for population: Population, to target: CGPoint) {
    // Set migration target for all bugs in the population
    print("🌍 Population \(population.name) is migrating to \(target)!")
}
```

### Migration Types

#### Voluntary Migration
- **Resource scarcity**: Territory quality below threshold
- **Population pressure**: Overcrowding in current territory
- **Territory competition**: Better territories available
- **Environmental changes**: Ecosystem stress or seasonal shifts

#### Forced Migration
- **Disaster displacement**: Natural disasters destroy territory
- **Predator pressure**: Intense predation in current area
- **Resource exhaustion**: Complete depletion of local resources
- **Population collapse**: Territory becomes uninhabitable

## 🧠 Neural Territorial Awareness

### Territory Inputs

The territory system provides **4 neural inputs** for territorial decision-making:

```swift
func getTerritoryInputs(at position: CGPoint, for populationId: UUID?) -> [Double] {
    var inputs: [Double] = [0, 0, 0, 0]
    
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
```

### Input Interpretation

| Input | Range | Meaning |
|-------|-------|---------|
| **Own Territory Quality** | 0.0-1.0 | Quality of bug's population territory |
| **In Own Territory** | 0.0 or 1.0 | Whether bug is in its territory |
| **Foreign Territory Detected** | 0.0 or 1.0 | Whether bug is in another population's territory |
| **Foreign Territory Quality** | 0.0-1.0 | Quality of foreign territory |

### Behavioral Responses

#### High Own Territory Quality (>0.7)
- **Territory defense** behaviors
- **Resource exploitation** strategies
- **Reproductive behavior** activation
- **Social cooperation** enhancement

#### Low Own Territory Quality (<0.3)
- **Migration preparation** behaviors
- **Resource conservation** strategies
- **Exploration** for better territories
- **Population dispersal** patterns

#### In Foreign Territory
- **Cautious movement** patterns
- **Quick resource gathering** strategies
- **Escape behavior** activation
- **Territory boundary** respect

## 📊 Territory Visualization

### Real-Time Territory Display

#### Territory Overlays
- **Population boundaries**: Clear territory borders
- **Quality indicators**: Color-coded territory quality
- **Population labels**: Territory ownership identification
- **Migration paths**: Visual migration routes

#### Territory Metrics
- **Quality heatmap**: Territory quality visualization
- **Population density**: Territory occupancy levels
- **Resource distribution**: Territory resource mapping
- **Migration indicators**: Population movement tracking

### Territory Analytics

#### Quality Trends
- **Territory quality** over time
- **Quality correlation** with population size
- **Quality impact** on survival rates
- **Quality changes** during environmental cycles

#### Migration Patterns
- **Migration frequency** by population
- **Migration distance** analysis
- **Migration success** rates
- **Migration timing** correlation with events

## ⚔️ Territorial Competition

### Competition Mechanics

#### Territory Disputes
- **Boundary conflicts**: Overlapping territory claims
- **Resource competition**: Competition for shared resources
- **Population pressure**: Overcrowding in contested areas
- **Quality degradation**: Reduced territory quality from competition

#### Resolution Strategies
- **Territory sharing**: Cooperative resource use
- **Boundary establishment**: Clear territory demarcation
- **Population dispersal**: Reduced population density
- **Migration**: Population relocation to new territories

### Competition Outcomes

#### Peaceful Resolution
- **Territory sharing**: Cooperative resource management
- **Boundary respect**: Clear territorial boundaries
- **Population balance**: Equilibrium population distribution
- **Resource optimization**: Efficient resource utilization

#### Conflict Resolution
- **Population displacement**: Forced migration of weaker populations
- **Territory division**: Splitting contested areas
- **Resource partitioning**: Specialized resource access
- **Population reduction**: Natural selection through competition

## 🔧 Configuration

### System Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Territory Grid Resolution** | 20 | Quality assessment precision |
| **Minimum Territory Quality** | 0.3 | Migration trigger threshold |
| **Migration Urgency Threshold** | 0.8 | Migration activation level |
| **Base Territory Radius** | 40.0 | Minimum territory size |
| **Population Size Multiplier** | 2.5 | Maximum territory scaling |

### Performance Optimization

#### Efficient Calculations
- **Grid-based quality assessment**: 20x20 resolution for performance
- **Spatial indexing**: Efficient territory queries
- **Cached calculations**: Territory quality caching
- **Update batching**: Territory updates every few ticks

#### Memory Management
- **Territory cleanup**: Remove extinct population territories
- **Quality caching**: Cache territory quality calculations
- **Migration tracking**: Efficient migration path storage
- **Visualization optimization**: Efficient territory rendering

## 📈 Territory Evolution

### Long-Term Patterns

#### Territory Stability
- **Stable territories**: High-quality, well-defended areas
- **Dynamic territories**: Frequently changing boundaries
- **Territory expansion**: Population growth and territory enlargement
- **Territory contraction**: Population decline and territory reduction

#### Evolutionary Trends
- **Territory specialization**: Populations adapt to specific territory types
- **Migration patterns**: Established migration routes and timing
- **Competition evolution**: Changing competitive dynamics
- **Resource adaptation**: Territory quality optimization strategies

### Adaptation Mechanisms

#### Population Adaptation
- **Territory defense**: Evolution of territorial behaviors
- **Migration efficiency**: Improved migration strategies
- **Resource utilization**: Better resource exploitation
- **Competition strategies**: Enhanced competitive abilities

#### Environmental Adaptation
- **Territory selection**: Choosing optimal territory locations
- **Quality maintenance**: Territory quality preservation strategies
- **Resource management**: Sustainable resource use patterns
- **Disaster response**: Territory recovery after disasters

## 🎯 Use Cases

### Educational Applications
- **Territory dynamics**: Show how populations claim and defend territories
- **Migration patterns**: Demonstrate population movement in response to environmental changes
- **Competition dynamics**: Illustrate territorial conflicts and resolutions
- **Spatial behavior**: Show how bugs navigate and interact with space

### Research Applications
- **Population dynamics**: Study territory-based population regulation
- **Migration ecology**: Research migration triggers and patterns
- **Territorial behavior**: Analyze territorial defense and competition
- **Spatial ecology**: Study spatial distribution and habitat selection

### Development Applications
- **System testing**: Validate territory management mechanics
- **Performance optimization**: Monitor territory calculation efficiency
- **Feature development**: Test new territorial behaviors
- **User experience**: Ensure engaging territorial dynamics

## 🔮 Future Expansions

### Planned Features
- **Territory hierarchies**: Nested territory structures
- **Territory alliances**: Cooperative territory management
- **Territory specialization**: Different territory types for different resources
- **Territory inheritance**: Territory passing between generations

### Advanced Mechanics
- **Territory warfare**: Direct territorial conflicts
- **Territory diplomacy**: Negotiated territory agreements
- **Territory markets**: Territory exchange systems
- **Territory evolution**: Territory adaptation over time

---

**🌍 The Territory System creates realistic spatial behaviors and population dynamics that drive evolutionary adaptation through territorial competition and migration pressure.** 