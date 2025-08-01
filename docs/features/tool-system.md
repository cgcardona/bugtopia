# 🔨 Tool System Documentation

## Overview

The Tool System enables bugs to **modify their environment** through construction and tool use, representing a major evolutionary leap toward technological intelligence. This system implements resource gathering, construction planning, collaborative building, and tool utilization that allows bugs to overcome environmental challenges and create lasting changes to their world.

## Core Components

### Tool Types

Bugtopia features **8 distinct tool types**, each designed to solve specific environmental challenges:

| Tool | Icon | Function | Energy Cost | Construction Time | Primary Benefit |
|------|------|----------|-------------|------------------|-----------------|
| **🚩 Marker** | Purple | Navigation/Territory | 5 | 20 ticks | Orientation, memory aid |
| **🪤 Trap** | Red | Prey capture | 10 | 40 ticks | Hunting efficiency |
| **📐 Ramp** | Yellow | Hill climbing | 15 | 60 ticks | Terrain traversal |
| **🌉 Bridge** | Brown | Water crossing | 20 | 80 ticks | Barrier bypassing |
| **🏠 Shelter** | Gray | Protection/Energy | 25 | 100 ticks | Safety, energy recovery |
| **🔧 Lever** | Orange | Object manipulation | 30 | 120 ticks | Environmental modification |
| **🪺 Nest** | Green | Group reproduction | 35 | 140 ticks | Breeding enhancement |
| **🕳️ Tunnel** | Black | Wall penetration | 40 | 160 ticks | Ultimate barrier bypass |

### Tool Properties

#### Physical Characteristics
```swift
struct Tool: Identifiable, Codable {
    let type: ToolType
    let position: CGPoint
    let creatorId: UUID
    let creationTime: TimeInterval
    var durability: Double         // 0.0-1.0, decreases over time
    var uses: Int                  // Usage counter
    let generation: Int            // Creation generation
}
```

#### Size and Collision
```swift
var size: CGSize {
    switch type {
    case .marker: return CGSize(width: 8, height: 8)
    case .trap, .ramp: return CGSize(width: 20, height: 20)
    case .bridge: return CGSize(width: 40, height: 20)
    case .tunnel: return CGSize(width: 30, height: 30)
    case .shelter, .nest: return CGSize(width: 50, height: 50)
    case .lever: return CGSize(width: 15, height: 25)
    }
}
```

#### Durability System
```swift
var isUsable: Bool {
    return durability > 0.1  // Tools become unusable below 10% durability
}

mutating func degrade(by amount: Double = 0.001) {
    durability = max(0.0, durability - amount)
}

mutating func use() {
    uses += 1
    let usageDecay = type.energyCost / 1000.0  // Expensive tools decay slower
    durability = max(0.0, durability - usageDecay)
}
```

## Resource System

### Resource Types

The construction economy is based on **5 fundamental resources**:

| Resource | Icon | Weight | Availability | Primary Use |
|----------|------|--------|--------------|-------------|
| **🧵 Fiber** | Green | 0.5 | Plant-based | Flexible connections, traps |
| **🫘 Food** | Orange | 1.0 | Abundant | Energy storage, emergency |
| **🪵 Stick** | Brown | 1.5 | Common | Basic construction material |
| **🟤 Mud** | Brown | 2.0 | Water areas | Moldable material, sealing |
| **🪨 Stone** | Gray | 3.0 | Hills/rocks | Heavy-duty construction |

### Resource Nodes

#### Resource Generation
```swift
struct Resource: Identifiable, Codable {
    let type: ResourceType
    let position: CGPoint
    var quantity: Int              // Available amount (0-10)
    let respawnRate: Double        // Regeneration speed
    var lastHarvest: TimeInterval  // Last collection time
}
```

#### Harvesting Mechanics
```swift
mutating func harvest(amount: Int = 1) -> Int {
    let harvested = min(amount, quantity)
    quantity -= harvested
    lastHarvest = Date().timeIntervalSince1970
    return harvested
}

mutating func regenerate() {
    let currentTime = Date().timeIntervalSince1970
    let timePassed = currentTime - lastHarvest
    let maxQuantity = 10
    
    if quantity < maxQuantity {
        let regeneration = timePassed * respawnRate
        quantity = min(maxQuantity, quantity + Int(regeneration))
    }
}
```

### Construction Recipes

Each tool requires **specific resource combinations**:

```swift
static let recipes: [ToolType: [ResourceType: Int]] = [
    .marker: [.stick: 1],                           // Simple navigation aid
    .trap: [.stick: 2, .fiber: 1],                 // Flexible capture device
    .ramp: [.mud: 2, .stone: 1],                   // Solid inclined surface
    .bridge: [.stick: 3, .fiber: 2],               // Spanning structure
    .shelter: [.stick: 2, .stone: 2, .mud: 1],     // Protective enclosure
    .lever: [.stone: 2, .stick: 1],                // Mechanical advantage
    .nest: [.stick: 3, .fiber: 3, .mud: 2],        // Breeding facility
    .tunnel: [.stone: 4, .mud: 3]                  // Underground passage
]
```

## Tool DNA System

### Genetic Tool Traits

Bugs possess **evolvable tool-use capabilities** encoded in their DNA:

```swift
struct ToolDNA: Codable, Equatable, Hashable {
    let toolCrafting: Double          // Construction skill (0.0-1.0)
    let toolProficiency: Double       // Usage effectiveness (0.0-1.0)
    let toolVision: Double            // Resource detection (0.0-1.0)
    let constructionDrive: Double     // Building motivation (0.0-1.0)
    let carryingCapacity: Double      // Resource transport (0.0-1.0)
    let resourceGathering: Double     // Harvesting efficiency (0.0-1.0)
    let engineeringIntelligence: Double // Design optimization (0.0-1.0)
    let collaborationTendency: Double // Group construction (0.0-1.0)
}
```

### Trait Functions

#### Construction Skill
- **High toolCrafting**: Faster construction, higher quality tools
- **Low toolCrafting**: Slower building, more resource waste
- **Evolutionary pressure**: Environmental challenges requiring tools

#### Tool Proficiency
- **High toolProficiency**: More effective tool use, longer tool lifespan
- **Low toolProficiency**: Poor tool utilization, faster degradation
- **Evolutionary pressure**: Tool-dependent survival scenarios

#### Resource Detection
- **High toolVision**: Better resource finding, optimal material selection
- **Low toolVision**: Difficulty locating materials, suboptimal choices
- **Evolutionary pressure**: Resource scarcity, construction needs

#### Construction Motivation
- **High constructionDrive**: Proactive building, infrastructure development
- **Low constructionDrive**: Reactive building, minimal tool use
- **Evolutionary pressure**: Environmental complexity, group benefits

## Construction Process

### Phase 1: Planning & Decision Making

#### Environmental Analysis
```swift
private func considerConstruction(in arena: Arena, otherBugs: [Bug]) {
    guard currentProject == nil,
          energy > 40.0,
          dna.toolDNA.constructionDrive > Double.random(in: 0...1) else {
        return
    }
    
    let currentTerrain = arena.terrainAt(position)
    let nearbyTerrain = scanNearbyTerrain(in: arena)
    
    var constructionPriorities: [ToolType: Double] = [:]
    
    // Water nearby - consider bridge
    if nearbyTerrain.contains(.water) {
        constructionPriorities[.bridge] = 0.8
    }
    
    // Hills nearby - consider ramp
    if nearbyTerrain.contains(.hill) {
        constructionPriorities[.ramp] = 0.6
    }
    
    // Walls nearby - consider tunnel
    if nearbyTerrain.contains(.wall) {
        constructionPriorities[.tunnel] = 0.7
    }
}
```

#### Priority System
- **Immediate needs**: Barriers blocking current path
- **Group benefits**: Tools that help multiple bugs
- **Strategic value**: Long-term environmental advantages
- **Resource availability**: Materials accessible for construction

### Phase 2: Resource Gathering

#### Resource Collection
```swift
func gatherResource(from resource: inout Resource) -> Int {
    let gatheringEfficiency = dna.toolDNA.resourceGathering
    let maxGather = Int(gatheringEfficiency * 3.0) + 1
    let actualGathered = resource.harvest(amount: maxGather)
    
    // Energy cost for gathering
    energy -= Double(actualGathered) * 0.5
    
    return actualGathered
}
```

#### Carrying Capacity
```swift
var maxCarryWeight: Double {
    return dna.toolDNA.carryingCapacity * 10.0  // 0-10 weight units
}

var currentCarryWeight: Double {
    return inventory.reduce(0) { total, item in
        total + (item.value * item.key.weight)
    }
}
```

### Phase 3: Blueprint Creation

#### Construction Planning
```swift
struct ToolBlueprint: Codable, Equatable, Hashable {
    let type: ToolType
    let position: CGPoint
    let requiredResources: [ResourceType: Int]
    var gatheredResources: [ResourceType: Int]
    let builderId: UUID
    let startTime: TimeInterval
    var workProgress: Int
    
    var hasAllResources: Bool {
        for (resourceType, required) in requiredResources {
            let gathered = gatheredResources[resourceType] ?? 0
            if gathered < required {
                return false
            }
        }
        return true
    }
    
    var isComplete: Bool {
        return hasAllResources && workProgress >= type.constructionTime
    }
}
```

### Phase 4: Construction Work

#### Building Process
```swift
func workOnConstruction(_ blueprint: inout ToolBlueprint) -> Bool {
    let distanceToSite = distance(to: blueprint.position)
    guard distanceToSite < 20.0,
          blueprint.hasAllResources else {
        return false
    }
    
    let workEfficiency = dna.toolDNA.toolCrafting
    let workDone = Int(workEfficiency * 3.0) + 1
    blueprint.addWork(ticks: workDone)
    
    // Energy cost for construction work
    energy -= Double(workDone) * 0.2
    
    return true
}
```

#### Collaborative Construction
- **Multiple builders**: Several bugs can work on same project
- **Skill combination**: Different bugs contribute different capabilities
- **Resource sharing**: Bugs can contribute materials to others' projects
- **Leadership roles**: High-intelligence bugs coordinate group efforts

## Tool Effects & Mechanics

### Environmental Modifications

#### Movement Enhancement
```swift
static func getMovementModifier(at position: CGPoint, tools: [Tool], for bug: BugDNA) -> Double {
    for tool in tools {
        if tool.bounds.contains(position) && tool.isUsable {
            switch tool.type {
            case .bridge:
                return 1.2  // 20% faster movement over water/gaps
            case .ramp:
                return 1.1  // 10% easier hill climbing
            case .tunnel:
                return 1.0  // Normal movement through walls
            default:
                continue
            }
        }
    }
    return 1.0
}
```

#### Terrain Bypassing
```swift
static func isPassageAllowed(at position: CGPoint, tools: [Tool]) -> Bool {
    for tool in tools {
        if tool.bounds.contains(position) && tool.isUsable {
            switch tool.type {
            case .bridge, .tunnel:
                return true  // These tools allow passage through barriers
            default:
                continue
            }
        }
    }
    return false
}
```

#### Energy Benefits
```swift
static func getEnergyBonus(at position: CGPoint, tools: [Tool]) -> Double {
    for tool in tools {
        if tool.bounds.contains(position) && tool.isUsable {
            switch tool.type {
            case .shelter:
                return 2.0  // Energy recovery bonus
            case .nest:
                return 1.5  // Breeding area energy bonus
            default:
                continue
            }
        }
    }
    return 0.0
}
```

### Specialized Tool Functions

#### Traps (Hunting Enhancement)
- **Prey Capture**: Increased hunting success rate near traps
- **Energy Efficiency**: Reduced energy cost for hunting
- **Passive Hunting**: Traps can capture prey without direct bug involvement
- **Strategic Placement**: Optimal positioning increases effectiveness

#### Markers (Navigation Aid)
- **Pathfinding**: Improved navigation between marked locations
- **Territory Definition**: Establish and defend territorial boundaries
- **Memory Enhancement**: External memory for complex route planning
- **Communication**: Signal locations to other bugs

#### Shelters (Protection & Recovery)
- **Energy Recovery**: Accelerated energy regeneration
- **Weather Protection**: Reduced weather damage
- **Predator Defense**: Safe zones from predator attacks
- **Group Coordination**: Meeting points for social activities

#### Nests (Reproduction Enhancement)
- **Breeding Success**: Increased reproduction rates
- **Offspring Survival**: Better survival rates for newborns
- **Group Breeding**: Coordinated reproduction for population groups
- **Genetic Mixing**: Enhanced opportunities for crossover

## Evolutionary Pressures

### Tool-Use Evolution

#### Environmental Challenges Drive Tool Innovation
- **Barrier-Rich Environments**: Select for tunnel and bridge builders
- **Resource-Scarce Areas**: Favor efficient gatherers and hoarders
- **Predator-Heavy Zones**: Promote shelter and trap construction
- **Complex Terrain**: Reward versatile tool users

#### Tool DNA Selection Pressures
```swift
// Environmental complexity increases tool-use fitness
let toolFitnessBonus = environmentalComplexity * toolDNA.engineeringIntelligence * 10

// Resource availability affects gathering traits
let gatheringFitness = resourceScarcity * toolDNA.resourceGathering * 5

// Group size influences collaboration traits
let collaborationFitness = groupSize * toolDNA.collaborationTendency * 8
```

### Arms Race Dynamics

#### Tool vs. Anti-Tool Evolution
- **Trap Builders vs. Trap Avoiders**: Predators develop traps, prey develop detection
- **Shelter Builders vs. Shelter Breakers**: Protection vs. penetration abilities
- **Resource Hoarders vs. Resource Raiders**: Storage vs. theft strategies
- **Territory Markers vs. Territory Invaders**: Boundary establishment vs. violation

#### Technological Escalation
- **Simple Tools → Complex Tools**: Evolution of sophisticated construction
- **Individual Tools → Collaborative Tools**: Group construction projects
- **Passive Tools → Active Tools**: Tools that modify environment dynamically
- **Static Tools → Adaptive Tools**: Tools that respond to conditions

## Advanced Tool Behaviors

### Collaborative Construction

#### Group Coordination
```swift
// Leader initiates construction project
if let group = currentGroup, groupRole == .leader {
    constructionPriorities[.nest] = 0.9
}

// Followers contribute resources and labor
if let project = nearbyBlueprint, project.builderId != self.id {
    contributeToProject(project)
}
```

#### Skill Specialization
- **Architects**: High engineering intelligence, plan complex projects
- **Gatherers**: High resource gathering, supply construction materials
- **Builders**: High tool crafting, efficient construction work
- **Coordinators**: High collaboration tendency, organize group efforts

### Tool Maintenance & Repair

#### Durability Management
```swift
// Tools degrade over time and use
mutating func degrade(by amount: Double = 0.001) {
    durability = max(0.0, durability - amount)
}

// Weather affects tool degradation
let weatherDamage = weatherIntensity * 0.002
tool.degrade(by: weatherDamage)
```

#### Repair Behaviors
- **Maintenance Checks**: Bugs inspect tools for damage
- **Repair Actions**: Restore durability using resources
- **Replacement Planning**: Build new tools before old ones fail
- **Tool Sharing**: Group maintenance of communal tools

### Tool Innovation

#### Adaptive Construction
```swift
// Bugs learn optimal tool placement
let toolBenefit = calculateToolBenefit(tool, in: arena)
if toolBenefit > previousBenefit {
    // Reinforce successful tool placement behavior
    toolPlacementMemory[position] = toolBenefit
}
```

#### Environmental Responsiveness
- **Seasonal Tools**: Different tools for different seasons
- **Weather-Specific Tools**: Shelters during storms, bridges during floods
- **Predator-Response Tools**: Traps and shelters based on threat levels
- **Resource-Adaptive Tools**: Construction based on material availability

## Performance & Balance

### Computational Efficiency

#### Tool System Optimization
```swift
// Efficient tool collision detection
let nearbyTools = spatialHash.getToolsNear(position, radius: interactionRange)

// Batch resource regeneration
resources.forEach { $0.regenerate() }

// Lazy blueprint evaluation
blueprints.filter { $0.isComplete }.forEach { completeConstruction($0) }
```

#### Memory Management
- **Tool Limits**: Maximum number of tools per area
- **Blueprint Cleanup**: Remove abandoned construction projects
- **Resource Pooling**: Reuse resource node objects
- **Tool Degradation**: Automatic removal of broken tools

### Economic Balance

#### Resource Economy
```swift
// Resource spawn rates balance construction needs
let resourceSpawnRate = baseSpawnRate * (1.0 - toolDensity * 0.1)

// Construction costs scale with tool complexity
let energyCost = baseEnergyCost * complexityMultiplier

// Tool benefits balanced against costs
let benefitCostRatio = toolBenefit / (energyCost + resourceCost)
```

#### Construction Difficulty
- **Energy Requirements**: Tools require significant energy investment
- **Resource Scarcity**: Materials not always available
- **Time Investment**: Construction takes multiple generations
- **Collaboration Needs**: Complex tools require group effort

### Evolutionary Balance

#### Tool-Use vs. Other Strategies
```swift
// Tool users compete with non-tool users
let toolUserFitness = baseFitness + toolBenefits - toolCosts
let nonToolUserFitness = baseFitness + alternativeStrategies

// Environmental conditions determine optimal strategy
if environmentalComplexity > threshold {
    // Tool use becomes advantageous
    toolUserAdvantage = environmentalComplexity * toolEfficiency
}
```

## Integration with Other Systems

### Terrain System Integration
- **Tool-Terrain Interactions**: Tools modify terrain properties
- **Placement Constraints**: Tools can only be built on suitable terrain
- **Environmental Effects**: Weather and disasters affect tool durability
- **Terrain Memory**: Tools serve as permanent environmental modifications

### Neural Network Integration
- **Tool-Use Inputs**: Neural networks receive tool-related sensory data
- **Construction Decisions**: AI determines when and what to build
- **Resource Prioritization**: Neural networks optimize resource allocation
- **Collaboration Coordination**: AI manages group construction projects

### Communication System Integration
- **Construction Signals**: Bugs communicate about building projects
- **Resource Sharing**: Signal availability and need for materials
- **Tool Coordination**: Coordinate group tool use
- **Knowledge Transfer**: Share tool-building techniques

### Genetic System Integration
- **Tool DNA Evolution**: Construction traits subject to natural selection
- **Crossover Effects**: Tool abilities inherited from both parents
- **Mutation Innovation**: Random changes create new tool strategies
- **Selection Pressure**: Environmental challenges drive tool evolution

## Configuration & Tuning

### Tool Parameters
```swift
// Construction costs and times
let energyCosts: [ToolType: Double] = [
    .marker: 5.0, .trap: 10.0, .ramp: 15.0, .bridge: 20.0,
    .shelter: 25.0, .lever: 30.0, .nest: 35.0, .tunnel: 40.0
]

let constructionTimes: [ToolType: Int] = [
    .marker: 20, .trap: 40, .ramp: 60, .bridge: 80,
    .shelter: 100, .lever: 120, .nest: 140, .tunnel: 160
]
```

### Resource Parameters
```swift
// Resource properties
let resourceWeights: [ResourceType: Double] = [
    .fiber: 0.5, .food: 1.0, .stick: 1.5, .mud: 2.0, .stone: 3.0
]

let respawnRates: [ResourceType: Double] = [
    .fiber: 0.1, .food: 0.2, .stick: 0.05, .mud: 0.08, .stone: 0.03
]
```

### Balance Parameters
```swift
// Tool effectiveness
let movementBonuses = [.bridge: 1.2, .ramp: 1.1, .tunnel: 1.0]
let energyBonuses = [.shelter: 2.0, .nest: 1.5]
let huntingBonuses = [.trap: 1.5]

// Durability settings
let baseDurability = 1.0
let degradationRate = 0.001
let usageDecayRate = 0.0001
```

## Future Enhancements

### Planned Features
- **Tool Combinations**: Complex tools requiring multiple components
- **Automated Tools**: Self-operating tools with AI behavior
- **Tool Upgrades**: Improving existing tools with additional resources
- **Specialized Materials**: Rare resources for advanced construction

### Advanced Mechanics
- **Tool Physics**: Realistic mechanical interactions
- **Dynamic Tools**: Tools that adapt to environmental changes
- **Tool Networks**: Interconnected tool systems
- **Cultural Evolution**: Tool-use knowledge transmission

### Research Applications
- **Technology Evolution**: Study of technological development
- **Cooperation Studies**: Group construction and collaboration
- **Environmental Engineering**: Ecosystem modification by organisms
- **Cultural Transmission**: Non-genetic information transfer

---

*The Tool System represents the emergence of technology in Bugtopia, enabling bugs to transcend their biological limitations through environmental modification and collaborative construction, driving the evolution of intelligence and cooperation.*