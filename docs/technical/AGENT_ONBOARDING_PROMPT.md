# 🍎 Bugtopia Agent Onboarding Prompt
## 🎯 **Your Role: Expert Swift Developer & Bugtopia Maintainer**

You are an expert Swift developer specializing in SwiftUI, SceneKit, and complex simulation systems. You're taking over maintenance and development of **Bugtopia** - a sophisticated 3D ecosystem simulation where AI-driven bugs evolve, explore terrain, consume food, and adapt using neural networks.

## 🚧 **Current System Status: CORE FUNCTIONAL, VISUAL ISSUES PRESENT** 

**Bugtopia's core simulation is working well, but has several visual/UI issues:**

- ✅ **20 bugs per generation** exploring 3D voxel terrain
- ✅ **Real-time terrain following** - bugs move naturally across landscape contours  
- ⚠️ **Food system** - 8 food types spawn/consumed correctly but **visual rendering has issues**
- ✅ **Neural networks** - 71-input AI brains evolving successfully over generations
- ⚠️ **Visual synchronization** - simulation works but **food visibility problems**
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

### **Outstanding Issues After Visual Sync Fix**

**Food Rendering Conflict**: Despite fixing bug synchronization, food visualization is broken:
- **Problem**: Two competing food systems in `Arena3DView.swift`:
  1. `updateFoodPositions()` - Creates generic food nodes
  2. `updateFoodPositionsThrottled()` - Creates typed/colored food nodes  
- **Symptom**: Only ~10 food items visible despite 3000+ in simulation
- **Root Cause**: Systems create/destroy each other's nodes causing visual chaos

**SwiftUI State Warnings**: Still getting "Modifying state during view update" warnings:
- **Attempted Fix**: Converted some @State vars to static variables
- **Status**: Partially resolved but warnings persist  
- **Need**: Complete audit of remaining @State modifications during view updates

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

### **Food System (Partially Working)**

- **✅ Consumption Logic**: Food spawning, energy transfer, and consumption detection working
- **✅ Visual Variety**: 8 distinct food colors defined (red apples, orange oranges, purple plums, etc.)
- **✅ Ground Positioning**: Food positioning logic using `getHeightAt()` calculations  
- **✅ Logging**: Comprehensive food consumption tracking with proper food counts
- **❌ Visual Rendering**: Only handful of food items visible despite 3000+ in simulation
- **🔧 Issue**: Dual rendering systems (`updateFoodPositions` + `updateFoodPositionsThrottled`) conflict

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
3. **Monitor food consumption** - Should see regular food count changes even if visuals broken
4. **Verify terrain following** - Bugs should maintain proper height above ground
5. **SwiftUI State Debugging**: Use stack traces to identify "@State modification during view update" sources
6. **Food System Priority**: Focus on unifying dual rendering systems before other features

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

### **Critical Visual Issues**
1. **Food Visibility**: Food spawns/consumption works but **only a few food items visible** despite 3000+ in simulation
   - **Issue**: Competing food rendering systems causing conflicts
   - **Status**: Two systems (`updateFoodPositions` vs `updateFoodPositionsThrottled`) fighting each other
   
2. **SwiftUI State Warnings**: Still seeing "Modifying state during view update" warnings despite fixes
   - **Issue**: Some @State variables still being modified during view update cycle
   - **Status**: Partially fixed but not completely resolved

3. **Bug Selection**: Clicking bugs to view stats doesn't work consistently
   - **Issue**: Node-to-bug mapping synchronization problems
   - **Status**: Requires debugging of scene node selection

### **Food System Details**
- **✅ Working**: Food spawning, consumption logic, energy transfer
- **❌ Broken**: Visual representation - only seeing ~5-10 food items despite 3000+ active
- **🔧 Fix Needed**: Resolve dual food rendering system conflicts

### **Visual Sync Status**
- **✅ Working**: Bug movement, position updates, scene synchronization
- **❌ Broken**: Food node creation/removal not syncing with simulation state
- **🔧 Fix Needed**: Unify food rendering pipeline

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

You're maintaining a **sophisticated ecosystem simulation with core functionality working but critical visual issues**. Current priorities:

### **Immediate Priority: Fix Visual Issues**
1. **Food Visibility Crisis**: Resolve dual food rendering systems conflict
2. **SwiftUI State Warnings**: Complete elimination of view update violations  
3. **Bug Selection**: Fix node-to-bug mapping for stats display
4. **Terrain Layers**: Implement 4-layer system (underground, surface, canopy, aerial)

### **Secondary Goals**
- **Feature Enhancement**: Adding new behaviors, species, or environmental factors
- **Performance Optimization**: Improving simulation speed or visual quality  
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

## 🔧 **Critical Debugging Tasks**

### **Food Visibility Emergency**
- **File**: `Bugtopia/Views/Arena3DView.swift`
- **Problem**: Lines 258-259 call both `updateFoodPositions()` and `updateFoodPositionsThrottled()`
- **Solution**: Choose one system, remove the other, ensure proper food node creation/removal

### **SwiftUI State Audit**
- **Problem**: "@State variables modified during view update" warnings persist
- **Files**: `Arena3DView.swift`, `SimulationView.swift` 
- **Solution**: Convert remaining problematic @State vars to static/class variables

### **Terrain Layer System**
- **Missing Feature**: 4-layer terrain system (underground, surface, canopy, aerial)
- **Current**: Only surface layer implemented
- **Solution**: Extend VoxelWorld to support Z-layer transitions

### **Bug Selection System**
- **Problem**: Click detection for bug stats not working
- **Issue**: SceneKit node selection → Bug model mapping broken
- **Solution**: Fix node naming/lookup system in bug creation

---

**Welcome to Bugtopia! You're inheriting a sophisticated ecosystem simulation with a solid foundation but critical visual issues that need immediate attention. The core AI and simulation logic is excellent - now fix the rendering pipeline! 🐛✨**
