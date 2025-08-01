# 🌍 Terrain System Documentation

## Overview

The Terrain System is the foundation of Bugtopia's environmental challenges, providing diverse landscapes that create unique evolutionary pressures. Each terrain type presents specific obstacles and advantages that bugs must adapt to survive and thrive.

## Core Components

### Terrain Types

Bugtopia features **8 distinct terrain types**, each with unique properties and challenges:

| Terrain | Icon | Description | Movement Challenge | Evolutionary Pressure |
|---------|------|-------------|-------------------|---------------------|
| **Open** | ⬛ | Standard terrain with no penalties | None | Baseline fitness |
| **Wall** | 🪨 | Impassable barriers | Complete blockage | Memory & pathfinding |
| **Water** | 🌊 | Requires swimming ability | Speed/efficiency challenge | Aquatic adaptation |
| **Hill** | ⛰️ | Elevated terrain requiring climbing | Strength requirement | Physical power |
| **Shadow** | 🌫️ | Areas with limited visibility | Vision reduction | Enhanced memory |
| **Predator** | 🦁 | Dangerous zones with lurking threats | Survival challenge | Combat or stealth |
| **Wind** | 💨 | Areas with strong air currents | Size-based disruption | Stability traits |
| **Food** | 🌱 | Resource-rich feeding areas | None (bonus) | Exploration skills |

### Terrain Mechanics

#### Movement Modifiers

Each terrain type applies **three key modifiers** to bug behavior:

1. **Speed Multiplier** - How fast bugs can move
2. **Vision Multiplier** - How far bugs can see
3. **Energy Cost Multiplier** - How much energy movement consumes

#### Adaptive Calculations

Terrain effects are **dynamically calculated** based on bug genetics:

```swift
// Example: Water terrain speed calculation
func speedMultiplier(for bug: BugDNA) -> Double {
    let waterAbility = (bug.speed + (2.0 - bug.energyEfficiency)) / 2.0
    let result = waterAbility - 0.5
    return max(0.1, min(1.0, result))
}
```

This creates **emergent specialization** where bugs with different genetic makeups perform differently on the same terrain.

## World Generation System

### Organic World Types

Bugtopia generates **6 distinct world types** for maximum variety:

#### 🏝️ Archipelago
- **Theme**: Island chains in vast oceans
- **Features**: Water dominates, scattered land masses
- **Challenges**: Swimming ability essential, resource scarcity
- **Specialization**: Aquatic adaptation, efficient movement

#### 🏔️ Canyon
- **Theme**: Deep valleys and mesa formations  
- **Features**: Dramatic elevation changes, cliff faces
- **Challenges**: Climbing difficulty, limited pathways
- **Specialization**: Strength, vertical navigation

#### 🌾 Wetlands
- **Theme**: Marshes and waterways
- **Features**: Mixed water/land, rich vegetation
- **Challenges**: Variable terrain, predator zones
- **Specialization**: Adaptability, resource exploitation

#### 🌋 Volcanic
- **Theme**: Harsh volcanic landscape
- **Features**: Hills, dangerous zones, rare resources
- **Challenges**: High energy costs, environmental hazards
- **Specialization**: Resilience, danger navigation

#### 🌾 Plains
- **Theme**: Open grasslands with scattered features
- **Features**: Mostly open terrain, distributed challenges
- **Challenges**: Long-distance travel, resource competition
- **Specialization**: Endurance, exploration

#### 🧩 Maze
- **Theme**: Complex wall systems and corridors
- **Features**: Intricate pathways, hidden resources
- **Challenges**: Navigation complexity, dead ends
- **Specialization**: Memory, spatial intelligence

### Procedural Generation

#### Spatial Noise Algorithm

Terrain generation uses **multi-octave spatial noise** for realistic patterns:

```swift
// Create spatial correlation using multiple noise octaves
let noise1 = spatialNoise(x: x, y: y, scale: 0.1)      // Primary pattern
let noise2 = spatialNoise(x: x, y: y, scale: 0.05) * 0.5   // Large features
let noise3 = spatialNoise(x: x, y: y, scale: 0.2) * 0.25   // Fine details
let combinedNoise = noise1 + noise2 + noise3
```

#### Deterministic Randomness

Each position generates terrain using **position-based seeding**:

```swift
let seed = Int(x * 73856093) ^ Int(y * 19349663) ^ Int(scale * 83492791)
```

This ensures:
- **Spatial correlation** - nearby tiles have similar terrain
- **Reproducibility** - same world generates identically
- **No artificial borders** - terrain flows naturally

#### Spawn Area Management

The system automatically creates **safe spawn zones**:
- **3-6 random spawn areas** distributed across the world
- **Variable clearing radius** (1-2 tiles) for organic shapes
- **80% clearing probability** - occasionally leaves terrain features
- **Guaranteed center spawn** - ensures population survival

## Terrain Effects on Evolution

### Selection Pressures

Different terrains create **specific evolutionary pressures**:

#### Water Terrain → Aquatic Specialists
- **Speed** evolution for faster swimming
- **Energy Efficiency** for reduced swimming costs
- **Size** optimization for hydrodynamic advantage

#### Hill Terrain → Mountain Climbers  
- **Strength** development for climbing ability
- **Size** increase for stability and power
- **Endurance** for sustained elevation changes

#### Shadow Terrain → Memory Masters
- **Memory** enhancement for navigation without vision
- **Curiosity** development for thorough exploration
- **Spatial intelligence** for mental mapping

#### Predator Terrain → Survival Specialists
- **Aggression** for fighting back
- **Camouflage** for stealth avoidance
- **Speed** for quick escapes

### Fitness Calculations

Each terrain type has **specialized fitness functions**:

```swift
func terrainFitness(for terrainType: TerrainType) -> Double {
    switch terrainType {
    case .water:
        return (speed * 0.4 + (2.0 - energyEfficiency) * 0.4 + stickiness * 0.2)
    case .hill:
        return (strength * 0.6 + size * 0.2 + stickiness * 0.2)
    case .shadow:
        return (visionRadius * 0.01 + memory * 0.4 + curiosity * 0.3)
    // ... additional cases
    }
}
```

This drives **terrain specialization** where populations evolve different strategies for different environments.

## Integration with Other Systems

### Environmental Cycles
- **Resource depletion** affects food terrain abundance
- **Ecosystem aging** changes terrain distribution over time
- **Carrying capacity** varies by terrain type

### Weather Effects
- **Rain** makes hills more slippery (reduced climbing)
- **Drought** turns some water terrain into open terrain
- **Fog** reduces vision multipliers across all terrain
- **Blizzard** increases energy costs in exposed areas

### Natural Disasters
- **Floods** convert terrain to temporary water
- **Earthquakes** create new wall formations
- **Wildfires** clear vegetation (food → open)
- **Volcanic eruptions** create new hill/predator terrain

### Territory System
- **Territory quality** calculated based on terrain mix
- **Migration triggers** when terrain becomes unsuitable
- **Population specialization** drives territorial preferences

## Technical Implementation

### Data Structures

#### ArenaTile
```swift
struct ArenaTile {
    let terrain: TerrainType
    let position: CGPoint
    let size: CGSize
}
```

#### Arena Grid
- **Grid-based system** for efficient spatial queries
- **Configurable tile size** (default: 40x40 pixels)
- **Bounds-aware positioning** ensures tiles fit within arena

### Performance Optimizations

#### Spatial Queries
- **O(1) terrain lookup** using grid coordinates
- **Cached tile boundaries** for collision detection
- **Efficient pathfinding** with terrain-aware costs

#### Memory Management
- **Static terrain generation** - created once per simulation
- **Minimal runtime allocation** - reuses existing data structures
- **Efficient rendering** - tiles cached for drawing

## Usage Examples

### Basic Terrain Query
```swift
let terrain = arena.terrainAt(bugPosition)
let speedModifier = terrain.speedMultiplier(for: bug.dna)
let energyCost = terrain.energyCostMultiplier(for: bug.dna)
```

### Movement Calculation
```swift
let currentTerrain = arena.terrainAt(bug.position)
let modifiers = arena.movementModifiers(at: bug.position, for: bug.dna)
let actualSpeed = bug.dna.speed * modifiers.speed
let actualEnergyCost = baseCost * modifiers.energyCost
```

### Fitness Evaluation
```swift
let terrainBonus = bug.dna.terrainFitness(for: currentTerrain) * 5
let totalFitness = baseFitness + terrainBonus
```

## Configuration

### Terrain Distribution
Each world type has **carefully balanced terrain distributions**:
- **60-70% open terrain** for basic movement
- **10-20% challenging terrain** for specialization pressure
- **5-10% resource terrain** for competition
- **5-10% hazard terrain** for survival challenges

### Balancing Parameters
- **Speed multipliers**: 0.1 to 1.2 range
- **Vision multipliers**: 0.3 to 1.3 range  
- **Energy cost multipliers**: 0.5 to 2.0 range
- **Terrain fitness weights**: Optimized for trait importance

## Future Enhancements

### Planned Features
- **Dynamic terrain changes** based on bug activity
- **Seasonal terrain modifications** (frozen water, etc.)
- **Tool-based terrain modification** (bridges, tunnels)
- **3D terrain** with elevation and underground layers

### Research Opportunities
- **Terrain learning** - bugs remember successful routes
- **Collective terrain modification** - populations reshape environment
- **Evolutionary terrain preferences** - genetic terrain biases
- **Multi-scale terrain** - macro and micro environmental features

---

*The Terrain System forms the foundation of environmental challenge in Bugtopia, driving the evolution of specialized survival strategies and creating the diverse ecological niches that make each simulation unique.*