//
//  MemoryLeakTracker.swift
//  Bugtopia
//
//  Created by Assistant on 8/12/25.
//

import Foundation
import SceneKit

/// Comprehensive memory leak detection and tracking system
class MemoryLeakTracker {
    static let shared = MemoryLeakTracker()
    
    // MARK: - Tracking Counters
    private var nodeCreationCount: Int = 0
    private var nodeDestructionCount: Int = 0
    private var timerCreationCount: Int = 0
    private var timerInvalidationCount: Int = 0
    
    // Texture tracking
    private var textureCreationCount: Int = 0
    private var textureDestructionCount: Int = 0
    
    // Geometry tracking (LIKELY CULPRIT!)
    private var geometryCreationCount: Int = 0
    private var meshVertexCount: Int = 0
    private var geometryDestructionCount: Int = 0
    
    // Physics tracking (LIKELY THE REAL CULPRIT!)
    private var physicsBodyCreationCount: Int = 0
    private var physicsShapeCreationCount: Int = 0
    private var physicsBodyDestructionCount: Int = 0
    private var arena3DViewInstances: Int = 0
    private var navigationResponderInstances: Int = 0
    
    // MARK: - Array Size Tracking
    private var lastBugCount: Int = 0
    private var lastFoodCount: Int = 0
    private var lastSignalCount: Int = 0
    private var lastResourceCount: Int = 0
    private var lastToolCount: Int = 0
    
    // MARK: - Dictionary Size Tracking
    private var lastBugMappingSize: Int = 0
    private var lastFoodMappingSize: Int = 0
    
    // MARK: - Closure Tracking (RETAIN CYCLE DETECTION)
    private var activeClosures: [String: Int] = [:]
    private var closureCreationCount = 0
    private var closureDestructionCount = 0
    
    // MARK: - Memory Tracking
    private var lastMemoryUsage: UInt64 = 0
    private var memoryGrowthRate: Double = 0.0
    private var startTime: CFTimeInterval = 0
    
    private init() {
        startTime = CACurrentMediaTime()
        lastMemoryUsage = getCurrentMemoryUsage()
    }
    
    // MARK: - Node Tracking (Minimized - Nodes are balanced)
    func trackNodeCreation(type: String, name: String) {
        nodeCreationCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    func trackNodeDestruction(type: String, name: String) {
        nodeDestructionCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    // MARK: - Timer Tracking
    func trackTimerCreation(description: String) {
        timerCreationCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    func trackTimerInvalidation(description: String) {
        timerInvalidationCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    // MARK: - Texture Tracking (FOCUS: This is likely the real leak!)
    func trackTextureCreation(type: String, size: String) {
        textureCreationCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    // MARK: - Geometry Tracking (NEW SUSPECT!)
    func trackGeometryCreation(type: String, vertexCount: Int) {
        geometryCreationCount += 1
        meshVertexCount += vertexCount
        // Debug logging disabled for gameplay focus
    }
    
    func trackGeometryDestruction(type: String, vertexCount: Int) {
        geometryDestructionCount += 1
        meshVertexCount -= vertexCount
        // Debug logging disabled for gameplay focus
    }
    
    // MARK: - Physics Tracking (REAL CULPRIT SUSPECT!)
    func trackPhysicsBodyCreation(type: String) {
        physicsBodyCreationCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    func trackPhysicsShapeCreation(type: String, complexity: String) {
        physicsShapeCreationCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    func trackPhysicsBodyDestruction(type: String) {
        physicsBodyDestructionCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    func trackTextureDestruction(type: String) {
        textureDestructionCount += 1
        // Debug logging disabled for gameplay focus
    }
    
    // MARK: - Instance Tracking
    func trackArena3DViewCreation() {
        arena3DViewInstances += 1
        // Debug logging disabled for gameplay focus
    }
    
    func trackArena3DViewDestruction() {
        arena3DViewInstances -= 1
        // Debug logging disabled for gameplay focus
    }
    
    func trackNavigationResponderCreation() {
        navigationResponderInstances += 1
        // Debug logging disabled for gameplay focus
    }
    
    func trackNavigationResponderDestruction() {
        navigationResponderInstances -= 1
        // Debug logging disabled for gameplay focus
    }
    
    // MARK: - Enhanced Array Size Monitoring (PRIMARY SUSPECT!)
    func trackArraySizes(bugs: Int, foods: Int, signals: Int, resources: Int, tools: Int) {
        let bugGrowth = bugs - lastBugCount
        let foodGrowth = foods - lastFoodCount
        let signalGrowth = signals - lastSignalCount
        let resourceGrowth = resources - lastResourceCount
        let toolGrowth = tools - lastToolCount
        
        // Calculate total object count
        let totalObjects = bugs + foods + signals + resources + tools
        let previousTotal = lastBugCount + lastFoodCount + lastSignalCount + lastResourceCount + lastToolCount
        let totalGrowth = totalObjects - previousTotal
        
        if bugGrowth != 0 || foodGrowth != 0 || signalGrowth != 0 || resourceGrowth != 0 || toolGrowth != 0 {
            print("📊 [COLLECTION GROWTH] Total Objects: \(totalObjects) (Δ\(totalGrowth >= 0 ? "+" : "")\(totalGrowth))")
            if bugGrowth != 0 { print("  🐛 Bugs: \(lastBugCount) → \(bugs) (\(bugGrowth > 0 ? "+" : "")\(bugGrowth))") }
            if foodGrowth != 0 { print("  🍎 Foods: \(lastFoodCount) → \(foods) (\(foodGrowth > 0 ? "+" : "")\(foodGrowth))") }
            if signalGrowth != 0 { print("  📡 Signals: \(lastSignalCount) → \(signals) (\(signalGrowth > 0 ? "+" : "")\(signalGrowth))") }
            if resourceGrowth != 0 { print("  ⛏️ Resources: \(lastResourceCount) → \(resources) (\(resourceGrowth > 0 ? "+" : "")\(resourceGrowth))") }
            if toolGrowth != 0 { print("  🔨 Tools: \(lastToolCount) → \(tools) (\(toolGrowth > 0 ? "+" : "")\(toolGrowth))") }
            
            // FLAG SUSPICIOUS GROWTH
            if totalGrowth > 100 {
                print("🚨 [MEMORY ALERT] Large collection growth: +\(totalGrowth) objects!")
            }
        }
        
        lastBugCount = bugs
        lastFoodCount = foods
        lastSignalCount = signals
        lastResourceCount = resources
        lastToolCount = tools
    }
    
    // MARK: - Dictionary Size Monitoring
    func trackDictionarySizes(bugMappings: Int, foodMappings: Int) {
        let bugMappingGrowth = bugMappings - lastBugMappingSize
        let foodMappingGrowth = foodMappings - lastFoodMappingSize
        
        if bugMappingGrowth != 0 || foodMappingGrowth != 0 {
            let totalMappings = bugMappings + foodMappings
            let totalMappingGrowth = (bugMappings + foodMappings) - (lastBugMappingSize + lastFoodMappingSize)
            
            print("🗃️ [MAPPING GROWTH] Total: \(totalMappings) (Δ\(totalMappingGrowth >= 0 ? "+" : "")\(totalMappingGrowth))")
            if bugMappingGrowth != 0 { print("  🐛 Bug Mappings: \(lastBugMappingSize) → \(bugMappings) (\(bugMappingGrowth > 0 ? "+" : "")\(bugMappingGrowth))") }
            if foodMappingGrowth != 0 { print("  🍎 Food Mappings: \(lastFoodMappingSize) → \(foodMappings) (\(foodMappingGrowth > 0 ? "+" : "")\(foodMappingGrowth))") }
            
            // FLAG DICTIONARY LEAKS
            if totalMappingGrowth > 50 {
                print("🚨 [MAPPING ALERT] Large dictionary growth: +\(totalMappingGrowth) mappings!")
            }
        }
        
        lastBugMappingSize = bugMappings
        lastFoodMappingSize = foodMappings
    }
    
    // MARK: - Closure Lifecycle Tracking (RETAIN CYCLE DETECTION!)
    func trackClosureCreation(type: String) {
        closureCreationCount += 1
        activeClosures[type, default: 0] += 1
        print("🧵 [CLOSURE] Created \(type) (Active: \(activeClosures[type]!), Total: \(closureCreationCount))")
    }
    
    func trackClosureDestruction(type: String) {
        closureDestructionCount += 1
        if activeClosures[type, default: 0] > 0 {
            activeClosures[type]! -= 1
            print("🧵 [CLOSURE] Destroyed \(type) (Active: \(activeClosures[type]!), Total: \(closureDestructionCount))")
        } else {
            print("⚠️ [CLOSURE] Attempted to destroy \(type) but none active!")
        }
    }
    
    func getClosureLeak() -> Int {
        return closureCreationCount - closureDestructionCount
    }
    
    // MARK: - Comprehensive Memory Report
    func generateMemoryReport() {
        let currentMemory = getCurrentMemoryUsage()
        let memoryGrowth = currentMemory - lastMemoryUsage
        let timeElapsed = CACurrentMediaTime() - startTime
        
        if timeElapsed > 0 {
            memoryGrowthRate = Double(memoryGrowth) / timeElapsed
        }
        
        print("=" * 80)
        print("🧠 [MEMORY LEAK REPORT] - \(Date())")
        print("=" * 80)
        print("📈 Memory Usage: \(formatBytes(Int64(currentMemory))) (Growth: \(formatBytes(Int64(memoryGrowth))))")
        print("📊 Growth Rate: \(formatBytes(Int64(memoryGrowthRate)))/second")
        print("")
        print("🏟️ Arena3DView Instances: \(arena3DViewInstances)")
        print("🧭 NavigationResponder Instances: \(navigationResponderInstances)")
        print("")
        print("🟢 Nodes Created: \(nodeCreationCount)")
        print("🔴 Nodes Destroyed: \(nodeDestructionCount)")
        let nodeLeak = nodeCreationCount - nodeDestructionCount
        print("⚠️ Node Leak Potential: \(nodeLeak)")
        
        // TODO: Monitor small node leaks - even 2-3 nodes can compound over extended runtime
        // Target: Keep node leak under 10 consistently. If it grows beyond 50, investigate:
        // - Check if existence checks are working properly in all 4 creation paths
        // - Look for edge cases in node cleanup (death animations, generation changes)
        // - Verify cleanupOrphanedMappings() is catching all orphaned nodes
        if nodeLeak > 50 {
            print("🚨 [WARNING] Node leak exceeding acceptable threshold! Investigate node cleanup.")
        }
        print("")
        print("⏰ Timers Created: \(timerCreationCount)")
        print("⏹️ Timers Invalidated: \(timerInvalidationCount)")
        print("⚠️ Timer Leak Potential: \(timerCreationCount - timerInvalidationCount)")
        print("")
        print("🎨 Textures Created: \(textureCreationCount)")
        print("🗑️ Textures Destroyed: \(textureDestructionCount)")
        print("⚠️ Texture Leak Potential: \(textureCreationCount - textureDestructionCount)")
        print("")
        print("📐 Geometries Created: \(geometryCreationCount)")
        print("🗑️ Geometries Destroyed: \(geometryDestructionCount)")
        print("📊 Active Vertex Count: \(meshVertexCount)")
        print("⚠️ Geometry Leak Potential: \(geometryCreationCount - geometryDestructionCount)")
        print("")
        print("⚛️ Physics Bodies Created: \(physicsBodyCreationCount)")
        print("💥 Physics Bodies Destroyed: \(physicsBodyDestructionCount)")
        print("🔷 Physics Shapes Created: \(physicsShapeCreationCount)")
        print("⚠️ Physics Body Leak Potential: \(physicsBodyCreationCount - physicsBodyDestructionCount)")
        print("")
        print("📊 Current Arrays:")
        print("  🐛 Bugs: \(lastBugCount)")
        print("  🍎 Foods: \(lastFoodCount)")
        print("  📡 Signals: \(lastSignalCount)")
        print("  ⛏️ Resources: \(lastResourceCount)")
        print("  🔨 Tools: \(lastToolCount)")
        print("")
        print("🗂️ Current Dictionaries:")
        print("  🐛 Bug Mappings: \(lastBugMappingSize)")
        print("  🍎 Food Mappings: \(lastFoodMappingSize)")
        print("=" * 80)
        
        lastMemoryUsage = currentMemory
        startTime = CACurrentMediaTime()
    }
    
    // MARK: - Memory Utilities
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - String Extension for Repeat
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}
