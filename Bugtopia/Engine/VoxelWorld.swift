//
//  VoxelWorld.swift
//  Bugtopia
//
//  Advanced voxel-based 3D terrain system for true spatial evolution
//

import Foundation
import CoreGraphics

// MARK: - Essential 3D Types

/// Minimal Arena3D class for compatibility (legacy code support)
class Arena3D {
    let bounds: CGRect
    
    init(bounds: CGRect) {
        self.bounds = bounds
    }
    
    /// Check if position is valid within arena bounds
    func isValidPosition(_ position: Position3D) -> Bool {
        return bounds.contains(CGPoint(x: position.x, y: position.y))
    }
}

/// Minimal ArenaTile3D struct for compatibility
struct ArenaTile3D {
    let terrain: TerrainType
    let position: Position3D
    let layer: TerrainLayer
    
    init(terrain: TerrainType, position: Position3D, layer: TerrainLayer) {
        self.terrain = terrain
        self.position = position
        self.layer = layer
    }
}

/// 3D coordinate system for bugs and objects  
struct Position3D: Codable, Equatable {
    var x: Double
    var y: Double
    var z: Double  // Height/depth coordinate
    
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(from position2D: CGPoint, z: Double = 0.0) {
        self.x = position2D.x
        self.y = position2D.y
        self.z = z
    }
    
    /// Convert to 2D position (for backward compatibility)
    var position2D: CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    /// Calculate 3D distance to another position
    func distance(to other: Position3D) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    /// Calculate 2D distance (ignoring height)
    func distance2D(to other: Position3D) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx*dx + dy*dy)
    }
}

/// 3D terrain layers for multi-level environments
enum TerrainLayer: String, CaseIterable, Codable {
    case underground = "underground"  // Caves, tunnels (-50 to -30)
    case surface = "surface"          // Ground level (-30 to 10)
    case canopy = "canopy"           // Tree tops, elevated (10 to 30)
    case aerial = "aerial"           // Open sky (30+)
    
    /// Vertical range for each layer (approximate)
    var zRange: ClosedRange<Double> {
        switch self {
        case .underground: return -50.0...(-30.0)
        case .surface: return -30.0...10.0
        case .canopy: return 10.0...30.0
        case .aerial: return 30.0...200.0
        }
    }
    
    /// Center Z coordinate for each layer
    var centerZ: Double {
        switch self {
        case .underground: return -40.0
        case .surface: return -10.0
        case .canopy: return 20.0
        case .aerial: return 60.0
        }
    }
    
    /// Height range for each layer (same as zRange, for compatibility)
    var heightRange: ClosedRange<Double> {
        return zRange
    }
}

/// Biome types for environmental classification
enum BiomeType: String, CaseIterable, Codable {
    case tundra = "tundra"
    case borealForest = "boreal_forest"
    case temperateForest = "temperate_forest"
    case temperateGrassland = "temperate_grassland"
    case desert = "desert"
    case savanna = "savanna"
    case tropicalRainforest = "tropical_rainforest"
    case wetlands = "wetlands"
    case alpine = "alpine"
    case coastal = "coastal"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .tundra: return "Tundra"
        case .borealForest: return "Boreal Forest"
        case .temperateForest: return "Temperate Forest"
        case .temperateGrassland: return "Temperate Grassland"
        case .desert: return "Desert"
        case .savanna: return "Savanna"
        case .tropicalRainforest: return "Tropical Rainforest"
        case .wetlands: return "Wetlands"
        case .alpine: return "Alpine"
        case .coastal: return "Coastal"
        }
    }
    
    /// Vegetation density for terrain generation (0.0 to 1.0)
    var vegetationDensity: Double {
        switch self {
        case .tundra: return 0.1
        case .borealForest: return 0.7
        case .temperateForest: return 0.9
        case .temperateGrassland: return 0.4
        case .desert: return 0.05
        case .savanna: return 0.3
        case .tropicalRainforest: return 1.0
        case .wetlands: return 0.8
        case .alpine: return 0.2
        case .coastal: return 0.5
        }
    }
}

/// 3D world generation types for procedural terrain
enum WorldType3D: String, CaseIterable, Codable {
    case continental3D = "Continental 3D"
    case archipelago3D = "Archipelago 3D"
    case canyon3D = "Canyon 3D"
    case cavern3D = "Cavern 3D"
    case skylands3D = "Skylands 3D"
    case abyss3D = "Abyss 3D"
    case volcano3D = "Volcano 3D"
    
    /// Generate height for this world type at normalized coordinates
    func generateHeight(at x: Double, y: Double) -> Double {
        switch self {
        case .continental3D:
            // 🌍 CONTINENTAL: Dramatic landscape features with clear elevation zones
            // Create distinct regions: deep water → wetlands → plains → forests → hills → mountains
            
            // 🏔️ MOUNTAIN RANGES: Create 2-3 mountain chains across the continent
            let mountainChain1 = max(0, 35.0 - abs((x - 0.2) * 200.0)) // Western mountains
            let mountainChain2 = max(0, 30.0 - abs((y - 0.7) * 150.0)) // Northern mountains
            
            // 🌊 RIVER VALLEYS: Major river systems cutting through terrain
            let majorRiver = -25.0 + abs((x - 0.5) * 50.0) // Central river valley
            let tributary = -15.0 + abs((y - 0.3) * 40.0)   // Tributary valley
            
            // 🏞️ ROLLING HILLS: Gentle elevation changes across plains
            let plains = sin(x * 4.0) * cos(y * 3.0) * 8.0 + 5.0
            
            // 🏔️ Combine features with realistic geographic priority
            var height = plains // Start with gentle rolling terrain
            
            // Add mountain ranges (they dominate the landscape)
            height = max(height, mountainChain1)
            height = max(height, mountainChain2)
            
            // Cut river valleys through terrain (water always wins)
            if (abs(x - 0.5) < 0.05) { height = min(height, majorRiver) }  // Major river
            if (abs(y - 0.3) < 0.03) { height = min(height, tributary) }   // Tributary
            
            // 🌊 COASTAL LAKES: Large lake systems
            let lakeCenter1 = sqrt(pow(x - 0.8, 2) + pow(y - 0.2, 2))
            let lakeCenter2 = sqrt(pow(x - 0.15, 2) + pow(y - 0.8, 2))
            if lakeCenter1 < 0.15 { height = min(height, -20.0) } // Large lake
            if lakeCenter2 < 0.12 { height = min(height, -18.0) } // Smaller lake
            
            return height
            
        case .archipelago3D:
            // Island chains with water
            let islandDistance = sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2))
            let islandHeight = max(0, (0.3 - islandDistance) * 50.0)
            return islandHeight - 10.0
            
        case .canyon3D:
            // Deep valleys and high mesas
            let valleyDepth = abs(x - 0.5) < 0.2 ? -25.0 : 20.0
            return valleyDepth
            
        case .cavern3D:
            // Underground cave systems - mostly low terrain
            return -30.0 + sin(x * 6.28) * cos(y * 6.28) * 8.0
            
        case .skylands3D:
            // Floating islands - elevated terrain
            let elevation = sin(x * 4.0) * cos(y * 4.0) * 20.0
            return elevation + 25.0
            
        case .abyss3D:
            // Deep underwater trenches
            return -40.0 + sin(x * 2.0) * cos(y * 2.0) * 15.0
            
        case .volcano3D:
            // Volcanic peaks and lava flows
            let distanceFromCenter = sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2))
            let volcanoHeight = max(-5, 40.0 - distanceFromCenter * 60.0)
            return volcanoHeight
        }
    }
    
    /// 🌍 WORLD-TYPE SPECIFIC BIOME CONSTRAINTS
    /// Each world type dramatically limits which biomes can appear for unique experiences
    var allowedBiomes: [BiomeType] {
        switch self {
        case .cavern3D:
            // Underground world: Cold, rocky, minimal vegetation
            return [.tundra, .alpine]
            
        case .archipelago3D:
            // Island world: Water-rich, tropical themes
            return [.coastal, .tropicalRainforest, .wetlands, .temperateForest]
            
        case .abyss3D:
            // Deep underwater: Cold, harsh, sparse
            return [.tundra, .alpine, .wetlands]
            
        case .volcano3D:
            // Volcanic world: Hot, rocky, dangerous
            return [.desert, .alpine, .savanna]
            
        case .canyon3D:
            // Desert canyons: Dry, rocky, sparse
            return [.desert, .temperateGrassland, .alpine, .savanna]
            
        case .skylands3D:
            // Floating islands: Temperate, elevated
            return [.temperateForest, .alpine, .temperateGrassland, .borealForest]
            
        case .continental3D:
            // Standard continental: All biomes allowed for variety
            return BiomeType.allCases
        }
    }
}

// MARK: - 3D Direction System

enum Direction3D: CaseIterable {
    case north, south, east, west, up, down
    
    var offset: (x: Int, y: Int, z: Int) {
        switch self {
        case .north: return (0, -1, 0)
        case .south: return (0, 1, 0)
        case .east: return (1, 0, 0)
        case .west: return (-1, 0, 0)
        case .up: return (0, 0, 1)
        case .down: return (0, 0, -1)
        }
    }
}

// MARK: - Voxel Transition Types

enum TransitionType {
    case solid              // Impassable voxel
    case air                // Open space
    case ramp(angle: Double)           // Gradual slope (0.0-1.0)
    case climb(difficulty: Double)     // Vertical climbing (0.0-1.0)
    case swim(depth: Double)          // Water transition (0.0-1.0)
    case tunnel(width: Double)        // Cave passage (0.0-1.0)
    case flight(clearance: Double)    // Aerial movement (0.0-1.0)
    case bridge(stability: Double)    // Constructed connection (0.0-1.0)
    
    var isPassable: Bool {
        switch self {
        case .solid: return false
        default: return true
        }
    }
    
    func movementCost(for species: SpeciesType, with dna: BugDNA) -> Double? {
        switch self {
        case .solid:
            return nil // Impassable
            
        case .air:
            return 1.0 // Standard movement
            
        case .ramp(let angle):
            // Steeper ramps are harder
            return 1.0 + (angle * 0.5)
            
        case .climb(let difficulty):
            // Requires climbing ability
            guard dna.climbingGrip > difficulty * 0.5 else { return nil }
            return 2.0 + difficulty
            
        case .swim(let depth):
            // Requires swimming ability
            guard dna.divingDepth > depth * 0.3 else { return nil }
            return 1.5 + (depth * 0.5)
            
        case .tunnel(let width):
            // Smaller bugs move easier in tunnels
            let sizeAdvantage = max(0.1, 1.0 - dna.size)
            return 1.2 + (1.0 - width) * (1.0 - sizeAdvantage)
            
        case .flight(let clearance):
            // Requires flying ability
            guard dna.wingSpan > 0.3 else { return nil }
            return 1.0 + (1.0 - clearance) * (1.0 - dna.wingSpan)
            
        case .bridge(let stability):
            // Constructed bridges
            return 1.1 + (1.0 - stability) * 0.3
        }
    }
}

// MARK: - Individual Voxel

struct Voxel {
    let position: Position3D
    let gridPosition: (x: Int, y: Int, z: Int)
    let terrainType: TerrainType
    let layer: TerrainLayer
    let transitionType: TransitionType
    let biome: BiomeType
    
    // Environmental properties
    let temperature: Double      // -1.0 to 1.0
    let moisture: Double        // 0.0 to 1.0
    let light: Double          // 0.0 to 1.0
    let windSpeed: Double      // 0.0 to 1.0
    
    // Connectivity
    var connections: [Direction3D: Bool] = [:]  // Which directions are accessible
    
    // Resource availability
    var hasFood: Bool = false
    var foodDensity: Double = 0.0
    var resourceType: VoxelResourceType?
    
    init(gridPosition: (x: Int, y: Int, z: Int), 
         worldPosition: Position3D,
         terrainType: TerrainType,
         layer: TerrainLayer,
         transitionType: TransitionType,
         biome: BiomeType) {
        self.gridPosition = gridPosition
        self.position = worldPosition
        self.terrainType = terrainType
        self.layer = layer
        self.transitionType = transitionType
        self.biome = biome
        
        // Calculate environmental properties based on position and biome
        self.temperature = Self.calculateTemperature(position: worldPosition, biome: biome)
        self.moisture = Self.calculateMoisture(position: worldPosition, biome: biome)
        self.light = Self.calculateLight(layer: layer, position: worldPosition)
        self.windSpeed = Self.calculateWindSpeed(layer: layer, position: worldPosition)
        
        // Initialize all connections as potentially available
        for direction in Direction3D.allCases {
            connections[direction] = transitionType.isPassable
        }
    }
    
    // MARK: - Environmental Calculations
    
    private static func calculateTemperature(position: Position3D, biome: BiomeType) -> Double {
        let baseTemp = biome.averageTemperature
        let altitudeEffect = -position.z * 0.01  // Cooler at higher altitudes
        let latitudeEffect = sin(position.y * 0.01) * 0.3  // Varies with Y position
        return max(-1.0, min(1.0, baseTemp + altitudeEffect + latitudeEffect))
    }
    
    private static func calculateMoisture(position: Position3D, biome: BiomeType) -> Double {
        let baseMoisture = biome.averageMoisture
        let terrainEffect = 0.0  // Will be calculated based on biome in actual implementation
        let noiseEffect = sin(position.x * 0.05) * cos(position.y * 0.05) * 0.2
        return max(0.0, min(1.0, baseMoisture + terrainEffect + noiseEffect))
    }
    
    private static func calculateLight(layer: TerrainLayer, position: Position3D) -> Double {
        switch layer {
        case .underground: return 0.1 + (position.z + 50.0) / 500.0  // Dimmer deeper
        case .surface: return 0.8 + sin(position.x * 0.02) * 0.2     // Varied surface light
        case .canopy: return 0.6 + cos(position.y * 0.02) * 0.3      // Filtered canopy light
        case .aerial: return 1.0                                      // Full sunlight
        }
    }
    
    private static func calculateWindSpeed(layer: TerrainLayer, position: Position3D) -> Double {
        switch layer {
        case .underground: return 0.0
        case .surface: return 0.3 + sin(position.x * 0.01) * 0.2
        case .canopy: return 0.5 + cos(position.y * 0.01) * 0.3
        case .aerial: return 0.8 + sin(position.x * 0.005) * 0.2
        }
    }
    
    // MARK: - Movement Analysis
    
    func canMoveTo(direction: Direction3D, for species: SpeciesType, with dna: BugDNA) -> Bool {
        guard connections[direction] == true else { return false }
        return transitionType.movementCost(for: species, with: dna) != nil
    }
    
    func movementCost(for species: SpeciesType, with dna: BugDNA) -> Double {
        return transitionType.movementCost(for: species, with: dna) ?? Double.infinity
    }
}

// MARK: - Resource Types for Voxels

enum VoxelResourceType: String, CaseIterable {
    case vegetation = "vegetation"
    case minerals = "minerals"
    case water = "water"
    case insects = "insects"
    case nectar = "nectar"
    case seeds = "seeds"
    case fungi = "fungi"
    case detritus = "detritus"
    
    var preferredLayer: TerrainLayer {
        switch self {
        case .vegetation, .water: return .surface
        case .minerals, .fungi, .detritus: return .underground
        case .nectar, .seeds: return .canopy
        case .insects: return .aerial
        }
    }
    
    var nutritionValue: Double {
        switch self {
        case .vegetation: return 15.0
        case .minerals: return 5.0
        case .water: return 10.0
        case .insects: return 25.0
        case .nectar: return 30.0
        case .seeds: return 20.0
        case .fungi: return 18.0
        case .detritus: return 12.0
        }
    }
}

// MARK: - Voxel World Container

class VoxelWorld {
    // Grid dimensions
    let dimensions: (width: Int, height: Int, depth: Int)
    let voxelSize: Double
    let worldBounds: CGRect
    
    // 3D voxel grid [x][y][z]
    private(set) var voxels: [[[Voxel]]] = []
    
    // Spatial indexing for performance
    private var layerVoxels: [TerrainLayer: [Voxel]] = [:]
    private var transitionVoxels: [Voxel] = []
    
    // World generation parameters
    let worldType: WorldType3D
    let noiseSeed: Double  // Random seed for terrain generation
    var heightMap: [[Double]] = []
    var biomeMap: [[BiomeType]] = []
    var temperatureMap: [[Double]] = []
    var moistureMap: [[Double]] = []
    
    init(bounds: CGRect, worldType: WorldType3D = .continental3D, resolution: Int = 32) {
        self.worldBounds = bounds
        self.worldType = worldType
        
        // 🎲 RANDOM SEED for truly unique worlds each time
        self.noiseSeed = Double.random(in: 0...10000)

        
        // Calculate dimensions - higher resolution for true voxel detail
        self.dimensions = (width: resolution, height: resolution, depth: resolution)
        self.voxelSize = min(bounds.width / Double(resolution), bounds.height / Double(resolution))
        
        // Initialize layer collections
        for layer in TerrainLayer.allCases {
            layerVoxels[layer] = []
        }
        
        // Generate the voxel world
        generateVoxelWorld()
    }
    
    // MARK: - Voxel World Generation
    
    private func generateVoxelWorld() {
        // Generating voxel world
        
        // Step 1: Generate base terrain data
        generateHeightMap()
        generateClimateData()
        generateBiomeMap()
        
        // Step 2: Create 3D voxel grid
        generateVoxelGrid()
        
        // Step 3: Create layer transitions
        generateLayerTransitions()
        
        // Step 4: Add resources and details
        populateResources()
        
        // Step 5: Optimize connectivity
        optimizeConnectivity()
        
        // Voxel world generation complete
    }
    
    private func generateHeightMap() {
        heightMap = Array(repeating: Array(repeating: 0.0, count: dimensions.height), count: dimensions.width)
        
        // 🌍 WORLD TYPE-SPECIFIC HEIGHT GENERATION

        
        for x in 0..<dimensions.width {
            for y in 0..<dimensions.height {
                let normalizedX = Double(x) / Double(dimensions.width)
                let normalizedY = Double(y) / Double(dimensions.height)
                
                // 🎯 CONTINENTAL TERRAIN: Dramatically simplified for coherent features
                // World type height now DOMINATES - 90% of final height
                let worldTypeHeight = worldType.generateHeight(at: normalizedX, y: normalizedY)
                
                // 🎯 MINIMAL NOISE: Only add very subtle continental-scale variation
                // Reduced from 5.0 + 2.0 + 0.5 = 7.5 total to just 2.0 total
                let continentalVariation = noise2D(normalizedX * 0.5, normalizedY * 0.5) * 2.0
                
                // REMOVED: Regional and local detail noise - they made terrain too random
                // Now terrain is 95% world-type determined, 5% gentle variation
                
                heightMap[x][y] = worldTypeHeight + continentalVariation
            }
        }
        
        // 🔍 DEBUG: Log height range for continental terrain analysis
        let heights = heightMap.flatMap { $0 }
        let minHeight = heights.min() ?? 0.0
        let maxHeight = heights.max() ?? 0.0
        print("🌍 Continental heightmap range: \(String(format: "%.1f", minHeight)) to \(String(format: "%.1f", maxHeight))")
    }
    
    private func generateBiomeMap() {
        biomeMap = Array(repeating: Array(repeating: .temperateForest, count: dimensions.height), count: dimensions.width)
        
        for x in 0..<dimensions.width {
            for y in 0..<dimensions.height {
                let temperature = temperatureMap[x][y]
                let moisture = moistureMap[x][y]
                biomeMap[x][y] = determineBiome(temperature: temperature, moisture: moisture)
            }
        }
    }
    
    private func generateClimateData() {
        temperatureMap = Array(repeating: Array(repeating: 0.0, count: dimensions.height), count: dimensions.width)
        moistureMap = Array(repeating: Array(repeating: 0.0, count: dimensions.height), count: dimensions.width)
        
        for x in 0..<dimensions.width {
            for y in 0..<dimensions.height {
                let normalizedX = Double(x) / Double(dimensions.width)
                let normalizedY = Double(y) / Double(dimensions.height)
                
                // Temperature: warmer in the middle, cooler at edges
                let tempBase = 1.0 - abs(normalizedY - 0.5) * 2.0
                let tempNoise = noise2D(normalizedX * 6.0, normalizedY * 6.0) * 0.3
                temperatureMap[x][y] = max(-1.0, min(1.0, tempBase + tempNoise))
                
                // Moisture: varies with terrain and noise
                let moistBase = noise2D(normalizedX * 3.0, normalizedY * 3.0) * 0.5 + 0.5
                let moistDetail = noise2D(normalizedX * 15.0, normalizedY * 15.0) * 0.2
                moistureMap[x][y] = max(0.0, min(1.0, moistBase + moistDetail))
            }
        }
    }
    
    private func generateVoxelGrid() {
        voxels = []
        
        // Tracking variables for debug statistics
        var terrainCounts: [String: Int] = [:]
        var transitionCounts: [String: Int] = [:]
        
        // Initialize empty 3D array structure
        for _ in 0..<dimensions.width {
            var yArray: [[Voxel]] = []
            for _ in 0..<dimensions.height {
                var zArray: [Voxel] = []
                for _ in 0..<dimensions.depth {
                    zArray.append(Voxel(
                        gridPosition: (0, 0, 0), // Temporary, will be set correctly
                        worldPosition: Position3D(0, 0, 0),
                        terrainType: .open,
                        layer: .surface,
                        transitionType: .air,
                        biome: .temperateForest
                    ))
                }
                yArray.append(zArray)
            }
            voxels.append(yArray)
        }
        
        for x in 0..<dimensions.width {
            for y in 0..<dimensions.height {
                for z in 0..<dimensions.depth {
                    let voxel = createVoxel(at: (x, y, z))
                    voxels[x][y][z] = voxel
                    
                    // Add to layer collections
                    layerVoxels[voxel.layer]?.append(voxel)
                    
                    // Track statistics
                    let terrainKey = "\(voxel.terrainType)"
                    let transitionKey = "\(voxel.transitionType)"
                    terrainCounts[terrainKey, default: 0] += 1
                    transitionCounts[transitionKey, default: 0] += 1
                }
            }
        }
        

    }
    
    private func createVoxel(at gridPos: (x: Int, y: Int, z: Int)) -> Voxel {
        // Convert grid position to world position
        let worldX = worldBounds.minX + (Double(gridPos.x) + 0.5) * voxelSize
        let worldY = worldBounds.minY + (Double(gridPos.y) + 0.5) * voxelSize
        
        // FIXED: Properly map 32 Z-levels (0-31) to world range (-50 to +50)
        let worldZ = (Double(gridPos.z) / Double(dimensions.depth - 1)) * 100.0 - 50.0
        
        let worldPosition = Position3D(worldX, worldY, worldZ)
        let layer = determineLayer(z: worldZ)
        
        // Determine terrain properties with bounds checking
        guard gridPos.x < heightMap.count && gridPos.y < heightMap[0].count,
              gridPos.x < biomeMap.count && gridPos.y < biomeMap[0].count else {
            // Grid position out of bounds
            // Return a safe default voxel
            return Voxel(
                gridPosition: gridPos,
                worldPosition: worldPosition,
                terrainType: .open,
                layer: layer,
                transitionType: .air,
                biome: .temperateForest
            )
        }
        
        let heightAtPosition = heightMap[gridPos.x][gridPos.y]
        let biome = biomeMap[gridPos.x][gridPos.y]
        let terrainType = determineTerrainType(gridPos: gridPos, worldZ: worldZ, heightAtPosition: heightAtPosition, biome: biome)
        let transitionType = determineTransitionType(gridPos: gridPos, terrainType: terrainType, layer: layer)
        
        return Voxel(
            gridPosition: gridPos,
            worldPosition: worldPosition,
            terrainType: terrainType,
            layer: layer,
            transitionType: transitionType,
            biome: biome
        )
    }
    
    private func determineLayer(z: Double) -> TerrainLayer {
        // Adjusted for actual Z coordinate range: -50 to +50
        switch z {
        case ..<(-30): return .underground    // Z = -50 to -30
        case (-30)..<10: return .surface      // Z = -30 to 10 (includes terrain at -50 to -46)
        case 10..<30: return .canopy          // Z = 10 to 30
        default: return .aerial               // Z > 30
        }
    }
    
    private func determineTerrainType(gridPos: (x: Int, y: Int, z: Int), worldZ: Double, heightAtPosition: Double, biome: BiomeType) -> TerrainType {
        // NEW: 4-Layer Independent Terrain Generation
        // Each layer generates terrain independently to allow exploration
        
        let layer = determineLayer(z: worldZ)
        
        // Use grid position for consistent spatial noise
        let normalizedX = Double(gridPos.x) / Double(dimensions.width)
        let normalizedY = Double(gridPos.y) / Double(dimensions.height)
        let normalizedZ = Double(gridPos.z) / Double(dimensions.depth)
        
        // 🎯 MINIMAL NOISE: Dramatically reduced for height-based terrain dominance  
        // Reduced from 0.5x to 0.1x for maximum terrain coherence
        let biomeNoise = noise2D(normalizedX * 0.1 + normalizedZ * 0.05, normalizedY * 0.1 + normalizedZ * 0.05)
        
        // Generate terrain based on layer type, following original Arena3D design
        switch layer {
        case .underground:
            return generateUndergroundTerrain(biome: biome, height: heightAtPosition, noise: biomeNoise)
        case .surface:
            return generateSurfaceTerrain(biome: biome, height: heightAtPosition, noise: biomeNoise)
        case .canopy:
            return generateCanopyTerrain(biome: biome, height: heightAtPosition, noise: biomeNoise)
        case .aerial:
            return generateAerialTerrain(biome: biome, height: heightAtPosition, noise: biomeNoise)
        }
    }
    
    // MARK: - Layer-Specific Terrain Generation (Ported from Arena3D)
    
    private func generateUndergroundTerrain(biome: BiomeType, height: Double, noise: Double) -> TerrainType {
        // 🌍 WORLD TYPE-SPECIFIC UNDERGROUND TERRAIN
        // First determine base underground terrain from biome, then modify based on world type
        
        let baseTerrain: TerrainType
        switch biome {
        case .wetlands, .coastal:
            if noise > 0.3 { baseTerrain = .water }      // Underground pools
            else if noise > 0.1 { baseTerrain = .wall }  // Cave walls (reduced from 0.4)
            else if noise < -0.4 { baseTerrain = .food } // Underground resources
            else { baseTerrain = .open }                 // Cave passages
        case .desert:
            if noise > 0.3 { baseTerrain = .wall }       // Rock formations (reduced)
            else if noise < -0.3 { baseTerrain = .food } // Mineral deposits
            else { baseTerrain = .open }                 // Cave passages
        default:
            if noise > 0.2 { baseTerrain = .wall }       // Cave walls (much reduced for exploration)
            else if noise > 0.0 && biome.averageMoisture > 0.7 { baseTerrain = .water }  // Underground water
            else if noise < -0.4 { baseTerrain = .food } // Cave resources
            else { baseTerrain = .open }                 // Explorable cave space
        }
        
        // 🎯 Apply world type modifications to underground terrain
        return applyWorldTypeModifications(baseTerrain: baseTerrain, height: height, noise: noise)
    }
    
    private func generateSurfaceTerrain(biome: BiomeType, height: Double, noise: Double) -> TerrainType {
        // 🌍 WORLD TYPE-SPECIFIC TERRAIN MODULATION
        // First determine base terrain from biome, then modify based on world type
        
        let baseTerrain = generateBiomeBasedTerrain(biome: biome, height: height, noise: noise)
        
        // 🎯 Apply world type modifications
        return applyWorldTypeModifications(baseTerrain: baseTerrain, height: height, noise: noise)
    }
    
    private func generateBiomeBasedTerrain(biome: BiomeType, height: Double, noise: Double) -> TerrainType {
        // Base biome terrain generation
        switch biome {
        case .desert:
            if noise > 0.6 { return .hill }
            if noise > 0.3 { return .sand }
            if noise < -0.7 { return .food }      // Oasis
            return .open
        case .tropicalRainforest, .temperateForest, .borealForest:
            if noise > 0.4 { return .forest }
            if noise > 0.0 { return .food }       // Rich forest resources
            if noise < -0.5 { return .water }     // Forest streams
            return .open
        case .wetlands:
            if noise > 0.2 { return .water }
            if noise > -0.2 { return .swamp }
            if noise < -0.5 { return .food }
            return .open
        case .alpine, .tundra:
            if biome.averageTemperature < -0.3 && noise > 0.3 { return .ice }
            if noise > 0.5 { return .hill }
            if noise < -0.6 { return .food }
            return .open
        case .coastal:
            if height < 5 && noise > 0.0 { return .water }
            if noise > 0.4 { return .sand }
            if noise < -0.4 { return .food }
            return .open
        default: // Grasslands, Savanna
            if noise > 0.7 { return .hill }       // Reduced hills to 30%
            if noise > 0.2 { return .food }       // Abundant grassland resources
            if noise < -0.6 { return .water }
            return .open  // Note: .open renders as grass in default material case
        }
    }
    
    private func applyWorldTypeModifications(baseTerrain: TerrainType, height: Double, noise: Double) -> TerrainType {
        // 🌍 PHASE 2: DRAMATIC TERRAIN GENERATION
        // Each world type now creates completely different terrain patterns
        
        switch worldType {
        case .archipelago3D:
            // 🏖️ ARCHIPELAGO: 70% water, 20% coastal, 10% islands
            if height < -5 { return .water }                 // Ocean dominates
            if height < 0 && noise > 0.3 { return .water }   // More ocean areas
            if height < 5 { return .sand }                   // Beach zones
            if height < 8 && noise > 0.0 { return .food }    // Coastal vegetation
            if height > 15 { return .hill }                  // Island peaks
            return .open                                     // Island ground
            
        case .canyon3D:
            // ⛰️ CANYON: Dramatic valleys and towering mesas
            let centerDistance = abs(0.5 - noise)           // Distance from valley center
            if centerDistance < 0.15 && height < -15 { return .water }  // River valley
            if centerDistance < 0.25 { return .open }        // Valley floor
            if height > 25 { return .wall }                  // Mesa walls/cliffs
            if height > 15 { return .hill }                  // Mesa tops
            if height < -10 { return .shadow }               // Deep canyon shadows
            return .hill                                     // Slopes
            
        case .cavern3D:
            // 🏔️ CAVERN: 80% underground accessible, cave systems
            if height < -25 { return .shadow }               // Deep cave passages
            if height < -20 && noise > 0.3 { return .open }  // Cave floors
            if height < -15 && noise < 0.2 { return .water } // Underground pools
            if height > -10 && noise > 0.6 { return .wall }  // Cave walls/ceilings
            if height > 0 && noise > 0.4 { return .wall }    // Block most surface
            return .shadow                                   // More cave areas
            
        case .skylands3D:
            // ☁️ SKYLANDS: Floating islands with wind currents
            if height < 10 { return .open }                  // Open air below islands
            if height > 35 && noise > 0.4 { return .wind }   // Wind currents
            if height > 30 { return .hill }                  // Island tops
            if height > 25 && noise > 0.2 { return .forest } // Island vegetation
            if height > 20 { return .open }                  // Island ground
            return .open                                     // Mostly open air
            
        case .abyss3D:
            // 🌊 ABYSS: Deep underwater trenches and darkness
            if height < -35 { return .shadow }               // Deep abyss darkness
            if height < -25 { return .water }                // Deep water
            if height < -15 && noise > 0.5 { return .predator } // Dangerous deep areas
            if height < -10 { return .water }                // More water layers
            if height < 0 { return .water }                  // Surface water
            return .hill                                     // Rare surface land
            
        case .volcano3D:
            // 🌋 VOLCANO: Central peak with lava and dangerous terrain
            let centerDistance = sqrt(pow(noise - 0.5, 2))  // Distance from volcano center
            if centerDistance < 0.1 && height > 35 { return .predator } // Lava crater
            if centerDistance < 0.2 && height > 30 { return .wall }     // Volcanic walls
            if height > 25 { return .hill }                  // Volcanic slopes
            if centerDistance < 0.3 && noise > 0.5 { return .predator } // Lava flows
            if baseTerrain == .water && noise > 0.3 { return .hill }    // Dry volcanic
            if noise > 0.6 { return .wall }                  // Rocky volcanic terrain
            return .hill                                     // Volcanic ground
            
        case .continental3D:
            // 🌍 CONTINENTAL: Coherent, functional terrain with logical features
            return generateContinentalTerrain(height: height, noise: noise)
        }
    }
    
    /// 🌍 CONTINENTAL TERRAIN: Creates massive, coherent terrain regions
    private func generateContinentalTerrain(height: Double, noise: Double) -> TerrainType {
        // 🎯 HEIGHT-DOMINANT TERRAIN: Create distinct elevation-based zones
        
        // 🌊 DEEP WATER SYSTEMS: Major lakes, rivers, and deep valleys
        if height < -20 {
            return .water  // Deep water (major lakes, rivers, valleys)
        }
        
        // 🌊 SHALLOW WATER & WETLANDS: Water transition zones  
        if height < -10 {
            return .water  // Shallow water and wetland systems
        }
        
        // 🏖️ COASTAL PLAINS: Low-lying areas around water
        if height < -2 {
            return .open   // Wetland/coastal plains - large coherent areas
        }
        
        // 🌾 VAST PLAINS: The dominant terrain type - minimal noise influence
        if height < 15 {
            // Use ultra-minimal noise for enormous grassland regions
            if noise > 0.8 { return .food }   // Very rare fertile patches
            if noise < -0.9 { return .hill }  // Extremely rare gentle hills
            return .open                      // Massive grassland plains (95% of mid-elevation)
        }
        
        // 🌲 FORESTED HIGHLANDS: Elevated forest regions
        if height < 30 {
            // Reduce noise influence for large coherent forests
            if noise > 0.3 { return .forest } // Large forest areas
            return .open                      // Forest clearings and meadows
        }
        
        // ⛰️ MOUNTAIN RANGES: High elevation rocky terrain
        if height > 30 {
            if noise > 0.0 { return .wall }   // Rocky mountain areas (more rocks)
            return .hill                      // Mountain slopes and peaks
        }
        
        // Default to plains
        return .open
    }
    
    private func generateCanopyTerrain(biome: BiomeType, height: Double, noise: Double) -> TerrainType {
        // 🌍 WORLD TYPE-SPECIFIC CANOPY TERRAIN
        // First determine base canopy terrain from biome, then modify based on world type
        
        let vegetationThreshold = biome.vegetationDensity
        let baseTerrain: TerrainType
        
        if vegetationThreshold < 0.3 {
            baseTerrain = .open  // No canopy in low vegetation biomes
        } else {
            switch biome {
            case .tropicalRainforest:
                if noise > 0.2 { baseTerrain = .forest }     // Dense canopy
                else if noise > -0.3 { baseTerrain = .food } // Canopy fruits
                else { baseTerrain = .open }
            case .temperateForest, .borealForest:
                if noise > 0.4 { baseTerrain = .forest }
                else if noise > 0.0 { baseTerrain = .food }
                else if noise < -0.4 { baseTerrain = .wind } // Canopy air currents
                else { baseTerrain = .open }
            case .savanna:
                if noise > 0.6 { baseTerrain = .forest }     // Scattered trees
                else if noise > 0.2 { baseTerrain = .food }
                else { baseTerrain = .open }
            default:
                if noise > 0.5 { baseTerrain = .food }
                else if noise < -0.3 { baseTerrain = .wind }
                else { baseTerrain = .open }
            }
        }
        
        // 🎯 Apply world type modifications to canopy terrain
        return applyWorldTypeModifications(baseTerrain: baseTerrain, height: height, noise: noise)
    }
    
    private func generateAerialTerrain(biome: BiomeType, height: Double, noise: Double) -> TerrainType {
        // 🌍 WORLD TYPE-SPECIFIC AERIAL TERRAIN
        // First determine base aerial terrain from biome, then modify based on world type
        
        let baseTerrain: TerrainType
        if noise > 0.4 {
            baseTerrain = .wind  // Strong high-altitude winds
        } else if noise > 0.7 {
            baseTerrain = .food  // Aerial resources (flying insects, etc.)
        } else if noise > 0.2 && noise < 0.4 {
            baseTerrain = .wind  // Air currents
        } else {
            baseTerrain = .open
        }
        
        // 🎯 Apply world type modifications to aerial terrain
        return applyWorldTypeModifications(baseTerrain: baseTerrain, height: height, noise: noise)
    }
    
    private func determineTransitionType(gridPos: (x: Int, y: Int, z: Int), terrainType: TerrainType, layer: TerrainLayer) -> TransitionType {
        switch terrainType {
        case .wall:
            return .solid
        case .water:
            // Much easier swimming - max depth 0.25 instead of 1.0
            let depth = min(0.25, Double(gridPos.z) / Double(dimensions.depth))
            return .swim(depth: depth)
        case .hill:
            // Check if this creates a ramp
            let adjacentHeights = getAdjacentHeights(at: gridPos)
            let avgHeight = adjacentHeights.reduce(0, +) / Double(adjacentHeights.count)
            let heightDiff = abs(Double(gridPos.z) - avgHeight)
            if heightDiff > 2.0 {
                // Much easier climbing - max difficulty 0.4 instead of 1.0
                return .climb(difficulty: min(0.4, heightDiff / 20.0))
            } else {
                // Easier ramps too
                return .ramp(angle: min(0.3, heightDiff / 10.0))
            }
        case .forest:
            // 🌲 Create ultra-sparse forest: only ~1% of forest voxels are solid tree trunks
            // This creates vast navigable spaces with occasional scattered trees
            let treeHash = (gridPos.x * 73 + gridPos.y * 97 + gridPos.z * 131) % 100
            return treeHash < 1 ? .solid : .air
        case .food:
            // 🍎 Create ultra-sparse food sources: only ~1% of food voxels are solid food items
            // This creates very rare, easily reachable food scattered throughout areas
            let foodHash = (gridPos.x * 83 + gridPos.y * 107 + gridPos.z * 139) % 100  
            return foodHash < 1 ? .solid : .air
        case .sand:
            // 🏖️ Create ultra-sparse sand features: only ~2% solid for scattered dunes
            let sandHash = (gridPos.x * 71 + gridPos.y * 103 + gridPos.z * 127) % 100
            return sandHash < 2 ? .solid : .air
        case .ice:
            // 🧊 Create ultra-sparse ice features: only ~2% solid for scattered ice
            let iceHash = (gridPos.x * 79 + gridPos.y * 109 + gridPos.z * 137) % 100
            return iceHash < 2 ? .solid : .air
        case .swamp:
            // 🐊 Create ultra-sparse swamp features: only ~1% solid for rare muddy patches
            let swampHash = (gridPos.x * 89 + gridPos.y * 113 + gridPos.z * 149) % 100
            return swampHash < 1 ? .solid : .air  
        case .open:
            return layer == .aerial ? .flight(clearance: 1.0) : .air
        case .shadow:
            return .air    // Shadows remain as navigable air
        case .predator:
            return .air    // Predator areas remain as navigable air
        case .wind:
            return .air    // Wind areas remain as navigable air
        }
    }
    
    private func getAdjacentHeights(at gridPos: (x: Int, y: Int, z: Int)) -> [Double] {
        var heights: [Double] = []
        
        for direction in [Direction3D.north, .south, .east, .west] {
            let offset = direction.offset
            let adjX = gridPos.x + offset.x
            let adjY = gridPos.y + offset.y
            
            if adjX >= 0 && adjX < dimensions.width && adjY >= 0 && adjY < dimensions.height {
                heights.append(heightMap[adjX][adjY])
            }
        }
        
        return heights.isEmpty ? [Double(gridPos.z)] : heights
    }
    
    private func generateLayerTransitions() {
        // Generating layer transitions
        
        // 🔧 CRITICAL FIX: Create horizontal connectivity for bug movement
        createHorizontalConnectivity()
        
        // Create vertical connectivity throughout the world
        for x in 0..<dimensions.width {
            for y in 0..<dimensions.height {
                createVerticalConnectivity(at: (x, y))
            }
        }
        
        // Create abundant layer transition features
        createCaveEntrances()      // Underground ↔ Surface
        createTreeClimbingRoutes() // Surface ↔ Canopy  
        createAerialAccess()       // Canopy ↔ Aerial
        createVerticalShafts()     // Direct multi-layer connections
    }
    
    private func createHorizontalConnectivity() {
        // 🔧 OPTIMIZED: Create horizontal connections without the for-loop-ception

        
        // Process horizontal edges only (avoid redundant iterations)
        for z in 0..<dimensions.depth {
            for x in 0..<dimensions.width {
                for y in 0..<(dimensions.height - 1) {
                    // North-South connections (only process each edge once)
                    let currentVoxel = voxels[x][y][z]
                    let northVoxel = voxels[x][y + 1][z]
                    
                    if currentVoxel.transitionType.isPassable && northVoxel.transitionType.isPassable {
                        voxels[x][y][z].connections[.north] = true
                        voxels[x][y + 1][z].connections[.south] = true
                    }
                }
            }
            
            for y in 0..<dimensions.height {
                for x in 0..<(dimensions.width - 1) {
                    // East-West connections (only process each edge once)
                    let currentVoxel = voxels[x][y][z]
                    let eastVoxel = voxels[x + 1][y][z]
                    
                    if currentVoxel.transitionType.isPassable && eastVoxel.transitionType.isPassable {
                        voxels[x][y][z].connections[.east] = true
                        voxels[x + 1][y][z].connections[.west] = true
                    }
                }
            }
        }
        

    }
    
    private func createVerticalConnectivity(at pos: (x: Int, y: Int)) {
        // Create vertical connections between adjacent layers
        for z in 1..<dimensions.depth {
            let currentVoxel = voxels[pos.x][pos.y][z]
            let belowVoxel = voxels[pos.x][pos.y][z-1]
            
            // Allow vertical movement between open voxels
            if currentVoxel.transitionType.isPassable && belowVoxel.transitionType.isPassable {
                voxels[pos.x][pos.y][z].connections[.down] = true
                voxels[pos.x][pos.y][z-1].connections[.up] = true
            }
        }
    }
    
    private func createTreeClimbingRoutes() {
        // Create climbable tree trunk routes from surface to canopy
        let treeCount = dimensions.width / 8  // Sparse tree distribution
        
        for _ in 0..<treeCount {
            let x = Int.random(in: 0..<dimensions.width)
            let y = Int.random(in: 0..<dimensions.height)
            
            // Find surface level at this position
            let surfaceZ = findSurfaceLevel(at: (x, y))
            let canopyZ = surfaceZ + 10  // Trees extend 10 voxels up
            
            // Create climbing route with range validation
            let maxZ = min(canopyZ, dimensions.depth - 1)
            guard surfaceZ <= maxZ && surfaceZ >= 0 && surfaceZ < dimensions.depth else {
                // Skipping tree (invalid range)
                continue  // Skip if invalid range
            }
            
            // Creating tree
            for z in surfaceZ...maxZ {
                if z < dimensions.depth {
                    voxels[x][y][z] = Voxel(
                        gridPosition: (x, y, z),
                        worldPosition: voxels[x][y][z].position,
                        terrainType: .open,
                        layer: z < surfaceZ + 5 ? .surface : .canopy,
                        transitionType: .climb(difficulty: 0.3),
                        biome: voxels[x][y][z].biome
                    )
                }
            }
        }
    }
    
    private func createCaveEntrances() {
        // Create cave entrance tunnels from surface to underground
        let caveCount = dimensions.width / 12
        
        for _ in 0..<caveCount {
            let x = Int.random(in: 2..<dimensions.width-2)
            let y = Int.random(in: 2..<dimensions.height-2)
            let surfaceZ = findSurfaceLevel(at: (x, y))
            
            // Create tunnel going down
            for z in stride(from: surfaceZ, to: max(0, surfaceZ - 8), by: -1) {
                if z >= 0 {
                    // FIXED: Use proper coordinate conversion
                    let worldZ = (Double(z) / Double(dimensions.depth - 1)) * 100.0 - 50.0
                    voxels[x][y][z] = Voxel(
                        gridPosition: (x, y, z),
                        worldPosition: voxels[x][y][z].position,
                        terrainType: .open,
                        layer: determineLayer(z: worldZ),
                        transitionType: .tunnel(width: 0.8),
                        biome: voxels[x][y][z].biome
                    )
                }
            }
        }
    }
    
    private func createRockClimbingFaces() {
        // Create climbable rock faces for vertical movement
        for x in 0..<dimensions.width-1 {
            for y in 0..<dimensions.height-1 {
                let heightDiff = abs(heightMap[x][y] - heightMap[x+1][y])
                
                if heightDiff > 5.0 {  // Significant height difference
                    let baseHeight = min(heightMap[x][y], heightMap[x+1][y])
                    let topHeight = max(heightMap[x][y], heightMap[x+1][y])
                    
                    // FIXED: Convert to grid coordinates using proper mapping
                    let baseZ = max(0, min(Int((baseHeight + 50.0) / 100.0 * Double(dimensions.depth - 1)), dimensions.depth - 1))
                    let topZ = max(0, min(Int((topHeight + 50.0) / 100.0 * Double(dimensions.depth - 1)), dimensions.depth - 1))
                    
                    // Ensure valid range
                    guard baseZ <= topZ else { 
                        // Skipping rock face (invalid range)
                        continue 
                    }
                    
                    // Creating rock face
                    
                    // Create climbing face
                    for z in baseZ...topZ {
                        if z >= 0 && z < dimensions.depth {
                            let difficulty = min(1.0, heightDiff / 15.0)
                            // FIXED: Use proper coordinate conversion
                            let worldZ = (Double(z) / Double(dimensions.depth - 1)) * 100.0 - 50.0
                            voxels[x][y][z] = Voxel(
                                gridPosition: (x, y, z),
                                worldPosition: voxels[x][y][z].position,
                                terrainType: .hill,
                                layer: determineLayer(z: worldZ),
                                transitionType: .climb(difficulty: difficulty),
                                biome: voxels[x][y][z].biome
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func createAerialAccess() {
        // Create access points from canopy to aerial layer
        let accessCount = dimensions.width / 6  // More frequent access points
        
        for _ in 0..<accessCount {
            let x = Int.random(in: 0..<dimensions.width)
            let y = Int.random(in: 0..<dimensions.height)
            
            // FIXED: Use proper grid coordinates for layer boundaries
            // Canopy layer: world Z 10-30 maps to grid Z ~19-25
            // Aerial layer: world Z 30+ maps to grid Z ~25-31
            let canopyStart = Int(Double(dimensions.depth) * 0.6)  // ~19 for depth=32
            let _ = Int(Double(dimensions.depth) * 0.8)  // ~25 for depth=32 (unused but kept for clarity)
            
            for z in canopyStart..<dimensions.depth {
                if z >= 0 && z < dimensions.depth {
                    // Convert grid Z back to world Z for layer determination
                    let worldZ = (Double(z) / Double(dimensions.depth - 1)) * 100.0 - 50.0
                    voxels[x][y][z] = Voxel(
                        gridPosition: (x, y, z),
                        worldPosition: voxels[x][y][z].position,
                        terrainType: .wind,
                        layer: determineLayer(z: worldZ),
                        transitionType: .flight(clearance: 0.8),
                        biome: voxels[x][y][z].biome
                    )
                }
            }
        }
    }
    
    private func createVerticalShafts() {
        // Create vertical shafts that connect all layers
        let shaftCount = dimensions.width / 10  // Sparse but important connections
        
        for _ in 0..<shaftCount {
            let x = Int.random(in: 2..<dimensions.width-2)
            let y = Int.random(in: 2..<dimensions.height-2)
            
            // Create a shaft from underground to aerial
            for z in 0..<dimensions.depth {
                // FIXED: Use proper coordinate conversion
                let worldZ = (Double(z) / Double(dimensions.depth - 1)) * 100.0 - 50.0
                voxels[x][y][z] = Voxel(
                    gridPosition: (x, y, z),
                    worldPosition: voxels[x][y][z].position,
                    terrainType: .open,
                    layer: determineLayer(z: worldZ),
                    transitionType: .air,
                    biome: voxels[x][y][z].biome
                )
                
                                        // Add climbing points around the shaft
                        for dx in -1...1 {
                            for dy in -1...1 {
                                let adjX = x + dx
                                let adjY = y + dy
                                if adjX >= 0 && adjX < dimensions.width && adjY >= 0 && adjY < dimensions.height {
                                    if !voxels[adjX][adjY][z].transitionType.isPassable {
                                        // FIXED: Use proper coordinate conversion
                                        let worldZ = (Double(z) / Double(dimensions.depth - 1)) * 100.0 - 50.0
                                        voxels[adjX][adjY][z] = Voxel(
                                            gridPosition: (adjX, adjY, z),
                                            worldPosition: voxels[adjX][adjY][z].position,
                                            terrainType: .hill,
                                            layer: determineLayer(z: worldZ),
                                            transitionType: .climb(difficulty: 0.3),
                                            biome: voxels[adjX][adjY][z].biome
                                        )
                                    }
                                }
                            }
                        }
            }
        }
    }
    
    private func findSurfaceLevel(at pos: (x: Int, y: Int)) -> Int {
        let height = heightMap[pos.x][pos.y]
        
        // FIXED: Proper conversion from world height to grid Z coordinate
        let surfaceZ = Int((height + 50.0) / 100.0 * Double(dimensions.depth - 1))
        let clampedZ = max(0, min(surfaceZ, dimensions.depth - 1))  // Clamp to valid range
        
        // Debug extreme values
        if surfaceZ < 0 || surfaceZ >= dimensions.depth {
            // Surface level clamped
        }
        
        return clampedZ
    }
    
    private func populateResources() {
        // Populating voxel resources
        
        for x in 0..<dimensions.width {
            for y in 0..<dimensions.height {
                for z in 0..<dimensions.depth {
                    var voxel = voxels[x][y][z]
                    
                    // Add resources based on layer and biome
                    if voxel.transitionType.isPassable {
                        let resourceChance = calculateResourceChance(voxel: voxel)
                        
                        if Double.random(in: 0...1) < resourceChance {
                            let resourceType = selectResourceType(for: voxel)
                            voxel.hasFood = true
                            voxel.foodDensity = Double.random(in: 0.3...1.0)
                            voxel.resourceType = resourceType
                            voxels[x][y][z] = voxel
                        }
                    }
                }
            }
        }
    }
    
    private func calculateResourceChance(voxel: Voxel) -> Double {
        var chance = 0.05  // Base 5% chance
        
        // Biome modifiers
        switch voxel.biome {
        case .tropicalRainforest: chance *= 2.0
        case .temperateForest: chance *= 1.5
        case .desert: chance *= 0.3
        default: break
        }
        
        // Layer modifiers
        switch voxel.layer {
        case .surface: chance *= 1.2
        case .canopy: chance *= 1.1
        case .underground: chance *= 0.8
        case .aerial: chance *= 0.6
        }
        
        return min(0.3, chance)  // Cap at 30%
    }
    
    private func selectResourceType(for voxel: Voxel) -> VoxelResourceType {
        let layerResources = VoxelResourceType.allCases.filter { $0.preferredLayer == voxel.layer }
        return layerResources.randomElement() ?? .vegetation
    }
    
    private func optimizeConnectivity() {
        // Optimizing voxel connectivity
        
        // Update connections based on actual neighbor accessibility
        for x in 0..<dimensions.width {
            for y in 0..<dimensions.height {
                for z in 0..<dimensions.depth {
                    updateVoxelConnections(at: (x, y, z))
                }
            }
        }
    }
    
    private func updateVoxelConnections(at pos: (x: Int, y: Int, z: Int)) {
        var voxel = voxels[pos.x][pos.y][pos.z]
        
        for direction in Direction3D.allCases {
            let offset = direction.offset
            let neighborPos = (
                x: pos.x + offset.x,
                y: pos.y + offset.y,
                z: pos.z + offset.z
            )
            
            if isValidPosition(neighborPos) {
                let neighbor = voxels[neighborPos.x][neighborPos.y][neighborPos.z]
                voxel.connections[direction] = canConnect(from: voxel, to: neighbor, direction: direction)
            } else {
                voxel.connections[direction] = false
            }
        }
        
        voxels[pos.x][pos.y][pos.z] = voxel
    }
    
    private func canConnect(from: Voxel, to: Voxel, direction: Direction3D) -> Bool {
        // Both voxels must be passable
        guard from.transitionType.isPassable && to.transitionType.isPassable else { return false }
        
        // Special rules for vertical connections
        if direction == .up || direction == .down {
            // Vertical movement requires special transition types
            // Vertical movement requires special transition types
            switch (from.transitionType, to.transitionType) {
            case (.air, .air):
                return false
            default:
                return true
            }
        }
        
        return true
    }
    
    // MARK: - Utility Functions
    
    private func isValidPosition(_ pos: (x: Int, y: Int, z: Int)) -> Bool {
        return pos.x >= 0 && pos.x < dimensions.width &&
               pos.y >= 0 && pos.y < dimensions.height &&
               pos.z >= 0 && pos.z < dimensions.depth
    }
    
    func getTotalVoxelCount() -> Int {
        return dimensions.width * dimensions.height * dimensions.depth
    }
    
    private func noise2D(_ x: Double, _ y: Double) -> Double {
        // Seeded noise function for truly random terrain generation
        // Uses noiseSeed to ensure different worlds each time
        let n = sin((x + noiseSeed) * 12.9898 + (y + noiseSeed * 0.7) * 78.233) * 43758.5453
        return n - floor(n)
    }
    
    private func determineBiome(temperature: Double, moisture: Double) -> BiomeType {
        // 🌍 WORLD-TYPE SPECIFIC BIOME CONSTRAINTS
        // Each world type now limits which biomes can appear for dramatic differentiation
        let allowedBiomes = worldType.allowedBiomes
        
        // Determine biome based on climate as before
        let climateBiome: BiomeType
        switch (temperature, moisture) {
        case let (t, m) where t < -0.3 && m < 0.3: climateBiome = .tundra
        case let (t, m) where t < -0.3 && m >= 0.3: climateBiome = .borealForest
        case let (t, m) where t >= -0.3 && t < 0.3 && m < 0.3: climateBiome = .temperateGrassland
        case let (t, m) where t >= -0.3 && t < 0.3 && m >= 0.3: climateBiome = .temperateForest
        case let (t, m) where t >= 0.3 && m < 0.3: climateBiome = .desert
        case let (t, m) where t >= 0.3 && m >= 0.3 && m < 0.7: climateBiome = .savanna
        default: climateBiome = .tropicalRainforest
        }
        
        // 🎯 If climate biome is allowed for this world type, use it
        if allowedBiomes.contains(climateBiome) {
            return climateBiome
        }
        
        // 🔄 Otherwise, find the closest allowed biome
        return findClosestAllowedBiome(target: climateBiome, allowed: allowedBiomes, temperature: temperature, moisture: moisture)
    }
    
    /// Finds the closest allowed biome based on climate similarity
    private func findClosestAllowedBiome(target: BiomeType, allowed: [BiomeType], temperature: Double, moisture: Double) -> BiomeType {
        var bestMatch = allowed.first ?? .temperateForest
        var bestScore = Double.infinity
        
        for biome in allowed {
            // Calculate climate distance
            let tempDiff = abs(temperature - biome.averageTemperature)
            let moistDiff = abs(moisture - biome.averageMoisture)
            let score = tempDiff + moistDiff
            
            if score < bestScore {
                bestScore = score
                bestMatch = biome
            }
        }
        
        return bestMatch
    }
    
    // MARK: - Public Access Methods
    
    func getVoxel(at gridPos: (x: Int, y: Int, z: Int)) -> Voxel? {
        guard isValidPosition(gridPos) else { return nil }
        return voxels[gridPos.x][gridPos.y][gridPos.z]
    }
    
    func getVoxel(at worldPos: Position3D) -> Voxel? {
        let gridPos = worldToGrid(worldPos)
        return getVoxel(at: gridPos)
    }
    
    func worldToGrid(_ worldPos: Position3D) -> (x: Int, y: Int, z: Int) {
        let x = Int((worldPos.x - worldBounds.minX) / voxelSize)
        let y = Int((worldPos.y - worldBounds.minY) / voxelSize)
        
        // FIXED: Proper world Z to grid Z conversion
        let z = Int((worldPos.z + 50.0) / 100.0 * Double(dimensions.depth - 1))
        
        return (
            x: max(0, min(dimensions.width - 1, x)),
            y: max(0, min(dimensions.height - 1, y)),
            z: max(0, min(dimensions.depth - 1, z))
        )
    }
    
    func gridToWorld(_ gridPos: (x: Int, y: Int, z: Int)) -> Position3D {
        let x = worldBounds.minX + (Double(gridPos.x) + 0.5) * voxelSize
        let y = worldBounds.minY + (Double(gridPos.y) + 0.5) * voxelSize
        
        // FIXED: Proper grid Z to world Z conversion
        let z = (Double(gridPos.z) / Double(dimensions.depth - 1)) * 100.0 - 50.0
        
        return Position3D(x, y, z)
    }
    
    func getVoxelsInLayer(_ layer: TerrainLayer) -> [Voxel] {
        return layerVoxels[layer] ?? []
    }
    
    /// Get terrain height at world coordinates using the height map
    func getHeightAt(x: Double, z: Double) -> Double {
        // Convert world coordinates to grid coordinates
        let gridX = Int((x - worldBounds.minX) / voxelSize)
        let gridY = Int((z - worldBounds.minY) / voxelSize)
        
        // Clamp to valid range
        let clampedX = max(0, min(heightMap.count - 1, gridX))
        let clampedY = max(0, min(heightMap[0].count - 1, gridY))
        
        return heightMap[clampedX][clampedY]
    }
    
    func findSpawnPosition() -> Position3D {
        // Find a suitable spawn position on the surface with nearby open space
        let surfaceVoxels = getVoxelsInLayer(.surface).filter { $0.transitionType.isPassable }
//        print("🔍 Found \(surfaceVoxels.count) passable surface voxels for spawning")
        
        // Debug: show some surface voxel positions
        if surfaceVoxels.count > 0 {
            let _ = surfaceVoxels[0]  // Sample for debugging
//            print("🔍 Sample surface voxel: Position3D(\(sampleVoxel.position.x), \(sampleVoxel.position.y), \(sampleVoxel.position.z)), layer: \(sampleVoxel.layer)")
        }
        
        // Prefer voxels with multiple adjacent passable voxels for better movement
        let goodSpawnVoxels = surfaceVoxels.filter { voxel in
            let adjacent = getAdjacentVoxels(to: voxel)
            let passableCount = adjacent.values.count { $0.transitionType.isPassable }
            return passableCount >= 3  // At least 3 passable neighbors
        }
        
        if let spawnVoxel = goodSpawnVoxels.randomElement() {
//            print("🐛 Spawning at good location with \(getAdjacentVoxels(to: spawnVoxel).values.count { $0.transitionType.isPassable }) passable neighbors")
//            print("🐛 Selected spawn voxel: Position3D(\(spawnVoxel.position.x), \(spawnVoxel.position.y), \(spawnVoxel.position.z))")
            return spawnVoxel.position
        }
        
        // Fallback to any passable surface voxel
        if let spawnVoxel = surfaceVoxels.randomElement() {
            // Spawning at fallback location
            return spawnVoxel.position
        }
        
        // Final fallback - find actual surface height in the center of the world
        // No suitable spawn positions found, using emergency spawn
        let centerX = dimensions.width / 2
        let centerY = dimensions.height / 2
        
        // Find the highest solid voxel at the center position, then place spawn above it
        var surfaceZ = -50.0  // Start from bottom
        for z in (0..<dimensions.depth).reversed() {
            let voxel = voxels[centerX][centerY][z]
            if !voxel.transitionType.isPassable {
                // Found solid terrain, spawn above it
                surfaceZ = voxel.position.z + (voxelSize / 2.0)
                break
            }
        }
        
        // Emergency spawn at world center
        return Position3D(worldBounds.midX, worldBounds.midY, surfaceZ)
    }
    
    func getAdjacentVoxels(to voxel: Voxel) -> [Direction3D: Voxel] {
        var adjacent: [Direction3D: Voxel] = [:]
        
        for direction in Direction3D.allCases {
            let offset = direction.offset
            let neighborPos = (
                x: voxel.gridPosition.x + offset.x,
                y: voxel.gridPosition.y + offset.y,
                z: voxel.gridPosition.z + offset.z
            )
            
            if let neighbor = getVoxel(at: neighborPos) {
                adjacent[direction] = neighbor
            }
        }
        
        return adjacent
    }
}

// MARK: - Biome Extensions

extension BiomeType {
    var averageTemperature: Double {
        switch self {
        case .tundra: return -0.8
        case .borealForest: return -0.4
        case .temperateForest: return 0.0
        case .temperateGrassland: return 0.2
        case .desert: return 0.8
        case .savanna: return 0.6
        case .tropicalRainforest: return 0.7
        case .wetlands: return 0.0
        case .alpine: return -0.6
        case .coastal: return 0.1
        }
    }
    
    var averageMoisture: Double {
        switch self {
        case .tundra: return 0.2
        case .borealForest: return 0.6
        case .temperateForest: return 0.5
        case .temperateGrassland: return 0.3
        case .desert: return 0.1
        case .savanna: return 0.4
        case .tropicalRainforest: return 0.9
        case .wetlands: return 0.9
        case .alpine: return 0.4
        case .coastal: return 0.7
        }
    }
    
    var primaryTerrain: TerrainType {
        switch self {
        case .tundra: return .ice
        case .borealForest, .temperateForest: return .forest
        case .temperateGrassland: return .open
        case .desert: return .sand
        case .savanna: return .open
        case .tropicalRainforest: return .forest
        case .wetlands: return .water
        case .alpine: return .hill
        case .coastal: return .open
        }
    }
}

// MARK: - VoxelWorld Arena Adapter

/// Lightweight adapter that implements Arena interface using VoxelWorld
/// This eliminates duplicate terrain generation while maintaining Bug API compatibility
class VoxelWorldArenaAdapter: Arena {
    private let voxelWorld: VoxelWorld
    
    init(voxelWorld: VoxelWorld) {
        self.voxelWorld = voxelWorld
        // Use VoxelWorld bounds and a standard tile size
        super.init(bounds: voxelWorld.worldBounds, tileSize: CGSize(width: 20, height: 20))
    }
    
    // MARK: - Arena Interface Implementation using VoxelWorld
    
    override func terrainAt(_ position: CGPoint) -> TerrainType {
        let position3D = Position3D(position.x, position.y, 0.0) // Surface level
        return voxelWorld.getVoxel(at: position3D)?.terrainType ?? .open
    }
    
    override func isPassable(_ position: CGPoint, for dna: BugDNA) -> Bool {
        let terrain = terrainAt(position)
        return terrain.isPassable
    }
    
    override func movementModifiers(at position: CGPoint, for dna: BugDNA) -> (speed: Double, vision: Double, energyCost: Double) {
        let terrain = terrainAt(position)
        return (
            speed: terrain.speedMultiplier(for: dna),
            vision: 1.0, // Default vision
            energyCost: terrain.energyCostMultiplier(for: dna)
        )
    }
    
    override func tilesOfType(_ terrainType: TerrainType) -> [ArenaTile] {
        // Convert VoxelWorld surface voxels to ArenaTiles for compatibility
        let surfaceVoxels = voxelWorld.getVoxelsInLayer(.surface).filter { $0.terrainType == terrainType }
        return surfaceVoxels.map { voxel in
            ArenaTile(
                terrain: voxel.terrainType,
                position: CGPoint(x: voxel.position.x, y: voxel.position.y),
                size: CGSize(width: 20, height: 20)
            )
        }
    }
    
    override func findPath(from start: CGPoint, to end: CGPoint, for dna: BugDNA) -> [CGPoint] {
        // Use VoxelWorld pathfinding if available, otherwise return direct path
        // Note: Could be enhanced with proper 3D pathfinding later
        
        // Simple direct path for now - could be enhanced with proper 3D pathfinding
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
        let steps = max(1, Int(distance / 10)) // 10-unit steps
        
        var path: [CGPoint] = []
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t
            let pathPoint = CGPoint(x: x, y: y)
            
            if isPassable(pathPoint, for: dna) {
                path.append(pathPoint)
            }
        }
        
        return path.isEmpty ? [end] : path
    }
}
