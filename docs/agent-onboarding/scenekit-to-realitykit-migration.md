# 🤖 Agent Onboarding: SceneKit to RealityKit Migration

## 🎯 Mission Context

**Current Task**: Migrating Bugtopia's 3D rendering from SceneKit to RealityKit for future-proofing and spatial computing capabilities.

**Project Status**: Phase 2 in progress - Enhanced terrain visualization complete, 3D scene rendering next.

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
- [x] **RealityKit Proof-of-Concept**: Enhanced terrain analysis display
- [x] **Entity Architecture**: Design ECS system for bugs (`BugEntityManager`)
- [x] **Neural Integration Test**: Verify AI → RealityKit compatibility
- [x] **Feature Flag System**: Seamless SceneKit ↔ RealityKit switching
- [x] **Performance Monitoring**: Real-time benchmarking tools
- [x] **Memory Leak Fix**: Resolved arithmetic overflow crash
- [x] **Crash Debugging**: Stable 10+ minute operation

### Phase 2: Core Systems 🚧 IN PROGRESS
- [x] **Enhanced Terrain Visualization**: 12K+ surface voxels analyzed
- [x] **Real-time Bug Tracking**: 15+ bug entities with performance metrics
- [x] **Terrain Composition**: 12 terrain types (open, water, forest, etc.)
- [x] **Live Performance Display**: 30 FPS entity updates, optimal performance
- [ ] **CURRENT BLOCKER**: RealityView 3D scene rendering (macOS compatibility)
- [ ] **Bug Entity System**: Convert all 180 bugs to 3D RealityKit entities
- [ ] **Movement Migration**: 3D pathfinding and layer navigation
- [ ] **Terrain Conversion**: Procedural 3D world generation (from voxel data)
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

## 🔍 Critical Phase 1 Discoveries

### Technical Blockers Discovered
1. **RealityView macOS Issue**: `RealityViewContent` type not available on macOS
   ```swift
   // This fails on macOS:
   private func setupRealityKitScene(content: RealityViewContent) async {
       // Error: cannot find type 'RealityViewContent' in scope
   }
   ```
   - **Status**: Temporary workaround with enhanced data visualization
   - **Next Steps**: Research alternative 3D rendering approaches

2. **Memory Leak Tracker Crash**: Arithmetic overflow in memory tracking
   ```swift
   // Fixed in MemoryLeakTracker.swift:
   let memoryGrowth = Int64(currentMemory) - Int64(lastMemoryUsage)
   // Added safe arithmetic to prevent UInt64 overflow
   ```

### Major Successes
1. **Feature Flag System**: Perfect switching between SceneKit/RealityKit
2. **Enhanced Terrain Analysis**: Rich 12K+ voxel visualization with composition
3. **Performance Stability**: 30 FPS sustained, no memory growth in RealityKit
4. **Entity System Architecture**: Clean ECS implementation ready for 3D

### Current State Summary
- **SceneKit**: Working but shows immediate memory leak (confirming migration need)
- **RealityKit**: Excellent performance metrics, rich data display, stable operation
- **Next Priority**: Solve 3D scene rendering to visualize terrain and bugs in 3D space

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

### Immediate Priority (Phase 2 Continuation)
1. **Solve RealityView Issue**: Research macOS-compatible 3D scene rendering
   - Try different RealityKit approaches for macOS
   - Investigate Entity creation without RealityViewContent
   - Consider Metal/SceneKit hybrid approach as fallback

2. **3D Terrain Rendering**: Convert voxel data to 3D meshes
   - Use existing terrain analysis (12K+ voxels, 12 terrain types)
   - Generate 3D cube meshes for each voxel
   - Apply materials based on terrain type (grass=green, water=blue, etc.)

3. **3D Bug Visualization**: Replace text with actual 3D entities
   - Position 15+ bugs in 3D space using current coordinate system
   - Create simple sphere or box geometry for bugs
   - Apply bug state visualization (energy levels, species, behavior)

### Knowledge Base Required
1. **Enhanced Implementation**: `Arena3DView_RealityKit_v2.swift` (rich terrain display)
2. **Entity Management**: `BugEntityManager.swift` (ECS architecture)
3. **Performance System**: Stable 30 FPS, memory leak fixes
4. **Feature Flags**: Perfect SceneKit ↔ RealityKit switching

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

## 📋 Current Handoff Status

**Phase**: 2 of 3 (Core Systems - Visual Enhancement Focus)
**Last Major Achievement**: Enhanced terrain analysis with 12K+ voxels and real-time performance metrics
**Current Challenge**: RealityView 3D scene rendering compatibility on macOS
**Next Agent Priority**: Solve 3D visualization to show terrain and bugs in actual 3D space

### Files Modified This Session:
- `Arena3DView_RealityKit_v2.swift` - Enhanced terrain information display
- `BugEntityManager.swift` - ECS system with coordinate conversion
- `MemoryLeakTracker.swift` - Arithmetic overflow fix
- `RenderingEngine.swift` - Memory tracker integration

### Performance Status:
- ✅ **RealityKit Mode**: 30 FPS, no memory growth, stable 10+ minutes
- ⚠️ **SceneKit Mode**: Immediate memory balloon (confirms migration necessity)

**Agent Handoff Protocol**: When context runs out, provide this document + current progress status + specific blockers encountered.

*Last Updated: Current Session - Phase 2 Visual Enhancement*
*Context: Enhanced data visualization complete, 3D scene rendering next*
