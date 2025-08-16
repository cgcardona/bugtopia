//
//  Arena3DView_RealityKit_Minimal.swift
//  Bugtopia
//
//  Created by AI Developer on 12/20/24.
//  MINIMAL COORDINATE SYSTEM FOUNDATION
//

import SwiftUI
import RealityKit
import simd

/// 🔧 MINIMAL: "Hello World" RealityKit Implementation
/// This is a bare-bones coordinate system foundation to rebuild from first principles
struct Arena3DView_RealityKit_Minimal: View {
    
    // MARK: - Core Dependencies
    
    let simulationEngine: SimulationEngine
    
    // MARK: - Coordinate System Constants (SQUARED SYSTEM!)
    
    private let simulationScale: Float = 0.1  // Sacred constant - never change
    private let terrainScale: Float = 6.25    // Terrain scale factor 
    private let terrainSize: Float = 200.0    // 🟫 SQUARED: 2000 * 0.1 = 200 units (PERFECT MATCH!)
    
    // MARK: - Camera System (ADVANCED NAVIGATION)
    
    @State private var cameraPosition = SIMD3<Float>(112, 25, 50)   // LOWERED: Match terrain level (~-16 to +9)
    @State private var cameraPitch: Float = -0.3     // 17° downward 
    @State private var cameraYaw: Float = Float.pi   // Face world center
    @State private var isGodMode: Bool = true
    @State private var isFlightMode: Bool = true     // true = fly, false = walk
    private let movementSpeed: Float = 10.0          // Units per key press
    private let lookSpeed: Float = 0.1               // Radians per key press
    
    // MARK: - Scene References
    
    @State private var sceneAnchor: AnchorEntity?
    
    // MARK: - Debug System
    
    @State private var showDebugOverlay: Bool = true
    @State private var debugInfo: String = "MINIMAL MODE: Coordinate System Debug"
    
    // MARK: - Test Points (FROM MASTERY DOCS)
    
    private let testPoints: [(Float, Float)] = [
        (0.0, 0.0),      // Origin
        (100.0, 100.0),  // Center of SQUARE terrain (200/2 = 100)
        (200.0, 200.0)   // Far corner of SQUARE terrain
    ]
    
    init(simulationEngine: SimulationEngine) {
        self.simulationEngine = simulationEngine
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main 3D content
            if #available(macOS 14.0, *) {
                minimalRealityView
            } else {
                Text("RealityKit requires macOS 14.0+")
                    .foregroundColor(.red)
            }
            
            // Debug overlay
            if showDebugOverlay {
                minimalDebugOverlay
            }
            
            // Navigation instructions
            navigationInstructions
        }
        .onAppear {
            print("🚀 [MINIMAL] Starting coordinate system reconstruction...")
            validateCoordinateSystem()
        }
        .onTapGesture {
            // For now, tapping moves camera to see different areas
            moveToNextViewpoint()
        }
        .onKeyPress(.init("r")) {
            // Reset to origin for debugging
            if let anchor = sceneAnchor {
                anchor.position = [0, 0, 0]
                currentViewpoint = 0
                print("🔄 [RESET] World anchor reset to origin (0, 0, 0)")
            }
            return .handled
        }
        .onKeyPress(.init(" ")) {
            // Spacebar: Toggle between fly and walk modes
            isFlightMode.toggle()
            print("🎮 [MODE] Switched to \(isFlightMode ? "FLY" : "WALK") mode")
            return .handled
        }
        .onKeyPress(.init("w")) {
            moveCamera(direction: .forward)
            return .handled
        }
        .onKeyPress(.init("a")) {
            moveCamera(direction: .left)
            return .handled
        }
        .onKeyPress(.init("s")) {
            moveCamera(direction: .backward)
            return .handled
        }
        .onKeyPress(.init("d")) {
            moveCamera(direction: .right)
            return .handled
        }
        .onKeyPress(.init("q")) {
            moveCamera(direction: .up)
            return .handled
        }
        .onKeyPress(.init("e")) {
            moveCamera(direction: .down)
            return .handled
        }
        .onKeyPress(.upArrow) {
            lookCamera(direction: .up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            lookCamera(direction: .down)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            lookCamera(direction: .left)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            lookCamera(direction: .right)
            return .handled
        }
    }
    
    // MARK: - Minimal RealityView
    
    @available(macOS 14.0, *)
    private var minimalRealityView: some View {
        RealityView { content in
            setupMinimalWorld(content)
        }
    }
    
    // MARK: - Minimal World Setup
    
    @available(macOS 14.0, *)
    private func setupMinimalWorld(_ content: any RealityViewContentProtocol) {
        print("🌍 [MINIMAL] Building minimal world with unified coordinates...")
        
        // STEP 1: Create world anchor positioned for camera visibility
        let anchor = AnchorEntity(.world(transform: Transform.identity.matrix))
        anchor.name = "MinimalWorldAnchor"
        
        // 🎯 CAMERA FIX: Position world so SQUARED terrain is visible from default camera position
        // Default RealityView camera looks at origin from a few meters back  
        // Move world center to be visible and properly oriented
        anchor.position = [0, 0, 0]  // Keep world at origin, camera moves instead
        print("📷 [CAMERA FIX] World anchor at origin (0, 0, 0) - camera controls view")
        
        // Store reference
        sceneAnchor = anchor
        
        // STEP 2: Add minimal terrain ONLY
        setupMinimalTerrain(in: anchor)
        
        // STEP 3: Add comprehensive coordinate mastery demonstration
        print("🎯 [DEBUG] About to call addCoordinateMasteryDemo...")
        addCoordinateMasteryDemo(in: anchor)
        print("🎯 [DEBUG] addCoordinateMasteryDemo completed")
        
        // EMERGENCY DEBUG: Add super simple red cube at origin
        print("🚨 [EMERGENCY] Adding simple debug cube at origin...")
        let debugCube = ModelEntity(mesh: .generateBox(size: 50.0), materials: [SimpleMaterial(color: .red, isMetallic: false)])
        debugCube.position = SIMD3<Float>(0, 25, 0)  // Right at origin, elevated
        anchor.addChild(debugCube)
        print("🚨 [EMERGENCY] Debug cube added at (0, 25, 0)")
        
        // STEP 4: Add basic lighting
        setupMinimalLighting(in: anchor)
        
        // Add to scene
        content.add(anchor)
        
        print("✅ [MINIMAL] World created with NO coordinate offsets")
    }
    
    // MARK: - Minimal Terrain
    
    @available(macOS 14.0, *)
    private func setupMinimalTerrain(in anchor: Entity) {
        print("🏔️ [MINIMAL] Creating terrain with UNIFIED coordinate system...")
        
        let voxelWorld = simulationEngine.voxelWorld
        let heightMap = voxelWorld.heightMap
        let resolution = heightMap.count
        
        // Create smooth terrain mesh using EXACT coordinates from mastery docs
        let terrainEntity = createUnifiedTerrainMesh(heightMap: heightMap, resolution: resolution)
        terrainEntity.name = "UnifiedTerrain"
        
        anchor.addChild(terrainEntity)
        
        // Test terrain height calculation immediately
        testTerrainHeightCalculation()
        
        print("✅ [MINIMAL] Terrain created with 0-200 SQUARED coordinate range")
    }
    
    @available(macOS 14.0, *)
    private func createUnifiedTerrainMesh(heightMap: [[Double]], resolution: Int) -> ModelEntity {
        print("🎯 [TERRAIN] Creating mesh with EXACT coordinate alignment...")
        
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        // UNIFIED COORDINATE FORMULA: SQUARED SYSTEM!
        // Terrain covers 0-200 range to match simulation scale of 0.1 (2000*0.1=200)
        let heightScale: Float = 0.8  // Match RealityKit v2
        
        // Generate vertices in 0-200 range (SQUARED!)
        for x in 0..<resolution {
            for z in 0..<resolution {
                // EXACT COORDINATE MAPPING: 0 to 200 units (SQUARED!)
                let worldX = Float(x) * terrainScale  // 0 to 32*6.25 = 0 to 200
                let worldZ = Float(z) * terrainScale  // 0 to 32*6.25 = 0 to 200
                let worldY = Float(heightMap[x][z]) * heightScale
                
                vertices.append(SIMD3<Float>(worldX, worldY, worldZ))
            }
        }
        
        // Generate triangle indices
        for x in 0..<(resolution-1) {
            for z in 0..<(resolution-1) {
                let i0 = UInt32(x * resolution + z)
                let i1 = UInt32((x + 1) * resolution + z)
                let i2 = UInt32(x * resolution + (z + 1))
                let i3 = UInt32((x + 1) * resolution + (z + 1))
                
                // Triangle 1
                indices.append(contentsOf: [i0, i1, i2])
                
                // Triangle 2  
                indices.append(contentsOf: [i1, i3, i2])
            }
        }
        
        // Create mesh
        var meshDescriptor = MeshDescriptor(name: "UnifiedTerrain")
        meshDescriptor.positions = MeshBuffers.Positions(vertices)
        meshDescriptor.primitives = .triangles(indices)
        
        let mesh = try! MeshResource.generate(from: [meshDescriptor])
        
        // Bright green material for visibility
        var material = SimpleMaterial()
        material.color = .init(tint: .green)
        material.roughness = 0.6
        material.metallic = 0.1
        
        let terrainEntity = ModelEntity(mesh: mesh, materials: [material])
        
        return terrainEntity
    }
    
    // MARK: - Test Markers
    
    @available(macOS 14.0, *)
    private func addTestMarkers(in anchor: Entity) {
        print("🎯 [TEST] Adding coordinate validation markers...")
        
        for (index, point) in testPoints.enumerated() {
            let x = point.0
            let z = point.1
            
            // Get terrain height using UNIFIED system
            let terrainHeight = getTerrainHeightAtPosition(x: x, z: z)
            
            // Create large, bright marker 
            let marker = ModelEntity(
                mesh: .generateSphere(radius: 5.0),  // Larger for visibility
                materials: [SimpleMaterial(color: index == 0 ? .red : index == 1 ? .yellow : .blue, isMetallic: false)]
            )
            
            // Position using UNIFIED coordinates - elevated for visibility
            marker.position = SIMD3<Float>(x, terrainHeight + 10.0, z)  // Higher above terrain
            marker.name = "TestMarker_\(index)"
            
            anchor.addChild(marker)
            
            print("🎯 [TEST POINT] (\(x), \(z)) -> Height: \(terrainHeight) -> Final: (\(x), \(terrainHeight + 3.0), \(z))")
        }
        
        print("✅ [TEST] Added \(testPoints.count) validation markers")
    }
    
    // MARK: - Central Test Cube
    
    @available(macOS 14.0, *)
    private func addCentralTestCube(in anchor: Entity) {
        // Bright cube at world center for immediate visibility test
        let cube = ModelEntity(
            mesh: .generateBox(size: 10.0),  // Large cube
            materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )
        
        // Position near camera view for immediate visibility
        cube.position = SIMD3<Float>(0, 10, -20)  // In front of camera view
        cube.name = "CentralTestCube"
        
        anchor.addChild(cube)
        
        print("🟥 [TEST CUBE] Added bright red cube at (0, 10, -20) for visibility test")
    }
    
    // MARK: - Coordinate Mastery Demonstration
    
    @available(macOS 14.0, *)
    private func addCoordinateMasteryDemo(in anchor: Entity) {
        print("🎯 [DEBUG] Starting addCoordinateMasteryDemo...")
        print("🎯 [DEBUG] Anchor received: \(anchor)")
        
        // SINGLE OBJECT FOCUS - One bright red cube at world center for systematic testing
        let demoObjects: [(position: SIMD3<Float>, shape: String, color: NSColor, size: Float, name: String)] = [
            // ONE BRIGHT RED CUBE at world center (100, 50, 100)
            (SIMD3<Float>(100, 50, 100), "cube", .red, 30.0, "TARGET: Red Cube at World Center")
        ]
        
        print("🎯 [DEBUG] Demo objects array created with \(demoObjects.count) objects")
        
        // Create and position each demo object
        for (index, demo) in demoObjects.enumerated() {
            print("🎯 [DEBUG] Creating object \(index): \(demo.name)")
            print("🎯 [DEBUG] Target position: \(demo.position)")
            
            let entity = createGeometricShape(
                shape: demo.shape,
                size: demo.size,
                color: demo.color,
                name: "\(index): \(demo.name)"
            )
            
            print("🎯 [DEBUG] Entity created: \(entity)")
            
            // Get terrain height at this position for proper ground-following
            let terrainHeight = getTerrainHeightAtPosition(x: demo.position.x, z: demo.position.z)
            print("🎯 [DEBUG] Terrain height at (\(demo.position.x), \(demo.position.z)): \(terrainHeight)")
            
            let finalPosition = SIMD3<Float>(
                demo.position.x,
                max(demo.position.y, terrainHeight + demo.size/2), // Ensure above terrain
                demo.position.z
            )
            
            print("🎯 [DEBUG] Final position: \(finalPosition)")
            
            entity.position = finalPosition
            anchor.addChild(entity)
            
            print("🎯 [DEBUG] Entity added to anchor successfully")
            print("🎨 [DEMO \(index)] \(demo.name): \(demo.shape) at (\(finalPosition.x), \(finalPosition.y), \(finalPosition.z))")
        }
        
        print("✅ [PRECISION COORDINATE MASTERY] Created \(demoObjects.count) targeted objects for perfect viewpoint alignment")
    }
    
    @available(macOS 14.0, *)
    private func createGeometricShape(shape: String, size: Float, color: NSColor, name: String) -> ModelEntity {
        let mesh: MeshResource
        
        switch shape.lowercased() {
        case "cube":
            mesh = .generateBox(size: size)
        case "sphere":
            mesh = .generateSphere(radius: size/2)
        case "cylinder":
            mesh = .generateCylinder(height: size * 1.5, radius: size/3)  // Taller cylinders
        case "pyramid":
            // Create a simple pyramid using box with custom scaling
            mesh = .generateBox(size: size)
        default:
            mesh = .generateBox(size: size)
        }
        
        // Create bright, non-metallic material
        var material = SimpleMaterial()
        material.color = .init(tint: color)
        material.roughness = 0.2  // Less rough = more reflective
        material.metallic = 0.0   // Not metallic
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        
        // For pyramids, add a distinct rotation to make them stand out
        if shape.lowercased() == "pyramid" {
            entity.transform.rotation = simd_quatf(angle: Float.pi/4, axis: [0, 1, 0])
            entity.transform.scale = SIMD3<Float>(1.0, 2.0, 1.0)  // Make pyramids taller
        }
        
        return entity
    }
    
    // MARK: - Terrain Height Calculation (FROM MASTERY DOCS)
    
    private func getTerrainHeightAtPosition(x: Float, z: Float) -> Float {
        let voxelWorld = simulationEngine.voxelWorld
        let heightMap = voxelWorld.heightMap
        let resolution = heightMap.count
        
        // EXACT FORMULA FROM MASTERY DOCS
        let normalizedX = x / terrainSize  // 0-1 range, origin-based
        let normalizedZ = z / terrainSize
        
        // Clamp to valid range
        let clampedX = max(0, min(0.99, normalizedX))
        let clampedZ = max(0, min(0.99, normalizedZ))
        
        let mapX = Int(clampedX * Float(resolution))
        let mapZ = Int(clampedZ * Float(resolution))
        
        let height = heightMap[mapX][mapZ]
        let scaledHeight = Float(height) * 0.8  // Match heightScale
        
        return scaledHeight
    }
    
    // MARK: - Lighting
    
    @available(macOS 14.0, *)
    private func setupMinimalLighting(in anchor: Entity) {
        // Strong directional light from above
        let sunLight = DirectionalLight()
        sunLight.light.intensity = 2500  // Brighter
        sunLight.position = [0, 100, 0]  // Directly above center
        sunLight.look(at: [0, 0, 0], from: sunLight.position, relativeTo: nil)
        anchor.addChild(sunLight)
        
        // Ambient light for fill lighting
        let ambientLight = DirectionalLight()
        ambientLight.light.intensity = 800
        ambientLight.position = [50, 50, 50]
        ambientLight.look(at: [0, 0, 0], from: ambientLight.position, relativeTo: nil)
        anchor.addChild(ambientLight)
        
        print("💡 [MINIMAL] Enhanced lighting added (sun + ambient)")
    }
    
    // MARK: - Debug Overlay
    
    private var minimalDebugOverlay: some View {
        VStack {
            HStack {
                // Compact main header
                VStack(alignment: .leading, spacing: 2) {
                    Text("🎯 PRECISION COORDINATE MASTERY")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    Text("1 Red Cube | Systematic Orbiting")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.75))
                .cornerRadius(6)
                
                Spacer()
                
                // Compact viewpoint indicator
                Text("Viewpoint \(currentViewpoint)/7")
                    .foregroundColor(.yellow)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(4)
            }
            .padding(.top, 8)
            .padding(.horizontal, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Navigation Instructions
    
    private var navigationInstructions: some View {
        VStack {
            Spacer()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎮 ADVANCED NAVIGATION")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    Text("WASD: Move | QE: Up/Down | Arrows: Look")
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Text("Space: Toggle \(isFlightMode ? "FLY" : "WALK") mode")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Click: Cycle viewpoints | R: Reset")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Simple Navigation
    
    @State private var currentViewpoint = 0
    
    private func moveToNextViewpoint() {
        guard let anchor = sceneAnchor else { return }
        
        // OPTIMIZED world positions for better viewing angles
        // Adjusted heights to prevent looking up from below terrain
        // CORRECTED CAMERA POSITIONS to see EMERGENCY CUBE at (0, 25, 0) and RED CUBE at (100, 50, 100)
        let worldPositions: [SIMD3<Float>] = [
            [0, -25, -50],     // 0: Look at EMERGENCY cube at origin from front
            [0, -25, -30],     // 1: Look at EMERGENCY cube - closer view
            [-100, -50, -80],  // 2: Look at RED cube from front  
            [-100, -50, -120], // 3: Look at RED cube from behind
            [-80, -50, -100],  // 4: Look at RED cube from right
            [-120, -50, -100], // 5: Look at RED cube from left
            [-100, -30, -100], // 6: Look at RED cube from above
            [-100, -70, -100]  // 7: Look at RED cube from below
        ]
        
        currentViewpoint = (currentViewpoint + 1) % worldPositions.count
        anchor.position = worldPositions[currentViewpoint]
        
        // PRECISION DESCRIPTIONS - Exactly what should be visible
        // CORRECTED DESCRIPTIONS - Emergency cube at (0,25,0) and Red cube at (100,50,100)
        let viewpointDescriptions = [
            "EMERGENCY CUBE: Large red cube (50 units) at origin should FILL screen",
            "EMERGENCY CUBE: Same red cube at origin but closer view",
            "RED CUBE: Target red cube (30 units) at (100,50,100) from front", 
            "RED CUBE: Target red cube at (100,50,100) from behind",
            "RED CUBE: Target red cube at (100,50,100) from right side",
            "RED CUBE: Target red cube at (100,50,100) from left side",
            "RED CUBE: Target red cube at (100,50,100) from above",
            "RED CUBE: Target red cube at (100,50,100) from below"
        ]
        
        print("📷 [VIEWPOINT \(currentViewpoint)] World moved to: \(worldPositions[currentViewpoint])")
        print("👁️ [EXPECTED] \(viewpointDescriptions[currentViewpoint])")
    }
    
    // MARK: - Validation
    
    private func validateCoordinateSystem() {
        print("🔍 [VALIDATION] Testing coordinate system integrity...")
        
        for (index, point) in testPoints.enumerated() {
            let height = getTerrainHeightAtPosition(x: point.0, z: point.1)
            print("🎯 [TEST POINT \(index)] (\(point.0), \(point.1)) -> Height: \(height)")
            
            // Validate bounds (SQUARED SYSTEM!)
            assert(point.0 >= 0 && point.0 <= 200, "X coordinate out of bounds: \(point.0)")
            assert(point.1 >= 0 && point.1 <= 200, "Z coordinate out of bounds: \(point.1)")
        }
        
        print("✅ [VALIDATION] Coordinate system integrity confirmed")
    }
    
    // MARK: - Advanced Camera Movement
    
    enum CameraDirection {
        case forward, backward, left, right, up, down
    }
    
    private func moveCamera(direction: CameraDirection) {
        guard let anchor = sceneAnchor else { return }
        
        let currentPos = anchor.position
        var newPos = currentPos
        
        // FIXED: Use axis-aligned movement vectors for proper WASD navigation
        switch direction {
        case .forward:
            newPos.z += movementSpeed             // Move world forward (camera forward)
        case .backward:
            newPos.z -= movementSpeed             // Move world backward (camera backward)
        case .left:
            newPos.x += movementSpeed             // Move world left (camera left)
        case .right:
            newPos.x -= movementSpeed             // Move world right (camera right)
        case .up:
            newPos.y -= movementSpeed             // Move world down (camera up)
        case .down:
            if isFlightMode {
                newPos.y += movementSpeed         // Move world up (camera down)
            } else {
                // In walk mode, follow terrain height
                let terrainHeight = getTerrainHeightAtPosition(x: -newPos.x, z: -newPos.z)
                newPos.y = -(terrainHeight + 10.0)  // Stay 10 units above terrain
            }
        }
        
        // Apply movement
        anchor.position = newPos
        
        // In walk mode, always adjust Y to follow terrain
        if !isFlightMode {
            let terrainHeight = getTerrainHeightAtPosition(x: -newPos.x, z: -newPos.z)
            anchor.position.y = -(terrainHeight + 10.0)  // Stay 10 units above terrain
        }
        
        print("🎮 [MOVE] \(direction) in \(isFlightMode ? "FLY" : "WALK") mode -> Position: \(anchor.position)")
    }
    
    private func lookCamera(direction: CameraDirection) {
        switch direction {
        case .up:
            cameraPitch = max(cameraPitch - lookSpeed, -Float.pi/2)  // Look up (pitch down)
        case .down:
            cameraPitch = min(cameraPitch + lookSpeed, Float.pi/2)   // Look down (pitch up)
        case .left:
            cameraYaw -= lookSpeed                                   // Look left
        case .right:
            cameraYaw += lookSpeed                                   // Look right
        default:
            break  // forward/backward don't apply to looking
        }
        
        // Normalize yaw to 0-2π
        if cameraYaw < 0 { cameraYaw += 2 * Float.pi }
        if cameraYaw > 2 * Float.pi { cameraYaw -= 2 * Float.pi }
        
        print("🎮 [LOOK] \(direction) -> Pitch: \(cameraPitch), Yaw: \(cameraYaw)")
        
        // FIXED: Apply rotation to the world anchor for actual visual changes
        if let anchor = sceneAnchor {
            // Create rotation transform from pitch and yaw
            let pitchRotation = simd_quatf(angle: cameraPitch, axis: SIMD3<Float>(1, 0, 0))  // X-axis rotation
            let yawRotation = simd_quatf(angle: cameraYaw, axis: SIMD3<Float>(0, 1, 0))      // Y-axis rotation
            
            // Combine rotations: yaw first, then pitch
            let combinedRotation = pitchRotation * yawRotation
            
            // Apply rotation to anchor
            anchor.orientation = combinedRotation
            
            print("🎮 [ROTATION] Applied rotation - Pitch: \(cameraPitch), Yaw: \(cameraYaw)")
        }
    }
    
    private func testTerrainHeightCalculation() {
        print("🏔️ [TERRAIN TEST] Validating height calculation...")
        
        // Test height calculation on a few points
        for point in testPoints {
            let height = getTerrainHeightAtPosition(x: point.0, z: point.1)
            print("🏔️ [HEIGHT] (\(point.0), \(point.1)) -> \(height)")
        }
    }
}
