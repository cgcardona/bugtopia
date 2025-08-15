//
//  AAAPLumGeometry.swift
//  Bugtopia
//
//  AAA-Quality Procedural Plum Generation System
//  Creates photorealistic plum geometry with proper topology and UV mapping
//

import Foundation
import RealityKit
import Metal

@available(macOS 14.0, *)
class AAAFoodGeometry {
    
    // MARK: - AAA Food Generation
    
    /// Creates AAA food geometry based on food type
    /// - Parameter foodType: The type of food to generate
    /// - Returns: High-quality food mesh optimized for mobile AR
    static func createAAAFoodMesh(for foodType: FoodType) -> MeshResource {
        switch foodType {
        case .plum:
            return createAAAPlumMesh()
        case .apple:
            return createAAAAppleMesh()
        case .orange:
            return createAAAOrangeMesh()
        case .melon:
            return createAAAMelonMesh()
        case .meat:
            return createAAAMeatMesh()
        case .fish:
            return createAAAFishMesh()
        case .seeds:
            return createAAASeedsMesh()
        case .nuts:
            return createAAANutsMesh()
        }
    }
    
    // MARK: - Individual Food Geometries
    
    /// Creates a photorealistic plum with proper topology and UV coordinates
    /// - Parameters:
    ///   - segments: Number of horizontal segments (more = smoother)
    ///   - rings: Number of vertical rings (more = smoother)  
    ///   - asymmetry: Natural plum asymmetry factor (0.0 = perfect sphere, 0.2 = realistic)
    ///   - stemIndent: Whether to create natural stem indentation
    /// - Returns: High-quality plum mesh optimized for mobile AR
    static func createAAAPLumMesh(
        segments: Int = 32,
        rings: Int = 16, 
        asymmetry: Float = 0.15,
        stemIndent: Bool = true
    ) -> MeshResource {
        
        print("🍇 [AAA] Generating photorealistic plum geometry...")
        print("📐 [AAA] Segments: \(segments), Rings: \(rings), Asymmetry: \(asymmetry)")
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        // 🍇 PLUM SHAPE PARAMETERS: Based on real plum proportions
        let baseRadius: Float = 1.0
        let heightScale: Float = 1.1  // Plums are slightly taller than wide
        let stemIndentDepth: Float = stemIndent ? 0.3 : 0.0
        let stemIndentRadius: Float = 0.4
        
        // 🎨 GENERATE VERTICES WITH NATURAL PLUM SHAPE
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * heightScale
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC SPHERICAL COORDINATES
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius
                var currentY = y
                
                // 🍇 NATURAL PLUM ASYMMETRY: Slightly flatten one side
                let asymmetryFactor = 1.0 + asymmetry * sin(segmentAngle * 2.0) * 0.5
                x *= asymmetryFactor
                z *= asymmetryFactor * 0.95  // Plums are slightly narrower front-to-back
                
                // 🌿 STEM INDENT: Create natural top indentation
                if stemIndent && ring < rings / 4 {
                    let distanceFromCenter = sqrt(x * x + z * z)
                    if distanceFromCenter < stemIndentRadius {
                        let indentFactor = (stemIndentRadius - distanceFromCenter) / stemIndentRadius
                        currentY -= stemIndentDepth * indentFactor * indentFactor
                    }
                }
                
                // 🍇 NATURAL PLUM CREASE: Subtle vertical indentation
                let creaseDepth: Float = 0.05
                let creaseWidth: Float = 0.3
                let creaseAngle = segmentAngle + Float.pi  // Opposite side from asymmetry
                let creaseDistance = abs(sin(creaseAngle * 0.5))
                if creaseDistance < creaseWidth {
                    let creaseFactor = (creaseWidth - creaseDistance) / creaseWidth
                    x *= (1.0 - creaseDepth * creaseFactor)
                    z *= (1.0 - creaseDepth * creaseFactor * 0.5)
                }
                
                let vertex = SIMD3<Float>(x, currentY, z)
                vertices.append(vertex)
                
                // 🔆 CALCULATE NORMALS: Smooth surface normals for realistic lighting
                let normal = normalize(vertex)
                normals.append(normal)
                
                // 🗺️ UV MAPPING: Perfect texture coordinate mapping
                let u = Float(segment) / Float(segments)
                let v = Float(ring) / Float(rings)
                uvs.append(SIMD2<Float>(u, v))
            }
        }
        
        // 🔗 GENERATE INDICES: Create triangular faces with proper winding
        for ring in 0..<rings {
            for segment in 0..<segments {
                let current = ring * (segments + 1) + segment
                let next = current + segments + 1
                
                // Create two triangles per quad with consistent winding
                // Triangle 1
                indices.append(UInt32(current))
                indices.append(UInt32(next))
                indices.append(UInt32(current + 1))
                
                // Triangle 2  
                indices.append(UInt32(current + 1))
                indices.append(UInt32(next))
                indices.append(UInt32(next + 1))
            }
        }
        
        print("✅ [AAA] Generated plum: \(vertices.count) vertices, \(indices.count/3) triangles")
        print("🎯 [AAA] Performance: \(indices.count/3) triangles (target: <1000)")
        
        // 🚀 CREATE REALITYKIT MESH with proper vertex attributes
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            print("🏆 [AAA] Plum mesh generation complete!")
            return mesh
        } catch {
            print("❌ [AAA] Mesh generation failed: \(error)")
            // Fallback to basic sphere
            return .generateSphere(radius: 1.0)
        }
    }
    
    /// Creates a photorealistic apple with proper topology and UV coordinates
    /// - Returns: High-quality apple mesh with natural apple shape
    static func createAAAAppleMesh() -> MeshResource {
        print("🍎 [AAA] Generating photorealistic apple geometry...")
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 32
        let rings = 16
        
        // 🍎 APPLE SHAPE PARAMETERS: Classic apple proportions
        let baseRadius: Float = 1.0
        let heightScale: Float = 1.2  // Apples are taller than wide
        let waistPosition: Float = 0.6  // Where the apple narrows (60% up)
        let waistFactor: Float = 0.85  // How much it narrows at waist
        let stemIndentDepth: Float = 0.4  // Deep stem indent
        let stemIndentRadius: Float = 0.3  // Narrow stem area
        
        // 🎨 GENERATE VERTICES WITH NATURAL APPLE SHAPE
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * heightScale
            
            // 🍎 APPLE WAIST: Narrow in the middle like real apples
            var radiusMultiplier: Float = 1.0
            let normalizedY = (y + heightScale) / (2.0 * heightScale) // 0 to 1
            
            if normalizedY > waistPosition {
                // Upper section: gradually narrow toward stem
                let waistProgress = (normalizedY - waistPosition) / (1.0 - waistPosition)
                radiusMultiplier = waistFactor + (1.0 - waistFactor) * (1.0 - waistProgress * 0.8)
            }
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC SPHERICAL COORDINATES WITH APPLE WAIST
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius * radiusMultiplier
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius * radiusMultiplier
                var currentY = y
                
                // 🍎 STEM INDENT: Create characteristic apple top indentation
                if ring < rings / 4 {
                    let distanceFromCenter = sqrt(x * x + z * z)
                    if distanceFromCenter < stemIndentRadius {
                        let indentFactor = (stemIndentRadius - distanceFromCenter) / stemIndentRadius
                        currentY -= stemIndentDepth * indentFactor * indentFactor
                    }
                }
                
                let vertex = SIMD3<Float>(x, currentY, z)
                vertices.append(vertex)
                
                // 🔆 CALCULATE NORMALS: Smooth surface normals for realistic lighting
                let normal = normalize(vertex)
                normals.append(normal)
                
                // 🗺️ UV MAPPING: Perfect texture coordinate mapping
                let u = Float(segment) / Float(segments)
                let v = Float(ring) / Float(rings)
                uvs.append(SIMD2<Float>(u, v))
            }
        }
        
        // 🔗 GENERATE INDICES: Create triangular faces
        for ring in 0..<rings {
            for segment in 0..<segments {
                let current = ring * (segments + 1) + segment
                let next = current + segments + 1
                
                // Triangle 1
                indices.append(UInt32(current))
                indices.append(UInt32(next))
                indices.append(UInt32(current + 1))
                
                // Triangle 2
                indices.append(UInt32(current + 1))
                indices.append(UInt32(next))
                indices.append(UInt32(next + 1))
            }
        }
        
        print("✅ [AAA] Generated apple: \(vertices.count) vertices, \(indices.count/3) triangles")
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            print("🏆 [AAA] Apple mesh generation complete!")
            return mesh
        } catch {
            print("❌ [AAA] Apple mesh generation failed: \(error)")
            return .generateSphere(radius: 1.0)
        }
    }
    
    /// Creates a photorealistic orange with proper topology and UV coordinates  
    /// - Returns: High-quality orange mesh with natural citrus shape
    static func createAAAOrangeMesh() -> MeshResource {
        print("🍊 [AAA] Generating photorealistic orange geometry...")
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 32
        let rings = 16
        
        // 🍊 ORANGE SHAPE PARAMETERS: Natural citrus proportions
        let baseRadius: Float = 1.0
        let heightScale: Float = 0.95  // Oranges are slightly flattened spheres
        let segmentDepth: Float = 0.05  // Subtle segment divisions
        let numCitrusSegments = 8  // Natural orange segments
        
        // 🎨 GENERATE VERTICES WITH NATURAL ORANGE SHAPE
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * heightScale
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC SPHERICAL COORDINATES
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius
                let currentY = y
                
                // 🍊 CITRUS SEGMENTS: Subtle indentations for natural orange segments
                let citrusSegmentAngle = Float(numCitrusSegments) * segmentAngle
                let segmentFactor = 1.0 - segmentDepth * sin(citrusSegmentAngle) * sin(ringAngle)
                x *= segmentFactor
                z *= segmentFactor
                
                let vertex = SIMD3<Float>(x, currentY, z)
                vertices.append(vertex)
                
                // 🔆 CALCULATE NORMALS
                let normal = normalize(vertex)
                normals.append(normal)
                
                // 🗺️ UV MAPPING
                let u = Float(segment) / Float(segments)
                let v = Float(ring) / Float(rings)
                uvs.append(SIMD2<Float>(u, v))
            }
        }
        
        // 🔗 GENERATE INDICES
        for ring in 0..<rings {
            for segment in 0..<segments {
                let current = ring * (segments + 1) + segment
                let next = current + segments + 1
                
                indices.append(UInt32(current))
                indices.append(UInt32(next))
                indices.append(UInt32(current + 1))
                
                indices.append(UInt32(current + 1))
                indices.append(UInt32(next))
                indices.append(UInt32(next + 1))
            }
        }
        
        print("✅ [AAA] Generated orange: \(vertices.count) vertices, \(indices.count/3) triangles")
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            print("🏆 [AAA] Orange mesh generation complete!")
            return mesh
        } catch {
            print("❌ [AAA] Orange mesh generation failed: \(error)")
            return .generateSphere(radius: 1.0)
        }
    }
    
    // MARK: - LOD System for Mobile Optimization
    
    /// Creates multiple Level-of-Detail meshes for performance optimization
    /// - Returns: Array of meshes from highest to lowest detail
    static func createLODMeshes() -> [MeshResource] {
        return [
            // LOD 0: High detail for close viewing
            createAAAPLumMesh(segments: 32, rings: 16, asymmetry: 0.15),
            
            // LOD 1: Medium detail for mid-range
            createAAAPLumMesh(segments: 20, rings: 12, asymmetry: 0.15),
            
            // LOD 2: Low detail for distant viewing
            createAAAPLumMesh(segments: 12, rings: 8, asymmetry: 0.10),
            
            // LOD 3: Ultra-low for very distant (fallback sphere)
            .generateSphere(radius: 1.0)
        ]
    }
    
    // MARK: - Utility Functions
    
    /// Calculates appropriate LOD level based on distance from camera
    /// - Parameter distance: Distance from camera to plum
    /// - Returns: LOD level (0 = highest detail, 3 = lowest)
    static func calculateLODLevel(distance: Float) -> Int {
        switch distance {
        case 0..<5:   return 0  // Close: full detail
        case 5..<15:  return 1  // Medium: reduced detail  
        case 15..<30: return 2  // Far: low detail
        default:      return 3  // Very far: minimal detail
        }
    }
}

// MARK: - Extensions for Convenience

@available(macOS 14.0, *)
extension AAAFoodGeometry {
    
    /// Quick method to create a standard AAA plum with optimal settings
    static func createStandardPlum() -> MeshResource {
        return createAAAPLumMesh(
            segments: 28,      // Smooth but mobile-friendly
            rings: 14,         // Good vertical detail
            asymmetry: 0.15,   // Natural plum shape
            stemIndent: true   // Realistic stem area
        )
    }
    
    /// Creates a performance-optimized plum for mobile devices
    static func createMobilePlum() -> MeshResource {
        return createAAAPLumMesh(
            segments: 20,      // Lower polygon count
            rings: 10,         // Fewer rings
            asymmetry: 0.12,   // Slightly less complex
            stemIndent: false  // Skip complex stem for performance
        )
    }
    
    /// Quick method to create a standard AAA apple with optimal settings
    static func createStandardApple() -> MeshResource {
        return createAAAAppleMesh()
    }
    
    /// Quick method to create a standard AAA orange with optimal settings
    static func createStandardOrange() -> MeshResource {
        return createAAAOrangeMesh()
    }
}
