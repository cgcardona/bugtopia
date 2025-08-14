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
import CoreGraphics

// 🎮 SIMPLIFIED: No complex navigation enums needed

/// 🚀 PHASE 2: Working RealityKit Implementation
/// Properly implemented with Entity-Component-System architecture
struct Arena3DView_RealityKit_v2: View {
    
    // MARK: - Core Dependencies
    
    let simulationEngine: SimulationEngine
    
    // MARK: - Simplified Navigation System
    
    @State private var pressedKeys: Set<UInt16> = []
    @State private var lastUpdateTime = CACurrentMediaTime()
    @State private var movementSpeed: Float = 50.0  // ⚡ SIMPLIFIED: Basic movement speed
    @State private var sceneAnchor: AnchorEntity?
    @State private var cameraPosition = SIMD3<Float>(0, 10, 0)  // 📷 SIMPLIFIED: Basic camera position
    @State private var cameraPitch: Float = 0.0  // 🎮 TRACKPAD: Up/down look angle (pitch)
    @State private var cameraYaw: Float = 0.0    // 🎮 TRACKPAD: Left/right look angle (yaw)
    
    // MARK: - Selection System
    
    var onBugSelected: ((Bug?) -> Void)?
    var onFoodSelected: ((FoodItem?) -> Void)?
    
    // MARK: - Entity Management
    
    @StateObject private var bugEntityManager = BugEntityManager()
    
    // MARK: - Performance Tracking
    
    @State private var frameCount: Int = 0
    @State private var lastFPSUpdate: Date = Date()
    @State private var currentFPS: Double = 0.0
    @State private var performanceMetrics = Phase2PerformanceMetrics()
    
    // MARK: - Camera Navigation (legacy - removed duplicates)
    
    // MARK: - Debug
    
    @State private var debugMode: Bool = true
    
    // MARK: - Update Management
    
    @State private var updateTimer: Timer?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main 3D content
            mainContentView
            
            // Debug overlay
            if debugMode {
                debugOverlay
            }
        }
        .onAppear {
            startPerformanceMonitoring()
            print("🚀 [RealityKit] View appeared, FPS monitoring enabled")
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
        // RealityKit 3D Scene with proper FPS tracking
        RealityView { content in
            setupHelloWorldScene(content)
        } update: { content in
            // Track frame rendering for FPS calculation
            DispatchQueue.main.async {
                frameCount += 1
            }
            
            // Update bug positions based on simulation
            updateBugPositions()
        }
        // 🎮 TWO-FINGER ONLY: Using scroll wheel events, no single-finger drag needed
        .onAppear {
            startNavigationUpdates()
            setupKeyboardMonitoring()
        }
        .onDisappear {
            stopKeyboardMonitoring()
        }
        .overlay(alignment: .bottomTrailing) {
            // Simple overlay to confirm RealityView is active
            Text("🌍 RealityKit Active")
                .font(.caption)
                .foregroundColor(.green)
                .padding(4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .padding()
        }
    }
    
    @available(macOS 14.0, *)
    private func setupHelloWorldScene(_ content: any RealityViewContentProtocol) {
        print("🚀 [RealityKit] BUILDING BUGTOPIA WORLD...")
        
        // Create scene anchor positioned like SceneKit camera view
        let anchor = AnchorEntity(.world(transform: Transform.identity.matrix))
        
        // Position the world anchor for optimal viewing
        anchor.transform.translation = [0, -5, -8]  // Lower and further away for better overview
        
        // Store reference for camera manipulation
        sceneAnchor = anchor
        
        // 1. Add skybox background (far away)
        setupSkybox(in: anchor)
        
        // 2. Add ground plane foundation
        setupGroundPlane(in: anchor)
        
        // 3. Add terrain voxels on top of ground
        addSimulationTerrain(in: anchor)
        
        // 4. Add lighting for proper visibility
        setupWorldLighting(in: anchor)
        
        // 5. Add bug entities
        addBugEntities(in: anchor)
        
        // Add to scene
        content.add(anchor)
        
        print("✅ [RealityKit] Bugtopia world created with proper structure")
    }
    
    @available(macOS 14.0, *)
    private func setupTestLighting(in anchor: Entity) {
        // Strong directional light from above-right
        let sunLight = DirectionalLight()
        sunLight.light.intensity = 2000
        sunLight.position = [5, 10, 5]
        sunLight.look(at: [0, 0, -3], from: sunLight.position, relativeTo: nil)
        anchor.addChild(sunLight)
        
        // Ambient light for fill
        let ambientLight = DirectionalLight()
        ambientLight.light.intensity = 500
        ambientLight.position = [-5, 5, 5]
        ambientLight.look(at: [0, 0, -3], from: ambientLight.position, relativeTo: nil)
        anchor.addChild(ambientLight)
        
        print("💡 [RealityKit] Strong lighting setup complete")
    }
    
    @available(macOS 14.0, *)
    private func addTestObjects(to anchor: Entity) {
        // Red cube (center) - Enhanced material
        var redMaterial = SimpleMaterial()
        redMaterial.color = .init(tint: .red)
        redMaterial.metallic = 0.1
        redMaterial.roughness = 0.3
        
        let redCube = ModelEntity(
            mesh: .generateBox(size: 1.0),
            materials: [redMaterial]
        )
        redCube.position = [0, 0, -4]
        anchor.addChild(redCube)
        
        // Green sphere (left)
        let greenSphere = ModelEntity(
            mesh: .generateSphere(radius: 0.8),
            materials: [SimpleMaterial(color: .green, isMetallic: false)]
        )
        greenSphere.position = [-3, 0, -4]
        anchor.addChild(greenSphere)
        
        // Blue cylinder (right)
        let blueCylinder = ModelEntity(
            mesh: .generateCylinder(height: 1.5, radius: 0.5),
            materials: [SimpleMaterial(color: .blue, isMetallic: false)]
        )
        blueCylinder.position = [3, 0, -4]
        anchor.addChild(blueCylinder)
        
        // Yellow pyramid (closer)
        let yellowBox = ModelEntity(
            mesh: .generateBox(size: 0.8),
            materials: [SimpleMaterial(color: .yellow, isMetallic: false)]
        )
        yellowBox.position = [0, 1.5, -3]
        // Rotate to make it diamond-like
        yellowBox.orientation = simd_quatf(angle: .pi/4, axis: [1, 1, 0])
        anchor.addChild(yellowBox)
        
        print("🎨 [RealityKit] Added 4 test objects with strong colors")
    }
    
    @available(macOS 14.0, *)
    private func setupSkybox(in anchor: Entity) {
        print("🌌 [RealityKit] Setting up skybox...")
        
        // Get current world type from simulation
        let worldType = simulationEngine.voxelWorld.worldType
        let skyboxImageName = getSkyboxImageName(for: worldType)
        
        print("🌍 [RealityKit] World type: \(worldType), skybox: \(skyboxImageName)")
        
        // Create skybox material with actual texture
        var skyboxMaterial: SimpleMaterial
        
        // Try to load the actual skybox texture from Assets.xcassets (macOS)
        if let skyboxImage = NSImage(named: skyboxImageName),
           let cgImage = skyboxImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            print("✅ [RealityKit] Loaded skybox texture: \(skyboxImageName)")
            
            // Create texture resource from CGImage
            do {
                let textureResource = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
                skyboxMaterial = SimpleMaterial()
                skyboxMaterial.color = .init(texture: .init(textureResource))
                skyboxMaterial.roughness = 1.0
            } catch {
                print("⚠️ [RealityKit] Failed to create texture resource: \(error)")
                skyboxMaterial = SimpleMaterial(color: getSkyboxFallbackColor(for: worldType), isMetallic: false)
            }
        } else {
            print("⚠️ [RealityKit] Could not load skybox image: \(skyboxImageName), using fallback color")
            skyboxMaterial = SimpleMaterial(color: getSkyboxFallbackColor(for: worldType), isMetallic: false)
        }
        
        // Create a much larger skybox to prevent seeing it when zooming out
        let backgroundSphere = ModelEntity(
            mesh: .generateSphere(radius: 2000), // 🔧 FIXED: Much larger radius to prevent seeing edges
            materials: [skyboxMaterial]
        )
        
        // Invert normals to see from inside and center at origin
        backgroundSphere.scale = [-1, 1, 1]
        backgroundSphere.position = [0, 0, 0]  // 🔧 FIXED: Center at origin for better coverage
        
        anchor.addChild(backgroundSphere)
        print("✅ [RealityKit] Positioned skybox sphere for \(worldType) (radius: 2000, centered at origin)")
    }
    
    @available(macOS 14.0, *)
    private func setupGroundPlane(in anchor: Entity) {
        print("🌍 [RealityKit] Creating smooth navigable terrain...")
        
        let voxelWorld = simulationEngine.voxelWorld
        let heightMap = voxelWorld.heightMap
        let biomeMap = voxelWorld.biomeMap
        let resolution = heightMap.count
        
        print("📊 [RealityKit] Processing \(resolution)x\(resolution) height map for smooth terrain")
        
        // Create main terrain container
        let terrainContainer = Entity()
        terrainContainer.name = "SmoothTerrainContainer"
        terrainContainer.position = [0, 0, 0]
        
        // Create smooth terrain mesh from height map
        let smoothTerrain = createSmoothTerrainMesh(heightMap: heightMap, biomeMap: biomeMap, resolution: resolution)
        terrainContainer.addChild(smoothTerrain)
        
        // Add water surfaces for areas below water level
        let waterSurfaces = createWaterSurfaces(heightMap: heightMap, resolution: resolution)
        terrainContainer.addChild(waterSurfaces)
        
        anchor.addChild(terrainContainer)
        print("✅ [RealityKit] Smooth navigable terrain created for bug movement")
    }
    
    @available(macOS 14.0, *)
    private func createSmoothTerrainMesh(heightMap: [[Double]], biomeMap: [[BiomeType]], resolution: Int) -> ModelEntity {
        // Create a single smooth terrain mesh using height map data
        let scale: Float = 2.0  // 🌍 FIXED: Full-scale world (was 0.5, too small)
        let heightScale: Float = 1.0  // 🏔️ FIXED: Natural height scale (was 0.15, too compressed)
        
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        // Generate vertices from height map
        for x in 0..<resolution {
            for z in 0..<resolution {
                let worldX = Float(x - resolution/2) * scale
                let worldZ = Float(z - resolution/2) * scale
                let worldY = Float(heightMap[x][z]) * heightScale
                
                vertices.append(SIMD3<Float>(worldX, worldY, worldZ))
            }
        }
        
        // Generate triangle indices for the mesh
        for x in 0..<(resolution-1) {
            for z in 0..<(resolution-1) {
                let bottomLeft = UInt32(x * resolution + z)
                let bottomRight = UInt32(x * resolution + z + 1)
                let topLeft = UInt32((x + 1) * resolution + z)
                let topRight = UInt32((x + 1) * resolution + z + 1)
                
                // First triangle (bottom-left, top-left, bottom-right)
                indices.append(bottomLeft)
                indices.append(topLeft)
                indices.append(bottomRight)
                
                // Second triangle (bottom-right, top-left, top-right)
                indices.append(bottomRight)
                indices.append(topLeft)
                indices.append(topRight)
            }
        }
        
        // Create mesh resource
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffer(vertices)
        meshDescriptor.primitives = .triangles(indices)
        
        let terrainMesh = try! MeshResource.generate(from: [meshDescriptor])
        
        // Create material based on dominant biome
        let dominantBiome = findDominantBiome(biomeMap: biomeMap)
        let terrainMaterial = createTerrainMaterial(for: dominantBiome)
        
        let terrainEntity = ModelEntity(mesh: terrainMesh, materials: [terrainMaterial])
        terrainEntity.name = "SmoothTerrain"
        
        return terrainEntity
    }
    
    @available(macOS 14.0, *)
    private func createWaterSurfaces(heightMap: [[Double]], resolution: Int) -> Entity {
        let waterContainer = Entity()
        waterContainer.name = "WaterSurfaces"
        
        let scale: Float = 2.0  // 🌊 FIXED: Match terrain scale
        let waterLevel: Double = -5.0  // Water level threshold
        
        // Find water areas and create smooth water planes
        var waterAreas: [[Bool]] = Array(repeating: Array(repeating: false, count: resolution), count: resolution)
        
        for x in 0..<resolution {
            for z in 0..<resolution {
                if heightMap[x][z] < waterLevel {
                    waterAreas[x][z] = true
                }
            }
        }
        
        // Create water plane at water level
        let waterSize = Float(resolution) * scale
        let waterMesh = MeshResource.generatePlane(width: waterSize, depth: waterSize)
        let waterMaterial = createWaterMaterial(height: waterLevel)
        
        let waterEntity = ModelEntity(mesh: waterMesh, materials: [waterMaterial])
        waterEntity.position = [0, Float(waterLevel) * 0.15, 0]  // Position at water level
        waterEntity.name = "WaterPlane"
        
        waterContainer.addChild(waterEntity)
        
        return waterContainer
    }
    
    @available(macOS 14.0, *)
    private func findDominantBiome(biomeMap: [[BiomeType]]) -> BiomeType {
        var biomeCounts: [BiomeType: Int] = [:]
        
        for row in biomeMap {
            for biome in row {
                biomeCounts[biome, default: 0] += 1
            }
        }
        
        return biomeCounts.max(by: { $0.value < $1.value })?.key ?? .temperateForest
    }
    
    @available(macOS 14.0, *)
    private func createTerrainMaterial(for biome: BiomeType) -> SimpleMaterial {
        let biomeColor = getBiomeColor(biome: biome)
        var material = SimpleMaterial(color: biomeColor, isMetallic: false)
        material.roughness = 0.8  // Natural terrain roughness
        return material
    }
    
    @available(macOS 14.0, *)
    private func createBiomeTerrainPatch(height: Double, biome: BiomeType, position: SIMD3<Float>) -> ModelEntity {
        // Determine terrain patch size and color based on height and biome
        let patchSize: Float
        let terrainColor: NSColor
        let isWater = height < -5  // Anything below -5m is water
        
        // Height-based terrain colors (matching SceneKit implementation)
        if height < -20 {
            terrainColor = NSColor.blue  // Deep water
            patchSize = 2.0  // Larger water patches
        } else if height < -5 {
            terrainColor = NSColor.cyan  // Wetlands/shallow water
            patchSize = 2.0  // Larger water patches
        } else if height > 5 && height < 25 {
            terrainColor = getBiomeColor(biome: biome)  // Biome-specific colors
            patchSize = 1.0
        } else if height > 30 {
            terrainColor = NSColor.gray  // Mountains
            patchSize = 1.2
        } else if height > 15 {
            terrainColor = NSColor.brown  // Hills
            patchSize = 1.0
        } else {
            terrainColor = getBiomeColor(biome: biome)  // Plains with biome colors
            patchSize = 1.0
        }
        
        // Create mesh based on height type
        let mesh: MeshResource
        if isWater {
            // Create smooth water surface with plane geometry
            mesh = .generatePlane(width: patchSize, depth: patchSize)
        } else if height > 15 {
            // Use taller boxes for hills and mountains
            mesh = .generateBox(width: patchSize, height: patchSize * 1.5, depth: patchSize)
        } else {
            // Use flatter boxes for plains
            mesh = .generateBox(width: patchSize, height: patchSize * 0.5, depth: patchSize)
        }
        
        // Create appropriate material for water vs land
        let material: SimpleMaterial
        if isWater {
            material = createWaterMaterial(height: height)
        } else {
            material = SimpleMaterial(color: terrainColor, isMetallic: false)
        }
        
        let terrainPatch = ModelEntity(mesh: mesh, materials: [material])
        terrainPatch.position = position
        
        return terrainPatch
    }
    
    @available(macOS 14.0, *)
    private func createWaterMaterial(height: Double) -> SimpleMaterial {
        var waterMaterial = SimpleMaterial()
        
        // Water color based on depth (deeper = darker blue)
        let waterDepth = abs(height + 5) / 15.0  // Normalize depth (0-1)
        let blueIntensity = 0.3 + (waterDepth * 0.7)  // Deeper water is more blue
        
        let waterColor = NSColor(
            red: 0.0,
            green: 0.3 + (waterDepth * 0.2),  // Slight green tint in shallow water
            blue: blueIntensity,
            alpha: 0.7  // Semi-transparent for water effect
        )
        
        waterMaterial.color = .init(tint: waterColor)
        waterMaterial.roughness = 0.1  // Very smooth water surface
        waterMaterial.metallic = 0.8   // Reflective like water
        
        return waterMaterial
    }
    
    @available(macOS 14.0, *)
    private func getBiomeColor(biome: BiomeType) -> NSColor {
        // Biome colors matching the SceneKit implementation
        switch biome {
        case .tundra: return NSColor.white
        case .borealForest: return NSColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)  // Dark green
        case .temperateForest: return NSColor.green
        case .temperateGrassland: return NSColor(red: 0.6, green: 0.8, blue: 0.2, alpha: 1.0)  // Light green
        case .desert: return NSColor.orange
        case .savanna: return NSColor.brown
        case .tropicalRainforest: return NSColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)  // Forest green
        case .wetlands: return NSColor.cyan
        case .alpine: return NSColor.lightGray
        case .coastal: return NSColor.blue
        }
    }
    
    @available(macOS 14.0, *)
    private func setupWorldLighting(in anchor: Entity) {
        // Soft sunlight from above
        let sunLight = DirectionalLight()
        sunLight.light.intensity = 1500  // Increased for better visibility
        sunLight.position = [0, 20, 10]
        sunLight.look(at: [0, 0, 0], from: sunLight.position, relativeTo: nil)
        anchor.addChild(sunLight)
        
        print("☀️ [RealityKit] World lighting added")
    }
    
    @available(macOS 14.0, *)
    private func addSimulationTerrain(in anchor: Entity) {
        print("🏔️ [RealityKit] Adding terrain from simulation...")
        
        let voxelWorld = simulationEngine.voxelWorld
        let surfaceVoxels = voxelWorld.getVoxelsInLayer(.surface)
        
        print("📊 [RealityKit] Processing \(surfaceVoxels.count) surface voxels")
        
        // Create terrain container positioned on the ground
        let terrainContainer = Entity()
        terrainContainer.name = "TerrainContainer"
        terrainContainer.position = [0, 0.5, 0]  // Slightly above the ground plane
        
        // Group voxels by terrain type for better performance
        var terrainGroups: [TerrainType: [Voxel]] = [:]
        for voxel in surfaceVoxels {
            terrainGroups[voxel.terrainType, default: []].append(voxel)
        }
        
        // Create a more structured terrain layout
        for (terrainType, voxels) in terrainGroups {
            let terrainGroup = Entity()
            terrainGroup.name = "Terrain_\(terrainType)"
            
            let material = createTerrainMaterial(for: terrainType)
            
            // Create fewer, larger voxel entities for better performance and visibility
            let maxVoxels = min(8, voxels.count)  // Fewer voxels for cleaner view
            for (index, _) in voxels.prefix(maxVoxels).enumerated() {
                let voxelEntity = ModelEntity(
                    mesh: .generateBox(size: 1.5),  // Moderate size voxels
                    materials: [material]
                )
                
                // Arrange voxels in a grid pattern above the ground
                let gridSize = 3
                let spacing: Float = 2.5
                let row = index / gridSize
                let col = index % gridSize
                
                let worldX = Float(col - gridSize/2) * spacing
                let worldZ = Float(row - gridSize/2) * spacing
                let worldY: Float = 0.0  // On the ground level
                
                voxelEntity.position = [worldX, worldY, worldZ]
                terrainGroup.addChild(voxelEntity)
            }
            
            terrainContainer.addChild(terrainGroup)
            print("🎨 [RealityKit] Added \(maxVoxels) \(terrainType) voxels in grid")
        }
        
        anchor.addChild(terrainContainer)
        print("✅ [RealityKit] Terrain generation complete")
    }
    
    @available(macOS 14.0, *)
    private func createTerrainMaterial(for terrainType: TerrainType) -> RealityKit.Material {
        var material = SimpleMaterial()
        
        switch terrainType {
        case .forest:
            material.color = .init(tint: .green)
        case .hill:
            material.color = .init(tint: .brown)
        case .wall:
            material.color = .init(tint: .gray)
        case .water:
            material.color = .init(tint: .blue)
        case .sand:
            material.color = .init(tint: .yellow)
        case .food:
            material.color = .init(tint: .orange)
        case .ice:
            material.color = .init(tint: .cyan)
        case .swamp:
            material.color = .init(tint: NSColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0))
        default:
            material.color = .init(tint: .white)
        }
        
        material.metallic = 0.1
        material.roughness = 0.8
        
        return material
    }
    
    private func getSkyboxImageName(for worldType: WorldType3D) -> String {
        switch worldType {
        case .abyss3D:
            return "abyss-skybox"
        case .archipelago3D:
            return "archipelago-skybox"
        case .canyon3D:
            return "canyon-skybox"
        case .cavern3D:
            return "cavern-skybox"
        case .continental3D:
            return "continental-skybox"
        case .skylands3D:
            return "skylands-skybox"
        case .volcano3D:
            return "volcano-skybox"
        default:
            return "epic-skybox-panorama" // Default fallback
        }
    }
    
        private func getSkyboxFallbackColor(for worldType: WorldType3D) -> NSColor {
        switch worldType {
        case .abyss3D:
            return .black
        case .archipelago3D:
            return .blue
        case .canyon3D:
            return .orange
        case .cavern3D:
            return .darkGray
        case .continental3D:
            return .green
        case .skylands3D:
            return .cyan
        case .volcano3D:
            return .red
        default:
            return .blue
        }
    }
    
    @available(macOS 14.0, *)
    private func addBugEntities(in anchor: Entity) {
        print("🐛 [RealityKit] Adding bug entities...")
        
        // Create bug container
        let bugContainer = Entity()
        bugContainer.name = "BugContainer"
        bugContainer.position = [0, 0, 0]  // Same level as terrain
        
        // Add more bugs from the simulation (scale up from 5 to 15+)
        let bugsToShow = Array(simulationEngine.bugs.prefix(15))
        
        for (index, bug) in bugsToShow.enumerated() {
            // Create species-specific bug geometry
            let bugEntity = ModelEntity(
                mesh: createBugMesh(for: bug),
                materials: [createBugMaterial(for: bug)]
            )
            
            // Position bugs in a simple grid pattern near the terrain
            let gridSize = 4
            let spacing: Float = 2.0
            let row = index / gridSize
            let col = index % gridSize
            
            let bugX = Float(col - gridSize/2) * spacing
            let bugZ = Float(row - gridSize/2) * spacing  
            let bugY: Float = 2.0  // Well above the ground
            
            bugEntity.position = [bugX, bugY, bugZ]
            bugEntity.name = "Bug_\(index)"
            
            bugContainer.addChild(bugEntity)
        }
        
        anchor.addChild(bugContainer)
        print("✅ [RealityKit] Added \(bugsToShow.count) bug entities at positions:")
        for (index, _) in bugsToShow.enumerated() {
            let gridSize = 4
            let spacing: Float = 2.0
            let row = index / gridSize
            let col = index % gridSize
            let bugX = Float(col - gridSize/2) * spacing
            let bugZ = Float(row - gridSize/2) * spacing
            print("   Bug \(index): [\(bugX), 2.0, \(bugZ)]")
        }
    }
    
    @available(macOS 14.0, *)
    private func createBugMesh(for bug: Bug) -> MeshResource {
        // Create different shapes based on species type
        switch bug.dna.speciesTraits.speciesType {
        case .herbivore:
            return .generateSphere(radius: 0.4)  // Round herbivores
        case .carnivore:
            return .generateBox(size: [0.8, 0.4, 0.8])  // Angular carnivores
        case .omnivore:
            return .generateCylinder(height: 0.8, radius: 0.4)  // Cylinder omnivores
        case .scavenger:
            return .generateBox(size: [0.6, 0.8, 0.6])  // Tall scavengers
        }
    }
    
    @available(macOS 14.0, *)
    private func createBugMaterial(for bug: Bug) -> SimpleMaterial {
        var material = SimpleMaterial()
        
        // Color based on species type first, then energy level
        let baseColor: NSColor
        switch bug.dna.speciesTraits.speciesType {
        case .herbivore:
            baseColor = .green
        case .carnivore:
            baseColor = .red
        case .omnivore:
            baseColor = .blue
        case .scavenger:
            baseColor = .purple
        }
        
        // Modify brightness based on energy level
        let energyRatio = bug.energy / 100.0
        let brightness = max(0.3, min(1.0, energyRatio))
        
        material.color = .init(tint: baseColor.withAlphaComponent(brightness))
        material.metallic = 0.2
        material.roughness = 0.6
        
        return material
    }
    
    @available(macOS 14.0, *)
    private func updateBugPositions() {
        // DISABLED: Dynamic position updates causing bugs to fly off-screen
        // Keep bugs in their initial grid positions for now
        // TODO: Fix coordinate system mapping between simulation and RealityKit
        
        // Future implementation will properly map:
        // - Simulation world coordinates (large scale)
        // - RealityKit world coordinates (small scale)
        // - Proper terrain following
    }

    
    
    @available(macOS 14.0, *)
    private func generateSampleTerrain(in anchor: Entity) {
        print("🌍 [RealityKit] Generating terrain from voxel data...")
        
        let voxelWorld = simulationEngine.voxelWorld
        let surfaceVoxels = voxelWorld.getVoxelsInLayer(.surface)
        let voxelSize = Float(voxelWorld.voxelSize)
        
        print("📊 [RealityKit] Processing \(surfaceVoxels.count) surface voxels (size: \(voxelSize))")
        
        // Create terrain container
        let terrainContainer = Entity()
        terrainContainer.name = "TerrainContainer"
        anchor.addChild(terrainContainer)
        
        // Render a sample of voxels (limit for performance testing)
        let sampleSize = min(100, surfaceVoxels.count)
        let sampleVoxels = Array(surfaceVoxels.prefix(sampleSize))
        
        // Group by terrain type for efficiency
        let voxelsByType = Dictionary(grouping: sampleVoxels) { $0.terrainType }
        
        for (terrainType, typeVoxels) in voxelsByType {
            createTerrainTypeGroup(terrainType: terrainType, voxels: typeVoxels, voxelSize: voxelSize, in: terrainContainer)
        }
        
        print("✅ [RealityKit] Generated \(sampleSize) terrain voxels in \(voxelsByType.count) types")
    }
    
    @available(macOS 14.0, *)
    private func createTerrainTypeGroup(terrainType: TerrainType, voxels: [Voxel], voxelSize: Float, in container: Entity) {
        let groupEntity = Entity()
        groupEntity.name = "Terrain_\(terrainType.rawValue)"
        
        // Limit voxels per type for initial testing
        let maxVoxelsPerType = min(20, voxels.count)
        let renderVoxels = Array(voxels.prefix(maxVoxelsPerType))
        
        for voxel in renderVoxels {
            let voxelEntity = ModelEntity(
                mesh: .generateBox(size: voxelSize * 0.8), // Slightly smaller for visual separation
                materials: [createVoxelMaterial(for: terrainType)]
            )
            
            // Convert Bugtopia coordinates to RealityKit coordinates
            // 🌍 FIXED: Use full-scale coordinates (was 0.1, too tiny)
            let scale: Float = 1.0
            voxelEntity.position = SIMD3<Float>(
                Float(voxel.position.x) * scale,
                Float(voxel.position.z) * scale, // Z becomes Y (up)
                Float(voxel.position.y) * scale  // Y becomes Z (depth)
            )
            
            groupEntity.addChild(voxelEntity)
        }
        
        container.addChild(groupEntity)
        print("🎨 [RealityKit] Created \(renderVoxels.count) \(terrainType.rawValue) voxels")
    }
    
    @available(macOS 14.0, *)
    private func createVoxelMaterial(for terrainType: TerrainType) -> SimpleMaterial {
        var material = SimpleMaterial()
        material.metallic = 0.1
        material.roughness = 0.7
        
        // Use terrain type colors with good contrast
        switch terrainType {
        case .open:
            material.color = .init(tint: .green)
        case .wall:
            material.color = .init(tint: .gray)
        case .water:
            material.color = .init(tint: .cyan)
        case .hill:
            material.color = .init(tint: .brown)
        case .food:
            material.color = .init(tint: .yellow)
        case .forest:
            material.color = .init(tint: .init(red: 0, green: 0.6, blue: 0, alpha: 1))
        case .sand:
            material.color = .init(tint: .init(red: 0.9, green: 0.8, blue: 0.4, alpha: 1))
        default:
            material.color = .init(tint: .lightGray)
        }
        
        return material
    }
    
    @available(macOS 14.0, *)
    private func generateSampleBugs(in anchor: Entity) {
        print("🐛 [RealityKit] Generating sample bugs...")
        
        let bugContainer = Entity()
        bugContainer.name = "BugContainer"
        anchor.addChild(bugContainer)
        
        // Create a few sample bugs as colored spheres
        let sampleBugs = Array(simulationEngine.bugs.prefix(5))
        
        for (_, bug) in sampleBugs.enumerated() {
            let bugEntity = ModelEntity(
                mesh: .generateSphere(radius: 0.2),
                materials: [createBugMaterial(for: bug)]
            )
            
            // Position bugs above terrain at full scale
            let scale: Float = 1.0  // 🐛 FIXED: Full-scale bugs (was 0.1, too tiny)
            bugEntity.position = SIMD3<Float>(
                Float(bug.position3D.x) * scale,
                Float(bug.position3D.z) * scale + 0.5, // Above terrain
                Float(bug.position3D.y) * scale
            )
            
            bugContainer.addChild(bugEntity)
        }
        
        print("✅ [RealityKit] Generated \(sampleBugs.count) bug entities")
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
    
    // MARK: - Camera Controls
    
    // 🎮 REMOVED: Single-finger drag function no longer needed
    
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
        let sceneAnchor = AnchorEntity(.world(transform: Transform.identity.matrix))
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
        
        // Fix FPS calculation - ensure we have a valid time interval
        if elapsed > 0 {
            currentFPS = Double(frameCount) / elapsed
        } else {
            currentFPS = 0.0
        }
        
        frameCount = 0
        lastFPSUpdate = now
        
        performanceMetrics.currentFPS = currentFPS
        performanceMetrics.entityCount = bugEntityManager.bugEntities.count
        
        // Debug logging to help track FPS issues
        if currentFPS > 0 {
            // print("📊 [RealityKit] FPS: \(String(format: "%.1f", currentFPS))")
        }
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
    
    // MARK: - Navigation System Implementation
    
    @State private var keyboardEventMonitor: Any?
    @State private var keyUpEventMonitor: Any?
    @State private var scrollWheelMonitor: Any?  // 🎮 TWO-FINGER: For trackpad scroll events
    
    private func startNavigationUpdates() {
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            updateMovement()
        }
    }
    
    private func setupKeyboardMonitoring() {
        // Monitor key down events globally
        keyboardEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyDown(event)
            return nil // Allow event to continue
        }
        
        // Monitor key up events globally
        keyUpEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            handleKeyUp(event)
            return nil // Allow event to continue
        }
        
        print("🎮 SIMPLIFIED: Basic keyboard monitoring started")
        
        // Also setup scroll wheel monitoring for two-finger trackpad gestures
        setupScrollWheelMonitoring()
    }
    
    private func stopKeyboardMonitoring() {
        if let monitor = keyboardEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardEventMonitor = nil
        }
        if let monitor = keyUpEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyUpEventMonitor = nil
        }
        if let monitor = scrollWheelMonitor {
            NSEvent.removeMonitor(monitor)
            scrollWheelMonitor = nil
        }
        print("🎮 SIMPLIFIED: Basic keyboard and scroll monitoring stopped")
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let keyCode = event.keyCode
        pressedKeys.insert(keyCode)
        print("🎮 SIMPLIFIED: Key pressed: \(keyCode)")
    }
    
    private func handleKeyUp(_ event: NSEvent) {
        let keyCode = event.keyCode
        pressedKeys.remove(keyCode)
        print("🎮 Key released: \(keyCode)")
    }
    
    private func setupScrollWheelMonitoring() {
        // Monitor scroll wheel events globally for two-finger trackpad gestures
        scrollWheelMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            handleScrollWheel(event)
            return nil // Allow event to continue
        }
        
        print("🎮 TWO-FINGER: Scroll wheel monitoring started for trackpad gestures")
    }
    
    private func handleScrollWheel(_ event: NSEvent) {
        // Two-finger scroll wheel event - use both vertical and horizontal scrolling
        let sensitivity: Float = 0.02  // Higher sensitivity for scroll events
        let pitchDelta = Float(event.deltaY) * sensitivity   // Vertical scroll for pitch
        let yawDelta = Float(event.deltaX) * sensitivity     // Horizontal scroll for yaw
        
        var rotationChanged = false
        
        // Handle vertical scrolling (pitch - up/down look)
        if abs(event.deltaY) > 0.1 {
            let oldPitch = cameraPitch
            cameraPitch += pitchDelta
            
            // 🔒 CONSTRAIN PITCH: Prevent over-rotation (looking too far up/down)
            cameraPitch = max(-Float.pi/2.1, min(Float.pi/2.1, cameraPitch))
            rotationChanged = true
            
            // print("🎮 TWO-FINGER PITCH: \(oldPitch * 180 / .pi)° → \(cameraPitch * 180 / .pi)° (delta: \(pitchDelta * 180 / .pi)°)")
        }
        
        // Handle horizontal scrolling (yaw - left/right look)
        if abs(event.deltaX) > 0.1 {
            let oldYaw = cameraYaw
            cameraYaw += yawDelta
            
            // 🔄 NORMALIZE YAW: Keep yaw in 0-360° range for cleaner values
            while cameraYaw > Float.pi { cameraYaw -= 2 * Float.pi }
            while cameraYaw < -Float.pi { cameraYaw += 2 * Float.pi }
            rotationChanged = true
            
            // print("🎮 TWO-FINGER YAW: \(oldYaw * 180 / .pi)° → \(cameraYaw * 180 / .pi)° (delta: \(yawDelta * 180 / .pi)°)")
        }
        
        // Apply combined rotation to the scene
        if rotationChanged {
            guard let anchor = sceneAnchor else { return }
            
            // 🔒 ORIENTATION LOCK: Create rotation that maintains up vector
            anchor.transform.rotation = createOrientationLockedRotation()
        }
    }
    
    private func updateMovement() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = Float(currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        
        guard let anchor = sceneAnchor else { return }
        
        // 🎮 SIMPLIFIED: Handle basic arrow key movement
        for keyCode in pressedKeys {
            switch keyCode {
            case 123:  // Left Arrow - Move LEFT
                moveLeft(deltaTime: deltaTime, anchor: anchor)
            case 124:  // Right Arrow - Move RIGHT  
                moveRight(deltaTime: deltaTime, anchor: anchor)
            case 126:  // Up Arrow - Move FORWARD
                moveForward(deltaTime: deltaTime, anchor: anchor)
            case 125:  // Down Arrow - Move BACKWARD
                moveBackward(deltaTime: deltaTime, anchor: anchor)
            default:
                break
            }
        }
    }
    
    // 🎮 SIMPLIFIED: Basic left movement
    private func moveLeft(deltaTime: Float, anchor: AnchorEntity) {
        let distance = movementSpeed * deltaTime
        
        // Move camera position left (negative X)
        cameraPosition.x -= distance
        
        // Update the world anchor (negative because we move the world opposite to camera)
        anchor.transform.translation = -cameraPosition
        
        // 🔒 MAINTAIN ORIENTATION: Keep proper up vector when moving
        anchor.transform.rotation = createOrientationLockedRotation()
        
        print("🎮 SIMPLIFIED: Moved LEFT to position: \(cameraPosition)")
    }
    
    // 🎮 SIMPLIFIED: Basic right movement  
    private func moveRight(deltaTime: Float, anchor: AnchorEntity) {
        let distance = movementSpeed * deltaTime
        
        // Move camera position right (positive X)
        cameraPosition.x += distance
        
        // Update the world anchor (negative because we move the world opposite to camera)
        anchor.transform.translation = -cameraPosition
        
        // 🔒 MAINTAIN ORIENTATION: Keep proper up vector when moving
        anchor.transform.rotation = createOrientationLockedRotation()
        
        print("🎮 SIMPLIFIED: Moved RIGHT to position: \(cameraPosition)")
    }
    
    // 🎮 SIMPLIFIED: Basic forward movement
    private func moveForward(deltaTime: Float, anchor: AnchorEntity) {
        let distance = movementSpeed * deltaTime
        
        // 🔧 FIXED: Move camera position forward (negative Z in RealityKit)
        cameraPosition.z -= distance
        
        // Update the world anchor (negative because we move the world opposite to camera)
        anchor.transform.translation = -cameraPosition
        
        // 🔒 MAINTAIN ORIENTATION: Keep proper up vector when moving
        anchor.transform.rotation = createOrientationLockedRotation()
        
        print("🎮 SIMPLIFIED: Moved FORWARD to position: \(cameraPosition)")
    }
    
    // 🎮 SIMPLIFIED: Basic backward movement
    private func moveBackward(deltaTime: Float, anchor: AnchorEntity) {
        let distance = movementSpeed * deltaTime
        
        // 🔧 FIXED: Move camera position backward (positive Z in RealityKit)
        cameraPosition.z += distance
        
        // Update the world anchor (negative because we move the world opposite to camera)
        anchor.transform.translation = -cameraPosition
        
        // 🔒 MAINTAIN ORIENTATION: Keep proper up vector when moving
        anchor.transform.rotation = createOrientationLockedRotation()
        
        print("🎮 SIMPLIFIED: Moved BACKWARD to position: \(cameraPosition)")
    }
    
    // 🎮 SIMPLIFIED: No navigation mode toggle needed
    
    // MARK: - Helper Functions (matching SceneKit implementation)
    
    // Helper function to create SIMD3 vectors (removed SCNVector3 dependency)
    private func createSIMD3(_ x: Float, _ y: Float, _ z: Float) -> SIMD3<Float> {
        return SIMD3<Float>(x, y, z)
    }
    
    // 🔒 SCENEKIT-STYLE ROTATION: Direct Euler angle approach like SceneKit
    private func createOrientationLockedRotation() -> simd_quatf {
        // DIRECT COPY of SceneKit approach: Use Euler angles with roll=0
        // SceneKit: cameraNode.eulerAngles = SCNVector3(newPitch, newYaw, 0)
        
        // 🚀 DIRECT AXIS-ANGLE: Use RealityKit's direct quaternion multiplication
        // This matches SceneKit's behavior exactly: pitch (X), yaw (Y), roll (Z=0)
        let quaternion = simd_quatf(angle: cameraPitch, axis: SIMD3<Float>(1, 0, 0)) *  // Pitch around X-axis
                        simd_quatf(angle: cameraYaw, axis: SIMD3<Float>(0, 1, 0))      // Yaw around Y-axis
                        // No roll component - prevents tilting!
        
        return quaternion
    }

    
    // 🎮 SIMPLIFIED: No collision checking needed
    private func wouldCollide(at position: SIMD3<Float>) -> Bool {
        return false  // No collision checking in simplified mode
    }
    
    // 🎮 SIMPLIFIED: Helper functions removed
    
    // 🎮 SIMPLIFIED: Basic terrain height
    private func getTerrainHeight(at position: SIMD3<Float>) -> Float {
        return 0.0  // Flat ground for simplified mode
    }
}

// MARK: - Global Keyboard Monitoring System
// Uses NSEvent monitoring for reliable keyboard capture

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

