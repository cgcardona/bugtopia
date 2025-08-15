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
            return createAAAPLumMesh()
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
            return .generateSphere(radius: 0.7)
        case .nuts:
            return .generateBox(size: [0.9, 0.7, 0.8])
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
                let x = sin(ringAngle) * cos(segmentAngle) * baseRadius * radiusMultiplier
                let z = sin(ringAngle) * sin(segmentAngle) * baseRadius * radiusMultiplier
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
    
    /// Creates a photorealistic melon with proper topology and UV coordinates  
    /// - Returns: High-quality melon mesh with characteristic netted cantaloupe surface
    static func createAAAMelonMesh() -> MeshResource {
        print("🍈 [AAA] Generating photorealistic melon geometry...")
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 32
        let rings = 16
        
        // 🍈 MELON SHAPE PARAMETERS: Cantaloupe proportions
        let baseRadius: Float = 1.0
        let heightScale: Float = 0.85  // Melons are wider than tall (oblate)
        let netDepth: Float = 0.08     // Depth of netted surface pattern
        let ridgeDepth: Float = 0.12   // Deeper ridges running lengthwise
        let numRidges = 12             // Natural cantaloupe ridge count
        
        // 🎨 GENERATE VERTICES WITH NATURAL MELON SHAPE
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * heightScale
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC SPHERICAL COORDINATES
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius
                let currentY = y
                
                // 🍈 CANTALOUPE RIDGES: Longitudinal indentations
                let ridgeAngle = Float(numRidges) * segmentAngle
                let ridgeFactor = 1.0 - ridgeDepth * sin(ridgeAngle) * sin(ringAngle) * sin(ringAngle)
                x *= ridgeFactor
                z *= ridgeFactor
                
                // 🕸️ NETTED SURFACE: Fine mesh pattern characteristic of cantaloupe
                let netAngleU = Float(segments * 2) * segmentAngle
                let netAngleV = Float(rings * 2) * ringAngle
                let netPattern = sin(netAngleU) * sin(netAngleV)
                let netFactor = 1.0 - netDepth * netPattern * sin(ringAngle)
                x *= netFactor
                z *= netFactor
                
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
        
        print("✅ [AAA] Generated melon: \(vertices.count) vertices, \(indices.count/3) triangles")
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            print("🏆 [AAA] Melon mesh generation complete!")
            return mesh
        } catch {
            print("❌ [AAA] Melon mesh generation failed: \(error)")
            return .generateSphere(radius: 1.3)
        }
    }
    
    /// Creates a photorealistic meat chunk with proper topology and UV coordinates  
    /// - Returns: High-quality meat mesh with realistic organic shape
    static func createAAAMeatMesh() -> MeshResource {
        print("🥩 [AAA] Generating photorealistic meat geometry...")
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 24
        let rings = 16
        
        // 🥩 MEAT SHAPE PARAMETERS: Irregular chunk proportions
        let baseRadius: Float = 1.0
        let lengthScale: Float = 1.3   // Meat chunks are longer than round
        let widthScale: Float = 0.9    // Slightly compressed width
        let heightScale: Float = 0.8   // Lower profile
        let irregularityFactor: Float = 0.25  // High irregularity for organic look
        let marbling: Float = 0.15     // Surface texture variation
        
        // 🎨 GENERATE VERTICES WITH NATURAL MEAT CHUNK SHAPE
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * heightScale
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC ELLIPSOIDAL COORDINATES
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius * widthScale
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius * lengthScale
                let currentY = y
                
                // 🥩 ORGANIC IRREGULARITY: Random deformations for natural meat shape
                let noiseU = sin(Float(segment * 3) * segmentAngle) * sin(Float(ring * 2) * ringAngle)
                let noiseV = cos(Float(segment * 2) * segmentAngle) * cos(Float(ring * 3) * ringAngle)
                let irregularity = irregularityFactor * (noiseU + noiseV) * 0.5
                
                x *= (1.0 + irregularity)
                z *= (1.0 + irregularity)
                
                // 🍖 MARBLING SURFACE: Fine surface texture variation
                let marblingU = sin(Float(Double(segments) * 1.5) * segmentAngle)
                let marblingV = sin(Float(Double(rings) * 1.5) * ringAngle)
                let marblingPattern = marblingU * marblingV
                let marblingFactor = 1.0 + marbling * marblingPattern * 0.3
                x *= marblingFactor
                z *= marblingFactor
                
                // 🥩 CHUNK EDGES: Slightly beveled for realistic appearance
                let edgeFactor = sin(ringAngle) // Natural tapering
                let adjustedY = currentY * (1.0 + edgeFactor * 0.1)
                
                let vertex = SIMD3<Float>(x, adjustedY, z)
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
        
        print("✅ [AAA] Generated meat: \(vertices.count) vertices, \(indices.count/3) triangles")
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            print("🏆 [AAA] Meat mesh generation complete!")
            return mesh
        } catch {
            print("❌ [AAA] Meat mesh generation failed: \(error)")
            return .generateBox(size: [1.2, 0.8, 1.0])
        }
    }
    
    /// Creates a photorealistic fish with proper topology and UV coordinates  
    /// - Returns: High-quality fish mesh with streamlined aquatic shape
    static func createAAAFishMesh() -> MeshResource {
        print("🐟 [AAA] Generating photorealistic fish geometry...")
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 32
        let rings = 16
        
        // 🐟 FISH SHAPE PARAMETERS: Streamlined aquatic proportions
        let baseRadius: Float = 0.8
        let lengthScale: Float = 2.2   // Fish are much longer than wide
        let heightScale: Float = 0.9   // Slightly compressed vertically
        let widthScale: Float = 0.7    // Narrow profile for swimming
        let tailTaper: Float = 0.8     // How much the tail tapers
        let finDetail: Float = 0.1     // Subtle fin ridges
        
        // 🎨 GENERATE VERTICES WITH NATURAL FISH SHAPE
        for ring in 0...rings {
            let ringProgress = Float(ring) / Float(rings)
            let ringAngle = ringProgress * Float.pi
            
            // 🐟 FISH BODY PROFILE: Streamlined from head to tail
            var bodyRadius = sin(ringAngle) * baseRadius
            
            // 🏊 STREAMLINED TAPERING: Wide in middle, narrow at ends
            let streamlineFactor: Float
            if ringProgress < 0.3 {
                // Head region - gradual taper
                streamlineFactor = ringProgress / 0.3 * 0.9
            } else if ringProgress > 0.7 {
                // Tail region - dramatic taper
                let tailProgress = (ringProgress - 0.7) / 0.3
                streamlineFactor = (1.0 - tailProgress * tailTaper) * 0.9
            } else {
                // Body region - full width
                streamlineFactor = 0.9
            }
            bodyRadius *= streamlineFactor
            
            let y = cos(ringAngle) * heightScale * streamlineFactor
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC ELLIPSOIDAL COORDINATES
                var x = sin(ringAngle) * cos(segmentAngle) * bodyRadius * widthScale
                let z = sin(ringAngle) * sin(segmentAngle) * bodyRadius * lengthScale
                var currentY = y
                
                // 🐟 DORSAL/VENTRAL FINS: Subtle ridges along top and bottom
                let dorsalVentralFactor = abs(cos(segmentAngle * 2.0)) // Top and bottom
                let finRidge = finDetail * dorsalVentralFactor * sin(ringAngle) * streamlineFactor
                
                if cos(segmentAngle) > 0.7 { // Dorsal (top)
                    currentY += finRidge
                } else if cos(segmentAngle) < -0.7 { // Ventral (bottom)
                    currentY -= finRidge * 0.5 // Smaller ventral fins
                }
                
                // 🏊 LATERAL COMPRESSION: Fish are compressed side-to-side
                let lateralCompressionFactor = 1.0 - abs(sin(segmentAngle)) * 0.2
                x *= lateralCompressionFactor
                
                let vertex = SIMD3<Float>(x, currentY, z)
                vertices.append(vertex)
                
                // 🔆 CALCULATE NORMALS
                let normal = normalize(vertex)
                normals.append(normal)
                
                // 🗺️ UV MAPPING: Scale pattern friendly
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
        
        print("✅ [AAA] Generated fish: \(vertices.count) vertices, \(indices.count/3) triangles")
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            print("🏆 [AAA] Fish mesh generation complete!")
            return mesh
        } catch {
            print("❌ [AAA] Fish mesh generation failed: \(error)")
            return .generateBox(size: [1.5, 0.6, 0.8])
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
    
    /// Quick method to create a standard AAA melon with optimal settings
    static func createStandardMelon() -> MeshResource {
        return createAAAMelonMesh()
    }
    
    /// Quick method to create a standard AAA meat with optimal settings
    static func createStandardMeat() -> MeshResource {
        return createAAAMeatMesh()
    }
    
    /// Quick method to create a standard AAA fish with optimal settings
    static func createStandardFish() -> MeshResource {
        return createAAAFishMesh()
    }
}
