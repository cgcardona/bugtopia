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
class AAAPLumGeometry {
    
    // MARK: - AAA Plum Generation
    
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
extension AAAPLumGeometry {
    
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
}
