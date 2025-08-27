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
        case .blackberry:
            return createAAABlackberryMesh()
        case .tuna:
            return createAAATunaMesh()
        case .mediumSteak:
            return createAAAMediumSteakMesh()
        case .rawFlesh:
            return createAAARawFleshMesh()
        case .rawSteak:
            return createAAARawSteakMesh()
        case .grilledSteak:
            return createAAAGrilledSteakMesh()
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
    static func createAAAPlumMesh(
        segments: Int = 32,
        rings: Int = 16, 
        asymmetry: Float = 0.15,
        stemIndent: Bool = true
    ) -> MeshResource {
        
        // 🍇 Generating photorealistic plum geometry...
        // Generating mesh with segments, rings, and asymmetry
        
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
        
        // Generated plum mesh
        
        // 🚀 CREATE REALITYKIT MESH with proper vertex attributes
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // Plum mesh generation complete
            return mesh
        } catch {
            // Mesh generation failed
            // Fallback to basic sphere
            return .generateSphere(radius: 1.0)
        }
    }
    
    /// Creates a photorealistic apple with proper topology and UV coordinates
    /// - Returns: High-quality apple mesh with natural apple shape
    static func createAAAAppleMesh() -> MeshResource {
        // 🍎 Generating UV-optimized apple geometry...
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 32  // 🍎 AAA: Balanced detail for close-up viewing (was 48)
        let rings = 16     // 🍎 AAA: Good vertical resolution (was 24)
        
        // 🍎 APPLE SHAPE PARAMETERS: Photorealistic apple proportions
        let baseRadius: Float = 1.0
        let heightScale: Float = 1.15  // More natural apple proportions
        let waistPosition: Float = 0.65  // Slightly higher waist for realism
        let waistFactor: Float = 0.88   // Subtle waist narrowing
        let stemIndentDepth: Float = 0.12  // Natural stem depression
        let stemIndentRadius: Float = 0.2   // Realistic stem area
        let bottomBulge: Float = 1.05  // Slight bottom bulge for realism
        let asymmetryFactor: Float = 0.02  // Subtle natural asymmetry
        
        // 🎨 GENERATE VERTICES WITH NATURAL APPLE SHAPE
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * heightScale
            
            // 🍎 AAA APPLE SHAPE: Realistic proportions with natural variations
            var radiusMultiplier: Float = 1.0
            let normalizedY = (y + heightScale) / (2.0 * heightScale) // 0 to 1
            
            // Bottom bulge for natural apple shape
            if normalizedY < 0.3 {
                radiusMultiplier *= bottomBulge
            }
            
            // Waist narrowing in upper section
            if normalizedY > waistPosition {
                let waistProgress = (normalizedY - waistPosition) / (1.0 - waistPosition)
                radiusMultiplier *= waistFactor + (1.0 - waistFactor) * (1.0 - waistProgress * 0.8)
            }
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 AAA SPHERICAL COORDINATES WITH NATURAL ASYMMETRY
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius * radiusMultiplier
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius * radiusMultiplier
                var currentY = y
                
                // 🍎 SUBTLE ASYMMETRY: Real apples aren't perfectly symmetrical
                let asymmetryX = sin(segmentAngle * 3.0) * asymmetryFactor * radiusMultiplier
                let asymmetryZ = cos(segmentAngle * 2.0) * asymmetryFactor * radiusMultiplier
                x += asymmetryX
                z += asymmetryZ
                
                // 🍎 GENTLE STEM INDENT: Reduced distortion for better UV mapping
                if ring < rings / 6 {  // REDUCED: Affect fewer rings
                    let distanceFromCenter = sqrt(x * x + z * z)
                    if distanceFromCenter < stemIndentRadius {
                        let indentFactor = (stemIndentRadius - distanceFromCenter) / stemIndentRadius
                        // SMOOTHER: Use quartic curve instead of quadratic for gentler transition
                        currentY -= stemIndentDepth * indentFactor * indentFactor * indentFactor * indentFactor
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
        
        // ✅ Generated apple: \(vertices.count) vertices, \(indices.count/3) triangles
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // 🏆 Apple mesh generation complete!
            return mesh
        } catch {
            // Apple mesh generation failed
            return .generateSphere(radius: 1.0)
        }
    }
    
    /// Creates a photorealistic blackberry with clustered berry arrangement
    /// - Returns: High-quality blackberry mesh with natural clustered berries
    static func createAAABlackberryMesh() -> MeshResource {
        // 🫐 Generating photorealistic blackberry geometry...
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 24  // Fewer segments for berry clusters
        let rings = 16     // Good detail for clustered shape
        
        // 🫐 BLACKBERRY SHAPE PARAMETERS: Clustered berry aggregate
        let baseRadius: Float = 0.8
        let clusterScale: Float = 1.1   // Overall cluster size
        let berryBumpScale: Float = 0.15  // Individual berry bumps
        let _: Float = 0.9   // How tightly packed (reserved for future use)
        let asymmetryFactor: Float = 0.03 // Natural irregularity
        
        // 🎨 GENERATE VERTICES WITH CLUSTERED BERRY SHAPE
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * clusterScale
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC SPHERICAL COORDINATES
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius * clusterScale
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius * clusterScale
                let currentY = y
                
                // 🫐 BERRY CLUSTERING: Create individual berry bumps
                let berryU = sin(Float(segment * 3) * segmentAngle) * sin(Float(ring * 2) * ringAngle)
                let berryV = cos(Float(segment * 2) * segmentAngle) * cos(Float(ring * 3) * ringAngle)
                let berryBumps = berryBumpScale * (berryU + berryV) * sin(ringAngle)
                
                let bumpRadius = sqrt(x * x + z * z)
                if bumpRadius > 0 {
                    x += (x / bumpRadius) * berryBumps
                    z += (z / bumpRadius) * berryBumps
                }
                
                // 🫐 NATURAL ASYMMETRY: Slight irregularity
                let asymmetryX = sin(segmentAngle * 2.5) * asymmetryFactor
                let asymmetryZ = cos(segmentAngle * 1.8) * asymmetryFactor
                x += asymmetryX
                z += asymmetryZ
                
                let vertex = SIMD3<Float>(x, currentY, z)
                vertices.append(vertex)
                
                // 🔆 CALCULATE NORMALS
                let normal = normalize(vertex)
                normals.append(normal)
                
                // 🗺️ UV MAPPING: Berry cluster friendly
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
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // 🏆 Blackberry mesh generation complete!
            return mesh
        } catch {
            // Blackberry mesh generation failed
            return .generateSphere(radius: 0.8)
        }
    }
    
    /// Creates a photorealistic orange with proper topology and UV coordinates  
    /// - Returns: High-quality orange mesh with natural citrus shape
    static func createAAAOrangeMesh() -> MeshResource {
        // 🍊 Generating photorealistic orange geometry...
        
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
        
        // Generated orange mesh
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // Orange mesh generation complete
            return mesh
        } catch {
            // Orange mesh generation failed
            return .generateSphere(radius: 1.0)
        }
    }
    
    /// Creates a photorealistic melon with proper topology and UV coordinates  
    /// - Returns: High-quality melon mesh with characteristic netted cantaloupe surface
    static func createAAAMelonMesh() -> MeshResource {
        // 🍈 Generating photorealistic melon geometry...
        
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
        
        // Generated melon mesh
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // Melon mesh generation complete
            return mesh
        } catch {
            // Melon mesh generation failed
            return .generateSphere(radius: 1.3)
        }
    }
    
    /// Creates a photorealistic meat chunk with proper topology and UV coordinates  
    /// - Returns: High-quality meat mesh with realistic organic shape
    static func createAAAMeatMesh() -> MeshResource {
        // 🥩 Generating photorealistic meat geometry...
        
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
        
        // Generated meat mesh
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // Meat mesh generation complete
            return mesh
        } catch {
            // Meat mesh generation failed
            return .generateBox(size: [1.2, 0.8, 1.0])
        }
    }
    
    /// Creates a photorealistic fish with proper topology and UV coordinates  
    /// - Returns: High-quality fish mesh with streamlined aquatic shape
    static func createAAAFishMesh() -> MeshResource {
        // 🐟 Generating photorealistic fish geometry...
        
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
        
        // Generated fish mesh
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // Fish mesh generation complete
            return mesh
        } catch {
            // Fish mesh generation failed
            return .generateBox(size: [1.5, 0.6, 0.8])
        }
    }
    
    /// Creates a photorealistic sushi tuna piece with rectangular shape and smooth surface
    /// - Returns: High-quality tuna mesh optimized for sushi presentation
    static func createAAATunaMesh() -> MeshResource {
        // 🍣 Generating proper 3D sushi tuna geometry...
        
        // 🍣 SUSHI TUNA PARAMETERS: Rectangular piece dimensions
        let width: Float = 1.2      // Width of tuna piece
        let height: Float = 1.0     // Height (thickness) of piece - proper sushi thickness!
        let depth: Float = 0.8      // Depth of tuna piece
        
        // 🏗️ CREATE PROPER 3D BOX MESH with all 6 faces
        let mesh = MeshResource.generateBox(width: width, height: height, depth: depth)
        // print("🍣 [GEOMETRY] AAA 3D sushi tuna box created successfully! (w:\(width) h:\(height) d:\(depth))")
        return mesh
    }
    
    /// Creates a photorealistic medium steak with proper topology and UV coordinates
    /// - Returns: High-quality medium steak mesh with realistic proportions and rounded edges
    static func createAAAMediumSteakMesh() -> MeshResource {
        // 🥩 Generating AAA medium steak geometry with rounded edges...
        
        // 🥩 MEDIUM STEAK PARAMETERS: More rectangular, realistic steak dimensions
        let width: Float = 1.8      // Width of steak (more rectangular)
        let height: Float = 0.7     // Height (thickness) - medium steak thickness
        let depth: Float = 1.1      // Depth of steak (less square)
        let cornerRadius: Float = 0.08  // Rounded edges for natural appearance
        
        // 🏗️ CREATE ROUNDED STEAK MESH with natural edges
        let mesh = MeshResource.generateBox(width: width, height: height, depth: depth, cornerRadius: cornerRadius)
        // print("🥩 [GEOMETRY] AAA 3D medium steak with rounded edges created! (w:\(width) h:\(height) d:\(depth) r:\(cornerRadius))")
        return mesh
    }
    
    /// Creates a photorealistic raw flesh glob with organic, irregular shape
    /// - Returns: High-quality raw flesh mesh with natural organic form
    static func createAAARawFleshMesh() -> MeshResource {
        // 🩸 Generating organic raw flesh geometry...
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 24  // Balanced detail for lumpy surface (was 48)
        let rings = 16     // Sufficient rings for surface irregularity (was 32)
        
        // 🩸 RAW FLESH PARAMETERS: Organic, irregular glob
        let baseRadius: Float = 0.6
        let height: Float = 0.8
        let irregularityFactor: Float = 0.8  // Much more aggressive distortion for lumpy texture
        
        // Generate vertices with organic irregularity
        for ring in 0...rings {
            let v = Float(ring) / Float(rings)
            let y = (v - 0.5) * height
            
            // Create organic bulging - wider in middle, tapered ends
            var ringRadius = baseRadius * sin(v * Float.pi)  // Natural blob shape: 0 at ends, max in middle
            
            // Add organic irregularity based on position
            let organicVariation = sin(v * Float.pi * 3.0) * 0.15 + cos(v * Float.pi * 5.0) * 0.1
            ringRadius *= (1.0 + organicVariation * irregularityFactor)
            
            // Ensure we don't get negative radius (which would cause weird geometry)
            ringRadius = max(0.01, ringRadius)
            
            for segment in 0...segments {
                let u = Float(segment) / Float(segments)
                let angle = u * 2.0 * Float.pi
                
                // Add more organic variation around the circumference
                let circumferenceVariation = sin(angle * 4.0) * 0.2 + cos(angle * 7.0) * 0.15
                let finalRadius = ringRadius * (1.0 + circumferenceVariation * irregularityFactor)
                
                let x = cos(angle) * finalRadius
                let z = sin(angle) * finalRadius
                
                vertices.append(SIMD3<Float>(x, y, z))
                
                // Calculate normal for organic surface
                let normal = normalize(SIMD3<Float>(x, 0.2, z))  // Slightly upward-pointing for flesh
                normals.append(normal)
                
                // UV mapping
                uvs.append(SIMD2<Float>(u, v))
            }
        }
        
        // Generate indices for triangular faces
        for ring in 0..<rings {
            for segment in 0..<segments {
                let current = ring * (segments + 1) + segment
                let next = current + segments + 1
                
                // Two triangles per quad
                indices.append(UInt32(current))
                indices.append(UInt32(next))
                indices.append(UInt32(current + 1))
                
                indices.append(UInt32(current + 1))
                indices.append(UInt32(next))
                indices.append(UInt32(next + 1))
            }
        }
        
        // Create mesh descriptor
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffer(vertices)
        meshDescriptor.normals = MeshBuffer(normals)
        meshDescriptor.textureCoordinates = MeshBuffer(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // print("🩸 [GEOMETRY] AAA organic raw flesh glob created successfully! (\(vertices.count) vertices)")
            return mesh
        } catch {
            print("❌ [GEOMETRY] Failed to create raw flesh mesh: \(error)")
            // Fallback to simple sphere
            let fallbackMesh = MeshResource.generateSphere(radius: 0.6)
            print("🩸 [GEOMETRY] Using fallback sphere for raw flesh")
            return fallbackMesh
        }
    }
    
    /// Creates a photorealistic raw steak with natural steak proportions and rough edges
    /// - Returns: High-quality raw steak mesh with organic steak shape
    static func createAAARawSteakMesh() -> MeshResource {
        // 🥩 Generating AAA raw steak geometry...
        
        // 🥩 RAW STEAK PARAMETERS: More irregular than cooked steak
        let width: Float = 1.7      // Width of raw steak (slightly wider)
        let height: Float = 0.6     // Height (thickness) - raw steak is thicker
        let depth: Float = 1.0      // Depth of raw steak
        let cornerRadius: Float = 0.05  // Less rounded edges for raw appearance
        
        // 🏗️ CREATE RAW STEAK MESH with slightly rougher edges
        let mesh = MeshResource.generateBox(width: width, height: height, depth: depth, cornerRadius: cornerRadius)
        // print("🥩 [GEOMETRY] AAA 3D raw steak created successfully! (w:\(width) h:\(height) d:\(depth) r:\(cornerRadius))")
        return mesh
    }
    
    /// Creates a photorealistic grilled steak with perfect grill marks and cooked appearance
    /// - Returns: High-quality grilled steak mesh with refined steak shape
    static func createAAAGrilledSteakMesh() -> MeshResource {
        // 🔥 Generating AAA grilled steak geometry...
        
        // 🔥 GRILLED STEAK PARAMETERS: More refined than raw steak
        let width: Float = 1.6      // Width of grilled steak (slightly smaller due to cooking)
        let height: Float = 0.5     // Height (thickness) - grilled steak is slightly thinner
        let depth: Float = 0.9      // Depth of grilled steak
        let cornerRadius: Float = 0.08  // More rounded edges for cooked appearance
        
        // 🏗️ CREATE GRILLED STEAK MESH with refined edges
        let mesh = MeshResource.generateBox(width: width, height: height, depth: depth, cornerRadius: cornerRadius)
        // print("🔥 [GEOMETRY] AAA 3D grilled steak created successfully! (w:\(width) h:\(height) d:\(depth) r:\(cornerRadius))")
        return mesh
    }
    
    /// Creates a photorealistic seeds cluster with proper topology and UV coordinates  
    /// - Returns: High-quality seeds mesh with natural clustered arrangement
    static func createAAASeedsMesh() -> MeshResource {
        // 🌱 Generating photorealistic seeds geometry...
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 20
        let rings = 12
        
        // 🌱 SEEDS SHAPE PARAMETERS: Small clustered seed arrangement
        let baseRadius: Float = 0.5
        let clusterScale: Float = 1.2   // Overall cluster size
        let seedVariation: Float = 0.3  // Individual seed size variation
        let clusterDensity: Float = 0.8 // How tightly packed the seeds are
        let surfaceRoughness: Float = 0.15 // Natural seed surface irregularity
        
        // 🎨 GENERATE VERTICES WITH NATURAL SEED CLUSTER SHAPE
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * clusterScale
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC SPHERICAL COORDINATES
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius * clusterScale
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius * clusterScale
                let currentY = y
                
                // 🌱 SEED CLUSTERING: Multiple small seeds grouped together
                let clusterU = sin(Float(ring * 3) * ringAngle) * sin(Float(segment * 2) * segmentAngle)
                let clusterV = cos(Float(ring * 2) * ringAngle) * cos(Float(segment * 3) * segmentAngle)
                let clusterFactor = clusterDensity + seedVariation * (clusterU + clusterV) * 0.5
                
                x *= clusterFactor
                z *= clusterFactor
                
                // 🌰 INDIVIDUAL SEED BUMPS: Surface irregularity for multiple seeds
                let seedBumpU = sin(Float(Double(segments) * 2.5) * segmentAngle)
                let seedBumpV = sin(Float(Double(rings) * 2.5) * ringAngle)
                let seedBumps = surfaceRoughness * seedBumpU * seedBumpV * sin(ringAngle)
                
                let bumpRadius = sqrt(x * x + z * z)
                if bumpRadius > 0 {
                    x += (x / bumpRadius) * seedBumps
                    z += (z / bumpRadius) * seedBumps
                }
                
                // 🌱 NATURAL SEED ASYMMETRY: Slight flattening on one side
                let asymmetryFactor = 1.0 - abs(cos(segmentAngle)) * 0.2
                x *= asymmetryFactor
                
                let vertex = SIMD3<Float>(x, currentY, z)
                vertices.append(vertex)
                
                // 🔆 CALCULATE NORMALS
                let normal = normalize(vertex)
                normals.append(normal)
                
                // 🗺️ UV MAPPING: Cluster pattern friendly
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
        
        // Generated seeds mesh
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // print("🏆 [AAA] Seeds mesh generation complete!")
            return mesh
        } catch {
            // print("❌ [AAA] Seeds mesh generation failed: \(error)")
            return .generateSphere(radius: 0.7)
        }
    }
    
    /// Creates a photorealistic nuts mix with proper topology and UV coordinates  
    /// - Returns: High-quality nuts mesh with mixed nut shapes and textures
    static func createAAANutsMesh() -> MeshResource {
        // 🥜 Generating photorealistic nuts geometry...
        
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let segments = 24
        let rings = 16
        
        // 🥜 NUTS SHAPE PARAMETERS: Mixed nut collection
        let baseRadius: Float = 0.6
        let nutScale: Float = 1.1     // Overall size
        let shellRoughness: Float = 0.2  // Shell surface texture
        let nutVariation: Float = 0.4    // Individual nut shape variation
        let crackDetail: Float = 0.15    // Natural shell cracks and ridges
        
        // 🎨 GENERATE VERTICES WITH NATURAL NUT SHAPES
        for ring in 0...rings {
            let ringAngle = Float(ring) / Float(rings) * Float.pi
            let y = cos(ringAngle) * nutScale
            
            for segment in 0...segments {
                let segmentAngle = Float(segment) / Float(segments) * 2.0 * Float.pi
                
                // 🌍 BASIC ELLIPSOIDAL COORDINATES
                var x = sin(ringAngle) * cos(segmentAngle) * baseRadius * nutScale
                var z = sin(ringAngle) * sin(segmentAngle) * baseRadius * nutScale
                let currentY = y
                
                // 🥜 NUT VARIETY: Different nut shapes (almonds, walnuts, pecans)
                let nutTypeU = sin(Float(ring * 2) * ringAngle) * cos(Float(segment * 3) * segmentAngle)
                let nutTypeV = cos(Float(ring * 3) * ringAngle) * sin(Float(segment * 2) * segmentAngle)
                let nutShapeFactor = 1.0 + nutVariation * (nutTypeU + nutTypeV) * 0.5
                
                x *= nutShapeFactor
                z *= nutShapeFactor
                
                // 🌰 SHELL TEXTURE: Natural nut shell ridges and patterns
                let shellU = sin(Float(Double(segments) * 1.8) * segmentAngle)
                let shellV = sin(Float(Double(rings) * 1.8) * ringAngle)
                let shellPattern = shellRoughness * shellU * shellV * sin(ringAngle)
                
                let shellRadius = sqrt(x * x + z * z)
                if shellRadius > 0 {
                    x += (x / shellRadius) * shellPattern
                    z += (z / shellRadius) * shellPattern
                }
                
                // 🔍 CRACK DETAILS: Natural shell cracks and lines
                let crackU = sin(Float(segment * 7) * segmentAngle) * cos(Float(ring * 5) * ringAngle)
                let crackV = cos(Float(segment * 5) * segmentAngle) * sin(Float(ring * 7) * ringAngle)
                let crackIndentation = crackDetail * crackU * crackV * 0.3
                
                if crackIndentation > 0.05 {
                    let crackRadius = sqrt(x * x + z * z)
                    if crackRadius > 0 {
                        x -= (x / crackRadius) * crackIndentation
                        z -= (z / crackRadius) * crackIndentation
                    }
                }
                
                // 🥜 NATURAL NUT ASYMMETRY: Nuts aren't perfectly round
                let asymmetryFactor = 1.0 - abs(sin(segmentAngle * 2.0)) * 0.15
                x *= asymmetryFactor
                
                let vertex = SIMD3<Float>(x, currentY, z)
                vertices.append(vertex)
                
                // 🔆 CALCULATE NORMALS
                let normal = normalize(vertex)
                normals.append(normal)
                
                // 🗺️ UV MAPPING: Mixed nut texture friendly
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
        
        // print("✅ [AAA] Generated nuts: \(vertices.count) vertices, \(indices.count/3) triangles")
        
        // 🚀 CREATE REALITYKIT MESH
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(vertices)
        meshDescriptor.normals = .init(normals)
        meshDescriptor.textureCoordinates = .init(uvs)
        meshDescriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [meshDescriptor])
            // print("🏆 [AAA] Nuts mesh generation complete!")
            return mesh
        } catch {
            // print("❌ [AAA] Nuts mesh generation failed: \(error)")
            return .generateBox(size: [0.9, 0.7, 0.8])
        }
    }
    
    // MARK: - LOD System for Mobile Optimization
    
    /// Creates multiple Level-of-Detail meshes for performance optimization
    /// - Returns: Array of meshes from highest to lowest detail
    static func createLODMeshes() -> [MeshResource] {
        return [
            // LOD 0: High detail for close viewing
            createAAAPlumMesh(segments: 32, rings: 16, asymmetry: 0.15),
            
            // LOD 1: Medium detail for mid-range
            createAAAPlumMesh(segments: 20, rings: 12, asymmetry: 0.15),
            
            // LOD 2: Low detail for distant viewing
            createAAAPlumMesh(segments: 12, rings: 8, asymmetry: 0.10),
            
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
        return createAAAPlumMesh(
            segments: 28,      // Smooth but mobile-friendly
            rings: 14,         // Good vertical detail
            asymmetry: 0.15,   // Natural plum shape
            stemIndent: true   // Realistic stem area
        )
    }
    
    /// Creates a performance-optimized plum for mobile devices
    static func createMobilePlum() -> MeshResource {
        return createAAAPlumMesh(
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
    
    /// Quick method to create a standard AAA blackberry with optimal settings
    static func createStandardBlackberry() -> MeshResource {
        return createAAABlackberryMesh()
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
    
    /// Quick method to create a standard AAA seeds with optimal settings
    static func createStandardSeeds() -> MeshResource {
        return createAAASeedsMesh()
    }
    
    /// Quick method to create a standard AAA nuts with optimal settings
    static func createStandardNuts() -> MeshResource {
        return createAAANutsMesh()
    }
}
