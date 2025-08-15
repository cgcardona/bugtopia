//
//  Arena3DView.swift
//  Bugtopia
//
//  Created by Assistant on 8/1/25.
//

import SwiftUI
import SceneKit
import ModelIO

// 🎮 NAVIGATION MODES for dual camera system
enum NavigationMode {
    case walking  // First person ground-level with terrain following
    case god      // Free flight mode
}

/// Epic 3D visualization of the Bugtopia simulation
struct Arena3DView: NSViewRepresentable {
    let simulationEngine: SimulationEngine
    
    // 🎯 Bug Selection System
    var onBugSelected: ((Bug?) -> Void)?
    
    // 🍎 Food Selection System
    var onFoodSelected: ((FoodItem?) -> Void)?
    
    // 🐛 SINGLE BUG DEBUG: Class-level scene storage for timer access
    private static var globalPersistentScene: SCNScene? = nil
    
    init(simulationEngine: SimulationEngine, onBugSelected: ((Bug?) -> Void)? = nil, onFoodSelected: ((FoodItem?) -> Void)? = nil) {
        self.simulationEngine = simulationEngine
        self.onBugSelected = onBugSelected
        self.onFoodSelected = onFoodSelected
        
        // 🔍 MEMORY LEAK DEBUG: Track Arena3DView creation
        MemoryLeakTracker.shared.trackArena3DViewCreation()
    }
    
    // 🔧 MEMORY LEAK FIX: Add coordinator for proper cleanup
    class Coordinator {
        var navigationResponder: NavigationResponderView?
        
        deinit {
            // 🔍 MEMORY LEAK DEBUG: Track coordinator cleanup
            // Debug logging disabled for gameplay focus
            
            // Clean up navigation responder and its timer
            if let timer = navigationResponder?.updateTimer {
                MemoryLeakTracker.shared.trackTimerInvalidation(description: "NavigationResponder updateTimer (Coordinator deinit)")
                timer.invalidate()
            }
            navigationResponder?.removeFromSuperview()
            NavigationResponderView.currentInstance = nil
            
            // Clear global scene reference
            Arena3DView.globalPersistentScene = nil
            
            // Track Arena3DView destruction
            MemoryLeakTracker.shared.trackArena3DViewDestruction()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    @State private var sceneView: SCNView?
    @State private var cameraNode: SCNNode?
    @State private var isAnimating = true
    
    // Camera controls
    @State private var cameraPosition: SCNVector3 = SCNVector3(0, 200, 300)
    @State private var cameraRotation: SCNVector4 = SCNVector4(1, 0, 0, -0.3)
    
    // 🎮 DUAL NAVIGATION SYSTEM
    @State private var navigationMode: NavigationMode = .god
    @State private var walkingHeight: Float = 10.0  // Height above ground for walking mode
    @State private var movementSpeed: Float = 50.0  // Movement speed
    @State private var rotationSpeed: Float = 1.0   // Rotation speed
    
    // PHASE 1 DEBUG: Synchronization system
    @State private var syncTimer: Timer?
    @State private var bugNodeMapping: [UUID: SCNNode] = [:]
    
    // 🎯 Bug Selection Mapping
    @State private var bugNodeToBugMapping: [SCNNode: Bug] = [:]
    
    // 🍎 Food Selection Mapping
    @State private var foodNodeToFoodMapping: [SCNNode: FoodItem] = [:]
    
    // Track previous alive state to detect death transitions
    @State private var previousBugAliveState: [UUID: Bool] = [:]
    
    // Track previous generation to detect generation changes
    @State private var previousGeneration: Int = -1 // Start at -1 to catch first generation
    
    // Track individual bug IDs to detect population replacements
    @State private var previousBugIds: Set<UUID> = []
    @State private var navigationResponder: NavigationResponderView?
    
    // 🎮 AAA PERFORMANCE MONITORING
    @State private var performanceLogger = PerformanceLogger()
    
    // Static variables for timing outside view update cycle
    private static var frameTimeTracker: CFTimeInterval = 0
    

    

    

    
    /// 🎮 AAA PERFORMANCE: Public method to trigger performance analysis
    func triggerPerformanceAnalysis() {
        DispatchQueue.main.async {
            self.performanceLogger.logPerformanceReport()
            
            // Additional frame timing analysis
            self.analyzeFrameTiming()
        }
    }
    

    

    
    // MARK: - 🎯 Bug Selection System
    
    /// Set up click detection for bug selection using NavigationResponderView
    private func setupBugSelection(sceneView: SCNView) {
        // Bug selection will be handled by NavigationResponderView's mouse events
        // Since we can't use @objc in a struct, we'll use the existing navigation system
    }
    
    /// 🎮 AAA PERFORMANCE: Analyze frame timing and detect stutters
    private func analyzeFrameTiming() {
        let currentTime = CACurrentMediaTime()
        // Use static variable for frame timing instead of @State to avoid modification warnings
        let frameTime = currentTime - Self.frameTimeTracker
        Self.frameTimeTracker = currentTime
        
        // Remove state updates to avoid view update violations
        // Performance tracking moved to dedicated system outside view updates
        
        // Calculate FPS
        let fps = frameTime > 0 ? 1.0 / frameTime : 0
        
        // Detect performance issues
        if frameTime > 0.033 { // > 30 FPS
        }
        if frameTime > 0.016 { // > 60 FPS
        }
        
        // Memory usage (rough estimate)
        var memInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryMB = Double(memInfo.resident_size) / (1024 * 1024)
        }
    }
    
    func makeNSView(context: Context) -> SCNView {
        let sceneView = SCNView()
        
        // Store sceneView reference directly since we're in view creation
        self.sceneView = sceneView
        
        // Create the 3D scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Store scene reference globally for timer access
        Arena3DView.globalPersistentScene = scene
        
        // Configure scene view
        sceneView.backgroundColor = NSColor.black
        sceneView.allowsCameraControl = false  // Disable built-in - we'll handle navigation
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = false
        
        // Clean visual appearance (no debug overlays)
        sceneView.debugOptions = []
        
        // 🎯 Enable bug selection via clicks
        setupBugSelection(sceneView: sceneView)
        
        // Set up the epic 3D world
        setupScene(scene: scene)
        setupLighting(scene: scene)
        setupCamera(scene: scene)
        setupEnvironmentalContext(scene: scene)
        addNavigationAids(scene: scene)
        
        // 🎨 VAN GOGH MATERIALS READY
        // Materials will be created fresh (no caching system active)
        
        // Render the world with fresh Van Gogh materials
        renderTerrain(scene: scene)
        renderBugs(scene: scene)
        renderTerritories(scene: scene)
        
        // 🎮 SET UP PROPER DUAL NAVIGATION SYSTEM
        setupDualNavigationSystem(sceneView: sceneView, scene: scene)
        
        // Dual Navigation: Walking Mode + God Mode ready
        
        return sceneView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        // 🔧 MEMORY LEAK FIX: Store navigation responder reference in coordinator
        if let navResponder = navigationResponder {
            context.coordinator.navigationResponder = navResponder
        }
        // ✅ FIXED: Removed StateViolationDetector reference to fix build issues
        
        // SwiftUI update tracking (avoid state modification during view updates)
        Arena3DView.swiftuiUpdateCount += 1
        
        if Arena3DView.swiftuiUpdateCount % 10 == 0 {
        }
        
        // ✅ FIX: Move scene updates out of SwiftUI update cycle to prevent violations
        guard let scene = nsView.scene else { 
            return 
        }
        
        // 🎮 AAA GAME DEV: Debug SwiftUI-SceneKit bridge
        let currentTime = CACurrentMediaTime()
        if Int(currentTime) % 2 == 0 && Int(currentTime * 10) % 10 == 0 { // Log every 2 seconds
        }
        
        // Update scene directly since we're already on main thread during view updates  
        // Schedule bug visual refresh - remove state tracking to avoid modification warnings
        // Use a simple one-time check based on scene content instead of @State
        let bugContainer = scene.rootNode.childNode(withName: "BugContainer", recursively: false)
        let existingBugNodes = bugContainer?.childNodes.filter { $0.name?.hasPrefix("Bug_") == true } ?? []
        
        if existingBugNodes.isEmpty || existingBugNodes.count != simulationEngine.bugs.count {
            refreshAllBugVisuals(scene: scene)
        }
        
        updateBugPositions(scene: scene)
        
        // 🚨 FOOD SYSTEM: Use the performance-optimized food rendering system
        updateFoodPositionsThrottled(scene: scene)
        
        updateTerritoryVisualizations(scene: scene)
        
        // 🔍 MEMORY LEAK DEBUG: Track dictionary sizes every 150 updates (~5 seconds)
        if Arena3DView.swiftuiUpdateCount % 150 == 0 {
            MemoryLeakTracker.shared.trackDictionarySizes(
                bugMappings: bugNodeToBugMapping.count,
                foodMappings: foodNodeToFoodMapping.count
            )
        }
        
        // 🔧 MEMORY LEAK FIX: Periodically clean up orphaned mappings
        if Arena3DView.swiftuiUpdateCount % 300 == 0 { // Every ~10 seconds at 30fps
            cleanupOrphanedMappings()
        }
        
        // 🎮 AAA GAME DEV: Force scene refresh after updates
        nsView.setNeedsDisplay(nsView.bounds)
    }
    
    // 🔧 MEMORY LEAK FIX: Clean up orphaned node mappings
    private func cleanupOrphanedMappings() {
        // Remove mappings for nodes that no longer exist in the scene
        guard let scene = Arena3DView.globalPersistentScene else { return }
        
        let validBugNodes = Set(bugNodeToBugMapping.keys.filter { node in
            node.parent != nil && scene.rootNode.childNode(withName: node.name ?? "", recursively: true) != nil
        })
        let validFoodNodes = Set(foodNodeToFoodMapping.keys.filter { node in
            node.parent != nil && scene.rootNode.childNode(withName: node.name ?? "", recursively: true) != nil
        })
        
        // Clean up bug mappings
        let orphanedBugNodes = bugNodeToBugMapping.keys.filter { !validBugNodes.contains($0) }
        for node in orphanedBugNodes {
            bugNodeToBugMapping.removeValue(forKey: node)
        }
        
        // Clean up food mappings  
        let orphanedFoodNodes = foodNodeToFoodMapping.keys.filter { !validFoodNodes.contains($0) }
        for node in orphanedFoodNodes {
            foodNodeToFoodMapping.removeValue(forKey: node)
        }
        
        // Also clean up NavigationResponder mappings
        if let navResponder = NavigationResponderView.currentInstance {
            for node in orphanedBugNodes {
                navResponder.bugNodeToBugMapping.removeValue(forKey: node)
            }
            
            for node in orphanedFoodNodes {
                navResponder.foodNodeToFoodMapping.removeValue(forKey: node)
            }
        }
        
        if !orphanedBugNodes.isEmpty || !orphanedFoodNodes.isEmpty {
            // Debug logging disabled for gameplay focus
            
            // Track node destructions for cleanup
            for node in orphanedBugNodes {
                MemoryLeakTracker.shared.trackNodeDestruction(type: "BugNode (cleanup)", name: node.name ?? "unnamed")
                
                // 🔍 MEMORY LEAK DEBUG: Track physics body cleanup (THE FINAL FIX!)
                if node.physicsBody != nil {
                    MemoryLeakTracker.shared.trackPhysicsBodyDestruction(type: "BugDynamic")
                    node.physicsBody = nil // Explicitly clear physics body
                }
                
                removeBugNodeSafely(node)
            }
            for node in orphanedFoodNodes {
                MemoryLeakTracker.shared.trackNodeDestruction(type: "FoodNode (cleanup)", name: node.name ?? "unnamed")
            }
        }
    }
    
    // MARK: - 🌍 Dynamic Biome Detection
    
    /// Analyzes the voxel world to determine the primary biome for lighting
    private func detectPrimaryBiome() -> BiomeType {
        // Sample surface layer voxels to determine biome distribution
        var biomeCounts: [BiomeType: Int] = [:]
        let surfaceVoxels = simulationEngine.voxelWorld.getVoxelsInLayer(.surface)
        let sampleSize = min(100, surfaceVoxels.count) // Sample up to 100 voxels
        let sampleVoxels = Array(surfaceVoxels.prefix(sampleSize))
        
        for voxel in sampleVoxels {
            biomeCounts[voxel.biome, default: 0] += 1
        }
        
        // Find the most common biome
        let primaryBiome = biomeCounts.max(by: { $0.value < $1.value })?.key ?? .temperateForest
        
        // Log biome distribution for development insight


        
        return primaryBiome
    }
    
    // MARK: - Scene Setup
    
    private func setupScene(scene: SCNScene) {
        // Add atmospheric fog for depth
        scene.fogStartDistance = 200
        scene.fogEndDistance = 800
        scene.fogColor = NSColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        scene.fogDensityExponent = 1.5
        
        // Add physics world with enhanced settings for stability
        scene.physicsWorld.gravity = SCNVector3(0, -2.0, 0)  // Reduced gravity to prevent fast falling
        scene.physicsWorld.speed = 0.3 // Slower for better collision detection
        scene.physicsWorld.contactDelegate = nil // For now, no contact delegate
        
        // Force physics world to process all static bodies immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scene.physicsWorld.timeStep = 1.0 / 60.0  // Ensure consistent timestep
            // Physics world synchronized and ready
        }
        
        // Debug physics world setup
        // Physics world configured
        
        // 🗑️ SAFETY FLOOR DISABLED - not needed with terrain mesh collision system
        // createSafetyFloor(scene: scene)
    }
    
    private func createSafetyFloor(scene: SCNScene) {
        // Create a large invisible floor far below the terrain to catch falling objects
        let floorGeometry = SCNBox(width: 1000, height: 1, length: 1000, chamferRadius: 0)
        let floorNode = SCNNode(geometry: floorGeometry)
        
        // Position it well below the lowest terrain (terrain is around Z=-50)
        floorNode.position = SCNVector3(0, -100, 0)  // Far below terrain
        
        // Make it invisible but with physics
        floorNode.geometry?.firstMaterial?.diffuse.contents = NSColor.clear
        floorNode.geometry?.firstMaterial?.transparency = 0.0
        
        // Add physics body that catches everything
        let floorShape = SCNPhysicsShape(geometry: floorGeometry, options: nil)
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: floorShape)
        floorNode.physicsBody?.categoryBitMask = 4         // Safety floor category
        floorNode.physicsBody?.collisionBitMask = 2        // Collides with bugs
        floorNode.physicsBody?.contactTestBitMask = 2      // Detects bug contact
        floorNode.physicsBody?.restitution = 0.8          // Bouncy to launch back up
        
        scene.rootNode.addChildNode(floorNode)
        // Safety floor created at Y=-100
        
        // Position validation will be handled through better physics and positioning
    }
    
    private func setupLighting(scene: SCNScene) {
        // 🎨 ENHANCED BIOME-AWARE LIGHTING SYSTEM
        // Apply our style guide lighting principles with biome-specific presets
        
        // 🌍 DYNAMIC BIOME DETECTION: Analyze actual world biomes for adaptive lighting
        let primaryBiome = detectPrimaryBiome()
        
        // Apply biome lighting preset
        setupBiomeLighting(scene: scene, biome: primaryBiome)
    }
    
    private func setupBiomeLighting(scene: SCNScene, biome: BiomeType) {
        // 🌞 BIOME-ADAPTIVE SUN: Lighting that changes based on biome character
        let sunLight = SCNLight()
        sunLight.type = .directional
        
        // Apply biome-specific sun characteristics following our style guide
        let sunConfig = getBiomeSunConfiguration(biome: biome)
        sunLight.color = sunConfig.color
        sunLight.intensity = sunConfig.intensity
        sunLight.castsShadow = true
        sunLight.shadowRadius = 4.0
        sunLight.shadowMapSize = CGSize(width: 1024, height: 1024)
        sunLight.shadowMode = .deferred
        sunLight.shadowSampleCount = 8
        sunLight.shadowColor = NSColor.black.withAlphaComponent(0.6)
        
        let sunNode = SCNNode()
        sunNode.light = sunLight
        sunNode.position = SCNVector3(300, 500, 300)
        sunNode.look(at: SCNVector3(0, 0, 0))
        
        // 🔧 VISUAL FIX: Remove visible sun geometry (was creating white spheres in sky)
        // Sun light still works for illumination, but no visible sphere geometry
        sunNode.geometry = nil  // No visible geometry - removes white spheres
        scene.rootNode.addChildNode(sunNode)
        
        // 🌙 BIOME-ADAPTIVE AMBIENT: Sky lighting that matches biome mood
        let ambientConfig = getBiomeAmbientConfiguration(biome: biome)
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = ambientConfig.color
        ambientLight.intensity = ambientConfig.intensity
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // 💎 BIOME-ADAPTIVE FILL: Atmospheric lighting for depth
        let fillConfig = getBiomeFillConfiguration(biome: biome)
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = fillConfig.color
        fillLight.intensity = fillConfig.intensity
        
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(-200, 300, -200)
        fillNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fillNode)
        
        // Add biome-specific specialty lighting
        setupBiomeSpecialtyLighting(scene: scene, biome: biome)
        
        // 🌈 BIOME-ADAPTIVE HDR: Environment that matches the biome
        scene.lightingEnvironment.intensity = 2.0
        scene.lightingEnvironment.contents = createBiomeHDREnvironment(biome: biome)
    }
    
    // MARK: - 🌍 Biome Lighting Configuration System
    
    struct LightConfiguration {
        let color: NSColor
        let intensity: Double
        let emissionColor: NSColor?
    }
    
    private func getBiomeSunConfiguration(biome: BiomeType) -> LightConfiguration {
        switch biome {
        case .tundra:
            // "Crystalline Majesty" - Cool, brilliant arctic sun
            return LightConfiguration(
                color: NSColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0),
                intensity: 2800,
                emissionColor: NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
            )
        case .desert:
            // "Timeless Endurance" - Intense, warm desert sun
            return LightConfiguration(
                color: NSColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0),
                intensity: 3200,
                emissionColor: NSColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
            )
        case .tropicalRainforest:
            // "Emerald Cathedral" - Filtered through dense canopy
            return LightConfiguration(
                color: NSColor(red: 0.85, green: 0.95, blue: 0.75, alpha: 1.0),
                intensity: 2000,
                emissionColor: NSColor(red: 0.8, green: 0.9, blue: 0.6, alpha: 1.0)
            )
        default:
            // Default temperate forest lighting
            return LightConfiguration(
                color: NSColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0),
                intensity: 2500,
                emissionColor: NSColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)
            )
        }
    }
    
    private func getBiomeAmbientConfiguration(biome: BiomeType) -> LightConfiguration {
        switch biome {
        case .tundra:
            return LightConfiguration(color: NSColor(red: 0.3, green: 0.4, blue: 0.7, alpha: 1.0), intensity: 500, emissionColor: nil)
        case .desert:
            return LightConfiguration(color: NSColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 1.0), intensity: 300, emissionColor: nil)
        case .tropicalRainforest:
            return LightConfiguration(color: NSColor(red: 0.3, green: 0.6, blue: 0.4, alpha: 1.0), intensity: 320, emissionColor: nil)
        default:
            return LightConfiguration(color: NSColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 1.0), intensity: 400, emissionColor: nil)
        }
    }
    
    private func getBiomeFillConfiguration(biome: BiomeType) -> LightConfiguration {
        switch biome {
        case .tundra:
            return LightConfiguration(color: NSColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 1.0), intensity: 900, emissionColor: nil)
        case .desert:
            return LightConfiguration(color: NSColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0), intensity: 600, emissionColor: nil)
        case .tropicalRainforest:
            return LightConfiguration(color: NSColor(red: 0.5, green: 0.8, blue: 0.6, alpha: 1.0), intensity: 650, emissionColor: nil)
        default:
            return LightConfiguration(color: NSColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0), intensity: 800, emissionColor: nil)
        }
    }
    
    private func setupBiomeSpecialtyLighting(scene: SCNScene, biome: BiomeType) {
        switch biome {
        case .tundra:
            // ❄️ TUNDRA: "Crystalline Aurora Majesty"
            createAuroraEffect(scene: scene)
            createBreathFogEffect(scene: scene)
            createCrystallineFormations(scene: scene)
            
        case .borealForest:
            // 🌲 BOREAL FOREST: "Ancient Pine Cathedral"
            createMorningMistEffect(scene: scene)
            createDappled_PineCanopyLighting(scene: scene)
            createPineDustMotes(scene: scene)
            
        case .temperateForest:
            // 🌳 TEMPERATE FOREST: "Living Light Symphony" 
            createCanopyLightFiltering(scene: scene)
            createForestFloorIllumination(scene: scene)
            createSeasonalLeafEffects(scene: scene)
            
        case .temperateGrassland:
            // 🌾 GRASSLANDS: "Golden Wind Dance"
            createGoldenHourLighting(scene: scene)
            createWindSweptGrassEffects(scene: scene)
            createWildflowerGlow(scene: scene)
            
        case .desert:
            // 🏜️ DESERT: "Timeless Heat Dreams"
            createHeatShimmerEffect(scene: scene)
            createDesertMirageEffect(scene: scene)
            createSandDuneShadows(scene: scene)
            
        case .savanna:
            // 🦒 SAVANNA: "Endless Horizon Drama"
            createDramaticSunsetLighting(scene: scene)
            createAcaciaTreeSilhouettes(scene: scene)
            createSavannaDustEffects(scene: scene)
            
        case .tropicalRainforest:
            // 🌴 RAINFOREST: "Emerald Cathedral Life"
            createLayeredCanopyLighting(scene: scene)
            createWaterDrippingEffects(scene: scene)
            createDenseUndergrowthAtmosphere(scene: scene)
            
        case .wetlands:
            // 🐸 WETLANDS: "Mystical Water Mirror"
            createReflectiveWaterEffects(scene: scene)
            createFireflyLighting(scene: scene)
            createCattailSwayingEffects(scene: scene)
            
        case .alpine:
            // ⛰️ ALPINE: "Majestic Peak Glory"
            createSnowCapPeakEffects(scene: scene)
            createAlpineGlowLighting(scene: scene)
            createRockyTextureHighlights(scene: scene)
            
        case .coastal:
            // 🏖️ COASTAL: "Ocean's Breath"
            createWaveFoamEffects(scene: scene)
            createSeaMistAtmosphere(scene: scene)
            createSeashellGlimmerEffects(scene: scene)
        }
    }
    
    // MARK: - 🌟 Signature Biome Atmospheric Effects
    
    // ❄️ TUNDRA EFFECTS: "Crystalline Aurora Majesty"
    
    private func createAuroraEffect(scene: SCNScene) {
        // 🌌 AURORA BOREALIS: Dancing northern lights
        for i in 0..<5 {
            let auroraLight = SCNLight()
            auroraLight.type = .spot
            auroraLight.color = NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
            auroraLight.intensity = 800 + Double(i) * 200
            auroraLight.spotInnerAngle = 45
            auroraLight.spotOuterAngle = 90
            
            let auroraNode = SCNNode()
            auroraNode.light = auroraLight
            auroraNode.position = SCNVector3(-100 + Float(i) * 50, 200, -200)
            auroraNode.look(at: SCNVector3(0, 50, 0))
            
            // Add aurora geometry for visual effect
            let auroraGeometry = SCNPlane(width: 200, height: 100)
            auroraGeometry.firstMaterial?.diffuse.contents = NSColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 0.3)
            auroraGeometry.firstMaterial?.emission.contents = NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
            auroraGeometry.firstMaterial?.transparency = 0.7
            auroraGeometry.firstMaterial?.isDoubleSided = true
            auroraNode.geometry = auroraGeometry
            
            scene.rootNode.addChildNode(auroraNode)
            
            // Animate aurora dancing
            let animation = SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0.2, z: 0.1, duration: 3.0 + Double(i)),
                SCNAction.rotateBy(x: 0, y: -0.4, z: -0.2, duration: 4.0 + Double(i))
            ])
            auroraNode.runAction(SCNAction.repeatForever(animation))
        }
    }
    
    private func createBreathFogEffect(scene: SCNScene) {
        // 💨 BREATH FOG: Cold air visibility
        for _ in 0..<8 {
            let fogLight = SCNLight()
            fogLight.type = .omni
            fogLight.color = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
            fogLight.intensity = 300
            fogLight.attenuationStartDistance = 10
            fogLight.attenuationEndDistance = 30
            
            let fogNode = SCNNode()
            fogNode.light = fogLight
            fogNode.position = SCNVector3(
                Float.random(in: -50...50),
                Float.random(in: 10...25),
                Float.random(in: -50...50)
            )
            
            // Fog particle effect
            let fogGeometry = SCNSphere(radius: 3)
            fogGeometry.firstMaterial?.diffuse.contents = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.2)
            fogGeometry.firstMaterial?.transparency = 0.8
            fogNode.geometry = fogGeometry
            
            scene.rootNode.addChildNode(fogNode)
            
            // Animate fog drifting
            let driftAnimation = SCNAction.moveBy(x: CGFloat(Float.random(in: -5...5)), y: CGFloat(Float.random(in: -2...2)), z: CGFloat(Float.random(in: -5...5)), duration: 6.0)
            fogNode.runAction(SCNAction.repeatForever(SCNAction.sequence([driftAnimation, driftAnimation.reversed()])))
        }
    }
    
    private func createCrystallineFormations(scene: SCNScene) {
        // 💎 CRYSTALLINE ICE: Sparkling formations
        for _ in 0..<6 {
            let crystalLight = SCNLight()
            crystalLight.type = .omni
            crystalLight.color = NSColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0)
            crystalLight.intensity = 600
            crystalLight.attenuationStartDistance = 15
            crystalLight.attenuationEndDistance = 40
            
            let crystalNode = SCNNode()
            crystalNode.light = crystalLight
            crystalNode.position = SCNVector3(
                Float.random(in: -60...60),
                Float.random(in: 5...15),
                Float.random(in: -60...60)
            )
            
            // Crystal geometry
            let crystalGeometry = SCNBox(width: 4, height: 8, length: 4, chamferRadius: 0.5)
            crystalGeometry.firstMaterial?.diffuse.contents = NSColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 0.9)
            crystalGeometry.firstMaterial?.emission.contents = NSColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
            crystalGeometry.firstMaterial?.transparency = 0.3
            crystalGeometry.firstMaterial?.roughness.contents = 0.1
            crystalGeometry.firstMaterial?.metalness.contents = 0.9
            crystalNode.geometry = crystalGeometry
            
            scene.rootNode.addChildNode(crystalNode)
            
            // Animate crystal sparkling
            let sparkleAnimation = SCNAction.sequence([
                SCNAction.scale(to: 1.2, duration: 2.0),
                SCNAction.scale(to: 1.0, duration: 1.5)
            ])
            crystalNode.runAction(SCNAction.repeatForever(sparkleAnimation))
        }
    }
    
    // 🏜️ DESERT EFFECTS: "Timeless Heat Dreams"
    
    private func createHeatShimmerEffect(scene: SCNScene) {
        // 🌡️ HEAT SHIMMER: Distortion effect from desert heat
        for _ in 0..<12 {
            let shimmerLight = SCNLight()
            shimmerLight.type = .spot
            shimmerLight.color = NSColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)
            shimmerLight.intensity = 400
            shimmerLight.spotInnerAngle = 60
            shimmerLight.spotOuterAngle = 120
            
            let shimmerNode = SCNNode()
            shimmerNode.light = shimmerLight
            shimmerNode.position = SCNVector3(
                Float.random(in: -80...80),
                Float.random(in: 2...8),
                Float.random(in: -80...80)
            )
            shimmerNode.look(at: SCNVector3(0, 0, 0))
            
            // Heat distortion geometry
            let shimmerGeometry = SCNPlane(width: 20, height: 5)
            shimmerGeometry.firstMaterial?.diffuse.contents = NSColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.1)
            shimmerGeometry.firstMaterial?.transparency = 0.9
            shimmerGeometry.firstMaterial?.isDoubleSided = true
            shimmerNode.geometry = shimmerGeometry
            
            scene.rootNode.addChildNode(shimmerNode)
            
            // Animate heat waves
            let waveAnimation = SCNAction.sequence([
                SCNAction.scale(by: 1.3, duration: 1.0),
                SCNAction.scale(by: 0.7, duration: 0.8)
            ])
            shimmerNode.runAction(SCNAction.repeatForever(waveAnimation))
        }
    }
    
    private func createDesertMirageEffect(scene: SCNScene) {
        // 🏜️ MIRAGE: Ethereal desert illusions
        let mirageLight = SCNLight()
        mirageLight.type = .directional
        mirageLight.color = NSColor(red: 0.9, green: 0.8, blue: 1.0, alpha: 1.0)
        mirageLight.intensity = 800
        
        let mirageNode = SCNNode()
        mirageNode.light = mirageLight
        mirageNode.position = SCNVector3(100, 30, 100)
        mirageNode.look(at: SCNVector3(0, 10, 0))
        
        // Mirage geometry - distant oasis illusion
        let mirageGeometry = SCNPlane(width: 40, height: 20)
        mirageGeometry.firstMaterial?.diffuse.contents = NSColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 0.2)
        mirageGeometry.firstMaterial?.emission.contents = NSColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
        mirageGeometry.firstMaterial?.transparency = 0.8
        mirageNode.geometry = mirageGeometry
        
        scene.rootNode.addChildNode(mirageNode)
        
        // Animate mirage wavering
        let mirageAnimation = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.8, duration: 3.0),
            SCNAction.fadeOpacity(to: 0.2, duration: 2.0)
        ])
        mirageNode.runAction(SCNAction.repeatForever(mirageAnimation))
    }
    
    private func createSandDuneShadows(scene: SCNScene) {
        // 🏜️ DRAMATIC SHADOWS: Deep dune shadow contrast
        for i in 0..<4 {
            let shadowLight = SCNLight()
            shadowLight.type = .spot
            shadowLight.color = NSColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
            shadowLight.intensity = 1200
            shadowLight.spotInnerAngle = 30
            shadowLight.spotOuterAngle = 90
            shadowLight.castsShadow = true
            shadowLight.shadowRadius = 8.0
            
            let shadowNode = SCNNode()
            shadowNode.light = shadowLight
            shadowNode.position = SCNVector3(
                Float(i) * 40 - 60,
                50,
                Float(i) * 30 - 45
            )
            shadowNode.look(at: SCNVector3(Float(i) * 20, 0, Float(i) * 15))
            
            scene.rootNode.addChildNode(shadowNode)
        }
    }
    
    // 🐸 WETLANDS EFFECTS: "Mystical Water Mirror"
    
    private func createFireflyLighting(scene: SCNScene) {
        // ✨ FIREFLIES: Magical dancing lights
        for i in 0..<15 {
            let fireflyLight = SCNLight()
            fireflyLight.type = .omni
            fireflyLight.color = NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
            fireflyLight.intensity = 200
            fireflyLight.attenuationStartDistance = 5
            fireflyLight.attenuationEndDistance = 15
            
            let fireflyNode = SCNNode()
            fireflyNode.light = fireflyLight
            fireflyNode.position = SCNVector3(
                Float.random(in: -40...40),
                Float.random(in: 8...20),
                Float.random(in: -40...40)
            )
            
            // Firefly glow geometry
            let fireflyGeometry = SCNSphere(radius: 0.5)
            fireflyGeometry.firstMaterial?.diffuse.contents = NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.8)
            fireflyGeometry.firstMaterial?.emission.contents = NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
            fireflyNode.geometry = fireflyGeometry
            
            scene.rootNode.addChildNode(fireflyNode)
            
            // Animate firefly dancing with simple circular motion
            let radius = Float.random(in: 8...20)
            let height = Float.random(in: -3...5)
            let duration = 8.0 + Double(i) * 0.5
            
            let circleAnimation = SCNAction.sequence([
                SCNAction.moveBy(x: CGFloat(radius), y: CGFloat(height), z: 0, duration: duration / 4),
                SCNAction.moveBy(x: 0, y: CGFloat(-height), z: CGFloat(radius), duration: duration / 4),
                SCNAction.moveBy(x: CGFloat(-radius), y: CGFloat(height), z: 0, duration: duration / 4),
                SCNAction.moveBy(x: 0, y: CGFloat(-height), z: CGFloat(-radius), duration: duration / 4)
            ])
            fireflyNode.runAction(SCNAction.repeatForever(circleAnimation))
            
            // Firefly blinking
            let blinkAnimation = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 1.0, duration: 0.2),
                SCNAction.fadeOpacity(to: 0.3, duration: 0.8)
            ])
            fireflyNode.runAction(SCNAction.repeatForever(blinkAnimation))
        }
    }
    
    // 🌲 BOREAL FOREST EFFECTS: "Ancient Pine Cathedral"
    
    private func createMorningMistEffect(scene: SCNScene) {
        // 🌫️ MORNING MIST: Ethereal forest atmosphere
        for _ in 0..<10 {
            let mistLight = SCNLight()
            mistLight.type = .omni
            mistLight.color = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
            mistLight.intensity = 400
            mistLight.attenuationStartDistance = 20
            mistLight.attenuationEndDistance = 60
            
            let mistNode = SCNNode()
            mistNode.light = mistLight
            mistNode.position = SCNVector3(
                Float.random(in: -60...60),
                Float.random(in: 5...15),
                Float.random(in: -60...60)
            )
            
            // Mist particle geometry
            let mistGeometry = SCNSphere(radius: 8)
            mistGeometry.firstMaterial?.diffuse.contents = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.1)
            mistGeometry.firstMaterial?.transparency = 0.9
            mistNode.geometry = mistGeometry
            
            scene.rootNode.addChildNode(mistNode)
            
            // Animate mist drifting
            let driftAnimation = SCNAction.moveBy(x: CGFloat(Float.random(in: -10...10)), y: CGFloat(Float.random(in: -2...3)), z: CGFloat(Float.random(in: -10...10)), duration: 12.0)
            mistNode.runAction(SCNAction.repeatForever(SCNAction.sequence([driftAnimation, driftAnimation.reversed()])))
        }
    }
    
    // MARK: - 🌿 Stub Functions (to be implemented)
    
    private func createDappled_PineCanopyLighting(scene: SCNScene) {
        // TODO: Implement dappled pine canopy lighting
    }
    
    private func createPineDustMotes(scene: SCNScene) {
        // TODO: Implement floating pine dust motes
    }
    
    private func createCanopyLightFiltering(scene: SCNScene) {
        // TODO: Implement temperate forest canopy filtering
    }
    
    private func createForestFloorIllumination(scene: SCNScene) {
        // TODO: Implement forest floor lighting
    }
    
    private func createSeasonalLeafEffects(scene: SCNScene) {
        // TODO: Implement seasonal leaf variations
    }
    
    private func createGoldenHourLighting(scene: SCNScene) {
        // 🌾 GRASSLANDS: "Golden Wind Dance" - Warm golden hour atmosphere
        
        // Main golden hour sun effect
        let goldenSun = SCNLight()
        goldenSun.type = .directional
        goldenSun.color = NSColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        goldenSun.intensity = 1800
        goldenSun.castsShadow = true
        goldenSun.shadowRadius = 8.0
        
        let goldenSunNode = SCNNode()
        goldenSunNode.light = goldenSun
        goldenSunNode.position = SCNVector3(150, 80, 100) // Low angle like sunset
        goldenSunNode.look(at: SCNVector3(0, 5, 0))
        scene.rootNode.addChildNode(goldenSunNode)
        
        // Atmospheric golden glow particles
        for _ in 0..<20 {
            let goldenGlow = SCNLight()
            goldenGlow.type = .omni
            goldenGlow.color = NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
            goldenGlow.intensity = 150
            goldenGlow.attenuationStartDistance = 20
            goldenGlow.attenuationEndDistance = 60
            
            let glowNode = SCNNode()
            glowNode.light = goldenGlow
            glowNode.position = SCNVector3(
                Float.random(in: -80...80),
                Float.random(in: 10...30),
                Float.random(in: -80...80)
            )
            scene.rootNode.addChildNode(glowNode)
            
            // Add visible golden particles
            let particleGeometry = SCNSphere(radius: 1.5)
            particleGeometry.firstMaterial?.diffuse.contents = NSColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.3)
            particleGeometry.firstMaterial?.emission.contents = NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
            particleGeometry.firstMaterial?.transparency = 0.7
            glowNode.geometry = particleGeometry
            
            // Animate floating golden particles
            let floatAnimation = SCNAction.sequence([
                SCNAction.moveBy(x: CGFloat(Float.random(in: -8...8)), y: CGFloat(Float.random(in: -3...5)), z: CGFloat(Float.random(in: -8...8)), duration: 6.0),
                SCNAction.moveBy(x: CGFloat(Float.random(in: -8...8)), y: CGFloat(Float.random(in: -3...5)), z: CGFloat(Float.random(in: -8...8)), duration: 5.5)
            ])
            glowNode.runAction(SCNAction.repeatForever(floatAnimation))
        }
        
        // Warm ambient enhancement for golden hour
        let warmAmbient = SCNLight()
        warmAmbient.type = .ambient
        warmAmbient.color = NSColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)
        warmAmbient.intensity = 300
        
        let ambientNode = SCNNode()
        ambientNode.light = warmAmbient
        scene.rootNode.addChildNode(ambientNode)
    }
    
    private func createWindSweptGrassEffects(scene: SCNScene) {
        // TODO: Implement wind-swept grass animations
    }
    
    private func createWildflowerGlow(scene: SCNScene) {
        // TODO: Implement wildflower glow effects
    }
    
    private func createDramaticSunsetLighting(scene: SCNScene) {
        // TODO: Implement savanna sunset lighting
    }
    
    private func createAcaciaTreeSilhouettes(scene: SCNScene) {
        // TODO: Implement acacia tree silhouettes
    }
    
    private func createSavannaDustEffects(scene: SCNScene) {
        // TODO: Implement savanna dust particle effects
    }
    
    private func createLayeredCanopyLighting(scene: SCNScene) {
        // 🌴 RAINFOREST: "Emerald Cathedral" - Multi-layer canopy lighting
        
        // Upper canopy - bright green filtering
        for _ in 0..<8 {
            let upperLight = SCNLight()
            upperLight.type = .spot
            upperLight.color = NSColor(red: 0.6, green: 0.9, blue: 0.4, alpha: 1.0)
            upperLight.intensity = 600
            upperLight.spotInnerAngle = 30
            upperLight.spotOuterAngle = 60
            
            let upperNode = SCNNode()
            upperNode.light = upperLight
            upperNode.position = SCNVector3(
                Float.random(in: -80...80),
                Float.random(in: 40...60),
                Float.random(in: -80...80)
            )
            upperNode.look(at: SCNVector3(0, 20, 0))
            scene.rootNode.addChildNode(upperNode)
        }
        
        // Mid canopy - dappled light filtering
        for _ in 0..<12 {
            let midLight = SCNLight()
            midLight.type = .omni
            midLight.color = NSColor(red: 0.4, green: 0.8, blue: 0.3, alpha: 1.0)
            midLight.intensity = 300
            midLight.attenuationStartDistance = 15
            midLight.attenuationEndDistance = 35
            
            let midNode = SCNNode()
            midNode.light = midLight
            midNode.position = SCNVector3(
                Float.random(in: -60...60),
                Float.random(in: 20...35),
                Float.random(in: -60...60)
            )
            scene.rootNode.addChildNode(midNode)
            
            // Animate dappled light movement
            let swayAnimation = SCNAction.sequence([
                SCNAction.moveBy(x: CGFloat(Float.random(in: -3...3)), y: CGFloat(Float.random(in: -1...1)), z: CGFloat(Float.random(in: -3...3)), duration: 4.0),
                SCNAction.moveBy(x: CGFloat(Float.random(in: -3...3)), y: CGFloat(Float.random(in: -1...1)), z: CGFloat(Float.random(in: -3...3)), duration: 3.5)
            ])
            midNode.runAction(SCNAction.repeatForever(swayAnimation))
        }
        
        // Ground level - filtered green glow
        for _ in 0..<6 {
            let groundLight = SCNLight()
            groundLight.type = .directional
            groundLight.color = NSColor(red: 0.2, green: 0.6, blue: 0.1, alpha: 1.0)
            groundLight.intensity = 200
            
            let groundNode = SCNNode()
            groundNode.light = groundLight
            groundNode.position = SCNVector3(
                Float.random(in: -40...40),
                Float.random(in: 10...20),
                Float.random(in: -40...40)
            )
            groundNode.look(at: SCNVector3(0, 0, 0))
            scene.rootNode.addChildNode(groundNode)
        }
    }
    
    private func createWaterDrippingEffects(scene: SCNScene) {
        // TODO: Implement water dripping effects
    }
    
    private func createDenseUndergrowthAtmosphere(scene: SCNScene) {
        // TODO: Implement dense undergrowth atmosphere
    }
    
    private func createReflectiveWaterEffects(scene: SCNScene) {
        // 🐸 WETLANDS: "Mirror of Life" - Reflective water surfaces with ethereal beauty
        
        // Main water reflection lighting
        for _ in 0..<6 {
            let reflectionLight = SCNLight()
            reflectionLight.type = .directional
            reflectionLight.color = NSColor(red: 0.6, green: 0.8, blue: 0.9, alpha: 1.0)
            reflectionLight.intensity = 400
            
            let reflectionNode = SCNNode()
            reflectionNode.light = reflectionLight
            reflectionNode.position = SCNVector3(
                Float.random(in: -40...40),
                Float.random(in: -5...5), // Near water level
                Float.random(in: -40...40)
            )
            reflectionNode.look(at: SCNVector3(0, 10, 0)) // Look upward for reflection effect
            scene.rootNode.addChildNode(reflectionNode)
            
            // Animate gentle water movement
            let rippleAnimation = SCNAction.sequence([
                SCNAction.rotateBy(x: 0.1, y: 0, z: 0.05, duration: 2.5),
                SCNAction.rotateBy(x: -0.2, y: 0, z: -0.1, duration: 3.0),
                SCNAction.rotateBy(x: 0.1, y: 0, z: 0.05, duration: 2.0)
            ])
            reflectionNode.runAction(SCNAction.repeatForever(rippleAnimation))
        }
        
        // Underwater caustic lighting effects
        for _ in 0..<8 {
            let causticLight = SCNLight()
            causticLight.type = .spot
            causticLight.color = NSColor(red: 0.4, green: 0.7, blue: 0.8, alpha: 1.0)
            causticLight.intensity = 300
            causticLight.spotInnerAngle = 20
            causticLight.spotOuterAngle = 45
            
            let causticNode = SCNNode()
            causticNode.light = causticLight
            causticNode.position = SCNVector3(
                Float.random(in: -60...60),
                Float.random(in: 8...15), // Above water level
                Float.random(in: -60...60)
            )
            causticNode.look(at: SCNVector3(0, 0, 0)) // Down toward water
            scene.rootNode.addChildNode(causticNode)
            
            // Animate caustic patterns
            let causticAnimation = SCNAction.sequence([
                SCNAction.scale(to: 1.4, duration: 1.8),
                SCNAction.scale(to: 0.8, duration: 2.2),
                SCNAction.scale(to: 1.0, duration: 1.5)
            ])
            causticNode.runAction(SCNAction.repeatForever(causticAnimation))
        }
        
        // Surface glimmer points
        for _ in 0..<15 {
            let glimmerLight = SCNLight()
            glimmerLight.type = .omni
            glimmerLight.color = NSColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0)
            glimmerLight.intensity = 200
            glimmerLight.attenuationStartDistance = 5
            glimmerLight.attenuationEndDistance = 15
            
            let glimmerNode = SCNNode()
            glimmerNode.light = glimmerLight
            glimmerNode.position = SCNVector3(
                Float.random(in: -50...50),
                Float.random(in: 2...8),
                Float.random(in: -50...50)
            )
            scene.rootNode.addChildNode(glimmerNode)
            
            // Animate twinkling glimmers
            let twinkleAnimation = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 1.0, duration: 0.8),
                SCNAction.fadeOpacity(to: 0.2, duration: 1.2),
                SCNAction.wait(duration: Double.random(in: 0.5...2.0))
            ])
            glimmerNode.runAction(SCNAction.repeatForever(twinkleAnimation))
        }
    }
    
    private func createCattailSwayingEffects(scene: SCNScene) {
        // TODO: Implement cattail swaying animations
    }
    
    private func createSnowCapPeakEffects(scene: SCNScene) {
        // TODO: Implement snow-capped peak effects
    }
    
    private func createAlpineGlowLighting(scene: SCNScene) {
        // TODO: Implement alpine glow lighting
    }
    
    private func createRockyTextureHighlights(scene: SCNScene) {
        // TODO: Implement rocky texture highlights
    }
    
    private func createWaveFoamEffects(scene: SCNScene) {
        // TODO: Implement wave foam effects
    }
    
    private func createSeaMistAtmosphere(scene: SCNScene) {
        // TODO: Implement sea mist atmosphere
    }
    
    private func createSeashellGlimmerEffects(scene: SCNScene) {
        // TODO: Implement seashell glimmer effects
    }
    
    private func createBiomeHDREnvironment(biome: BiomeType) -> NSImage {
        let size = 128
        let image = NSImage(size: NSSize(width: size, height: size))
        
        image.lockFocus()
        
        // Create biome-specific sky gradients
        let colors = getBiomeEnvironmentColors(biome: biome)
        let gradient = NSGradient(colors: colors)
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: 90)
        
        image.unlockFocus()
        return image
    }
    
    private func getBiomeEnvironmentColors(biome: BiomeType) -> [NSColor] {
        switch biome {
        case .tundra:
            return [
                NSColor(red: 0.05, green: 0.15, blue: 0.4, alpha: 1.0),  // Deep arctic blue
                NSColor(red: 0.3, green: 0.4, blue: 0.7, alpha: 1.0),   // Arctic sky
                NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),   // Ice horizon
                NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0),  // Snow
            ]
        case .desert:
            return [
                NSColor(red: 0.2, green: 0.15, blue: 0.4, alpha: 1.0),  // Desert night sky
                NSColor(red: 0.6, green: 0.4, blue: 0.3, alpha: 1.0),   // Desert sky
                NSColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0),   // Desert horizon
                NSColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0),   // Sand dunes
            ]
        case .tropicalRainforest:
            return [
                NSColor(red: 0.05, green: 0.2, blue: 0.1, alpha: 1.0),  // Deep forest canopy
                NSColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0),   // Forest sky glimpse
                NSColor(red: 0.6, green: 0.8, blue: 0.4, alpha: 1.0),   // Canopy light
                NSColor(red: 0.4, green: 0.7, blue: 0.3, alpha: 1.0),   // Mid forest
            ]
        default:
            // Default temperate colors
            return [
                NSColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0),
                NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0),
                NSColor(red: 0.9, green: 0.8, blue: 0.7, alpha: 1.0),
                NSColor(red: 0.5, green: 0.7, blue: 0.3, alpha: 1.0),
            ]
        }
    }
    
    private func createAdvancedHDREnvironment() -> NSImage {
        let size = 128  // Optimized resolution for good performance
        let image = NSImage(size: NSSize(width: size, height: size))
        
        image.lockFocus()
        
        // Create realistic sky gradient with atmospheric perspective
        let colors = [
            NSColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0),  // Deep sky
            NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0),  // Mid sky
            NSColor(red: 0.9, green: 0.8, blue: 0.7, alpha: 1.0),  // Horizon
            NSColor(red: 0.5, green: 0.7, blue: 0.3, alpha: 1.0),  // Vegetation
            NSColor(red: 0.2, green: 0.3, blue: 0.1, alpha: 1.0)   // Ground
        ]
        
        let gradient = NSGradient(colors: colors)
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: 90)
        
        // Add subtle cloud patterns for more realistic reflections
        for _ in 0..<20 {
            let cloudX = Double.random(in: 0...Double(size))
            let cloudY = Double.random(in: Double(size) * 0.6...Double(size) * 0.9)
            let cloudSize = Double.random(in: 20...60)
            
            let cloudColor = NSColor.white.withAlphaComponent(0.3)
            cloudColor.setFill()
            
            let cloudRect = NSRect(x: cloudX, y: cloudY, width: cloudSize, height: cloudSize * 0.5)
            let cloudPath = NSBezierPath(ovalIn: cloudRect)
            cloudPath.fill()
        }
        
        image.unlockFocus()
        return image
    }
    
    private func setupEnvironmentalContext(scene: SCNScene) {
        // Creating immersive environmental context
        
        // 1️⃣ SKYBOX: Replace black void with realistic environment
        createSkybox(scene: scene)
        
        // 2️⃣ GROUND PLANE: Removed to eliminate white texture below terrain
        // createGroundPlane(scene: scene)
        
        // 3️⃣ OPTIMIZED ATMOSPHERIC CLOUDS: Beautiful DALL-E clouds
        // 🔧 PERFORMANCE FIX: Disabled atmospheric clouds (were creating white spheres in sky)
        // createOptimizedAtmosphericClouds(scene: scene)
        
        // 🗑️ LEGACY DEBUG SYSTEMS DISABLED - these created floating objects in sky
        // createHorizonMarkers(scene: scene)      // Was creating colored floating boxes
        // createCoordinateGrid(scene: scene)      // Was creating white grid lines
        
        // Environmental context active
    }
    
    private func createSkybox(scene: SCNScene) {
        // 🌍 DYNAMIC SKYBOX: Load world-specific DALL-E skybox
        let worldType = simulationEngine.voxelWorld.worldType
        let skyboxAssetName = getSkyboxAssetName(for: worldType)
        

        
        // Try to load world-specific skybox first
        if let skyboxImage = NSImage(named: skyboxAssetName) {
            scene.background.contents = skyboxImage
            scene.lightingEnvironment.contents = skyboxImage
            scene.lightingEnvironment.intensity = getSkyboxIntensity(for: worldType)

        } else if let fallbackImage = NSImage(named: "epic-skybox-panorama") {
            // Fallback to original skybox if world-specific not found
            scene.background.contents = fallbackImage
            scene.lightingEnvironment.contents = fallbackImage
            scene.lightingEnvironment.intensity = 2.5
        } else {
            // Final fallback to procedural skybox
            let skybox = MDLSkyCubeTexture(name: nil,
                                          channelEncoding: .uInt8,
                                          textureDimensions: vector_int2(Int32(256), Int32(256)),
                                          turbidity: 0.28,
                                          sunElevation: 0.6,
                                          upperAtmosphereScattering: 0.4,
                                          groundAlbedo: 0.3)
            
            scene.background.contents = skybox.imageFromTexture()?.takeUnretainedValue()
            scene.lightingEnvironment.contents = skybox.imageFromTexture()?.takeUnretainedValue()
            scene.lightingEnvironment.intensity = 1.0
        }
    }
    
    /// Maps world types to their corresponding skybox asset names
    private func getSkyboxAssetName(for worldType: WorldType3D) -> String {
        switch worldType {
        case .continental3D:
            return "continental-skybox"
        case .archipelago3D:
            return "archipelago-skybox"
        case .canyon3D:
            return "canyon-skybox"
        case .cavern3D:
            return "cavern-skybox"
        case .skylands3D:
            return "skylands-skybox"
        case .abyss3D:
            return "abyss-skybox"
        case .volcano3D:
            return "volcano-skybox"
        }
    }
    
    /// Returns optimal lighting intensity for each world type's atmosphere
    private func getSkyboxIntensity(for worldType: WorldType3D) -> CGFloat {
        switch worldType {
        case .continental3D:
            return 2.5  // Bright, open plains
        case .archipelago3D:
            return 3.0  // Brilliant tropical sunlight
        case .canyon3D:
            return 2.0  // Harsh desert light
        case .cavern3D:
            return 1.2  // Dim underground lighting
        case .skylands3D:
            return 2.8  // Ethereal sky lighting
        case .abyss3D:
            return 1.5  // Filtered underwater light
        case .volcano3D:
            return 2.2  // Dramatic volcanic glow
        }
    }
    
    private func createGroundPlane(scene: SCNScene) {
        // Loading ground texture
        
        // MASSIVE GROUND PLANE for epic infinite horizon
        let groundGeometry = SCNPlane(width: 4000, height: 4000)
        
        // GORGEOUS GROUND MATERIAL with DALL-E texture
        let groundMaterial = SCNMaterial()
        
        // INSTANT LOADING: Use gorgeous pre-generated DALL-E ground texture
        if let groundTexture = NSImage(named: "fantasy-ground-diffuse") {
            groundMaterial.diffuse.contents = groundTexture
            groundMaterial.lightingModel = .physicallyBased  // PBR for realism
            // Ground texture loaded
        } else {
            // Ground texture not found, using fallback
            groundMaterial.diffuse.contents = NSColor(red: 0.15, green: 0.25, blue: 0.1, alpha: 1.0)
        }
        
        // Enhanced PBR properties
        groundMaterial.roughness.contents = NSColor(white: 0.8, alpha: 1.0)
        groundMaterial.metalness.contents = NSColor(white: 0.0, alpha: 1.0)
        
        groundGeometry.firstMaterial = groundMaterial
        
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.position = SCNVector3(0, -120, 0)  // Lower for more drama
        groundNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)  // Horizontal
        
        scene.rootNode.addChildNode(groundNode)
    }
    
    private func createOptimizedAtmosphericClouds(scene: SCNScene) {
        // Adding atmospheric clouds
        
        // LIGHTWEIGHT CLOUDS: Just a few for atmosphere, not performance-heavy
        guard let cloudTexture = NSImage(named: "volumetric-cloud-texture") else {
            // Cloud texture not found
            return
        }
        
        // Only 4 clouds for great performance
        for i in 0..<4 {
            let cloudGeometry = SCNSphere(radius: CGFloat(150 + i * 30))
            
            let cloudMaterial = SCNMaterial()
            cloudMaterial.diffuse.contents = cloudTexture
            cloudMaterial.transparency = 0.3
            cloudMaterial.isDoubleSided = true
            cloudMaterial.writesToDepthBuffer = false
            
            cloudGeometry.firstMaterial = cloudMaterial
            
            let cloudNode = SCNNode(geometry: cloudGeometry)
            
            // Position around the horizon
            let angle = Float(i) * (Float.pi * 2 / 4)
            cloudNode.position = SCNVector3(
                cos(angle) * 800,
                300 + Float(i * 50),
                sin(angle) * 800
            )
            
            // Gentle animation
            let floatAction = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 15, z: 0, duration: 25.0),
                SCNAction.moveBy(x: 0, y: -15, z: 0, duration: 25.0)
            ])
            cloudNode.runAction(SCNAction.repeatForever(floatAction))
            
            scene.rootNode.addChildNode(cloudNode)
        }
        
        // Atmospheric clouds added
    }
    
    private func createHorizonMarkers(scene: SCNScene) {
        // Distant landmarks for navigation reference
        let markerPositions = [
            SCNVector3(400, 50, 0),      // East
            SCNVector3(-400, 50, 0),     // West  
            SCNVector3(0, 50, 400),      // North
            SCNVector3(0, 50, -400),     // South
        ]
        
        let markerColors = [
            NSColor.red,    // East - Red
            NSColor.blue,   // West - Blue
            NSColor.green,  // North - Green  
            NSColor.orange  // South - Orange
        ]
        
        for (index, position) in markerPositions.enumerated() {
            let markerGeometry = SCNBox(width: 10, height: 50, length: 10, chamferRadius: 2)
            let markerMaterial = SCNMaterial()
            markerMaterial.diffuse.contents = markerColors[index]
            markerMaterial.emission.contents = markerColors[index].withAlphaComponent(0.3)
            markerGeometry.firstMaterial = markerMaterial
            
            let markerNode = SCNNode(geometry: markerGeometry)
            markerNode.position = position
            
            scene.rootNode.addChildNode(markerNode)
        }
    }
    
    private func createCoordinateGrid(scene: SCNScene) {
        // Optional grid lines for spatial reference (subtle)
        let gridSpacing: Float = 50
        let gridSize: Float = 500
        let gridAlpha: CGFloat = 0.1
        
        // Create X-axis lines
        let lineCount = Int(gridSize / gridSpacing)
        for i in -lineCount...lineCount {
            let lineGeometry = SCNBox(width: CGFloat(gridSize * 2), height: 0.5, length: 0.5, chamferRadius: 0)
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = NSColor.white.withAlphaComponent(gridAlpha)
            lineGeometry.firstMaterial = lineMaterial
            
            let lineNode = SCNNode(geometry: lineGeometry)
            lineNode.position = SCNVector3(0, -95, Float(i) * gridSpacing)
            
            scene.rootNode.addChildNode(lineNode)
        }
        
        // Create Z-axis lines
        for i in -lineCount...lineCount {
            let lineGeometry = SCNBox(width: 0.5, height: 0.5, length: CGFloat(gridSize * 2), chamferRadius: 0)
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = NSColor.white.withAlphaComponent(gridAlpha)
            lineGeometry.firstMaterial = lineMaterial
            
            let lineNode = SCNNode(geometry: lineGeometry)
            lineNode.position = SCNVector3(Float(i) * gridSpacing, -95, 0)
            
            scene.rootNode.addChildNode(lineNode)
        }
    }
    
    private func setupCamera(scene: SCNScene) {
        // Setting up enhanced navigation camera
        
        let camera = SCNCamera()
        camera.fieldOfView = 75
        camera.zNear = 1.0
        camera.zFar = 3000.0  // Increased for better distant viewing
        
        // Enhanced camera settings for better navigation
        camera.wantsHDR = true
        camera.bloomThreshold = 0.8
        camera.bloomIntensity = 0.3
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // 🌍 DYNAMIC CAMERA POSITIONING: Showcase each world type's unique features!
        let worldType = simulationEngine.voxelWorld.worldType
        let (cameraPos, lookAtPos) = calculateOptimalCameraPosition(for: worldType)
        
        cameraNode.position = cameraPos
        cameraNode.look(at: lookAtPos)
        

        
        scene.rootNode.addChildNode(cameraNode)
        // Store camera node reference directly
        self.cameraNode = cameraNode
        
        // Camera node created and assigned
        // Camera position dynamically set based on world type
    }
    
    /// Calculate optimal camera position to showcase each world type's unique features
    private func calculateOptimalCameraPosition(for worldType: WorldType3D) -> (SCNVector3, SCNVector3) {
        let bounds = simulationEngine.voxelWorld.worldBounds
        let centerX = Float(bounds.midX)
        let centerY = Float(bounds.midY)
        
        switch worldType {
        case .continental3D:
            // 🎉 ELEVATED OVERVIEW: High angle position for observing terrain and food distribution
            let cameraPos = SCNVector3(centerX + 60, 80, centerY + 80)  // Much higher elevated view
            let lookAt = SCNVector3(centerX, 0, centerY)                 // Look at terrain surface
            return (cameraPos, lookAt)
            
        case .archipelago3D:
            // High angle to show island chains and water
            let cameraPos = SCNVector3(centerX + 50, 40, centerY + 60)
            let lookAt = SCNVector3(centerX, -10, centerY)
            return (cameraPos, lookAt)
            
        case .canyon3D:
            // Side view to showcase dramatic elevation changes
            let cameraPos = SCNVector3(centerX + 80, 30, centerY)
            let lookAt = SCNVector3(centerX, 0, centerY)
            return (cameraPos, lookAt)
            
        case .cavern3D:
            // Lower angle to show cave entrances and underground features
            let cameraPos = SCNVector3(centerX + 25, -5, centerY + 35)
            let lookAt = SCNVector3(centerX, -20, centerY)
            return (cameraPos, lookAt)
            
        case .skylands3D:
            // High altitude to show floating islands
            let cameraPos = SCNVector3(centerX + 40, 60, centerY + 50)
            let lookAt = SCNVector3(centerX, 20, centerY)
            return (cameraPos, lookAt)
            
        case .abyss3D:
            // Elevated view to show abyss depths without going too deep underground
            let cameraPos = SCNVector3(centerX + 40, 25, centerY + 50)
            let lookAt = SCNVector3(centerX, -10, centerY)
            return (cameraPos, lookAt)
            
        case .volcano3D:
            // Angled view to show volcanic peaks and dangerous terrain
            let cameraPos = SCNVector3(centerX + 60, 35, centerY + 30)
            let lookAt = SCNVector3(centerX, 5, centerY)
            return (cameraPos, lookAt)
        }
    }
    
    private func addCameraConstraints(cameraNode: SCNNode, scene: SCNScene) {
        // Add terrain center reference node first
        let centerNode = SCNNode()
        centerNode.name = "terrainCenter"
        centerNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(centerNode)
        
        // Distance constraint to prevent getting too close/far
        let distanceConstraint = SCNDistanceConstraint(target: centerNode)
        distanceConstraint.minimumDistance = 50
        distanceConstraint.maximumDistance = 800
        
        cameraNode.constraints = [distanceConstraint]
    }
    
    private func addNavigationAids(scene: SCNScene) {
        // Adding navigation aids
        
        // 🎯 TERRAIN CENTER MARKER: Clear reference point
        // 🔧 VISUAL FIX: Disabled terrain center marker (white glowing sphere)
        // addTerrainCenterMarker(scene: scene)
        
        // 🗑️ NAVIGATION AIDS DISABLED - these were creating floating objects in sky
        // addScaleReference(scene: scene)          // Was creating yellow floating scale bars
        // addLayerIndicators(scene: scene)         // Was creating cyan/green floating layer indicators
        
        // Navigation aids active
    }
    
    private func addTerrainCenterMarker(scene: SCNScene) {
        // Glowing center marker to show terrain origin
        let markerGeometry = SCNSphere(radius: 3)
        let markerMaterial = SCNMaterial()
        markerMaterial.diffuse.contents = NSColor.white
        markerMaterial.emission.contents = NSColor.white.withAlphaComponent(0.8)
        markerGeometry.firstMaterial = markerMaterial
        
        let markerNode = SCNNode(geometry: markerGeometry)
        markerNode.position = SCNVector3(0, 0, 0)
        
        // Add pulsing animation
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.5, duration: 1.0),
            SCNAction.scale(to: 1.0, duration: 1.0)
        ])
        markerNode.runAction(SCNAction.repeatForever(pulseAction))
        
        scene.rootNode.addChildNode(markerNode)
    }
    
    private func addScaleReference(scene: SCNScene) {
        // Scale bars to help understand distances
        let scalePositions = [
            SCNVector3(100, 10, 0),   // 100-unit reference East
            SCNVector3(0, 10, 100),   // 100-unit reference North
        ]
        
        for (index, position) in scalePositions.enumerated() {
            let scaleGeometry = SCNBox(width: index == 0 ? 100 : 5, 
                                     height: 2, 
                                     length: index == 0 ? 5 : 100, 
                                     chamferRadius: 1)
            let scaleMaterial = SCNMaterial()
            scaleMaterial.diffuse.contents = NSColor.yellow.withAlphaComponent(0.6)
            scaleMaterial.emission.contents = NSColor.yellow.withAlphaComponent(0.2)
            scaleGeometry.firstMaterial = scaleMaterial
            
            let scaleNode = SCNNode(geometry: scaleGeometry)
            scaleNode.position = position
            
            scene.rootNode.addChildNode(scaleNode)
        }
    }
    
    private func addLayerIndicators(scene: SCNScene) {
        // Visual indicators for the 4 terrain layers
        let layerInfo = [
            (name: "Aerial", y: Float(60), color: NSColor.cyan),
            (name: "Canopy", y: Float(30), color: NSColor.green),
            (name: "Surface", y: Float(0), color: NSColor.brown),
            (name: "Underground", y: Float(-30), color: NSColor.purple)
        ]
        
        for layer in layerInfo {
            // Create subtle layer indication plane
            let layerGeometry = SCNPlane(width: 200, height: 200)
            let layerMaterial = SCNMaterial()
            layerMaterial.diffuse.contents = layer.color.withAlphaComponent(0.05)
            layerMaterial.isDoubleSided = true
            layerGeometry.firstMaterial = layerMaterial
            
            let layerNode = SCNNode(geometry: layerGeometry)
            layerNode.position = SCNVector3(0, layer.y, 0)
            layerNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)  // Horizontal
            
            scene.rootNode.addChildNode(layerNode)
            
            // Add layer label marker at edge
            let labelGeometry = SCNBox(width: 5, height: 5, length: 15, chamferRadius: 1)
            let labelMaterial = SCNMaterial()
            labelMaterial.diffuse.contents = layer.color
            labelMaterial.emission.contents = layer.color.withAlphaComponent(0.5)
            labelGeometry.firstMaterial = labelMaterial
            
            let labelNode = SCNNode(geometry: labelGeometry)
            labelNode.position = SCNVector3(90, layer.y + 2, 0)
            
            scene.rootNode.addChildNode(labelNode)
        }
    }
    
    // MARK: - Epic Terrain Rendering
    
    private func renderTerrain(scene: SCNScene) {
        // 🌍 RENDERING CONTINENTAL TERRAIN MESH
        
        // 🎨 Clear previous terrain
        scene.rootNode.childNode(withName: "VoxelTerrainContainer", recursively: false)?.removeFromParentNode()
        scene.rootNode.childNode(withName: "ContinentalTerrainContainer", recursively: false)?.removeFromParentNode()
        
        // Create terrain container
        let terrainContainer = SCNNode()
        terrainContainer.name = "ContinentalTerrainContainer"
        scene.rootNode.addChildNode(terrainContainer)
        
        // 🏔️ GENERATE CONTINENTAL TERRAIN MESH: Shows mountain ranges, rivers, lakes
        renderContinentalTerrainMesh(container: terrainContainer)
        
        // 🗑️ LEGACY VOXEL RENDERING DISABLED - terrain mesh replaced individual voxel objects
        // renderSelectiveVoxelFeatures(container: terrainContainer)
        
        // 🎨 INSTANT VAN GOGH MATERIALS: All terrain types get immediate artistic treatment!
        // No async processing needed - all materials applied instantly during voxel creation
        
        // 🗑️ ATMOSPHERIC & WATER EFFECTS DISABLED - these were creating floating objects in sky
        // self.startSpectacularWaterAnimation(scene: scene)    // Was creating floating water effects
        // addAtmosphericEffects(scene: scene)                  // Was creating floating atmospheric objects
        // addBiomeSpecificAtmosphericEffects(scene: scene)     // Was creating floating biome objects  
        // addWeatherSpecificEffects(scene: scene)              // Was creating floating weather objects
    }
    
    private func renderVoxelTerrain(container: SCNNode) {
        // Rendering voxel world
        
        // Create layer containers for organization
        var layerContainers: [TerrainLayer: SCNNode] = [:]
        for layer in TerrainLayer.allCases {
            let layerContainer = SCNNode()
            layerContainer.name = "VoxelLayer_\(layer.rawValue)"
            container.addChildNode(layerContainer)
            layerContainers[layer] = layerContainer
        }
        
        // 🚀 PERFORMANCE FIX: Spatial sampling to reduce render count
        // Only render every 2nd voxel in each dimension to prevent memory explosion
        let samplingRate = 2  // Renders 1/8th of voxels (2³ = 8x reduction)
        
        var renderedCount = 0
        for x in stride(from: 0, to: simulationEngine.voxelWorld.dimensions.width, by: samplingRate) {
            for y in stride(from: 0, to: simulationEngine.voxelWorld.dimensions.height, by: samplingRate) {
                for z in stride(from: 0, to: simulationEngine.voxelWorld.dimensions.depth, by: samplingRate) {
                    let voxel = simulationEngine.voxelWorld.voxels[x][y][z]
                    
                    // Only render solid/interesting voxels
                    if shouldRenderVoxel(voxel) {
                        let voxelNode = createVoxelNode(voxel: voxel)
                        layerContainers[voxel.layer]?.addChildNode(voxelNode)
                        renderedCount += 1
                    }
                }
            }
        }
        
    }
    
    // MARK: - Continental Terrain Mesh Generation
    
    private func renderContinentalTerrainMesh(container: SCNNode) {

        
        let voxelWorld = simulationEngine.voxelWorld
        let heightMap = voxelWorld.heightMap
        let bounds = voxelWorld.worldBounds
        
        // Create terrain mesh geometry
        let terrainMesh = createTerrainMeshFromHeightMap(
            heightMap: heightMap,
            bounds: bounds,
            resolution: voxelWorld.dimensions.width
        )
        
        // Create terrain node
        let terrainNode = SCNNode(geometry: terrainMesh)
        terrainNode.name = "ContinentalTerrainMesh"
        
        // 🔧 COORDINATE FIX: Position terrain at origin - vertices already in world coordinates
        terrainNode.position = SCNVector3(0, 0, 0)
        
        // 🔧 COLLISION FIX: Add physics collision to terrain mesh
        // This prevents bugs from walking through the terrain
        let terrainPhysicsShape = SCNPhysicsShape(geometry: terrainMesh, options: [
            .type: SCNPhysicsShape.ShapeType.concavePolyhedron,  // For complex terrain mesh
            .collisionMargin: 0.1                                // Small margin for accuracy
        ])
        terrainNode.physicsBody = SCNPhysicsBody(type: .static, shape: terrainPhysicsShape)
        terrainNode.physicsBody?.categoryBitMask = 1      // Terrain category (matches voxel terrain)
        terrainNode.physicsBody?.collisionBitMask = 2     // Collides with bugs
        terrainNode.physicsBody?.contactTestBitMask = 2   // Detect contact with bugs
        terrainNode.physicsBody?.friction = 1.0          // High friction for walking
        terrainNode.physicsBody?.restitution = 0.0       // No bounce - bugs should stay grounded
        
        container.addChildNode(terrainNode)
        

    }
    
    private func createTerrainMeshFromHeightMap(heightMap: [[Double]], bounds: CGRect, resolution: Int) -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var texCoords: [CGPoint] = []
        var indices: [Int32] = []
        
        let width = resolution
        let height = resolution
        let stepX = Float(bounds.width) / Float(width - 1)
        let stepZ = Float(bounds.height) / Float(height - 1)
        
        // Generate vertices  
        for z in 0..<height {
            for x in 0..<width {
                let worldX = Float(bounds.minX) + Float(x) * stepX
                let worldZ = Float(bounds.minY) + Float(z) * stepZ
                
                // 🔧 COORDINATE FIX: Voxel world uses Z-up, SceneKit uses Y-up
                // Map voxel world Z (-50 to +50) to SceneKit Y axis
                let heightMapValue = heightMap[x][z]  // -25.0 to 34.3
                let worldY = Float(heightMapValue)    // Use height as Y (up) in SceneKit
                
                vertices.append(SCNVector3(worldX, worldY, worldZ))
                
                // Calculate normal (simplified - pointing up for now)
                normals.append(SCNVector3(0, 1, 0))
                
                // Texture coordinates
                texCoords.append(CGPoint(x: Double(x) / Double(width - 1), y: Double(z) / Double(height - 1)))
            }
        }
        
        // Generate triangle indices
        for z in 0..<(height - 1) {
            for x in 0..<(width - 1) {
                let topLeft = z * width + x
                let topRight = z * width + (x + 1)
                let bottomLeft = (z + 1) * width + x
                let bottomRight = (z + 1) * width + (x + 1)
                
                // First triangle
                indices.append(Int32(topLeft))
                indices.append(Int32(bottomLeft))
                indices.append(Int32(topRight))
                
                // Second triangle
                indices.append(Int32(topRight))
                indices.append(Int32(bottomLeft))
                indices.append(Int32(bottomRight))
            }
        }
        
        // Create geometry sources
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let texCoordSource = SCNGeometrySource(textureCoordinates: texCoords)
        
        // Create geometry element
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        // Create geometry with sources and elements
        let geometry = SCNGeometry(sources: [vertexSource, normalSource, texCoordSource], elements: [element])
        
        // 🔍 MEMORY LEAK DEBUG: Track massive terrain mesh creation
        MemoryLeakTracker.shared.trackGeometryCreation(type: "TerrainMesh", vertexCount: vertices.count)
        
        // Apply continental terrain material
        geometry.firstMaterial = createContinentalTerrainMaterial()
        
        return geometry
    }
    
    /// Get terrain height at world coordinates for proper positioning
    private func getTerrainHeightAt(x: Double, z: Double) -> Double {
        let heightMap = simulationEngine.voxelWorld.heightMap
        let bounds = simulationEngine.voxelWorld.worldBounds
        let resolution = simulationEngine.voxelWorld.dimensions.width
        
        // 🔧 ENHANCED COORDINATE MAPPING: More precise height lookup
        // Convert world coordinates to height map indices with better precision
        let normalizedX = (x - bounds.minX) / bounds.width
        let normalizedZ = (z - bounds.minY) / bounds.height
        
        // 🎯 BILINEAR INTERPOLATION: More accurate height between grid points
        let exactX = normalizedX * Double(resolution - 1)
        let exactZ = normalizedZ * Double(resolution - 1)
        
        let x0 = Int(floor(exactX))
        let z0 = Int(floor(exactZ))
        let x1 = min(x0 + 1, resolution - 1)
        let z1 = min(z0 + 1, resolution - 1)
        
        // Bounds check
        let clampedX0 = max(0, min(resolution - 1, x0))
        let clampedZ0 = max(0, min(resolution - 1, z0))
        let clampedX1 = max(0, min(resolution - 1, x1))
        let clampedZ1 = max(0, min(resolution - 1, z1))
        
        // Get height values at grid corners
        let h00 = heightMap[clampedX0][clampedZ0]  // Top-left
        let h10 = heightMap[clampedX1][clampedZ0]  // Top-right  
        let h01 = heightMap[clampedX0][clampedZ1]  // Bottom-left
        let h11 = heightMap[clampedX1][clampedZ1]  // Bottom-right
        
        // Interpolation factors
        let fx = exactX - Double(x0)
        let fz = exactZ - Double(z0)
        
        // Bilinear interpolation
        let h_top = h00 + fx * (h10 - h00)
        let h_bottom = h01 + fx * (h11 - h01)
        let interpolatedHeight = h_top + fz * (h_bottom - h_top)
        
        return interpolatedHeight
    }
    
    private func createContinentalTerrainMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🎮 MINECRAFT-STYLE TERRAIN MATERIAL
        let terrainTexture = createHeightBasedTerrainTexture()
        material.diffuse.contents = terrainTexture
        
        // 🔧 MATERIAL PROPERTIES for crisp, game-like appearance
        material.roughness.contents = NSColor(white: 0.9, alpha: 1.0)     // Slightly rough for natural look
        material.metalness.contents = NSColor(white: 0.0, alpha: 1.0)     // Non-metallic terrain
        material.lightingModel = .physicallyBased
        material.isDoubleSided = false
        
        // 🎯 TEXTURE FILTERING for crisp pixels (Minecraft-style)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.diffuse.minificationFilter = .nearest  // Crisp pixel edges
        material.diffuse.magnificationFilter = .nearest // No blurring
        material.diffuse.mipFilter = .nearest           // Sharp detail levels
        
        // 🌟 VISUAL ENHANCEMENTS
        material.normal.intensity = 0.3  // Subtle surface detail
        material.ambientOcclusion.intensity = 0.2  // Add depth
        

        return material
    }
    
    private func createHeightBasedTerrainTexture() -> NSImage {
        // 🔍 MEMORY LEAK DEBUG: Track large terrain texture creation
        MemoryLeakTracker.shared.trackTextureCreation(type: "terrain_heightmap", size: "512x512")
        let heightMap = simulationEngine.voxelWorld.heightMap
        let resolution = heightMap.count
        let size = CGSize(width: resolution, height: resolution)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // 🌍 MINECRAFT-STYLE TERRAIN MAPPING: Map actual terrain heights to colors

        
        for x in 0..<resolution {
            for z in 0..<resolution {
                let height = heightMap[x][z]
                
                // 🎯 HEIGHT-BASED TERRAIN COLORS (matches our terrain logic)
                let terrainColor: NSColor
                if height < -20 {
                    terrainColor = NSColor.blue                                      // Deep water
                } else if height < -5 {
                    terrainColor = NSColor.cyan                                      // Wetlands
                } else if height > 5 && height < 25 {
                    terrainColor = NSColor(red: 0, green: 0.5, blue: 0, alpha: 1)  // Forest (dark green)
                } else if height > 30 {
                    terrainColor = NSColor.gray                                      // Mountains
                } else if height > 15 {
                    terrainColor = NSColor.brown                                     // Hills
                } else {
                    terrainColor = NSColor.green                                     // Plains (default)
                }
                
                // Set pixel color using Core Graphics
                let pixelRect = CGRect(x: x, y: z, width: 1, height: 1)
                terrainColor.setFill()
                pixelRect.fill()
            }
        }
        
        image.unlockFocus()
        

        return image
    }
    
    private func renderSelectiveVoxelFeatures(container: SCNNode) {

        
        // Create features container for organization
        let featuresContainer = SCNNode()
        featuresContainer.name = "SurfaceFeatures"
        container.addChildNode(featuresContainer)
        
        var featureCount = 0
        let samplingRate = 4  // Even sparser for features - only every 4th voxel
        
        // Only render surface layer features that add visual interest
        for x in stride(from: 0, to: simulationEngine.voxelWorld.dimensions.width, by: samplingRate) {
            for y in stride(from: 0, to: simulationEngine.voxelWorld.dimensions.height, by: samplingRate) {
                for z in stride(from: 0, to: simulationEngine.voxelWorld.dimensions.depth, by: samplingRate) {
                    let voxel = simulationEngine.voxelWorld.voxels[x][y][z]
                    
                    // Only render interesting surface features
                    if shouldRenderAsFeature(voxel) {
                        let featureNode = createFeatureNode(voxel: voxel)
                        
                        // 🔧 TERRAIN SURFACE POSITIONING: Align features with terrain mesh
                        let terrainHeight = getTerrainHeightAt(x: voxel.position.x, z: voxel.position.y)
                        let surfacePosition = SCNVector3(
                            Float(voxel.position.x),
                            Float(terrainHeight), // Place on terrain surface
                            Float(voxel.position.y)
                        )
                        featureNode.position = surfacePosition
                        
                        featuresContainer.addChildNode(featureNode)
                        featureCount += 1
                    }
                }
            }
        }
        

    }
    
    private func shouldRenderAsFeature(_ voxel: Voxel) -> Bool {
        // Only render specific terrain types as features on top of the terrain mesh
        switch voxel.terrainType {
        case .forest:
            return voxel.layer == .surface || voxel.layer == .canopy  // Trees
        case .wall:
            return voxel.layer == .surface  // Rock outcroppings
        case .water:
            return voxel.layer == .surface && voxel.position.z > -10  // Water features above deep water
        default:
            return false  // Everything else is handled by the terrain mesh
        }
    }
    
    private func createFeatureNode(voxel: Voxel) -> SCNNode {
        let node = SCNNode()
        node.name = "Feature_\(voxel.terrainType)_\(voxel.gridPosition.x)_\(voxel.gridPosition.y)_\(voxel.gridPosition.z)"
        
        // Create appropriate geometry for the feature type
        let geometry = createFeatureGeometry(for: voxel)
        node.geometry = geometry
        
        // Position the feature
        let scnPosition = SCNVector3(
            Float(voxel.position.x),
            Float(voxel.position.z), // Use Z as height
            Float(voxel.position.y)
        )
        node.position = scnPosition
        
        return node
    }
    
    private func createFeatureGeometry(for voxel: Voxel) -> SCNGeometry {
        let baseSize = Float(simulationEngine.voxelWorld.voxelSize) * 1.5
        
        switch voxel.terrainType {
        case .forest:
            // Create simple tree representation
            return createTreeGeometry(size: baseSize)
        case .wall:
            // Create rock outcropping
            return createRockGeometry(size: baseSize)
        case .water:
            // Create water feature (smaller, animated)
            return createWaterFeatureGeometry(size: baseSize * 0.8)
        default:
            // Fallback to simple box
            let box = SCNBox(width: CGFloat(baseSize), height: CGFloat(baseSize), length: CGFloat(baseSize), chamferRadius: 0.02)
            box.firstMaterial?.diffuse.contents = NSColor.gray
            return box
        }
    }
    
    private func createTreeGeometry(size: Float) -> SCNGeometry {
        // Simple tree representation as a brown cylinder (trunk)
        // TODO: Could combine trunk + crown geometries for more realistic trees
        
        let trunk = SCNCylinder(radius: CGFloat(size * 0.1), height: CGFloat(size * 0.8))
        trunk.firstMaterial?.diffuse.contents = NSColor.brown
        trunk.firstMaterial?.roughness.contents = NSColor(white: 0.8, alpha: 1.0)
        
        return trunk
    }
    
    private func createRockGeometry(size: Float) -> SCNGeometry {
        let rock = SCNBox(
            width: CGFloat(size * 1.2), 
            height: CGFloat(size * 0.6), 
            length: CGFloat(size * 0.9), 
            chamferRadius: 0.1
        )
        rock.firstMaterial?.diffuse.contents = NSColor.darkGray
        rock.firstMaterial?.roughness.contents = NSColor(white: 0.9, alpha: 1.0)
        return rock
    }
    
    private func createWaterFeatureGeometry(size: Float) -> SCNGeometry {
        let water = SCNBox(
            width: CGFloat(size), 
            height: CGFloat(size * 0.2), 
            length: CGFloat(size), 
            chamferRadius: 0.02
        )
        water.firstMaterial?.diffuse.contents = NSColor.blue
        water.firstMaterial?.transparency = 0.7
        water.firstMaterial?.metalness.contents = NSColor(white: 0.0, alpha: 1.0)
        water.firstMaterial?.roughness.contents = NSColor(white: 0.1, alpha: 1.0)
        return water
    }
    
    private func shouldRenderVoxel(_ voxel: Voxel) -> Bool {
        // Only render voxels that represent actual terrain features
        // Navigation-friendly areas (air, flight) should remain invisible for movement
        switch voxel.transitionType {
        case .air:
            return false  // Don't render empty air voxels - navigable space
        case .flight(_):
            return false  // Don't render flight areas - navigable air space for flying
        case .solid, .swim(_), .climb(_), .ramp(_), .tunnel(_), .bridge(_):
            return true   // Render actual terrain features (walls, water, climbable surfaces, etc.)
        }
    }
    
    private func createVoxelNode(voxel: Voxel) -> SCNNode {
        let voxelNode = SCNNode()
        
        // Create geometry based on voxel properties
        let geometry = createVoxelGeometry(for: voxel)
        voxelNode.geometry = geometry
        
        // Position the voxel in 3D space
        let scnPosition = SCNVector3(
            Float(voxel.position.x),
            Float(voxel.position.z), // Use Z as height
            Float(voxel.position.y)
        )
        voxelNode.position = scnPosition
        
        // Debug positioning for first few voxels
        if voxel.gridPosition.x < 3 && voxel.gridPosition.y < 3 && voxel.gridPosition.z < 3 {
            // Voxel rendering debug (commented for performance)ion.y), \(scnPosition.z)) [\(voxel.transitionType)]")
        }
        
        // Add physics body for collision detection if solid
        if !voxel.transitionType.isPassable {
            // Create physics body with enhanced collision reliability
            let physicsOptions: [SCNPhysicsShape.Option: Any] = [
                .type: SCNPhysicsShape.ShapeType.boundingBox,  // Use bounding box for reliable collision
                .keepAsCompound: false,                         // Simplify to single shape
                .collisionMargin: 1.0                          // Larger collision margin for reliability
            ]
            let physicsShape = SCNPhysicsShape(geometry: geometry, options: physicsOptions)
            voxelNode.physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
            voxelNode.physicsBody?.categoryBitMask = 1     // Terrain category
            voxelNode.physicsBody?.collisionBitMask = 2    // Collides with bugs
            voxelNode.physicsBody?.contactTestBitMask = 2  // Detect contact with bugs
            
            // Enhance physics properties for more solid collision
            voxelNode.physicsBody?.friction = 2.0         // Extra high friction
            voxelNode.physicsBody?.restitution = 0.0      // No bounce to keep bugs grounded
            
            // Force physics body to be immediately active (read-only property, handled automatically)
            
            // Debug physics body creation
            // Physics body created for voxel (debug commented)
        }
        
        return voxelNode
    }
    
    private func createVoxelGeometry(for voxel: Voxel) -> SCNGeometry {
        // 🚀 PERFORMANCE FIX: Larger voxels to compensate for spatial sampling
        let baseVoxelSize = Float(simulationEngine.voxelWorld.voxelSize)
        let voxelSize = baseVoxelSize * 1.8  // Larger voxels to fill gaps from sampling
        
        // Create appropriate geometry based on voxel properties
        switch voxel.transitionType {
        case .solid:
            return createSolidVoxel(size: voxelSize, voxel: voxel)
        case .swim(let depth):
            return createWaterVoxel(size: voxelSize, voxel: voxel, depth: depth)
        case .climb(let difficulty):
            return createClimbVoxel(size: voxelSize, voxel: voxel, difficulty: difficulty)
        case .tunnel(let width):
            return createTunnelVoxel(size: voxelSize, voxel: voxel, width: width)
        case .ramp(let angle):
            return createRampVoxel(size: voxelSize, voxel: voxel, angle: angle)
        case .flight(let clearance):
            return createFlightVoxel(size: voxelSize, voxel: voxel, clearance: clearance)
        case .bridge(let stability):
            return createBridgeVoxel(size: voxelSize, voxel: voxel, stability: stability)
        case .air:
            return createAirVoxel(size: voxelSize, voxel: voxel)
        }
    }
    
    private func createSolidVoxel(size: Float, voxel: Voxel) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(size), length: CGFloat(size), chamferRadius: 0.02)
        
        // 🔍 MEMORY LEAK DEBUG: Track voxel geometry creation (8 vertices per box)
        MemoryLeakTracker.shared.trackGeometryCreation(type: "VoxelBox", vertexCount: 8)
        
        // AAA-Quality PBR Material System
        let material = createPBRMaterial(for: voxel)
        box.firstMaterial = material
        
        return box
    }
    
    private func createWaterVoxel(size: Float, voxel: Voxel, depth: Double) -> SCNGeometry {
        let waterHeight = Float(1.0 - depth) * size * 0.9  // Deeper water = lower height
        let box = SCNBox(width: CGFloat(size), height: CGFloat(waterHeight), length: CGFloat(size), chamferRadius: 0.05)
        
        // Advanced water material with realistic properties
        let material = createAdvancedWaterMaterial(depth: depth, voxel: voxel)
        box.firstMaterial = material
        
        return box
    }
    
    private func createAdvancedWaterMaterial(depth: Double, voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🎨 VAN GOGH WATER COLORING: Swirling artistic patterns
        let vanGoghWaterColor = createVanGoghWaterColor(voxel: voxel)
        
        material.diffuse.contents = vanGoghWaterColor
        material.metalness.contents = 0.98      // Water is highly reflective
        material.roughness.contents = 0.02      // Ultra-smooth surface
        material.transparency = 0.3 + (depth * 0.4)  // Deeper water is more opaque
        
        // 🎨 VAN GOGH SWIRL PATTERNS: Artistic water textures
        material.normal.contents = getVanGoghTexture(type: "water_swirl")
        material.transparencyMode = .aOne
        
        // 🎨 VAN GOGH CAUSTIC LIGHTING: Starlight on water effects
        material.emission.contents = createVanGoghCausticLighting(voxel: voxel)
        
        // 🎨 VAN GOGH REFLECTION MAPPING: Artistic sky reflections
        material.reflective.contents = createVanGoghWaterReflectionMap()
        
        // 🎨 VAN GOGH DISPLACEMENT: Painterly depth illusion
        material.displacement.contents = createVanGoghWaterDisplacementMap(voxel: voxel)
        
        return material
    }
    
    private func createWaterNormalMap(voxel: Voxel) -> NSImage {
        let size = 32
        let image = NSImage(size: NSSize(width: size, height: size))
        
        image.lockFocus()
        
        // Create ripple patterns
        for x in 0..<size {
            for y in 0..<size {
                let ripple1 = sin(Double(x + voxel.gridPosition.x) * 0.8) * cos(Double(y + voxel.gridPosition.y) * 0.8)
                let ripple2 = sin(Double(x + voxel.gridPosition.z) * 1.2) * cos(Double(y + voxel.gridPosition.z) * 1.2)
                let combined = (ripple1 + ripple2) * 0.3 + 0.5
                
                let color = NSColor(red: 0.5, green: 0.5, blue: combined, alpha: 1.0)
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func createClimbVoxel(size: Float, voxel: Voxel, difficulty: Double) -> SCNGeometry {
        let roughness = Float(difficulty)  // Higher difficulty = rougher surface
        let box = SCNBox(width: CGFloat(size), height: CGFloat(size), length: CGFloat(size), chamferRadius: 0.05)
        box.firstMaterial?.diffuse.contents = NSColor.brown.withAlphaComponent(0.8)
        box.firstMaterial?.roughness.contents = roughness
        return box
    }
    
    private func createTunnelVoxel(size: Float, voxel: Voxel, width: Double) -> SCNGeometry {
        let tunnelRadius = Float(width) * size * 0.4  // Width affects tunnel radius
        let cylinder = SCNCylinder(radius: CGFloat(tunnelRadius), height: CGFloat(size))
        cylinder.firstMaterial?.diffuse.contents = NSColor.darkGray.withAlphaComponent(0.7)
        return cylinder
    }
    
    private func createRampVoxel(size: Float, voxel: Voxel, angle: Double) -> SCNGeometry {
        // Create a sloped voxel for ramps
        let box = SCNBox(width: CGFloat(size), height: CGFloat(size * Float(angle)), length: CGFloat(size), chamferRadius: 0.1)
        box.firstMaterial?.diffuse.contents = getVoxelColor(voxel: voxel)
        box.firstMaterial?.roughness.contents = 0.5
        return box
    }
    
    private func createFlightVoxel(size: Float, voxel: Voxel, clearance: Double) -> SCNGeometry {
        // Create a partially transparent voxel for flight zones
        let sphere = SCNSphere(radius: CGFloat(size * Float(clearance) * 0.5))
        sphere.firstMaterial?.diffuse.contents = NSColor.cyan.withAlphaComponent(0.2)
        sphere.firstMaterial?.transparency = 0.8
        return sphere
    }
    
    private func createBridgeVoxel(size: Float, voxel: Voxel, stability: Double) -> SCNGeometry {
        // Create a bridge-like structure
        let box = SCNBox(width: CGFloat(size), height: CGFloat(size * 0.3), length: CGFloat(size), chamferRadius: 0.05)
        let stabilityAlpha = CGFloat(stability)
        box.firstMaterial?.diffuse.contents = NSColor.orange.withAlphaComponent(stabilityAlpha)
        box.firstMaterial?.metalness.contents = 0.7
        return box
    }
    
    private func createAirVoxel(size: Float, voxel: Voxel) -> SCNGeometry {
        // For air voxels that have resources, create small resource indicators
        if voxel.hasFood {
            let sphere = SCNSphere(radius: CGFloat(size * 0.2))
            sphere.firstMaterial?.diffuse.contents = NSColor.green
            sphere.firstMaterial?.emission.contents = NSColor.green.withAlphaComponent(0.3)
            return sphere
        }
        
        // Empty air - shouldn't render but just in case
        let box = SCNBox(width: CGFloat(size * 0.1), height: CGFloat(size * 0.1), length: CGFloat(size * 0.1), chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = NSColor.clear
        return box
    }
    
    // MARK: - Van Gogh Material System (No Caching)
    // 
    // MARK: - 🎨 Enhanced Stylized Material System
    
    /// Enhanced material creation following our style guide principles
    private func createStylizedMaterial(for voxel: Voxel) -> SCNMaterial {
        // 🎨 Style Guide-Driven Material Creation
        // Each material follows our "David Attenborough meets Studio Ghibli" vision
        
        switch voxel.terrainType {
        case .water:
            return createEnhancedWaterMaterial(voxel: voxel)
        case .forest:
            return createEnhancedForestMaterial(voxel: voxel)
        case .wall:
            return createEnhancedRockMaterial(voxel: voxel)
        case .sand:
            return createEnhancedSandMaterial(voxel: voxel)
        case .ice:
            return createEnhancedIceMaterial(voxel: voxel)
        case .hill:
            return createEnhancedStoneMaterial(voxel: voxel)
        case .food:
            return createEnhancedVegetationMaterial(voxel: voxel)
        case .swamp:
            return createEnhancedMudMaterial(voxel: voxel)
        case .open:
            return createEnhancedGrassMaterial(voxel: voxel)
        case .shadow:
            return createEnhancedShadowMaterial(voxel: voxel)
        case .predator:
            return createEnhancedPredatorMaterial(voxel: voxel)
        case .wind:
            return createEnhancedWindMaterial(voxel: voxel)
        }
    }
    
    // MARK: - 🌊 Enhanced Water Material - "Living Mirror"
    private func createEnhancedWaterMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Ocean Blue #1E90FF with transparency and movement
        let baseWaterBlue = NSColor(red: 0.12, green: 0.56, blue: 1.0, alpha: 0.8)
        
        material.diffuse.contents = baseWaterBlue
        
        // Water-like properties
        material.roughness.contents = 0.0  // Very smooth for reflections
        material.metalness.contents = 0.1  // Slightly metallic for shine
        material.transparency = 0.7        // Semi-transparent
        
        // Subtle blue emission for underwater glow
        material.emission.contents = NSColor(red: 0.02, green: 0.08, blue: 0.15, alpha: 1.0)
        
        return material
    }
    
    // MARK: - 🌲 Enhanced Forest Material - "Ancient Guardians"
    private func createEnhancedForestMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Rich Deep Forest Green #1B4D3E - darker, more saturated than basic green
        let enhancedForestGreen = NSColor(red: 0.11, green: 0.30, blue: 0.24, alpha: 1.0)
        
        // Add subtle procedural variation for organic feel
        let variation = Double.random(in: -0.03...0.03)
        let variedColor = NSColor(
            red: min(1.0, max(0.0, enhancedForestGreen.redComponent + variation)),
            green: min(1.0, max(0.0, enhancedForestGreen.greenComponent + variation * 0.7)),
            blue: min(1.0, max(0.0, enhancedForestGreen.blueComponent + variation)),
            alpha: 1.0
        )
        
        material.diffuse.contents = variedColor
        
        // High roughness for organic bark texture
        material.roughness.contents = 0.85 + Double.random(in: -0.1...0.1)
        material.metalness.contents = 0.0
        
        // Subtle life force glow
        material.emission.contents = NSColor(red: 0.02, green: 0.06, blue: 0.04, alpha: 1.0)
        
        return material
    }
    
    // MARK: - 🪨 Enhanced Rock Material - "Timeless Foundation"
    private func createEnhancedRockMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Weathered Stone #5D4E37 - rich earthy brown-gray
        let enhancedStoneColor = NSColor(red: 0.36, green: 0.31, blue: 0.22, alpha: 1.0)
        
        // Add subtle geological variation
        let variation = Double.random(in: -0.04...0.04)
        let variedColor = NSColor(
            red: min(1.0, max(0.0, enhancedStoneColor.redComponent + variation)),
            green: min(1.0, max(0.0, enhancedStoneColor.greenComponent + variation * 0.8)),
            blue: min(1.0, max(0.0, enhancedStoneColor.blueComponent + variation * 0.6)),
            alpha: 1.0
        )
        
        material.diffuse.contents = variedColor
        
        // High roughness for weathered stone texture
        material.roughness.contents = 0.90 + Double.random(in: -0.05...0.05)
        material.metalness.contents = 0.03  // Tiny bit of mineral shine
        
        // Very subtle mineral glow
        material.emission.contents = NSColor(red: 0.02, green: 0.015, blue: 0.01, alpha: 1.0)
        
        return material
    }
    
    // MARK: - 🏖️ Enhanced Sand Material - "Golden Memories"
    private func createEnhancedSandMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Warm Golden Sand #D2B48C - richer than basic tan
        let enhancedSandColor = NSColor(red: 0.82, green: 0.71, blue: 0.55, alpha: 1.0)
        
        // Add subtle grain variation
        let variation = Double.random(in: -0.02...0.02)
        let variedColor = NSColor(
            red: min(1.0, max(0.0, enhancedSandColor.redComponent + variation)),
            green: min(1.0, max(0.0, enhancedSandColor.greenComponent + variation * 0.9)),
            blue: min(1.0, max(0.0, enhancedSandColor.blueComponent + variation * 0.7)),
            alpha: 1.0
        )
        
        material.diffuse.contents = variedColor
        
        // Ultra-high roughness for sand grains
        material.roughness.contents = 0.95
        material.metalness.contents = 0.0
        
        // Warm golden emission
        material.emission.contents = NSColor(red: 0.1, green: 0.06, blue: 0.02, alpha: 1.0)
        
        return material
    }
    
    // MARK: - 🧊 Enhanced Ice Material - "Crystal Dreams"
    private func createEnhancedIceMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Glacier Blue #A2E4F0 with crystal clarity
        material.diffuse.contents = NSColor(red: 0.64, green: 0.89, blue: 0.94, alpha: 0.8)
        
        // Very low roughness for ice smoothness
        material.roughness.contents = 0.02
        material.metalness.contents = 0.15
        material.transparency = 0.2
        
        // Cool blue emission for inner glow
        material.emission.contents = NSColor(red: 0.02, green: 0.08, blue: 0.12, alpha: 1.0)
        
        return material
    }
    
    // MARK: - ⛰️ Enhanced Stone Material - "Mountain Majesty"
    private func createEnhancedStoneMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Rich Earth #8B4513 for hill stone
        material.diffuse.contents = NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0)
        
        // Medium roughness for weathered stone
        material.roughness.contents = 0.75
        material.metalness.contents = 0.03
        
        return material
    }
    
    // MARK: - 🍎 Enhanced Vegetation Material - "Life's Bounty"
    private func createEnhancedVegetationMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Emerald #50C878 for fresh food
        material.diffuse.contents = NSColor(red: 0.31, green: 0.78, blue: 0.47, alpha: 1.0)
        
        // Medium roughness for plant texture
        material.roughness.contents = 0.6
        material.metalness.contents = 0.0
        
        // Strong green emission for life energy
        material.emission.contents = NSColor(red: 0.1, green: 0.4, blue: 0.15, alpha: 1.0)
        
        return material
    }
    
    // MARK: - 🐊 Enhanced Mud Material - "Ancient Depths"
    private func createEnhancedMudMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Deep earth brown for swamp
        material.diffuse.contents = NSColor(red: 0.28, green: 0.22, blue: 0.12, alpha: 1.0)
        
        // Very high roughness for mud texture
        material.roughness.contents = 0.95
        material.metalness.contents = 0.0
        
        return material
    }
    
    // MARK: - 🌱 Enhanced Grass Material - "Living Carpet"
    private func createEnhancedGrassMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Forest Green #4D8B31 with seasonal variation
        let baseColor = NSColor(red: 0.30, green: 0.70, blue: 0.30, alpha: 1.0)
        
        // Apply layer-aware coloring (existing function)
        material.diffuse.contents = getLayerAwareColor(baseColor: baseColor, voxel: voxel)
        
        // Medium roughness for grass
        material.roughness.contents = 0.7
        material.metalness.contents = 0.0
        
        // Subtle green emission for life
        material.emission.contents = NSColor(red: 0.03, green: 0.08, blue: 0.03, alpha: 1.0)
        
        return material
    }
    
    // MARK: - 🌫️ Enhanced Shadow Material - "Mystery Veils"
    private func createEnhancedShadowMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        material.diffuse.contents = NSColor(white: 0.15, alpha: 0.7)
        material.transparency = 0.7
        material.roughness.contents = 0.9
        material.metalness.contents = 0.0
        
        return material
    }
    
    // MARK: - 🦁 Enhanced Predator Material - "Danger Zones"
    private func createEnhancedPredatorMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Coral #FF6B6B for danger
        material.diffuse.contents = NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 0.4)
            material.transparency = 0.6
            material.roughness.contents = 0.8
            material.metalness.contents = 0.02
        
        // Pulsing red emission for warning
        material.emission.contents = NSColor(red: 0.2, green: 0.02, blue: 0.02, alpha: 1.0)
        
        return material
    }
    
    // MARK: - 💨 Enhanced Wind Material - "Flowing Energy"
    private func createEnhancedWindMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Style Guide: Sky Blue #87CEEB for wind/air
        material.diffuse.contents = NSColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 0.3)
        material.transparency = 0.7
        material.roughness.contents = 0.1
        material.metalness.contents = 0.0
        
        // Flowing blue emission
        material.emission.contents = NSColor(red: 0.02, green: 0.05, blue: 0.08, alpha: 1.0)
        
        return material
    }
    
    // MARK: - 🌍 Biome-Aware Material Enhancement
    
    /// Enhance materials based on biome characteristics following our style guide
    private func applyBiomeEnhancement(_ material: SCNMaterial, voxel: Voxel, biome: BiomeType) -> SCNMaterial {
        // Apply biome-specific color modulation per our style guide
        
        switch biome {
        case .tundra:
            // "Crystalline Majesty" - Cool blues, pure whites
            addColorTint(material, tint: NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0), strength: 0.2)
        case .borealForest:
            // "Misty Cathedral" - Deep greens, silvery mist
            addColorTint(material, tint: NSColor(red: 0.85, green: 0.95, blue: 0.85, alpha: 1.0), strength: 0.15)
        case .temperateForest:
            // "Living Symphony" - Rich greens, warm earth
            addColorTint(material, tint: NSColor(red: 0.9, green: 1.0, blue: 0.85, alpha: 1.0), strength: 0.1)
        case .temperateGrassland:
            // "Windswept Freedom" - Fresh greens, golden yellows
            addColorTint(material, tint: NSColor(red: 1.0, green: 1.0, blue: 0.85, alpha: 1.0), strength: 0.15)
        case .desert:
            // "Timeless Endurance" - Warm sandstones, burning oranges
            addColorTint(material, tint: NSColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0), strength: 0.25)
        case .savanna:
            // "Epic Horizons" - Golden grass, earth reds
            addColorTint(material, tint: NSColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0), strength: 0.2)
        case .tropicalRainforest:
            // "Emerald Cathedral" - Every shade of green
            addColorTint(material, tint: NSColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0), strength: 0.2)
        case .wetlands:
            // "Mirror of Life" - Water blues, marsh greens
            addColorTint(material, tint: NSColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0), strength: 0.15)
        case .alpine:
            // "Majestic Heights" - Stone grays, alpine blues
            addColorTint(material, tint: NSColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0), strength: 0.2)
        case .coastal:
            // "Where Worlds Meet" - Ocean blues, sand golds
            addColorTint(material, tint: NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0), strength: 0.15)
        }
        
        return material
    }
    
    /// Add subtle color tint to material while preserving its character
    private func addColorTint(_ material: SCNMaterial, tint: NSColor, strength: Double) {
        guard let currentColor = material.diffuse.contents as? NSColor else { return }
        
        // Blend current color with biome tint
        let blendedColor = NSColor(
            red: currentColor.redComponent * (1.0 - strength) + tint.redComponent * strength,
            green: currentColor.greenComponent * (1.0 - strength) + tint.greenComponent * strength,
            blue: currentColor.blueComponent * (1.0 - strength) + tint.blueComponent * strength,
            alpha: currentColor.alphaComponent
        )
        
        material.diffuse.contents = blendedColor
    }
    
    // ALL CACHING DISABLED TO PREVENT SWIFTUI VIOLATIONS
    // Materials and textures are generated fresh each time for SwiftUI compliance
    // Performance traded for stability and Van Gogh effect visibility
    
    private func createPBRMaterial(for voxel: Voxel) -> SCNMaterial {
        // 🎨 ENHANCED ARTISTIC MATERIAL SYSTEM
        // Apply our new style guide-driven materials for cinematic beauty!
        
        // Use our enhanced material creation system
        return createStylizedMaterial(for: voxel)
    }
    
    // MARK: - 🎨 Enhanced Van Gogh Material System
    // Comprehensive artistic materials for all terrain types (merged from main branch)
    
    private func createVanGoghForestMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh forest colors: Deep greens with warm golden undertones
        let baseColor = NSColor(red: 0.2, green: 0.4, blue: 0.1, alpha: 1.0)  
        material.diffuse.contents = baseColor
        
        // Warm golden emission like sunlight through trees
        material.emission.contents = NSColor(red: 0.15, green: 0.12, blue: 0.05, alpha: 1.0)
        material.roughness.contents = 0.7
        material.metalness.contents = 0.0
        
        // Van Gogh swirl texture for tree bark
        material.normal.contents = getVanGoghTexture(type: "tree_swirl")
        
        return material
    }
    
    private func createVanGoghGrassMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh grass: Vibrant greens with brushstroke texture
        let grassGreen = NSColor(red: 0.3, green: 0.6, blue: 0.2, alpha: 1.0)
        material.diffuse.contents = grassGreen
        
        // Subtle earth-tone emission 
        material.emission.contents = NSColor(red: 0.05, green: 0.08, blue: 0.02, alpha: 1.0)
        material.roughness.contents = 0.8
        material.metalness.contents = 0.0
        
        return material
    }
    
    private func createVanGoghFoodMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh vegetation: Rich purples and oranges like his irises
        let foodColor = NSColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0)
        material.diffuse.contents = foodColor
        
        // Vibrant emission for food visibility
        material.emission.contents = NSColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 1.0)
        material.roughness.contents = 0.6
        material.metalness.contents = 0.0
        
        return material
    }
    
    private func createVanGoghRockMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh rocks: Warm earth tones with artistic texture
        let rockColor = NSColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
        material.diffuse.contents = rockColor
        
        // Subtle warm emission
        material.emission.contents = NSColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 1.0)
        material.roughness.contents = 0.9
        material.metalness.contents = 0.1
        
        return material
    }
    
    private func createVanGoghSandMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh sand: Warm golden yellows like his sunflower paintings
        let sandColor = NSColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0)
        material.diffuse.contents = sandColor
        
        // Bright golden emission like desert sunlight
        material.emission.contents = NSColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        material.roughness.contents = 0.6
        material.metalness.contents = 0.0
        
        return material
    }
    
    private func createVanGoghIceMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh ice: Cool blues and whites with crystalline beauty
        let iceColor = NSColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.8)
        material.diffuse.contents = iceColor
        
        // Cool blue emission like winter light
        material.emission.contents = NSColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0)
        material.roughness.contents = 0.1
        material.metalness.contents = 0.0
        material.transparency = 0.3
        
        return material
    }
    
    private func createVanGoghStoneMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh stone: Gray-blue tones like his quarry paintings
        let stoneColor = NSColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1.0)
        material.diffuse.contents = stoneColor
        
        // Cool gray emission
        material.emission.contents = NSColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 1.0)
        material.roughness.contents = 0.8
        material.metalness.contents = 0.2
        
        return material
    }
    
    private func createVanGoghSwampMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh swamp: Deep muddy greens and browns
        let swampColor = NSColor(red: 0.3, green: 0.4, blue: 0.2, alpha: 1.0)
        material.diffuse.contents = swampColor
        
        // Murky green emission
        material.emission.contents = NSColor(red: 0.08, green: 0.12, blue: 0.06, alpha: 1.0)
        material.roughness.contents = 0.9
        material.metalness.contents = 0.0
        
        return material
    }
    
    private func createVanGoghWindMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Van Gogh wind: Light flowing greens like grass in motion
        let windColor = NSColor(red: 0.4, green: 0.7, blue: 0.3, alpha: 0.7)
        material.diffuse.contents = windColor
        
        // Subtle green emission suggesting movement
        material.emission.contents = NSColor(red: 0.1, green: 0.15, blue: 0.08, alpha: 1.0)
        material.roughness.contents = 0.6
        material.metalness.contents = 0.0
        material.transparency = 0.2
        
        return material
    }
    
    // MARK: - 🗑️ DEAD CODE REMOVED: All async Van Gogh processing eliminated!
    // All materials are now applied instantly during voxel creation - no more 30s delays!
    
    private func createSimpleRockMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Simple rock material for performance (no Van Gogh styling)
        material.diffuse.contents = getLayerAwareColor(
            baseColor: NSColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0),
            voxel: voxel
        )
        material.metalness.contents = 0.02      // Rocks are not metallic
        material.roughness.contents = 0.8       // Rough surface
        
        return material
    }
    
    private func createOptimizedRockMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🎨 VAN GOGH ROCKS: Dramatic, expressive stone with swirling energy
        let vanGoghRockColor = createVanGoghRockColor(voxel: voxel)
        material.diffuse.contents = getLayerAwareColor(
            baseColor: vanGoghRockColor,
            voxel: voxel
        )
        material.metalness.contents = 0.1       // Slight metallic shimmer like minerals
        material.roughness.contents = 0.6       // Softer for painterly effect
        
        // Use Van Gogh swirling rock patterns
        material.normal.contents = getVanGoghTexture(type: "rock_swirl")
        
        // Add warm earth glow like Van Gogh's earthy palette
        material.emission.contents = NSColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 1.0)
        
        return material
    }
    
    // 🎨 Van Gogh Rock Color Generation
    private func createVanGoghRockColor(voxel: Voxel) -> NSColor {
        let position = voxel.position
        
        // Create geological swirling patterns like Van Gogh's brushstrokes
        let swirl1 = sin(position.x * 0.1) * cos(position.z * 0.12)
        let swirl2 = cos(position.y * 0.08) * sin(position.x * 0.15)
        let geologicalPattern = (swirl1 + swirl2) * 0.4
        
        // Van Gogh-style earth tones with dynamic intensity
        let earthBrown = 0.45 + geologicalPattern * 0.3      // Rich browns
        let warmOcher = 0.35 + geologicalPattern * 0.25      // Golden ochre tones  
        let deepUmber = 0.25 + max(0, geologicalPattern * 0.2) // Deep shadow tones
        
        // Add subtle mineral sparkle variation
        let mineralGlint = sin(position.x * 0.2 + position.z * 0.18) * 0.1
        
        return NSColor(
            red: CGFloat(earthBrown + mineralGlint),
            green: CGFloat(warmOcher + mineralGlint * 0.5),
            blue: CGFloat(deepUmber),
            alpha: 1.0
        )
    }
    
    private func createOptimizedWaterMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🌟 ULTRA-SPECTACULAR WATER SYSTEM: Multiple advanced techniques
        
        // 1. 🎨 VAN GOGH WATER COLOR: Swirling artistic patterns
        let vanGoghWaterColor = createVanGoghWaterColor(voxel: voxel)
        material.diffuse.contents = vanGoghWaterColor
        
        // 2. Ultra-realistic water physics properties
        material.metalness.contents = 0.95      // Nearly perfect reflection
        material.roughness.contents = 0.02      // Mirror-smooth surface
        material.transparency = calculateDynamicTransparency(voxel: voxel)
        
        // 3. 🎨 VAN GOGH SWIRL PATTERNS: Artistic water textures
        material.normal.contents = getVanGoghTexture(type: "water_swirl")
        material.transparencyMode = .aOne
        
        // 4. Spectacular caustic lighting effects
        material.emission.contents = createCausticLighting(voxel: voxel)
        
        // 5. Environment reflection for photorealism
        material.reflective.contents = createWaterReflectionMap()
        
        // 6. Advanced displacement for water depth illusion
        material.displacement.contents = createWaterDisplacementMap(voxel: voxel)
        
        return material
    }
    
    // 🌟 SPECTACULAR WATER COLOR SYSTEM
    private func createSpectacularWaterColor(voxel: Voxel) -> NSColor {
        let position = voxel.position
        let currentTime = Date().timeIntervalSince1970
        
        // 1. ULTRA-DRAMATIC FLOWING WATER ANIMATION - Amplified 3x!
        let flowX = sin(currentTime * 1.5 + position.x * 0.2) * 0.8         // 3x stronger, faster
        let flowY = cos(currentTime * 2.0 + position.y * 0.25) * 0.6        // More dramatic
        let flowZ = sin(currentTime * 1.0 + position.z * 0.15) * 0.7        // Enhanced movement
        
        // 2. DRAMATIC MULTI-LAYERED DEPTH SIMULATION - More layers, stronger effects
        let surfaceDisturbance = sin(position.x * 0.4 + currentTime * 4.0) * 
                                cos(position.z * 0.35 + currentTime * 3.0) * 0.4    // 3x stronger ripples
        let midDepthFlow = cos(position.x * 0.2 + position.z * 0.2 + currentTime * 1.5) * 0.5  // Enhanced flow
        let deepCurrents = sin(position.x * 0.1 + position.z * 0.12 + currentTime * 0.8) * 0.3  // Stronger currents
        
        // 3. SPECTACULAR CAUSTIC LIGHT INTERACTIONS - More patterns, faster animation
        let lightX = position.x / 15.0  // Tighter patterns
        let lightZ = position.z / 15.0
        let causticPattern1 = sin(lightX * 12.0 + currentTime * 6.0) * cos(lightZ * 10.0 + currentTime * 5.0)
        let causticPattern2 = cos(lightX * 18.0 + currentTime * 8.0) * sin(lightZ * 15.0 + currentTime * 7.0)
        let causticPattern3 = sin(lightX * 25.0 + lightZ * 20.0 + currentTime * 10.0) * 0.8  // New pattern!
        let lightEffect = (causticPattern1 + causticPattern2 + causticPattern3) * 0.6  // 2x stronger
        
        // 4. DEPTH-BASED COLOR BLENDING
        let deepBlue = 0.1 + flowZ * 0.15        // Deep ocean blues
        let mediumBlue = 0.4 + flowY * 0.2 + midDepthFlow // Medium water
        let surfaceBlue = 0.7 + flowX * 0.3 + surfaceDisturbance // Surface reflection
        
        // 5. CARIBBEAN/TROPICAL WATER COLORS with animation
        let turquoise = 0.2 + lightEffect * 0.4  // Bright tropical turquoise
        let emerald = 0.6 + (flowX + flowY) * 0.2 // Emerald green highlights
        let crystal = 0.9 + lightEffect * 0.1 + deepCurrents  // Crystal clear highlights
        
        // 6. FINAL SPECTACULAR COLOR COMPOSITION
        let finalRed = CGFloat(crystal * 0.3 + turquoise * 0.2)
        let finalGreen = CGFloat(emerald * 0.8 + lightEffect * 0.3)
        let finalBlue = CGFloat(surfaceBlue * 0.6 + mediumBlue * 0.3 + deepBlue * 0.1)
        
        return NSColor(
            red: finalRed,
            green: finalGreen, 
            blue: finalBlue,
            alpha: 0.75
        )
    }
    
    private func calculateDynamicTransparency(voxel: Voxel) -> CGFloat {
        let position = voxel.position
        let currentTime = Date().timeIntervalSince1970
        
        // DRAMATIC transparency variations - more dynamic range
        let baseTransparency = voxel.layer == .underground ? 0.3 : 0.6
        let rippleEffect = sin(currentTime * 4.0 + position.x * 0.3) * 0.25     // 2.5x stronger variation
        let waveEffect = cos(currentTime * 3.0 + position.z * 0.25) * 0.15      // Additional wave transparency
        
        let dynamicTransparency = baseTransparency + rippleEffect + waveEffect
        return CGFloat(max(0.2, min(0.9, dynamicTransparency)))  // Clamp to reasonable range
    }
    
    private func createAdvancedWaterNormals(voxel: Voxel) -> NSImage {
        let size = 64  // Higher resolution for water
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let currentTime = Date().timeIntervalSince1970
        
        for x in 0..<size {
            for y in 0..<size {
                // ULTRA-DRAMATIC multiple wave layers for spectacular water surface
                let wave1 = sin(Double(x) * 0.6 + currentTime * 6.0) * cos(Double(y) * 0.5 + currentTime * 4.0)
                let wave2 = cos(Double(x) * 0.3 + currentTime * 3.0) * sin(Double(y) * 0.4 + currentTime * 5.0)
                let wave3 = sin(Double(x) * 0.8 + Double(y) * 0.7 + currentTime * 8.0) * 0.8
                let wave4 = cos(Double(x) * 0.45 + Double(y) * 0.35 + currentTime * 7.0) * 0.6  // New wave layer
                
                let normalIntensity = (wave1 + wave2 + wave3 + wave4) / 4.0
                let clampedIntensity = (normalIntensity + 1.0) / 2.0  // Normalize to 0-1
                
                let color = NSColor(
                    red: 0.5, 
                    green: 0.5,
                    blue: clampedIntensity,
                    alpha: 1.0
                )
                
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func createCausticLighting(voxel: Voxel) -> NSColor {
        let position = voxel.position
        let currentTime = Date().timeIntervalSince1970
        
        // ULTRA-SPECTACULAR animated caustic patterns - dramatic sunlight through water
        let caustic1 = sin(position.x * 0.4 + currentTime * 8.0) * cos(position.z * 0.35 + currentTime * 7.0)
        let caustic2 = cos(position.x * 0.3 + currentTime * 6.0) * sin(position.z * 0.45 + currentTime * 9.0)
        let caustic3 = sin(position.x * 0.5 + position.z * 0.4 + currentTime * 11.0) * 0.9
        let caustic4 = cos(position.x * 0.25 + position.z * 0.3 + currentTime * 5.0) * 0.8  // New pattern
        
        let causticIntensity = (caustic1 + caustic2 + caustic3 + caustic4) / 4.0
        let brightness = max(0, causticIntensity) * 0.8  // 2x brighter caustics!
        
        // More dramatic color variations
        let dynamicRed = 0.3 + brightness * 1.2      // Enhanced warm sunlight
        let dynamicGreen = 0.5 + brightness * 0.9    // Richer golden highlights
        let dynamicBlue = 0.7 + brightness * 0.6     // Deeper water tones
        
        return NSColor(
            red: CGFloat(max(0, min(1, dynamicRed))),
            green: CGFloat(max(0, min(1, dynamicGreen))),
            blue: CGFloat(max(0, min(1, dynamicBlue))),
            alpha: 1.0
        )
    }
    
    private func createWaterReflectionMap() -> NSImage {
        // Create a simple sky reflection for water
        let size = 32
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Gradient from sky blue to white (clouds)
        for x in 0..<size {
            for y in 0..<size {
                let skyIntensity = Double(y) / Double(size)  // Vertical gradient
                let cloudNoise = sin(Double(x) * 0.5) * cos(Double(y) * 0.6) * 0.2
                
                let finalIntensity = skyIntensity + cloudNoise
                let color = NSColor(
                    red: CGFloat(0.6 + finalIntensity * 0.4),
                    green: CGFloat(0.8 + finalIntensity * 0.2),
                    blue: CGFloat(1.0),
                    alpha: 1.0
                )
                
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func createWaterDisplacementMap(voxel: Voxel) -> NSImage {
        let size = 32
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let currentTime = Date().timeIntervalSince1970
        
        // Create subtle displacement for water depth illusion
        for x in 0..<size {
            for y in 0..<size {
                let displacement = sin(Double(x) * 0.4 + currentTime * 2.0) * 
                                 cos(Double(y) * 0.3 + currentTime * 1.5) * 0.1
                
                let intensity = (displacement + 1.0) / 2.0  // Normalize
                let color = NSColor(red: intensity, green: intensity, blue: intensity, alpha: 1.0)
                
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    // 🌊 SPECTACULAR WATER ANIMATION SYSTEM
    private func startSpectacularWaterAnimation(scene: SCNScene) {
        // 🚨 AAA PERFORMANCE: DISABLED - This was a massive performance killer!
        // The water animation timer was doing scene.rootNode.enumerateChildNodes 10x/second
        // which enumerated through ALL nodes in the scene causing beach ball cursor
        
        
        // TODO: Replace with targeted water node updates using cached references
        // Only update specific water nodes that are actually visible
    }
    
    private func refreshSpectacularWaterMaterials(scene: SCNScene) {
        // Find all water voxel nodes and refresh their materials
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry,
               geometry is SCNBox,
               let material = geometry.firstMaterial,
               material.transparency > 0.3 {  // Likely a water voxel
                
                // Only refresh water materials (detect by metalness signature)
                if (material.metalness.contents as? NSNumber)?.floatValue == 0.95 {  // Our water metalness signature
                    
                    self.updateWaterMaterialInRealTime(node: node)
                }
            }
        }
    }
    
    private func updateWaterMaterialInRealTime(node: SCNNode) {
        guard let geometry = node.geometry,
              let material = geometry.firstMaterial else { return }
        
        // Create time-based water position for animation
        let currentTime = Date().timeIntervalSince1970
        let animatedPosition = Position3D(
            node.position.x + sin(currentTime) * 2.0,
            node.position.z + cos(currentTime * 1.2) * 1.5,  // Note: SCN Y->Z mapping
            node.position.y + sin(currentTime * 0.8) * 1.0   // Note: SCN Z->Y mapping
        )
        
        // Create animated voxel for material generation
        let animatedVoxel = createAnimatedWaterVoxel(position: animatedPosition)
        
        // Update the material properties with new Van Gogh animations
        DispatchQueue.main.async {
            material.diffuse.contents = self.createVanGoghWaterColor(voxel: animatedVoxel)
            material.emission.contents = self.createCausticLighting(voxel: animatedVoxel)
            material.transparency = self.calculateDynamicTransparency(voxel: animatedVoxel)
            
            // Update Van Gogh swirl patterns less frequently for performance
            if Int(currentTime * 2) % 3 == 0 {  // Every 1.5 seconds
                material.normal.contents = self.getVanGoghTexture(type: "water_swirl")
            }
        }
    }
    
    private func createAnimatedWaterVoxel(position: Position3D) -> Voxel {
        // Create a temporary voxel for animation calculations
        return Voxel(
            gridPosition: (0, 0, 0),  // Not used for materials
            worldPosition: position,
            terrainType: .water,
            layer: .surface,
            transitionType: .swim(depth: 0.8),
            biome: .temperateForest
        )
    }
    
    // 🎨 VAN GOGH ULTRA-SPECTACULAR WATER COLOR SYSTEM
    private func createVanGoghWaterColor(voxel: Voxel) -> NSColor {
        let position = voxel.position
        let currentTime = Date().timeIntervalSince1970
        
        // 1. VAN GOGH FLOWING BRUSHSTROKES - Ultra-dramatic like Starry Night over the Rhône
        let brushstrokeX = sin(currentTime * 1.5 + position.x * 0.2) * 0.8         // Flowing brushstrokes
        let brushstrokeY = cos(currentTime * 2.0 + position.y * 0.25) * 0.6        // Swirling patterns
        let brushstrokeZ = sin(currentTime * 1.0 + position.z * 0.15) * 0.7        // Depth movement
        
        // 2. VAN GOGH CIRCULAR SPIRAL PATTERNS - Like whirlpools in Starry Night
        let centerX = position.x / 50.0 - 0.5
        let centerY = position.y / 50.0 - 0.5
        let radius = sqrt(centerX * centerX + centerY * centerY)
        let angle = atan2(centerY, centerX)
        let spiral = sin(radius * 15.0 + angle * 4.0 + currentTime * 3.0) * 0.4    // Animated spirals
        
        // 3. VAN GOGH LAYERED WATER DEPTHS - Multiple brushstroke layers
        let surfaceSwirls = sin(position.x * 0.4 + currentTime * 4.0) * 
                           cos(position.z * 0.35 + currentTime * 3.0) * 0.4        // Surface brushstrokes
        let midDepthFlow = cos(position.x * 0.2 + position.z * 0.2 + currentTime * 1.5) * 0.5  // Medium depth
        let deepCurrents = sin(position.x * 0.1 + position.z * 0.12 + currentTime * 0.8) * 0.3  // Deep patterns
        
        // 4. VAN GOGH IMPASTO LIGHT EFFECTS - Thick paint texture like moonlight on water
        let lightX = position.x / 15.0
        let lightZ = position.z / 15.0
        let impasto1 = sin(lightX * 12.0 + currentTime * 6.0) * cos(lightZ * 10.0 + currentTime * 5.0)
        let impasto2 = cos(lightX * 18.0 + currentTime * 8.0) * sin(lightZ * 15.0 + currentTime * 7.0)
        let impasto3 = sin(lightX * 25.0 + lightZ * 20.0 + currentTime * 10.0) * 0.8
        let impastoEffect = (impasto1 + impasto2 + impasto3) * 0.6
        
        // 5. VAN GOGH SIGNATURE PALETTE - Deep blues, swirling yellows, moonlight whites
        let deepNightBlue = 0.1 + brushstrokeZ * 0.15 + spiral * 0.2            // Deep Van Gogh blues
        let swirlingCyan = 0.4 + brushstrokeY * 0.2 + midDepthFlow * 0.3        // Cyan highlights
        let moonlightBlue = 0.7 + brushstrokeX * 0.3 + surfaceSwirls * 0.2      // Surface moonlight
        
        // 6. VAN GOGH GOLDEN HIGHLIGHTS - Like starlight reflections
        let goldenHighlight = 0.2 + impastoEffect * 0.4 + spiral * 0.3          // Van Gogh gold
        let emeraldSwirl = 0.6 + (brushstrokeX + brushstrokeY) * 0.2            // Green swirls
        let celestialWhite = 0.9 + impastoEffect * 0.1 + deepCurrents * 0.1     // Celestial highlights
        
        // 7. FINAL VAN GOGH WATER COMPOSITION - Artistic color mixing
        let finalRed = CGFloat(celestialWhite * 0.3 + goldenHighlight * 0.4)     // Warm moonlight
        let finalGreen = CGFloat(emeraldSwirl * 0.8 + impastoEffect * 0.3)       // Van Gogh green-blues
        let finalBlue = CGFloat(moonlightBlue * 0.6 + swirlingCyan * 0.3 + deepNightBlue * 0.4)  // Deep blues
        
        return NSColor(
            red: finalRed,
            green: finalGreen,
            blue: finalBlue,
            alpha: 0.75
        )
    }
    
    // 🎨 VAN GOGH CAUSTIC LIGHTING SYSTEM - Starlight on water like in Starry Night over the Rhône
    private func createVanGoghCausticLighting(voxel: Voxel) -> NSColor {
        let position = voxel.position
        let currentTime = Date().timeIntervalSince1970
        
        // VAN GOGH STELLAR LIGHT PATTERNS - Like stars reflecting on water
        let starLight1 = sin(position.x * 0.4 + currentTime * 8.0) * cos(position.z * 0.35 + currentTime * 7.0)
        let starLight2 = cos(position.x * 0.3 + currentTime * 6.0) * sin(position.z * 0.45 + currentTime * 9.0)
        let starLight3 = sin(position.x * 0.5 + position.z * 0.4 + currentTime * 11.0) * 0.9
        let moonBeam = cos(position.x * 0.25 + position.z * 0.3 + currentTime * 5.0) * 0.8  // Moonlight pattern
        
        let celestialIntensity = (starLight1 + starLight2 + starLight3 + moonBeam) / 4.0
        let brightness = max(0, celestialIntensity) * 0.8
        
        // VAN GOGH PALETTE - Golden stars, deep blues, celestial whites
        let starGold = 0.8 + brightness * 1.2          // Golden starlight
        let moonSilver = 0.7 + brightness * 0.9        // Silver moonbeams  
        let deepNight = 0.3 + brightness * 0.6         // Deep night blues
        
        return NSColor(
            red: CGFloat(max(0, min(1, starGold))),
            green: CGFloat(max(0, min(1, moonSilver))),
            blue: CGFloat(max(0, min(1, deepNight))),
            alpha: 1.0
        )
    }
    
    // 🎨 VAN GOGH WATER REFLECTION MAPPING - Swirling night sky like Starry Night
    private func createVanGoghWaterReflectionMap() -> NSImage {
        let size = 32
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let currentTime = Date().timeIntervalSince1970
        
        // Van Gogh swirling night sky reflection
        for x in 0..<size {
            for y in 0..<size {
                // Swirling sky patterns like Starry Night
                let skySwirl = sin(Double(x) * 0.5 + currentTime * 2.0) * cos(Double(y) * 0.6 + currentTime * 1.5)
                let starPattern = cos(Double(x) * 0.3) * sin(Double(y) * 0.4) * 0.3
                
                let finalIntensity = (skySwirl + starPattern) * 0.5 + 0.5
                let color = NSColor(
                    red: CGFloat(0.2 + finalIntensity * 0.6),      // Golden sky tones
                    green: CGFloat(0.3 + finalIntensity * 0.5),    // Warm highlights
                    blue: CGFloat(0.8 + finalIntensity * 0.2),     // Deep night blues
                    alpha: 1.0
                )
                
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    // 🎨 VAN GOGH WATER DISPLACEMENT MAPPING - Painterly brushstroke depth
    private func createVanGoghWaterDisplacementMap(voxel: Voxel) -> NSImage {
        let size = 32
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let currentTime = Date().timeIntervalSince1970
        
        // Van Gogh impasto brushstroke displacement
        for x in 0..<size {
            for y in 0..<size {
                let brushstroke = sin(Double(x) * 0.4 + currentTime * 2.0) * 
                                cos(Double(y) * 0.3 + currentTime * 1.5) * 0.2
                let impasto = cos(Double(x) * 0.6 + Double(y) * 0.5) * 0.1  // Thick paint texture
                
                let displacement = brushstroke + impasto
                let intensity = (displacement + 1.0) / 2.0  // Normalize
                let color = NSColor(red: intensity, green: intensity, blue: intensity, alpha: 1.0)
                
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func createOptimizedWoodMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🎨 VAN GOGH TREES: Expressive cypress-like with flame patterns
        let vanGoghTreeColor = createVanGoghTreeColor(voxel: voxel)
        
        // Apply the actual Van Gogh tree colors with layer-aware color adjustments
        material.diffuse.contents = getLayerAwareColor(
            baseColor: vanGoghTreeColor,
            voxel: voxel
        )
        material.metalness.contents = 0.0       // Wood is not metallic
        material.roughness.contents = 0.7       // Textured bark feeling
        
        // Use Van Gogh flame-like tree normal map for artistic texture
        material.normal.contents = getVanGoghTexture(type: "tree_swirl")
        
        // Add warm tree glow like Van Gogh's golden trees
        material.emission.contents = NSColor(red: 0.2, green: 0.12, blue: 0.05, alpha: 1.0)
        
        return material
    }
    
    // 🎨 Van Gogh Tree Color Generation
    private func createVanGoghTreeColor(voxel: Voxel) -> NSColor {
        let position = voxel.position
        
        // Create vertical flame-like patterns for cypress trees
        let vertical = sin(position.z * 0.3) * cos(position.x * 0.1) * 0.3
        let bark = cos(position.y * 0.2) * 0.2
        
        // Van Gogh tree colors: warm browns with golden highlights
        let brownBase = 0.3 + vertical * 0.2
        let goldenHint = 0.15 + max(0, vertical * 0.3)
        let depth = 0.1 + bark * 0.1
        
        return NSColor(
            red: CGFloat(brownBase + goldenHint),
            green: CGFloat(brownBase * 0.7),
            blue: CGFloat(depth),
            alpha: 1.0
        )
    }
    
    private func createOptimizedSandMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Sand properties
        material.diffuse.contents = NSColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0)
        material.metalness.contents = 0.0       // Sand is not metallic
        material.roughness.contents = 0.9       // Very rough surface
        
        return material
    }
    
    private func createOptimizedIceMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Ice properties - highly reflective and smooth
        material.diffuse.contents = NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.9)
        material.metalness.contents = 0.1       // Slight metallic quality
        material.roughness.contents = 0.05      // Very smooth
        material.transparency = 0.1
        
        return material
    }
    
    private func createOptimizedStoneMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Stone/hill material
        material.diffuse.contents = NSColor(red: 0.5, green: 0.45, blue: 0.4, alpha: 1.0)
        material.metalness.contents = 0.05      // Slight metallic quality from minerals
        material.roughness.contents = 0.7       // Rough surface
        
        return material
    }
    
    private func createOptimizedVegetationMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🍎 VAN GOGH FOOD: Vibrant, pulsing life energy
        let vanGoghFoodColor = createVanGoghFoodColor(voxel: voxel)
        material.diffuse.contents = vanGoghFoodColor
        material.metalness.contents = 0.0       // Natural organic material
        material.roughness.contents = 0.5       // Softer, more inviting
        
        // Magical glow indicating nutritious life energy
        material.emission.contents = NSColor(red: 0.15, green: 0.6, blue: 0.15, alpha: 1.0)
        
        return material
    }
    
    // 🎨 Van Gogh Food Color Generation
    private func createVanGoghFoodColor(voxel: Voxel) -> NSColor {
        let position = voxel.position
        
        // Create pulsing life energy patterns
        let pulse1 = sin(position.x * 0.2) * cos(position.y * 0.2) * 0.3
        let pulse2 = cos(position.x * 0.15 + position.y * 0.15) * 0.2
        let lifePulse = (pulse1 + pulse2) * 0.5
        
        // Van Gogh-style vibrant greens with golden life energy
        let vibrantGreen = 0.6 + lifePulse * 0.3
        let lifeGold = 0.2 + max(0, lifePulse * 0.4)
        let depth = 0.1 + pulse1 * 0.1
        
        return NSColor(
            red: CGFloat(lifeGold),
            green: CGFloat(vibrantGreen),
            blue: CGFloat(depth),
            alpha: 1.0
        )
    }
    
    private func createOptimizedMudMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Swamp/mud material
        material.diffuse.contents = NSColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 1.0)
        material.metalness.contents = 0.0       // Mud is not metallic
        material.roughness.contents = 0.9       // Very rough surface
        
        return material
    }
    
    private func createOptimizedGrassMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🎨 VAN GOGH GRASS: Swirling, expressive grass with painterly feel
        let vanGoghGrassColor = createVanGoghGrassColor(voxel: voxel)
        material.diffuse.contents = getLayerAwareColor(
            baseColor: vanGoghGrassColor,
            voxel: voxel
        )
        material.metalness.contents = 0.0       // Grass is not metallic
        material.roughness.contents = 0.6       // Softer for painterly effect
        
        // Add Van Gogh swirling normal map for texture
        material.normal.contents = getVanGoghTexture(type: "grass_swirl")
        
        // Add subtle magical glow like Van Gogh's luminous greens
        material.emission.contents = NSColor(red: 0.05, green: 0.12, blue: 0.03, alpha: 1.0)
        
        return material
    }
    
    // 🎨 Van Gogh Color Generation for Grass
    private func createVanGoghGrassColor(voxel: Voxel) -> NSColor {
        // Van Gogh-inspired grass colors with swirling variation
        let position = voxel.position
        
        // Create swirling pattern using position-based noise
        let swirl1 = sin(position.x * 0.15) * cos(position.y * 0.15)
        let swirl2 = cos(position.x * 0.08) * sin(position.y * 0.12)
        let swirlIntensity = (swirl1 + swirl2) * 0.3
        
        // Van Gogh-style vibrant greens with expression
        let baseGreen = 0.5 + swirlIntensity * 0.4        // Dynamic green intensity
        let expressiveBlue = 0.15 + swirlIntensity * 0.2   // Cooler tones in shadows
        let warmYellow = 0.1 + max(0, swirlIntensity * 0.3) // Warm highlights
        
        return NSColor(
            red: CGFloat(warmYellow), 
            green: CGFloat(baseGreen), 
            blue: CGFloat(expressiveBlue), 
            alpha: 1.0
        )
    }
    
    // MARK: - Shared Texture System (Performance Optimized)
    
    private func getSharedTexture(type: String) -> NSImage {
        // ⚠️ SKIP STATIC PROPERTY ACCESS TO AVOID SWIFTUI VIOLATIONS
        // Always generate fresh textures during view updates
        
        // 🔍 MEMORY LEAK DEBUG: Track texture creation
        MemoryLeakTracker.shared.trackTextureCreation(type: type, size: "64x64")
        
        // Generate texture fresh each time (no cache access)
        let texture: NSImage
        switch type {
        case "rock_normal":
            texture = createOptimizedRockNormalMap()
        case "water_normal":
            texture = createOptimizedWaterNormalMap()
        case "wood_normal":
            texture = createOptimizedWoodNormalMap()
        case "grass_swirl":
            texture = createVanGoghSwirlTexture(pattern: .grass)
        case "water_swirl":
            texture = createVanGoghSwirlTexture(pattern: .water)
        case "tree_swirl":
            texture = createVanGoghSwirlTexture(pattern: .tree)
        case "rock_swirl":
            texture = createVanGoghSwirlTexture(pattern: .rock)
        default:
            texture = createDefaultNormalMap()
        }
        
        // ⚠️ NO CACHING TO AVOID SWIFTUI VIOLATIONS
        // Skip: Self.sharedTextures[type] = texture
        return texture
    }
    
    private func createOptimizedRockNormalMap() -> NSImage {
        let size = 32  // Reduced from 64 for performance
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Simplified noise pattern
        for x in 0..<size {
            for y in 0..<size {
                let noise = sin(Double(x) * 0.5) * cos(Double(y) * 0.5)
                let intensity = (noise + 1.0) / 2.0
                let color = NSColor(red: 0.5, green: 0.5, blue: intensity, alpha: 1.0)
                
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func createOptimizedWaterNormalMap() -> NSImage {
        let size = 24  // Smaller for better performance
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Simple ripple pattern
        for x in 0..<size {
            for y in 0..<size {
                let ripple = sin(Double(x) * 0.8) * cos(Double(y) * 0.8) * 0.3 + 0.5
                let color = NSColor(red: 0.5, green: 0.5, blue: ripple, alpha: 1.0)
                
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func createOptimizedWoodNormalMap() -> NSImage {
        let size = 24
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Simple wood grain
        for x in 0..<size {
            for y in 0..<size {
                let grain = sin(Double(y) * 0.6) * 0.3 + 0.7
                let color = NSColor(red: 0.5, green: 0.5, blue: grain, alpha: 1.0)
                
                let rect = NSRect(x: x, y: y, width: 1, height: 1)
                color.setFill()
                rect.fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func createDefaultNormalMap() -> NSImage {
        let size = 16
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Flat normal map
        NSColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()
        
        image.unlockFocus()
        return image
    }
    
    // MARK: - 🎨 Van Gogh Texture Generation System
    
    enum VanGoghPattern {
        case grass, water, tree, rock, sky
    }
    
    private func createVanGoghSwirlTexture(pattern: VanGoghPattern) -> NSImage {
        let size = 64  // Balanced size for detail vs performance
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Van Gogh swirling pattern generation
        for x in 0..<size {
            for y in 0..<size {
                let fx = Double(x) / Double(size)
                let fy = Double(y) / Double(size)
                
                // Create Van Gogh-style swirling patterns
                let swirl = createVanGoghSwirl(x: fx, y: fy, pattern: pattern)
                
                // Convert to normal map colors (bluish with red/green variation)
                let normalColor = NSColor(
                    red: CGFloat(0.5 + swirl.x * 0.5),
                    green: CGFloat(0.5 + swirl.y * 0.5),
                    blue: CGFloat(0.7 + swirl.z * 0.3),
                    alpha: 1.0
                )
                
                normalColor.setFill()
                NSRect(x: x, y: y, width: 1, height: 1).fill()
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func createVanGoghSwirl(x: Double, y: Double, pattern: VanGoghPattern) -> (x: Double, y: Double, z: Double) {
        switch pattern {
        case .grass:
            // Organic, flowing grass patterns like Van Gogh's wheat fields
            let swirl1 = sin(x * 8.0) * cos(y * 6.0) * 0.3
            let swirl2 = cos(x * 4.0) * sin(y * 8.0) * 0.2
            return (swirl1, swirl2, 0.1)
            
        case .water:
            // Circular, hypnotic water swirls like Starry Night
            let centerX = x - 0.5
            let centerY = y - 0.5
            let radius = sqrt(centerX * centerX + centerY * centerY)
            let angle = atan2(centerY, centerX)
            let spiral = sin(radius * 10.0 + angle * 3.0) * 0.4
            return (spiral * cos(angle), spiral * sin(angle), 0.2)
            
        case .tree:
            // Vertical, flame-like patterns for cypress trees
            let vertical = sin(y * 12.0) * cos(x * 3.0) * 0.4
            let twist = cos(y * 8.0 + x * 2.0) * 0.2
            return (twist, vertical, 0.15)
            
        case .rock:
            // Geological, mineral-like patterns with angular swirls
            let geological = sin(x * 8.0) * cos(y * 6.0) * 0.35
            let stratified = cos(y * 10.0) * 0.25
            return (geological, stratified * cos(x * 4.0), 0.2)
            
        case .sky:
            // Atmospheric, cloud-like swirls
            let cloud1 = sin(x * 3.0) * cos(y * 2.0) * 0.3
            let cloud2 = cos(x * 2.0 + y * 3.0) * 0.2
            return (cloud1, cloud2, 0.25)
        }
    }
    
    // 🎨 Van Gogh Texture Helper
    private func getVanGoghTexture(type: String) -> NSImage {
        return getSharedTexture(type: type)
    }
    
    // MARK: - Advanced Material Helpers
    
    private func getLayerAwareColor(baseColor: NSColor, voxel: Voxel) -> NSColor {
        // Modify colors based on terrain layer for depth perception
        switch voxel.layer {
        case .underground:
            // Darker, more muted colors underground
            return baseColor.withAlphaComponent(0.8).blended(withFraction: 0.3, of: NSColor.black) ?? baseColor
        case .surface:
            // Natural colors at surface
            return baseColor
        case .canopy:
            // Slightly lighter, more vibrant in canopy
            return baseColor.blended(withFraction: 0.1, of: NSColor.white) ?? baseColor
        case .aerial:
            // Lighter, more ethereal in aerial zones
            return baseColor.blended(withFraction: 0.2, of: NSColor.white) ?? baseColor
        }
    }
    
    private func modulateColorByBiome(baseColor: NSColor, biome: BiomeType) -> NSColor {
        // Add biome-specific color tinting
        switch biome {
        case .desert:
            return baseColor.blended(withFraction: 0.2, of: NSColor.orange) ?? baseColor
        case .tundra:
            return baseColor.blended(withFraction: 0.3, of: NSColor.cyan) ?? baseColor
        case .tropicalRainforest:
            return baseColor.blended(withFraction: 0.2, of: NSColor.green) ?? baseColor
        case .wetlands:
            return baseColor.blended(withFraction: 0.2, of: NSColor.blue) ?? baseColor
        case .alpine:
            return baseColor.blended(withFraction: 0.1, of: NSColor.white) ?? baseColor
        default:
            return baseColor
        }
    }
    
    // NOTE: Old per-voxel texture generation functions removed for performance
    // Now using shared texture system for optimal startup times
    
    private func getVoxelColor(voxel: Voxel) -> NSColor {
        // Legacy color system - kept for compatibility
        let biomeColor = getBiomeColor(biome: voxel.biome)
        let terrainColor = getTerrainTypeColor(terrain: voxel.terrainType)
        
        // Blend biome and terrain colors
        return blendColors(biomeColor, terrainColor, ratio: 0.6)
    }
    
    private func getBiomeColor(biome: BiomeType) -> NSColor {
        switch biome {
        case .tundra: return NSColor.white
        case .borealForest: return NSColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        case .temperateForest: return NSColor.green
        case .temperateGrassland: return NSColor.yellow
        case .desert: return NSColor.orange
        case .savanna: return NSColor.brown
        case .tropicalRainforest: return NSColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)
        case .wetlands: return NSColor.cyan
        case .alpine: return NSColor.lightGray
        case .coastal: return NSColor.blue
        }
    }
    
    private func getTerrainTypeColor(terrain: TerrainType) -> NSColor {
        switch terrain {
        case .open: return NSColor.green
        case .wall: return NSColor.gray
        case .water: return NSColor.blue
        case .food: return NSColor.yellow
        case .forest: return NSColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
        case .hill: return NSColor.brown
        case .sand: return NSColor.orange
        case .ice: return NSColor.white
        case .swamp: return NSColor(red: 0.0, green: 0.3, blue: 0.0, alpha: 1.0)
        case .wind: return NSColor.lightGray
        case .predator: return NSColor.red
        case .shadow: return NSColor.black
        }
    }
    
    private func blendColors(_ color1: NSColor, _ color2: NSColor, ratio: CGFloat) -> NSColor {
        let c1 = color1.usingColorSpace(.deviceRGB) ?? color1
        let c2 = color2.usingColorSpace(.deviceRGB) ?? color2
        
        return NSColor(
            red: c1.redComponent * ratio + c2.redComponent * (1 - ratio),
            green: c1.greenComponent * ratio + c2.greenComponent * (1 - ratio),
            blue: c1.blueComponent * ratio + c2.blueComponent * (1 - ratio),
            alpha: c1.alphaComponent * ratio + c2.alphaComponent * (1 - ratio)
        )
    }
    
    private func createTileNode(tile: ArenaTile3D, row: Int, col: Int) -> SCNNode {
        let tileNode = SCNNode()
        
        // Create geometry based on terrain type
        let geometry = createTerrainGeometry(for: tile.terrain, layer: tile.layer)
        tileNode.geometry = geometry
        
        // Position the tile in 3D space
        tileNode.position = SCNVector3(
            Float(tile.position.x),
            Float(tile.position.z), // Use Z as height
            Float(tile.position.y)
        )
        
        // Add physics body for collision detection
        if !tile.terrain.isPassable {
            tileNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            tileNode.physicsBody?.categoryBitMask = 1
        }
        
        // Add special effects for certain terrain types
        addTerrainEffects(node: tileNode, terrain: tile.terrain, layer: tile.layer)
        
        return tileNode
    }
    
    private func createTerrainGeometry(for terrain: TerrainType, layer: TerrainLayer) -> SCNGeometry {
        let size: Float = 10.0 // Tile size
        let height: Float = getTerrainHeight(for: terrain, layer: layer)
        
        switch terrain {
        case .open:
            return createOpenTerrain(size: size, height: height, layer: layer)
        case .wall:
            return createWallTerrain(size: size, height: height, layer: layer)
        case .water:
            return createWaterTerrain(size: size, height: height, layer: layer)
        case .food:
            return createFoodTerrain(size: size, height: height, layer: layer)
        case .forest:
            return createForestTerrain(size: size, height: height, layer: layer)
        case .hill:
            return createHillTerrain(size: size, height: height, layer: layer)
        case .sand:
            return createSandTerrain(size: size, height: height, layer: layer)
        case .ice:
            return createIceTerrain(size: size, height: height, layer: layer)
        case .swamp:
            return createSwampTerrain(size: size, height: height, layer: layer)
        case .wind:
            return createWindTerrain(size: size, height: height, layer: layer)
        case .predator:
            return createPredatorTerrain(size: size, height: height, layer: layer)
        case .shadow:
            return createShadowTerrain(size: size, height: height, layer: layer)
        }
    }
    
    private func getTerrainHeight(for terrain: TerrainType, layer: TerrainLayer) -> Float {
        let baseHeight: Float = 2.0
        
        switch terrain {
        case .wall: return baseHeight * 3.0
        case .hill: return baseHeight * 2.5
        case .forest: return baseHeight * 2.0
        case .water: return baseHeight * 0.3
        case .ice: return baseHeight * 1.2
        default: return baseHeight
        }
    }
    
    // MARK: - Terrain Type Geometries
    
    private func createOpenTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.2)
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .open, layer: layer)
        box.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return box
    }
    
    private func createWallTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.1)
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .wall, layer: layer)
        box.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return box
    }
    
    private func createWaterTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.5)
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .water, layer: layer)
        box.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return box
    }
    
    private func createFoodTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let sphere = SCNSphere(radius: CGFloat(size * 0.4))
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .food, layer: layer)
        sphere.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return sphere
    }
    
    private func createForestTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let cylinder = SCNCylinder(radius: CGFloat(size * 0.3), height: CGFloat(height))
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .forest, layer: layer)
        cylinder.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return cylinder
    }
    
    private func createHillTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let cone = SCNCone(topRadius: 0, bottomRadius: CGFloat(size * 0.6), height: CGFloat(height))
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .hill, layer: layer)
        cone.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return cone
    }
    
    private func createSandTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.3)
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .sand, layer: layer)
        box.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return box
    }
    
    private func createIceTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.1)
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .ice, layer: layer)
        box.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return box
    }
    
    private func createSwampTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.4)
        
        // 🎨 APPLY ENHANCED MATERIALS to tile terrain!
        let dummyVoxel = createDummyVoxel(terrainType: .swamp, layer: layer)
        box.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return box
    }
    
    private func createWindTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        // Invisible geometry with particle effects - keep simple for wind
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height * 0.1), length: CGFloat(size), chamferRadius: 0.5)
        box.firstMaterial?.diffuse.contents = NSColor.clear
        box.firstMaterial?.transparency = 0.1
        return box
    }
    
    private func createPredatorTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let pyramid = SCNPyramid(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size))
        
        // 🎨 APPLY ENHANCED MATERIALS to predator terrain (dramatic stones)!
        let dummyVoxel = createDummyVoxel(terrainType: .predator, layer: layer)
        pyramid.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        
        return pyramid
    }
    
    private func createShadowTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height * 0.5), length: CGFloat(size), chamferRadius: 0.2)
        
        // 🎨 APPLY ENHANCED MATERIALS to shadow terrain (dark artistic stones)!
        let dummyVoxel = createDummyVoxel(terrainType: .shadow, layer: layer)
        box.firstMaterial = createStylizedMaterial(for: dummyVoxel)
        box.firstMaterial?.transparency = 0.6
        return box
    }
    
    // 🎨 HELPER: Create dummy voxel for tile terrain Van Gogh materials
    private func createDummyVoxel(terrainType: TerrainType, layer: TerrainLayer) -> Voxel {
        return Voxel(
            gridPosition: (0, 0, 0),  // Not used for materials
            worldPosition: Position3D(0, 0, 0),  // Not used for materials  
            terrainType: terrainType,
            layer: layer,
            transitionType: .solid,  // Default transition
            biome: .temperateForest  // Default biome
        )
    }
    
    private func getLayerColor(layer: TerrainLayer, alpha: Float = 1.0) -> NSColor {
        switch layer {
        case .underground:
            return NSColor(red: 0.4, green: 0.3, blue: 0.2, alpha: CGFloat(alpha))
        case .surface:
            return NSColor(red: 0.3, green: 0.7, blue: 0.3, alpha: CGFloat(alpha))
        case .canopy:
            return NSColor(red: 0.2, green: 0.6, blue: 0.2, alpha: CGFloat(alpha))
        case .aerial:
            return NSColor(red: 0.7, green: 0.8, blue: 1.0, alpha: CGFloat(alpha))
        }
    }
    
    // MARK: - Phase 1 Debug: State Connection Verification
    
    /// PHASE 1 DEBUG: Verify Bug Model → 3D Node Mapping
    private func verifyBugMapping() {
        guard let sceneView = sceneView,
              let scene = sceneView.scene,
              let bugContainer = scene.rootNode.childNode(withName: "BugContainer", recursively: false) else {
            return
        }
        
        let bugModels = simulationEngine.bugs
        let bugNodes = bugContainer.childNodes.filter { $0.name?.hasPrefix("Bug_") == true }
        
        
        // Check for orphaned nodes (nodes without corresponding bug models)
        let orphanedNodes = bugNodes.filter { node in
            guard let nodeName = node.name,
                  let bugId = nodeName.replacingOccurrences(of: "Bug_", with: "").components(separatedBy: "_").first,
                  let uuid = UUID(uuidString: bugId) else { return true }
            return !bugModels.contains { $0.id == uuid }
        }
        
        if !orphanedNodes.isEmpty {
        }
        
        // Check for missing nodes (bug models without corresponding nodes)
        let missingNodes = bugModels.filter { bug in
            let targetName = "Bug_\(bug.id.uuidString)"
            return bugContainer.childNode(withName: targetName, recursively: false) == nil
        }
        
        if !missingNodes.isEmpty {
            for bug in missingNodes.prefix(3) {
            }
        }
    }
    
    /// PHASE 1 DEBUG: Track update frequency and position changes
    // 🔧 FIXED: Converted to static variables to prevent state modification warnings
    private static var lastUpdateTime: TimeInterval = 0
    private static var updateCallCount: Int = 0
    private static var syncCallCount: Int = 0  // Track synchronizeWorldState calls
    private static var lastKnownBugPositions: [UUID: Position3D] = [:]
    
    private static var bugPositionTracker: [UUID: Position3D] = [:] // Track all bug positions for movement debugging
    private static var swiftuiUpdateCount: Int = 0 // Track SwiftUI update frequency for debugging
    private static var updateBugPositionsCount: Int = 0 // Track updateBugPositions call frequency
    private static var forceUpdateTrigger: Int = 0 // Force SwiftUI to call updateNSView regularly
    
    // 🔄 Method to force visual updates by directly calling updateBugPositions
    func triggerVisualUpdate() {
        // ✅ FIXED: Simplified approach - only use global persistent scene to avoid @State access
        if let globalScene = Arena3DView.globalPersistentScene {
            updateBugPositions(scene: globalScene)
        }
    }
    

    
    /// PHASE 1 DEBUG: Verify simulation state is actually changing
    private func debugSimulationState() {
        
        // Sample first 3 bugs for detailed state
        for (index, bug) in simulationEngine.bugs.prefix(3).enumerated() {
        }
    }
    

    
    // MARK: - Phase 1: Real-Time State Synchronization
    
    /// PHASE 1: Event-driven synchronization (replaces timer-based approach for performance)
    private func triggerStateSynchronization() {
        // This will be called by existing update methods instead of using a timer
        synchronizeWorldState()
    }
    
    /// PHASE 1: Stop synchronization system
    private func stopStateSynchronization() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    /// PHASE 1: Core synchronization method - updates 3D scene from simulation state
    private func synchronizeWorldState() {
        // ✅ FIXED: Use global persistent scene to avoid @State access during view updates
        guard let scene = Arena3DView.globalPersistentScene else { 
            return 
        }
        
        // 1. Update bug positions and states (existing comprehensive function)
        updateBugPositions(scene: scene)
        
        // 2. Update food items - REMOVED to prevent double food system conflict
        // Food is handled by main view update cycle
        
        // 3. Handle bug lifecycle (births/deaths) - handled within updateBugPositions
        // Existing function already creates missing nodes and cleans up orphaned ones
    }
    

    
    /// PHASE 1: Update energy bar visual based on bug energy
    private func updateEnergyBarVisual(energyBar: SCNNode, energy: Double) {
        // Scale energy bar based on energy level (0-100)
        let energyRatio = Float(max(0, min(1, energy / 100.0)))
        
        // Update scale
        energyBar.scale = SCNVector3(energyRatio, 1.0, 1.0)
        
        // Update color based on energy level
        if let material = energyBar.geometry?.firstMaterial {
            if energyRatio > 0.7 {
                material.diffuse.contents = NSColor.green
            } else if energyRatio > 0.3 {
                material.diffuse.contents = NSColor.orange
            } else {
                material.diffuse.contents = NSColor.red
            }
        }
    }
    
    // MARK: - Physics Body Cleanup
    
    /// Safely removes a bug node with proper physics body cleanup
    private func removeBugNodeSafely(_ bugNode: SCNNode) {
        // 🔍 MEMORY LEAK DEBUG: Track physics body cleanup (CRITICAL FIX!)
        if bugNode.physicsBody != nil {
            MemoryLeakTracker.shared.trackPhysicsBodyDestruction(type: "BugDynamic")
            bugNode.physicsBody = nil // Explicitly clear physics body
        }
        
        bugNode.removeFromParentNode()
    }
    
    // MARK: - Bug Rendering
    
    private func renderBugs(scene: SCNScene) {
        let bugs = simulationEngine.bugs
        // Rendering 3D Bugs
        // Bug array contents (debug commented)
        
        let bugContainer = SCNNode()
        bugContainer.name = "BugContainer"
        scene.rootNode.addChildNode(bugContainer)
        
        for bug in bugs {
            // 🔧 FIX: Check if node already exists before creating (renderBugs path)
            let existingNode = bugContainer.childNode(withName: "Bug_\(bug.id.uuidString)", recursively: false)
            if existingNode == nil {
                let bugNode = createBugNode(bug: bug)
                bugContainer.addChildNode(bugNode)
                // Created 3D node for bug
            }
        }
        // BugContainer added to scene
    }
    
    private func createBugNode(bug: Bug) -> SCNNode {
        let bugNode = SCNNode()
        bugNode.name = "Bug_\(bug.id.uuidString)"
        
        // 🔍 MEMORY LEAK DEBUG: Track bug node creation (minimized logging)
        MemoryLeakTracker.shared.trackNodeCreation(type: "BugNode", name: bugNode.name ?? "unnamed")
        
        // TODO: SCNNode Leak Monitoring - Currently showing 2-3 node net leak per test
        // This small leak could compound over extended runtime (hours/days)
        // If node leak grows beyond 50, check:
        // 1. All 4 existence check paths are working properly
        // 2. Death animations are properly destroying nodes
        // 3. Generation changes are cleaning up correctly
        // 4. cleanupOrphanedMappings() is catching all edge cases
        
        // Create detailed multi-part bug body based on species
        createDetailedBugBody(for: bug, parentNode: bugNode)
        
        // ✅ TEMPORARY DEBUG:Increase bug scale for better movement visibility
        bugNode.scale = SCNVector3(2.0, 2.0, 2.0) // 2x larger for visibility
        
        // 🎯 TEMPORARY FIX: Add invisible collision sphere for reliable clicking
        let clickSphere = SCNSphere(radius: CGFloat(bug.dna.size * 8.0)) // Larger than visual
        clickSphere.firstMaterial?.transparency = 0.0 // Completely invisible
        let clickNode = SCNNode(geometry: clickSphere)
        clickNode.name = "ClickCollider_\(bug.id.uuidString)"
        bugNode.addChildNode(clickNode)
        // Only log click sphere creation for every 10th bug to reduce noise
        if Int.random(in: 1...10) == 1 {
        }
        
        // Add movement capabilities indicators
        if bug.canFly {
            addWings(to: bugNode, bug: bug)
        }
        
        if bug.canSwim {
            addFins(to: bugNode, bug: bug)
        }
        
        if bug.canClimb {
            addClimbingGear(to: bugNode, bug: bug)
        }
        
        // 🌍 TERRAIN FOLLOWING: Use actual terrain height for initial bug positioning
        let terrainHeight = getTerrainHeightAt(x: bug.position3D.x, z: bug.position3D.y)
        let scnPosition = SCNVector3(
            Float(bug.position3D.x),
            Float(terrainHeight + 4.0), // Place bug well above terrain surface to prevent body clipping
            Float(bug.position3D.y)
        )
        
        bugNode.position = scnPosition
        
        // Debug positioning
        // Bug positioned (debug commented)
        
        // 🔍 DEBUG: Physics body setup
        
        // Add physics body with enhanced shape and margin for reliable collision
        // Create a simple physics shape for the compound bug body
        let physicsRadius = CGFloat(bug.dna.size * 6.0) // Slightly larger for better collision
        let physicsGeometry = SCNSphere(radius: physicsRadius)
        
        // Use simpler physics shape for better performance and reliability
        let physicsShape = SCNPhysicsShape(geometry: physicsGeometry, options: [
            .type: SCNPhysicsShape.ShapeType.convexHull,
            .collisionMargin: 1.0  // Increased margin for better collision detection
        ])
        
        // 🔍 MEMORY LEAK DEBUG: Track physics creation (LIKELY THE REAL CULPRIT!)
        MemoryLeakTracker.shared.trackPhysicsShapeCreation(type: "BugPhysics", complexity: "ConvexHull")
        
        bugNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        
        // 🔍 MEMORY LEAK DEBUG: Track physics body creation
        MemoryLeakTracker.shared.trackPhysicsBodyCreation(type: "BugDynamic")
        bugNode.physicsBody?.mass = 0.1
        bugNode.physicsBody?.categoryBitMask = 2       // Bug category  
        bugNode.physicsBody?.collisionBitMask = 1      // Collides with terrain
        bugNode.physicsBody?.contactTestBitMask = 1    // Detect contact with terrain
        
        // Configure physics properties to prevent falling through
        bugNode.physicsBody?.restitution = 0.1        // Minimal bounce
        bugNode.physicsBody?.friction = 1.0           // Maximum grip on terrain
        bugNode.physicsBody?.damping = 0.8            // High damping for stability
        
        // CRITICAL: Enable continuous collision detection to prevent tunneling
        bugNode.physicsBody?.usesDefaultMomentOfInertia = true
        bugNode.physicsBody?.continuousCollisionDetectionThreshold = 0.01  // Very sensitive
        
        // Limit velocity to prevent physics engine breaking
        bugNode.physicsBody?.velocityFactor = SCNVector3(0.3, 0.3, 0.3)  // Further reduced max velocity
        
        // Only log physics creation for every 20th bug to reduce noise
        if Int.random(in: 1...20) == 1 {
        }
        
        // 🌟 PHASE 3: Enhanced Health & Age Indicators
        addAdvancedHealthIndicators(to: bugNode, bug: bug)
        
        // 🎭 PHASE 3: Add behavioral animation system
        addBehavioralAnimations(to: bugNode, bug: bug)
        
        // 🔍 Debug: Get bug ID for logging
        let bugId = bug.id.uuidString.prefix(8)
        
        // 🎯 Bug Selection: Establish node-to-bug mapping
        bugNodeToBugMapping[bugNode] = bug
        // print("🗂️ [MAPPING-CREATED] Arena3DView mapping: '\(bugNode.name ?? "unnamed")' → bug \(bugId)")
        
        // Update NavigationResponder's mapping too
        // 🐛 FIX: Ensure navigation mapping is updated even during direct triggerVisualUpdate() calls
        if let navResponder = navigationResponder {
            navResponder.bugNodeToBugMapping[bugNode] = bug
            // print("✅ [NAV-MAPPING] NavigationResponder mapping updated via @State reference for bug \(bugId)")
            // Only log navigation mapping for every 20th bug to reduce noise
            if Int.random(in: 1...20) == 1 {
            }
        } else {
            // 🐛 FIX: During direct updates, navigationResponder @State may be nil
            // Use static reference to update NavigationResponder directly
            // print("⚠️ [NAV-MAPPING] @State navigationResponder is nil, trying static reference...")
            if let staticNavResponder = NavigationResponderView.currentInstance {
                staticNavResponder.bugNodeToBugMapping[bugNode] = bug
                // print("🔧 [BUG-MAPPING-FIX] Updated NavigationResponder mapping via static reference for bug \(bugId)")
            } else {
                // print("❌ [NAV-MAPPING] No static NavigationResponder reference available!")
            }
            // Only log missing NavigationResponder for every 20th bug
            if Int.random(in: 1...20) == 1 {
            }
        }
        
        // Only log mapping creation for every 20th bug to reduce noise
        if Int.random(in: 1...20) == 1 {
            let nodeName = bugNode.name ?? "unnamed"
        }
        
        // 🔍 Debug: Check if bug node has proper geometry for hit testing
        if bugNode.childNodes.isEmpty {
        } else {
        }
        
        // 🔍 Debug: Check physics body setup
        if let physicsBody = bugNode.physicsBody {
        } else {
        }
        
        return bugNode
    }
    
    // MARK: - 🦋 PHASE 3: CREATURE BEAUTY - Advanced Bug Geometry
    
    // 🦋 PHASE 3: Create detailed multi-part insect body based on species
    private func createDetailedBugBody(for bug: Bug, parentNode: SCNNode) {
        let species = bug.dna.speciesTraits.speciesType
        let size = Float(bug.dna.size * 10.0) // Scale for visibility in voxel world
        
        switch species {
        case .herbivore:
            createDetailedHerbivoreBody(bug: bug, size: size, parentNode: parentNode)
        case .carnivore:
            createDetailedCarnivoreBody(bug: bug, size: size, parentNode: parentNode)
        case .omnivore:
            createDetailedOmnivoreBody(bug: bug, size: size, parentNode: parentNode)
        case .scavenger:
            createDetailedScavengerBody(bug: bug, size: size, parentNode: parentNode)
        }
    }
    
    private func createBugGeometry(for bug: Bug) -> SCNGeometry {
        let species = bug.dna.speciesTraits.speciesType
        let size = Float(bug.dna.size * 10.0) // Scale for visibility in voxel world
        
        switch species {
        case .herbivore:
            // 🦋 BUTTERFLY/BEETLE INSPIRATION: Elegant oval body with gentle curves
            return createHerbivoreGeometry(bug: bug, size: size)
            
        case .carnivore:
            // 🥊 PRAYING MANTIS/WASP INSPIRATION: Angular, predatory with sharp edges
            return createCarnivoreGeometry(bug: bug, size: size)
            
        case .omnivore:
            // 🐜 ANT/BEE INSPIRATION: Segmented body with tool-carrying adaptations
            return createOmnivoreGeometry(bug: bug, size: size)
            
        case .scavenger:
            // 🪰 FLY INSPIRATION: Rounded, opportunistic with weathered appearance
            return createScavengerGeometry(bug: bug, size: size)
        }
    }
    
    // 🦋 Herbivore: Butterfly/Beetle-inspired elegant geometry
    private func createHerbivoreGeometry(bug: Bug, size: Float) -> SCNGeometry {
        // Create compound geometry for detailed insect body
        let compoundNode = SCNNode()
        
        // 1. HEAD: Small rounded head
        let head = SCNSphere(radius: CGFloat(size * 0.3))
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, size * 0.8, 0)
        head.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.25, 
            speciesModifier: 0.3,
            baseColor: NSColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        )
        compoundNode.addChildNode(headNode)
        
        // 2. THORAX: Elongated oval thorax (main body)
        let thorax = SCNSphere(radius: CGFloat(size * 0.5))
        thorax.segmentCount = 12
        let thoraxNode = SCNNode(geometry: thorax)
        thoraxNode.scale = SCNVector3(1.0, 1.4, 0.8)  // Make it elongated
        thoraxNode.position = SCNVector3(0, 0, 0)
        thorax.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.25, 
            speciesModifier: 0.3,
            baseColor: NSColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        )
        compoundNode.addChildNode(thoraxNode)
        
        // 3. ABDOMEN: Segmented abdomen
        let abdomen = SCNSphere(radius: CGFloat(size * 0.4))
        let abdomenNode = SCNNode(geometry: abdomen)
        abdomenNode.scale = SCNVector3(0.9, 1.6, 0.7)  // Long and narrow
        abdomenNode.position = SCNVector3(0, -size * 0.9, 0)
        abdomen.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.25, 
            speciesModifier: 0.2,
            baseColor: NSColor(red: 0.15, green: 0.6, blue: 0.25, alpha: 1.0)
        )
        compoundNode.addChildNode(abdomenNode)
        
        // 4. ANTENNAE: Thin cylindrical antennae
        for i in 0..<2 {
            let antenna = SCNCylinder(radius: CGFloat(size * 0.05), height: CGFloat(size * 0.6))
            let antennaNode = SCNNode(geometry: antenna)
            let xOffset = i == 0 ? -size * 0.2 : size * 0.2
            antennaNode.position = SCNVector3(xOffset, size * 1.0, size * 0.1)
            antennaNode.eulerAngles = SCNVector3(Float.pi * 0.3, 0, 0)
            antenna.firstMaterial?.diffuse.contents = NSColor.brown
            compoundNode.addChildNode(antennaNode)
        }
        
        // Return the compound geometry as a single shape
        // Since SCNGeometry can't contain child nodes, we'll return the thorax as main geometry
        // and add the other parts as child nodes to the bug node later
        return thorax
    }
    
    // 🦋 Detailed Herbivore Body: Butterfly/Beetle-inspired multi-part geometry
    private func createDetailedHerbivoreBody(bug: Bug, size: Float, parentNode: SCNNode) {
        // 1. HEAD: Small rounded head with compound eyes
        let head = SCNSphere(radius: CGFloat(size * 0.3))
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, size * 0.8, 0)
        head.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.25, 
            speciesModifier: 0.3,
            baseColor: NSColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        )
        parentNode.addChildNode(headNode)
        
        // 2. THORAX: Elongated oval thorax (main body) 
        let thorax = SCNSphere(radius: CGFloat(size * 0.5))
        thorax.segmentCount = 12
        let thoraxNode = SCNNode(geometry: thorax)
        thoraxNode.scale = SCNVector3(1.0, 1.4, 0.8)  // Make it elongated
        thoraxNode.position = SCNVector3(0, 0, 0)
        thorax.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.25, 
            speciesModifier: 0.3,
            baseColor: NSColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        )
        parentNode.addChildNode(thoraxNode)
        
        // 3. ABDOMEN: Segmented abdomen
        let abdomen = SCNSphere(radius: CGFloat(size * 0.4))
        let abdomenNode = SCNNode(geometry: abdomen)
        abdomenNode.scale = SCNVector3(0.9, 1.6, 0.7)  // Long and narrow
        abdomenNode.position = SCNVector3(0, -size * 0.9, 0)
        abdomen.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.25, 
            speciesModifier: 0.2,
            baseColor: NSColor(red: 0.15, green: 0.6, blue: 0.25, alpha: 1.0)
        )
        parentNode.addChildNode(abdomenNode)
        
        // 4. ANTENNAE: Thin cylindrical antennae
        for i in 0..<2 {
            let antenna = SCNCylinder(radius: CGFloat(size * 0.05), height: CGFloat(size * 0.6))
            let antennaNode = SCNNode(geometry: antenna)
            let xOffset = i == 0 ? -size * 0.2 : size * 0.2
            antennaNode.position = SCNVector3(xOffset, size * 1.0, size * 0.1)
            antennaNode.eulerAngles = SCNVector3(Float.pi * 0.3, 0, 0)
            antenna.firstMaterial?.diffuse.contents = NSColor.brown
            parentNode.addChildNode(antennaNode)
        }
        
        // 5. LEGS: Six legs positioned around thorax
        for i in 0..<6 {
            let leg = SCNCylinder(radius: CGFloat(size * 0.03), height: CGFloat(size * 0.4))
            let legNode = SCNNode(geometry: leg)
            
            let angle = Float(i) * Float.pi / 3.0
            let legX = cos(angle) * size * 0.6
            let legZ = sin(angle) * size * 0.6
            
            legNode.position = SCNVector3(legX, -size * 0.2, legZ)
            legNode.eulerAngles = SCNVector3(Float.pi * 0.5, angle, 0)
            leg.firstMaterial?.diffuse.contents = NSColor.darkGray
            parentNode.addChildNode(legNode)
        }
    }
    
    // 🥊 Carnivore: Praying Mantis/Wasp-inspired predatory geometry
    private func createCarnivoreGeometry(bug: Bug, size: Float) -> SCNGeometry {
        // Create angular, aggressive thorax
        let body = SCNBox(
            width: CGFloat(size * 0.8), 
            height: CGFloat(size * 1.2), 
            length: CGFloat(size * 1.4), 
            chamferRadius: CGFloat(size * 0.1)
        )
        
        // Sharp, predatory appearance with genetic variation
        body.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.05, 
            speciesModifier: 0.9,
                baseColor: NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
            )
        
        return body
    }
    
    // 🥊 Detailed Carnivore Body: Praying Mantis/Wasp-inspired predatory geometry
    private func createDetailedCarnivoreBody(bug: Bug, size: Float, parentNode: SCNNode) {
        // 1. HEAD: Triangular predatory head
        let head = SCNBox(
            width: CGFloat(size * 0.4), 
            height: CGFloat(size * 0.3), 
            length: CGFloat(size * 0.5), 
            chamferRadius: CGFloat(size * 0.05)
        )
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, size * 0.9, 0)
        head.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.05, 
            speciesModifier: 0.9,
            baseColor: NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        )
        parentNode.addChildNode(headNode)
        
        // 2. THORAX: Angular, muscular thorax
        let thorax = SCNBox(
            width: CGFloat(size * 0.6), 
            height: CGFloat(size * 0.8), 
            length: CGFloat(size * 1.0), 
            chamferRadius: CGFloat(size * 0.1)
        )
        let thoraxNode = SCNNode(geometry: thorax)
        thoraxNode.position = SCNVector3(0, 0, 0)
        thorax.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.05, 
            speciesModifier: 0.9,
            baseColor: NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        )
        parentNode.addChildNode(thoraxNode)
        
        // 3. NARROW WAIST: Characteristic wasp waist
        let waist = SCNCylinder(radius: CGFloat(size * 0.15), height: CGFloat(size * 0.3))
        let waistNode = SCNNode(geometry: waist)
        waistNode.position = SCNVector3(0, -size * 0.6, 0)
        waist.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.05, 
            speciesModifier: 0.7,
            baseColor: NSColor(red: 0.6, green: 0.08, blue: 0.08, alpha: 1.0)
        )
        parentNode.addChildNode(waistNode)
        
        // 4. ABDOMEN: Pointed abdomen
        let abdomen = SCNSphere(radius: CGFloat(size * 0.4))
        let abdomenNode = SCNNode(geometry: abdomen)
        abdomenNode.scale = SCNVector3(0.8, 1.4, 0.8)  // Elongated and pointed
        abdomenNode.position = SCNVector3(0, -size * 1.1, 0)
        abdomen.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.05, 
            speciesModifier: 0.8,
            baseColor: NSColor(red: 0.7, green: 0.05, blue: 0.05, alpha: 1.0)
        )
        parentNode.addChildNode(abdomenNode)
        
        // 5. LARGE COMPOUND EYES
        for i in 0..<2 {
            let eye = SCNSphere(radius: CGFloat(size * 0.12))
            let eyeNode = SCNNode(geometry: eye)
            let xOffset = i == 0 ? -size * 0.15 : size * 0.15
            eyeNode.position = SCNVector3(xOffset, size * 1.0, size * 0.2)
            eye.firstMaterial?.diffuse.contents = NSColor.black
            parentNode.addChildNode(eyeNode)
        }
        
        // 6. POWERFUL FRONT LEGS (raptorial legs like mantis)
        for i in 0..<2 {
            let frontLeg = SCNBox(
                width: CGFloat(size * 0.08), 
                height: CGFloat(size * 0.6), 
                length: CGFloat(size * 0.06), 
                chamferRadius: 0
            )
            let frontLegNode = SCNNode(geometry: frontLeg)
            let xOffset = i == 0 ? -size * 0.4 : size * 0.4
            frontLegNode.position = SCNVector3(xOffset, size * 0.2, size * 0.3)
            frontLegNode.eulerAngles = SCNVector3(Float.pi * 0.3, 0, 0)
            frontLeg.firstMaterial?.diffuse.contents = NSColor.darkGray
            parentNode.addChildNode(frontLegNode)
        }
        
        // 7. REGULAR LEGS: Four additional legs
        for i in 0..<4 {
            let leg = SCNCylinder(radius: CGFloat(size * 0.03), height: CGFloat(size * 0.4))
            let legNode = SCNNode(geometry: leg)
            
            let angle = Float(i) * Float.pi / 2.0 + Float.pi / 4.0
            let legX = cos(angle) * size * 0.5
            let legZ = sin(angle) * size * 0.5
            
            legNode.position = SCNVector3(legX, -size * 0.2, legZ)
            legNode.eulerAngles = SCNVector3(Float.pi * 0.5, angle, 0)
            leg.firstMaterial?.diffuse.contents = NSColor.darkGray
            parentNode.addChildNode(legNode)
        }
    }
    
    // 🐜 Omnivore: Ant/Bee-inspired segmented geometry  
    private func createOmnivoreGeometry(bug: Bug, size: Float) -> SCNGeometry {
        // Create segmented body (like ant thorax)
        let body = SCNCapsule(capRadius: CGFloat(size * 0.5), height: CGFloat(size * 1.6))
        body.heightSegmentCount = 8  // Visible segmentation
        body.radialSegmentCount = 12
        
        // Warm, industrious colors with genetic expression
        body.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.15, 
            speciesModifier: 0.6,
                baseColor: NSColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
            )
        
        return body
    }
    
    // 🐜 Detailed Omnivore Body: Ant/Bee-inspired segmented geometry
    private func createDetailedOmnivoreBody(bug: Bug, size: Float, parentNode: SCNNode) {
        // 1. HEAD: Rounded head with mandibles
        let head = SCNSphere(radius: CGFloat(size * 0.35))
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, size * 0.8, 0)
        head.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.15, 
            speciesModifier: 0.6,
            baseColor: NSColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
        )
        parentNode.addChildNode(headNode)
        
        // 2. THORAX: Segmented thorax
        let thorax = SCNCapsule(capRadius: CGFloat(size * 0.4), height: CGFloat(size * 0.8))
        let thoraxNode = SCNNode(geometry: thorax)
        thoraxNode.position = SCNVector3(0, 0, 0)
        thorax.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.15, 
            speciesModifier: 0.6,
            baseColor: NSColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
        )
        parentNode.addChildNode(thoraxNode)
        
        // 3. NARROW CONNECTOR: Petiole (ant waist)
        let connector = SCNCylinder(radius: CGFloat(size * 0.1), height: CGFloat(size * 0.2))
        let connectorNode = SCNNode(geometry: connector)
        connectorNode.position = SCNVector3(0, -size * 0.6, 0)
        connector.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.15, 
            speciesModifier: 0.4,
            baseColor: NSColor(red: 0.7, green: 0.4, blue: 0.08, alpha: 1.0)
        )
        parentNode.addChildNode(connectorNode)
        
        // 4. ABDOMEN: Large segmented abdomen
        let abdomen = SCNSphere(radius: CGFloat(size * 0.5))
        let abdomenNode = SCNNode(geometry: abdomen)
        abdomenNode.scale = SCNVector3(1.0, 1.3, 1.0)
        abdomenNode.position = SCNVector3(0, -size * 1.0, 0)
        abdomen.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.15, 
            speciesModifier: 0.5,
            baseColor: NSColor(red: 0.8, green: 0.45, blue: 0.09, alpha: 1.0)
        )
        parentNode.addChildNode(abdomenNode)
        
        // 5. ANTENNAE: Bent antennae
        for i in 0..<2 {
            let antenna = SCNCylinder(radius: CGFloat(size * 0.04), height: CGFloat(size * 0.5))
            let antennaNode = SCNNode(geometry: antenna)
            let xOffset = i == 0 ? -size * 0.2 : size * 0.2
            antennaNode.position = SCNVector3(xOffset, size * 1.0, size * 0.1)
            antennaNode.eulerAngles = SCNVector3(Float.pi * 0.4, 0, 0)
            antenna.firstMaterial?.diffuse.contents = NSColor.darkGray
            parentNode.addChildNode(antennaNode)
        }
        
        // 6. SIX LEGS: Standard insect legs
        for i in 0..<6 {
            let leg = SCNCylinder(radius: CGFloat(size * 0.03), height: CGFloat(size * 0.4))
            let legNode = SCNNode(geometry: leg)
            
            let angle = Float(i) * Float.pi / 3.0
            let legX = cos(angle) * size * 0.5
            let legZ = sin(angle) * size * 0.5
            
            legNode.position = SCNVector3(legX, -size * 0.1, legZ)
            legNode.eulerAngles = SCNVector3(Float.pi * 0.5, angle, 0)
            leg.firstMaterial?.diffuse.contents = NSColor.darkGray
            parentNode.addChildNode(legNode)
        }
    }
    
    // 🪰 Scavenger: Fly-inspired opportunistic geometry
    private func createScavengerGeometry(bug: Bug, size: Float) -> SCNGeometry {
        // Create rounded, compact body
        let body = SCNCylinder(radius: CGFloat(size * 0.7), height: CGFloat(size * 0.9))
        body.radialSegmentCount = 10
        body.heightSegmentCount = 6
        
        // Iridescent, opportunistic colors with genetic variation
        body.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.75, 
            speciesModifier: 0.8,
                baseColor: NSColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0)
            )
        
        return body
    }
    
    // 🪰 Detailed Scavenger Body: Fly-inspired compact geometry
    private func createDetailedScavengerBody(bug: Bug, size: Float, parentNode: SCNNode) {
        // 1. LARGE HEAD: Big head with compound eyes (like fly)
        let head = SCNSphere(radius: CGFloat(size * 0.4))
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, size * 0.6, 0)
        head.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.75, 
            speciesModifier: 0.8,
            baseColor: NSColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0)
        )
        parentNode.addChildNode(headNode)
        
        // 2. COMPACT THORAX: Short, robust thorax
        let thorax = SCNCylinder(radius: CGFloat(size * 0.45), height: CGFloat(size * 0.6))
        let thoraxNode = SCNNode(geometry: thorax)
        thoraxNode.position = SCNVector3(0, 0, 0)
        thorax.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.75, 
            speciesModifier: 0.8,
            baseColor: NSColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0)
        )
        parentNode.addChildNode(thoraxNode)
        
        // 3. BULBOUS ABDOMEN: Large rounded abdomen
        let abdomen = SCNSphere(radius: CGFloat(size * 0.5))
        let abdomenNode = SCNNode(geometry: abdomen)
        abdomenNode.scale = SCNVector3(1.1, 1.2, 1.1)
        abdomenNode.position = SCNVector3(0, -size * 0.7, 0)
        abdomen.firstMaterial = createGeneticVanGoghMaterial(
            for: bug, 
            baseHue: 0.75, 
            speciesModifier: 0.7,
            baseColor: NSColor(red: 0.4, green: 0.15, blue: 0.7, alpha: 1.0)
        )
        parentNode.addChildNode(abdomenNode)
        
        // 4. LARGE COMPOUND EYES: Prominent eyes
        for i in 0..<2 {
            let eye = SCNSphere(radius: CGFloat(size * 0.15))
            let eyeNode = SCNNode(geometry: eye)
            let xOffset = i == 0 ? -size * 0.25 : size * 0.25
            eyeNode.position = SCNVector3(xOffset, size * 0.7, size * 0.3)
            eye.firstMaterial?.diffuse.contents = NSColor.black
            eye.firstMaterial?.specular.contents = NSColor.white
            parentNode.addChildNode(eyeNode)
        }
        
        // 5. SHORT ANTENNAE: Stubby fly antennae
        for i in 0..<2 {
            let antenna = SCNCylinder(radius: CGFloat(size * 0.03), height: CGFloat(size * 0.2))
            let antennaNode = SCNNode(geometry: antenna)
            let xOffset = i == 0 ? -size * 0.15 : size * 0.15
            antennaNode.position = SCNVector3(xOffset, size * 0.9, size * 0.2)
            antenna.firstMaterial?.diffuse.contents = NSColor.darkGray
            parentNode.addChildNode(antennaNode)
        }
        
        // 6. SIX LEGS: Stocky scavenger legs
        for i in 0..<6 {
            let leg = SCNCylinder(radius: CGFloat(size * 0.04), height: CGFloat(size * 0.3))
            let legNode = SCNNode(geometry: leg)
            
            let angle = Float(i) * Float.pi / 3.0
            let legX = cos(angle) * size * 0.6
            let legZ = sin(angle) * size * 0.6
            
            legNode.position = SCNVector3(legX, -size * 0.2, legZ)
            legNode.eulerAngles = SCNVector3(Float.pi * 0.5, angle, 0)
            leg.firstMaterial?.diffuse.contents = NSColor.darkGray
            parentNode.addChildNode(legNode)
        }
    }
    
    // 🧬 PHASE 3: Genetic Visual Expression Material System
    private func createGeneticVanGoghMaterial(for bug: Bug, baseHue: Double, speciesModifier: Double, baseColor: NSColor) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Genetic color expression: DNA determines final appearance
        let geneticColor = createGeneticExpressedColor(bug: bug, baseHue: baseHue, speciesModifier: speciesModifier)
        
        // Van Gogh artistic styling combined with genetic traits
        let expressiveColor = createVanGoghGeneticColor(
            species: bug.dna.speciesTraits.speciesType, 
            bug: bug, 
            geneticColor: geneticColor,
            baseColor: baseColor
        )
        
        // Apply genetic traits to material properties
        material.diffuse.contents = expressiveColor
        
        // Genetic size affects material properties
        let sizeEffect = Float(bug.dna.size)
        material.roughness.contents = NSNumber(value: 0.3 + (1.0 - sizeEffect) * 0.4) // Smaller bugs are rougher
        
        // Camouflage affects transparency and iridescence
        let camouflage = Float(bug.dna.camouflage)
        material.transparency = CGFloat(0.95 + camouflage * 0.05) // High camouflage = slight transparency
        
        // Age affects material weathering
        let ageEffect = min(1.0, Float(bug.age) / Float(Bug.maxAge))
        material.metalness.contents = NSNumber(value: camouflage * 0.2 + ageEffect * 0.3) // Older bugs get more metallic
        
        // Health affects brightness
        let healthRatio = Float(bug.energy / Bug.maxEnergy)
        let brightness = 0.7 + healthRatio * 0.3
        material.emission.contents = NSColor(white: CGFloat(brightness * 0.1), alpha: 1.0) // Healthy bugs glow slightly
        
        return material
    }
    
    // 🧬 Genetic Color Expression Functions
    private func createGeneticExpressedColor(bug: Bug, baseHue: Double, speciesModifier: Double) -> NSColor {
        // Combine individual DNA color with species tendency
        let individualHue = bug.dna.colorHue
        let blendedHue = (individualHue * 0.7 + baseHue * 0.3).truncatingRemainder(dividingBy: 1.0)
        
        // Genetic traits affect saturation and brightness
        let geneticSaturation = bug.dna.colorSaturation * (0.8 + bug.dna.aggression * 0.2) // Aggressive bugs are more saturated
        let geneticBrightness = bug.dna.colorBrightness * (0.7 + bug.energy / Bug.maxEnergy * 0.3) // Healthy bugs are brighter
        
        return NSColor(
            hue: CGFloat(blendedHue),
            saturation: CGFloat(geneticSaturation),
            brightness: CGFloat(geneticBrightness),
            alpha: 1.0
        )
    }
    
    private func createVanGoghGeneticColor(species: SpeciesType, bug: Bug, geneticColor: NSColor, baseColor: NSColor) -> NSColor {
        // Blend genetic expression with Van Gogh artistic style
        let geneticRGB = geneticColor.rgbComponents
        let baseRGB = baseColor.rgbComponents
        
        // Species personality affects the blend ratio
        let speciesStrength: Double
        switch species {
        case .herbivore:
            speciesStrength = 0.3 // Gentle, individual expression dominates
        case .carnivore:
            speciesStrength = 0.7 // Strong species identity
        case .omnivore:
            speciesStrength = 0.5 // Balanced
        case .scavenger:
            speciesStrength = 0.4 // Opportunistic, varied appearance
        }
        
        return NSColor(
            red: CGFloat(geneticRGB.red * (1.0 - speciesStrength) + baseRGB.red * speciesStrength),
            green: CGFloat(geneticRGB.green * (1.0 - speciesStrength) + baseRGB.green * speciesStrength),
            blue: CGFloat(geneticRGB.blue * (1.0 - speciesStrength) + baseRGB.blue * speciesStrength),
            alpha: 1.0
        )
    }
    
    // 🎨 Van Gogh Bug Material Creation (Legacy support)
    private func createVanGoghBugMaterial(species: SpeciesType, bug: Bug, baseColor: NSColor) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Create expressive, Van Gogh-inspired bug coloring
        let expressiveColor = createVanGoghBugColor(species: species, bug: bug, baseColor: baseColor)
        material.diffuse.contents = expressiveColor
        
        // Give bugs personality through material properties
        switch species {
        case .herbivore:
            material.metalness.contents = 0.0
            material.roughness.contents = 0.8    // Soft, organic feeling
            material.emission.contents = NSColor(red: 0.05, green: 0.15, blue: 0.05, alpha: 1.0)
            
        case .carnivore:
            material.metalness.contents = 0.2    // Slight menacing sheen
            material.roughness.contents = 0.3    // Smooth, predatory
            material.emission.contents = NSColor(red: 0.2, green: 0.02, blue: 0.02, alpha: 1.0)
            
        case .omnivore:
            material.metalness.contents = 0.1
            material.roughness.contents = 0.5    // Balanced texture
            material.emission.contents = NSColor(red: 0.15, green: 0.1, blue: 0.02, alpha: 1.0)
            
        case .scavenger:
            material.metalness.contents = 0.3    // Mysterious iridescence
            material.roughness.contents = 0.2    // Sleek appearance
            material.emission.contents = NSColor(red: 0.1, green: 0.05, blue: 0.15, alpha: 1.0)
        }
        
        return material
    }
    
    // 🎨 Van Gogh Bug Color with Personality
    private func createVanGoghBugColor(species: SpeciesType, bug: Bug, baseColor: NSColor) -> NSColor {
        // Add personality variation based on bug's unique ID and traits
        let bugVariation = Double(bug.id.hashValue % 1000) / 1000.0
        let energyInfluence = bug.energy / Bug.maxEnergy
        
        // Create expressive color variation like Van Gogh's paint dabs
        let variation = sin(bugVariation * .pi * 2) * 0.3
        let energy = energyInfluence * 0.2
        
        // Extract base color components
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        baseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Apply Van Gogh-style expressive modulation
        let expressiveRed = max(0, min(1, red + CGFloat(variation) + CGFloat(energy)))
        let expressiveGreen = max(0, min(1, green + CGFloat(variation * 0.7)))
        let expressiveBlue = max(0, min(1, blue + CGFloat(variation * 0.5)))
        
        return NSColor(
            red: expressiveRed,
            green: expressiveGreen,
            blue: expressiveBlue,
            alpha: alpha
        )
    }
    
    // 🦋 PHASE 3: ADVANCED PROCEDURAL WING SYSTEM
    private func addWings(to bugNode: SCNNode, bug: Bug) {
        guard bug.dna.wingSpan > 0.5 else { return } // Only bugs with significant wing span get wings
        
        let wingSize = Float(bug.dna.wingSpan * 0.6)
        let species = bug.dna.speciesTraits.speciesType
        
        // Create species-specific wing shapes
        let (leftWing, rightWing) = createSpeciesSpecificWings(for: species, bug: bug, wingSize: wingSize)
        
        // Position wings based on body size and species
        let wingOffset = wingSize * 0.8
        let leftWingNode = SCNNode(geometry: leftWing)
        let rightWingNode = SCNNode(geometry: rightWing)
        
        leftWingNode.position = SCNVector3(-wingOffset, 0, 0)
        rightWingNode.position = SCNVector3(wingOffset, 0, 0)
        
        // Set wing names for behavioral animation targeting
        leftWingNode.name = "LeftWing"
        rightWingNode.name = "RightWing"
        
        bugNode.addChildNode(leftWingNode)
        bugNode.addChildNode(rightWingNode)
        
        // Add procedural wing animation based on genetics and behavior
        addProceduralWingAnimation(to: leftWingNode, bug: bug, isLeftWing: true)
        addProceduralWingAnimation(to: rightWingNode, bug: bug, isLeftWing: false)
    }
    
    // 🎨 Species-Specific Wing Shapes
    private func createSpeciesSpecificWings(for species: SpeciesType, bug: Bug, wingSize: Float) -> (SCNGeometry, SCNGeometry) {
        let wingMaterial = createWingMaterial(for: bug)
        
        switch species {
        case .herbivore:
            // 🦋 Butterfly wings: Large, rounded, beautiful
            let wing = SCNPlane(width: CGFloat(wingSize * 1.2), height: CGFloat(wingSize * 0.8))
            wing.cornerRadius = CGFloat(wingSize * 0.3)
            wing.firstMaterial = wingMaterial
            return (wing, wing)
            
        case .carnivore:
            // 🦅 Wasp wings: Narrow, sharp, efficient
            let wing = SCNPlane(width: CGFloat(wingSize * 0.8), height: CGFloat(wingSize * 1.4))
            wing.cornerRadius = CGFloat(wingSize * 0.1)
            wing.firstMaterial = wingMaterial
            return (wing, wing)
            
        case .omnivore:
            // 🐝 Bee wings: Compact, functional, translucent
            let wing = SCNPlane(width: CGFloat(wingSize), height: CGFloat(wingSize))
            wing.cornerRadius = CGFloat(wingSize * 0.2)
            wing.firstMaterial = wingMaterial
            return (wing, wing)
            
        case .scavenger:
            // 🪰 Fly wings: Small, rapid-flutter design
            let wing = SCNPlane(width: CGFloat(wingSize * 0.6), height: CGFloat(wingSize * 0.9))
            wing.cornerRadius = CGFloat(wingSize * 0.4)
            wing.firstMaterial = wingMaterial
            return (wing, wing)
        }
    }
    
    // 🌈 Wing Material with Genetic Expression
    private func createWingMaterial(for bug: Bug) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Wing transparency based on genetics
        let baseTransparency = 0.3 + bug.dna.wingSpan * 0.4 // Larger wings more transparent
        material.transparency = baseTransparency
        
        // Wing color reflects genetics
        let wingColor = createGeneticExpressedColor(bug: bug, baseHue: 0.1, speciesModifier: 0.2)
        material.diffuse.contents = wingColor
        
        // Iridescence based on species and genetics
        let iridescence = Float(bug.dna.camouflage * 0.3 + bug.dna.colorSaturation * 0.2)
        material.metalness.contents = NSNumber(value: iridescence)
        material.roughness.contents = NSNumber(value: 0.1) // Wings are smooth
        
        // Age affects wing wear
        let ageEffect = Float(bug.age) / Float(Bug.maxAge)
        material.emission.contents = NSColor(white: CGFloat(0.1 - ageEffect * 0.05), alpha: 1.0)
        
        return material
    }
    
    // 🎭 Procedural Wing Animation System
    private func addProceduralWingAnimation(to wingNode: SCNNode, bug: Bug, isLeftWing: Bool) {
        // Base flap rate influenced by genetics
        let baseFlaps = 0.05 + bug.dna.speed * 0.1 // Faster bugs flap faster
        let aggressionBoost = bug.dna.aggression * 0.05 // Aggressive bugs flap more intensely
        let energyMultiplier = bug.energy / Bug.maxEnergy // Low energy = slower flapping
        
        let flapDuration = (baseFlaps + aggressionBoost) * energyMultiplier
        let flapIntensity = Float(0.2 + bug.dna.wingSpan * 0.4) // Larger wings = bigger movement
        
        // Species-specific flap patterns
        let flapPattern = createSpeciesFlappingPattern(
            species: bug.dna.speciesTraits.speciesType, 
            duration: flapDuration, 
            intensity: flapIntensity,
            isLeftWing: isLeftWing
        )
        
        // Behavioral modifiers affect wing animation
        addBehavioralWingModifiers(to: wingNode, bug: bug, basePattern: flapPattern)
    }
    
    // 🎪 Species-Specific Flapping Patterns
    private func createSpeciesFlappingPattern(species: SpeciesType, duration: Double, intensity: Float, isLeftWing: Bool) -> SCNAction {
        let direction: Float = isLeftWing ? 1.0 : -1.0
        
        switch species {
        case .herbivore:
            // 🦋 Butterfly: Graceful, slow, sweeping motions
            return SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * direction * 0.8), duration: duration * 2.0),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-intensity * direction * 1.6), duration: duration * 1.0),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * direction * 0.8), duration: duration * 2.0)
            ])
            
        case .carnivore:
            // 🦅 Wasp: Sharp, aggressive, rapid beats
            return SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * direction), duration: duration * 0.3),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-intensity * direction * 2.0), duration: duration * 0.4),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * direction), duration: duration * 0.3)
            ])
            
        case .omnivore:
            // 🐝 Bee: Efficient, steady, rhythmic
            return SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * direction * 0.6), duration: duration),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-intensity * direction * 1.2), duration: duration),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * direction * 0.6), duration: duration)
            ])
            
        case .scavenger:
            // 🪰 Fly: Very rapid, buzzing, erratic
            return SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * direction * 0.4), duration: duration * 0.1),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-intensity * direction * 0.8), duration: duration * 0.2),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * direction * 0.4), duration: duration * 0.1)
            ])
        }
    }
    
    // 🎭 Behavioral Wing Animation Modifiers
    private func addBehavioralWingModifiers(to wingNode: SCNNode, bug: Bug, basePattern: SCNAction) {
        var finalPattern = basePattern
        
        // Check current behavior state and modify wing animation accordingly
        if let decision = bug.lastDecision {
            if decision.fleeing > 0.7 {
                // PANIC FLAPPING: Faster, more erratic when fleeing
                finalPattern = basePattern
            } else if decision.hunting > 0.7 {
                // AGGRESSIVE FLAPPING: More intense when hunting
                finalPattern = basePattern
            } else if decision.social > 0.8 {
                // DISPLAY FLAPPING: Showy, rhythmic during social interactions
                finalPattern = basePattern
            } else if bug.energy < Bug.maxEnergy * 0.3 {
                // TIRED FLAPPING: Slower, weaker when low energy
                finalPattern = basePattern
            }
        }
        
        let repeatPattern = SCNAction.repeatForever(finalPattern)
        wingNode.runAction(repeatPattern)
    }
    
    // MARK: - 🎭 PHASE 3: BEHAVIORAL ANIMATION SYSTEM
    
    private func addBehavioralAnimations(to bugNode: SCNNode, bug: Bug) {
        // ✅ FIXED: Re-enable behavioral animations with reduced intensity to prevent jumping
        // Set up behavioral animation tracking
        bugNode.name = "Bug_\(bug.id.uuidString)"
        
        // Add subtle idle animation - breathing/pulsing (REDUCED INTENSITY)
        addIdleAnimation(to: bugNode, bug: bug)
        
        // Check current behavioral state and add appropriate animations (SELECTIVE)
        if let decision = bug.lastDecision {
            addBehaviorSpecificAnimations(to: bugNode, bug: bug, decision: decision)
        }
        
        // Add age-related animation effects (REDUCED INTENSITY)
        addAgeRelatedAnimations(to: bugNode, bug: bug)
    }
    
    // 🌊 Idle Breathing/Pulsing Animation
    private func addIdleAnimation(to bugNode: SCNNode, bug: Bug) {
        // 🔧 REDUCED INTENSITY: Subtle breathing effect - very slight scale pulsing
        let breathingRate = 3.0 + bug.dna.speed * 0.5 // Slower, more subtle breathing
        let breathingIntensity = 0.005 + bug.dna.size * 0.003 // Much smaller breathing intensity (was 0.02)
        
        let breatheIn = SCNAction.scale(by: 1.0 + breathingIntensity, duration: breathingRate)
        let breatheOut = SCNAction.scale(by: 1.0 - breathingIntensity, duration: breathingRate)
        
        let breathingCycle = SCNAction.sequence([breatheIn, breatheOut])
        let breathing = SCNAction.repeatForever(breathingCycle)
        
        bugNode.runAction(breathing, forKey: "breathing")
    }
    
    // 🎪 Behavior-Specific Animations
    private func addBehaviorSpecificAnimations(to bugNode: SCNNode, bug: Bug, decision: BugOutputs) {
        
        // 🏃 FLEEING ANIMATION - Panic response
        if decision.fleeing > 0.7 {
            addFleeingAnimation(to: bugNode, bug: bug, intensity: decision.fleeing)
        }
        
        // 🦁 HUNTING ANIMATION - Predatory stance
        else if decision.hunting > 0.7 {
            addHuntingAnimation(to: bugNode, bug: bug, intensity: decision.hunting)
        }
        
        // 💖 REPRODUCTION ANIMATION - Mating display
        else if decision.reproduction > 0.8 {
            addMatingAnimation(to: bugNode, bug: bug, intensity: decision.reproduction)
        }
        
        // 🤝 SOCIAL ANIMATION - Social display
        else if decision.social > 0.8 {
            addSocialAnimation(to: bugNode, bug: bug, intensity: decision.social)
        }
        
        // 😤 AGGRESSION ANIMATION - Aggressive posturing
        else if decision.aggression > 0.7 {
            addAggressionAnimation(to: bugNode, bug: bug, intensity: decision.aggression)
        }
        
        // 🔍 EXPLORATION ANIMATION - Curious movement
        else if decision.exploration > 0.8 {
            addExplorationAnimation(to: bugNode, bug: bug, intensity: decision.exploration)
        }
    }
    
    // 😨 Fleeing Animation - Erratic, fast movements
    private func addFleeingAnimation(to bugNode: SCNNode, bug: Bug, intensity: Double) {
        let panicShake = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.1), z: 0, duration: 0.05),
            SCNAction.rotateBy(x: 0, y: CGFloat(-intensity * 0.2), z: 0, duration: 0.1),
            SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.1), z: 0, duration: 0.05)
        ])
        
        let repeatPanic = SCNAction.repeatForever(panicShake)
        bugNode.runAction(repeatPanic, forKey: "fleeing")
        
        // Enhanced wing flapping for flying species
        if bug.canFly {
            enhanceWingAnimationForBehavior(bugNode: bugNode, behavior: "panic", multiplier: 3.0)
        }
    }
    
    // 🦁 Hunting Animation - Predatory crouch and pounce preparation
    private func addHuntingAnimation(to bugNode: SCNNode, bug: Bug, intensity: Double) {
        // 🔧 REDUCED INTENSITY: Much subtler predatory stance
        let crouch = SCNAction.scale(by: 0.98, duration: 1.0) // Was 0.8 - much too aggressive
        let rise = SCNAction.scale(by: 1.02, duration: 0.8)   // Was 1.25 - much too aggressive
        
        // Tension animation - very slight back-and-forth rocking
        let tense = SCNAction.sequence([
            SCNAction.rotateBy(x: CGFloat(intensity * 0.02), y: 0, z: 0, duration: 0.4), // Reduced from 0.05
            SCNAction.rotateBy(x: CGFloat(-intensity * 0.04), y: 0, z: 0, duration: 0.8), // Reduced from 0.1
            SCNAction.rotateBy(x: CGFloat(intensity * 0.02), y: 0, z: 0, duration: 0.4)  // Reduced from 0.05
        ])
        
        let huntingCycle = SCNAction.sequence([crouch, tense, rise])
        let hunting = SCNAction.repeatForever(huntingCycle)
        
        bugNode.runAction(hunting, forKey: "hunting")
        
        // Enhanced wing readiness for flying predators
        if bug.canFly {
            enhanceWingAnimationForBehavior(bugNode: bugNode, behavior: "hunt", multiplier: 1.2) // Reduced from 1.5
        }
    }
    
    // 💖 Mating Animation - Rhythmic display dance
    private func addMatingAnimation(to bugNode: SCNNode, bug: Bug, intensity: Double) {
        let species = bug.dna.speciesTraits.speciesType
        let matingDance = createSpeciesMatingDance(species: species, bug: bug, intensity: intensity)
        
        let mating = SCNAction.repeatForever(matingDance)
        bugNode.runAction(mating, forKey: "mating")
        
        // Show off wings if available
        if bug.canFly {
            enhanceWingAnimationForBehavior(bugNode: bugNode, behavior: "display", multiplier: 0.5) // Slower, showier
        }
    }
    
    // 🎪 Species-Specific Mating Dances
    private func createSpeciesMatingDance(species: SpeciesType, bug: Bug, intensity: Double) -> SCNAction {
        switch species {
        case .herbivore:
            // 🦋 Butterfly courtship: Spiraling flight pattern simulation
            return SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.5), z: 0, duration: 1.0),
                SCNAction.scale(by: 1.1, duration: 0.5),
                SCNAction.scale(by: 0.9, duration: 0.5),
                SCNAction.rotateBy(x: 0, y: CGFloat(-intensity * 0.5), z: 0, duration: 1.0)
            ])
            
        case .carnivore:
            // 🦅 Aggressive display: Sharp, dominant movements
            return SCNAction.sequence([
                SCNAction.scale(by: 1.2, duration: 0.3),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * 0.3), duration: 0.2),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-intensity * 0.6), duration: 0.4),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * 0.3), duration: 0.2),
                SCNAction.scale(by: 0.83, duration: 0.3)
            ])
            
        case .omnivore:
            // 🐝 Bee waggle dance: Figure-eight pattern simulation
            return SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.2), z: 0, duration: 0.4),
                SCNAction.move(by: SCNVector3(Float(intensity), 0, 0), duration: 0.2),
                SCNAction.rotateBy(x: 0, y: CGFloat(-intensity * 0.4), z: 0, duration: 0.8),
                SCNAction.move(by: SCNVector3(-Float(intensity), 0, 0), duration: 0.2),
                SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.2), z: 0, duration: 0.4)
            ])
            
        case .scavenger:
            // 🪰 Erratic display: Quick, opportunistic movements
            return SCNAction.sequence([
                SCNAction.rotateBy(x: CGFloat(intensity * 0.1), y: CGFloat(intensity * 0.2), z: CGFloat(intensity * 0.1), duration: 0.1),
                SCNAction.scale(by: 1.05, duration: 0.1),
                SCNAction.scale(by: 0.95, duration: 0.1),
                SCNAction.rotateBy(x: CGFloat(-intensity * 0.1), y: CGFloat(-intensity * 0.2), z: CGFloat(-intensity * 0.1), duration: 0.1)
            ])
        }
    }
    
    // 🤝 Social Animation - Friendly, open posture
    private func addSocialAnimation(to bugNode: SCNNode, bug: Bug, intensity: Double) {
        // Gentle swaying motion
        let sway = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.1), z: 0, duration: 1.5),
            SCNAction.rotateBy(x: 0, y: CGFloat(-intensity * 0.2), z: 0, duration: 3.0),
            SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.1), z: 0, duration: 1.5)
        ])
        
        let social = SCNAction.repeatForever(sway)
        bugNode.runAction(social, forKey: "social")
    }
    
    // 😤 Aggression Animation - Threatening posture
    private func addAggressionAnimation(to bugNode: SCNNode, bug: Bug, intensity: Double) {
        // Puffing up and angular movements
        let puffUp = SCNAction.scale(by: 1.0 + intensity * 0.1, duration: 0.3)
        let deflate = SCNAction.scale(by: 1.0 - intensity * 0.05, duration: 0.2)
        
        let threat = SCNAction.sequence([
            puffUp,
            SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * 0.2), duration: 0.1),
            SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-intensity * 0.4), duration: 0.2),
            SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(intensity * 0.2), duration: 0.1),
            deflate
        ])
        
        let aggression = SCNAction.repeatForever(threat)
        bugNode.runAction(aggression, forKey: "aggression")
    }
    
    // 🔍 Exploration Animation - Curious, searching movements
    private func addExplorationAnimation(to bugNode: SCNNode, bug: Bug, intensity: Double) {
        // Head-turning motion simulating looking around
        let lookAround = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.3), z: 0, duration: 0.8),
            SCNAction.wait(duration: 0.2),
            SCNAction.rotateBy(x: 0, y: CGFloat(-intensity * 0.6), z: 0, duration: 1.6),
            SCNAction.wait(duration: 0.2),
            SCNAction.rotateBy(x: 0, y: CGFloat(intensity * 0.3), z: 0, duration: 0.8),
            SCNAction.wait(duration: 0.4)
        ])
        
        let exploration = SCNAction.repeatForever(lookAround)
        bugNode.runAction(exploration, forKey: "exploration")
    }
    
    // 🕰️ Age-Related Animations
    private func addAgeRelatedAnimations(to bugNode: SCNNode, bug: Bug) {
        let ageRatio = Double(bug.age) / Double(Bug.maxAge)
        
        if ageRatio > 0.7 {
            // Old bugs move more slowly and stiffly
            let tremor = SCNAction.sequence([
                SCNAction.rotateBy(x: CGFloat(ageRatio * 0.02), y: 0, z: 0, duration: 0.2),
                SCNAction.rotateBy(x: CGFloat(-ageRatio * 0.04), y: 0, z: 0, duration: 0.4),
                SCNAction.rotateBy(x: CGFloat(ageRatio * 0.02), y: 0, z: 0, duration: 0.2)
            ])
            
            let oldAge = SCNAction.repeatForever(tremor)
            bugNode.runAction(oldAge, forKey: "aging")
        }
    }
    
    // ✨ Wing Animation Enhancement for Behaviors
    private func enhanceWingAnimationForBehavior(bugNode: SCNNode, behavior: String, multiplier: Double) {
        // Find wing nodes and modify their animation speed
        if let leftWing = bugNode.childNode(withName: "LeftWing", recursively: true),
           let rightWing = bugNode.childNode(withName: "RightWing", recursively: true) {
            
            // Remove existing animation
            leftWing.removeAllActions()
            rightWing.removeAllActions()
            
            // Add enhanced animation based on behavior
            // This would need access to the original wing animation - simplified for now
            let enhancedFlap = SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(0.3 * multiplier), duration: 0.1 / multiplier),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-0.6 * multiplier), duration: 0.2 / multiplier),
                SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(0.3 * multiplier), duration: 0.1 / multiplier)
            ])
            
            let repeatEnhanced = SCNAction.repeatForever(enhancedFlap)
            leftWing.runAction(repeatEnhanced)
            rightWing.runAction(repeatEnhanced)
        }
    }
    
    private func addFins(to bugNode: SCNNode, bug: Bug) {
        let finSize = Float(bug.dna.divingDepth * 0.1)
        
        let fin = SCNBox(width: CGFloat(finSize), height: 0.05, length: CGFloat(finSize * 0.8), chamferRadius: 0.02)
        fin.firstMaterial?.diffuse.contents = NSColor.cyan
        
        let finNode = SCNNode(geometry: fin)
        finNode.position = SCNVector3(0, -finSize * 0.5, finSize * 0.5)
        bugNode.addChildNode(finNode)
    }
    
    private func addClimbingGear(to bugNode: SCNNode, bug: Bug) {
        let gripSize = Float(bug.dna.climbingGrip * 0.05)
        
        for i in 0..<4 {
            let grip = SCNSphere(radius: CGFloat(gripSize))
            grip.firstMaterial?.diffuse.contents = NSColor.brown
            
            let gripNode = SCNNode(geometry: grip)
            let angle = Float(i) * Float.pi * 0.5
            gripNode.position = SCNVector3(
                cos(angle) * gripSize * 3,
                -gripSize,
                sin(angle) * gripSize * 3
            )
            bugNode.addChildNode(gripNode)
        }
    }
    
    // 🌟 PHASE 3: ADVANCED HEALTH & AGE VISUAL INDICATORS
    
    private func addAdvancedHealthIndicators(to bugNode: SCNNode, bug: Bug) {
        // Multi-layered health visualization system
        addEnergyBar(to: bugNode, bug: bug)
        addAgeIndicator(to: bugNode, bug: bug)
        addHealthEffects(to: bugNode, bug: bug)
        addSpeciesStatusIndicator(to: bugNode, bug: bug)
    }
    
    // ⚡ Enhanced Energy Bar with Health Context
    private func addEnergyBar(to bugNode: SCNNode, bug: Bug) {
        let energyRatio = bug.energy / Bug.maxEnergy
        let ageRatio = Double(bug.age) / Double(Bug.maxAge)
        
        // Energy bar size affected by age
        let barHeight = CGFloat(energyRatio * 5.0 * (1.0 - ageRatio * 0.3)) // Older bugs have smaller max energy display
        let energyBar = SCNBox(width: 0.12, height: barHeight, length: 0.12, chamferRadius: 0.03)
        
        // Dynamic energy color with age consideration
        let energyColor = getHealthColor(energy: energyRatio, age: ageRatio)
        
        energyBar.firstMaterial?.diffuse.contents = energyColor
        energyBar.firstMaterial?.emission.contents = energyColor
        
        // Add pulse effect for very low or high energy
        let energyNode = SCNNode(geometry: energyBar)
        energyNode.position = SCNVector3(0, 3.5, 0)
        energyNode.name = "EnergyBar"
        
        // 🔧 CONTINENTAL WORLD FIX: Disable pulse animations to prevent jumping appearance
        // Pulse when critically low energy (DISABLED to prevent visual jumping)
        if false && energyRatio < 0.2 {
            let pulse = SCNAction.sequence([
                SCNAction.scale(by: 1.3, duration: 0.3),
                SCNAction.scale(by: 0.7, duration: 0.3)
            ])
            let warning = SCNAction.repeatForever(pulse)
            energyNode.runAction(warning, forKey: "lowEnergyWarning")
        }
        
        bugNode.addChildNode(energyNode)
    }
    
    // 🕰️ Age Indicator Ring
    private func addAgeIndicator(to bugNode: SCNNode, bug: Bug) {
        let ageRatio = Double(bug.age) / Double(Bug.maxAge)
        
        // Age ring that fills up as bug gets older
        let ageRing = SCNTorus(ringRadius: 0.8, pipeRadius: 0.05)
        
        // Age color progression: young (blue) -> mature (green) -> old (orange) -> ancient (red)
        let ageColor = getAgeColor(ageRatio: ageRatio)
        
        ageRing.firstMaterial?.diffuse.contents = ageColor
        ageRing.firstMaterial?.transparency = 0.3 + ageRatio * 0.4 // More visible as they age
        
        let ageNode = SCNNode(geometry: ageRing)
        ageNode.position = SCNVector3(0, 0.2, 0)
        ageNode.name = "AgeRing"
        
        // 🔧 CONTINENTAL WORLD FIX: Disable age rotation to prevent visual jumping
        // Gentle rotation to show life activity (DISABLED to prevent visual jumping)
        if false {
            let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(Double.pi * 2), z: 0, duration: 10.0 - ageRatio * 5.0) // Slower rotation as they age
            let ageAnimation = SCNAction.repeatForever(rotation)
            ageNode.runAction(ageAnimation, forKey: "ageRotation")
        }
        
        bugNode.addChildNode(ageNode)
    }
    
    // ❤️ Health Visual Effects
    private func addHealthEffects(to bugNode: SCNNode, bug: Bug) {
        let energyRatio = bug.energy / Bug.maxEnergy
        let ageRatio = Double(bug.age) / Double(Bug.maxAge)
        
        // Health particle effects
        if energyRatio > 0.8 && ageRatio < 0.3 {
            // Vibrant health sparkles for young, healthy bugs
            addHealthSparkles(to: bugNode, bug: bug)
        } else if energyRatio < 0.3 || ageRatio > 0.8 {
            // Decay effects for sick or very old bugs
            addDecayEffects(to: bugNode, bug: bug)
        }
        
        // Generation indicator for evolved bugs
        if bug.generation > 0 {
            addGenerationIndicator(to: bugNode, generation: bug.generation)
        }
    }
    
    // ✨ Health Sparkles for Vibrant Bugs
    private func addHealthSparkles(to bugNode: SCNNode, bug: Bug) {
        let sparkleSystem = SCNParticleSystem()
        sparkleSystem.particleImage = createSparkleParticleImage()
        sparkleSystem.birthRate = 5.0
        sparkleSystem.particleLifeSpan = 1.0
        sparkleSystem.particleSize = 0.3
        sparkleSystem.particleSizeVariation = 0.1
        sparkleSystem.particleVelocity = 2.0
        sparkleSystem.particleVelocityVariation = 1.0
        // sparkleSystem.emissionShape = SCNSphere(radius: 0.5) // Not available in SceneKit
        
        // Genetic color sparkles
        let sparkleColor = createGeneticExpressedColor(bug: bug, baseHue: 0.6, speciesModifier: 0.3)
        sparkleSystem.particleColor = sparkleColor
        
        let sparkleNode = SCNNode()
        sparkleNode.addParticleSystem(sparkleSystem)
        sparkleNode.position = SCNVector3(0, 1, 0)
        sparkleNode.name = "HealthSparkles"
        bugNode.addChildNode(sparkleNode)
    }
    
    // 💀 Decay Effects for Sick/Old Bugs
    private func addDecayEffects(to bugNode: SCNNode, bug: Bug) {
        let decaySystem = SCNParticleSystem()
        decaySystem.particleImage = createDecayParticleImage()
        decaySystem.birthRate = 2.0
        decaySystem.particleLifeSpan = 2.0
        decaySystem.particleSize = 0.2
        decaySystem.particleVelocity = 0.5
        decaySystem.particleVelocityVariation = 0.3
        decaySystem.particleColor = NSColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 0.6)
        
        let decayNode = SCNNode()
        decayNode.addParticleSystem(decaySystem)
        decayNode.position = SCNVector3(0, 0.5, 0)
        decayNode.name = "DecayEffects"
        bugNode.addChildNode(decayNode)
    }
    
    // 🏆 Generation Indicator Badge
    private func addGenerationIndicator(to bugNode: SCNNode, generation: Int) {
        let badge = SCNSphere(radius: 0.15)
        
        // Color badge based on generation advancement
        let generationHue = min(1.0, Double(generation) * 0.1) // Evolves through spectrum
        let badgeColor = NSColor(hue: CGFloat(generationHue), saturation: 0.8, brightness: 0.9, alpha: 0.8)
        
        badge.firstMaterial?.diffuse.contents = badgeColor
        badge.firstMaterial?.emission.contents = badgeColor
        
        let badgeNode = SCNNode(geometry: badge)
        badgeNode.position = SCNVector3(1.2, 2, 0)
        badgeNode.name = "GenerationBadge"
        
        // Generation text would be complex - for now show evolution through color and size
        let generationSize = 1.0 + min(Double(generation) * 0.1, 0.5)
        badgeNode.scale = SCNVector3(generationSize, generationSize, generationSize)
        
        bugNode.addChildNode(badgeNode)
    }
    
    // 🏷️ Species Status Indicator
    private func addSpeciesStatusIndicator(to bugNode: SCNNode, bug: Bug) {
        // Small indicator showing species and key genetic traits
        let statusRing = SCNTorus(ringRadius: 0.3, pipeRadius: 0.02)
        
        // Color based on species with genetic modification
        let speciesColor = createGeneticExpressedColor(bug: bug, baseHue: 0.0, speciesModifier: 1.0)
        statusRing.firstMaterial?.diffuse.contents = speciesColor
        statusRing.firstMaterial?.metalness.contents = NSNumber(value: bug.dna.camouflage)
        
        let statusNode = SCNNode(geometry: statusRing)
        statusNode.position = SCNVector3(0, -0.3, 0)
        statusNode.name = "SpeciesStatus"
        
        // Different rotation speeds for different species
        let rotationSpeed = bug.dna.speed * 2.0
        let statusRotation = SCNAction.rotateBy(x: 0, y: CGFloat(Double.pi * 2), z: 0, duration: 5.0 / rotationSpeed)
        let statusAnimation = SCNAction.repeatForever(statusRotation)
        statusNode.runAction(statusAnimation, forKey: "speciesRotation")
        
        bugNode.addChildNode(statusNode)
    }
    
    // 🎨 Color Helper Functions
    private func getHealthColor(energy: Double, age: Double) -> NSColor {
        // Health color affected by both energy and age
        let healthScore = energy * (1.0 - age * 0.3) // Age reduces perceived health
        
        if healthScore > 0.7 {
            return NSColor.green
        } else if healthScore > 0.4 {
            return NSColor.yellow
        } else if healthScore > 0.2 {
            return NSColor.orange
        } else {
            return NSColor.red
        }
    }
    
    private func getAgeColor(ageRatio: Double) -> NSColor {
        if ageRatio < 0.25 {
            // Young: Vibrant blue
            return NSColor(hue: 0.6, saturation: 0.8, brightness: 1.0, alpha: 1.0)
        } else if ageRatio < 0.5 {
            // Mature: Fresh green
            return NSColor(hue: 0.3, saturation: 0.8, brightness: 0.9, alpha: 1.0)
        } else if ageRatio < 0.75 {
            // Middle-aged: Warm orange
            return NSColor(hue: 0.1, saturation: 0.8, brightness: 0.8, alpha: 1.0)
        } else {
            // Old: Deep red
            return NSColor(hue: 0.0, saturation: 0.8, brightness: 0.7, alpha: 1.0)
        }
    }
    
    // 🎨 Particle Image Generators
    private func createSparkleParticleImage() -> NSImage {
        let size: CGFloat = 8
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor.white.setFill()
        let sparkle = NSBezierPath()
        
        // Create star shape
        sparkle.move(to: NSPoint(x: size/2, y: 0))
        sparkle.line(to: NSPoint(x: size*0.6, y: size*0.4))
        sparkle.line(to: NSPoint(x: size, y: size*0.4))
        sparkle.line(to: NSPoint(x: size*0.7, y: size*0.6))
        sparkle.line(to: NSPoint(x: size*0.8, y: size))
        sparkle.line(to: NSPoint(x: size/2, y: size*0.8))
        sparkle.line(to: NSPoint(x: size*0.2, y: size))
        sparkle.line(to: NSPoint(x: size*0.3, y: size*0.6))
        sparkle.line(to: NSPoint(x: 0, y: size*0.4))
        sparkle.line(to: NSPoint(x: size*0.4, y: size*0.4))
        sparkle.close()
        sparkle.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createDecayParticleImage() -> NSImage {
        let size: CGFloat = 6
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 0.8).setFill()
        let decay = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size-2, height: size-2))
        decay.fill()
        
        image.unlockFocus()
        return image
    }
    
    // Legacy energy indicator for compatibility
    private func addEnergyIndicator(to bugNode: SCNNode, energy: Double) {
        let energyBar = SCNBox(width: 0.1, height: CGFloat(energy / Bug.maxEnergy * 5.0), length: 0.1, chamferRadius: 0.02)
        
        let energyColor = energy > Bug.maxEnergy * 0.7 ? NSColor.green :
                         energy > Bug.maxEnergy * 0.3 ? NSColor.yellow : NSColor.red
        
        energyBar.firstMaterial?.diffuse.contents = energyColor
        energyBar.firstMaterial?.emission.contents = energyColor
        
        let energyNode = SCNNode(geometry: energyBar)
        energyNode.position = SCNVector3(0, 3, 0)
        bugNode.addChildNode(energyNode)
    }
    
    // MARK: - Territory Rendering
    
    private func renderTerritories(scene: SCNScene) {
        let territories3D = simulationEngine.territoryManager.territories3D
        // Rendering 3D Territories
        
        let territoryContainer = SCNNode()
        territoryContainer.name = "TerritoryContainer"
        scene.rootNode.addChildNode(territoryContainer)
        
        for territory in territories3D {
            let territoryNode = createTerritoryNode(territory: territory)
            territoryContainer.addChildNode(territoryNode)
        }
    }
    
    private func createTerritoryNode(territory: Territory3D) -> SCNNode {
        let territoryNode = SCNNode()
        territoryNode.name = "Territory_\(territory.id.uuidString)"
        
        // Create territory boundary visualization
        let bounds = territory.bounds3D
        let width = bounds.max.x - bounds.min.x
        let height = bounds.max.z - bounds.min.z
        let length = bounds.max.y - bounds.min.y
        
        // Territory boundary box (wireframe)
        let boundaryGeometry = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(length), chamferRadius: 0)
        boundaryGeometry.firstMaterial?.diffuse.contents = NSColor.clear
        boundaryGeometry.firstMaterial?.transparency = 0.1
        
        // Add wireframe effect
        let wireframe = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(length), chamferRadius: 0)
        wireframe.firstMaterial?.fillMode = .lines
        wireframe.firstMaterial?.diffuse.contents = getTerritoryColor(for: territory)
        
        let boundaryNode = SCNNode(geometry: wireframe)
        boundaryNode.position = SCNVector3(
            Float((bounds.min.x + bounds.max.x) / 2),
            Float((bounds.min.z + bounds.max.z) / 2),
            Float((bounds.min.y + bounds.max.y) / 2)
        )
        
        territoryNode.addChildNode(boundaryNode)
        
        // Add layer indicators
        for layer in TerrainLayer.allCases {
            if territory.layerQualities[layer] ?? 0 > 0.3 {
                let layerIndicator = createLayerIndicator(layer: layer, quality: territory.layerQualities[layer] ?? 0)
                layerIndicator.position = SCNVector3(
                    Float((bounds.min.x + bounds.max.x) / 2),
                    Float(layer.heightRange.lowerBound + (layer.heightRange.upperBound - layer.heightRange.lowerBound) / 2),
                    Float((bounds.min.y + bounds.max.y) / 2)
                )
                territoryNode.addChildNode(layerIndicator)
            }
        }
        
        return territoryNode
    }
    
    private func createLayerIndicator(layer: TerrainLayer, quality: Double) -> SCNNode {
        let indicator = SCNSphere(radius: CGFloat(quality * 5.0))
        indicator.firstMaterial?.diffuse.contents = getLayerColor(layer: layer, alpha: 0.3)
        indicator.firstMaterial?.transparency = 0.3
        
        return SCNNode(geometry: indicator)
    }
    
    private func getTerritoryColor(for territory: Territory3D) -> NSColor {
        // Color based on dominant layer
        switch territory.dominantLayer {
        case .underground: return NSColor.brown
        case .surface: return NSColor.green
        case .canopy: return NSColor.orange
        case .aerial: return NSColor.cyan
        }
    }
    
    // MARK: - Special Effects
    
    private func addTerrainEffects(node: SCNNode, terrain: TerrainType, layer: TerrainLayer) {
        switch terrain {
        case .water:
            addWaterEffects(to: node)
        case .wind:
            addWindEffects(to: node)
        case .food:
            addFoodEffects(to: node)
        case .ice:
            addIceEffects(to: node)
        default:
            break
        }
    }
    
    private func addWaterEffects(to node: SCNNode) {
        // Add ripple animation
        let rippleAnimation = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 1.0),
            SCNAction.scale(to: 0.9, duration: 1.0)
        ])
        node.runAction(SCNAction.repeatForever(rippleAnimation))
    }
    
    private func addWindEffects(to node: SCNNode) {
        // Add particle system for wind
        let particleSystem = SCNParticleSystem()
        // Create a simple white dot image for particles
        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: 4, height: 4)).fill()
        image.unlockFocus()
        particleSystem.particleImage = image
        particleSystem.birthRate = 50
        particleSystem.particleLifeSpan = 2.0
        particleSystem.particleVelocity = 20
        particleSystem.particleSize = 0.5
        particleSystem.particleColor = NSColor(white: 1.0, alpha: 0.3)
        
        node.addParticleSystem(particleSystem)
    }
    
    private func addFoodEffects(to node: SCNNode) {
        // Add glowing effect
        let glowAnimation = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.5, duration: 0.8),
            SCNAction.fadeOpacity(to: 1.0, duration: 0.8)
        ])
        node.runAction(SCNAction.repeatForever(glowAnimation))
    }
    
    private func addIceEffects(to node: SCNNode) {
        // Add crystalline sparkle
        let sparkleAnimation = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 0.1), z: 0, duration: 0.5),
            SCNAction.wait(duration: 2.0)
        ])
        node.runAction(SCNAction.repeatForever(sparkleAnimation))
    }
    
    private func addAtmosphericEffects(scene: SCNScene) {
        // Creating cinematic atmospheric effects
        
        // 🌫️ ENHANCED FOG: Layer-specific atmospheric density
        createLayeredFog(scene: scene)
        
        // ✨ MAGICAL PARTICLES: Multi-layer atmospheric systems
        createMagicalParticles(scene: scene)
        
        // 🌊 UNDERWATER CAUSTICS: Dynamic water light patterns
        createUnderwaterCaustics(scene: scene)
        
        // 🍃 AERIAL CURRENTS: Wind visualization in aerial zones
        createAerialWindCurrents(scene: scene)
        
        // 🔮 MYSTICAL AURA: Underground energy emanations
        createUndergroundMysticAura(scene: scene)
        
        // Cinematic atmosphere: particle systems active
    }
    
    private func createLayeredFog(scene: SCNScene) {
        // Sophisticated fog system with depth layers
        scene.fogStartDistance = 100
        scene.fogEndDistance = 600
        scene.fogColor = NSColor(red: 0.85, green: 0.9, blue: 0.95, alpha: 1.0)
        scene.fogDensityExponent = 1.8  // Realistic atmospheric falloff
    }
    
    private func createMagicalParticles(scene: SCNScene) {
        // Create the star particle image once
        let sparkleImage = createSparkleParticleImage()
        
        // SURFACE PARTICLES: Optimized dust motes and pollen
        let surfaceSystem = SCNParticleSystem()
        surfaceSystem.particleImage = sparkleImage
        surfaceSystem.birthRate = 30  // Reduced for performance
        surfaceSystem.particleLifeSpan = 8.0  // Shorter lifespan
        surfaceSystem.particleLifeSpanVariation = 2.0
        surfaceSystem.particleSize = 2.0
        surfaceSystem.particleSizeVariation = 0.5
        surfaceSystem.particleColor = NSColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 0.3)
        surfaceSystem.particleColorVariation = SCNVector4(0.1, 0.1, 0.05, 0.05)  // Reduced variation
        surfaceSystem.particleVelocity = 2.0
        surfaceSystem.particleVelocityVariation = 1.0
        
        let surfaceNode = SCNNode()
        surfaceNode.addParticleSystem(surfaceSystem)
        surfaceNode.position = SCNVector3(0, 30, 0)
        scene.rootNode.addChildNode(surfaceNode)
        
        // CANOPY PARTICLES: Optimized leaf fragments and light specks
        let canopySystem = SCNParticleSystem()
        canopySystem.particleImage = sparkleImage
        canopySystem.birthRate = 20  // Reduced for performance
        canopySystem.particleLifeSpan = 10.0  // Shorter lifespan
        canopySystem.particleSize = 1.5
        canopySystem.particleColor = NSColor(red: 0.4, green: 0.8, blue: 0.3, alpha: 0.4)
        canopySystem.particleVelocity = 1.0
        canopySystem.particleVelocityVariation = 0.5
        
        let canopyNode = SCNNode()
        canopyNode.addParticleSystem(canopySystem)
        canopyNode.position = SCNVector3(0, 60, 0)
        scene.rootNode.addChildNode(canopyNode)
    }
    
    private func createUnderwaterCaustics(scene: SCNScene) {
        let causticsSystem = SCNParticleSystem()
        causticsSystem.particleImage = createCausticParticleImage()
        causticsSystem.birthRate = 25
        causticsSystem.particleLifeSpan = 8.0
        causticsSystem.particleSize = 5.0
        causticsSystem.particleSizeVariation = 2.0
        causticsSystem.particleColor = NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.4)
        causticsSystem.particleVelocity = 0.8
        causticsSystem.particleVelocityVariation = 0.5
        
        let causticsNode = SCNNode()
        causticsNode.addParticleSystem(causticsSystem)
        causticsNode.position = SCNVector3(0, 20, 0)
        scene.rootNode.addChildNode(causticsNode)
    }
    
    private func createAerialWindCurrents(scene: SCNScene) {
        let windSystem = SCNParticleSystem()
        windSystem.particleImage = createWindParticleImage()
        windSystem.birthRate = 30
        windSystem.particleLifeSpan = 10.0
        windSystem.particleSize = 4.0
        windSystem.particleColor = NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.2)
        windSystem.particleVelocity = 6.0
        windSystem.particleVelocityVariation = 3.0
        
        let windNode = SCNNode()
        windNode.addParticleSystem(windSystem)
        windNode.position = SCNVector3(0, 100, 0)
        scene.rootNode.addChildNode(windNode)
    }
    
    private func createUndergroundMysticAura(scene: SCNScene) {
        let auraSystem = SCNParticleSystem()
        auraSystem.particleImage = createAuraParticleImage()
        auraSystem.birthRate = 20
        auraSystem.particleLifeSpan = 18.0
        auraSystem.particleSize = 3.5
        auraSystem.particleSizeVariation = 1.5
        auraSystem.particleColor = NSColor(red: 0.5, green: 0.2, blue: 0.9, alpha: 0.5)
        auraSystem.particleColorVariation = SCNVector4(0.3, 0.1, 0.2, 0.2)
        auraSystem.particleVelocity = 0.5
        auraSystem.particleVelocityVariation = 0.4
        
        let auraNode = SCNNode()
        auraNode.addParticleSystem(auraSystem)
        auraNode.position = SCNVector3(0, -20, 0)
        scene.rootNode.addChildNode(auraNode)
    }
    
    // MARK: - 🌍 PHASE 2: Enhanced Biome-Specific Atmospheric Effects
    
    private func addBiomeSpecificAtmosphericEffects(scene: SCNScene) {
        // Create biome-specific particle effects based on dominant biome
        let dominantBiome = getDominantBiome()
        
        switch dominantBiome {
        case .tundra:
            addTundraSnowEffects(scene: scene)
            addTundraAuroraEffects(scene: scene)
        case .borealForest:
            addBorealMistEffects(scene: scene)
            addBorealPineMotes(scene: scene)
        case .temperateForest:
            addTemperateForestLightRays(scene: scene)
            addTemperateForestLeafFall(scene: scene)
        case .temperateGrassland:
            addGrasslandWindWaves(scene: scene)
            addGrasslandPollenEffects(scene: scene)
        case .desert:
            addDesertHeatShimmer(scene: scene)
            addDesertSandstorm(scene: scene)
        case .savanna:
            addSavannaGrassSeeds(scene: scene)
            addSavannaDustDevils(scene: scene)
        case .tropicalRainforest:
            addRainforestMist(scene: scene)
            addRainforestDroplets(scene: scene)
        case .wetlands:
            addWetlandsFireflies(scene: scene)
            addWetlandsBubbles(scene: scene)
        case .alpine:
            addAlpineSnowfall(scene: scene)
            addAlpineWindGusts(scene: scene)
        case .coastal:
            addCoastalSeaSpray(scene: scene)
            addCoastalSeagullFeathers(scene: scene)
        }
    }
    
    // 🏔️ Tundra Effects - "Crystalline Majesty"
    private func addTundraSnowEffects(scene: SCNScene) {
        let snowSystem = SCNParticleSystem()
        snowSystem.particleImage = createSnowflakeParticleImage()
        snowSystem.birthRate = 40
        snowSystem.particleLifeSpan = 15.0
        snowSystem.particleSize = 3.0
        snowSystem.particleSizeVariation = 1.0
        snowSystem.particleColor = NSColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 0.8)
        snowSystem.particleColorVariation = SCNVector4(0.05, 0.05, 0.0, 0.1)
        snowSystem.particleVelocity = 1.5
        snowSystem.particleVelocityVariation = 0.8
        snowSystem.acceleration = SCNVector3(0, -2.0, 0)  // Gentle fall
        
        let snowNode = SCNNode()
        snowNode.addParticleSystem(snowSystem)
        snowNode.position = SCNVector3(0, 150, 0)
        snowNode.name = "TundraSnow"
        scene.rootNode.addChildNode(snowNode)
    }
    
    private func addTundraAuroraEffects(scene: SCNScene) {
        let auroraSystem = SCNParticleSystem()
        auroraSystem.particleImage = createAuroraParticleImage()
        auroraSystem.birthRate = 10
        auroraSystem.particleLifeSpan = 25.0
        auroraSystem.particleSize = 8.0
        auroraSystem.particleSizeVariation = 3.0
        auroraSystem.particleColor = NSColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 0.4)
        auroraSystem.particleColorVariation = SCNVector4(0.2, 0.3, 0.4, 0.2)
        auroraSystem.particleVelocity = 0.3
        
        let auroraNode = SCNNode()
        auroraNode.addParticleSystem(auroraSystem)
        auroraNode.position = SCNVector3(0, 180, 0)
        auroraNode.name = "TundraAurora"
        scene.rootNode.addChildNode(auroraNode)
    }
    
    // 🌲 Boreal Forest Effects - "Misty Cathedral"
    private func addBorealMistEffects(scene: SCNScene) {
        let mistSystem = SCNParticleSystem()
        mistSystem.particleImage = createMistParticleImage()
        mistSystem.birthRate = 25
        mistSystem.particleLifeSpan = 20.0
        mistSystem.particleSize = 6.0
        mistSystem.particleSizeVariation = 2.0
        mistSystem.particleColor = NSColor(red: 0.9, green: 0.95, blue: 0.98, alpha: 0.3)
        mistSystem.particleVelocity = 0.5
        mistSystem.particleVelocityVariation = 0.3
        
        let mistNode = SCNNode()
        mistNode.addParticleSystem(mistSystem)
        mistNode.position = SCNVector3(0, 40, 0)
        mistNode.name = "BorealMist"
        scene.rootNode.addChildNode(mistNode)
    }
    
    private func addBorealPineMotes(scene: SCNScene) {
        let moteSystem = SCNParticleSystem()
        moteSystem.particleImage = createPineMoteParticleImage()
        moteSystem.birthRate = 15
        moteSystem.particleLifeSpan = 12.0
        moteSystem.particleSize = 2.5
        moteSystem.particleColor = NSColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 0.6)
        moteSystem.particleVelocity = 1.0
        
        let moteNode = SCNNode()
        moteNode.addParticleSystem(moteSystem)
        moteNode.position = SCNVector3(0, 50, 0)
        moteNode.name = "BorealPineMotes"
        scene.rootNode.addChildNode(moteNode)
    }
    
    // 🌳 Temperate Forest Effects - "Living Symphony"
    private func addTemperateForestLightRays(scene: SCNScene) {
        let raySystem = SCNParticleSystem()
        raySystem.particleImage = createLightRayParticleImage()
        raySystem.birthRate = 8
        raySystem.particleLifeSpan = 30.0
        raySystem.particleSize = 12.0
        raySystem.particleSizeVariation = 4.0
        raySystem.particleColor = NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.2)
        raySystem.particleVelocity = 0.1
        
        let rayNode = SCNNode()
        rayNode.addParticleSystem(raySystem)
        rayNode.position = SCNVector3(0, 80, 0)
        rayNode.name = "TemperateForestLightRays"
        scene.rootNode.addChildNode(rayNode)
    }
    
    private func addTemperateForestLeafFall(scene: SCNScene) {
        let leafSystem = SCNParticleSystem()
        leafSystem.particleImage = createLeafParticleImage()
        leafSystem.birthRate = 20
        leafSystem.particleLifeSpan = 18.0
        leafSystem.particleSize = 4.0
        leafSystem.particleSizeVariation = 1.5
        leafSystem.particleColor = NSColor(red: 0.6, green: 0.8, blue: 0.3, alpha: 0.7)
        leafSystem.particleColorVariation = SCNVector4(0.3, 0.2, 0.2, 0.1)
        leafSystem.particleVelocity = 1.2
        leafSystem.acceleration = SCNVector3(0, -1.5, 0)
        
        let leafNode = SCNNode()
        leafNode.addParticleSystem(leafSystem)
        leafNode.position = SCNVector3(0, 70, 0)
        leafNode.name = "TemperateForestLeaves"
        scene.rootNode.addChildNode(leafNode)
    }
    
    // 🌾 Grassland Effects - "Windswept Freedom"
    private func addGrasslandWindWaves(scene: SCNScene) {
        let waveSystem = SCNParticleSystem()
        waveSystem.particleImage = createGrassWaveParticleImage()
        waveSystem.birthRate = 35
        waveSystem.particleLifeSpan = 8.0
        waveSystem.particleSize = 5.0
        waveSystem.particleColor = NSColor(red: 0.7, green: 0.9, blue: 0.4, alpha: 0.4)
        waveSystem.particleVelocity = 4.0
        waveSystem.particleVelocityVariation = 2.0
        
        let waveNode = SCNNode()
        waveNode.addParticleSystem(waveSystem)
        waveNode.position = SCNVector3(0, 25, 0)
        waveNode.name = "GrasslandWindWaves"
        scene.rootNode.addChildNode(waveNode)
    }
    
    private func addGrasslandPollenEffects(scene: SCNScene) {
        let pollenSystem = SCNParticleSystem()
        pollenSystem.particleImage = createPollenParticleImage()
        pollenSystem.birthRate = 50
        pollenSystem.particleLifeSpan = 10.0
        pollenSystem.particleSize = 1.5
        pollenSystem.particleColor = NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.5)
        pollenSystem.particleVelocity = 2.5
        pollenSystem.particleVelocityVariation = 1.5
        
        let pollenNode = SCNNode()
        pollenNode.addParticleSystem(pollenSystem)
        pollenNode.position = SCNVector3(0, 35, 0)
        pollenNode.name = "GrasslandPollen"
        scene.rootNode.addChildNode(pollenNode)
    }
    
    // 🏜️ Desert Effects - "Timeless Endurance"
    private func addDesertHeatShimmer(scene: SCNScene) {
        let shimmerSystem = SCNParticleSystem()
        shimmerSystem.particleImage = createHeatShimmerParticleImage()
        shimmerSystem.birthRate = 60
        shimmerSystem.particleLifeSpan = 4.0
        shimmerSystem.particleSize = 8.0
        shimmerSystem.particleSizeVariation = 3.0
        shimmerSystem.particleColor = NSColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 0.2)
        shimmerSystem.particleVelocity = 3.0
        shimmerSystem.acceleration = SCNVector3(0, 5.0, 0)  // Rising heat
        
        let shimmerNode = SCNNode()
        shimmerNode.addParticleSystem(shimmerSystem)
        shimmerNode.position = SCNVector3(0, 15, 0)
        shimmerNode.name = "DesertHeatShimmer"
        scene.rootNode.addChildNode(shimmerNode)
    }
    
    private func addDesertSandstorm(scene: SCNScene) {
        let sandSystem = SCNParticleSystem()
        sandSystem.particleImage = createSandParticleImage()
        sandSystem.birthRate = 30
        sandSystem.particleLifeSpan = 15.0
        sandSystem.particleSize = 3.0
        sandSystem.particleColor = NSColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.6)
        sandSystem.particleVelocity = 8.0
        sandSystem.particleVelocityVariation = 4.0
        
        let sandNode = SCNNode()
        sandNode.addParticleSystem(sandSystem)
        sandNode.position = SCNVector3(0, 30, 0)
        sandNode.name = "DesertSandstorm"
        scene.rootNode.addChildNode(sandNode)
    }
    
    // 🦒 Savanna Effects - "Epic Horizons"
    private func addSavannaGrassSeeds(scene: SCNScene) {
        let seedSystem = SCNParticleSystem()
        seedSystem.particleImage = createGrassSeedParticleImage()
        seedSystem.birthRate = 25
        seedSystem.particleLifeSpan = 12.0
        seedSystem.particleSize = 2.0
        seedSystem.particleColor = NSColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 0.7)
        seedSystem.particleVelocity = 3.0
        seedSystem.particleVelocityVariation = 2.0
        
        let seedNode = SCNNode()
        seedNode.addParticleSystem(seedSystem)
        seedNode.position = SCNVector3(0, 30, 0)
        seedNode.name = "SavannaGrassSeeds"
        scene.rootNode.addChildNode(seedNode)
    }
    
    private func addSavannaDustDevils(scene: SCNScene) {
        let dustSystem = SCNParticleSystem()
        dustSystem.particleImage = createDustDevilParticleImage()
        dustSystem.birthRate = 10
        dustSystem.particleLifeSpan = 20.0
        dustSystem.particleSize = 10.0
        dustSystem.particleSizeVariation = 5.0
        dustSystem.particleColor = NSColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 0.4)
        dustSystem.particleVelocity = 5.0
        dustSystem.particleVelocityVariation = 3.0
        
        let dustNode = SCNNode()
        dustNode.addParticleSystem(dustSystem)
        dustNode.position = SCNVector3(0, 25, 0)
        dustNode.name = "SavannaDustDevils"
        scene.rootNode.addChildNode(dustNode)
    }
    
    // 🌴 Tropical Rainforest Effects - "Emerald Cathedral"
    private func addRainforestMist(scene: SCNScene) {
        let mistSystem = SCNParticleSystem()
        mistSystem.particleImage = createTropicalMistParticleImage()
        mistSystem.birthRate = 40
        mistSystem.particleLifeSpan = 25.0
        mistSystem.particleSize = 7.0
        mistSystem.particleSizeVariation = 2.0
        mistSystem.particleColor = NSColor(red: 0.8, green: 0.95, blue: 0.85, alpha: 0.4)
        mistSystem.particleVelocity = 0.8
        mistSystem.particleVelocityVariation = 0.5
        
        let mistNode = SCNNode()
        mistNode.addParticleSystem(mistSystem)
        mistNode.position = SCNVector3(0, 50, 0)
        mistNode.name = "RainforestMist"
        scene.rootNode.addChildNode(mistNode)
    }
    
    private func addRainforestDroplets(scene: SCNScene) {
        let dropletSystem = SCNParticleSystem()
        dropletSystem.particleImage = createWaterDropletParticleImage()
        dropletSystem.birthRate = 35
        dropletSystem.particleLifeSpan = 8.0
        dropletSystem.particleSize = 2.5
        dropletSystem.particleColor = NSColor(red: 0.7, green: 0.9, blue: 0.95, alpha: 0.6)
        dropletSystem.particleVelocity = 2.0
        dropletSystem.acceleration = SCNVector3(0, -3.0, 0)
        
        let dropletNode = SCNNode()
        dropletNode.addParticleSystem(dropletSystem)
        dropletNode.position = SCNVector3(0, 80, 0)
        dropletNode.name = "RainforestDroplets"
        scene.rootNode.addChildNode(dropletNode)
    }
    
    // 🐸 Wetlands Effects - "Mirror of Life"
    private func addWetlandsFireflies(scene: SCNScene) {
        let fireflySystem = SCNParticleSystem()
        fireflySystem.particleImage = createFireflyParticleImage()
        fireflySystem.birthRate = 15
        fireflySystem.particleLifeSpan = 30.0
        fireflySystem.particleSize = 3.0
        fireflySystem.particleColor = NSColor(red: 1.0, green: 1.0, blue: 0.6, alpha: 0.8)
        fireflySystem.particleVelocity = 1.5
        fireflySystem.particleVelocityVariation = 1.0
        
        let fireflyNode = SCNNode()
        fireflyNode.addParticleSystem(fireflySystem)
        fireflyNode.position = SCNVector3(0, 35, 0)
        fireflyNode.name = "WetlandsFireflies"
        scene.rootNode.addChildNode(fireflyNode)
        
        // Add gentle pulsing animation for fireflies
        let pulseAnimation = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.3, duration: 2.0),
            SCNAction.fadeOpacity(to: 0.8, duration: 2.0)
        ])
        fireflyNode.runAction(SCNAction.repeatForever(pulseAnimation))
    }
    
    private func addWetlandsBubbles(scene: SCNScene) {
        let bubbleSystem = SCNParticleSystem()
        bubbleSystem.particleImage = createBubbleParticleImage()
        bubbleSystem.birthRate = 20
        bubbleSystem.particleLifeSpan = 15.0
        bubbleSystem.particleSize = 4.0
        bubbleSystem.particleSizeVariation = 2.0
        bubbleSystem.particleColor = NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.3)
        bubbleSystem.particleVelocity = 1.0
        bubbleSystem.acceleration = SCNVector3(0, 2.0, 0)  // Rising bubbles
        
        let bubbleNode = SCNNode()
        bubbleNode.addParticleSystem(bubbleSystem)
        bubbleNode.position = SCNVector3(0, 10, 0)
        bubbleNode.name = "WetlandsBubbles"
        scene.rootNode.addChildNode(bubbleNode)
    }
    
    // ⛰️ Alpine Effects - "Majestic Heights"
    private func addAlpineSnowfall(scene: SCNScene) {
        let snowSystem = SCNParticleSystem()
        snowSystem.particleImage = createAlpineSnowParticleImage()
        snowSystem.birthRate = 35
        snowSystem.particleLifeSpan = 20.0
        snowSystem.particleSize = 3.5
        snowSystem.particleSizeVariation = 1.0
        snowSystem.particleColor = NSColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 0.9)
        snowSystem.particleVelocity = 2.0
        snowSystem.acceleration = SCNVector3(0, -2.5, 0)
        
        let snowNode = SCNNode()
        snowNode.addParticleSystem(snowSystem)
        snowNode.position = SCNVector3(0, 120, 0)
        snowNode.name = "AlpineSnowfall"
        scene.rootNode.addChildNode(snowNode)
    }
    
    private func addAlpineWindGusts(scene: SCNScene) {
        let gustSystem = SCNParticleSystem()
        gustSystem.particleImage = createWindGustParticleImage()
        gustSystem.birthRate = 25
        gustSystem.particleLifeSpan = 8.0
        gustSystem.particleSize = 6.0
        gustSystem.particleColor = NSColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 0.3)
        gustSystem.particleVelocity = 10.0
        gustSystem.particleVelocityVariation = 5.0
        
        let gustNode = SCNNode()
        gustNode.addParticleSystem(gustSystem)
        gustNode.position = SCNVector3(0, 90, 0)
        gustNode.name = "AlpineWindGusts"
        scene.rootNode.addChildNode(gustNode)
    }
    
    // 🏖️ Coastal Effects - "Where Worlds Meet"
    private func addCoastalSeaSpray(scene: SCNScene) {
        let spraySystem = SCNParticleSystem()
        spraySystem.particleImage = createSeaSprayParticleImage()
        spraySystem.birthRate = 30
        spraySystem.particleLifeSpan = 12.0
        spraySystem.particleSize = 4.0
        spraySystem.particleSizeVariation = 2.0
        spraySystem.particleColor = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.5)
        spraySystem.particleVelocity = 3.0
        spraySystem.particleVelocityVariation = 2.0
        spraySystem.acceleration = SCNVector3(0, -1.0, 0)
        
        let sprayNode = SCNNode()
        sprayNode.addParticleSystem(spraySystem)
        sprayNode.position = SCNVector3(0, 25, 0)
        sprayNode.name = "CoastalSeaSpray"
        scene.rootNode.addChildNode(sprayNode)
    }
    
    private func addCoastalSeagullFeathers(scene: SCNScene) {
        let featherSystem = SCNParticleSystem()
        featherSystem.particleImage = createFeatherParticleImage()
        featherSystem.birthRate = 8
        featherSystem.particleLifeSpan = 25.0
        featherSystem.particleSize = 5.0
        featherSystem.particleSizeVariation = 2.0
        featherSystem.particleColor = NSColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 0.7)
        featherSystem.particleVelocity = 2.0
        featherSystem.acceleration = SCNVector3(0, -0.8, 0)
        
        let featherNode = SCNNode()
        featherNode.addParticleSystem(featherSystem)
        featherNode.position = SCNVector3(0, 100, 0)
        featherNode.name = "CoastalSeagullFeathers"
        scene.rootNode.addChildNode(featherNode)
    }
    
    // MARK: - 🌦️ PHASE 2: Weather-Specific Visual Effects
    
    private func addWeatherSpecificEffects(scene: SCNScene) {
        // Get current weather from simulation engine
        let currentWeather = simulationEngine.weatherManager.currentWeather
        let weatherIntensity = simulationEngine.weatherManager.weatherIntensity
        
        // Remove any existing weather effects first
        scene.rootNode.childNodes.filter { $0.name?.hasPrefix("Weather_") == true }.forEach { $0.removeFromParentNode() }
        
        switch currentWeather {
        case .rain:
            addRainEffects(scene: scene, intensity: weatherIntensity)
        case .blizzard:
            addBlizzardEffects(scene: scene, intensity: weatherIntensity)
        case .storm:
            addStormEffects(scene: scene, intensity: weatherIntensity)
        case .fog:
            addFogEffects(scene: scene, intensity: weatherIntensity)
        case .drought:
            addDroughtEffects(scene: scene, intensity: weatherIntensity)
        case .clear:
            addClearWeatherEffects(scene: scene)
        }
    }
    
    // 🌧️ Rain Effects
    private func addRainEffects(scene: SCNScene, intensity: Double) {
        let rainSystem = SCNParticleSystem()
        rainSystem.particleImage = createRainDropParticleImage()
        rainSystem.birthRate = CGFloat(100 * intensity)  // More intense = more rain
        rainSystem.particleLifeSpan = 3.0
        rainSystem.particleSize = 2.0
        rainSystem.particleSizeVariation = 0.5
        rainSystem.particleColor = NSColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 0.8)
        rainSystem.particleVelocity = CGFloat(15.0 + (10.0 * intensity))
        rainSystem.acceleration = SCNVector3(0, -20.0, 0)
        // Note: emissionOcclusionSpeedFactor not available in SceneKit
        rainSystem.particleAngleVariation = CGFloat(Double.pi / 6)
        
        let rainNode = SCNNode()
        rainNode.addParticleSystem(rainSystem)
        rainNode.position = SCNVector3(0, 200, 0)
        rainNode.name = "Weather_Rain"
        scene.rootNode.addChildNode(rainNode)
        
        // Add puddle effects on surface
        addPuddleEffects(scene: scene, intensity: intensity)
    }
    
    // ❄️ Blizzard Effects
    private func addBlizzardEffects(scene: SCNScene, intensity: Double) {
        let blizzardSystem = SCNParticleSystem()
        blizzardSystem.particleImage = createBlizzardSnowParticleImage()
        blizzardSystem.birthRate = CGFloat(80 * intensity)
        blizzardSystem.particleLifeSpan = 8.0
        blizzardSystem.particleSize = 4.0
        blizzardSystem.particleSizeVariation = 2.0
        blizzardSystem.particleColor = NSColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 0.9)
        blizzardSystem.particleVelocity = CGFloat(20.0 * intensity)
        blizzardSystem.particleVelocityVariation = CGFloat(10.0 * intensity)
        blizzardSystem.acceleration = SCNVector3(-5.0, -8.0, 0)  // Horizontal wind
        blizzardSystem.particleAngleVariation = CGFloat(Double.pi / 2)
        
        let blizzardNode = SCNNode()
        blizzardNode.addParticleSystem(blizzardSystem)
        blizzardNode.position = SCNVector3(0, 150, 0)
        blizzardNode.name = "Weather_Blizzard"
        scene.rootNode.addChildNode(blizzardNode)
        
        // Add wind gusts
        addWindGustEffects(scene: scene, intensity: intensity)
    }
    
    // ⛈️ Storm Effects
    private func addStormEffects(scene: SCNScene, intensity: Double) {
        // Heavy rain
        addRainEffects(scene: scene, intensity: intensity)
        
        // Lightning effects
        let lightningSystem = SCNParticleSystem()
        lightningSystem.particleImage = createLightningParticleImage()
        lightningSystem.birthRate = CGFloat(2 * intensity)
        lightningSystem.particleLifeSpan = 0.3
        lightningSystem.particleSize = 50.0
        lightningSystem.particleSizeVariation = 20.0
        lightningSystem.particleColor = NSColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.9)
        lightningSystem.particleVelocity = 0.0
        
        let lightningNode = SCNNode()
        lightningNode.addParticleSystem(lightningSystem)
        lightningNode.position = SCNVector3(0, 100, 0)
        lightningNode.name = "Weather_Lightning"
        scene.rootNode.addChildNode(lightningNode)
        
        // Dark storm clouds effect (enhanced fog)
        addStormCloudEffects(scene: scene, intensity: intensity)
    }
    
    // 🌫️ Fog Effects
    private func addFogEffects(scene: SCNScene, intensity: Double) {
        // Enhanced scene fog
        scene.fogStartDistance = CGFloat(50 - (30 * intensity))  // More intense = closer fog
        scene.fogEndDistance = CGFloat(200 - (100 * intensity))
        scene.fogColor = NSColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0)
        scene.fogDensityExponent = 2.0 + intensity
        
        // Additional fog particles
        let fogSystem = SCNParticleSystem()
        fogSystem.particleImage = createFogParticleImage()
        fogSystem.birthRate = CGFloat(60 * intensity)
        fogSystem.particleLifeSpan = 30.0
        fogSystem.particleSize = 15.0
        fogSystem.particleSizeVariation = 8.0
        fogSystem.particleColor = NSColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 0.3)
        fogSystem.particleVelocity = 0.5
        fogSystem.particleVelocityVariation = 0.3
        
        let fogNode = SCNNode()
        fogNode.addParticleSystem(fogSystem)
        fogNode.position = SCNVector3(0, 40, 0)
        fogNode.name = "Weather_Fog"
        scene.rootNode.addChildNode(fogNode)
    }
    
    // 🏜️ Drought Effects
    private func addDroughtEffects(scene: SCNScene, intensity: Double) {
        // Heat shimmer
        let heatSystem = SCNParticleSystem()
        heatSystem.particleImage = createHeatWaveParticleImage()
        heatSystem.birthRate = CGFloat(40 * intensity)
        heatSystem.particleLifeSpan = 6.0
        heatSystem.particleSize = 10.0
        heatSystem.particleSizeVariation = 4.0
        heatSystem.particleColor = NSColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 0.2)
        heatSystem.particleVelocity = 2.0
        heatSystem.acceleration = SCNVector3(0, 4.0, 0)  // Rising heat
        
        let heatNode = SCNNode()
        heatNode.addParticleSystem(heatSystem)
        heatNode.position = SCNVector3(0, 10, 0)
        heatNode.name = "Weather_Drought"
        scene.rootNode.addChildNode(heatNode)
        
        // Dust particles
        addDustEffects(scene: scene, intensity: intensity)
    }
    
    // ☀️ Clear Weather Effects
    private func addClearWeatherEffects(scene: SCNScene) {
        // Reset fog to normal
        scene.fogStartDistance = 100
        scene.fogEndDistance = 600
        scene.fogColor = NSColor(red: 0.85, green: 0.9, blue: 0.95, alpha: 1.0)
        scene.fogDensityExponent = 1.8
        
        // Gentle sunbeam effects
        let sunbeamSystem = SCNParticleSystem()
        sunbeamSystem.particleImage = createSunbeamParticleImage()
        sunbeamSystem.birthRate = 5
        sunbeamSystem.particleLifeSpan = 40.0
        sunbeamSystem.particleSize = 20.0
        sunbeamSystem.particleSizeVariation = 8.0
        sunbeamSystem.particleColor = NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.1)
        sunbeamSystem.particleVelocity = 0.2
        
        let sunbeamNode = SCNNode()
        sunbeamNode.addParticleSystem(sunbeamSystem)
        sunbeamNode.position = SCNVector3(0, 120, 0)
        sunbeamNode.name = "Weather_Sunbeams"
        scene.rootNode.addChildNode(sunbeamNode)
    }
    
    // Supporting weather effects
    private func addPuddleEffects(scene: SCNScene, intensity: Double) {
        let puddleSystem = SCNParticleSystem()
        puddleSystem.particleImage = createSplashParticleImage()
        puddleSystem.birthRate = CGFloat(30 * intensity)
        puddleSystem.particleLifeSpan = 2.0
        puddleSystem.particleSize = 3.0
        puddleSystem.particleColor = NSColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 0.6)
        puddleSystem.particleVelocity = 1.0
        puddleSystem.acceleration = SCNVector3(0, -5.0, 0)
        
        let puddleNode = SCNNode()
        puddleNode.addParticleSystem(puddleSystem)
        puddleNode.position = SCNVector3(0, 5, 0)
        puddleNode.name = "Weather_Puddles"
        scene.rootNode.addChildNode(puddleNode)
    }
    
    private func addWindGustEffects(scene: SCNScene, intensity: Double) {
        let gustSystem = SCNParticleSystem()
        gustSystem.particleImage = createWindGustParticleImage()
        gustSystem.birthRate = CGFloat(50 * intensity)
        gustSystem.particleLifeSpan = 5.0
        gustSystem.particleSize = 8.0
        gustSystem.particleColor = NSColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 0.2)
        gustSystem.particleVelocity = CGFloat(15.0 * intensity)
        gustSystem.particleVelocityVariation = CGFloat(8.0 * intensity)
        
        let gustNode = SCNNode()
        gustNode.addParticleSystem(gustSystem)
        gustNode.position = SCNVector3(0, 60, 0)
        gustNode.name = "Weather_WindGusts"
        scene.rootNode.addChildNode(gustNode)
    }
    
    private func addStormCloudEffects(scene: SCNScene, intensity: Double) {
        let cloudSystem = SCNParticleSystem()
        cloudSystem.particleImage = createStormCloudParticleImage()
        cloudSystem.birthRate = CGFloat(20 * intensity)
        cloudSystem.particleLifeSpan = 50.0
        cloudSystem.particleSize = 25.0
        cloudSystem.particleSizeVariation = 10.0
        cloudSystem.particleColor = NSColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 0.7)
        cloudSystem.particleVelocity = 2.0
        
        let cloudNode = SCNNode()
        cloudNode.addParticleSystem(cloudSystem)
        cloudNode.position = SCNVector3(0, 150, 0)
        cloudNode.name = "Weather_StormClouds"
        scene.rootNode.addChildNode(cloudNode)
    }
    
    private func addDustEffects(scene: SCNScene, intensity: Double) {
        let dustSystem = SCNParticleSystem()
        dustSystem.particleImage = createDustParticleImage()
        dustSystem.birthRate = CGFloat(45 * intensity)
        dustSystem.particleLifeSpan = 12.0
        dustSystem.particleSize = 4.0
        dustSystem.particleColor = NSColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 0.4)
        dustSystem.particleVelocity = 3.0
        dustSystem.particleVelocityVariation = 2.0
        
        let dustNode = SCNNode()
        dustNode.addParticleSystem(dustSystem)
        dustNode.position = SCNVector3(0, 20, 0)
        dustNode.name = "Weather_Dust"
        scene.rootNode.addChildNode(dustNode)
    }
    
    // MARK: - 🌍 Utility Functions
    
    /// Determine the dominant biome in the current world for biome-specific effects
    private func getDominantBiome() -> BiomeType {
        let voxelWorld = simulationEngine.voxelWorld
        var biomeCount: [BiomeType: Int] = [:]
        
        // Sample biomes from multiple points across the world
        let samplePoints = 20
        let stepX = voxelWorld.dimensions.width / samplePoints
        let stepY = voxelWorld.dimensions.height / samplePoints
        
        for i in 0..<samplePoints {
            for j in 0..<samplePoints {
                let x = min(i * stepX, voxelWorld.dimensions.width - 1)
                let y = min(j * stepY, voxelWorld.dimensions.height - 1)
                let biome = voxelWorld.biomeMap[x][y]
                biomeCount[biome, default: 0] += 1
            }
        }
        
        // Return the most common biome
        return biomeCount.max(by: { $0.value < $1.value })?.key ?? .temperateForest
    }
    
    // MARK: - Particle Image Generators
    
    private func createCausticParticleImage() -> NSImage {
        let size = 12
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Create ripple pattern
        NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.6).setFill()
        let circle = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size-2, height: size-2))
        circle.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createWindParticleImage() -> NSImage {
        let size = 16
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Create wind streak
        NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.3).setFill()
        let streak = NSBezierPath()
        streak.move(to: NSPoint(x: 0, y: size/2))
        streak.line(to: NSPoint(x: size, y: size/2 + 1))
        streak.line(to: NSPoint(x: size, y: size/2 - 1))
        streak.close()
        streak.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createAuraParticleImage() -> NSImage {
        let size = 10
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Create glowing orb
        let gradient = NSGradient(colors: [
            NSColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 0.8),
            NSColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    // MARK: - 🌍 PHASE 2: Enhanced Biome-Specific Particle Images
    
    // Snow and Ice Particles
    private func createSnowflakeParticleImage() -> NSImage {
        let size = 12
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor.white.setFill()
        let center = CGFloat(size) / 2
        let snowflake = NSBezierPath()
        
        // Create 6-pointed snowflake
        for i in 0..<6 {
            let angle = Double(i) * Double.pi / 3.0
            let x1 = center + cos(angle) * (center - 1)
            let y1 = center + sin(angle) * (center - 1)
            let x2 = center + cos(angle) * 2
            let y2 = center + sin(angle) * 2
            
            snowflake.move(to: NSPoint(x: x2, y: y2))
            snowflake.line(to: NSPoint(x: x1, y: y1))
        }
        snowflake.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func createAuroraParticleImage() -> NSImage {
        let size = 20
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 0.6),
            NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.3),
            NSColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 0.1)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createAlpineSnowParticleImage() -> NSImage {
        let size = 8
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 0.9).setFill()
        let snowflake = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size-2, height: size-2))
        snowflake.fill()
        
        image.unlockFocus()
        return image
    }
    
    // Forest and Plant Particles
    private func createMistParticleImage() -> NSImage {
        let size = 16
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 0.9, green: 0.95, blue: 0.98, alpha: 0.4),
            NSColor(red: 0.9, green: 0.95, blue: 0.98, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createTropicalMistParticleImage() -> NSImage {
        let size = 18
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 0.8, green: 0.95, blue: 0.85, alpha: 0.5),
            NSColor(red: 0.8, green: 0.95, blue: 0.85, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createPineMoteParticleImage() -> NSImage {
        let size = 6
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 0.7).setFill()
        let mote = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size))
        mote.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createLightRayParticleImage() -> NSImage {
        let size = 24
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.3),
            NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createLeafParticleImage() -> NSImage {
        let size: CGFloat = 8
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.6, green: 0.8, blue: 0.3, alpha: 0.8).setFill()
        let leaf = NSBezierPath()
        leaf.move(to: NSPoint(x: size/2, y: 0))
        leaf.curve(to: NSPoint(x: size, y: size/2), controlPoint1: NSPoint(x: size*0.8, y: size*0.2), controlPoint2: NSPoint(x: size*0.9, y: size*0.4))
        leaf.curve(to: NSPoint(x: size/2, y: size), controlPoint1: NSPoint(x: size*0.9, y: size*0.6), controlPoint2: NSPoint(x: size*0.8, y: size*0.8))
        leaf.curve(to: NSPoint(x: 0, y: size/2), controlPoint1: NSPoint(x: size*0.2, y: size*0.8), controlPoint2: NSPoint(x: size*0.1, y: size*0.6))
        leaf.curve(to: NSPoint(x: size/2, y: 0), controlPoint1: NSPoint(x: size*0.1, y: size*0.4), controlPoint2: NSPoint(x: size*0.2, y: size*0.2))
        leaf.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createGrassWaveParticleImage() -> NSImage {
        let size = 12
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.7, green: 0.9, blue: 0.4, alpha: 0.5).setStroke()
        let wave = NSBezierPath()
        wave.move(to: NSPoint(x: 0, y: size/2))
        wave.curve(to: NSPoint(x: size, y: size/2), controlPoint1: NSPoint(x: size/3, y: 0), controlPoint2: NSPoint(x: size*2/3, y: size))
        wave.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func createPollenParticleImage() -> NSImage {
        let size = 4
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.8).setFill()
        let pollen = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size))
        pollen.fill()
        
        image.unlockFocus()
        return image
    }
    
    // Desert Particles
    private func createHeatShimmerParticleImage() -> NSImage {
        let size = 16
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 0.3),
            NSColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createSandParticleImage() -> NSImage {
        let size = 6
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.7).setFill()
        let sand = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size))
        sand.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createGrassSeedParticleImage() -> NSImage {
        let size = 4
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 0.8).setFill()
        let seed = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size-2, height: size-2))
        seed.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createDustDevilParticleImage() -> NSImage {
        let size = 20
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 0.5).setStroke()
        let spiral = NSBezierPath()
        let center = CGFloat(size) / 2
        
        for i in 0..<20 {
            let angle = Double(i) * 0.5
            let radius = Double(i) * 0.4
            let x = center + cos(angle) * radius
            let y = center + sin(angle) * radius
            
            if i == 0 {
                spiral.move(to: NSPoint(x: x, y: y))
            } else {
                spiral.line(to: NSPoint(x: x, y: y))
            }
        }
        spiral.stroke()
        
        image.unlockFocus()
        return image
    }
    
    // Water Particles
    private func createWaterDropletParticleImage() -> NSImage {
        let size: CGFloat = 6
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.7, green: 0.9, blue: 0.95, alpha: 0.8).setFill()
        let droplet = NSBezierPath()
        droplet.move(to: NSPoint(x: size/2, y: 0))
        droplet.curve(to: NSPoint(x: size, y: size*0.7), controlPoint1: NSPoint(x: size*0.8, y: size*0.3), controlPoint2: NSPoint(x: size, y: size*0.5))
        droplet.curve(to: NSPoint(x: size/2, y: size), controlPoint1: NSPoint(x: size, y: size*0.9), controlPoint2: NSPoint(x: size*0.75, y: size))
        droplet.curve(to: NSPoint(x: 0, y: size*0.7), controlPoint1: NSPoint(x: size*0.25, y: size), controlPoint2: NSPoint(x: 0, y: size*0.9))
        droplet.curve(to: NSPoint(x: size/2, y: 0), controlPoint1: NSPoint(x: 0, y: size*0.5), controlPoint2: NSPoint(x: size*0.2, y: size*0.3))
        droplet.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createFireflyParticleImage() -> NSImage {
        let size = 8
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 1.0, green: 1.0, blue: 0.6, alpha: 1.0),
            NSColor(red: 1.0, green: 1.0, blue: 0.6, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createBubbleParticleImage() -> NSImage {
        let size = 10
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.4).setStroke()
        let bubble = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size-2, height: size-2))
        bubble.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func createSeaSprayParticleImage() -> NSImage {
        let size: CGFloat = 8
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.7).setFill()
        let spray = NSBezierPath()
        
        // Create irregular splash shape
        spray.move(to: NSPoint(x: size/2, y: 0))
        spray.line(to: NSPoint(x: size*0.8, y: size*0.3))
        spray.line(to: NSPoint(x: size, y: size*0.6))
        spray.line(to: NSPoint(x: size*0.7, y: size))
        spray.line(to: NSPoint(x: size*0.3, y: size))
        spray.line(to: NSPoint(x: 0, y: size*0.6))
        spray.line(to: NSPoint(x: size*0.2, y: size*0.3))
        spray.close()
        spray.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createFeatherParticleImage() -> NSImage {
        let size: CGFloat = 12
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 0.8).setFill()
        let feather = NSBezierPath()
        
        // Create feather shape
        feather.move(to: NSPoint(x: size/2, y: 0))
        feather.curve(to: NSPoint(x: size*0.8, y: size*0.4), controlPoint1: NSPoint(x: size*0.6, y: size*0.1), controlPoint2: NSPoint(x: size*0.7, y: size*0.25))
        feather.curve(to: NSPoint(x: size/2, y: size), controlPoint1: NSPoint(x: size*0.8, y: size*0.6), controlPoint2: NSPoint(x: size*0.65, y: size*0.8))
        feather.curve(to: NSPoint(x: size*0.2, y: size*0.4), controlPoint1: NSPoint(x: size*0.35, y: size*0.8), controlPoint2: NSPoint(x: size*0.2, y: size*0.6))
        feather.curve(to: NSPoint(x: size/2, y: 0), controlPoint1: NSPoint(x: size*0.3, y: size*0.25), controlPoint2: NSPoint(x: size*0.4, y: size*0.1))
        feather.fill()
        
        image.unlockFocus()
        return image
    }
    
    // MARK: - 🌦️ PHASE 2: Weather-Specific Particle Images
    
    private func createRainDropParticleImage() -> NSImage {
        let size = 4
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 0.9).setFill()
        let raindrop = NSBezierPath()
        raindrop.move(to: NSPoint(x: size/2, y: 0))
        raindrop.line(to: NSPoint(x: size/2, y: size))
        raindrop.lineWidth = 1.0
        raindrop.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func createBlizzardSnowParticleImage() -> NSImage {
        let size = 10
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 0.95).setFill()
        let snow = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size-2, height: size-2))
        snow.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createLightningParticleImage() -> NSImage {
        let size: CGFloat = 60
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.95).setStroke()
        let lightning = NSBezierPath()
        lightning.lineWidth = 3.0
        
        // Create zigzag lightning bolt
        lightning.move(to: NSPoint(x: size/2, y: 0))
        lightning.line(to: NSPoint(x: size*0.4, y: size*0.3))
        lightning.line(to: NSPoint(x: size*0.6, y: size*0.5))
        lightning.line(to: NSPoint(x: size*0.3, y: size*0.7))
        lightning.line(to: NSPoint(x: size/2, y: size))
        lightning.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func createFogParticleImage() -> NSImage {
        let size = 20
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 0.4),
            NSColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createHeatWaveParticleImage() -> NSImage {
        let size = 14
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 0.3),
            NSColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createSunbeamParticleImage() -> NSImage {
        let size = 40
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.2),
            NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createSplashParticleImage() -> NSImage {
        let size = 6
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 0.7).setFill()
        let splash = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size))
        splash.fill()
        
        image.unlockFocus()
        return image
    }
    
    private func createWindGustParticleImage() -> NSImage {
        let size: CGFloat = 16
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 0.3).setStroke()
        let gust = NSBezierPath()
        gust.lineWidth = 2.0
        
        // Create wind lines
        for i in 0..<3 {
            let y = CGFloat(i) * size/3 + size/6
            gust.move(to: NSPoint(x: 0, y: y))
            gust.line(to: NSPoint(x: size, y: y))
        }
        gust.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func createStormCloudParticleImage() -> NSImage {
        let size = 30
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 0.8),
            NSColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 0.0)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), relativeCenterPosition: NSPoint.zero)
        
        image.unlockFocus()
        return image
    }
    
    private func createDustParticleImage() -> NSImage {
        let size = 8
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        NSColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 0.5).setFill()
        let dust = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size-2, height: size-2))
        dust.fill()
        
        image.unlockFocus()
        return image
    }
    
    // MARK: - Animation and Updates
    
    private func setupCameraAnimation(scene: SCNScene) {
        // DISABLED: Let user control camera manually with built-in SceneKit controls
        // Camera animation disabled - manual control active
    }
    
    private func updateBugPositions(scene: SCNScene) {
        // Track updateBugPositions call frequency for performance monitoring
        
        // 🎮 AAA PERFORMANCE: Measure this critical function
        return performanceLogger.measure("updateBugPositions", includeStackTrace: true) {
            updateBugPositionsInternal(scene: scene)
        }
    }
    
    private func updateBugPositionsInternal(scene: SCNScene) {
        // Method call frequency tracking for performance monitoring
        
        // 🚨 IMMEDIATE GHOST BUG KILLER: Run before ANY other logic!
        let zeroEnergyBugsImmediate = simulationEngine.bugs.filter { $0.energy <= 0 }
        let lowEnergyBugs = simulationEngine.bugs.filter { $0.energy <= 1.0 && $0.energy > 0 }
        
        // 🚨 Track dying bugs immediately
        if lowEnergyBugs.count > 0 {
            for dyingBug in lowEnergyBugs {
                let dyingId = String(dyingBug.id.uuidString.prefix(8))
            }
        }
        
        if zeroEnergyBugsImmediate.count > 0 {
            
            // Get BugContainer immediately for removal
            if let bugContainer = scene.rootNode.childNode(withName: "BugContainer", recursively: false) {
                for deadBug in zeroEnergyBugsImmediate {
                    let deadId = String(deadBug.id.uuidString.prefix(8))
                    
                    // 🚨 FORCE REMOVE the visual node immediately
                    if let deadNode = bugContainer.childNode(withName: "Bug_\(deadBug.id.uuidString)", recursively: false) {
                        // 🔍 MEMORY LEAK DEBUG: Track node destruction
                        MemoryLeakTracker.shared.trackNodeDestruction(type: "BugNode (immediate death)", name: deadNode.name ?? "unnamed")
                        
                        // 🔍 MEMORY LEAK DEBUG: Track physics body cleanup (THE FINAL FIX!)
                        if deadNode.physicsBody != nil {
                            MemoryLeakTracker.shared.trackPhysicsBodyDestruction(type: "BugDynamic")
                            deadNode.physicsBody = nil // Explicitly clear physics body
                        }
                        
                        removeBugNodeSafely(deadNode)
                        bugNodeToBugMapping.removeValue(forKey: deadNode)
                    } else {
                    }
                }
            }
        }
        // Only log update frequency every 120 frames (4 seconds) to reduce noise
        if Arena3DView.updateCallCount % 120 == 0 {
            
            // 🚨 SPEED DIAGNOSIS: Check why bugs aren't moving
            let stuckBugs = simulationEngine.bugs.filter { 
                let decision = $0.lastDecision
                return decision != nil && (abs(decision!.moveX) < 0.01 && abs(decision!.moveY) < 0.01)
            }
        }
        
        // PHASE 1 DEBUG: Call verification methods
        // Debug tracking removed for performance
        
        // PHASE 1 DEBUG: Detailed verification every 5 seconds
        if Arena3DView.updateCallCount % 150 == 0 {
            verifyBugMapping()
            debugSimulationState()
        }
        
        // ✅ FIXED: Re-enabled visual positioning - jumping was caused by behavioral animations
        guard let bugContainer = scene.rootNode.childNode(withName: "BugContainer", recursively: false) else { 
            return 
        }
        
        // ✅ CRITICAL DEBUG: Force log every call and check for mismatches
        let visualNodes = bugContainer.childNodes.filter { $0.name?.hasPrefix("Bug_") == true }.count
        let aliveBugs = simulationEngine.bugs.filter { $0.isAlive }
        let deadBugs = simulationEngine.bugs.filter { !$0.isAlive }
        
        // 🚨 MANDATORY ZERO-ENERGY CHECK: Run every single update regardless of other conditions
        let zeroEnergyBugsSecondary = simulationEngine.bugs.filter { $0.energy <= 0 }
        
        // 🚨 CRITICAL DEBUG: Force log zero energy detection EVERY FRAME to see why it's not working
        let bugEnergies = simulationEngine.bugs.map { "\(String($0.id.uuidString.prefix(8))):\(String(format: "%.1f", $0.energy))" }
        
        if Arena3DView.updateCallCount % 30 == 0 {
        }
        
        // 🚨 IMMEDIATE: Log any bug with energy ≤ 1.0 (using lowEnergyBugs defined above)
        for bug in lowEnergyBugs {
            let bugId = String(bug.id.uuidString.prefix(8))
            if Arena3DView.updateCallCount % 10 == 0 { // Every 10 frames for low energy
            }
        }
        
        // 🚨 IMMEDIATE GHOST KILLER: Force remove any bug with negative energy
        let negativeEnergyBugs = simulationEngine.bugs.filter { $0.energy < 0 }
        if negativeEnergyBugs.count > 0 {
            for ghostBug in negativeEnergyBugs {
                let ghostId = String(ghostBug.id.uuidString.prefix(8))
                
                // Find and remove the visual node immediately
                if let ghostNode = bugContainer.childNode(withName: "Bug_\(ghostBug.id.uuidString)", recursively: false) {
                    // Physics cleanup handled by removeBugNodeSafely
                    removeBugNodeSafely(ghostNode)
                    bugNodeToBugMapping.removeValue(forKey: ghostNode)
                }
            }
        }
        
        // 🍎 PHASE 4 DIAGNOSTIC: Track energy oscillations for first 3 bugs
        for (_, bug) in simulationEngine.bugs.prefix(3).enumerated() {
            let bugId = String(bug.id.uuidString.prefix(8))
            
            // 🚨 FORCE ENERGY TRACKING: Run every 30 frames to see energy changes
            if Arena3DView.updateCallCount % 30 == 0 { // Log every 30 frames (1 second)
                let consumedFoodPos = bug.consumedFood != nil ? "(\(String(format: "%.1f", bug.consumedFood!.x)), \(String(format: "%.1f", bug.consumedFood!.y)))" : "none"
                
                // Check if bug is near food
                let nearbyFood = simulationEngine.foods.filter { food in
                    let distance = sqrt(pow(food.position.x - bug.position.x, 2) + pow(food.position.y - bug.position.y, 2))
                    return distance < 20.0
                }
                
                if !nearbyFood.isEmpty {
                }
                
                // Log neural movement intent
                if let decision = bug.lastDecision {
                    let movement = sqrt(decision.moveX * decision.moveX + decision.moveY * decision.moveY)
                }
            }
        }
        
        // 🚨 FORCE AGGRESSIVE DETECTION: Always check if counts don't match OR if dead bugs exist
        if visualNodes != simulationEngine.bugs.count || deadBugs.count > 0 {
            
            // 🚨 EMERGENCY: If we have 0 visual nodes but bugs exist, force immediate recreation
            if visualNodes == 0 && simulationEngine.bugs.count > 0 {
                for bug in simulationEngine.bugs {
                    // 🔧 FIX: Check if node already exists before creating
                    let existingNode = bugContainer.childNode(withName: "Bug_\(bug.id.uuidString)", recursively: false)
                    if existingNode == nil {
                        let newBugNode = createBugNode(bug: bug)
                        bugContainer.addChildNode(newBugNode)
                    }
                }
                return // Skip normal processing, let next frame handle positioning
            }
            
            // Force immediate death detection when mismatch detected
            checkForOrphanedNodes(bugContainer: bugContainer)
        }
        
        // 🚨 COMPREHENSIVE DEAD BUG CHECK: Look for ANY bugs that should be dead
        let potentiallyDeadBugs = simulationEngine.bugs.filter { $0.energy <= 5.0 } // Check bugs with very low energy
        if !potentiallyDeadBugs.isEmpty {
            for bug in potentiallyDeadBugs {
                let bugId = String(bug.id.uuidString.prefix(8))
                
                if bug.energy <= 0 {
                }
            }
        }
        
        // 🚨 PROCESS ALL ZERO-ENERGY BUGS: Always run this check
        if zeroEnergyBugsSecondary.count > 0 {
            for bug in zeroEnergyBugsSecondary {
                
                // 🚨 EMERGENCY: Force remove 0-energy bugs immediately regardless of isAlive status
                let bugIdString = String(bug.id.uuidString.prefix(8))
                if let visualNode = bugContainer.childNodes.first(where: { 
                    $0.name?.contains(bugIdString) == true 
                }) {
                    
                    addDeathAnimation(to: visualNode) {
                        // 🔍 MEMORY LEAK DEBUG: Track node destruction
                        MemoryLeakTracker.shared.trackNodeDestruction(type: "BugNode (death animation)", name: visualNode.name ?? "unnamed")
                        
                        // Remove from scene after animation
                        // Physics cleanup handled by removeBugNodeSafely
                        removeBugNodeSafely(visualNode)
                        
                        // Clean up mappings
                        self.bugNodeToBugMapping.removeValue(forKey: visualNode)
                        self.navigationResponder?.bugNodeToBugMapping.removeValue(forKey: visualNode)
                        
                    }
                }
            }
            
            // Force immediate cleanup of 0-energy bugs
            checkForOrphanedNodes(bugContainer: bugContainer)
        }
        
        if Int.random(in: 1...5) == 1 { // Very frequent logging for debugging
        }
        
        // 🧹 GENERATION CHANGE DETECTION: Check if we need to regenerate all bugs
        checkForGenerationChange(bugContainer: bugContainer)
        
        // 🧹 DEAD BUG CLEANUP: Always run aggressive death detection
        checkForNewlyDeadBugs(bugContainer: bugContainer)
        
        // 🚨 EMERGENCY DETECTION: Also check for any visual bugs that don't exist in simulation
        checkForOrphanedNodes(bugContainer: bugContainer)
        
        // 🔬 PHASE 1 DIAGNOSTIC: Enhanced movement tracking for all bugs
        
        // Track first bug's position changes for movement debugging
        if let firstBug = simulationEngine.bugs.first {
            let firstBugId = String(firstBug.id.uuidString.prefix(8))
            
            if let previousPos = Arena3DView.bugPositionTracker[firstBug.id] {
                let currentPos = firstBug.position3D
                let moved = sqrt(pow(currentPos.x - previousPos.x, 2) + pow(currentPos.y - previousPos.y, 2))
                
                if moved > 0.5 { // Only log significant movement
                    
                    // Check if visual node reflects this movement
                    if let visualNode = bugContainer.childNode(withName: "Bug_\(firstBug.id.uuidString)", recursively: false) {
                        let visualPos = visualNode.position
                        let visualDistance = sqrt(pow(Double(visualPos.x) - currentPos.x, 2) + pow(Double(visualPos.z) - currentPos.y, 2))
                        
                        if visualDistance > 5.0 {
                        }
                    }
                }
                
                Arena3DView.bugPositionTracker[firstBug.id] = currentPos
            } else {
                // Initialize tracking
                Arena3DView.bugPositionTracker[firstBug.id] = firstBug.position3D
            }
        }
        
        // Update visual positions to match simulation
        for bug in simulationEngine.bugs {
            
            let bugNodeName = "Bug_\(bug.id.uuidString)"
            let bugId = String(bug.id.uuidString.prefix(8))
            
            if let bugNode = bugContainer.childNode(withName: bugNodeName, recursively: false) {
                // Node found - applying position update
                // 🌍 TERRAIN FOLLOWING: Position bugs using their actual 3D position with terrain following
                let terrainHeight = getTerrainHeightAt(x: bug.position3D.x, z: bug.position3D.y)
                
                // Ensure bugs are always clearly above terrain surface
                let bugHeight = terrainHeight + 4.0  // Always 4 units above terrain to prevent body clipping
                
                let targetPosition = SCNVector3(
                    Float(bug.position3D.x),     // X position
                    Float(bugHeight),            // Y is height - use bug's actual height or terrain minimum
                    Float(bug.position3D.y)      // Z is depth/forward-back movement  
                )
                
                // Only check horizontal distance for movement animation
                let currentPosition = bugNode.position
                let horizontalDistance = sqrt(
                    (targetPosition.x - currentPosition.x) * (targetPosition.x - currentPosition.x) +
                    (targetPosition.z - currentPosition.z) * (targetPosition.z - currentPosition.z)
                )
                
                // Only log position updates for significant movement and reduce frequency 
                if horizontalDistance > 5.0 && Int.random(in: 1...100) == 1 {
                }
                
                // 🔍 VISUAL COORDINATE DEBUG: Track logical vs visual coordinate mapping
                let debugId = String(bug.id.uuidString.prefix(8))
                

                

                
                // Position update for bug movement
                
                if horizontalDistance > 0.01 { // Movement threshold to catch all movement
                    // 🎮 AAA GAME DEV FIX: Make movement DRAMATICALLY OBVIOUS for debugging
                    
                    // Remove any existing animations that might conflict
                    bugNode.removeAllActions()
                    
                    // 🎮 DRAMATIC VISUAL: Flash the bug bright red during movement 
                    if let geometry = bugNode.geometry {
                        let originalMaterial = geometry.firstMaterial?.diffuse.contents
                        geometry.firstMaterial?.diffuse.contents = NSColor.red
                        
                        // Reset color after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            geometry.firstMaterial?.diffuse.contents = originalMaterial
                        }
                    }
                    
                    // 🎮 DRAMATIC VISUAL: Scale bug up during movement
                    let originalScale = bugNode.scale
                    bugNode.scale = SCNVector3(originalScale.x * 2.0, originalScale.y * 2.0, originalScale.z * 2.0)
                    
                    // Set position directly instead of using animation for now
                    bugNode.position = targetPosition
                    
                    // Reset scale after movement
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        bugNode.scale = originalScale
                    }
                    
                    // Verify position was set
                    let verifyPosition = bugNode.position
                    
                    // Track movement frequency using local variables to avoid state modification violations
                    let currentTime = CACurrentMediaTime()
                    // Remove state tracking to avoid modification warnings
                    
                    // 🎮 AAA GAME DEV: Force SceneKit to refresh by triggering geometry update
                    bugNode.geometry?.firstMaterial?.transparency = 1.0
                    
                    // OLD ANIMATION CODE (disabled for debugging):
                    // let animationDuration = min(3.0, max(1.5, horizontalDistance * 0.1)) // 1.5-3.0 seconds - very slow!
                    // let moveAction = SCNAction.move(to: targetPosition, duration: animationDuration)
                    // moveAction.timingMode = .easeInEaseOut
                    // bugNode.runAction(moveAction, forKey: "movement") // ✅ Added key to prevent conflicts
                    
                    // ✅ DISABLED: Scaling animation during debugging
                    // if horizontalDistance > 5.0 {
                    //     let scaleUp = SCNAction.scale(to: 6.0, duration: 0.5)
                    //     let scaleDown = SCNAction.scale(to: 5.0, duration: 0.5)
                    //     let pulseAction = SCNAction.sequence([scaleUp, scaleDown])
                    //     bugNode.runAction(pulseAction, forKey: "movementPulse")
                    // }
                    
                    // ✅ FORCE ANIMATION DEBUG: More frequent logging to catch missing animations 
                    if horizontalDistance > 1.0 && Int.random(in: 1...8) == 1 {
                        
                    }
                } else {
                    // Set position directly for tiny movements only
                    bugNode.position = targetPosition
                    
                    // Log small movements being set directly
                    if horizontalDistance > 0.1 && Int.random(in: 1...200) == 1 {
                    }
                }
                
                // Update energy indicator (with threshold to prevent micro-updates)
                updateEnergyIndicator(bugNode: bugNode, energy: bug.energy)
                

                
            } else {
                // Bug node not found!
                
                // 🔧 FIX: Double-check if node already exists before creating
                let existingNode = bugContainer.childNode(withName: "Bug_\(bug.id.uuidString)", recursively: false)
                if existingNode == nil {
                    // Bug node doesn't exist, create it with new Phase 3 visuals
                    let newBugNode = createBugNode(bug: bug)
                    bugContainer.addChildNode(newBugNode)
                    
                    // Initialize tracking state for new bug
                    previousBugAliveState[bug.id] = bug.isAlive
                } else {
                    // Node exists but wasn't found in previous lookup - update mapping
                    if let existingNode = existingNode {
                        bugNodeToBugMapping[existingNode] = bug
                        previousBugAliveState[bug.id] = bug.isAlive
                    }
                }
            }
        }
    }
    
            // 🧹 Dead Bug Detection: Find orphaned visual nodes (bugs removed from simulation)
    private func checkForNewlyDeadBugs(bugContainer: SCNNode) {
        // Get current simulation bug IDs and their alive status
        let currentBugIds = Set(simulationEngine.bugs.map { $0.id })
        let currentBugStates = Dictionary(simulationEngine.bugs.map { ($0.id, $0.isAlive) }, uniquingKeysWith: { first, _ in first })
        
        // 🚨 DETAILED ANALYSIS: Check each bug's energy and alive status
        for bug in simulationEngine.bugs {
            if bug.energy <= 0 {
            }
        }
        
        // Find all visual bug nodes
        let allBugNodes = bugContainer.childNodes.filter { $0.name?.hasPrefix("Bug_") == true }
        
        
        var orphanedNodes: [SCNNode] = []
        var deadButVisibleNodes: [SCNNode] = []
        
        // Check each visual node to see if its bug still exists or died
        for bugNode in allBugNodes {
            guard let nodeName = bugNode.name,
                  let bugIdRange = nodeName.range(of: "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}", options: .regularExpression) else {
                continue
            }
            
            let bugIdString = String(nodeName[bugIdRange])
            if let bugId = UUID(uuidString: bugIdString) {
                
                if !currentBugIds.contains(bugId) {
                    // Bug completely removed from simulation - it died
                    orphanedNodes.append(bugNode)
                } else if let currentAlive = currentBugStates[bugId], 
                          let previousAlive = previousBugAliveState[bugId],
                          previousAlive && !currentAlive {
                    // Bug still in simulation but transitioned from alive to dead
                    deadButVisibleNodes.append(bugNode)
                } else if let currentAlive = currentBugStates[bugId], !currentAlive {
                    // Bug is dead in simulation and we haven't removed it yet
                    deadButVisibleNodes.append(bugNode)
                } else {
                    // 🚨 EXTRA CHECK: Manually check if bug should be dead based on energy
                    if let bug = simulationEngine.bugs.first(where: { $0.id == bugId }) {
                        if bug.energy <= 0 && bug.isAlive {
                            deadButVisibleNodes.append(bugNode)
                        }
                    }
                }
            }
        }
        
        // Process orphaned nodes (completely removed from simulation)
        for bugNode in orphanedNodes {
            guard let nodeName = bugNode.name,
                  let bugIdRange = nodeName.range(of: "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}", options: .regularExpression) else {
                continue
            }
            
            let bugIdString = String(nodeName[bugIdRange])
            let bugId = UUID(uuidString: bugIdString)
            
            
            addDeathAnimation(to: bugNode) {
                // 🔍 MEMORY LEAK DEBUG: Track node destruction
                MemoryLeakTracker.shared.trackNodeDestruction(type: "BugNode (orphaned)", name: bugNode.name ?? "unnamed")
                
                // Remove from scene after animation
                self.removeBugNodeSafely(bugNode)
                
                // Clean up mappings
                self.bugNodeToBugMapping.removeValue(forKey: bugNode)
                self.navigationResponder?.bugNodeToBugMapping.removeValue(forKey: bugNode)
                
                if let bugId = bugId {
                    self.previousBugAliveState.removeValue(forKey: bugId)
                }
                
            }
        }
        
        // Process dead bugs (still in simulation but dead)
        for bugNode in deadButVisibleNodes {
            guard let nodeName = bugNode.name,
                  let bugIdRange = nodeName.range(of: "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}", options: .regularExpression) else {
                continue
            }
            
            let bugIdString = String(nodeName[bugIdRange])
            
            
            addDeathAnimation(to: bugNode) {
                // 🔍 MEMORY LEAK DEBUG: Track node destruction
                MemoryLeakTracker.shared.trackNodeDestruction(type: "BugNode (dead but visible)", name: bugNode.name ?? "unnamed")
                
                // Remove from scene after animation
                self.removeBugNodeSafely(bugNode)
                
                // Clean up mappings
                self.bugNodeToBugMapping.removeValue(forKey: bugNode)
                self.navigationResponder?.bugNodeToBugMapping.removeValue(forKey: bugNode)
                
            }
        }
        
        let totalDeadNodes = orphanedNodes.count + deadButVisibleNodes.count
        if totalDeadNodes > 0 {
        }
        
        // Update tracking state for all current bugs
        for bug in simulationEngine.bugs {
            previousBugAliveState[bug.id] = bug.isAlive
        }
    }
    
    // 🚨 Emergency Orphaned Node Detection: Direct check for visual bugs without simulation counterparts
    private func checkForOrphanedNodes(bugContainer: SCNNode) {
        let currentBugIds = Set(simulationEngine.bugs.map { $0.id })
        let allBugNodes = bugContainer.childNodes.filter { $0.name?.hasPrefix("Bug_") == true }
        
        var orphanedCount = 0
        
        for bugNode in allBugNodes {
            guard let nodeName = bugNode.name,
                  let bugIdRange = nodeName.range(of: "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}", options: .regularExpression) else {
                continue
            }
            
            let bugIdString = String(nodeName[bugIdRange])
            if let bugId = UUID(uuidString: bugIdString) {
                if !currentBugIds.contains(bugId) {
                    orphanedCount += 1
                    
                    // Immediate removal with death animation
                    
                    addDeathAnimation(to: bugNode) {
                        // 🔍 MEMORY LEAK DEBUG: Track node destruction
                        MemoryLeakTracker.shared.trackNodeDestruction(type: "BugNode (orphaned cleanup)", name: bugNode.name ?? "unnamed")
                        
                        // Physics cleanup handled by removeBugNodeSafely
                        removeBugNodeSafely(bugNode)
                        self.bugNodeToBugMapping.removeValue(forKey: bugNode)
                        self.navigationResponder?.bugNodeToBugMapping.removeValue(forKey: bugNode)
                        
                        self.previousBugAliveState.removeValue(forKey: bugId)
                        
                    }
                }
            }
        }
        
        if orphanedCount > 0 {
        }
    }
    
    // 🧬 Generation Change Detection: Handle evolution to new generation
    private func checkForGenerationChange(bugContainer: SCNNode) {
        let currentGeneration = simulationEngine.currentGeneration
        let currentBugCount = simulationEngine.bugs.count
        let visualNodeCount = bugContainer.childNodes.filter { $0.name?.hasPrefix("Bug_") == true }.count
        
        // Get current bug IDs (needed for all checks)
        let currentBugIds = Set(simulationEngine.bugs.map { $0.id })
        
        // Only log generation debug every 60 frames (2 seconds) unless there's a change
        let shouldLogGenDebug = Arena3DView.updateCallCount % 60 == 0 || currentGeneration != previousGeneration || currentBugCount != visualNodeCount
        if shouldLogGenDebug {
        }
        
        // 🚨 EMERGENCY: If we see evolution logs but no generation change, force detection
        if currentGeneration == previousGeneration && currentBugCount == 20 && visualNodeCount == 20 {
            // Check if all bug IDs are different (indicates evolution happened but generation number didn't update)
            let allBugNodes = bugContainer.childNodes.filter { $0.name?.hasPrefix("Bug_") == true }
            var nodeIdMismatches = 0
            var visualBugIds: [String] = []
            
            for bugNode in allBugNodes {
                guard let nodeName = bugNode.name,
                      let bugIdRange = nodeName.range(of: "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}", options: .regularExpression) else {
                    continue
                }
                
                let bugIdString = String(nodeName[bugIdRange])
                visualBugIds.append(String(bugIdString.prefix(8)))
                
                if let bugId = UUID(uuidString: bugIdString) {
                    // Check if this visual bug ID exists in current simulation
                    if !currentBugIds.contains(bugId) {
                        nodeIdMismatches += 1
                    }
                }
            }
            
            if shouldLogGenDebug {
            }
            
            if nodeIdMismatches > 10 { // If more than half don't match, assume evolution happened
            }
        }
        
        // Check for generation change OR massive population replacement (indicates evolution)
        let generationChanged = currentGeneration != previousGeneration
        let populationJumped = currentBugCount > visualNodeCount + 5 // Big population increase suggests evolution
        
        // ID-based detection: If 80%+ of bug IDs changed, it's likely a generation change
        let commonIds = previousBugIds.intersection(currentBugIds)
        let replacementRatio = previousBugIds.isEmpty ? 0.0 : (1.0 - Double(commonIds.count) / Double(previousBugIds.count))
        let massiveReplacement = replacementRatio > 0.8 && !previousBugIds.isEmpty
        
        if shouldLogGenDebug {
        }
        
        if generationChanged || populationJumped || massiveReplacement {
            
            // Remove all existing bug nodes (they represent the old generation)
            let allBugNodes = bugContainer.childNodes.filter { $0.name?.hasPrefix("Bug_") == true }
            
            for bugNode in allBugNodes {
                // 🔍 MEMORY LEAK DEBUG: Track node destruction
                MemoryLeakTracker.shared.trackNodeDestruction(type: "BugNode (generation change)", name: bugNode.name ?? "unnamed")
                
                // No death animation for generation change - instant removal
                // Physics cleanup handled by removeBugNodeSafely
                removeBugNodeSafely(bugNode)
            }
            
            // Clear all mappings (old generation data)
            bugNodeToBugMapping.removeAll()
            previousBugAliveState.removeAll()
            
            // Clear NavigationResponder mappings too
            navigationResponder?.bugNodeToBugMapping.removeAll()
            
            
            // Update generation tracking
            previousGeneration = currentGeneration
            previousBugIds = currentBugIds
            
            // Note: New bug nodes will be created automatically in the main loop
            // when it detects missing nodes for the current bugs
            
            
            // Force initialization of new bug tracking states
            for bug in simulationEngine.bugs {
                previousBugAliveState[bug.id] = bug.isAlive
            }
            
        } else {
            // No generation change detected, but update tracking for next time
            previousBugIds = currentBugIds
        }
    }
    
    // 🎭 Add death animation to bug node before removal
    private func addDeathAnimation(to bugNode: SCNNode, completion: @escaping () -> Void) {
        // Create dramatic but faster death animation for better testing
        let fadeOut = SCNAction.fadeOut(duration: 1.0)
        let scaleDown = SCNAction.scale(to: 0.1, duration: 1.0)
        let spinAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 1.0)
        
        // Combine animations
        let deathAnimation = SCNAction.group([fadeOut, scaleDown, spinAction])
        
        
        // Run animation and then call completion
        bugNode.runAction(deathAnimation) {
            completion()
        }
    }
    
    // MARK: - 🍎 Food Rendering System
    
    // Food timing tracking removed to avoid state modification warnings
    
    // Static variable for food throttling outside the function to avoid scope issues
    private static var foodUpdateLastTime: TimeInterval = 0
    
        /// High-performance food system - renders all foods with LOD optimization
    private func updateFoodPositionsThrottled(scene: SCNScene) {
        let currentTime = CACurrentMediaTime()
        
        // Use static variable for throttling instead of @State to avoid modification warnings
        // Limit food updates to 20 FPS (every 50ms) for better performance - increased for better responsiveness
        if currentTime - Self.foodUpdateLastTime < 0.05 {
            return
        }
        Self.foodUpdateLastTime = currentTime
        
        // Remove state updates to avoid view modification violations
        // Food timing tracking moved to dedicated system outside view updates
        
        // 🎮 AAA PERFORMANCE: Measure food system
        return performanceLogger.measure("updateFoodPositionsThrottled") {
            updateFoodPositionsThrottledInternal(scene: scene)
        }
    }
    
    private func updateFoodPositionsThrottledInternal(scene: SCNScene) {
        // Get or create food container
        var foodContainer = scene.rootNode.childNode(withName: "FoodContainer", recursively: false)
        if foodContainer == nil {
            foodContainer = SCNNode()
            foodContainer!.name = "FoodContainer"
            scene.rootNode.addChildNode(foodContainer!)
        }
        
        let foods = simulationEngine.foods
        guard !foods.isEmpty else { return }
        
        // 🚀 LOD OPTIMIZATION: Render all foods but with distance-based level of detail
        let allFood = foods
        let foodsToRender = min(allFood.count, 1500)  // Increased cap to show more food (was 500)
        
        // Sort by distance to camera (if available) and render closest ones
        let cameraPosition = cameraNode?.position ?? SCNVector3(0, 200, 300)
        let sortedFoods = allFood.sorted { food1, food2 in
            let dist1 = sqrt(pow(food1.position.x - Double(cameraPosition.x), 2) + pow(food1.position.y - Double(cameraPosition.z), 2))
            let dist2 = sqrt(pow(food2.position.x - Double(cameraPosition.x), 2) + pow(food2.position.y - Double(cameraPosition.z), 2))
            return dist1 < dist2
        }
        
        let foodBatch = Array(sortedFoods.prefix(foodsToRender))
        
        // Clear existing food nodes and recreate from scratch for consistency
        let existingFoodNodes = foodContainer!.childNodes.filter { $0.name?.hasPrefix("Food_") == true }
        for node in existingFoodNodes {
            node.removeFromParentNode()
        }
        
        // Create nodes for visible foods
        for food in foodBatch {
            let foodId = "\(String(format: "%.1f", food.position.x))_\(String(format: "%.1f", food.position.y))"
            let foodNode = createSimpleFoodNode(position: food.position)
            foodNode.name = "Food_\(foodId)"
            foodContainer!.addChildNode(foodNode)
        }
        
        // Remove processing index state updates to avoid modification warnings
        // Index tracking moved to local variables
    }
    
    /// Create simplified food node for better performance with proper terrain positioning and food variety
    private func createSimpleFoodNode(position: CGPoint) -> SCNNode {
        let foodNode = SCNNode()
        
        // 🎯 GET ACTUAL FOOD TYPE: Use position to determine food type variety
        let foods = simulationEngine.foods
        let matchingFood = foods.first { food in
            let distance = sqrt(pow(food.position.x - position.x, 2) + pow(food.position.y - position.y, 2))
            return distance < 1.0  // Find food within 1 unit of this position
        }
        
        let foodType = matchingFood?.type ?? .apple  // Default to apple if no match
        
        // 🍎 Food Selection: Establish node-to-food mapping
        // 🔧 MEMORY LEAK FIX: Use weak references and check bounds
        if let actualFood = matchingFood {
            // Prevent dictionary from growing unbounded
            if foodNodeToFoodMapping.count < 1000 {
                foodNodeToFoodMapping[foodNode] = actualFood
                
                // 🐛 FIX: Also update NavigationResponder's mapping using static reference
                if let navResponder = NavigationResponderView.currentInstance,
                   navResponder.foodNodeToFoodMapping.count < 1000 {
                    navResponder.foodNodeToFoodMapping[foodNode] = actualFood
                }
            }
        }
        
        // 🍎 FOOD VARIETY: Create different visuals for different food types
        let sphere = SCNSphere(radius: 2.5)  // Slightly larger for better visibility
        let material = SCNMaterial()
        
        // Set color and properties based on food type
        switch foodType {
        case .apple:
            material.diffuse.contents = NSColor.red
        case .orange: 
            material.diffuse.contents = NSColor.orange
        case .plum:
            material.diffuse.contents = NSColor.purple
        case .melon:
            material.diffuse.contents = NSColor.green
        case .meat:
            material.diffuse.contents = NSColor.brown
        case .fish:
            material.diffuse.contents = NSColor.blue
        case .seeds:
            material.diffuse.contents = NSColor.yellow
        case .nuts:
            material.diffuse.contents = NSColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0) // Brown
        }
        
        material.metalness.contents = 0.0
        material.roughness.contents = 0.4
        
        // Add slight glow for food energy
        material.emission.contents = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 0.2)
        
        sphere.firstMaterial = material
        foodNode.geometry = sphere
        
        // 🌍 TERRAIN POSITIONING: Use actual terrain height instead of fixed height
        let terrainHeight = getTerrainHeightAt(x: position.x, z: position.y)
        let scnPosition = SCNVector3(
            Float(position.x),
            Float(terrainHeight + 1.5),  // Slightly above terrain surface (was fixed 10.0)
            Float(position.y)
        )
        foodNode.position = scnPosition
        
        // Add gentle pulsing to make food more noticeable
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.2, duration: 1.5),
            SCNAction.scale(to: 1.0, duration: 1.5)
        ])
        let repeatPulse = SCNAction.repeatForever(pulseAction)
        foodNode.runAction(repeatPulse)
        
        return foodNode
    }
    
    private func updateFoodPositions(scene: SCNScene) {
        // 🎮 AAA PERFORMANCE: Measure food system performance
        return performanceLogger.measure("updateFoodPositions") {
            updateFoodPositionsInternal(scene: scene)
        }
    }
    
    private func updateFoodPositionsInternal(scene: SCNScene) {
        // Get or create food container
        var foodContainer = scene.rootNode.childNode(withName: "FoodContainer", recursively: false)
        if foodContainer == nil {
            foodContainer = SCNNode()
            foodContainer!.name = "FoodContainer"
            scene.rootNode.addChildNode(foodContainer!)
        }
        
        // Get current food nodes
        let existingFoodNodes = foodContainer!.childNodes.filter { $0.name?.hasPrefix("Food_") == true }
        
        // Remove nodes for food that no longer exists
        for foodNode in existingFoodNodes {
            let foodId = foodNode.name?.replacingOccurrences(of: "Food_", with: "") ?? ""
            
            // 🔧 FIX: Use exact position matching instead of integer truncation
            let foodExists = simulationEngine.foods.contains(where: { food in
                let exactId = "\(String(format: "%.1f", food.position.x))_\(String(format: "%.1f", food.position.y))"
                return exactId == foodId
            })
            if !foodExists {
                // 🔍 MEMORY LEAK DEBUG: Track food node destruction
                MemoryLeakTracker.shared.trackNodeDestruction(type: "FoodNode", name: foodNode.name ?? "unnamed")
                foodNode.removeFromParentNode()
            }
        }
        
        // Add or update nodes for current food
        for food in simulationEngine.foods {
            // 🔧 FIX: Use exact position IDs to match removal system
            let foodId = "\(String(format: "%.1f", food.position.x))_\(String(format: "%.1f", food.position.y))"
            let existingNode = foodContainer!.childNode(withName: "Food_\(foodId)", recursively: false)
            
            if existingNode == nil {
                // Create new food node with exact position ID
                let foodNode = createFoodNode(position: food.position)
                foodNode.name = "Food_\(foodId)"
                foodContainer!.addChildNode(foodNode)
            }
        }
    }
    
    private func createFoodNode(position: CGPoint) -> SCNNode {
        let foodNode = SCNNode()
        
        // 🔍 MEMORY LEAK DEBUG: Track food node creation
        let foodId = "\(String(format: "%.1f", position.x))_\(String(format: "%.1f", position.y))"
        MemoryLeakTracker.shared.trackNodeCreation(type: "FoodNode", name: "Food_\(foodId)")
        
        // 🎯 GET ACTUAL FOOD TYPE: Use position to determine food type variety
        let foods = simulationEngine.foods
        let matchingFood = foods.first { food in
            let distance = sqrt(pow(food.position.x - position.x, 2) + pow(food.position.y - position.y, 2))
            return distance < 1.0  // Find food within 1 unit of this position
        }
        
        let foodType = matchingFood?.type ?? .apple  // Default to apple if no match
        
        // 🍎 Food Selection: Establish node-to-food mapping
        if let actualFood = matchingFood {
            foodNodeToFoodMapping[foodNode] = actualFood
            
            // 🐛 FIX: Also update NavigationResponder's mapping using static reference
            if let navResponder = NavigationResponderView.currentInstance {
                navResponder.foodNodeToFoodMapping[foodNode] = actualFood
            }
        }
        
        // Create food sphere with proper food type visuals
        let sphere = SCNSphere(radius: 2.5)  // Slightly smaller for better performance
        let material = SCNMaterial()
        
        // 🍎 FOOD VARIETY: Set color and properties based on actual food type
        switch foodType {
        case .apple:
            material.diffuse.contents = NSColor.red
            material.emission.contents = NSColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 0.3)
        case .orange: 
            material.diffuse.contents = NSColor.orange
            material.emission.contents = NSColor(red: 0.4, green: 0.2, blue: 0.0, alpha: 0.3)
        case .plum:
            material.diffuse.contents = NSColor.purple
            material.emission.contents = NSColor(red: 0.3, green: 0.1, blue: 0.3, alpha: 0.3)
        case .melon:
            material.diffuse.contents = NSColor.green
            material.emission.contents = NSColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 0.3)
        case .meat:
            material.diffuse.contents = NSColor.brown
            material.emission.contents = NSColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0.3)
        case .fish:
            material.diffuse.contents = NSColor.blue
            material.emission.contents = NSColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.3)
        case .seeds:
            material.diffuse.contents = NSColor.yellow
            material.emission.contents = NSColor(red: 0.3, green: 0.3, blue: 0.1, alpha: 0.3)
        case .nuts:
            material.diffuse.contents = NSColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0) // Brown
            material.emission.contents = NSColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 0.3)
        }
        
        material.metalness.contents = 0.0
        material.roughness.contents = 0.4
        
        sphere.firstMaterial = material
        foodNode.geometry = sphere
        
        // Position the food on the actual terrain surface
        let terrainHeight = getTerrainHeightAt(x: position.x, z: position.y)
        let scnPosition = SCNVector3(
            Float(position.x),
            Float(terrainHeight + 2.0), // Slightly above terrain surface
            Float(position.y)
        )
        foodNode.position = scnPosition
        
        // Add gentle pulsing animation to make food noticeable
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.2, duration: 1.5),
            SCNAction.scale(to: 1.0, duration: 1.5)
        ])
        let repeatPulse = SCNAction.repeatForever(pulseAction)
        foodNode.runAction(repeatPulse)
        
        return foodNode
    }
    
    // 🦋 PHASE 3: Force refresh of all bug visuals to apply new creature designs
    private func refreshAllBugVisuals(scene: SCNScene) {
        guard let bugContainer = scene.rootNode.childNode(withName: "BugContainer", recursively: false) else { return }
        
        // Remove all existing bug nodes
        let existingNodes = bugContainer.childNodes.filter { $0.name?.hasPrefix("Bug_") == true }
        for node in existingNodes {
            // 🔍 MEMORY LEAK DEBUG: Track node destruction
            MemoryLeakTracker.shared.trackNodeDestruction(type: "BugNode (visual refresh)", name: node.name ?? "unnamed")
            node.removeFromParentNode()
        }
        
        // Clear the old mappings since nodes are destroyed
        bugNodeToBugMapping.removeAll()
        
        // Recreate all bugs with new Phase 3 visuals
        for bug in simulationEngine.bugs {
            // 🔧 FIX: Check if node already exists before creating (refreshAllBugVisuals path)
            let existingNode = bugContainer.childNode(withName: "Bug_\(bug.id.uuidString)", recursively: false)
            if existingNode == nil {
                let newBugNode = createBugNode(bug: bug)
                bugContainer.addChildNode(newBugNode)
            }
        }
        
        // 🎯 CRITICAL: Refresh NavigationResponder mappings after recreating nodes
        refreshNavigationResponderMappings()
    }
    
    // 🎯 Bug Selection: Refresh NavigationResponder mappings after bug nodes are recreated
    private func refreshNavigationResponderMappings() {
        // Try direct reference first
        if let navigationResponder = navigationResponder {
            navigationResponder.bugNodeToBugMapping = bugNodeToBugMapping
            return
        }
        
        // Backup: Search for NavigationResponder in the view hierarchy
        if let foundResponder = findNavigationResponderInHierarchy() {
            foundResponder.bugNodeToBugMapping = bugNodeToBugMapping
            
            // Update our reference
            self.navigationResponder = foundResponder
            return
        }
        
    }
    
    // Helper function to find NavigationResponder in view hierarchy
    private func findNavigationResponderInHierarchy() -> NavigationResponderView? {
        // This will be called during setup to find the NavigationResponder
        // We'll use a more reliable approach - store a global reference or search the scene view
        return nil // For now, will implement if needed
    }
    
    private func updateEnergyIndicator(bugNode: SCNNode, energy: Double) {
        // Update energy bar height and color
        for childNode in bugNode.childNodes {
            if let geometry = childNode.geometry as? SCNBox,
               childNode.position.y > 2 { // Energy indicator is positioned above bug
                
                let newHeight = CGFloat(energy / Bug.maxEnergy * 5.0)
                let energyColor = energy > Bug.maxEnergy * 0.7 ? NSColor.green :
                                 energy > Bug.maxEnergy * 0.3 ? NSColor.yellow : NSColor.red
                
                // 🔧 CONTINENTAL WORLD FIX: Only update energy bar if significant change
                let heightDifference = abs(geometry.height - newHeight)
                if heightDifference > 0.2 { // Only update if energy changed by ~4% of max
                    geometry.height = newHeight
                    geometry.firstMaterial?.diffuse.contents = energyColor
                    geometry.firstMaterial?.emission.contents = energyColor
                }
            }
        }
    }
    
    private func updateTerritoryVisualizations(scene: SCNScene) {
        guard let territoryContainer = scene.rootNode.childNode(withName: "TerritoryContainer", recursively: false) else { return }
        
        // Update territory boundaries and contested areas
        for territory in simulationEngine.territoryManager.territories3D {
            if let territoryNode = territoryContainer.childNode(withName: "Territory_\(territory.id.uuidString)", recursively: false) {
                // Update contested layer indicators
                updateContestedLayers(territoryNode: territoryNode, territory: territory)
            }
        }
    }
    
    private func updateContestedLayers(territoryNode: SCNNode, territory: Territory3D) {
        // Add pulsing effect to contested layers
        for childNode in territoryNode.childNodes {
            if childNode.geometry is SCNSphere {
                var isContested = false
                for layer in territory.contestedLayers {
                    let layerMidPoint = layer.heightRange.lowerBound + (layer.heightRange.upperBound - layer.heightRange.lowerBound) / 2
                    let heightDifference = abs(Float(childNode.position.y) - Float(layerMidPoint))
                    if heightDifference < 10 {
                        isContested = true
                        break
                    }
                }
                
                if isContested {
                    let pulseAnimation = SCNAction.sequence([
                        SCNAction.scale(to: 1.2, duration: 0.5),
                        SCNAction.scale(to: 0.8, duration: 0.5)
                    ])
                    childNode.runAction(SCNAction.repeatForever(pulseAnimation))
                } else {
                    childNode.removeAllActions()
                    childNode.scale = SCNVector3(1, 1, 1)
                }
            }
        }
    }
    
    // MARK: - 🎮 DUAL NAVIGATION SYSTEM
    
    private func setupDualNavigationSystem(sceneView: SCNView, scene: SCNScene) {
        // Setting up dual navigation system
        // Camera node available checked
        
        // Create and configure navigation controller
        let navController = NavigationController()
        navController.cameraNode = cameraNode
        navController.sceneView = sceneView
        navController.voxelWorld = simulationEngine.voxelWorld  // For collision detection
        navController.navigationMode = navigationMode
        navController.walkingHeight = walkingHeight
        navController.movementSpeed = movementSpeed
        navController.rotationSpeed = rotationSpeed
        
        // Navigation controller camera set
        
        // Create navigation responder that fills the entire scene view
        let navigationResponder = NavigationResponderView()
        
        // 🔍 MEMORY LEAK DEBUG: Track NavigationResponder creation
        MemoryLeakTracker.shared.trackNavigationResponderCreation()
        
        navigationResponder.navigationController = navController
        navigationResponder.directCameraReference = cameraNode  // Direct backup reference
        navigationResponder.frame = sceneView.bounds
        navigationResponder.autoresizingMask = [.width, .height]
        
        // 🎯 Bug Selection: Set up bug selection system
        navigationResponder.sceneView = sceneView
        navigationResponder.bugNodeToBugMapping = bugNodeToBugMapping
        navigationResponder.onBugSelected = onBugSelected
        
        // 🍎 Food Selection: Set up food selection system
        navigationResponder.foodNodeToFoodMapping = foodNodeToFoodMapping
        navigationResponder.onFoodSelected = onFoodSelected
        
        // 🐛 FIX: Set static reference for access during direct triggerVisualUpdate() calls
        NavigationResponderView.currentInstance = navigationResponder
        
        // 🎯 NEW: Give NavigationResponder a closure to access current bug mappings
        // 🐛 FIX: Can't use [weak self] on structs, use direct references
        navigationResponder.getFallbackBugMappings = { 
            return self.bugNodeToBugMapping
        }
        
        // 🍎 NEW: Give NavigationResponder a closure to access current food mappings
        navigationResponder.getFallbackFoodMappings = {
            return self.foodNodeToFoodMapping
        }
        
        // CRITICAL: Make sure the responder can receive events
        navigationResponder.wantsLayer = true
        navigationResponder.canDrawConcurrently = true
        
        // Add to scene view
        sceneView.addSubview(navigationResponder)
        
        // 🎯 Store reference for later updates
        self.navigationResponder = navigationResponder
        
        // 🔧 MEMORY LEAK FIX: Store in coordinator for proper cleanup
        // Note: coordinator access will be handled in updateNSView instead
        
        // 🎯 Ensure mappings are properly transferred after initial setup
        refreshNavigationResponderMappings()
        
        // FORCE it to become first responder and update camera reference
        DispatchQueue.main.async {
            navigationResponder.window?.makeFirstResponder(navigationResponder)
            
            // RETRY camera assignment in case of timing issues
            if let camera = sceneView.scene?.rootNode.childNodes.first(where: { $0.camera != nil }) {
                navController.cameraNode = camera
                // Fixed camera reference
            }
            
            // Made NavigationResponder first responder
        }
        
        // Initial setup
        updateCameraForNavigationMode(navController.navigationMode)
        
        // Dual Navigation ready
        // Navigation responder frame set
    }
    
    private func updateCameraForNavigationMode(_ mode: NavigationMode) {
        guard let cameraNode = cameraNode, let sceneView = sceneView else { return }
        
        switch mode {
        case .walking:
            // First person walking mode: Lower height, ground following
            cameraNode.removeAllActions()
            let groundHeight = getTerrainHeight(at: cameraNode.position, sceneView: sceneView)
            cameraNode.position = SCNVector3(
                cameraNode.position.x,
                CGFloat(groundHeight + walkingHeight),
                cameraNode.position.z
            )
            // Walking Mode: First person at ground level
            
        case .god:
            // God mode: Free flight, start with overview
            cameraNode.removeAllActions()
            if cameraNode.position.y < 100 {
                cameraNode.position.y = 200  // Lift up for overview
            }
            // God Mode: Free flight navigation
        }
    }
    
    private func getTerrainHeight(at position: SCNVector3, sceneView: SCNView) -> Float {
        guard let scene = sceneView.scene else { return 0 }
        
        // Raycast from high above to ground to find terrain height
        let rayStart = SCNVector3(position.x, 1000, position.z)
        let rayEnd = SCNVector3(position.x, -1000, position.z)
        
        let raycastResults = scene.physicsWorld.rayTestWithSegment(from: rayStart, to: rayEnd, options: [
            .searchMode: SCNPhysicsWorld.TestSearchMode.closest.rawValue
        ])
        
        if let firstHit = raycastResults.first {
            return Float(firstHit.worldCoordinates.y)
        }
        
        // Fallback to default ground level
        return 0
    }
    
    // Old duplicate functions removed - logic moved to NavigationController
}

enum MovementDirection {
    case forward, backward, left, right, up, down
}

// 🎮 Navigation Controller - Handles navigation logic
class NavigationController {
    weak var cameraNode: SCNNode?
    weak var sceneView: SCNView?
    weak var voxelWorld: VoxelWorld?  // For collision detection
    var navigationMode: NavigationMode = .god
    var walkingHeight: Float = 10.0
    var movementSpeed: Float = 50.0
    var rotationSpeed: Float = 1.0
    
    var onModeToggle: (() -> Void)?
    
        // 🚧 COLLISION DETECTION for walkmode
    private func wouldCollide(at position: SCNVector3) -> Bool {
        guard let voxelWorld = voxelWorld, navigationMode == .walking else {
            return false  // No collision checking in god mode
        }
        
        // Collision check: Camera position
        
        // Convert SCNVector3 to Position3D for voxel lookup
        let position3D = Position3D(
            Double(position.x),
            Double(position.z),  // Note: SCN Y/Z swapped in voxel coords
            Double(position.y)
        )
        
        // Collision check: Converted position
        
        // Check voxel at this position
        guard let voxel = voxelWorld.getVoxel(at: position3D) else {
            // Collision check: No voxel found
            return false  // No voxel = no collision
        }
        
        // Collision check: Found voxel
        
        // 🚶 CAMERA-SPECIFIC COLLISION LOGIC
        // Cameras should be blocked by walls AND trees (even though bugs can climb trees)
        let wallBlocked = voxel.terrainType == .wall
        let treeBlocked = shouldBlockCameraFromVoxel(voxel)
        let isBlocked = wallBlocked || treeBlocked
        
        // Debug: Show blocking logic details
        // Blocking logic (debug commented)

        if isBlocked {
            // Collision detected - blocked
            return true
        } else {
            // No collision detected
            return false
        }
    }
    
    // 🌲 Determine if camera should be blocked by this voxel
    private func shouldBlockCameraFromVoxel(_ voxel: Voxel) -> Bool {
        switch voxel.transitionType {
        case .solid:
            return true  // Always block solid voxels
        case .climb:
            return true  // Block trees from camera (bugs can still climb)
        case .air, .ramp, .swim, .tunnel, .flight, .bridge:
            return false  // Allow camera through these
        }
    }
    
    func toggleMode() {
        navigationMode = navigationMode == .walking ? .god : .walking
        updateCameraForMode()
        
        let _ = navigationMode == .walking ? "🚶 Walking Mode" : "👁️ God Mode"
        // Switched navigation mode
    }
    
    private func updateCameraForMode() {
        guard let cameraNode = cameraNode else { return }
        
        switch navigationMode {
        case .walking:
            cameraNode.removeAllActions()
            let groundHeight = getTerrainHeight(at: cameraNode.position)
            cameraNode.position = SCNVector3(
                cameraNode.position.x,
                CGFloat(groundHeight + walkingHeight),
                cameraNode.position.z
            )
            // Set horizontal viewing angle for walking mode
            cameraNode.eulerAngles = SCNVector3(-0.1, cameraNode.eulerAngles.y, 0)  // Slight downward tilt
            // Walking Mode activated
            
        case .god:
            cameraNode.removeAllActions()
            if cameraNode.position.y < 100 {
                cameraNode.position.y = 200
            }
            // God Mode: Free flight navigation
        }
    }
    
    func moveCamera(direction: MovementDirection, deltaTime: Float) {
        // Try multiple ways to get camera reference
        var activeCamera: SCNNode?
        
        if let camera = cameraNode {
            activeCamera = camera
        } else if let scene = sceneView?.scene {
            activeCamera = scene.rootNode.childNodes.first(where: { $0.camera != nil })
            if let found = activeCamera {
                // Found camera in scene, updating reference
                cameraNode = found
            }
        }
        
        guard let cameraNode = activeCamera else { 
            // NavigationController: No camera node available
            return 
        }
        
        let distance = CGFloat(movementSpeed * deltaTime)
        var translation = SCNVector3(0, 0, 0)
        
        // Get camera's forward, right vectors
        let transform = cameraNode.transform
        let forward = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let right = SCNVector3(transform.m11, transform.m12, transform.m13)
        
        switch direction {
        case .forward:
            translation = SCNVector3(
                forward.x * distance,
                navigationMode == .walking ? 0 : forward.y * distance,
                forward.z * distance
            )
        case .backward:
            translation = SCNVector3(
                -forward.x * distance,
                navigationMode == .walking ? 0 : -forward.y * distance,
                -forward.z * distance
            )
        case .left:
            translation = SCNVector3(-right.x * distance, 0, -right.z * distance)
        case .right:
            translation = SCNVector3(right.x * distance, 0, right.z * distance)
        case .up:
            if navigationMode == .god {
                translation = SCNVector3(0, distance, 0)
            }
        case .down:
            if navigationMode == .god {
                translation = SCNVector3(0, -distance, 0)
            }
        }
        
        // Calculate intended new position
        let newPosition = SCNVector3(
            cameraNode.position.x + translation.x,
            cameraNode.position.y + translation.y,
            cameraNode.position.z + translation.z
        )
        
        // 🚧 COLLISION CHECK for walkmode
        if navigationMode == .walking {
            // Walkmode: Checking collision for movement
            let collisionResult = wouldCollide(at: newPosition)
            // Collision result checked
            if collisionResult {
                // Movement blocked by collision
                return  // Don't apply movement if collision detected
            } else {
                // No collision detected, allowing movement
            }
        }
        
        // Apply movement (no collision detected)
        cameraNode.position = newPosition
        
        // Only log significant movements to reduce noise
        let movementMagnitude = sqrt(translation.x * translation.x + translation.y * translation.y + translation.z * translation.z)
        if movementMagnitude > 1.0 {
            // Movement: direction logged
        }
        
        // Terrain following for walking mode
        if navigationMode == .walking {
            let groundHeight = getTerrainHeight(at: cameraNode.position)
            cameraNode.position.y = CGFloat(groundHeight + walkingHeight)
        }
    }
    
    func rotateCamera(yaw: Float, pitch: Float) {
        // Try multiple ways to get camera reference (same as moveCamera)
        var activeCamera: SCNNode?
        
        if let camera = cameraNode {
            activeCamera = camera
        } else if let scene = sceneView?.scene {
            activeCamera = scene.rootNode.childNodes.first(where: { $0.camera != nil })
            if let found = activeCamera {
                // Found camera in scene for rotation
                cameraNode = found
            }
        }
        
        guard let cameraNode = activeCamera else { 
            // NavigationController: No camera node for rotation
            return 
        }
        
        let currentRotation = cameraNode.eulerAngles
        let newYaw = currentRotation.y + CGFloat(yaw * rotationSpeed)
        let pitchAdjustment = CGFloat(pitch * rotationSpeed)
        let newPitch = max(CGFloat(-Float.pi/2 + 0.1), min(CGFloat(Float.pi/2 - 0.1), currentRotation.x + pitchAdjustment))
        
        cameraNode.eulerAngles = SCNVector3(newPitch, newYaw, 0)
        
        // Only log significant rotations
        if abs(yaw) > 0.01 || abs(pitch) > 0.01 {
            // Camera rotation applied
        }
    }
    
    private func getTerrainHeight(at position: SCNVector3) -> Float {
        guard let sceneView = sceneView, let scene = sceneView.scene else { return 0 }
        
        let rayStart = SCNVector3(position.x, 1000, position.z)
        let rayEnd = SCNVector3(position.x, -1000, position.z)
        
        let raycastResults = scene.physicsWorld.rayTestWithSegment(from: rayStart, to: rayEnd, options: [
            .searchMode: SCNPhysicsWorld.TestSearchMode.closest.rawValue
        ])
        
        if let firstHit = raycastResults.first {
            return Float(firstHit.worldCoordinates.y)
        }
        
        return 0
    }
}

// 🎮 Navigation Responder View - Handles input events
class NavigationResponderView: NSView {
    // 🐛 FIX: Static reference for access during direct triggerVisualUpdate() calls
    static weak var currentInstance: NavigationResponderView?
    
    var navigationController: NavigationController?
    weak var directCameraReference: SCNNode?  // Direct backup reference
    
    // 🎯 Bug Selection System
    weak var sceneView: SCNView?
    var bugNodeToBugMapping: [SCNNode: Bug] = [:]
    var onBugSelected: ((Bug?) -> Void)?
    
    // 🎯 NEW: Closure to get fallback bug mappings
    var getFallbackBugMappings: (() -> [SCNNode: Bug])?
    
    // 🍎 Food Selection System
    var foodNodeToFoodMapping: [SCNNode: FoodItem] = [:]
    var onFoodSelected: ((FoodItem?) -> Void)?
    var getFallbackFoodMappings: (() -> [SCNNode: FoodItem])?
    
    private var pressedKeys: Set<UInt16> = []
    private var lastUpdateTime: TimeInterval = 0
    internal var updateTimer: Timer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Enable mouse tracking
        let trackingArea = NSTrackingArea(
            rect: self.bounds,
            options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        self.addTrackingArea(trackingArea)
        
        // Start update timer
        lastUpdateTime = CACurrentMediaTime()
        startUpdateTimer()
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.window?.makeFirstResponder(self)
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        // Key down event
        pressedKeys.insert(event.keyCode)
        
        // Handle mode toggle (Space key)
        if event.keyCode == 49 { // Space
            // Space pressed - toggling mode
            navigationController?.toggleMode()
        }
    }
    
    override func keyUp(with event: NSEvent) {
        // Key up event
        pressedKeys.remove(event.keyCode)
    }
    
    override func mouseDragged(with event: NSEvent) {
        // Mouse dragged
        let sensitivity: Float = 0.005
        let yaw = Float(event.deltaX) * sensitivity    // 🎯 FIXED: Reversed for intuitive camera control
        let pitch = Float(event.deltaY) * sensitivity  // 🎯 FIXED: Reversed for intuitive camera control
        
        navigationController?.rotateCamera(yaw: yaw, pitch: pitch)
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        // Right mouse dragged
        // Same as left mouse drag for camera rotation
        mouseDragged(with: event)
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        // Other mouse dragged
        // Same as left mouse drag for camera rotation
        mouseDragged(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        // Mouse down - making first responder
        self.window?.makeFirstResponder(self)
        
        // 🎯 Bug Selection: Handle click for bug selection
        handleBugSelection(with: event)
    }
    
    // 🎯 Bug & Food Selection: Handle clicks on bugs and food items
    private func handleBugSelection(with event: NSEvent) {
        guard let sceneView = sceneView else {
            return
        }
        
        let clickLocation = convert(event.locationInWindow, from: nil)
        
        // Perform hit test to find clicked objects
        let hitResults = sceneView.hitTest(clickLocation, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .ignoreHiddenNodes: true
        ])
        
        let fallbackMappings = getFallbackBugMappings?() ?? [:]
        
        // Find the first bug node that was clicked
        for hitResult in hitResults {
            // Try NavigationResponder's mappings first
            if let bug = bugNodeToBugMapping[hitResult.node] {
                onBugSelected?(bug)
                return
            }
            
            // 🎯 FALLBACK: Try Arena3DView's mappings
            if let bug = fallbackMappings[hitResult.node] {
                onBugSelected?(bug)
                return
            }
            
            // Also check parent nodes (in case clicking on sub-components of bug)
            var parentNode = hitResult.node.parent
            var parentLevel = 0
            while parentNode != nil {
                // Try NavigationResponder's mappings for parent
                if let bug = bugNodeToBugMapping[parentNode!] {
                    onBugSelected?(bug)
                    return
                }
                
                // 🎯 FALLBACK: Try Arena3DView's mappings for parent
                if let bug = fallbackMappings[parentNode!] {
                    onBugSelected?(bug)
                    return
                }
                
                parentNode = parentNode?.parent
                parentLevel += 1
                if parentLevel > 5 { break } // Avoid infinite loops
            }
        }
        
        // 🍎 FOOD SELECTION: Check if clicked on food items
        let fallbackFoodMappings = getFallbackFoodMappings?() ?? [:]
        
        // Find the first food node that was clicked
        for hitResult in hitResults {
            // Try NavigationResponder's food mappings first
            if let food = foodNodeToFoodMapping[hitResult.node] {
                onFoodSelected?(food)
                onBugSelected?(nil) // Deselect any selected bug
                return
            }
            
            // 🎯 FALLBACK: Try Arena3DView's food mappings
            if let food = fallbackFoodMappings[hitResult.node] {
                onFoodSelected?(food)
                onBugSelected?(nil) // Deselect any selected bug
                return
            }
            
            // Also check parent nodes (in case clicking on sub-components of food)
            var parentNode = hitResult.node.parent
            var parentLevel = 0
            while parentNode != nil {
                // Try NavigationResponder's food mappings for parent
                if let food = foodNodeToFoodMapping[parentNode!] {
                    onFoodSelected?(food)
                    onBugSelected?(nil) // Deselect any selected bug
                    return
                }
                
                // 🎯 FALLBACK: Try Arena3DView's food mappings for parent
                if let food = fallbackFoodMappings[parentNode!] {
                    onFoodSelected?(food)
                    onBugSelected?(nil) // Deselect any selected bug
                    return
                }
                
                parentNode = parentNode?.parent
                parentLevel += 1
                if parentLevel > 5 { break } // Avoid infinite loops
            }
        }
        
        // No bug or food clicked - deselect both
        onBugSelected?(nil)
        onFoodSelected?(nil)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        // Right mouse down - making first responder
        self.window?.makeFirstResponder(self)
    }
    
    override func scrollWheel(with event: NSEvent) {
        // Scroll wheel event
        // Use scroll for camera rotation as backup
        let sensitivity: Float = 0.01
        let yaw = Float(event.deltaX) * sensitivity    // 🎯 FIXED: Reversed for intuitive trackpad control
        let pitch = Float(event.deltaY) * sensitivity  // 🎯 FIXED: Reversed for intuitive trackpad control
        
        if abs(event.deltaX) > 0.1 || abs(event.deltaY) > 0.1 {
            navigationController?.rotateCamera(yaw: yaw, pitch: pitch)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        // Track mouse movement even without dragging
        // Mouse moved in view
    }
    
    override func mouseEntered(with event: NSEvent) {
        // Mouse entered navigation view
        self.window?.makeFirstResponder(self)
    }
    
    override func mouseExited(with event: NSEvent) {
        // Mouse exited navigation view
    }
    
    private func startUpdateTimer() {
        // 🔍 MEMORY LEAK DEBUG: Track timer creation
        MemoryLeakTracker.shared.trackTimerCreation(description: "NavigationResponder updateTimer (60 FPS)")
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            // 🔧 FIXED: Defer to prevent state modifications during view updates
            DispatchQueue.main.async {
                self?.updateMovement()
            }
        }
    }
    
    private func updateMovement() {
        // 🎮 AAA PERFORMANCE: Measure this 60 FPS timer function
        PerformanceLogger.shared.measure("navigation_updateMovement") {
            updateMovementInternal()
        }
    }
    
    private func updateMovementInternal() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = Float(currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        
        guard let navigationController = navigationController else { 
            // No navigation controller
            return 
        }
        
        // Ensure navigation controller has camera reference
        if navigationController.cameraNode == nil && directCameraReference != nil {
            navigationController.cameraNode = directCameraReference
            // Restored camera reference from backup
        }
        
        // Debug: Show pressed keys only when they change
        // (removed periodic logging to reduce noise)
        
        // Handle continuous movement
        for keyCode in pressedKeys {
            switch keyCode {
            case 13, 126: // W or Up Arrow
                navigationController.moveCamera(direction: .forward, deltaTime: deltaTime)
            case 1, 125:  // S or Down Arrow  
                navigationController.moveCamera(direction: .backward, deltaTime: deltaTime)
            case 0, 123:  // A or Left Arrow
                navigationController.moveCamera(direction: .left, deltaTime: deltaTime)
            case 2, 124:  // D or Right Arrow
                navigationController.moveCamera(direction: .right, deltaTime: deltaTime)
            case 14:      // E - Up (God mode only)
                navigationController.moveCamera(direction: .up, deltaTime: deltaTime)
            case 12:      // Q - Down (God mode only)
                navigationController.moveCamera(direction: .down, deltaTime: deltaTime)
            default:
                break
            }
        }
    }
    

    
    deinit {
        // 🔍 MEMORY LEAK DEBUG: Track NavigationResponder destruction
        MemoryLeakTracker.shared.trackNavigationResponderDestruction()
        
        if let timer = updateTimer {
            MemoryLeakTracker.shared.trackTimerInvalidation(description: "NavigationResponder updateTimer (deinit)")
            timer.invalidate()
        }
    }
}

// MARK: - Position3D Extension for Debug
extension Position3D {
    func isClose(to other: Position3D, threshold: Double) -> Bool {
        let dist = distance(to: other) // Use existing distance method
        return dist < threshold
    }
}

// MARK: - 🌈 Extensions for Phase 3

// RGB Color Helper Extension for NSColor
private extension NSColor {
    var rgbComponents: (red: Double, green: Double, blue: Double) {
        guard let rgbColor = usingColorSpace(.deviceRGB) else {
            return (0.5, 0.5, 0.5) // Fallback gray
        }
        return (Double(rgbColor.redComponent), Double(rgbColor.greenComponent), Double(rgbColor.blueComponent))
    }
}

// MARK: - 🎮 AAA Performance Monitoring System

/// High-performance profiler for AAA game-quality performance monitoring
class PerformanceLogger {
    static let shared = PerformanceLogger() // Global singleton for easy access
    private var measurements: [String: PerformanceMeasurement] = [:]
    private let maxStackTraceDepth = 10
    
    struct PerformanceMeasurement {
        var totalTime: CFTimeInterval = 0
        var callCount: Int = 0
        var maxTime: CFTimeInterval = 0
        var minTime: CFTimeInterval = CFTimeInterval.greatestFiniteMagnitude
        var averageTime: CFTimeInterval { 
            callCount > 0 ? totalTime / CFTimeInterval(callCount) : 0 
        }
        var lastCallTime: CFTimeInterval = 0
        var stackTrace: String = ""
    }
    
    /// Start measuring performance for a specific operation
    func startMeasurement(_ operation: String, includeStackTrace: Bool = false) -> CFTimeInterval {
        let startTime = CACurrentMediaTime()
        
        if includeStackTrace {
            let stackTrace = Thread.callStackSymbols.prefix(maxStackTraceDepth).joined(separator: "\n")
            measurements[operation, default: PerformanceMeasurement()].stackTrace = stackTrace
        }
        
        return startTime
    }
    
    /// End measurement and record performance data
    func endMeasurement(_ operation: String, startTime: CFTimeInterval, threshold: CFTimeInterval = 0.016) {
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        
        var measurement = measurements[operation, default: PerformanceMeasurement()]
        measurement.totalTime += duration
        measurement.callCount += 1
        measurement.maxTime = max(measurement.maxTime, duration)
        measurement.minTime = min(measurement.minTime, duration)
        measurement.lastCallTime = duration
        measurements[operation] = measurement
        
        // Log if operation exceeds threshold (16ms = 60 FPS)
        if duration > threshold {
            let ms = duration * 1000
            
            // Print stack trace for slow operations
            if !measurement.stackTrace.isEmpty {
            }
        }
    }
    
    /// Log comprehensive performance report
    func logPerformanceReport() {
        
        let sortedMeasurements = measurements.sorted { $0.value.averageTime > $1.value.averageTime }
        
        for (operation, measurement) in sortedMeasurements {
            let avgMs = measurement.averageTime * 1000
            let maxMs = measurement.maxTime * 1000
            let minMs = measurement.minTime * 1000
            let lastMs = measurement.lastCallTime * 1000
            
            
            // Highlight problematic operations
            if measurement.averageTime > 0.016 { // > 16ms
            }
        }
        
    }
    
    /// Reset all measurements
    func reset() {
        measurements.removeAll()
    }
    
    /// Quick performance wrapper for measuring blocks
    @discardableResult
    func measure<T>(_ operation: String, includeStackTrace: Bool = false, _ block: () throws -> T) rethrows -> T {
        let startTime = startMeasurement(operation, includeStackTrace: includeStackTrace)
        defer { endMeasurement(operation, startTime: startTime) }
        return try block()
    }
}


