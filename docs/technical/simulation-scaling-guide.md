# 🎛️ Bugtopia Simulation Scaling Guide

## 📏 Resolution Scaling Reference

This document outlines exactly what values need to be changed when scaling Bugtopia's simulation and renderer resolutions for testing, debugging, and production use.

---

## 🎯 Current Production Settings (2000x2000 Simulation)

### **Simulation Resolution: 2000x2000**
- **File**: `Bugtopia/Views/SimulationView.swift`
- **Line**: ~34
- **Value**: `CGSize(width: 2000, height: 2000)`
- **Purpose**: Defines the simulation world bounds

### **Renderer Resolution: 200x200**
- **File**: `Bugtopia/Views/Arena3DView_RealityKit_v2.swift`
- **Line**: ~31
- **Value**: `private let terrainSize: Float = 200.0`
- **Purpose**: RealityKit world size (simulation * 0.1 scale factor)

### **Coordinate Scaling Factor: 0.1**
- **File**: `Bugtopia/Views/Arena3DView_RealityKit_v2.swift`
- **Line**: ~29
- **Value**: `private let simulationScale: Float = 0.1`
- **Purpose**: Converts simulation coordinates to RealityKit coordinates

### **3D Z-Coordinate Scaling: 0.1**
- **File**: `Bugtopia/Views/Arena3DView_RealityKit_v2.swift`
- **Line**: ~1399, ~2082, ~2996
- **Value**: `Float(bug.position3D.z) * 0.1`
- **Purpose**: Scales 3D layer Z-coordinates from simulation space to RealityKit space
- **Layer Mapping**: Underground (-50 to -30) → RK (-5 to -3), Surface (-30 to 10) → RK (-3 to 1), etc.

### **Pheromone System Resolution: 200x200**
- **File**: `Bugtopia/Views/Arena3DView_RealityKit_v2.swift`
- **Line**: ~215
- **Value**: `resolution: 200`
- **Purpose**: Pheromone field grid resolution (matches renderer resolution)

---

## 🔧 Scaling Configurations

### **Debug/Testing Scale (500x500 Simulation)**
```swift
// SimulationView.swift
CGSize(width: 500, height: 500)

// Arena3DView_RealityKit_v2.swift
private let simulationScale: Float = 0.1     // Keep same
private let terrainSize: Float = 50.0        // 500 * 0.1 = 50
resolution: 50                               // Match terrain size
```

### **Medium Scale (1000x1000 Simulation)**
```swift
// SimulationView.swift
CGSize(width: 1000, height: 1000)

// Arena3DView_RealityKit_v2.swift
private let simulationScale: Float = 0.1     // Keep same
private let terrainSize: Float = 100.0       // 1000 * 0.1 = 100
resolution: 100                              // Match terrain size
```

### **Production Scale (2000x2000 Simulation)**
```swift
// SimulationView.swift
CGSize(width: 2000, height: 2000)

// Arena3DView_RealityKit_v2.swift
private let simulationScale: Float = 0.1     // Keep same
private let terrainSize: Float = 200.0       // 2000 * 0.1 = 200
resolution: 200                              // Match terrain size
```

### **Large Scale (4000x4000 Simulation)**
```swift
// SimulationView.swift
CGSize(width: 4000, height: 4000)

// Arena3DView_RealityKit_v2.swift
private let simulationScale: Float = 0.1     // Keep same
private let terrainSize: Float = 400.0       // 4000 * 0.1 = 400
resolution: 400                              // Match terrain size
```

---

## 📋 Scaling Checklist

When changing simulation scale, update these values in order:

### ✅ **Step 1: Simulation Bounds**
- [ ] `Bugtopia/Views/SimulationView.swift` - Line ~34
- [ ] Update `CGSize(width: X, height: X)` where X is your desired simulation size

### ✅ **Step 2: Renderer Size**
- [ ] `Bugtopia/Views/Arena3DView_RealityKit_v2.swift` - Line ~31
- [ ] Update `terrainSize: Float = Y` where Y = X * 0.1

### ✅ **Step 3: Pheromone Resolution**
- [ ] `Bugtopia/Views/Arena3DView_RealityKit_v2.swift` - Line ~215
- [ ] Update `resolution: Z` where Z = Y (same as terrain size)

### ✅ **Step 4: Verify Coordinate System**
- [ ] Ensure `simulationScale: Float = 0.1` remains unchanged
- [ ] Verify `worldScale: Float = 0.1` remains unchanged
- [ ] Test that objects appear correctly positioned

---

## 🎮 Population Scaling Guidelines

### **Bug Population by Scale**
- **500x500**: 5-10 bugs (testing)
- **1000x1000**: 10-20 bugs (development)
- **2000x2000**: 20-50 bugs (production)
- **4000x4000**: 50-100 bugs (large scale)

### **Food Density by Scale**
- **Small worlds**: Higher density (more food per unit area)
- **Large worlds**: Lower density (bugs must search more)
- **Formula**: `maxFoodItems = (worldSize / 100) * baseFoodDensity`

---

## ⚠️ Important Notes

### **DO NOT CHANGE**
- `simulationScale: Float = 0.1` - This is the sacred coordinate conversion factor
- `worldScale: Float = 0.1` - This maintains coordinate system alignment
- `terrainScale: Float = 6.25` - This is calculated for optimal terrain mesh generation

### **ALWAYS MAINTAIN**
- **Square aspect ratio**: Width = Height for both simulation and renderer
- **10:1 scaling ratio**: Renderer size = Simulation size * 0.1
- **Matching pheromone resolution**: Should equal renderer size for optimal performance

### **PERFORMANCE CONSIDERATIONS**
- **Larger scales**: Require more memory and processing power
- **Pheromone resolution**: Higher resolution = better accuracy but slower performance
- **Bug population**: Scale population with world size to maintain density

---

## 🧪 Testing Different Scales

### **Quick Scale Test**
1. Change simulation size in `SimulationView.swift`
2. Update terrain size in `Arena3DView_RealityKit_v2.swift`
3. Update pheromone resolution
4. Launch and verify objects appear correctly positioned
5. Check performance and adjust population if needed

### **Verification Points**
- [ ] Bugs spawn within world bounds
- [ ] Food appears on terrain surface
- [ ] Camera navigation works smoothly
- [ ] Coordinate system debug info shows correct ranges
- [ ] Performance remains acceptable (30+ FPS)

---

*This guide ensures consistent scaling across all Bugtopia systems while maintaining the battle-tested coordinate system architecture.*
