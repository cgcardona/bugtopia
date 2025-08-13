//
//  BugEntityManager.swift
//  Bugtopia
//
//  Created by RealityKit Developer on 12/20/24.
//  Phase 2: Entity-Component-System for Bug Management
//

import Foundation
import RealityKit
import SwiftUI

/// 🐛 Bug Entity Manager
/// Manages the complete lifecycle of bug entities in RealityKit
/// Handles creation, updates, destruction, and performance optimization
class BugEntityManager: ObservableObject {
    
    // MARK: - Core State
    
    /// Mapping from simulation Bug ID to RealityKit Entity
    @Published private(set) var bugEntities: [UUID: Entity] = [:]
    
    /// Reverse mapping for interaction handling (using weak references)
    private(set) var entityToBugMapping: [Entity: UUID] = [:]
    
    /// Update concurrency control
    private var isUpdating: Bool = false
    
    /// Root container for all bug entities
    private(set) var bugContainer: Entity
    
    /// Performance tracking
    @Published private(set) var performanceMetrics = BugEntityPerformanceMetrics()
    
    // MARK: - Configuration
    
    /// Maximum entities before optimization kicks in
    let maxEntitiesBeforeOptimization: Int = 200
    
    /// Distance for LOD culling
    let lodCullingDistance: Float = 50.0
    
    /// Enable performance optimizations
    var enablePerformanceOptimizations: Bool = true
    
    // MARK: - Initialization
    
    init() {
        self.bugContainer = Entity()
        self.bugContainer.name = "BugContainer"
        print("🐛 [BugEntityManager] Initialized with container: \(bugContainer.name ?? "unnamed")")
    }
    
    // MARK: - Entity Lifecycle Management
    
    /// Create or update all bug entities to match simulation state
    @MainActor
    func updateBugEntities(with bugs: [Bug]) {
        // Prevent concurrent updates
        guard !isUpdating else {
            print("⚠️ [BugEntityManager] Skipping update - already in progress")
            return
        }
        
        isUpdating = true
        defer { isUpdating = false }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Performance tracking
        performanceMetrics.lastUpdateStartTime = startTime
        performanceMetrics.totalBugsInSimulation = bugs.count
        
        // Remove entities for bugs that no longer exist
        removeDeadBugEntities(currentBugs: bugs)
        
        // Create or update entities for current bugs
        updateAliveBugEntities(bugs)
        
        // Apply performance optimizations if needed
        if enablePerformanceOptimizations {
            applyPerformanceOptimizations()
        }
        
        // Update performance metrics
        let endTime = CFAbsoluteTimeGetCurrent()
        performanceMetrics.lastUpdateDuration = endTime - startTime
        performanceMetrics.totalManagedEntities = bugEntities.count
        
        if performanceMetrics.lastUpdateDuration > 0.016 { // > 16ms (60 FPS target)
            print("⚠️ [BugEntityManager] Slow update: \(String(format: "%.2f", performanceMetrics.lastUpdateDuration * 1000))ms")
        }
    }
    
    /// Remove entities for bugs that are no longer alive
    private func removeDeadBugEntities(currentBugs: [Bug]) {
        let currentBugIds = Set(currentBugs.map { $0.id })
        let deadBugIds = Set(bugEntities.keys).subtracting(currentBugIds)
        
        for deadBugId in deadBugIds {
            if let entity = bugEntities[deadBugId] {
                // Clean up mappings
                entityToBugMapping.removeValue(forKey: entity)
                bugEntities.removeValue(forKey: deadBugId)
                
                // Remove from scene safely
                Task { @MainActor in
                    entity.removeFromParent()
                }
                
                performanceMetrics.entitiesDestroyed += 1
            }
        }
        
        if !deadBugIds.isEmpty {
            print("🗑️ [BugEntityManager] Removed \(deadBugIds.count) dead bug entities")
        }
    }
    
    /// Create or update entities for alive bugs
    private func updateAliveBugEntities(_ bugs: [Bug]) {
        for bug in bugs where bug.isAlive {
            if let entity = bugEntities[bug.id] {
                // Update existing entity
                updateBugEntity(entity, for: bug)
            } else {
                // Create new entity
                let newEntity = createBugEntity(for: bug)
                bugContainer.addChild(newEntity)
                bugEntities[bug.id] = newEntity
                entityToBugMapping[newEntity] = bug.id  // Store UUID instead of Bug object
                
                performanceMetrics.entitiesCreated += 1
            }
        }
    }
    
    // MARK: - Bug Entity Creation
    
    /// Create a new RealityKit entity for a bug
    private func createBugEntity(for bug: Bug) -> Entity {
        let entity = Entity()
        entity.name = "Bug_\(bug.id.uuidString.prefix(8))"
        
        // Create species-specific geometry
        let bugMesh = createBugMesh(for: bug)
        let bugMaterial = createBugMaterial(for: bug)
        
        // Add model component
        entity.components.set(ModelComponent(
            mesh: bugMesh,
            materials: [bugMaterial]
        ))
        
        // Add collision for interaction
        entity.generateCollisionShapes(recursive: false)
        
        // Set initial transform
        updateBugTransform(entity, for: bug)
        
        // Add custom bug component for tracking
        entity.components.set(BugEntityComponent(bugId: bug.id))
        
        return entity
    }
    
    /// Update an existing bug entity
    private func updateBugEntity(_ entity: Entity, for bug: Bug) {
        // Update transform (position, rotation, scale)
        updateBugTransform(entity, for: bug)
        
        // Update materials based on current state
        updateBugMaterial(entity, for: bug)
        
        // Update any animations or effects
        updateBugEffects(entity, for: bug)
    }
    
    /// Update entity transform based on bug state
    private func updateBugTransform(_ entity: Entity, for bug: Bug) {
        // Position
        entity.position = SIMD3<Float>(
            Float(bug.position3D.x),
            Float(bug.position3D.y),
            Float(bug.position3D.z)
        )
        
        // Scale based on energy and age
        let energyScale = Float(bug.energy / Bug.maxEnergy)
        let ageScale = 1.0 - Float(bug.age) / Float(Bug.maxAge) * 0.2 // Slight size reduction with age
        let finalScale = max(0.3, energyScale * ageScale) // Minimum scale
        
        entity.scale = SIMD3<Float>(repeating: finalScale)
        
        // Rotation (could be based on movement direction)
        if let decision = bug.lastDecision {
            let moveDirection = SIMD2<Float>(Float(decision.moveX), Float(decision.moveY))
            if length(moveDirection) > 0.01 {
                let angle = atan2(moveDirection.y, moveDirection.x)
                entity.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
            }
        }
    }
    
    /// Update bug material based on current state
    private func updateBugMaterial(_ entity: Entity, for bug: Bug) {
        guard var modelComponent = entity.components[ModelComponent.self] else { return }
        
        let updatedMaterial = createBugMaterial(for: bug)
        modelComponent.materials = [updatedMaterial]
        entity.components.set(modelComponent)
    }
    
    /// Update visual effects for bug
    private func updateBugEffects(_ entity: Entity, for bug: Bug) {
        // Add energy glow effect for low energy bugs
        if bug.energy < 20.0 {
            // Could add particle effects or emission
        }
        
        // Add communication signal effects
        if !bug.recentSignals.isEmpty {
            // Could add signal visualization
        }
    }
    
    // MARK: - Geometry & Material Creation
    
    /// Create species-specific mesh for bug
    private func createBugMesh(for bug: Bug) -> MeshResource {
        // Safety: ensure valid size values
        let baseSize = max(0.1, min(2.0, Float(bug.dna.size))) // Clamp between 0.1 and 2.0
        
        // For now, use energy-based shapes (will be enhanced with species-specific geometry)
        if bug.energy > 70 {
            return MeshResource.generateSphere(radius: baseSize * 0.8)
        } else if bug.energy > 40 {
            let size = max(0.1, baseSize) // Ensure minimum size
            return MeshResource.generateBox(size: SIMD3<Float>(repeating: size))
        } else {
            return MeshResource.generateSphere(radius: max(0.1, baseSize * 0.6))
        }
    }
    
    /// Create material based on bug state and species
    private func createBugMaterial(for bug: Bug) -> RealityKit.Material {
        var material = PhysicallyBasedMaterial()
        
        // Energy-based color
        let energyRatio = Float(bug.energy / Bug.maxEnergy)
        let baseColor = NSColor(
            red: CGFloat(1.0 - energyRatio * 0.5), // More red when low energy
            green: CGFloat(energyRatio), // More green when high energy
            blue: CGFloat(0.2 + energyRatio * 0.3),
            alpha: 1.0
        )
        
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: baseColor)
        material.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: 0.4)
        material.metallic = PhysicallyBasedMaterial.Metallic(floatLiteral: 0.1)
        
        // Add emission for very low energy (warning)
        if bug.energy < 10.0 {
            material.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(color: .red)
            material.emissiveIntensity = 0.3
        }
        
        return material
    }
    
    // MARK: - Performance Optimization
    
    /// Apply various performance optimizations
    private func applyPerformanceOptimizations() {
        guard bugEntities.count > maxEntitiesBeforeOptimization else { return }
        
        // TODO: Implement LOD system
        // TODO: Implement frustum culling
        // TODO: Implement entity pooling
        
        performanceMetrics.optimizationsApplied += 1
    }
    
    // MARK: - Interaction Support
    
    /// Find bug ID associated with entity (for selection)
    func bugId(for entity: Entity) -> UUID? {
        return entityToBugMapping[entity]
    }
    
    /// Find entity associated with bug
    func entity(for bug: Bug) -> Entity? {
        return bugEntities[bug.id]
    }
    
    /// Get all entities within distance of point
    func entitiesNear(point: SIMD3<Float>, distance: Float) -> [Entity] {
        return bugEntities.values.filter { entity in
            let entityDistance = simd_distance(entity.position, point)
            return entityDistance <= distance
        }
    }
    
    // MARK: - Debug & Analytics
    
    /// Get current performance metrics
    func getPerformanceReport() -> String {
        return """
        🐛 Bug Entity Manager Performance:
        • Managed Entities: \(performanceMetrics.totalManagedEntities)
        • Simulation Bugs: \(performanceMetrics.totalBugsInSimulation)
        • Last Update: \(String(format: "%.2f", performanceMetrics.lastUpdateDuration * 1000))ms
        • Entities Created: \(performanceMetrics.entitiesCreated)
        • Entities Destroyed: \(performanceMetrics.entitiesDestroyed)
        • Optimizations Applied: \(performanceMetrics.optimizationsApplied)
        """
    }
    
    /// Clear all entities (for reset)
    @MainActor
    func clearAllEntities() {
        guard !isUpdating else {
            print("⚠️ [BugEntityManager] Cannot clear entities - update in progress")
            return
        }
        
        for entity in bugEntities.values {
            entity.removeFromParent()
        }
        
        bugEntities.removeAll()
        entityToBugMapping.removeAll()
        
        print("🗑️ [BugEntityManager] Cleared all entities")
    }
}

// MARK: - Custom Component

/// Custom component to track bug association
struct BugEntityComponent: Component {
    let bugId: UUID
    let creationTime: Date = Date()
}

// MARK: - Performance Metrics

/// Performance tracking for bug entity management
struct BugEntityPerformanceMetrics {
    var totalManagedEntities: Int = 0
    var totalBugsInSimulation: Int = 0
    var lastUpdateDuration: TimeInterval = 0.0
    var lastUpdateStartTime: TimeInterval = 0.0
    var entitiesCreated: Int = 0
    var entitiesDestroyed: Int = 0
    var optimizationsApplied: Int = 0
    
    var averageUpdateTime: TimeInterval {
        // Could track running average
        return lastUpdateDuration
    }
    
    var isPerformanceOptimal: Bool {
        return lastUpdateDuration < 0.016 // 60 FPS target
    }
}
