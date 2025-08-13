# 🤖 Agent Onboarding: SceneKit to RealityKit Migration

## 🎯 Mission Context

**Current Task**: Migrating Bugtopia's 3D rendering from SceneKit to RealityKit for future-proofing and spatial computing capabilities.

**Project Status**: Planning phase - creating migration strategy and documentation before implementation begins.

**Repository**: `/Users/gabriel/dev/tellurstori/MacOS/Bugtopia` (realitykit-refactor branch)

## 🧬 Bugtopia Overview

Bugtopia is an advanced evolutionary simulation featuring:
- **180+ simultaneous AI bugs** with evolvable neural networks (71 inputs, 10 outputs)
- **Complex 3D environments**: Underground caves, surface terrain, forest canopy, aerial zones
- **Predator-prey dynamics**: 4 species types with hunting/defensive behaviors
- **Environmental systems**: Weather, seasons, natural disasters, tool construction
- **Real-time evolution**: Genetics, neural networks, and population dynamics

## 🔄 Migration Context

### Why Migrate?
- **SceneKit**: Soft deprecated (only critical bug fixes)
- **RealityKit**: Apple's future, spatial computing ready, Vision Pro native
- **Bugtopia**: Unreleased, perfect candidate for next-gen platform

### Key Technical Challenges
1. **Performance**: 180+ entities with complex AI need 60 FPS
2. **Neural Integration**: 71-input neural networks driving bug behavior
3. **Complex Physics**: Multi-layer 3D movement, pathfinding, collisions
4. **Environmental Effects**: Weather, disasters, seasonal changes

## 🏗️ Current Architecture (SceneKit)

### Core Files to Understand
```
Bugtopia/
├── Views/Arena3DView.swift        # Main 3D visualization (8000+ lines)
├── Engine/SimulationEngine.swift  # Core simulation logic
├── Models/Bug.swift              # Individual bug entities with AI
├── AI/NeuralNetwork.swift        # 71-input neural networks
├── Engine/Arena.swift            # 3D world generation
└── Engine/VoxelWorld.swift       # Terrain and environment
```

### Key Architecture Components
```swift
// Current SceneKit Implementation
class Arena3DView: SCNView {
    @StateObject var simulationEngine: SimulationEngine
    var bugNodes: [SCNNode] = []           // 180+ bug visual nodes
    var bugNodeToBugMapping: [SCNNode: Bug] = [:]
    var terrainNode: SCNNode?              // Procedural terrain
    var bugContainer: SCNNode             // Spatial organization
}
```

### Critical Systems
1. **Bug Rendering**: Each bug is an SCNNode with geometry, materials, physics
2. **Neural Network Integration**: AI decisions → 3D movement/behavior
3. **Terrain Generation**: Procedural 3D worlds with multiple layers
4. **Performance Optimization**: LOD, culling, efficient updates

## 🎯 Target Architecture (RealityKit)

### Proposed Structure
```swift
// Target RealityKit Implementation
struct Arena3DView: View {
    @StateObject var simulationEngine: SimulationEngine
    
    var body: some View {
        RealityView { content in
            // Entity-Component-System architecture
            content.add(terrainEntity)
            content.add(bugContainer)
            content.add(environmentalEffects)
        } update: { content in
            updateBugPositions()
            updateNeuralNetworks()
            updateEnvironmentalSystems()
        }
    }
}
```

### Migration Mapping
| SceneKit Component | RealityKit Equivalent | Migration Complexity |
|-------------------|----------------------|-------------------|
| `SCNNode` | `Entity` | Medium - Different hierarchy |
| `SCNGeometry` | `ModelComponent` | Low - Direct conversion |
| `SCNMaterial` | `Material` (PBR) | Medium - Enhanced capabilities |
| `SCNPhysicsBody` | `PhysicsBodyComponent` | Medium - API differences |
| `SCNScene` | `RealityView` | High - Architecture change |

## 🧠 Neural Network Integration

### Current Implementation
```swift
// Bug AI decision making (Bug.swift:300-400)
let decision = neuralNetwork.processInputs(sensoryInputs)
// Apply decisions to SceneKit node
bugNode.position = SCNVector3(newPosition.x, newPosition.y, newPosition.z)
```

### Migration Requirements
- **Maintain**: 71-input neural network architecture
- **Adapt**: Position updates to RealityKit Entity system
- **Enhance**: Potential for better spatial AI with RealityKit features

## 📋 Migration Phase Checklist

### Phase 1: Foundation ✅ COMPLETED
- [x] **Performance Baseline**: Measure current SceneKit performance
- [x] **RealityKit Proof-of-Concept**: Basic terrain + 10 bugs
- [x] **Entity Architecture**: Design ECS system for bugs
- [x] **Neural Integration Test**: Verify AI → RealityKit compatibility
- [x] **Feature Flag System**: Seamless SceneKit ↔ RealityKit switching
- [x] **Performance Monitoring**: Real-time benchmarking tools

### Phase 2: Core Systems
- [ ] **Bug Entity System**: Convert all 180 bugs to RealityKit
- [ ] **Movement Migration**: 3D pathfinding and layer navigation
- [ ] **Terrain Conversion**: Procedural world generation
- [ ] **Environmental Effects**: Weather, disasters, seasons

### Phase 3: Polish & Optimize
- [ ] **Performance Optimization**: 60 FPS with full simulation
- [ ] **Visual Enhancement**: PBR materials, advanced lighting
- [ ] **Spatial Features**: Vision Pro preparation
- [ ] **Testing & Validation**: Feature parity verification

## 🔧 Implementation Strategy

### Development Approach
1. **Parallel Development**: Keep SceneKit version functional
2. **Feature Flags**: Easy switching between renderers
3. **Incremental Migration**: One system at a time
4. **Continuous Testing**: Performance and feature validation

### Key Migration Steps
```swift
// Step 1: Basic RealityView setup
struct Arena3DView: View {
    var body: some View {
        RealityView { content in
            // Start with empty scene
        }
    }
}

// Step 2: Add terrain entity
let terrainEntity = createTerrainEntity()
content.add(terrainEntity)

// Step 3: Migrate bug entities
for bug in simulationEngine.bugs {
    let bugEntity = createBugEntity(from: bug)
    content.add(bugEntity)
}

// Step 4: Integrate neural networks
func updateBugBehavior(entity: Entity, bug: Bug) {
    let decision = bug.neuralNetwork.processInputs(sensoryInputs)
    entity.transform.translation = SIMD3(decision.moveX, entity.transform.translation.y, decision.moveY)
}
```

## ⚠️ Critical Considerations

### Performance Requirements
- **Target**: 60 FPS with 180+ AI-driven entities
- **Memory**: Stay within reasonable limits on mobile devices
- **CPU**: Neural network processing + rendering optimization

### Technical Risks
1. **Entity Limits**: Unknown RealityKit performance ceiling
2. **Physics Integration**: Complex multi-layer movement system
3. **Neural Network Performance**: AI processing in RealityKit context
4. **Platform Differences**: macOS vs iOS vs visionOS variations

### Success Criteria
- All current features functional in RealityKit
- Performance equal or better than SceneKit
- Enhanced visual quality with PBR materials
- Vision Pro compatibility demonstrated

## 🚀 Next Steps for Agent

When taking over this migration task:

1. **Read Current Code**: Focus on `Arena3DView.swift` (main rendering)
2. **Understand Bug System**: `Bug.swift` + `NeuralNetwork.swift` integration
3. **Analyze Performance**: Current bottlenecks and optimization opportunities
4. **Start Small**: Begin with basic RealityView + single bug entity
5. **Measure Everything**: Performance benchmarks throughout migration

## 📚 Essential Context Files

### Before Making Changes, Read:
- `Views/Arena3DView.swift` - Current 3D implementation
- `Engine/SimulationEngine.swift` - Core simulation loop
- `Models/Bug.swift` - Individual entity behavior
- `docs/technical/scenekit-to-realitykit-migration-strategy.md` - Human-readable strategy

### Key Performance Areas:
- Bug entity updates (180+ entities)
- Neural network processing (71 inputs × 180 bugs)
- Terrain rendering and physics
- Environmental effect systems

---

**Agent Handoff Protocol**: When context runs out, provide this document + current progress status + specific blockers encountered.

*Last Updated: August 2025*
*Context: Planning phase, no implementation started yet*
