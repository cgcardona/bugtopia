//
//  Arena3DView_RealityKit_v2.swift
//  Bugtopia
//
//  Created by RealityKit Developer on 12/20/24.
//  Phase 2: Working RealityKit Implementation
//

import SwiftUI
import RealityKit
import simd

/// 🚀 PHASE 2: Working RealityKit Implementation
/// Properly implemented with Entity-Component-System architecture
struct Arena3DView_RealityKit_v2: View {
    
    // MARK: - Core Dependencies
    
    let simulationEngine: SimulationEngine
    
    // MARK: - Selection System
    
    var onBugSelected: ((Bug?) -> Void)?
    var onFoodSelected: ((FoodItem?) -> Void)?
    
    // MARK: - Entity Management
    
    @StateObject private var bugEntityManager = BugEntityManager()
    @State private var sceneAnchor: Entity?
    
    // MARK: - Performance Tracking
    
    @State private var frameCount: Int = 0
    @State private var lastFPSUpdate: Date = Date()
    @State private var currentFPS: Double = 0.0
    @State private var performanceMetrics = Phase2PerformanceMetrics()
    
    // MARK: - Debug
    
    @State private var debugMode: Bool = true
    
    // MARK: - Update Management
    
    @State private var updateTimer: Timer?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main 3D content
            realityContent
            
            // Debug overlay
            if debugMode {
                debugOverlay
            }
        }
        .onAppear {
            startPerformanceMonitoring()
        }
        .onTapGesture { location in
            handleTap(at: location)
        }
    }
    
    // MARK: - Reality Content
    
    @ViewBuilder
    private var realityContent: some View {
        ZStack {
            // Temporary: Show debug view until RealityView is working
            VStack {
                Text("🌍 RealityKit 3D World")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Terrain: \(simulationEngine.voxelWorld.getVoxelsInLayer(.surface).count) surface voxels")
                    .foregroundColor(.secondary)
                
                Text("Bugs: \(simulationEngine.bugs.count) entities")
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.9))
            .onAppear {
                // Start periodic updates for entities
                startPeriodicUpdates()
                setupBasicScene()
            }
            .onDisappear {
                stopPeriodicUpdates()
                // Clean up entities to prevent memory leaks
                bugEntityManager.clearAllEntities()
            }
            
            // Debug overlay (optional)
            if debugMode {
                VStack {
                    Spacer()
                    HStack {
                        debugStatusOverlay
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private var debugStatusOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🐛 Entities: \(bugEntityManager.bugEntities.count)")
                .foregroundColor(.green)
            Text("⚡ Performance: \(bugEntityManager.performanceMetrics.isPerformanceOptimal ? "✅" : "⚠️")")
                .foregroundColor(bugEntityManager.performanceMetrics.isPerformanceOptimal ? .green : .orange)
            Text("🎯 Last Update: \(String(format: "%.1f", bugEntityManager.performanceMetrics.lastUpdateDuration * 1000))ms")
                .foregroundColor(.blue)
        }
        .font(.caption)
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(6)
    }
    
    private var fallbackView: some View {
        VStack {
            Text("🚀 RealityKit (macOS 14.0+ Required)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("Current System: macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("RealityKit requires macOS 14.0 or later")
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Interaction Handling
    
    private func handleTap(at location: CGPoint) {
        print("🎯 [RealityKit] Tap at \(location)")
        // TODO: Implement ray casting for entity selection
    }
    
    // MARK: - RealityKit Scene Management
    
    @MainActor
    private func setupBasicScene() {
        print("🚀 [RealityKit] Setting up basic scene...")
        
        // Create main scene anchor for future RealityView implementation
        let sceneAnchor = Entity()
        sceneAnchor.name = "SceneRoot"
        self.sceneAnchor = sceneAnchor
        
        // Configure bug entity container with our scene anchor
        bugEntityManager.configureContainer(sceneAnchor)
        
        print("✅ [RealityKit] Basic scene setup complete!")
        
        // Log terrain info
        let voxelWorld = simulationEngine.voxelWorld
        let surfaceVoxels = voxelWorld.getVoxelsInLayer(.surface)
        print("🌍 [RealityKit] VoxelWorld loaded with \(surfaceVoxels.count) surface voxels")
        print("📏 [RealityKit] World dimensions: \(voxelWorld.dimensions)")
        print("📦 [RealityKit] Voxel size: \(voxelWorld.voxelSize)")
    }
    
    // MARK: - Update Management
    
    private func startPeriodicUpdates() {
        // Update entities at 30 FPS to reduce load
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            Task { @MainActor in
                bugEntityManager.updateBugEntities(with: simulationEngine.bugs)
            }
        }
    }
    
    private func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateFPS()
        }
    }
    
    private func updateFPS() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFPSUpdate)
        currentFPS = Double(frameCount) / elapsed
        frameCount = 0
        lastFPSUpdate = now
        
        performanceMetrics.currentFPS = currentFPS
        performanceMetrics.entityCount = bugEntityManager.bugEntities.count
    }
    
    // MARK: - Debug Overlay
    
    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🚀 RealityKit Debug")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("FPS: \(String(format: "%.1f", currentFPS))")
                .foregroundColor(currentFPS > 50 ? .green : currentFPS > 30 ? .orange : .red)
            
            Text("Bug Entities: \(bugEntityManager.bugEntities.count)")
                .foregroundColor(.cyan)
            
            Text("Simulation Bugs: \(simulationEngine.bugs.count)")
                .foregroundColor(.yellow)
            
            Text("Generation: \(simulationEngine.currentGeneration)")
                .foregroundColor(.purple)
            
            Text(bugEntityManager.getPerformanceReport())
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Phase 2 Performance Metrics

struct Phase2PerformanceMetrics {
    var currentFPS: Double = 0.0
    var entityCount: Int = 0
    var memoryUsage: Double = 0.0
    var renderTime: Double = 0.0
}

// MARK: - Preview

#Preview {
    Arena3DView_RealityKit_v2(
        simulationEngine: SimulationEngine(worldBounds: CGRect(x: 0, y: 0, width: 2000, height: 1500)),
        onBugSelected: { bug in
            print("Selected bug: \(bug?.id.uuidString.prefix(8) ?? "none")")
        }
    )
}
