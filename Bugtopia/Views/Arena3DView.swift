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
    
    func makeNSView(context: Context) -> SCNView {
        let sceneView = SCNView()
        self.sceneView = sceneView
        
        // Create the 3D scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Configure scene view
        sceneView.backgroundColor = NSColor.black
        sceneView.allowsCameraControl = false  // Disable built-in - we'll handle navigation
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = false
        
        // Clean visual appearance (no debug overlays)
        sceneView.debugOptions = []
        
        // Set up the epic 3D world
        setupScene(scene: scene)
        setupLighting(scene: scene)
        setupCamera(scene: scene)
        setupEnvironmentalContext(scene: scene)
        addNavigationAids(scene: scene)
        
        // 🎨 FORCE VAN GOGH MATERIAL INITIALIZATION
        // Clear cache immediately to ensure Van Gogh materials are used
        Self.clearMaterialCache()
        Self.hasInitializedVanGoghMaterials = false
        
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
        // Update bug positions and territories
        updateBugPositions(scene: nsView.scene!)
        updateTerritoryVisualizations(scene: nsView.scene!)
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
        
        // Add invisible safety floor to catch anything that falls through
        createSafetyFloor(scene: scene)
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
        // Initializing AAA PBR lighting pipeline
        
        // 🌞 OPTIMIZED SUN: Balanced quality and performance
        let sunLight = SCNLight()
        sunLight.type = .directional
        sunLight.color = NSColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        sunLight.intensity = 2500  // Balanced for PBR materials
        sunLight.castsShadow = true
        sunLight.shadowRadius = 4.0  // Balanced shadows
        sunLight.shadowMapSize = CGSize(width: 1024, height: 1024)  // Optimized resolution
        sunLight.shadowMode = .deferred
        sunLight.shadowSampleCount = 8  // Balanced soft shadows
        sunLight.shadowColor = NSColor.black.withAlphaComponent(0.6)
        
        let sunNode = SCNNode()
        sunNode.light = sunLight
        sunNode.position = SCNVector3(300, 500, 300)
        sunNode.look(at: SCNVector3(0, 0, 0))
        
        // ADD VISIBLE SUN: Make the light source visible
        let sunGeometry = SCNSphere(radius: 20)
        sunGeometry.firstMaterial?.diffuse.contents = NSColor.yellow
        sunGeometry.firstMaterial?.emission.contents = NSColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)
        sunNode.geometry = sunGeometry
        
        scene.rootNode.addChildNode(sunNode)
        
        // 🌙 ENHANCED AMBIENT: Realistic sky illumination
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = NSColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 1.0)
        ambientLight.intensity = 400  // Increased for PBR
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // 💎 FILL LIGHT: Subtle rim lighting for 3D depth
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = NSColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        fillLight.intensity = 800
        
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(-200, 300, -200)
        fillNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fillNode)
        
        // 🕳️ UNDERGROUND MYSTIQUE: Atmospheric cave lighting
        let caveLight = SCNLight()
        caveLight.type = .omni
        caveLight.color = NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        caveLight.intensity = 1200
        caveLight.attenuationStartDistance = 50
        caveLight.attenuationEndDistance = 150
        
        let caveNode = SCNNode()
        caveNode.light = caveLight
        caveNode.position = SCNVector3(0, -40, 0)  // Underground level
        
        // ADD VISIBLE CAVE CRYSTAL: Mystical underground light source
        let crystalGeometry = SCNSphere(radius: 5)
        crystalGeometry.firstMaterial?.diffuse.contents = NSColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.8)
        crystalGeometry.firstMaterial?.emission.contents = NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        crystalGeometry.firstMaterial?.transparency = 0.7
        caveNode.geometry = crystalGeometry
        
        scene.rootNode.addChildNode(caveNode)
        
        // 🌳 CANOPY FILTER: Dappled forest lighting
        let canopyLight = SCNLight()
        canopyLight.type = .spot
        canopyLight.color = NSColor(red: 0.6, green: 0.9, blue: 0.4, alpha: 1.0)
        canopyLight.intensity = 1000
        canopyLight.spotInnerAngle = 30
        canopyLight.spotOuterAngle = 60
        
        let canopyNode = SCNNode()
        canopyNode.light = canopyLight
        canopyNode.position = SCNVector3(50, 100, 50)
        canopyNode.look(at: SCNVector3(0, 30, 0))  // Point at canopy level
        scene.rootNode.addChildNode(canopyNode)
        
        // 🌈 HDR ENVIRONMENT: Realistic reflections and global illumination
        scene.lightingEnvironment.intensity = 2.0
        scene.lightingEnvironment.contents = createAdvancedHDREnvironment()
        
        // AAA lighting system active
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
        
        // 2️⃣ GROUND PLANE: Anchor the terrain with infinite ground
        createGroundPlane(scene: scene)
        
        // 3️⃣ OPTIMIZED ATMOSPHERIC CLOUDS: Beautiful DALL-E clouds
        createOptimizedAtmosphericClouds(scene: scene)
        
        // 4️⃣ HORIZON MARKERS: Add distant landmarks for navigation reference
        createHorizonMarkers(scene: scene)
        
        // 5️⃣ COORDINATE GRID: Optional spatial reference system
        createCoordinateGrid(scene: scene)
        
        // Environmental context active
    }
    
    private func createSkybox(scene: SCNScene) {
        // Loading skybox
        
        // INSTANT LOADING: Use gorgeous pre-generated DALL-E skybox
        if let skyboxImage = NSImage(named: "epic-skybox-panorama") {
            scene.background.contents = skyboxImage
            scene.lightingEnvironment.contents = skyboxImage
            scene.lightingEnvironment.intensity = 2.5  // Enhanced lighting
            // Skybox loaded
        } else {
            // Skybox asset not found, using fallback
            // Fallback to procedural skybox
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
        
        // GOOD STARTING POSITION: Nice overview of terrain
        cameraNode.position = SCNVector3(100, 100, 100)  // Closer elevated overview
        cameraNode.look(at: SCNVector3(0, 0, 0))  // Look at terrain center
        
        scene.rootNode.addChildNode(cameraNode)
        self.cameraNode = cameraNode
        
        // Camera node created and assigned
        // Camera position set
        
        // ADD CAMERA CONSTRAINTS for better navigation
        addCameraConstraints(cameraNode: cameraNode, scene: scene)
        
        // Enhanced camera: HDR + Bloom active
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
        addTerrainCenterMarker(scene: scene)
        
        // 📏 SCALE REFERENCE: Help understand distances
        addScaleReference(scene: scene)
        
        // 🔺 LAYER INDICATORS: Show the 4 terrain layers visually
        addLayerIndicators(scene: scene)
        
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
        // Rendering 3D Voxel Terrain
        
        // 🎨 VAN GOGH MATERIAL REFRESH
        // Always ensure fresh Van Gogh materials by removing existing terrain
        scene.rootNode.childNode(withName: "VoxelTerrainContainer", recursively: false)?.removeFromParentNode()
        // Scene cleared for Van Gogh material application - will rebuild with new materials
        
        // Create terrain container
        let terrainContainer = SCNNode()
        terrainContainer.name = "VoxelTerrainContainer"
        scene.rootNode.addChildNode(terrainContainer)
        
        // Render voxels with spectacular visuals
        renderVoxelTerrain(container: terrainContainer)
        
        // Add particle effects for atmosphere
        addAtmosphericEffects(scene: scene)
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
        
        // Render voxels efficiently (only render visible/solid voxels)
        for x in 0..<simulationEngine.voxelWorld.dimensions.width {
            for y in 0..<simulationEngine.voxelWorld.dimensions.height {
                for z in 0..<simulationEngine.voxelWorld.dimensions.depth {
                    let voxel = simulationEngine.voxelWorld.voxels[x][y][z]
                    
                    // Only render solid/interesting voxels
                    if shouldRenderVoxel(voxel) {
                        let voxelNode = createVoxelNode(voxel: voxel)
                        layerContainers[voxel.layer]?.addChildNode(voxelNode)
                    }
                }
            }
        }
    }
    
    private func shouldRenderVoxel(_ voxel: Voxel) -> Bool {
        // Render voxels that are not just empty air
        switch voxel.transitionType {
        case .air:
            return false  // Don't render empty air voxels
        default:
            return true   // Render everything else (solid, water, climbable, etc.)
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
        let voxelSize = Float(simulationEngine.voxelWorld.voxelSize)
        
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
        
        // Depth-based water coloring
        let deepBlue = NSColor(red: 0.05, green: 0.2, blue: 0.4, alpha: 0.8)
        let shallowBlue = NSColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.6)
        let waterColor = blendColors(deepBlue, shallowBlue, ratio: depth)
        
        material.diffuse.contents = waterColor
        material.metalness.contents = 0.98      // Water is highly reflective
        material.roughness.contents = 0.02      // Ultra-smooth surface
        material.transparency = 0.3 + (depth * 0.4)  // Deeper water is more opaque
        
        // Add caustic-like patterns
        material.normal.contents = createWaterNormalMap(voxel: voxel)
        
        // Enable environmental reflections
        material.transparencyMode = .aOne
        
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
    
    // MARK: - High-Performance Material Caching System
    
    private static var materialCache: [String: SCNMaterial] = [:]
    private static var sharedTextures: [String: NSImage] = [:]
    
    // 🎨 VAN GOGH CACHE MANAGEMENT
    // Clear material cache to force regeneration with new Van Gogh materials
    static func clearMaterialCache() {
        materialCache.removeAll()
        sharedTextures.removeAll()
        // Material cache cleared for Van Gogh transformation
    }
    
    // Force immediate Van Gogh material regeneration
    func forceVanGoghMaterialUpdate() {
        Self.clearMaterialCache()
        Self.hasInitializedVanGoghMaterials = false
        // No state modification - materials will be applied immediately
    }
    
    // Van Gogh materials are applied immediately without state tracking
    
    // Force cache refresh on first Van Gogh render
    private static var hasInitializedVanGoghMaterials = false
    
    private func createPBRMaterial(for voxel: Voxel) -> SCNMaterial {
        // 🎨 VAN GOGH CACHE INVALIDATION
        // Clear cache on first Van Gogh render to force regeneration
        if !Self.hasInitializedVanGoghMaterials {
            Self.clearMaterialCache()
            Self.hasInitializedVanGoghMaterials = true
            // Van Gogh materials now active - cache cleared
        }
        
        // Create cache key for material reuse
        let cacheKey = "\(voxel.terrainType.rawValue)_\(voxel.biome.rawValue)_\(voxel.layer.rawValue)"
        
        // Return cached material if available
        if let cachedMaterial = Self.materialCache[cacheKey] {
            return cachedMaterial.copy() as! SCNMaterial
        }
        
        // Create new material and cache it
        let material: SCNMaterial
        switch voxel.terrainType {
        case .wall:
            material = createOptimizedRockMaterial(voxel: voxel)
        case .water:
            material = createOptimizedWaterMaterial(voxel: voxel)
        case .forest:
            material = createOptimizedWoodMaterial(voxel: voxel)
        case .sand:
            material = createOptimizedSandMaterial(voxel: voxel)
        case .ice:
            material = createOptimizedIceMaterial(voxel: voxel)
        case .hill:
            material = createOptimizedStoneMaterial(voxel: voxel)
        case .food:
            material = createOptimizedVegetationMaterial(voxel: voxel)
        case .swamp:
            material = createOptimizedMudMaterial(voxel: voxel)
        default:
            material = createOptimizedGrassMaterial(voxel: voxel)
        }
        
        // Cache the material for reuse
        Self.materialCache[cacheKey] = material
        return material.copy() as! SCNMaterial
    }
    
    private func createOptimizedRockMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Realistic rock properties with optimized shared textures
        material.diffuse.contents = getLayerAwareColor(
            baseColor: NSColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0),
            voxel: voxel
        )
        material.metalness.contents = 0.02      // Rocks are not metallic
        material.roughness.contents = 0.8       // Rough surface
        
        // Use shared normal map instead of generating per voxel
        material.normal.contents = getSharedTexture(type: "rock_normal")
        
        // Add subtle color variation based on biome
        material.diffuse.contents = modulateColorByBiome(
            baseColor: material.diffuse.contents as! NSColor,
            biome: voxel.biome
        )
        
        return material
    }
    
    private func createOptimizedWaterMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🎨 VAN GOGH WATER: Swirling, mesmerizing like Starry Night
        let vanGoghWaterColor = createVanGoghWaterColor(voxel: voxel)
        material.diffuse.contents = vanGoghWaterColor
        material.metalness.contents = 0.9       // Highly reflective
        material.roughness.contents = 0.1       // Smooth but with character
        material.transparency = 0.6
        
        // Use Van Gogh swirling water normal map
        material.normal.contents = getVanGoghTexture(type: "water_swirl")
        material.transparencyMode = .aOne
        
        // Add magical luminescence like moonlight on water
        material.emission.contents = NSColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 1.0)
        
        return material
    }
    
    // 🎨 Van Gogh Water Color Generation
    private func createVanGoghWaterColor(voxel: Voxel) -> NSColor {
        let position = voxel.position
        
        // Create hypnotic water swirls
        let centerX = position.x / 50.0 - 0.5
        let centerY = position.y / 50.0 - 0.5
        let radius = sqrt(centerX * centerX + centerY * centerY)
        let angle = atan2(centerY, centerX)
        
        // Van Gogh-style water with circular patterns
        let spiral = sin(radius * 15.0 + angle * 4.0) * 0.3
        let depth = cos(radius * 8.0) * 0.2
        
        // Deep blues with swirling highlights
        let blueIntensity = 0.6 + spiral * 0.3
        let greenHint = 0.2 + depth * 0.2
        let highlights = 0.1 + max(0, spiral * 0.4)
        
        return NSColor(
            red: CGFloat(highlights),
            green: CGFloat(greenHint),
            blue: CGFloat(blueIntensity),
            alpha: 0.7
        )
    }
    
    private func createOptimizedWoodMaterial(voxel: Voxel) -> SCNMaterial {
        let material = SCNMaterial()
        
        // 🎨 VAN GOGH TREES: Expressive cypress-like with flame patterns
        let vanGoghTreeColor = createVanGoghTreeColor(voxel: voxel)
        material.diffuse.contents = vanGoghTreeColor
        material.metalness.contents = 0.0       // Wood is not metallic
        material.roughness.contents = 0.7       // Textured bark feeling
        
        // Use Van Gogh flame-like tree normal map
        material.normal.contents = getVanGoghTexture(type: "tree_swirl")
        
        // Add warm tree glow like Van Gogh's golden trees
        material.emission.contents = NSColor(red: 0.1, green: 0.05, blue: 0.02, alpha: 1.0)
        
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
        material.emission.contents = NSColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0)
        
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
        // Return cached texture if available
        if let cachedTexture = Self.sharedTextures[type] {
            return cachedTexture
        }
        
        // Generate texture once and cache it
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
        default:
            texture = createDefaultNormalMap()
        }
        
        // Cache for future use
        Self.sharedTextures[type] = texture
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
        case grass, water, tree, sky
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
        box.firstMaterial?.diffuse.contents = getLayerColor(layer: layer, alpha: 0.8)
        box.firstMaterial?.roughness.contents = 0.8
        box.firstMaterial?.metalness.contents = 0.1
        return box
    }
    
    private func createWallTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.1)
        box.firstMaterial?.diffuse.contents = NSColor.darkGray
        box.firstMaterial?.roughness.contents = 0.9
        box.firstMaterial?.metalness.contents = 0.2
        box.firstMaterial?.normal.contents = "rock_normal" // Add texture if available
        return box
    }
    
    private func createWaterTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.5)
        box.firstMaterial?.diffuse.contents = NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.7)
        box.firstMaterial?.transparency = 0.7
        box.firstMaterial?.roughness.contents = 0.1
        box.firstMaterial?.metalness.contents = 0.0
        return box
    }
    
    private func createFoodTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let sphere = SCNSphere(radius: CGFloat(size * 0.4))
        sphere.firstMaterial?.diffuse.contents = NSColor.green
        sphere.firstMaterial?.emission.contents = NSColor(red: 0.0, green: 0.3, blue: 0.0, alpha: 1.0)
        sphere.firstMaterial?.roughness.contents = 0.3
        return sphere
    }
    
    private func createForestTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let cylinder = SCNCylinder(radius: CGFloat(size * 0.3), height: CGFloat(height))
        cylinder.firstMaterial?.diffuse.contents = NSColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
        cylinder.firstMaterial?.roughness.contents = 0.7
        return cylinder
    }
    
    private func createHillTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let cone = SCNCone(topRadius: 0, bottomRadius: CGFloat(size * 0.6), height: CGFloat(height))
        cone.firstMaterial?.diffuse.contents = NSColor.brown
        cone.firstMaterial?.roughness.contents = 0.8
        return cone
    }
    
    private func createSandTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.3)
        box.firstMaterial?.diffuse.contents = NSColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)
        box.firstMaterial?.roughness.contents = 0.9
        return box
    }
    
    private func createIceTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.1)
        box.firstMaterial?.diffuse.contents = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.9)
        box.firstMaterial?.transparency = 0.9
        box.firstMaterial?.roughness.contents = 0.1
        box.firstMaterial?.metalness.contents = 0.1
        return box
    }
    
    private func createSwampTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size), chamferRadius: 0.4)
        box.firstMaterial?.diffuse.contents = NSColor(red: 0.4, green: 0.5, blue: 0.2, alpha: 0.8)
        box.firstMaterial?.roughness.contents = 0.9
        return box
    }
    
    private func createWindTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        // Invisible geometry with particle effects
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height * 0.1), length: CGFloat(size), chamferRadius: 0.5)
        box.firstMaterial?.diffuse.contents = NSColor.clear
        box.firstMaterial?.transparency = 0.1
        return box
    }
    
    private func createPredatorTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let pyramid = SCNPyramid(width: CGFloat(size), height: CGFloat(height), length: CGFloat(size))
        pyramid.firstMaterial?.diffuse.contents = NSColor.red
        pyramid.firstMaterial?.emission.contents = NSColor(red: 0.3, green: 0.0, blue: 0.0, alpha: 1.0)
        return pyramid
    }
    
    private func createShadowTerrain(size: Float, height: Float, layer: TerrainLayer) -> SCNGeometry {
        let box = SCNBox(width: CGFloat(size), height: CGFloat(height * 0.5), length: CGFloat(size), chamferRadius: 0.2)
        box.firstMaterial?.diffuse.contents = NSColor(white: 0.2, alpha: 0.6)
        box.firstMaterial?.transparency = 0.6
        return box
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
    
    // MARK: - Bug Rendering
    
    private func renderBugs(scene: SCNScene) {
        let bugs = simulationEngine.bugs
        // Rendering 3D Bugs
        // Bug array contents (debug commented)
        
        let bugContainer = SCNNode()
        bugContainer.name = "BugContainer"
        scene.rootNode.addChildNode(bugContainer)
        
        for bug in bugs {
            let bugNode = createBugNode(bug: bug)
            bugContainer.addChildNode(bugNode)
            // Created 3D node for bug
        }
        // BugContainer added to scene
    }
    
    private func createBugNode(bug: Bug) -> SCNNode {
        let bugNode = SCNNode()
        bugNode.name = "Bug_\(bug.id.uuidString)"
        
        // Create bug body based on species
        let bodyGeometry = createBugGeometry(for: bug)
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bugNode.addChildNode(bodyNode)
        
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
        
        // Position bug in 3D space with surface correction
        var scnPosition = SCNVector3(
            Float(bug.position3D.x),
            Float(bug.position3D.z),
            Float(bug.position3D.y)
        )
        
        // Ensure bug is positioned above any solid terrain at this location
        if let scene = sceneView?.scene {
            let rayStart = SCNVector3(scnPosition.x, scnPosition.y + 50, scnPosition.z)
            let rayEnd = SCNVector3(scnPosition.x, scnPosition.y - 50, scnPosition.z)
            
            let raycastResults = scene.physicsWorld.rayTestWithSegment(from: rayStart, to: rayEnd, options: [:])
            
            if let firstHit = raycastResults.first {
                // Position bug slightly above the terrain surface
                scnPosition.y = firstHit.worldCoordinates.y + 2.0  // 2 units above surface
                // Bug positioned on terrain surface
            }
        }
        
        bugNode.position = scnPosition
        
        // Debug positioning
        // Bug positioned (debug commented)
        
        // Add physics body with enhanced shape and margin for reliable collision
        let physicsOptions: [SCNPhysicsShape.Option: Any] = [
            .type: SCNPhysicsShape.ShapeType.convexHull,    // More accurate than bounding box
            .collisionMargin: 0.5                          // Add collision margin for reliability
        ]
        let physicsShape = SCNPhysicsShape(geometry: bodyGeometry, options: physicsOptions)
        bugNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
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
        
        // Debug physics body creation
                    // Physics body created for bug
        
        // Add energy indicator
        addEnergyIndicator(to: bugNode, energy: bug.energy)
        
        return bugNode
    }
    
    private func createBugGeometry(for bug: Bug) -> SCNGeometry {
        let species = bug.dna.speciesTraits.speciesType
        let size = Float(bug.dna.size * 10.0) // Scale for visibility in voxel world
        
        switch species {
        case .herbivore:
            // 🟢 VAN GOGH HERBIVORE: Organic, flowing sphere with swirling greens
            let sphere = SCNSphere(radius: CGFloat(size))
            sphere.firstMaterial = createVanGoghBugMaterial(
                species: .herbivore, 
                bug: bug,
                baseColor: NSColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
            )
            return sphere
            
        case .carnivore:
            // 🔴 VAN GOGH CARNIVORE: Angular, aggressive with flame-like reds
            let box = SCNBox(width: CGFloat(size * 1.5), height: CGFloat(size), length: CGFloat(size * 1.2), chamferRadius: 0.2)
            box.firstMaterial = createVanGoghBugMaterial(
                species: .carnivore, 
                bug: bug,
                baseColor: NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
            )
            return box
            
        case .omnivore:
            // 🟠 VAN GOGH OMNIVORE: Dynamic capsule with sunset gradients
            let capsule = SCNCapsule(capRadius: CGFloat(size * 0.8), height: CGFloat(size * 1.5))
            capsule.firstMaterial = createVanGoghBugMaterial(
                species: .omnivore, 
                bug: bug,
                baseColor: NSColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
            )
            return capsule
            
        case .scavenger:
            // 🟣 VAN GOGH SCAVENGER: Mysterious cylinder with iridescent purples
            let cylinder = SCNCylinder(radius: CGFloat(size * 0.7), height: CGFloat(size * 1.2))
            cylinder.firstMaterial = createVanGoghBugMaterial(
                species: .scavenger, 
                bug: bug,
                baseColor: NSColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0)
            )
            return cylinder
        }
    }
    
    // 🎨 Van Gogh Bug Material Creation
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
    
    private func addWings(to bugNode: SCNNode, bug: Bug) {
        let wingSize = Float(bug.dna.wingSpan * 0.5)
        
        // Left wing
        let leftWing = SCNBox(width: CGFloat(wingSize), height: 0.1, length: CGFloat(wingSize * 0.3), chamferRadius: 0.05)
        leftWing.firstMaterial?.diffuse.contents = NSColor(white: 0.9, alpha: 0.7)
        leftWing.firstMaterial?.transparency = 0.7
        
        let leftWingNode = SCNNode(geometry: leftWing)
        leftWingNode.position = SCNVector3(-wingSize * 0.7, 0, 0)
        bugNode.addChildNode(leftWingNode)
        
        // Right wing
        let rightWingNode = SCNNode(geometry: leftWing)
        rightWingNode.position = SCNVector3(wingSize * 0.7, 0, 0)
        bugNode.addChildNode(rightWingNode)
        
        // Add wing animation
        let flapAnimation = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0, z: 0.3, duration: 0.1),
            SCNAction.rotateBy(x: 0, y: 0, z: -0.6, duration: 0.2),
            SCNAction.rotateBy(x: 0, y: 0, z: 0.3, duration: 0.1)
        ])
        let repeatFlap = SCNAction.repeatForever(flapAnimation)
        
        leftWingNode.runAction(repeatFlap)
        rightWingNode.runAction(repeatFlap)
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
    
    // MARK: - Particle Image Generators
    
    private func createSparkleParticleImage() -> NSImage {
        let size = 8
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Create star shape
        NSColor.white.setFill()
        let center = CGFloat(size) / 2
        let star = NSBezierPath()
        star.move(to: NSPoint(x: center, y: CGFloat(size)))
        star.line(to: NSPoint(x: center - 1, y: center))
        star.line(to: NSPoint(x: 0, y: center))
        star.line(to: NSPoint(x: center - 1, y: center - 1))
        star.line(to: NSPoint(x: center, y: 0))
        star.line(to: NSPoint(x: center + 1, y: center - 1))
        star.line(to: NSPoint(x: CGFloat(size), y: center))
        star.line(to: NSPoint(x: center + 1, y: center))
        star.close()
        star.fill()
        
        image.unlockFocus()
        return image
    }
    
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
    
    // MARK: - Animation and Updates
    
    private func setupCameraAnimation(scene: SCNScene) {
        // DISABLED: Let user control camera manually with built-in SceneKit controls
        // Camera animation disabled - manual control active
    }
    
    private func updateBugPositions(scene: SCNScene) {
        guard let bugContainer = scene.rootNode.childNode(withName: "BugContainer", recursively: false) else { return }
        
        for bug in simulationEngine.bugs {
            if let bugNode = bugContainer.childNode(withName: "Bug_\(bug.id.uuidString)", recursively: false) {
                // Smooth position interpolation
                let targetPosition = SCNVector3(
                    Float(bug.position3D.x),
                    Float(bug.position3D.z),
                    Float(bug.position3D.y)
                )
                
                let moveAction = SCNAction.move(to: targetPosition, duration: 0.1)
                bugNode.runAction(moveAction)
                
                // Update energy indicator
                updateEnergyIndicator(bugNode: bugNode, energy: bug.energy)
            }
        }
    }
    
    private func updateEnergyIndicator(bugNode: SCNNode, energy: Double) {
        // Update energy bar height and color
        for childNode in bugNode.childNodes {
            if let geometry = childNode.geometry as? SCNBox,
               childNode.position.y > 2 { // Energy indicator is positioned above bug
                
                let newHeight = CGFloat(energy / Bug.maxEnergy * 5.0)
                let energyColor = energy > Bug.maxEnergy * 0.7 ? NSColor.green :
                                 energy > Bug.maxEnergy * 0.3 ? NSColor.yellow : NSColor.red
                
                geometry.height = newHeight
                geometry.firstMaterial?.diffuse.contents = energyColor
                geometry.firstMaterial?.emission.contents = energyColor
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
        navigationResponder.navigationController = navController
        navigationResponder.directCameraReference = cameraNode  // Direct backup reference
        navigationResponder.frame = sceneView.bounds
        navigationResponder.autoresizingMask = [.width, .height]
        
        // CRITICAL: Make sure the responder can receive events
        navigationResponder.wantsLayer = true
        navigationResponder.canDrawConcurrently = true
        
        // Add to scene view
        sceneView.addSubview(navigationResponder)
        
        // FORCE it to become first responder and update camera reference
        DispatchQueue.main.async { [weak sceneView] in
            navigationResponder.window?.makeFirstResponder(navigationResponder)
            
            // RETRY camera assignment in case of timing issues
            if let camera = sceneView?.scene?.rootNode.childNodes.first(where: { $0.camera != nil }) {
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
    var navigationController: NavigationController?
    weak var directCameraReference: SCNNode?  // Direct backup reference
    
    private var pressedKeys: Set<UInt16> = []
    private var lastUpdateTime: TimeInterval = 0
    private var updateTimer: Timer?
    
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
        let yaw = -Float(event.deltaX) * sensitivity
        let pitch = -Float(event.deltaY) * sensitivity
        
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
    }
    
    override func rightMouseDown(with event: NSEvent) {
        // Right mouse down - making first responder
        self.window?.makeFirstResponder(self)
    }
    
    override func scrollWheel(with event: NSEvent) {
        // Scroll wheel event
        // Use scroll for camera rotation as backup
        let sensitivity: Float = 0.01
        let yaw = -Float(event.deltaX) * sensitivity
        let pitch = -Float(event.deltaY) * sensitivity
        
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
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateMovement()
        }
    }
    
    private func updateMovement() {
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
        updateTimer?.invalidate()
    }
}
