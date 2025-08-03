# 🚀 Transition Type System Documentation

## Overview

The Transition Type System defines **how bugs navigate through the 3D voxel world**, providing sophisticated movement mechanics that enable realistic traversal of complex terrain. This system allows bugs to climb, swim, fly, tunnel, and use constructed paths based on their genetic capabilities and environmental conditions.

## TransitionType Enum

The system features **8 distinct transition types**, each with unique movement mechanics and difficulty parameters:

```swift
enum TransitionType {
    case solid              // Impassable voxel
    case air                // Open space
    case ramp(angle: Double)           // Gradual slope (0.0-1.0)
    case climb(difficulty: Double)     // Vertical climbing (0.0-1.0)
    case swim(depth: Double)          // Water transition (0.0-1.0)
    case tunnel(width: Double)        // Cave passage (0.0-1.0)
    case flight(clearance: Double)    // Aerial movement (0.0-1.0)
    case bridge(stability: Double)    // Constructed connection (0.0-1.0)
}
```

## Transition Type Details

### 🪨 **Solid**
- **Description**: Completely impassable terrain
- **Energy Cost**: ∞ (cannot traverse)
- **Bug Requirements**: None (blocks all movement)
- **Common Locations**: Rock faces, dense terrain, walls
- **Bypass Methods**: Tunneling tools, bridges, alternate routes

### 🌬️ **Air**
- **Description**: Open space allowing free movement
- **Energy Cost**: Base movement cost
- **Bug Requirements**: Standard locomotion
- **Common Locations**: Open areas, clearings, sky
- **Special Properties**: Easiest movement type, no restrictions

### 📐 **Ramp (angle: 0.0-1.0)**
- **Description**: Gradual inclined surfaces
- **Energy Cost**: Base cost × (1.0 + angle × 0.5)
- **Bug Requirements**: Basic climbing ability
- **Angle Scale**:
  - `0.0`: Flat terrain (no extra cost)
  - `0.5`: Moderate slope (25% extra energy)
  - `1.0`: Steep ramp (50% extra energy)
- **Common Locations**: Hills, natural slopes, constructed ramps

### 🧗 **Climb (difficulty: 0.0-1.0)**
- **Description**: Vertical or near-vertical surfaces
- **Energy Cost**: Base cost × (2.0 + difficulty × 3.0)
- **Bug Requirements**: High climbing DNA trait
- **Difficulty Scale**:
  - `0.0`: Easy climb (2× energy)
  - `0.5`: Moderate climb (3.5× energy)
  - `1.0`: Extreme climb (5× energy)
- **Common Locations**: Cliff faces, tree trunks, walls

### 🏊 **Swim (depth: 0.0-1.0)**
- **Description**: Aquatic movement through water
- **Energy Cost**: Base cost × (1.5 + depth × 2.0)
- **Bug Requirements**: Swimming capability, oxygen management
- **Depth Scale**:
  - `0.0`: Shallow water (1.5× energy)
  - `0.5`: Medium depth (2.5× energy)
  - `1.0`: Deep water (3.5× energy)
- **Common Locations**: Rivers, lakes, wetlands, flooded areas

### 🕳️ **Tunnel (width: 0.0-1.0)**
- **Description**: Underground or enclosed passages
- **Energy Cost**: Base cost × (1.2 + (1.0 - width) × 1.5)
- **Bug Requirements**: Tunnel navigation, claustrophobia tolerance
- **Width Scale**:
  - `0.0`: Tight squeeze (2.7× energy)
  - `0.5`: Narrow tunnel (1.95× energy)
  - `1.0`: Wide passage (1.2× energy)
- **Common Locations**: Natural caves, bug-made tunnels, crevices

### 🕊️ **Flight (clearance: 0.0-1.0)**
- **Description**: Aerial movement above ground
- **Energy Cost**: Base cost × (3.0 - clearance × 1.5)
- **Bug Requirements**: Flight capability, energy reserves
- **Clearance Scale**:
  - `0.0`: Obstacle-dense flight (3× energy)
  - `0.5`: Moderate clearance (2.25× energy)
  - `1.0`: Open sky (1.5× energy)
- **Common Locations**: Above trees, over water, open airspace

### 🌉 **Bridge (stability: 0.0-1.0)**
- **Description**: Constructed connections over gaps
- **Energy Cost**: Base cost × (1.1 + (1.0 - stability) × 0.3)
- **Bug Requirements**: Balance, confidence in structures
- **Stability Scale**:
  - `0.0`: Unstable bridge (1.4× energy, risk of collapse)
  - `0.5`: Moderate stability (1.25× energy)
  - `1.0`: Solid bridge (1.1× energy)
- **Common Locations**: Tool-constructed bridges, natural formations

## Movement Mechanics

### Energy Cost Calculation
```
Final Energy Cost = Base Movement Cost × Transition Multiplier × Bug Efficiency
```

### Bug Genetic Factors
- **Climbing Ability**: Affects climb and ramp success rates
- **Swimming Proficiency**: Determines water navigation efficiency
- **Flight Capability**: Enables aerial movement options
- **Tunnel Comfort**: Reduces claustrophobia in enclosed spaces
- **Balance**: Improves performance on unstable surfaces

### Environmental Modifiers
- **Weather Effects**: Rain makes climbing harder, wind affects flight
- **Seasonal Changes**: Ice makes surfaces slippery, drought affects swimming
- **Tool Assistance**: Equipment can improve transition capabilities
- **Group Cooperation**: Multiple bugs can assist with difficult transitions

## Pathfinding Integration

### Route Planning
- **Cost-Benefit Analysis**: Pathfinding weighs energy costs vs. distance
- **Alternative Routes**: System finds multiple path options
- **Dynamic Adaptation**: Real-time route adjustment based on conditions
- **Emergency Pathways**: Backup routes when primary paths fail

### Intelligent Navigation
- **Capability Assessment**: Bugs avoid transitions beyond their abilities
- **Learning**: Experience improves future navigation decisions
- **Social Pathfinding**: Bugs can follow successful routes used by others
- **Tool Integration**: Constructed paths become permanent route options

## Construction System Integration

### Built Transitions
- **Ramps**: Tools can create artificial slopes
- **Bridges**: Spanning gaps and water features
- **Tunnels**: Excavated passages through solid terrain
- **Platforms**: Stable surfaces for complex navigation

### Durability and Maintenance
- **Wear and Tear**: Constructed transitions degrade over time
- **Repair Mechanics**: Bugs can maintain and upgrade structures
- **Environmental Damage**: Weather and disasters affect construction
- **Collaborative Building**: Multiple bugs can work on large projects

## Future Development

### Advanced Features
- **Dynamic Difficulty**: Transitions that change based on environmental conditions
- **Specialized Equipment**: Tools that modify transition capabilities
- **Terrain Modification**: Bugs actively reshaping the environment
- **Adaptive Abilities**: Evolutionary development of new movement types

### Performance Optimizations
- **Transition Caching**: Pre-calculated movement costs for common routes
- **Predictive Pathfinding**: Anticipating optimal routes before movement
- **Parallel Processing**: Multiple navigation calculations simultaneously
- **Memory Optimization**: Efficient storage of transition data

This sophisticated transition system creates realistic and challenging navigation that drives evolutionary pressure toward improved locomotion abilities! 🏔️🌊✈️