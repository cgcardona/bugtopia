//
//  Arena3DView.swift
//  Bugtopia
//
//  Created by Assistant on 8/1/25.
//

import SwiftUI
import SceneKit

/// Epic 3D visualization of the Bugtopia simulation
struct Arena3DView: NSViewRepresentable {
    let arena3D: Arena3D
    let bugs: [Bug]
    let territories3D: [Territory3D]
    @State private var sceneView: SCNView?
    @State private var cameraNode: SCNNode?
    @State private var isAnimating = true
    
    // Camera controls
    @State private var cameraPosition: SCNVector3 = SCNVector3(0, 200, 300)
    @State private var cameraRotation: SCNVector4 = SCNVector4(1, 0, 0, -0.3)
    
    func makeNSView(context: Context) -> SCNView {
        let sceneView = SCNView()
        self.sceneView = sceneView
        
        // Create the 3D scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Configure scene view
        sceneView.backgroundColor = NSColor.black
        sceneView.allowsCameraControl = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = false
        
        // Set up the epic 3D world
        setupScene(scene: scene)
        setupLighting(scene: scene)
        setupCamera(scene: scene)
        
        // Render the world
        renderTerrain(scene: scene)
        renderBugs(scene: scene)
        renderTerritories(scene: scene)
        
        // Set up automatic camera animation
        setupCameraAnimation(scene: scene)
        
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
        
        // Add physics world
        scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        scene.physicsWorld.speed = 0.5 // Slower for better visibility
    }
    
    private func setupLighting(scene: SCNScene) {
        // 🌞 EPIC SUN LIGHTING
        let sunLight = SCNLight()
        sunLight.type = .directional
        sunLight.color = NSColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        sunLight.intensity = 1500
        sunLight.castsShadow = true
        sunLight.shadowRadius = 3.0
        sunLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        sunLight.shadowMode = .deferred
        
        let sunNode = SCNNode()
        sunNode.light = sunLight
        sunNode.position = SCNVector3(200, 400, 200)
        sunNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sunNode)
        
        // 🌙 AMBIENT MOONLIGHT
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = NSColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0)
        ambientLight.intensity = 200
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // ✨ ATMOSPHERIC SCATTER
        let skyLight = SCNLight()
        skyLight.type = .omni
        skyLight.color = NSColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0)
        skyLight.intensity = 300
        
        let skyNode = SCNNode()
        skyNode.light = skyLight
        skyNode.position = SCNVector3(0, 500, 0)
        scene.rootNode.addChildNode(skyNode)
    }
    
    private func setupCamera(scene: SCNScene) {
        let camera = SCNCamera()
        camera.fieldOfView = 75
        camera.zNear = 1.0
        camera.zFar = 2000.0
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = cameraPosition
        cameraNode.rotation = cameraRotation
        
        scene.rootNode.addChildNode(cameraNode)
        self.cameraNode = cameraNode
    }
    
    // MARK: - Epic Terrain Rendering
    
    private func renderTerrain(scene: SCNScene) {
        print("🎨 Rendering EPIC 3D Terrain...")
        
        // Create terrain container
        let terrainContainer = SCNNode()
        terrainContainer.name = "TerrainContainer"
        scene.rootNode.addChildNode(terrainContainer)
        
        // Render each layer with spectacular visuals
        for layer in TerrainLayer.allCases {
            renderTerrainLayer(layer: layer, container: terrainContainer)
        }
        
        // Add particle effects for atmosphere
        addAtmosphericEffects(scene: scene)
    }
    
    private func renderTerrainLayer(layer: TerrainLayer, container: SCNNode) {
        guard let layerTiles = arena3D.tiles[layer] else { return }
        
        let layerContainer = SCNNode()
        layerContainer.name = "Layer_\(layer.rawValue)"
        container.addChildNode(layerContainer)
        
        print("🏔️ Rendering \(layer.rawValue) layer with \(layerTiles.count * (layerTiles.first?.count ?? 0)) tiles")
        
        for (rowIndex, tileRow) in layerTiles.enumerated() {
            for (colIndex, tile) in tileRow.enumerated() {
                let tileNode = createTileNode(tile: tile, row: rowIndex, col: colIndex)
                layerContainer.addChildNode(tileNode)
            }
        }
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
        print("🐛 Rendering \(bugs.count) EPIC 3D Bugs...")
        
        let bugContainer = SCNNode()
        bugContainer.name = "BugContainer"
        scene.rootNode.addChildNode(bugContainer)
        
        for bug in bugs {
            let bugNode = createBugNode(bug: bug)
            bugContainer.addChildNode(bugNode)
        }
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
        
        // Position bug in 3D space
        bugNode.position = SCNVector3(
            Float(bug.position3D.x),
            Float(bug.position3D.z),
            Float(bug.position3D.y)
        )
        
        // Add physics body
        bugNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        bugNode.physicsBody?.mass = 0.1
        bugNode.physicsBody?.categoryBitMask = 2
        bugNode.physicsBody?.collisionBitMask = 1
        
        // Add energy indicator
        addEnergyIndicator(to: bugNode, energy: bug.energy)
        
        return bugNode
    }
    
    private func createBugGeometry(for bug: Bug) -> SCNGeometry {
        let species = bug.dna.speciesTraits.speciesType
        let size = Float(bug.dna.size * 2.0) // Scale for visibility
        
        switch species {
        case .herbivore:
            let sphere = SCNSphere(radius: CGFloat(size))
            sphere.firstMaterial?.diffuse.contents = NSColor.green
            return sphere
            
        case .carnivore:
            let box = SCNBox(width: CGFloat(size * 1.5), height: CGFloat(size), length: CGFloat(size * 1.2), chamferRadius: 0.1)
            box.firstMaterial?.diffuse.contents = NSColor.red
            return box
            
        case .omnivore:
            let capsule = SCNCapsule(capRadius: CGFloat(size * 0.8), height: CGFloat(size * 1.5))
            capsule.firstMaterial?.diffuse.contents = NSColor.orange
            return capsule
            
        case .scavenger:
            let cylinder = SCNCylinder(radius: CGFloat(size * 0.7), height: CGFloat(size * 1.2))
            cylinder.firstMaterial?.diffuse.contents = NSColor.purple
            return cylinder
        }
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
        print("🏰 Rendering \(territories3D.count) EPIC 3D Territories...")
        
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
        // Add floating particles for atmosphere
        let atmosphereSystem = SCNParticleSystem()
        // Create a simple sparkle image
        let image = NSImage(size: NSSize(width: 6, height: 6))
        image.lockFocus()
        NSColor.white.setFill()
        let star = NSBezierPath()
        star.move(to: NSPoint(x: 3, y: 6))
        star.line(to: NSPoint(x: 2, y: 2))
        star.line(to: NSPoint(x: 0, y: 2))
        star.line(to: NSPoint(x: 2, y: 1))
        star.line(to: NSPoint(x: 1, y: 0))
        star.line(to: NSPoint(x: 3, y: 1))
        star.line(to: NSPoint(x: 5, y: 0))
        star.line(to: NSPoint(x: 4, y: 1))
        star.line(to: NSPoint(x: 6, y: 2))
        star.line(to: NSPoint(x: 4, y: 2))
        star.close()
        star.fill()
        image.unlockFocus()
        atmosphereSystem.particleImage = image
        atmosphereSystem.birthRate = 20
        atmosphereSystem.particleLifeSpan = 10.0
        atmosphereSystem.particleVelocity = 5
        atmosphereSystem.particleSize = 1.0
        atmosphereSystem.particleColor = NSColor(white: 1.0, alpha: 0.2)
        // Note: emissionShape is not available on macOS, particles will emit from point
        
        let atmosphereNode = SCNNode()
        atmosphereNode.addParticleSystem(atmosphereSystem)
        atmosphereNode.position = SCNVector3(0, 100, 0)
        scene.rootNode.addChildNode(atmosphereNode)
    }
    
    // MARK: - Animation and Updates
    
    private func setupCameraAnimation(scene: SCNScene) {
        guard let cameraNode = cameraNode else { return }
        
        // Create smooth camera orbit animation using SceneKit actions
        let radius: Float = 400
        let height: Float = 200
        let duration: TimeInterval = 60.0 // Complete orbit in 60 seconds
        
        // Create circular path for camera
        let orbitAction = SCNAction.customAction(duration: duration) { node, elapsedTime in
            let angle = Float(elapsedTime / duration * 2 * Double.pi)
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            
            node.position = SCNVector3(x, height, z)
            node.look(at: SCNVector3(0, 0, 0))
        }
        
        // Repeat the orbit forever
        let repeatOrbit = SCNAction.repeatForever(orbitAction)
        cameraNode.runAction(repeatOrbit)
    }
    
    private func updateBugPositions(scene: SCNScene) {
        guard let bugContainer = scene.rootNode.childNode(withName: "BugContainer", recursively: false) else { return }
        
        for bug in bugs {
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
        for territory in territories3D {
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
}
