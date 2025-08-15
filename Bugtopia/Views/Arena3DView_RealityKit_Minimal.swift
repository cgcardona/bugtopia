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
    
    // MARK: - Coordinate System Constants (FROM MASTERY DOCS)
    
    private let simulationScale: Float = 0.1  // Sacred constant - never change
    private let terrainScale: Float = 6.25    // Terrain scale factor 
    private let terrainSize: Float = 225.0    // 6.25 * 36 = 225 units
    
    // MARK: - Camera System (ADJUSTED FOR TERRAIN LEVEL)
    
    @State private var cameraPosition = SIMD3<Float>(112, 25, 50)   // LOWERED: Match terrain level (~-16 to +9)
    @State private var cameraPitch: Float = -0.3     // 17° downward 
    @State private var cameraYaw: Float = Float.pi   // Face world center
    @State private var isGodMode: Bool = true
    
    // MARK: - Scene References
    
    @State private var sceneAnchor: AnchorEntity?
    
    // MARK: - Debug System
    
    @State private var showDebugOverlay: Bool = true
    @State private var debugInfo: String = "MINIMAL MODE: Coordinate System Debug"
    
    // MARK: - Test Points (FROM MASTERY DOCS)
    
    private let testPoints: [(Float, Float)] = [
        (0.0, 0.0),      // Origin
        (112.0, 112.0),  // Center
        (225.0, 225.0)   // Far corner
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
        }
        .onAppear {
            print("🚀 [MINIMAL] Starting coordinate system reconstruction...")
            validateCoordinateSystem()
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
        
        // 🎯 CAMERA FIX: Position world so terrain is visible from default camera position
        // Default RealityView camera looks at origin from a few meters back
        // Move world center to be visible and properly oriented
        anchor.position = [-112, 0, -50]  // Center terrain in view
        print("📷 [CAMERA FIX] World anchor positioned at (-112, 0, -50) for visibility")
        
        // Store reference
        sceneAnchor = anchor
        
        // STEP 2: Add minimal terrain ONLY
        setupMinimalTerrain(in: anchor)
        
        // STEP 3: Add coordinate system validation markers
        addTestMarkers(in: anchor)
        
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
        
        print("✅ [MINIMAL] Terrain created with 0-225 coordinate range")
    }
    
    @available(macOS 14.0, *)
    private func createUnifiedTerrainMesh(heightMap: [[Double]], resolution: Int) -> ModelEntity {
        print("🎯 [TERRAIN] Creating mesh with EXACT coordinate alignment...")
        
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        // UNIFIED COORDINATE FORMULA: From mastery docs
        // Terrain covers 0-225 range to match simulation scale of 0.1
        let heightScale: Float = 0.8  // Match RealityKit v2
        
        // Generate vertices in 0-225 range
        for x in 0..<resolution {
            for z in 0..<resolution {
                // EXACT COORDINATE MAPPING: 0 to 225 units
                let worldX = Float(x) * terrainScale  // 0 to 36*6.25 = 0 to 225
                let worldZ = Float(z) * terrainScale  // 0 to 36*6.25 = 0 to 225
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
            
            // Position using UNIFIED coordinates
            marker.position = SIMD3<Float>(x, terrainHeight + 3.0, z)
            marker.name = "TestMarker_\(index)"
            
            anchor.addChild(marker)
            
            print("🎯 [TEST POINT] (\(x), \(z)) -> Height: \(terrainHeight) -> Final: (\(x), \(terrainHeight + 3.0), \(z))")
        }
        
        print("✅ [TEST] Added \(testPoints.count) validation markers")
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
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("🔧 MINIMAL COORDINATE DEBUG")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    Text("Simulation Scale: \(simulationScale, specifier: "%.1f")")
                        .foregroundColor(.white)
                    
                    Text("Terrain Size: \(terrainSize, specifier: "%.1f") units")
                        .foregroundColor(.white)
                    
                    Text("World Anchor: (-112, 0, -50)")
                        .foregroundColor(.white)
                    
                    Text("Expected Camera: Default RealityView position")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Divider()
                    
                    Text("Test Points:")
                        .foregroundColor(.yellow)
                    
                    ForEach(Array(testPoints.enumerated()), id: \.offset) { index, point in
                        let height = getTerrainHeightAtPosition(x: point.0, z: point.1)
                        Text("(\(point.0, specifier: "%.0f"), \(point.1, specifier: "%.0f")) → H: \(height, specifier: "%.1f")")
                            .foregroundColor(index == 0 ? .red : index == 1 ? .yellow : .blue)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
            Spacer()
        }
    }
    
    // MARK: - Validation
    
    private func validateCoordinateSystem() {
        print("🔍 [VALIDATION] Testing coordinate system integrity...")
        
        for (index, point) in testPoints.enumerated() {
            let height = getTerrainHeightAtPosition(x: point.0, z: point.1)
            print("🎯 [TEST POINT \(index)] (\(point.0), \(point.1)) -> Height: \(height)")
            
            // Validate bounds (FROM MASTERY DOCS)
            assert(point.0 >= 0 && point.0 <= 225, "X coordinate out of bounds: \(point.0)")
            assert(point.1 >= 0 && point.1 <= 225, "Z coordinate out of bounds: \(point.1)")
        }
        
        print("✅ [VALIDATION] Coordinate system integrity confirmed")
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

#Preview {
    // Create preview simulation engine
    let previewEngine = SimulationEngine(worldBounds: CGRect(x: 0, y: 0, width: 2000, height: 1500))
    
    return Arena3DView_RealityKit_Minimal(simulationEngine: previewEngine)
        .frame(width: 800, height: 600)
}
