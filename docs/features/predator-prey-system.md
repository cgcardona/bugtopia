# 🦁 Predator-Prey System Documentation

## Overview

The Predator-Prey System forms the heart of Bugtopia's ecological dynamics, creating intense evolutionary pressures through species interactions. This system implements realistic hunting and defensive behaviors, energy transfer mechanics, and sophisticated AI-driven decision making that drives rapid evolution and specialization.

## Species Classifications

### Core Species Types

Bugtopia features **4 distinct ecological niches**, each with unique behaviors and evolutionary pressures:

| Species | Icon | Primary Food | Hunting Ability | Evolutionary Focus |
|---------|------|--------------|-----------------|-------------------|
| **🌱 Herbivore** | Green | Plants only | Cannot hunt | Defense, efficiency, foraging |
| **🦁 Carnivore** | Red | Prey only | Active hunter | Hunting skills, stealth, speed |
| **🐻 Omnivore** | Orange | Mixed diet | Can hunt | Versatility, adaptability |
| **🦅 Scavenger** | Purple | Carrion/plants | Cannot hunt | Opportunism, survival |

### Species Characteristics

```swift
enum SpeciesType: String, CaseIterable {
    case herbivore, carnivore, omnivore, scavenger
    
    var canHunt: Bool {
        switch self {
        case .herbivore, .scavenger: return false
        case .carnivore, .omnivore: return true
        }
    }
    
    var canEatPlants: Bool {
        switch self {
        case .herbivore, .omnivore, .scavenger: return true
        case .carnivore: return false
        }
    }
}
```

## Hunting Mechanics

### Hunting Behavior System

Predators (carnivores and omnivores) possess **evolvable hunting traits** that determine their effectiveness:

```swift
struct HuntingBehavior: Codable {
    let huntingIntensity: Double      // Aggression level (0.0-1.0)
    let preyDetectionRange: Double    // Detection distance (20-150 units)
    let chaseSpeedMultiplier: Double  // Speed boost when hunting (1.0-3.0)
    let huntingEnergyCost: Double     // Energy cost per attempt (0.5-5.0)
    let stealthLevel: Double          // Stealth ability (0.0-1.0)
    let packCoordination: Double      // Group hunting skill (0.0-1.0)
}
```

### Hunting Process

#### 1. Prey Detection
```swift
// Neural network identifies potential prey
let potentialPrey = otherBugs.filter { other in
    other.id != self.id &&
    other.dna.speciesTraits.speciesType != self.dna.speciesTraits.speciesType &&
    distance(to: other.position) < huntingBehavior.preyDetectionRange
}
```

#### 2. Target Selection
- **Nearest Target**: Closest prey within detection range
- **Species Compatibility**: Different species can hunt each other
- **Neural Decision**: AI decides whether to engage based on:
  - Energy levels
  - Prey size and strength
  - Environmental conditions
  - Risk assessment

#### 3. Chase Mechanics
```swift
// Enhanced speed during chase
let chaseSpeedMultiplier = huntingBehavior.chaseSpeedMultiplier // 1.2x typical
let huntVelocity = CGPoint(
    x: huntDirection.x * terrainSpeed * chaseSpeedMultiplier,
    y: huntDirection.y * terrainSpeed * chaseSpeedMultiplier
)

// Blend hunting with neural decisions (70% hunting, 30% AI)
finalVelocity = CGPoint(
    x: huntVelocity.x * 0.7 + neuralVelocity.x * 0.3,
    y: huntVelocity.y * 0.7 + neuralVelocity.y * 0.3
)
```

#### 4. Hunt Success Calculation
```swift
func calculateHuntSuccess(prey: Bug, huntingBehavior: HuntingBehavior) -> Double {
    let sizeAdvantage = (predator.size / prey.size) * 0.3        // 30% weight
    let speedAdvantage = (predator.speed / prey.speed) * 0.2     // 20% weight
    let stealthBonus = huntingBehavior.stealthLevel * 0.2        // 20% weight
    let preyDefense = prey.defensiveBehavior.counterAttackSkill  // Penalty
    let preyCamouflage = prey.camouflage * 0.15                  // Penalty
    
    let baseSuccess = huntingBehavior.huntingIntensity * 0.4     // 40% base
    let totalSuccess = baseSuccess + sizeAdvantage + speedAdvantage + stealthBonus - preyDefense - preyCamouflage
    
    return max(0.05, min(0.95, totalSuccess)) // 5-95% success range
}
```

### Hunt Outcomes

#### Successful Hunt
```swift
if huntSuccess {
    // Energy transfer (conservation of energy)
    let energyGained = min(speciesTraits.huntEnergyGain, 50.0)
    let actualTransfer = min(energyGained, prey.energy)
    
    predator.energy += actualTransfer
    prey.energy -= actualTransfer  // Exact conservation
    
    predator.huntingCooldown = huntingCooldownTime
}
```

#### Failed Hunt
```swift
else {
    // Energy cost for failed attempt
    predator.energy -= min(huntingBehavior.huntingEnergyCost, 10.0)
    predator.huntingCooldown = huntingCooldownTime / 2
}
```

## Defensive Mechanics

### Defensive Behavior System

All species possess **evolvable defensive traits** for survival:

```swift
struct DefensiveBehavior: Codable {
    let predatorDetection: Double     // Detection ability (0.0-1.0)
    let fleeSpeedMultiplier: Double   // Escape speed boost (1.0-3.0)
    let fleeDistance: Double          // Safe distance maintenance (30-200 units)
    let fleeEnergyCost: Double        // Energy cost of fleeing (0.5-4.0)
    let hidingSkill: Double           // Camouflage/hiding ability (0.0-1.0)
    let flockingTendency: Double      // Group safety behavior (0.0-1.0)
    let counterAttackSkill: Double    // Fighting back ability (0.0-1.0)
}
```

### Defensive Process

#### 1. Threat Detection
```swift
// Neural network identifies threats
if decision.fleeing > 0.6 {
    let potentialPredators = otherBugs.filter { other in
        other.id != self.id &&
        other.canHunt &&
        other.speciesType != self.speciesType &&
        distance(to: other.position) < (defensiveBehavior.predatorDetection * 100)
    }
    
    predatorThreat = potentialPredators.min(by: { distance(to: $0.position) < distance(to: $1.position) })
}
```

#### 2. Flee Response
```swift
// Enhanced speed during escape
if let threat = predatorThreat, decision.fleeing > 0.5 {
    let fleeDirection = normalize(CGPoint(
        x: position.x - threat.position.x,
        y: position.y - threat.position.y
    ))
    
    let fleeSpeedMultiplier = defensiveBehavior.fleeSpeedMultiplier // 1.3x typical
    let fleeVelocity = CGPoint(
        x: fleeDirection.x * finalSpeed * fleeSpeedMultiplier,
        y: fleeDirection.y * finalSpeed * fleeSpeedMultiplier
    )
    
    // Energy cost for panic response
    energy -= defensiveBehavior.fleeEnergyCost
}
```

#### 3. Hiding and Camouflage
- **Hiding Skill**: Reduces detection probability
- **Camouflage**: Works with genetic camouflage trait
- **Environmental Use**: Terrain-based hiding strategies

#### 4. Counter-Attack
- **Last Resort**: When cornered or caught
- **Damage Potential**: Can injure or deter predators
- **Energy Cost**: High energy expenditure
- **Success Rate**: Based on size, strength, and skill

## Neural Network Integration

### Predator Neural Inputs

Hunting behavior is controlled by **neural network decisions** with specialized inputs:

#### Prey Detection Inputs (3 neurons)
```swift
// Distance to nearest prey (0-1, normalized by arena size)
inputs.append(min(1.0, distance / maxDistance))

// Prey direction vector (X, Y normalized -1 to 1)
let dx = (nearestPrey.x - position.x) / maxDistance
let dy = (nearestPrey.y - position.y) / maxDistance
inputs.append(max(-1.0, min(1.0, dx)))
inputs.append(max(-1.0, min(1.0, dy)))
```

#### Environmental Context
- **Energy levels**: Current energy affects hunting decisions
- **Terrain conditions**: Hunting effectiveness varies by terrain
- **Seasonal factors**: Food availability affects hunting urgency
- **Population density**: More prey increases hunting opportunity

### Prey Neural Inputs

Defensive behavior uses **threat assessment inputs**:

#### Predator Detection Inputs (3 neurons)
```swift
// Distance to nearest predator (0-1, normalized)
inputs.append(min(1.0, distance / maxDistance))

// Predator direction vector (X, Y normalized -1 to 1)
let dx = (nearestPredator.x - position.x) / maxDistance
let dy = (nearestPredator.y - position.y) / maxDistance
inputs.append(max(-1.0, min(1.0, dx)))
inputs.append(max(-1.0, min(1.0, dy)))
```

### Neural Outputs

#### Predator Outputs
```swift
struct BugOutputs {
    let hunting: Double      // Hunting behavior intensity (0-1)
    let aggression: Double   // Combat aggressiveness (0-1)
    let moveX: Double        // Movement direction X (-1 to 1)
    let moveY: Double        // Movement direction Y (-1 to 1)
    // ... other behaviors
}
```

#### Prey Outputs
```swift
struct BugOutputs {
    let fleeing: Double      // Escape behavior intensity (0-1)
    let social: Double       // Flocking/grouping behavior (0-1)
    let exploration: Double  // Risk vs safety trade-off (0-1)
    let moveX: Double        // Escape direction X (-1 to 1)
    let moveY: Double        // Escape direction Y (-1 to 1)
    // ... other behaviors
}
```

## Behavioral Priorities

### Decision Hierarchy

Bugs follow a **strict priority system** for behavioral decisions:

```swift
// 1. FLEEING - Highest priority (survival)
if let threat = predatorThreat, decision.fleeing > 0.5 {
    // Override all other behaviors for escape
}
// 2. HUNTING - Second priority (carnivores/omnivores)
else if let prey = targetPrey, decision.hunting > 0.5, canHunt {
    // Active predation behavior
}
// 3. FOOD SEEKING - Third priority (all species)
else if let target = targetFood, decision.exploration < 0.7 {
    // Foraging for plant food
}
// 4. EXPLORATION - Lowest priority
else {
    // Random movement and exploration
}
```

### Behavioral Blending

Some behaviors can **blend together**:

- **Hunting + Neural Movement**: 70% hunting direction, 30% AI decision
- **Fleeing + Terrain Avoidance**: Escape while avoiding obstacles
- **Social + Defensive**: Group formation during threat response
- **Exploration + Caution**: Balanced risk-taking behavior

## Energy Economics

### Energy Transfer System

The predator-prey system implements **strict energy conservation**:

#### Hunt Energy Gain
```swift
// Predator energy gain from successful hunt
let energyGained = min(speciesTraits.huntEnergyGain, 50.0)  // Capped at 50
let actualTransfer = min(energyGained, prey.energy)        // Can't exceed prey energy

predator.energy += actualTransfer
prey.energy -= actualTransfer  // Exact conservation - no energy creation
```

#### Energy Costs
- **Hunting Attempts**: 1.0-3.0 energy per attempt
- **Chase Behavior**: Speed boost costs extra energy
- **Failed Hunts**: Energy loss without gain
- **Flee Response**: 1.5 energy for panic response
- **Counter-Attacks**: High energy defensive actions

### Metabolic Differences

Different species have **distinct energy profiles**:

#### Carnivores
- **High Energy Gain**: Successful hunts provide substantial energy
- **High Risk**: Failed hunts are costly
- **Feast or Famine**: Irregular but large energy inputs
- **Specialized**: Optimized for hunting efficiency

#### Herbivores
- **Steady Energy**: Consistent plant-based energy
- **Lower Risk**: Plants don't fight back
- **Energy Efficiency**: Optimized for low-cost survival
- **Defensive Focus**: Energy invested in escape mechanisms

#### Omnivores
- **Flexible Strategy**: Can switch between hunting and foraging
- **Balanced Risk**: Medium risk, medium reward
- **Adaptability**: Responds to environmental conditions
- **Generalist**: Jack-of-all-trades approach

#### Scavengers
- **Opportunistic**: Low-risk, low-reward strategy
- **Patience**: Wait for opportunities
- **Efficiency**: Minimal energy expenditure
- **Survival**: Outlast other species through efficiency

## Evolutionary Pressures

### Arms Race Dynamics

The predator-prey system creates **continuous evolutionary pressure**:

#### Predator Evolution
- **Enhanced Detection**: Better prey-finding abilities
- **Improved Speed**: Faster chase capabilities
- **Stealth Development**: Harder to detect approaches
- **Hunting Efficiency**: Lower energy cost per hunt
- **Size Advantages**: Larger size for hunt success

#### Prey Evolution
- **Enhanced Vigilance**: Better predator detection
- **Escape Speed**: Faster flee responses
- **Camouflage**: Harder to detect when hiding
- **Group Behavior**: Safety in numbers
- **Counter-Attack**: Fighting back when cornered

### Specialization Trends

Over many generations, species tend to **specialize**:

#### Apex Predators
- Large size and high strength
- Excellent stealth and hunting skills
- High energy efficiency in hunting
- Dominant territorial behavior
- Advanced neural networks for strategy

#### Evasion Specialists
- High speed and agility
- Excellent predator detection
- Energy-efficient fleeing
- Strong flocking tendencies
- Camouflage optimization

#### Balanced Omnivores
- Moderate hunting and defensive skills
- Flexible behavioral repertoires
- Adaptive neural networks
- Environmental responsiveness
- Survival generalists

## Advanced Behaviors

### Pack Hunting

Some predators develop **coordinated hunting** behaviors:

```swift
let packCoordination: Double  // 0.0-1.0 coordination ability
```

- **Group Formation**: Predators coordinate positions
- **Herding**: Drive prey toward other predators
- **Ambush Tactics**: Coordinated surprise attacks
- **Energy Sharing**: Distribute hunt costs among group

### Flocking Defense

Prey species develop **group defensive** strategies:

```swift
let flockingTendency: Double  // 0.0-1.0 grouping behavior
```

- **Safety in Numbers**: Reduced individual predation risk
- **Early Warning**: Group vigilance for threat detection
- **Confusion Effect**: Harder for predators to target individuals
- **Collective Escape**: Coordinated flee responses

### Territorial Behavior

Both predators and prey can develop **territorial strategies**:

- **Hunting Grounds**: Predators claim resource-rich areas
- **Safe Zones**: Prey establish predator-free territories
- **Border Patrol**: Defend territory boundaries
- **Resource Control**: Monopolize food sources

## Environmental Interactions

### Terrain Effects

Different terrains affect **predator-prey dynamics**:

#### Open Terrain
- **Predator Advantage**: Clear sight lines for hunting
- **High-Speed Chases**: Open space for pursuit
- **No Hiding**: Limited camouflage opportunities
- **Energy Efficiency**: Easy movement for all species

#### Dense Terrain (Hills, Walls)
- **Prey Advantage**: Many hiding spots and obstacles
- **Ambush Opportunities**: Predators can use stealth
- **Complex Pathfinding**: Intelligence advantages matter
- **Energy Costs**: Higher movement costs

#### Water Terrain
- **Specialist Advantage**: Swimming ability matters
- **Speed Modifiers**: Different species affected differently
- **Limited Access**: Some species avoid water entirely
- **Escape Routes**: Water as barrier or highway

### Weather Effects

Weather conditions modify **hunting and fleeing**:

#### Storms
- **Reduced Visibility**: Harder to detect prey/predators
- **Movement Penalties**: Slower chase and escape speeds
- **Energy Costs**: Higher energy expenditure
- **Shelter Seeking**: All species seek protection

#### Clear Weather
- **Enhanced Vision**: Better detection ranges
- **Optimal Movement**: Full speed capabilities
- **Active Hunting**: Predators more aggressive
- **Open Foraging**: Prey more willing to explore

### Seasonal Cycles

Seasons create **long-term behavioral changes**:

#### Spring/Summer
- **Abundant Food**: Less hunting pressure
- **Breeding Season**: Territorial behavior intensifies
- **Energy Surplus**: More risk-taking behavior
- **Population Growth**: Increased competition

#### Fall/Winter
- **Food Scarcity**: Increased hunting desperation
- **Energy Conservation**: Reduced activity levels
- **Survival Mode**: Focus on efficiency over growth
- **Population Pressure**: Intense competition for resources

## Performance Metrics

### Hunt Success Rates

Tracking **hunting effectiveness** over time:

```swift
// Typical success rates by species and generation
let huntSuccessRate = successfulHunts / totalHuntAttempts

// Early generations: 20-40% success
// Evolved predators: 60-80% success
// Apex predators: 80-95% success
```

### Survival Rates

Measuring **prey survival** against predation:

```swift
// Survival metrics
let predationMortality = deathsByPredation / totalDeaths
let escapeSuccess = successfulEscapes / predatorEncounters

// Early prey: 30-50% escape success
// Evolved prey: 70-90% escape success
// Evasion specialists: 90-95% escape success
```

### Energy Efficiency

Analyzing **energy economics** of predator-prey interactions:

```swift
// Energy efficiency metrics
let huntingROI = energyGained / energyCostPerHunt
let fleeingCost = totalFleeEnergy / totalFleeEvents

// Efficient predators: 3-5x energy return
// Efficient prey: <2 energy per flee event
```

## System Balance

### Population Dynamics

The system maintains **ecological balance** through:

#### Predator-Prey Oscillations
- High predator population → Prey population declines
- Low prey population → Predator population declines
- Low predator population → Prey population recovers
- High prey population → Predator population recovers

#### Carrying Capacity
- Environment limits total population
- Competition for resources
- Territory limitations
- Energy availability constraints

#### Evolutionary Stability
- Balanced selection pressures
- No single optimal strategy
- Environmental variation prevents fixation
- Continuous arms race dynamics

### Tuning Parameters

Key parameters for **system balance**:

```swift
// Hunt success factors
let huntSuccessBase = 0.4          // Base success probability
let sizeAdvantageWeight = 0.3      // Size importance in hunting
let speedAdvantageWeight = 0.2     // Speed importance in hunting
let stealthBonusWeight = 0.2       // Stealth effectiveness

// Energy economics
let maxHuntEnergyGain = 50.0       // Maximum energy from hunt
let huntEnergyCostRange = 1.0...3.0 // Energy cost variation
let fleeEnergyCostRange = 0.5...4.0 // Flee cost variation

// Detection ranges
let maxPreyDetectionRange = 150.0   // Maximum hunting range
let maxPredatorDetectionRange = 100.0 // Maximum threat detection
```

## Future Enhancements

### Planned Features
- **Pack Hunting AI**: Coordinated group strategies
- **Ambush Behaviors**: Stealth-based hunting tactics
- **Mimicry**: Prey species mimicking dangerous species
- **Tool-Assisted Hunting**: Using environmental tools

### Research Applications
- **Evolutionary Dynamics**: Study of predator-prey coevolution
- **Behavioral Ecology**: Emergence of complex behaviors
- **Population Biology**: Predator-prey population cycles
- **Game Theory**: Evolutionary stable strategies

---

*The Predator-Prey System creates the fundamental ecological dynamics that drive evolution in Bugtopia, ensuring that survival of the fittest plays out through realistic and engaging species interactions.*