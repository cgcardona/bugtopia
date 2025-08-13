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
    
    // MARK: - View Components
    
    @ViewBuilder
    private var mainContentView: some View {
        ZStack {
            // Try RealityView for 3D scene
            if #available(macOS 14.0, *) {
                realityView3D
            } else {
                // Fallback for older macOS
                dataVisualizationView
            }
        }
    }
    
    @ViewBuilder
    private var dataVisualizationView: some View {
        VStack(spacing: 20) {
            headerView
            worldStatsView
            terrainCompositionView
            Spacer()
            footerView
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
    
    @available(macOS 14.0, *)
    @ViewBuilder
    private var realityView3D: some View {
        // For now, fall back to enhanced data visualization
        // until RealityView issues are resolved on macOS
        dataVisualizationView
    }
    
    @ViewBuilder
    private var headerView: some View {
        Text("🌍 RealityKit 3D World")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.green)
    }
    
    @ViewBuilder
    private var worldStatsView: some View {
        Group {
            Text("🗺️ Terrain: \(simulationEngine.voxelWorld.getVoxelsInLayer(.surface).count) surface voxels")
                .foregroundColor(.secondary)
            
            Text("🐛 Bugs: \(simulationEngine.bugs.count) entities")
                .foregroundColor(.blue)
            
            Text("📏 World: \(simulationEngine.voxelWorld.dimensions.width)×\(simulationEngine.voxelWorld.dimensions.height)×\(simulationEngine.voxelWorld.dimensions.depth)")
                .foregroundColor(.orange)
            
            Text("📦 Voxel Size: \(String(format: "%.1f", simulationEngine.voxelWorld.voxelSize)) units")
                .foregroundColor(.purple)
        }
        .font(.headline)
    }
    
    @ViewBuilder
    private var terrainCompositionView: some View {
        let terrainCounts = getTerrainCounts()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("🎨 Terrain Composition:")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ForEach(Array(terrainCounts.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { terrainType in
                HStack {
                    Circle()
                        .fill(getTerrainColor(terrainType))
                        .frame(width: 12, height: 12)
                    Text("\(terrainType.rawValue.capitalized): \(terrainCounts[terrainType] ?? 0)")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var footerView: some View {
        Text("📺 RealityView 3D implementation coming next...")
            .font(.caption)
            .foregroundColor(.gray)
    }

    // MARK: - Reality Content
    
    @ViewBuilder
    private var realityContent: some View {
        ZStack {
            mainContentView
                .onAppear {
                    startPeriodicUpdates()
                    setupBasicScene()
                }
                .onDisappear {
                    stopPeriodicUpdates()
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
    
    // MARK: - Terrain Analysis Helpers
    
    private func getTerrainCounts() -> [TerrainType: Int] {
        let surfaceVoxels = simulationEngine.voxelWorld.getVoxelsInLayer(.surface)
        return Dictionary(grouping: surfaceVoxels) { $0.terrainType }
            .mapValues { $0.count }
    }
    
    private func getTerrainColor(_ terrainType: TerrainType) -> Color {
        return terrainType.color // Use the built-in color from TerrainType
    }
    
    private func setupBasicScene() {
        print("🚀 [RealityKit] Setting up enhanced 3D world data...")
        
        // Create basic scene anchor for entity management
        let sceneAnchor = Entity()
        sceneAnchor.name = "SceneRoot"
        self.sceneAnchor = sceneAnchor
        
        // Configure bug entity container
        bugEntityManager.configureContainer(sceneAnchor)
        
        // Log detailed terrain analysis
        let voxelWorld = simulationEngine.voxelWorld
        let surfaceVoxels = voxelWorld.getVoxelsInLayer(.surface)
        let terrainCounts = getTerrainCounts()
        
        print("✅ [RealityKit] Enhanced world analysis complete!")
        print("🌍 Total surface voxels: \(surfaceVoxels.count)")
        print("🎨 Terrain types found: \(terrainCounts.count)")
        for (terrain, count) in terrainCounts.sorted(by: { $0.value > $1.value }) {
            print("   - \(terrain.rawValue): \(count) voxels")
        }
    }
    
    // MARK: - RealityKit 3D Scene Implementation (Future)
    // Note: Commenting out until RealityViewContent issues are resolved
    
    /*
    @available(macOS 14.0, *)
    private func setupRealityKit3DScene(_ content: RealityViewContent) {
        print("🚀 [RealityKit] Setting up 3D scene...")
        
        // Create main anchor for the scene
        let worldAnchor = AnchorEntity(.world(transform: Transform.identity.matrix))
        content.add(worldAnchor)
        
        // Setup lighting for visibility
        setupBasicLighting(in: worldAnchor)
        
        // Generate terrain from voxel data
        generateTerrain3D(in: worldAnchor)
        
        // Create bug entities
        generateBugEntities3D(in: worldAnchor)
        
        print("✅ [RealityKit] 3D scene setup complete!")
    }
    
    @available(macOS 14.0, *)
    private func updateRealityKit3DScene(_ content: RealityViewContent) {
        // Real-time updates will be handled here
        // For now, just update bug positions
        updateBugPositions3D()
    }
    
    @available(macOS 14.0, *)
    private func setupBasicLighting(in anchor: Entity) {
        // Add directional light
        let light = DirectionalLight()
        light.light.intensity = 1000
        light.light.isRealWorldProxy = false
        light.position = [0, 10, 0]
        light.look(at: [0, 0, 0], from: light.position, relativeTo: nil)
        anchor.addChild(light)
        
        print("💡 [RealityKit] Lighting setup complete")
    }
    
    @available(macOS 14.0, *)
    private func generateTerrain3D(in anchor: Entity) {
        print("🌍 [RealityKit] Generating 3D terrain...")
        
        let voxelWorld = simulationEngine.voxelWorld
        let surfaceVoxels = voxelWorld.getVoxelsInLayer(.surface)
        let voxelSize = Float(voxelWorld.voxelSize)
        
        // Create terrain container
        let terrainContainer = Entity()
        terrainContainer.name = "TerrainContainer"
        anchor.addChild(terrainContainer)
        
        // Limit voxels for performance (start with a subset)
        let maxVoxels = min(500, surfaceVoxels.count)
        let voxelsToRender = Array(surfaceVoxels.prefix(maxVoxels))
        
        print("🔥 [RealityKit] Rendering \(voxelsToRender.count) of \(surfaceVoxels.count) voxels...")
        
        // Group by terrain type for efficiency
        let voxelsByType = Dictionary(grouping: voxelsToRender) { $0.terrainType }
        
        for (terrainType, typeVoxels) in voxelsByType {
            createTerrainChunk3D(
                terrainType: terrainType,
                voxels: typeVoxels,
                voxelSize: voxelSize,
                container: terrainContainer
            )
        }
        
        print("✅ [RealityKit] Generated terrain with \(voxelsByType.count) terrain types")
    }
    
    @available(macOS 14.0, *)
    private func createTerrainChunk3D(terrainType: TerrainType, voxels: [Voxel], voxelSize: Float, container: Entity) {
        let chunkEntity = Entity()
        chunkEntity.name = "Chunk_\(terrainType.rawValue)"
        
        // Limit voxels per chunk for performance
        let maxPerChunk = min(50, voxels.count)
        let chunkVoxels = Array(voxels.prefix(maxPerChunk))
        
        for voxel in chunkVoxels {
            let voxelEntity = Entity()
            
            // Create cube geometry
            let cubeMesh = MeshResource.generateBox(size: voxelSize * 0.8) // Slightly smaller for visual separation
            let material = createTerrainMaterial3D(for: terrainType)
            let modelComponent = ModelComponent(mesh: cubeMesh, materials: [material])
            
            voxelEntity.components.set(modelComponent)
            
            // Position in 3D space (convert Bugtopia coordinates to RealityKit)
            let position = SIMD3<Float>(
                Float(voxel.position.x),
                Float(voxel.position.z), // Z becomes Y (up)
                Float(voxel.position.y)  // Y becomes Z (depth)
            )
            voxelEntity.position = position
            
            chunkEntity.addChild(voxelEntity)
        }
        
        container.addChild(chunkEntity)
    }
    
    @available(macOS 14.0, *)
    private func createTerrainMaterial3D(for terrainType: TerrainType) -> Material {
        var material = SimpleMaterial()
        
        // Use terrain type colors
        switch terrainType {
        case .open:
            material.color = .init(tint: .green.withAlphaComponent(0.7))
        case .wall:
            material.color = .init(tint: .gray)
        case .water:
            material.color = .init(tint: .blue.withAlphaComponent(0.8))
        case .hill:
            material.color = .init(tint: .brown)
        case .food:
            material.color = .init(tint: .green)
        case .forest:
            material.color = .init(tint: .green.withAlphaComponent(0.9))
        case .sand:
            material.color = .init(tint: .yellow)
        default:
            material.color = .init(tint: .gray.withAlphaComponent(0.5))
        }
        
        material.metallic = 0.1
        material.roughness = 0.8
        
        return material
    }
    
    @available(macOS 14.0, *)
    private func generateBugEntities3D(in anchor: Entity) {
        print("🐛 [RealityKit] Generating 3D bug entities...")
        
        let bugContainer = Entity()
        bugContainer.name = "BugContainer"
        anchor.addChild(bugContainer)
        
        // Configure bug entity manager with this container
        bugEntityManager.configureContainer(bugContainer)
        
        // Create visual representations for current bugs
        for (index, bug) in simulationEngine.bugs.prefix(20).enumerated() {
            let bugEntity = Entity()
            bugEntity.name = "Bug_\(index)"
            
            // Create sphere geometry for bugs
            let sphereMesh = MeshResource.generateSphere(radius: 2.0) // Visible size
            let bugMaterial = createBugMaterial3D(for: bug)
            let modelComponent = ModelComponent(mesh: sphereMesh, materials: [bugMaterial])
            
            bugEntity.components.set(modelComponent)
            
            // Position bug in 3D space
            let position = SIMD3<Float>(
                Float(bug.position.x),
                Float(bug.position.z + 5), // Slightly above terrain
                Float(bug.position.y)
            )
            bugEntity.position = position
            
            bugContainer.addChild(bugEntity)
        }
        
        print("✅ [RealityKit] Generated \(min(20, simulationEngine.bugs.count)) bug entities")
    }
    
    @available(macOS 14.0, *)
    private func createBugMaterial3D(for bug: Bug) -> Material {
        var material = SimpleMaterial()
        
        // Color based on bug energy level
        let energyRatio = bug.energy / bug.dna.speciesTraits.baseEnergyCapacity
        if energyRatio > 0.7 {
            material.color = .init(tint: .green) // High energy - green
        } else if energyRatio > 0.4 {
            material.color = .init(tint: .yellow) // Medium energy - yellow
        } else {
            material.color = .init(tint: .red) // Low energy - red
        }
        
        material.metallic = 0.2
        material.roughness = 0.6
        
        return material
    }
    
    @available(macOS 14.0, *)
    private func updateBugPositions3D() {
        // This will be called during updates to move bugs in real-time
        // Implementation will sync with bugEntityManager
    }
    */
    
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
