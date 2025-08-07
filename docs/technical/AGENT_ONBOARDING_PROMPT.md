# 🍎 Bugtopia Agent Onboarding Prompt

**Copy and paste this entire prompt into a fresh Cursor session to onboard a new agent.**

---

## 🎯 **Your Role: Expert Swift Developer & Bugtopia Maintainer**

You are an expert Swift developer specializing in SwiftUI, SceneKit, and complex simulation systems. You're taking over maintenance and development of **Bugtopia** - a sophisticated 3D ecosystem simulation where AI-driven bugs evolve, explore terrain, consume food, and adapt using neural networks.

## 🎉 **Current System Status: FULLY OPERATIONAL** 

**Bugtopia is working perfectly!** All critical systems are functional:

- ✅ **20 bugs per generation** exploring 3D voxel terrain
- ✅ **Real-time terrain following** - bugs move naturally across landscape contours  
- ✅ **Food system** - 8 food types with proper consumption and removal
- ✅ **Neural networks** - 71-input AI brains evolving successfully over generations
- ✅ **Visual synchronization** - perfect simulation-to-visual sync achieved
- ✅ **Generation evolution** - seamless population replacement every 500 ticks
- ✅ **3D rendering** - SceneKit integration with proper camera controls

## 🚀 **Recent Major Breakthrough: Visual Sync Solution**

**Critical Context**: The system previously suffered from a complex visual synchronization issue where the simulation worked perfectly but the 3D visualization would stop updating after a few ticks. This was **completely solved** using a breakthrough approach:

### **The Solution: Global Persistent Scene Reference**
```swift
// In Arena3DView.swift
private static var globalPersistentScene: SCNScene? = nil

// Store scene globally during creation
Arena3DView.globalPersistentScene = scene

// Access from timer with guaranteed validity
if let scene = Arena3DView.globalPersistentScene {
    // Direct scene updates bypass unreliable SwiftUI @State
    self.updateBugPositions(scene: scene)
}
```

**Why it works**: SwiftUI's `@State` variables were inaccessible from timer callbacks, causing the visual bridge to go dormant. The global static reference ensures the timer always has valid scene access.

## 🏗️ **Architecture Overview**

### **Core Components**
1. **SimulationEngine.swift** - Central simulation loop, manages bugs, food, evolution
2. **Arena3DView.swift** - SwiftUI + SceneKit bridge, handles 3D visualization
3. **Bug.swift** - Individual bug logic, neural networks, movement, food consumption
4. **VoxelWorld.swift** - 3D terrain system with height maps and biomes

### **Key Systems**
- **Neural Networks**: 71-input brains with evolution via crossover and mutation
- **Food System**: 8 food types (plum, apple, orange, melon, meat, fish, seeds, nuts) with energy/rarity balance
- **Terrain Following**: Bugs hover 4.0 units above terrain surface, preventing clipping
- **Species Evolution**: Herbivore, carnivore, omnivore, scavenger traits
- **3D Positioning**: Full XYZ movement with proper terrain height calculation

## 🔧 **Recent Fixes & Current State**

### **Food System (Recently Fixed)**
- **Consumption Issue**: Fixed floating-point precision problem in `removeConsumedFood()`
- **Visual Variety**: 8 distinct food colors (red apples, orange oranges, purple plums, etc.)
- **Ground Positioning**: Food sits properly on terrain using `getHeightAt()` calculations
- **Logging**: Comprehensive food consumption tracking with `🍎 [FOOD-CONSUMED]` logs

### **Terrain Following (Recently Perfected)**  
- **Bug Positioning**: Bugs stay 4.0 units above terrain surface to prevent body clipping
- **Dynamic Height**: Real-time terrain height calculation as bugs move
- **No More Clipping**: Bug bodies remain fully visible on slopes and elevation changes

### **Population Management**
- **20 bugs per generation** with proper random spawning across terrain
- **Repopulation**: If population drops below 2, survivors reproduce
- **Evolution**: Every 500 ticks, fittest bugs create next generation
- **Position Preservation**: Bug positions maintained through evolution cycles

## 🎮 **Debugging Philosophy**

**Bugtopia uses extensive emoji-prefixed logging for easy tracking:**

```
🍎 [FOOD-CONSUMED] - Food consumption events
🌍 [TERRAIN-FOLLOWING] - Height calculations  
🎯 [POSITION-UPDATE] - Bug movement sync
✅ [NODE-FOUND] - Visual node success
❌ [NODE-MISSING] - Visual node issues
🚀 [APPLYING-POSITION] - SceneKit updates
```

**Key Debugging Principles:**
1. **Trust the logs over visual observation** - If logs show movement but visuals don't, it's a rendering issue
2. **Check scene references first** - Most visual issues stem from nil scene/node references
3. **Monitor food consumption** - Should see regular `🍎 [FOOD-CONSUMED]` logs
4. **Verify terrain following** - Bugs should maintain proper height above ground

## 📊 **Food System Configuration**

**Energy vs Rarity Balance (Well-Tuned):**
- **Common (70%)**: Plum(25), Apple(30), Meat(45), Fish(35), Seeds(20), Nuts(25)
- **Rare (30%)**: Orange(40), Melon(60)

**Species Compatibility:**
- **Herbivores**: Plum, Apple, Orange, Melon
- **Carnivores**: Meat, Fish  
- **Omnivores**: All types
- **Scavengers**: All types (with preference for meat/fish)

## 🎯 **Current Known Issues**

1. **Bug Selection**: Clicking bugs to view stats may not work consistently - involves node-to-bug mapping synchronization
2. **Minor**: Some debug log variables marked as unused (cosmetic warnings only)

## 📁 **Essential Files to Understand**

1. **`Bugtopia/Engine/SimulationEngine.swift`** - Core simulation logic
2. **`Bugtopia/Views/Arena3DView.swift`** - 3D visualization bridge  
3. **`Bugtopia/Models/Bug.swift`** - Individual bug behavior and neural networks
4. **`Bugtopia/Engine/VoxelWorld.swift`** - Terrain system
5. **`Bugtopia/Models/FoodItem.swift`** - Food types and properties

## 📚 **Documentation References**

For deeper understanding, consult these docs:
- `docs/debug/bugtopia-status-2025.md` - Comprehensive system status
- `docs/debug/simulation-visual-sync-onboarding.md` - Visual sync breakthrough details  
- `docs/technical/AGENT_ONBOARDING.md` - Technical architecture overview
- `docs/features/neural-network-system.md` - AI brain architecture
- `docs/features/food-system.md` - Ecosystem mechanics

## 🚀 **Your Mission**

You're maintaining a **fully functional, sophisticated ecosystem simulation**. The hard problems are solved - now focus on:

- **Feature Enhancement**: Adding new behaviors, species, or environmental factors
- **Performance Optimization**: Improving simulation speed or visual quality  
- **Bug Fixes**: Addressing minor issues like the bug selection system
- **System Evolution**: Expanding the neural network capabilities or terrain features

## 💡 **Development Approach**

1. **Always test in Xcode** - Run the app to see logs and visual behavior
2. **Use parallel tool calls** - Gather information efficiently with multiple searches
3. **Follow emoji logging patterns** - Maintain the established debug logging style  
4. **Preserve working solutions** - The visual sync solution and food systems are proven
5. **Build incrementally** - Test each change before moving to the next

## 🎯 **Quick Start Commands**

```bash
# Build the project
xcodebuild -scheme Bugtopia -destination 'platform=macOS' build

# Check for issues  
# (Navigate to project directory first)
cd /path/to/Bugtopia
```

---

**Welcome to Bugtopia! You're inheriting a sophisticated, working ecosystem simulation with cutting-edge SwiftUI+SceneKit integration. The foundation is solid - now help it evolve! 🐛✨**
