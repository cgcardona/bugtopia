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
    
    // MARK: - God/Walk Mode System
    
    @State private var isGodMode: Bool = true  // 🌟 Start in god mode (flying)
    @State private var walkModeHeight: Float = 5.0  // Height above terrain in walk mode
    @State private var cameraPosition = SIMD3<Float>(100, 200, 75)  // 📷 INSIDE TERRAIN: Center of 200×150 terrain (Z: 0-150)
    @State private var cameraPitch: Float = -1.57  // 🎮 LOOKING DOWN: 90° downward to see terrain directly below
    @State private var cameraYaw: Float = Float.pi     // 🎮 FIXED: Look AT the world (180°), not away from it
    
    // MARK: - Selection System
    
    private let onBugSelectedCallback: ((Bug?) -> Void)?
    private let onFoodSelectedCallback: ((FoodItem?) -> Void)?
    
    // MARK: - Debug System
    
    @State private var showDebugOverlay: Bool = true  // 🐛 Visual debugging enabled
    @State private var debugInfo: String = "Debug Loading..."
    
    // MARK: - Entity Management
    
    @StateObject private var bugEntityManager = BugEntityManager()
    
    // MARK: - Performance Tracking
    
    @State private var frameCount: Int = 0
    @State private var lastFPSUpdate: Date = Date()
    
    // MARK: - Debug Functions
    
    private func updateDebugInfo() {
        let terrain = "Terrain: 200×200 units (32×6.25 scale)"
        let camera = String(format: "Cam: (%.1f, %.1f, %.1f)", cameraPosition.x, cameraPosition.y, cameraPosition.z)
        let rotation = String(format: "Rot: P%.1f° Y%.1f°", cameraPitch * 180 / .pi, cameraYaw * 180 / .pi)
        let mode = isGodMode ? "🌟 GOD" : "🚶 WALK"
        
        debugInfo = "\(mode) | \(terrain)\n\(camera) | \(rotation)"
    }
    
    // MARK: - Visual Debug Overlay
    
    private var coordinateDebugOverlay: some View {
        VStack {
            Spacer()
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🐛 COORDINATE DEBUG")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text(debugInfo)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                    
                    // Terrain bounds indicator
                    Text("Expected Bounds:")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("X: 0 to 200 | Z: 0 to 200")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(4)
                }
                Spacer()
            }
            .padding()
        }
    }
    @State private var currentFPS: Double = 0.0
    @State private var performanceMetrics = Phase2PerformanceMetrics()
    
    // MARK: - Camera Navigation (legacy - removed duplicates)
    
    // MARK: - Debug
    
    @State private var debugMode: Bool = false
    
    // MARK: - Update Management
    
    @State private var updateTimer: Timer?
    
    // MARK: - Initialization
    
    init(simulationEngine: SimulationEngine, 
         onBugSelected: ((Bug?) -> Void)? = nil, 
         onFoodSelected: ((FoodItem?) -> Void)? = nil) {
        self.simulationEngine = simulationEngine
        self.onBugSelectedCallback = onBugSelected
        self.onFoodSelectedCallback = onFoodSelected
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main 3D content
            mainContentView
            
            // Debug overlay
            if debugMode {
                debugOverlay
            }
            
            // Visual Debug System
            if showDebugOverlay {
                coordinateDebugOverlay
            }
        }
        .onAppear {
            startPerformanceMonitoring()
            startEntityUpdates()
            updateDebugInfo()
            print("🚀 [RealityKit] View appeared, FPS monitoring and entity updates enabled")
        }
        .onDisappear {
            stopEntityUpdates()
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

    }
    
    @available(macOS 14.0, *)
    private func setupHelloWorldScene(_ content: any RealityViewContentProtocol) {
        print("🚀 [RealityKit] BUILDING BUGTOPIA WORLD...")
        
        // Create scene anchor positioned like SceneKit camera view
        let anchor = AnchorEntity(.world(transform: Transform.identity.matrix))
        
        // Position the world anchor for elevated overview
        anchor.transform.translation = [-100, -200, -75]  // Centered on unified 200×150 terrain
        
        // 🎯 INITIAL ROTATION: Set the camera looking down at terrain
        anchor.transform.rotation = createOrientationLockedRotation()
        print("📷 [SETUP] Initial camera rotation applied - Pitch: \(cameraPitch * 180 / .pi)°, Yaw: \(cameraYaw * 180 / .pi)°")
        
        // Store reference for camera manipulation
        sceneAnchor = anchor
        
        // 1. Add skybox background (far away)
        setupSkybox(in: anchor)
        
        // 2. Add continuous terrain surface (like SceneKit)
        setupGroundPlane(in: anchor)
        
        // 🗑️ DISABLED: Individual voxel terrain (creates grey cubes)
        // SceneKit uses only smooth terrain mesh for continuous surface
        // addSimulationTerrain(in: anchor)
        
        // 4. Add lighting for proper visibility
        setupWorldLighting(in: anchor)
        
        // 5. Add dramatic lighting system
        setupDynamicLighting(in: anchor)
        
        // 6. Add bug entities
        addBugEntities(in: anchor)
        
        // 7. Add food entities
        addFoodEntities(in: anchor)
        
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
        
        // 🌌 IMMERSIVE SKYBOX: Create massive sphere for true horizon-to-horizon coverage
        let backgroundSphere = ModelEntity(
            mesh: .generateSphere(radius: 5000), // 🌍 MASSIVE: Even larger for true immersion
            materials: [skyboxMaterial]
        )
        
        // 🎨 SKYBOX POSITIONING: Position far away so camera sees terrain, not skybox interior
        backgroundSphere.scale = [1, 1, 1]  // Normal orientation - don't invert
        backgroundSphere.position = [100, -1000, 75]  // Far below terrain so it acts as distant horizon
        
        // 🚫 TEMPORARILY DISABLED: Skip skybox to debug terrain visibility
        // anchor.addChild(backgroundSphere)
        print("🚫 [DEBUG] Skybox temporarily disabled to check terrain visibility")
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
        let scale: Float = 6.25  // 🎯 UNIFIED SCALE: 32*6.25=200 units to match simulation/food coordinates
        let heightScale: Float = 0.8  // 🏔️ NAVIGABLE: Gentle slopes for bug navigation (was 1.0)
        let minHeight: Float = -20.0  // 🌊 WATERTIGHT: Minimum terrain floor height
        
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        // 🌍 WATERTIGHT TERRAIN: Create extended resolution for seamless edges
        let extendedResolution = resolution + 4  // Add 2 vertices on each side for skirts
        let offset = 2  // Offset for the original heightmap within extended grid
        
        // Generate vertices with extended bounds and edge skirts
        for x in 0..<extendedResolution {
            for z in 0..<extendedResolution {
                let worldX = Float(x - extendedResolution/2) * scale
                let worldZ = Float(z - extendedResolution/2) * scale
                
                var worldY: Float
                
                // 🏔️ TERRAIN HEIGHT: Use heightmap data or create edge skirts
                if x >= offset && x < (resolution + offset) && z >= offset && z < (resolution + offset) {
                    // Inside original heightmap bounds
                    let heightMapX = x - offset
                    let heightMapZ = z - offset
                    worldY = Float(heightMap[heightMapX][heightMapZ]) * heightScale
                } else {
                    // Outside bounds - create low skirt to seal terrain
                    worldY = minHeight
                }
                
                // Ensure no vertex goes below minimum floor
                worldY = max(worldY, minHeight)
                
                vertices.append(SIMD3<Float>(worldX, worldY, worldZ))
            }
        }
        
        // Generate triangle indices for the extended mesh (includes skirts)
        for x in 0..<(extendedResolution-1) {
            for z in 0..<(extendedResolution-1) {
                let bottomLeft = UInt32(x * extendedResolution + z)
                let bottomRight = UInt32(x * extendedResolution + z + 1)
                let topLeft = UInt32((x + 1) * extendedResolution + z)
                let topRight = UInt32((x + 1) * extendedResolution + z + 1)
                
                // 🔧 CONSISTENT WINDING: Ensure counter-clockwise winding for all triangles
                // First triangle (bottom-left, bottom-right, top-left)
                indices.append(bottomLeft)
                indices.append(bottomRight)
                indices.append(topLeft)
                
                // Second triangle (bottom-right, top-right, top-left)
                indices.append(bottomRight)
                indices.append(topRight)
                indices.append(topLeft)
            }
        }
        
        // 🔧 CALCULATE NORMALS: Ensure proper lighting and visibility
        var normals: [SIMD3<Float>] = []
        
        // Generate normals for each vertex (pointing upward for terrain)
        for _ in 0..<vertices.count {
            normals.append(SIMD3<Float>(0, 1, 0))  // All normals point up for terrain
        }
        
        // Create mesh resource with normals
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffer(vertices)
        meshDescriptor.normals = MeshBuffer(normals)  // Add normals for proper lighting
        meshDescriptor.primitives = .triangles(indices)
        
        let terrainMesh = try! MeshResource.generate(from: [meshDescriptor])
        
        // 🔧 DOUBLE-SIDED TERRAIN: Create material that's visible from all angles
        var terrainMaterial = PhysicallyBasedMaterial()
        
        // Set terrain color based on dominant biome
        let dominantBiome = findDominantBiome(biomeMap: biomeMap)
        let terrainColor = getTerrainColor(for: dominantBiome)
        
        // 🌿 ORGANIC BEAUTY: Use natural colors without harsh textures (Style Guide approach)
        // Each terrain type gets its own natural material treatment
        terrainMaterial.baseColor = .init(tint: terrainColor)
        
        // 🌍 ENHANCED PBR: Realistic terrain surface properties
        terrainMaterial.roughness = 0.95  // Natural ground roughness
        terrainMaterial.metallic = 0.0    // Non-metallic terrain
        terrainMaterial.clearcoatRoughness = 0.8  // Subtle surface variation
        
        // 🔧 CRITICAL: Enable double-sided rendering to fix backface culling
        terrainMaterial.faceCulling = .none  // Render both front and back faces
        
        let terrainEntity = ModelEntity(mesh: terrainMesh, materials: [terrainMaterial])
        terrainEntity.name = "WatertightTerrain"
        
        print("🌍 [RealityKit] Created watertight terrain: \(vertices.count) vertices, \(indices.count/3) triangles")
        print("📐 [RealityKit] Extended resolution: \(extendedResolution)x\(extendedResolution) (was \(resolution)x\(resolution))")
        
        return terrainEntity
    }
    
    @available(macOS 14.0, *)
    private func createWaterSurfaces(heightMap: [[Double]], resolution: Int) -> Entity {
        let waterContainer = Entity()
        waterContainer.name = "WaterSurfaces"
        
        let scale: Float = 6.25  // 🌊 UNIFIED SCALE: Match terrain scale for consistency
        let waterLevel: Double = -15.0  // 🏔️ DEEPER: Only in deep valleys (was -5.0)
        
        // 🌊 VALLEY WATER: Only create water in actual valleys/low areas
        // Count how much terrain is below water level
        var waterAreaCount = 0
        for x in 0..<resolution {
            for z in 0..<resolution {
                if heightMap[x][z] <= waterLevel {
                    waterAreaCount += 1
                }
            }
        }
        
        // Only add water if there are significant valley areas
        if waterAreaCount > (resolution * resolution) / 50 {  // 🌊 LESS WATER: Only 2% threshold (was 5%)
            // Create large water plane that integrates with terrain edges
            let waterSize = Float(resolution + 4) * scale  // 🌊 FULL COVERAGE: Match extended terrain bounds
        let waterMesh = MeshResource.generatePlane(width: waterSize, depth: waterSize)
        let waterMaterial = createWaterMaterial(height: waterLevel)
        
        let waterEntity = ModelEntity(mesh: waterMesh, materials: [waterMaterial])
            waterEntity.position = [0, Float(waterLevel) * 0.8, 0]  // 🌊 INTEGRATED: Match terrain floor level
            waterEntity.name = "IntegratedWater"
        
        waterContainer.addChild(waterEntity)
            
            print("🌊 [RealityKit] Created integrated water plane covering \(waterAreaCount) valley areas")
        } else {
            print("🏔️ [RealityKit] No significant valleys found - skipping water")
        }
        
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
        let material: RealityKit.Material
        if isWater {
            material = createWaterMaterial(height: height)
        } else {
            // Create double-sided terrain material
            var terrainMat = PhysicallyBasedMaterial()
            terrainMat.baseColor = .init(tint: terrainColor)
            terrainMat.roughness = 0.8
            terrainMat.metallic = 0.1
            terrainMat.faceCulling = .none  // Double-sided rendering
            material = terrainMat
        }
        
        let terrainPatch = ModelEntity(mesh: mesh, materials: [material])
        terrainPatch.position = position
        
        return terrainPatch
    }
    
    @available(macOS 14.0, *)
    private func createWaterMaterial(height: Double) -> SimpleMaterial {
        var waterMaterial = SimpleMaterial()
        
        // 🌊 PHOTOREALISTIC WATER: Enhanced depth-based water rendering
        let waterDepth = abs(height + 5) / 15.0  // Normalize depth (0-1)
        let blueIntensity = 0.2 + (waterDepth * 0.6)  // Deeper water is more blue
        
        let waterColor = NSColor(
            red: 0.05,  // Slight warm tint for realism
            green: 0.25 + (waterDepth * 0.3),  // Green-blue gradient with depth
            blue: blueIntensity,
            alpha: 0.65 + (waterDepth * 0.25)  // Deeper water is less transparent
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
        sunLight.light.intensity = 5000  // 🔆 MUCH BRIGHTER: For debugging visibility
        sunLight.position = [100, 50, 75]  // Position near camera/terrain center
        sunLight.look(at: [100, 0, 75], from: sunLight.position, relativeTo: nil)
        anchor.addChild(sunLight)
        
        // 🌟 ADD BRIGHT AMBIENT LIGHT: For debugging terrain visibility
        let ambientLight = Entity()
        ambientLight.components.set(DirectionalLightComponent(
            color: .white,
            intensity: 3000
        ))
        ambientLight.position = [100, 100, 75]  // Above terrain center
        ambientLight.look(at: [100, 0, 75], from: ambientLight.position, relativeTo: nil)
        anchor.addChild(ambientLight)
        
        print("☀️ [RealityKit] Enhanced lighting added - Sun: 5000, Ambient: 3000")
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
    private func getTerrainColor(for biome: BiomeType) -> NSColor {
        switch biome {
        case .temperateForest:
            return NSColor.green
        case .desert:
            return NSColor.yellow
        case .alpine:
            return NSColor.gray
        case .temperateGrassland:
            return NSColor(red: 0.6, green: 0.8, blue: 0.2, alpha: 1.0)
        case .savanna:
            return NSColor.orange
        case .tropicalRainforest:
            return NSColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        case .wetlands:
            return NSColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1.0)
        case .coastal:
            return NSColor.cyan
        case .tundra:
            return NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        case .borealForest:
            return NSColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0)
        }
    }
    
    @available(macOS 14.0, *)
    private func createTerrainMaterial(for terrainType: TerrainType) -> RealityKit.Material {
        var material = SimpleMaterial()
        
        switch terrainType {
        case .forest:
            material.color = .init(tint: .green)
        case .hill:
            // 🏔️ CLAY HILLS: Using Style Guide color palette #CC8E35 for elevated, ancient terrain
            let clayColor = NSColor(red: 0.8, green: 0.557, blue: 0.208, alpha: 1.0) // Clay from style guide
            material.color = .init(tint: clayColor)
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
        
        // 🌿 ORGANIC BEAUTY: Natural surface properties for terrain
        material.metallic = 0.0   // Completely non-metallic for natural materials  
        material.roughness = 0.7  // Natural surface variation
        
        return material
    }
    
    @available(macOS 14.0, *)
    private func setupDynamicLighting(in anchor: Entity) {
        print("💡 [RealityKit] Setting up dramatic lighting system...")
        
        // 🌅 PRIMARY SUN LIGHT: Warm directional light simulating sun
        let sunLight = DirectionalLight()
        sunLight.light.color = .init(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0) // Warm sunlight
        sunLight.light.intensity = 3000 // Strong directional lighting
        sunLight.light.isRealWorldProxy = true // Enable shadows
        
        // Position sun at realistic angle (45° elevation, slightly offset)
        sunLight.orientation = simd_quatf(angle: Float.pi * 0.25, axis: [1, 0, 0]) * 
                              simd_quatf(angle: Float.pi * 0.3, axis: [0, 1, 0])
        sunLight.position = [0, 100, 50]
        
        anchor.addChild(sunLight)
        
        // 🌙 FILL LIGHT: Soft blue ambient to prevent harsh shadows
        let fillLight = DirectionalLight()
        fillLight.light.color = .init(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0) // Cool fill light
        fillLight.light.intensity = 800 // Gentle fill
        
        // Position opposite to sun for natural fill lighting
        fillLight.orientation = simd_quatf(angle: -Float.pi * 0.15, axis: [1, 0, 0]) * 
                               simd_quatf(angle: Float.pi * 1.3, axis: [0, 1, 0])
        fillLight.position = [0, 80, -30]
        
        anchor.addChild(fillLight)
        
        // 🌟 ACCENT LIGHTS: Add some dramatic colored lights based on world type
        let worldType = simulationEngine.voxelWorld.worldType
        addAccentLights(to: anchor, for: worldType)
        
        print("✅ [RealityKit] Dynamic lighting system with shadows and atmosphere created")
    }
    
    @available(macOS 14.0, *)
    private func addAccentLights(to anchor: Entity, for worldType: WorldType3D) {
        // 🎨 WORLD-SPECIFIC ACCENT LIGHTING: Each world gets unique atmospheric lighting
        let accentColor: NSColor
        let intensity: Float
        
        switch worldType {
        case .abyss3D:
            accentColor = NSColor(red: 0.4, green: 0.1, blue: 0.8, alpha: 1.0) // Deep purple
            intensity = 1500
        case .volcano3D:
            accentColor = NSColor(red: 1.0, green: 0.3, blue: 0.1, alpha: 1.0) // Fiery orange
            intensity = 2000
        case .canyon3D:
            accentColor = NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // Warm desert
            intensity = 1200
        case .archipelago3D:
            accentColor = NSColor(red: 0.1, green: 0.6, blue: 1.0, alpha: 1.0) // Ocean blue
            intensity = 1000
        case .cavern3D:
            accentColor = NSColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0) // Mysterious green
            intensity = 800
        default:
            accentColor = NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0) // Neutral
            intensity = 1000
        }
        
        // Create multiple accent lights for atmospheric depth
        for i in 0..<3 {
            let accentLight = PointLight()
            accentLight.light.color = accentColor
            accentLight.light.intensity = intensity * (0.7 + Float(i) * 0.15) // Vary intensity
            accentLight.light.attenuationRadius = 200.0 // Wide coverage
            
            // Position lights around the scene for ambient glow
            let angle = Float(i) * (2.0 * Float.pi / 3.0) // 120° apart
            let radius: Float = 120
            accentLight.position = [
                cos(angle) * radius,
                40 + Float(i) * 20, // Vary height
                sin(angle) * radius
            ]
            
            anchor.addChild(accentLight)
        }
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
    private func addFoodEntities(in anchor: Entity) {
        print("🍎 [RealityKit] Adding food entities...")
        
        // Create food container
        let foodContainer = Entity()
        foodContainer.name = "FoodContainer"
        
        // Get current food items from simulation
        let foods = simulationEngine.foods
        print("🍎 [RealityKit] Found \(foods.count) food items to render")
        
        // Create visual entities for each food item
        for (index, food) in foods.enumerated() {
            let foodEntity = createFoodEntity(for: food, index: index)
            foodContainer.addChild(foodEntity)
        }
        
        anchor.addChild(foodContainer)
        print("✅ [RealityKit] Added \(foods.count) food entities across terrain")
    }
    
    @available(macOS 14.0, *)
    private func createFoodEntity(for food: FoodItem, index: Int) -> Entity {
        // 🍎 REALISTIC FOOD MODELS: Create food-specific 3D shapes
        let mesh = createFoodMesh(for: food)
        
        // Create enhanced material based on food type
        let material = createFoodMaterial(for: food)
        
        // Create model entity
        let foodEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // UNIFIED COORDINATE SYSTEM: Direct 1:1 mapping from simulation to RealityKit
        let scaledX = Float(food.position.x) * 0.1  // 2000 sim units -> 200 RK units
        let scaledZ = Float(food.position.y) * 0.1  // 1500 sim units -> 150 RK units
        let terrainHeight = getTerrainHeightAtPosition(x: scaledX, z: scaledZ)
        let scaledPosition = SIMD3<Float>(
            scaledX, // Use consistent simulation scaling
            terrainHeight + 1.0, // Slightly above terrain
            scaledZ  // Use consistent simulation scaling
        )
        foodEntity.position = scaledPosition
        
        // Set entity name for identification
        foodEntity.name = "Food_\(index)"
        
        // Add gentle pulsing animation to make food noticeable
        addFoodAnimation(to: foodEntity)
        
        return foodEntity
    }
    
    @available(macOS 14.0, *)
    private func createFoodMesh(for food: FoodItem) -> MeshResource {
        // 🍎 FOOD-SPECIFIC 3D MODELS: Each food type gets its distinctive shape
        let baseSize: Float = 0.6 + Float(food.energyValue / 200.0) // Size based on energy value
        
        switch food.type {
        case .apple:
            // 🍎 APPLE: AAA PHOTOREALISTIC MODEL with natural apple shape!
            // 🚀 Creating photorealistic apple with scale: \(baseSize)
            let appleMesh = AAAFoodGeometry.createStandardApple()
            return appleMesh
            
        case .plum:
            // 🍇 PLUM: AAA PHOTOREALISTIC MODEL with proper topology!
            print("🚀 [AAA] Creating photorealistic plum with scale: \(baseSize)")
            let plumMesh = AAAFoodGeometry.createStandardPlum()
            return plumMesh
            
        case .orange:
            // 🍊 ORANGE: AAA PHOTOREALISTIC MODEL with citrus texture!
            print("🚀 [AAA] Creating photorealistic orange with scale: \(baseSize)")
            let orangeMesh = AAAFoodGeometry.createStandardOrange()
            return orangeMesh
            
        case .melon:
            // 🍈 MELON: AAA PHOTOREALISTIC MODEL with netted cantaloupe texture!
            print("🚀 [AAA] Creating photorealistic melon with scale: \(baseSize)")
            let melonMesh = AAAFoodGeometry.createStandardMelon()
            return melonMesh
            
        case .meat:
            // 🥩 MEAT: AAA PHOTOREALISTIC MODEL with organic chunky shape!
            print("🚀 [AAA] Creating photorealistic meat with scale: \(baseSize)")
            let meatMesh = AAAFoodGeometry.createStandardMeat()
            return meatMesh
            
        case .fish:
            // 🐟 FISH: AAA PHOTOREALISTIC MODEL with streamlined aquatic shape!
            print("🚀 [AAA] Creating photorealistic fish with scale: \(baseSize)")
            let fishMesh = AAAFoodGeometry.createStandardFish()
            return fishMesh
            
        case .seeds:
            // 🌱 SEEDS: AAA PHOTOREALISTIC MODEL with clustered seed arrangement!
            print("🚀 [AAA] Creating photorealistic seeds with scale: \(baseSize)")
            let seedsMesh = AAAFoodGeometry.createStandardSeeds()
            return seedsMesh
            
        case .nuts:
            // 🥜 NUTS: AAA PHOTOREALISTIC MODEL with mixed nut shell textures!
            print("🚀 [AAA] Creating photorealistic nuts with scale: \(baseSize)")
            let nutsMesh = AAAFoodGeometry.createStandardNuts()
            return nutsMesh
        }
    }
    
    @available(macOS 14.0, *)
    private func createFoodMaterial(for food: FoodItem) -> RealityKit.Material {
        
        // 🍎🍊🍇🍈🥩🐟🌱🥜 AAA PBR MATERIALS: Check if this food type has AAA materials!
        if [.plum, .apple, .orange, .melon, .meat, .fish, .seeds, .nuts].contains(food.type) {
            // 🎨 Creating photorealistic PBR \(food.type.rawValue) material...
            let energyFactor = Float(food.energyValue / 50.0) // Normalize energy
            return AAAPBRMaterials.createAAAFoodMaterial(
                for: food.type,
                energyLevel: energyFactor,
                freshness: 1.0  // Fresh food in simulation
            )
        }
        
        // 🍎 STANDARD MATERIALS: For other food types (will upgrade later)
        var material = SimpleMaterial()
        
        // 🍎 PHOTOREALISTIC FOOD MATERIALS: Each food type gets distinctive surface properties
        let (foodColor, roughness, metallic) = getFoodProperties(for: food.type)
        
        material.color = .init(tint: foodColor)
        material.roughness = MaterialScalarParameter(floatLiteral: roughness)
        material.metallic = MaterialScalarParameter(floatLiteral: metallic)
        
        // 🌟 ENERGY-BASED ENHANCEMENT: Higher energy foods look more appealing
        let energyBoost = Float(food.energyValue / 100.0) * 0.2
        material.roughness = MaterialScalarParameter(floatLiteral: max(0.1, roughness - energyBoost))
        
        return material
    }
    
    @available(macOS 14.0, *)
    private func getFoodProperties(for foodType: FoodType) -> (NSColor, Float, Float) {
        // 🍎 REALISTIC FOOD PROPERTIES: Color, roughness, and metallic values for each food type
        switch foodType {
        case .apple:
            // 🍎 FRESH APPLE: Glossy red with slight sheen
            return (NSColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0), 0.3, 0.1)
            
        case .orange:
            // 🍊 JUICY ORANGE: Bright orange with bumpy texture
            return (NSColor.orange, 0.6, 0.0)
            
        case .plum:
            // 🫐 RIPE PLUM: Deep purple with waxy surface
            return (NSColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0), 0.2, 0.2)
            
        case .melon:
            // 🍈 FRESH MELON: Vibrant green with natural matte finish
            return (NSColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0), 0.7, 0.0)
            
        case .meat:
            // 🥩 RAW MEAT: Rich red-brown with organic texture
            return (NSColor(red: 0.6, green: 0.3, blue: 0.2, alpha: 1.0), 0.8, 0.0)
            
        case .fish:
            // 🐟 FRESH FISH: Silver-blue with slight shimmer
            return (NSColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0), 0.3, 0.4)
            
        case .seeds:
            // 🌱 SEEDS: Golden yellow with matte finish
            return (NSColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0), 0.9, 0.0)
            
        case .nuts:
            // 🥜 NUTS: Rich brown with hard shell texture
            return (NSColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 1.0), 0.8, 0.0)
        }
    }
    
    @available(macOS 14.0, *)
    private func addFoodAnimation(to entity: Entity) {
        // Create gentle pulsing animation
        // Note: RealityKit animations work differently than SceneKit
        // This is a placeholder - animations can be enhanced later
        let startTransform = entity.transform
        var pulseTransform = startTransform
        pulseTransform.scale *= 1.1
        
        // Simple transform animation (RealityKit style)
        entity.transform = startTransform
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
            // 🚀 ADVANCED: Create detailed multi-part bug entity (ported from SceneKit)
            let bugEntity = createDetailedBugEntity(for: bug, index: index)
            
            // 🎯 FIXED: Use actual simulation coordinates with proper scaling
            // UNIFIED COORDINATE SYSTEM: Same scaling as food items
            let bugX = Float(bug.position3D.x) * 0.1  // 2000 sim units -> 200 RK units
            let bugZ = Float(bug.position3D.y) * 0.1  // 1500 sim units -> 150 RK units
            
            // 🏔️ TERRAIN FOLLOWING: Position bugs at appropriate height above terrain
            let bugY = getTerrainHeightAtPosition(x: bugX, z: bugZ) + 3.0  // 3 units above terrain
            
            bugEntity.position = [bugX, bugY, bugZ]
            // 🎯 FIXED: Use actual bug UUID for proper identification
            bugEntity.name = "Bug_\(bug.id.uuidString)"
            
            bugContainer.addChild(bugEntity)
            
            print("🐛 [RealityKit] Bug \(index): Sim(\(bug.position3D.x), \(bug.position3D.y)) -> RK(\(bugX), \(bugZ))")
        }
        
        anchor.addChild(bugContainer)
        print("✅ [RealityKit] Added \(bugsToShow.count) bug entities scattered across large terrain")
    }
    
    @available(macOS 14.0, *)
    private func createBugMesh(for bug: Bug) -> MeshResource {
        // 🎨 DRAMATIC SPECIES DISTINCTION: Create highly distinctive bug shapes
        let baseSize = Float(bug.dna.size * 3.0) // Larger for better visibility and drama
        
        switch bug.dna.speciesTraits.speciesType {
        case .herbivore:
            // 🦋 MAJESTIC BUTTERFLY: Elegant elongated oval with pronounced curves
            return .generateSphere(radius: baseSize * 0.6) // Slightly larger and more elegant
            
        case .carnivore:
            // ⚔️ FEARSOME PREDATOR: Sharp, angular predatory form like a mantis
            return .generateBox(size: [baseSize * 1.4, baseSize * 0.5, baseSize * 1.8]) // More elongated and menacing
            
        case .omnivore:
            // 🐜 INDUSTRIOUS WORKER: Segmented body like ants/bees
            return .generateCylinder(height: baseSize * 1.6, radius: baseSize * 0.5) // Taller, more pronounced segmentation
            
        case .scavenger:
            // 🪰 AGILE OPPORTUNIST: Compact, rounded form for quick movement
            return .generateBox(size: [baseSize * 0.9, baseSize * 1.2, baseSize * 0.9]) // More compact but distinctive
        }
    }
    
    @available(macOS 14.0, *)
    private func createBugMaterial(for bug: Bug) -> SimpleMaterial {
        var material = SimpleMaterial()
        
        // 🧬 ENHANCED GENETIC SYSTEM: Vivid genetic expression with species enhancement
        let baseGeneticColor = createGeneticExpressedColor(for: bug)
        let enhancedColor = enhanceColorForSpecies(baseGeneticColor, species: bug.dna.speciesTraits.speciesType)
        
        material.color = .init(tint: enhancedColor)
        
        // 🎨 DRAMATIC SPECIES MATERIALS: Highly distinctive surface properties
        switch bug.dna.speciesTraits.speciesType {
        case .herbivore:
            // 🦋 MAGICAL BUTTERFLY: Iridescent, shimmering wing-like surface
            material.metallic = 0.2   // Slight iridescence like butterfly wings
            material.roughness = 0.3  // Smooth, polished surface
            
        case .carnivore:
            // ⚔️ MENACING PREDATOR: Hard chitin with threatening sheen
            material.metallic = 0.7   // High metallic for intimidating appearance
            material.roughness = 0.1  // Very smooth, deadly precision
            
        case .omnivore:
            // 🐜 WORKER ANT: Matte, industrious surface
            material.metallic = 0.05  // Minimal reflection, practical
            material.roughness = 0.8  // Matte finish like working insects
            
        case .scavenger:
            // 🪰 MYSTERIOUS FLY: Oil-slick iridescence, ever-changing
            material.metallic = 0.9   // Maximum iridescence
            material.roughness = 0.2  // Smooth but with character
        }
        
        // 🧬 GENETIC INFLUENCE: Size and traits affect surface properties
        let _ = Float(bug.dna.size)  // Size effect for future material variation
        let _ = Float(bug.energy / 100.0)  // Energy effect for future material variation
        
        // 🧬 GENETIC INFLUENCE: Size and energy affect surface properties
        // Note: Material modification simplified for RealityKit compatibility
        
        return material
    }
    
    @available(macOS 14.0, *)
    private func enhanceColorForSpecies(_ baseColor: NSColor, species: SpeciesType) -> NSColor {
        // 🎨 SPECIES COLOR ENHANCEMENT: Make each species more visually distinct
        var red = baseColor.redComponent
        var green = baseColor.greenComponent  
        var blue = baseColor.blueComponent
        
        switch species {
        case .herbivore:
            // 🦋 BUTTERFLY: Enhance natural greens and soft pastels
            green = min(1.0, green * 1.3)  // Boost green for plant-eating nature
            red = min(1.0, red * 1.1)     // Slight warm enhancement
            blue = min(1.0, blue * 1.2)   // Gentle blue enhancement
            
        case .carnivore:
            // ⚔️ PREDATOR: Enhance reds and aggressive colors
            red = min(1.0, red * 1.5)     // Boost red for predatory nature
            blue = max(0.0, blue * 0.7)   // Reduce blue for warmer tone
            green = max(0.0, green * 0.8) // Slightly reduce green
            
        case .omnivore:
            // 🐜 BALANCED: Enhance earth tones and balanced colors
            red = min(1.0, red * 1.2)     // Warm earth tones
            green = min(1.0, green * 1.1) // Natural balance
            blue = min(1.0, blue * 1.0)   // Keep blue natural
            
        case .scavenger:
            // 🪰 IRIDESCENT: Create oil-slick, shifting colors
            red = min(1.0, red * 1.3)     // Enhance all colors
            green = min(1.0, green * 1.4) // for iridescent effect
            blue = min(1.0, blue * 1.6)   // Strong blue enhancement
        }
        
        return NSColor(red: red, green: green, blue: blue, alpha: baseColor.alphaComponent)
    }
    
    @available(macOS 14.0, *)
    private func createGeneticExpressedColor(for bug: Bug) -> NSColor {
        // 🧬 GENETIC COLOR EXPRESSION: DNA determines visual appearance
        let species = bug.dna.speciesTraits.speciesType
        
        // Base species colors (enhanced from SceneKit)
        let baseHue: Double
        
        switch species {
        case .herbivore:
            baseHue = 0.25 // Green range
            
        case .carnivore:
            baseHue = 0.05 // Red range
            
        case .omnivore:
            baseHue = 0.15 // Orange range
            
        case .scavenger:
            baseHue = 0.75 // Purple range
        }
        
        // 🧬 Apply genetic variation based on DNA
        let geneticVariation = hashBugGenes(bug: bug)
        let hueShift = (geneticVariation - 0.5) * 0.3 // ±15% hue variation
        let finalHue = baseHue + hueShift
        
        // Energy level affects brightness
        let energyRatio = bug.energy / 100.0
        let brightness = max(0.4, min(1.0, energyRatio))
        
        // Age affects color saturation
        let ageEffect = min(1.0, Double(bug.age) / Double(Bug.maxAge))
        let saturation = max(0.3, 1.0 - (ageEffect * 0.4)) // Older bugs are less saturated
        
        // Convert HSB to RGB for final color
        return NSColor(hue: finalHue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
    
    @available(macOS 14.0, *)
    private func hashBugGenes(bug: Bug) -> Double {
        // 🧬 Create a stable hash from bug's genetic properties for consistent coloring
        let hashString = "\(bug.dna.size)\(bug.dna.speed)\(bug.dna.strength)\(bug.dna.camouflage)"
        let hash = hashString.hash
        return Double(abs(hash) % 1000) / 1000.0 // Normalize to 0-1 range
    }
    
    @available(macOS 14.0, *)
    private func createDetailedBugEntity(for bug: Bug, index: Int) -> Entity {
        // 🚀 ADVANCED: Multi-part bug entity system (ported from SceneKit)
        let bugEntity = Entity()
        // 🎯 Note: Parent will set the proper "Bug_\(uuid)" name
        
        let size = Float(bug.dna.size * 2.0) // Scale for visibility
        let species = bug.dna.speciesTraits.speciesType
        
        // Create species-specific detailed body parts
        switch species {
        case .herbivore:
            createDetailedHerbivoreEntity(bug: bug, size: size, parentEntity: bugEntity)
        case .carnivore:
            createDetailedCarnivoreEntity(bug: bug, size: size, parentEntity: bugEntity)
        case .omnivore:
            createDetailedOmnivoreEntity(bug: bug, size: size, parentEntity: bugEntity)
        case .scavenger:
            createDetailedScavengerEntity(bug: bug, size: size, parentEntity: bugEntity)
        }
        
        // Add movement capabilities indicators
        if bug.canFly {
            addWings(to: bugEntity, bug: bug, size: size)
        }
        
        if bug.canSwim {
            addFins(to: bugEntity, bug: bug, size: size)
        }
        
        if bug.canClimb {
            addClimbingGear(to: bugEntity, bug: bug, size: size)
        }
        
        // Scale entire bug for visibility (matching SceneKit's 2x scale)
        bugEntity.scale = [2.0, 2.0, 2.0]
        
        return bugEntity
    }
    
    @available(macOS 14.0, *)
    private func createDetailedHerbivoreEntity(bug: Bug, size: Float, parentEntity: Entity) {
        // 🦋 Butterfly/Beetle-inspired multi-part body
        
        // 1. HEAD: Small rounded head
        let headEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.3),
            materials: [createGeneticMaterial(for: bug, bodyPart: .head)]
        )
        headEntity.position = [0, size * 0.8, 0]
        headEntity.name = "Head"
        parentEntity.addChild(headEntity)
        
        // 2. THORAX: Elongated main body
        let thoraxEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.5),
            materials: [createGeneticMaterial(for: bug, bodyPart: .thorax)]
        )
        thoraxEntity.scale = [1.0, 1.4, 0.8] // Elongated
        thoraxEntity.position = [0, 0, 0]
        thoraxEntity.name = "Thorax"
        parentEntity.addChild(thoraxEntity)
        
        // 3. ABDOMEN: Segmented abdomen
        let abdomenEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.4),
            materials: [createGeneticMaterial(for: bug, bodyPart: .abdomen)]
        )
        abdomenEntity.scale = [0.9, 1.6, 0.7] // Long and narrow
        abdomenEntity.position = [0, -size * 0.9, 0]
        abdomenEntity.name = "Abdomen"
        parentEntity.addChild(abdomenEntity)
        
        // 4. ANTENNAE: Thin antennae
        for i in 0..<2 {
            let antennaEntity = ModelEntity(
                mesh: .generateCylinder(height: size * 0.6, radius: size * 0.05),
                materials: [createGeneticMaterial(for: bug, bodyPart: .antennae)]
            )
            let angle = Float(i) * Float.pi - Float.pi / 2 // Left and right
            antennaEntity.position = [sin(angle) * size * 0.2, size * 1.0, cos(angle) * size * 0.1]
            antennaEntity.name = "Antenna_\(i)"
            parentEntity.addChild(antennaEntity)
        }
    }
    
    @available(macOS 14.0, *)
    private func createDetailedCarnivoreEntity(bug: Bug, size: Float, parentEntity: Entity) {
        // 🥊 Praying Mantis/Wasp-inspired predatory body
        
        // 1. HEAD: Triangular predatory head
        let headEntity = ModelEntity(
            mesh: .generateBox(size: [size * 0.4, size * 0.3, size * 0.5]),
            materials: [createGeneticMaterial(for: bug, bodyPart: .head)]
        )
        headEntity.position = [0, size * 0.9, 0]
        headEntity.name = "Head"
        parentEntity.addChild(headEntity)
        
        // 2. THORAX: Angular muscular thorax
        let thoraxEntity = ModelEntity(
            mesh: .generateBox(size: [size * 0.6, size * 0.8, size * 1.0]),
            materials: [createGeneticMaterial(for: bug, bodyPart: .thorax)]
        )
        thoraxEntity.position = [0, 0, 0]
        thoraxEntity.name = "Thorax"
        parentEntity.addChild(thoraxEntity)
        
        // 3. NARROW WAIST: Characteristic wasp waist
        let waistEntity = ModelEntity(
            mesh: .generateCylinder(height: size * 0.3, radius: size * 0.15),
            materials: [createGeneticMaterial(for: bug, bodyPart: .waist)]
        )
        waistEntity.position = [0, -size * 0.6, 0]
        waistEntity.name = "Waist"
        parentEntity.addChild(waistEntity)
        
        // 4. ABDOMEN: Pointed abdomen
        let abdomenEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.4),
            materials: [createGeneticMaterial(for: bug, bodyPart: .abdomen)]
        )
        abdomenEntity.scale = [1.0, 1.5, 0.8] // Pointed
        abdomenEntity.position = [0, -size * 1.2, 0]
        abdomenEntity.name = "Abdomen"
        parentEntity.addChild(abdomenEntity)
    }
    
    @available(macOS 14.0, *)
    private func createDetailedOmnivoreEntity(bug: Bug, size: Float, parentEntity: Entity) {
        // 🐜 Ant/Bee-inspired segmented body
        
        // 1. HEAD: Rounded head with mandibles
        let headEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.35),
            materials: [createGeneticMaterial(for: bug, bodyPart: .head)]
        )
        headEntity.position = [0, size * 0.8, 0]
        headEntity.name = "Head"
        parentEntity.addChild(headEntity)
        
        // 2. THORAX: Segmented capsule thorax
        let thoraxEntity = ModelEntity(
            mesh: .generateCylinder(height: size * 0.8, radius: size * 0.4), // Approximating capsule
            materials: [createGeneticMaterial(for: bug, bodyPart: .thorax)]
        )
        thoraxEntity.position = [0, 0, 0]
        thoraxEntity.name = "Thorax"
        parentEntity.addChild(thoraxEntity)
        
        // 3. NARROW CONNECTOR: Petiole (ant waist)
        let connectorEntity = ModelEntity(
            mesh: .generateCylinder(height: size * 0.2, radius: size * 0.1),
            materials: [createGeneticMaterial(for: bug, bodyPart: .waist)]
        )
        connectorEntity.position = [0, -size * 0.6, 0]
        connectorEntity.name = "Connector"
        parentEntity.addChild(connectorEntity)
        
        // 4. ABDOMEN: Large segmented abdomen
        let abdomenEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.5),
            materials: [createGeneticMaterial(for: bug, bodyPart: .abdomen)]
        )
        abdomenEntity.scale = [1.0, 1.3, 1.0]
        abdomenEntity.position = [0, -size * 1.0, 0]
        abdomenEntity.name = "Abdomen"
        parentEntity.addChild(abdomenEntity)
    }
    
    @available(macOS 14.0, *)
    private func createDetailedScavengerEntity(bug: Bug, size: Float, parentEntity: Entity) {
        // 🪰 Fly-inspired rounded opportunistic body
        
        // 1. HEAD: Large compound-eyed head
        let headEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.4),
            materials: [createGeneticMaterial(for: bug, bodyPart: .head)]
        )
        headEntity.position = [0, size * 0.7, 0]
        headEntity.name = "Head"
        parentEntity.addChild(headEntity)
        
        // 2. THORAX: Robust rounded thorax
        let thoraxEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.6),
            materials: [createGeneticMaterial(for: bug, bodyPart: .thorax)]
        )
        thoraxEntity.scale = [1.2, 0.8, 1.0] // Wide and flat
        thoraxEntity.position = [0, 0, 0]
        thoraxEntity.name = "Thorax"
        parentEntity.addChild(thoraxEntity)
        
        // 3. ABDOMEN: Large rounded abdomen
        let abdomenEntity = ModelEntity(
            mesh: .generateSphere(radius: size * 0.5),
            materials: [createGeneticMaterial(for: bug, bodyPart: .abdomen)]
        )
        abdomenEntity.scale = [1.1, 1.4, 1.0]
        abdomenEntity.position = [0, -size * 0.8, 0]
        abdomenEntity.name = "Abdomen"
        parentEntity.addChild(abdomenEntity)
    }
    
    // 🎨 Body part types for genetic material variation
    enum BugBodyPart {
        case head, thorax, abdomen, waist, antennae, legs, wings, fins
    }
    
    @available(macOS 14.0, *)
    private func createGeneticMaterial(for bug: Bug, bodyPart: BugBodyPart) -> SimpleMaterial {
        // 🧬 Create specialized materials for different body parts
        var material = SimpleMaterial()
        
        // Base genetic color
        let baseColor = createGeneticExpressedColor(for: bug)
        
        // Body part specific variations
        let partColor: NSColor
        switch bodyPart {
        case .head:
            // Heads are slightly brighter
            let brightness = min(1.0, baseColor.brightnessComponent * 1.2)
            partColor = NSColor(hue: baseColor.hueComponent, saturation: baseColor.saturationComponent, brightness: brightness, alpha: 1.0)
        case .thorax:
            // Thorax uses base color
            partColor = baseColor
        case .abdomen:
            // Abdomen is slightly darker
            let brightness = max(0.2, baseColor.brightnessComponent * 0.8)
            partColor = NSColor(hue: baseColor.hueComponent, saturation: baseColor.saturationComponent, brightness: brightness, alpha: 1.0)
        case .waist, .antennae:
            // Smaller parts are darker and more subdued
            let saturation = max(0.3, baseColor.saturationComponent * 0.6)
            partColor = NSColor(hue: baseColor.hueComponent, saturation: saturation, brightness: baseColor.brightnessComponent, alpha: 1.0)
        case .legs:
            // Legs are darker and less saturated
            partColor = NSColor.darkGray
        case .wings:
            // Wings are translucent
            partColor = NSColor(hue: baseColor.hueComponent, saturation: baseColor.saturationComponent, brightness: baseColor.brightnessComponent, alpha: 0.6)
        case .fins:
            // Fins have a blue tint
            partColor = NSColor(hue: 0.6, saturation: 0.7, brightness: baseColor.brightnessComponent, alpha: 1.0) // Blue tint
        }
        
        material.color = .init(tint: partColor)
        
        // Body part specific material properties
        switch bodyPart {
        case .head:
            material.metallic = 0.1
            material.roughness = 0.7
        case .thorax, .abdomen:
            material.metallic = 0.0
            material.roughness = 0.8
        case .waist, .antennae:
        material.metallic = 0.2
            material.roughness = 0.5
        case .legs:
            material.metallic = 0.3
            material.roughness = 0.4
        case .wings:
            material.metallic = 0.0
            material.roughness = 0.1
            // Note: Transparency handled in color alpha, not separate opacity property
        case .fins:
            material.metallic = 0.4
            material.roughness = 0.2
        }
        
        return material
    }
    
    @available(macOS 14.0, *)
    private func addWings(to bugEntity: Entity, bug: Bug, size: Float) {
        // 🦋 Add wings for flying bugs
        for i in 0..<2 {
            let wingEntity = ModelEntity(
                mesh: .generatePlane(width: size * 0.8, height: size * 0.4),
                materials: [createGeneticMaterial(for: bug, bodyPart: .wings)]
            )
            let side = i == 0 ? -1.0 : 1.0
            wingEntity.position = [Float(side) * size * 0.6, size * 0.3, 0]
            wingEntity.transform.rotation = simd_quatf(angle: Float.pi * 0.1, axis: [0, 0, 1])
            wingEntity.name = "Wing_\(i)"
            bugEntity.addChild(wingEntity)
        }
    }
    
    @available(macOS 14.0, *)
    private func addFins(to bugEntity: Entity, bug: Bug, size: Float) {
        // 🐟 Add fins for swimming bugs
        for i in 0..<4 {
            let finEntity = ModelEntity(
                mesh: .generatePlane(width: size * 0.3, height: size * 0.2),
                materials: [createGeneticMaterial(for: bug, bodyPart: .fins)]
            )
            let angle = Float(i) * Float.pi / 2
            finEntity.position = [sin(angle) * size * 0.4, 0, cos(angle) * size * 0.4]
            finEntity.name = "Fin_\(i)"
            bugEntity.addChild(finEntity)
        }
    }
    
    @available(macOS 14.0, *)
    private func addClimbingGear(to bugEntity: Entity, bug: Bug, size: Float) {
        // 🧗 Add climbing appendages for climbing bugs
        for i in 0..<6 {
            let legEntity = ModelEntity(
                mesh: .generateCylinder(height: size * 0.4, radius: size * 0.03),
                materials: [createGeneticMaterial(for: bug, bodyPart: .legs)]
            )
            let angle = Float(i) * Float.pi / 3
            legEntity.position = [sin(angle) * size * 0.5, -size * 0.2, cos(angle) * size * 0.5]
            legEntity.transform.rotation = simd_quatf(angle: Float.pi * 0.5, axis: [1, 0, 0])
            legEntity.name = "ClimbingLeg_\(i)"
            bugEntity.addChild(legEntity)
        }
    }
    
    @available(macOS 14.0, *)
    private func getTerrainHeightAtPosition(x: Float, z: Float) -> Float {
        // 🏔️ TERRAIN HEIGHT: Sample height from simulation's height map
        let voxelWorld = simulationEngine.voxelWorld
        let heightMap = voxelWorld.heightMap
        let resolution = heightMap.count
        
        // Convert world position to height map coordinates
        let terrainSize: Float = 8.0 * 32.0  // Match terrain scale * resolution
        let normalizedX = (x + terrainSize/2) / terrainSize  // 0-1 range
        let normalizedZ = (z + terrainSize/2) / terrainSize  // 0-1 range
        
        // Clamp to valid range and sample height map
        let clampedX = max(0, min(0.99, normalizedX))
        let clampedZ = max(0, min(0.99, normalizedZ))
        
        let mapX = Int(clampedX * Float(resolution))
        let mapZ = Int(clampedZ * Float(resolution))
        
        let height = heightMap[mapX][mapZ]
        return Float(height) * 0.8  // Match heightScale from terrain creation
    }
    
    @available(macOS 14.0, *)
    private func updateBugPositions() {
        // ✅ ENABLED: Real-time position updates with proper coordinate scaling
        guard let anchor = sceneAnchor,
              let bugContainer = anchor.findEntity(named: "BugContainer") else { return }
        
        let simulationScale: Float = 0.05  // Same scale used for initial positioning
        
        // Update positions for all live bugs
        for bug in simulationEngine.bugs.filter({ $0.isAlive }) {
            if let bugEntity = bugContainer.findEntity(named: "Bug_\(bug.id.uuidString)") {
                // Convert simulation coordinates to RealityKit coordinates
                let bugX = Float(bug.position3D.x) * simulationScale
                let bugZ = Float(bug.position3D.y) * simulationScale
                let bugY = getTerrainHeightAtPosition(x: bugX, z: bugZ) + 3.0
                
                // Smooth movement to prevent jarring updates
                let targetPosition = SIMD3<Float>(bugX, bugY, bugZ)
                let currentPosition = bugEntity.position
                let lerpFactor: Float = 0.1  // Smooth interpolation
                let newPosition = simd_mix(currentPosition, targetPosition, SIMD3<Float>(repeating: lerpFactor))
                
                bugEntity.position = newPosition
            }
        }
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
        
        // 🚀 MASSIVE INCREASE: More voxels for larger world (was 20)
        let maxVoxelsPerType = min(100, voxels.count)
        let renderVoxels = Array(voxels.prefix(maxVoxelsPerType))
        
        for voxel in renderVoxels {
            let voxelEntity = ModelEntity(
                mesh: .generateBox(size: voxelSize * 0.8), // Slightly smaller for visual separation
                materials: [createVoxelMaterial(for: terrainType)]
            )
            
            // Convert Bugtopia coordinates to RealityKit coordinates
            // 🚀 MASSIVE SCALE: Scale up voxel positions for large world
            let scale: Float = 4.0  // 4x larger voxel spacing (was 1.0)
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
            // 🏔️ CLAY HILLS: Using Style Guide color palette #CC8E35 for elevated, ancient terrain
            let clayColor = NSColor(red: 0.8, green: 0.557, blue: 0.208, alpha: 1.0)
            material.color = .init(tint: clayColor)
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
        
        guard let anchor = sceneAnchor else {
            print("❌ [RealityKit] No scene anchor found for tap detection")
            return
        }
        
        // Add more debug info
        print("🎯 [RealityKit] Camera position: \(cameraPosition)")
        print("🎯 [RealityKit] Scene anchor exists, attempting entity selection...")
        
        // Perform entity selection
        selectEntityAt(location: location, in: anchor)
    }
    
    @available(macOS 14.0, *)
    private func selectEntityAt(location: CGPoint, in anchor: AnchorEntity) {
        print("🎯 [RealityKit] Starting entity selection at \(location)...")
        
        // 🎯 IMPROVED: Use proper raycasting for entity selection
        // For now, we'll implement a distance-based selection as proper raycasting 
        // requires more complex RealityView integration
        
        var closestBugEntity: Entity?
        var closestFoodEntity: Entity?
        var closestBugDistance: Float = Float.greatestFiniteMagnitude
        var closestFoodDistance: Float = Float.greatestFiniteMagnitude
        
        // Find closest bug entity to the tap location
        if let bugContainer = anchor.findEntity(named: "BugContainer") {
            print("🐛 [RealityKit] Found BugContainer with \(bugContainer.children.count) children")
            
            for child in bugContainer.children {
                if child.name.hasPrefix("Bug_") {
                    // Simple distance check from camera center (more sophisticated raycasting would be ideal)
                    let bugPosition = child.position
                    let distanceFromCenter = simd_length(bugPosition - cameraPosition)
                    
                    if distanceFromCenter < closestBugDistance {
                        closestBugDistance = distanceFromCenter
                        closestBugEntity = child
                    }
                }
            }
        }
        
        // Find closest food entity to the tap location
        if let foodContainer = anchor.findEntity(named: "FoodContainer") {
            print("🍎 [RealityKit] Found FoodContainer with \(foodContainer.children.count) children")
            
            for child in foodContainer.children {
                if child.name.hasPrefix("Food_") {
                    let foodPosition = child.position
                    let distanceFromCenter = simd_length(foodPosition - cameraPosition)
                    
                    if distanceFromCenter < closestFoodDistance {
                        closestFoodDistance = distanceFromCenter
                        closestFoodEntity = child
                    }
                }
            }
        }
        
        // Select the closest entity (bug or food)
        if let bugEntity = closestBugEntity, 
           (closestFoodEntity == nil || closestBugDistance < closestFoodDistance) {
            print("🎯 [RealityKit] Selecting closest bug: \(bugEntity.name) at distance \(closestBugDistance)")
            selectBugEntity(bugEntity)
        } else if let foodEntity = closestFoodEntity {
            print("🎯 [RealityKit] Selecting closest food: \(foodEntity.name) at distance \(closestFoodDistance)")
            selectFoodEntity(foodEntity)
        } else {
            print("❌ [RealityKit] No entities found to select")
            deselectAllEntities()
        }
    }
    
    private func selectBugEntity(_ entity: Entity?) {
        guard let entity = entity else {
            print("❌ [RealityKit] No bug entity to select")
            return
        }
        
        print("🎯 [RealityKit] Attempting to select bug entity: \(entity.name)")
        
        // Extract bug ID from entity name
        let name = entity.name
        if name.hasPrefix("Bug_") {
            let bugIdString = String(name.dropFirst(4)) // Remove "Bug_" prefix
            print("🎯 [RealityKit] Extracted bug ID string: \(bugIdString)")
            
            if let bugId = UUID(uuidString: bugIdString) {
                print("🎯 [RealityKit] Parsed bug UUID: \(bugId)")
                
                // Find the corresponding bug from the simulation
                let totalBugs = simulationEngine.bugs.count
                print("🎯 [RealityKit] Searching through \(totalBugs) simulation bugs...")
                
                if let bug = simulationEngine.bugs.first(where: { $0.id == bugId }) {
                    print("✅ [RealityKit] Found matching bug!")
                    print("🐛 [RealityKit] Selected bug: \(bug.dna.speciesTraits.speciesType.rawValue) (\(bugId))")
                    
                    // Notify the selection system (similar to SceneKit)
                    notifyBugSelection(bug)
                    return
                } else {
                    print("❌ [RealityKit] No matching bug found in simulation")
                }
            } else {
                print("❌ [RealityKit] Could not parse UUID from: \(bugIdString)")
            }
        } else {
            print("❌ [RealityKit] Entity name doesn't start with 'Bug_': \(name)")
        }
        
        print("❌ [RealityKit] Could not find bug data for entity: \(name)")
        deselectAllEntities()
    }
    
    private func selectFoodEntity(_ entity: Entity?) {
        guard let entity = entity else {
            print("❌ [RealityKit] No food entity to select")
            return
        }
        
        // Extract food index from entity name
        let name = entity.name
        if name.hasPrefix("Food_") {
            let indexString = String(name.dropFirst(5)) // Remove "Food_" prefix
            if let index = Int(indexString) {
                // Find the corresponding food from the simulation
                let foods = simulationEngine.foods
                if index < foods.count {
                    let food = foods[index]
                    print("🍎 [RealityKit] Selected food: \(food.type.rawValue) at \(food.position)")
                    
                    // Notify the selection system (similar to SceneKit)
                    notifyFoodSelection(food)
                    return
                }
            }
        }
        
        print("❌ [RealityKit] Could not find food data for entity: \(name)")
        deselectAllEntities()
    }
    
    private func deselectAllEntities() {
        print("🔄 [RealityKit] Deselecting all entities")
        notifyBugSelection(nil)
        notifyFoodSelection(nil)
    }
    
    // MARK: - Selection Notification System
    
    private func notifyBugSelection(_ bug: Bug?) {
        DispatchQueue.main.async {
            self.onBugSelectedCallback?(bug)
        }
        
        // 🎯 Add visual feedback for selection
        if let bug = bug {
            print("✅ [RealityKit] Successfully selected bug: \(bug.dna.speciesTraits.speciesType.rawValue)")
            print("📊 [RealityKit] Bug Stats - Energy: \(bug.energy), Speed: \(bug.dna.speed), Size: \(bug.dna.size)")
        } else {
            print("🔄 [RealityKit] Bug deselected")
        }
    }
    
    private func notifyFoodSelection(_ food: FoodItem?) {
        DispatchQueue.main.async {
            self.onFoodSelectedCallback?(food)
        }
        
        // 🍎 Add visual feedback for food selection
        if let food = food {
            print("✅ [RealityKit] Successfully selected food: \(food.type.rawValue)")
            print("📊 [RealityKit] Food Stats - Energy: \(food.energyValue), Position: \(food.position)")
        } else {
            print("🔄 [RealityKit] Food deselected")
        }
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
            // 🏔️ CLAY HILLS: Using Style Guide color palette #CC8E35 for elevated, ancient terrain
            let clayColor = NSColor(red: 0.8, green: 0.557, blue: 0.208, alpha: 1.0)
            material.color = .init(tint: clayColor)
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
            bugEntity.name = "Bug_\(bug.id.uuidString)"
            
            // Create sphere geometry for bugs
            let sphereMesh = MeshResource.generateSphere(radius: 2.0) // Visible size
            let bugMaterial = createBugMaterial3D(for: bug)
            let modelComponent = ModelComponent(mesh: sphereMesh, materials: [bugMaterial])
            
            bugEntity.components.set(modelComponent)
            
            // Position bug in 3D space with proper coordinate scaling
            let simulationScale: Float = 0.05  // Same scale used everywhere else
            let position = SIMD3<Float>(
                Float(bug.position3D.x) * simulationScale,
                Float(bug.position3D.z + 5), // Slightly above terrain
                Float(bug.position3D.y) * simulationScale
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
    
    // MARK: - Entity Update System
    
    private func startEntityUpdates() {
        lastUpdateTime = CACurrentMediaTime()
        
        // Start entity update timer (30 FPS for smooth movement)
        Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { timer in
            self.updateEntities()
        }
    }
    
    private func stopEntityUpdates() {
        // Timer cleanup handled by weak reference
    }
    
    private func updateEntities() {
        guard let anchor = sceneAnchor else { return }
        
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update bug positions and behaviors
        updateBugEntities(in: anchor, deltaTime: Float(deltaTime))
        
        // Update food entities (spawn new, remove consumed)
        updateFoodEntities(in: anchor)
        
        // Update performance metrics (if accessible)
        // bugEntityManager.performanceMetrics.lastUpdateDuration = deltaTime
    }
    
    private func updateBugEntities(in anchor: Entity, deltaTime: Float) {
        guard let bugContainer = anchor.findEntity(named: "BugContainer") else { return }
        
        let currentBugs = simulationEngine.bugs.filter { $0.isAlive }
        
        // Update existing bug positions
        for bug in currentBugs {
            if let bugEntity = bugContainer.findEntity(named: "Bug_\(bug.id.uuidString)") {
                // Calculate new position with terrain following
                let simulationScale: Float = 0.1  // UNIFIED: Same as food items
                let scaledX = Float(bug.position3D.x) * simulationScale
                let scaledZ = Float(bug.position3D.y) * simulationScale
                let terrainHeight = getTerrainHeightAtPosition(x: scaledX, z: scaledZ)
                let newPosition = SIMD3<Float>(
                    scaledX, // Use consistent simulation scaling
                    terrainHeight + 1.5, // Above terrain
                    scaledZ  // Use consistent simulation scaling
                )
                
                // Smooth interpolation for natural movement
                let currentPosition = bugEntity.position
                let lerpFactor: Float = min(1.0, deltaTime * 5.0) // Smooth lerp
                let mixedPosition = simd_mix(currentPosition, newPosition, SIMD3<Float>(repeating: lerpFactor))
                bugEntity.position = mixedPosition
            }
        }
        
        // Remove entities for dead bugs
        for child in bugContainer.children {
            if child.name.hasPrefix("Bug_") {
                let name = child.name
                let bugIdString = String(name.dropFirst(4)) // Remove "Bug_" prefix
                if let bugId = UUID(uuidString: bugIdString) {
                    let bugExists = currentBugs.contains { $0.id == bugId }
                    if !bugExists {
                        child.removeFromParent()
                    }
                }
            }
        }
        
        // Add entities for new bugs
        for bug in currentBugs {
            if bugContainer.findEntity(named: "Bug_\(bug.id.uuidString)") == nil {
                let bugEntity = createDetailedBugEntity(for: bug, index: 0)
                bugEntity.name = "Bug_\(bug.id.uuidString)"
                bugContainer.addChild(bugEntity)
            }
        }
    }
    
    private func updateFoodEntities(in anchor: Entity) {
        guard let foodContainer = anchor.findEntity(named: "FoodContainer") else { return }
        
        let currentFoods = simulationEngine.foods
        let existingFoodEntities = foodContainer.children
        
        // Remove consumed food entities
        for foodEntity in existingFoodEntities {
            if foodEntity.name.hasPrefix("Food_") {
                let name = foodEntity.name
                let indexString = String(name.dropFirst(5)) // Remove "Food_" prefix
                if let index = Int(indexString) {
                    // Check if food still exists at this index
                    if index >= currentFoods.count {
                        foodEntity.removeFromParent()
                    }
                }
            }
        }
        
        // Add new food entities
        let existingCount = existingFoodEntities.count
        if currentFoods.count > existingCount {
            for index in existingCount..<currentFoods.count {
                let food = currentFoods[index]
                let foodEntity = createFoodEntity(for: food, index: index)
                foodContainer.addChild(foodEntity)
            }
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
        
        // 🌟 SPACE BAR: Toggle god/walk mode (keyCode 49)
        if keyCode == 49 {
            toggleGodWalkMode()
            return  // Don't add space to pressed keys for movement
        }
        
        pressedKeys.insert(keyCode)
        print("🎮 NAVIGATION: Key pressed: \(keyCode) | God Mode: \(isGodMode)")
    }
    
    private func handleKeyUp(_ event: NSEvent) {
        let keyCode = event.keyCode
        pressedKeys.remove(keyCode)
        print("🎮 Key released: \(keyCode)")
    }
    
    // MARK: - God/Walk Mode Toggle System
    
    private func toggleGodWalkMode() {
        isGodMode.toggle()
        
        if isGodMode {
            print("🌟 [MODE] Switched to GOD MODE - Free flying navigation")
            print("📊 [GOD] Camera Position: \(cameraPosition)")
            print("📊 [GOD] Camera Pitch: \(cameraPitch * 180 / .pi)°")
            print("📊 [GOD] Camera Yaw: \(cameraYaw * 180 / .pi)°")
        } else {
            print("🚶 [MODE] Switched to WALK MODE - Terrain collision")
            
            // 🏃 WALK MODE: Move camera to terrain level
            let terrainHeight = getTerrainHeightAt(x: cameraPosition.x, z: cameraPosition.z)
            cameraPosition.y = terrainHeight + walkModeHeight
            
            print("📊 [WALK] Terrain Height: \(terrainHeight)")
            print("📊 [WALK] New Camera Height: \(cameraPosition.y)")
            print("📊 [WALK] Walk Mode Height Offset: \(walkModeHeight)")
            
            // Update scene anchor to new position
            if let anchor = sceneAnchor {
                anchor.transform.translation = -cameraPosition
                print("📊 [WALK] Updated anchor translation: \(-cameraPosition)")
            }
        }
    }
    
    private func getTerrainHeightAt(x: Float, z: Float) -> Float {
        // 🌍 TERRAIN HEIGHT: Get the actual terrain height at this position
        // For now, return ground level - this should eventually query the voxel world
        let groundLevel: Float = 0.0
        
        // TODO: Query SimulationEngine's VoxelWorld for actual terrain height
        // This would require converting camera coordinates back to voxel coordinates
        
        print("🌍 [TERRAIN] Getting height at (\(x), \(z)) = \(groundLevel)")
        return groundLevel
    }
    
    private func canMoveToPosition(x: Float, z: Float) -> Bool {
        // 🚫 COLLISION DETECTION: Check if we can move to this position in walk mode
        // For now, always allow movement - this should eventually check for solid terrain
        
        // TODO: Check SimulationEngine's VoxelWorld for solid voxels at this position
        // This would prevent walking through mountains, trees, etc.
        
        print("🚫 [COLLISION] Checking movement to (\(x), \(z)) = allowed")
        return true
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
        
        print("🎮 [TRACKPAD] Raw deltas - X: \(event.deltaX), Y: \(event.deltaY)")
        print("🎮 [TRACKPAD] Calculated deltas - Pitch: \(pitchDelta * 180 / .pi)°, Yaw: \(yawDelta * 180 / .pi)°")
        
        var rotationChanged = false
        
        // Handle vertical scrolling (pitch - up/down look)
        if abs(event.deltaY) > 0.1 {
            let oldPitch = cameraPitch
            cameraPitch += pitchDelta
            
            // 🔒 CONSTRAIN PITCH: Prevent over-rotation (looking too far up/down)
            cameraPitch = max(-Float.pi/2.1, min(Float.pi/2.1, cameraPitch))
            rotationChanged = true
            
            print("🎮 [PITCH] \(oldPitch * 180 / .pi)° → \(cameraPitch * 180 / .pi)° (delta: \(pitchDelta * 180 / .pi)°)")
        }
        
        // Handle horizontal scrolling (yaw - left/right look)
        if abs(event.deltaX) > 0.1 {
            let oldYaw = cameraYaw
            cameraYaw += yawDelta
            
            // 🔄 NORMALIZE YAW: Keep yaw in 0-360° range for cleaner values
            while cameraYaw > Float.pi { cameraYaw -= 2 * Float.pi }
            while cameraYaw < -Float.pi { cameraYaw += 2 * Float.pi }
            rotationChanged = true
            
            print("🎮 [YAW] \(oldYaw * 180 / .pi)° → \(cameraYaw * 180 / .pi)° (delta: \(yawDelta * 180 / .pi)°)")
        }
        
        // Apply combined rotation to the scene
        if rotationChanged {
            guard let anchor = sceneAnchor else { 
                print("❌ [TRACKPAD] No scene anchor available for rotation")
                return 
            }
            
            // 🔒 ORIENTATION LOCK: Create rotation that maintains up vector
            let newRotation = createOrientationLockedRotation()
            anchor.transform.rotation = newRotation
            print("🔄 [ROTATION] Applied new rotation to scene anchor")
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
        let oldPosition = cameraPosition
        
        // 🌟 GOD MODE: Free movement vs 🚶 WALK MODE: Constrained movement
        if isGodMode {
            // Move camera position left (negative X)
            cameraPosition.x -= distance
            print("⬅️ [GOD] Moving LEFT: \(oldPosition.x) → \(cameraPosition.x) (distance: \(distance))")
        } else {
            // Walk mode: check for collision and stay at terrain level
            let newX = cameraPosition.x - distance
            let terrainHeight = getTerrainHeightAt(x: newX, z: cameraPosition.z)
            
            // Only move if not colliding with terrain obstacles
            if canMoveToPosition(x: newX, z: cameraPosition.z) {
                cameraPosition.x = newX
                cameraPosition.y = terrainHeight + walkModeHeight
                print("⬅️ [WALK] Moving LEFT: \(oldPosition.x) → \(cameraPosition.x) (terrain: \(terrainHeight))")
            } else {
                print("⬅️ [WALK] BLOCKED: Cannot move left due to terrain collision")
                return  // Exit early if blocked
            }
        }
        
        // Update the world anchor (negative because we move the world opposite to camera)
        anchor.transform.translation = -cameraPosition
        print("📍 [ANCHOR] Translation updated: \(-cameraPosition)")
        
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
        
        // 🔧 FORWARD: Move INTO the 200×150 terrain (positive Z direction)
        cameraPosition.z += distance
        
        // Update the world anchor (negative because we move the world opposite to camera)
        anchor.transform.translation = -cameraPosition
        
        // 🔒 MAINTAIN ORIENTATION: Keep proper up vector when moving
        anchor.transform.rotation = createOrientationLockedRotation()
        
        updateDebugInfo()
        print("⬆️ [FORWARD] Camera: Z \(cameraPosition.z - distance) → \(cameraPosition.z) | Anchor: \(-cameraPosition)")
    }
    
    // 🎮 SIMPLIFIED: Basic backward movement
    private func moveBackward(deltaTime: Float, anchor: AnchorEntity) {
        let distance = movementSpeed * deltaTime
        
        // 🔧 BACKWARD: Move OUT of the 200×150 terrain (negative Z direction)  
        cameraPosition.z -= distance
        
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

