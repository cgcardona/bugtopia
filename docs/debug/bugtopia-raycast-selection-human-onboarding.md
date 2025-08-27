# Bugtopia Ray-Casting Selection System - Human Developer Onboarding

## 🎯 **Overview**

Bugtopia uses a custom ray-casting selection system to enable pixel-perfect clicking on food items and bugs in the 3D world. This system converts 2D screen clicks into 3D world coordinates and performs ray-sphere intersection testing.

## 🏗️ **Architecture**

### **Current Implementation Status**
- ✅ **Ray-casting mathematics implemented**
- ✅ **Screen-to-world projection**
- ✅ **UUID-based entity identification**
- ❌ **MAJOR ISSUE: Only 14% success rate (1/7 clicks)**
- ❌ **Food stats mismatch visual entities**
- ❌ **Golden highlight never appears**

## 🔧 **Core Components**

### **1. Main Selection Entry Point**
```swift
@available(macOS 14.0, *)
private func selectEntityAt(location: CGPoint, in anchor: AnchorEntity)
```
- **Input**: Screen coordinates from tap gesture
- **Process**: Converts to normalized coordinates, creates ray, tests intersections
- **Output**: Selects closest entity along ray or deselects all

### **2. Ray-Casting Mathematics**
```swift
private func rayIntersectsEntity(rayOrigin: SIMD3<Float>, rayDirection: SIMD3<Float>, entity: Entity) -> Float?
```
- **Algorithm**: Ray-sphere intersection using dot product and distance calculations
- **Entity Radius**: Fixed 2.0 units (may be incorrect)
- **Returns**: Distance along ray to intersection point, or nil if no hit

### **3. Screen-to-World Projection**
```swift
private func projectClickToTerrain(normalizedX: Float, normalizedY: Float) -> SIMD3<Float>
```
- **WARNING**: Currently uses simplified orthographic projection
- **Scale Factor**: 50.0 units (arbitrary, may cause issues)
- **Limitation**: Doesn't account for camera pitch/yaw properly

## 🚨 **Known Issues & Root Causes**

### **Issue 1: Unreliable Selection (14% success rate)**
**Root Cause**: Camera transform calculations are incorrect
- Current ray direction uses hardcoded camera vectors
- Doesn't properly apply `cameraPitch` and `cameraYaw` rotations
- Screen-to-world projection is oversimplified

### **Issue 2: Food Stats Mismatch**
**Root Cause**: Entity positioning vs simulation data desync
- Visual entities may not be in exact sync with `simulationEngine.foods` array
- Timing issues between entity updates and data updates

### **Issue 3: Golden Highlight Never Appears**
**Root Cause**: Selection highlight creation issues
- May be positioning problem with highlight entity
- Could be material/visibility issue
- Might be parent/child hierarchy problem

## 🔍 **Debugging Tools**

### **Enhanced Logging**
When clicking, you'll see detailed debug output:
```
🎯 [SELECTION] Click at screen coordinates: (x, y)
🎯 [RAY] From: SIMD3<Float>(x, y, z), Direction: SIMD3<Float>(x, y, z)
🍎 [DEBUG] Found FoodContainer with X children
🔍 [RAY] Entity: Food_UUID at SIMD3<Float>(x, y, z)
🔍 [RAY] Distance to entity: X, radius: 2.0
```

### **Selection Success Indicators**
- `🎯 [RAY] HIT!` = Ray intersection successful
- `❌ [RAY] MISS` = Ray missed entity
- `✅ FOOD MATCH` = Entity linked to data successfully

## 💡 **Improvement Strategy**

### **Phase 1: Fix Camera Transform**
1. Implement proper camera matrix calculations
2. Use actual `cameraPitch` and `cameraYaw` in ray direction
3. Add perspective projection instead of orthographic

### **Phase 2: Fix Entity Bounds**
1. Use actual entity bounds instead of fixed 2.0 radius
2. Consider entity shape (sphere vs. box vs. complex mesh)
3. Add adaptive selection radius based on camera distance

### **Phase 3: RealityKit Native Integration**
1. Investigate RealityKit's built-in entity selection APIs
2. Use `ARView.raycast()` methods if available
3. Leverage RealityKit's collision detection system

## 🎯 **Testing Guidelines**

### **Manual Testing**
1. Click directly on center of food items
2. Test from different camera angles/distances
3. Verify food stats match visual appearance
4. Look for golden highlight appearance

### **Debug Mode**
- Enable all ray-casting logs
- Monitor FPS impact of selection system
- Track memory usage of highlight entities

## 🏆 **Success Criteria**

- **95%+ selection accuracy** on direct clicks
- **Zero data mismatches** between visual and stats
- **Consistent golden highlights** on all food selections
- **Sub-16ms selection processing** to maintain 60fps

---

*Last Updated: Current as of ray-casting implementation with UUID-based entity naming*
