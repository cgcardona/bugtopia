//
//  Arena3D.swift
//  Bugtopia
//
//  Phase 7.0: 3D Arena System
//  Created by Assistant on 8/1/25.
//

import Foundation
import SwiftUI
import SceneKit

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

/// 3D terrain layers and biome types
enum TerrainLayer: String, CaseIterable, Codable {
    case underground = "underground"    // Below surface caves, tunnels
    case surface = "surface"           // Ground level terrain
    case canopy = "canopy"             // Tree/elevated level
    case aerial = "aerial"             // Sky/flying zone
    
    /// Height range for this layer
    var heightRange: ClosedRange<Double> {
        switch self {
        case .underground: return -100.0...0.0
        case .surface: return 0.0...20.0
        case .canopy: return 20.0...60.0
        case .aerial: return 60.0...200.0
        }
    }
    
    /// Visual color for layer rendering
    var color: Color {
        switch self {
        case .underground: return Color.brown.opacity(0.8)
        case .surface: return Color.green.opacity(0.6)
        case .canopy: return Color.green.opacity(0.4)
        case .aerial: return Color.cyan.opacity(0.2)
        }
    }
}

/// Enhanced 3D terrain tile
struct ArenaTile3D {
    let terrain: TerrainType
    let layer: TerrainLayer
    let position: Position3D
    let size: CGSize
    let height: Double  // Elevation/depth value
    
    /// Check if a 3D point is within this tile
    func contains(_ point: Position3D) -> Bool {
        let bounds2D = CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        
        let inXY = bounds2D.contains(point.position2D)
        let inZ = layer.heightRange.contains(point.z)
        
        return inXY && inZ
    }
    
    /// Get the 3D bounds for this tile
    var bounds3D: (min: Position3D, max: Position3D) {
        let minX = position.x - size.width / 2
        let maxX = position.x + size.width / 2
        let minY = position.y - size.height / 2
        let maxY = position.y + size.height / 2
        
        return (
            min: Position3D(minX, minY, layer.heightRange.lowerBound),
            max: Position3D(maxX, maxY, layer.heightRange.upperBound)
        )
    }
}

/// 3D Arena system with layered terrain and height maps
class Arena3D: ObservableObject {
    
    // MARK: - Properties
    
    /// 3D tile grid organized by layers
    private(set) var tiles: [TerrainLayer: [[ArenaTile3D]]] = [:]
    
    /// Height map for terrain elevation
    private(set) var heightMap: [[Double]] = []
    
    /// World dimensions
    let bounds: CGRect
    let maxHeight: Double = 200.0
    let minHeight: Double = -100.0
    
    /// Grid resolution
    private let gridWidth: Int
    private let gridHeight: Int
    private let tileSize: CGSize
    
    /// Current world type (extended for 3D)
    private(set) var worldType: WorldType3D
    
    /// Advanced terrain generation data
    private var biomeMap: [[BiomeType?]] = []
    private var temperatureMap: [[Double]] = []
    private var moistureMap: [[Double]] = []
    private var erosionMap: [[Double]] = []
    private var vegetationDensity: [[Double]] = []
    
    // MARK: - Initialization
    
    init(bounds: CGRect, gridWidth: Int = 40, gridHeight: Int = 30) {
        self.bounds = bounds
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        self.tileSize = CGSize(
            width: bounds.width / Double(gridWidth),
            height: bounds.height / Double(gridHeight)
        )
        self.worldType = WorldType3D.allCases.randomElement() ?? .continental3D
        
        generateTerrain()
    }
    
    // MARK: - 3D Terrain Generation
    
    private func generateTerrain() {
        print("🌍 Generating 3D Arena: \(worldType.rawValue)")
        
        // Generate complex height map with multiple octaves
        generateAdvancedHeightMap()
        
        // Generate moisture and temperature maps for realistic ecosystems
        generateClimateData()
        
        // Generate biome map for terrain variation (requires climate data)
        generateBiomeMap()
        
        // Apply erosion simulation now that climate data is available
        simulateErosion()
        
        // Generate terrain for each layer with complex interactions
        for layer in TerrainLayer.allCases {
            tiles[layer] = generateAdvancedLayerTerrain(for: layer)
        }
        
        // Post-process terrain for realistic features
        applyTerrainPostProcessing()
        
        print("🏔️ Generated advanced 3D terrain with \(TerrainLayer.allCases.count) layers")
        print("🌿 Biomes: \(biomeMap.flatMap { $0 }.compactMap { $0 }.count) biome zones")
        print("🌡️ Climate zones: \(temperatureMap.flatMap { $0 }.count) temperature variations")
    }
    
    private func generateAdvancedHeightMap() {
        heightMap = Array(repeating: Array(repeating: 0.0, count: gridWidth), count: gridHeight)
        
        // Multi-octave noise for realistic terrain
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                let x = Double(col) / Double(gridWidth)
                let y = Double(row) / Double(gridHeight)
                
                // Base terrain from world type
                let baseHeight = worldType.generateHeight(at: x, y: y)
                
                // Add multiple octaves of noise for detail
                let detailNoise1 = noise2D(x * 8, y * 8) * 10.0    // Fine detail
                let detailNoise2 = noise2D(x * 16, y * 16) * 5.0   // Very fine detail
                let ridgeNoise = abs(noise2D(x * 4, y * 4)) * 15.0  // Ridge patterns
                
                // Combine all noise layers
                let finalHeight = baseHeight + detailNoise1 + detailNoise2 + ridgeNoise
                
                // Apply world-specific modifications
                heightMap[row][col] = applyWorldTypeModifications(height: finalHeight, x: x, y: y)
            }
        }
        
        // Erosion will be applied after climate data is generated
    }
    
    private func generateBiomeMap() {
        biomeMap = Array(repeating: Array(repeating: nil, count: gridWidth), count: gridHeight)
        
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                let x = Double(col) / Double(gridWidth)
                let y = Double(row) / Double(gridHeight)
                let height = heightMap[row][col]
                let temperature = temperatureMap[row][col]
                let moisture = moistureMap[row][col]
                
                // Determine biome based on temperature, moisture, and height
                biomeMap[row][col] = determineBiome(
                    temperature: temperature,
                    moisture: moisture,
                    height: height,
                    x: x, y: y
                )
            }
        }
    }
    
    private func generateClimateData() {
        // Initialize climate maps
        temperatureMap = Array(repeating: Array(repeating: 0.0, count: gridWidth), count: gridHeight)
        moistureMap = Array(repeating: Array(repeating: 0.0, count: gridWidth), count: gridHeight)
        erosionMap = Array(repeating: Array(repeating: 0.0, count: gridWidth), count: gridHeight)
        vegetationDensity = Array(repeating: Array(repeating: 0.0, count: gridWidth), count: gridHeight)
        
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                let x = Double(col) / Double(gridWidth)
                let y = Double(row) / Double(gridHeight)
                let height = heightMap[row][col]
                
                // Temperature: affected by latitude (y), altitude, and world type
                let latitudeTemp = 1.0 - abs(y - 0.5) * 2.0  // Warmer at center (equator)
                let altitudeTemp = max(0.0, 1.0 - height / 100.0)  // Cooler at higher altitudes
                let worldTempModifier = worldType.getTemperatureModifier(x: x, y: y)
                temperatureMap[row][col] = max(0.0, min(1.0, 
                    (latitudeTemp * 0.6 + altitudeTemp * 0.3 + worldTempModifier * 0.1) + 
                    noise2D(x * 3, y * 3) * 0.2
                ))
                
                // Moisture: affected by height, distance from water, and prevailing winds
                let heightMoisture = height < 0 ? 1.0 : max(0.0, 1.0 - height / 80.0)
                let windMoisture = noise2D(x * 2 + 100, y * 2 + 100) * 0.5 + 0.5
                let worldMoistureModifier = worldType.getMoistureModifier(x: x, y: y)
                moistureMap[row][col] = max(0.0, min(1.0,
                    (heightMoisture * 0.4 + windMoisture * 0.4 + worldMoistureModifier * 0.2) +
                    noise2D(x * 5, y * 5) * 0.15
                ))
                
                // Erosion: affected by height, slope, and moisture
                let slope = calculateSlope(row: row, col: col)
                erosionMap[row][col] = slope * moistureMap[row][col] * 0.5
            }
        }
    }
    
    // MARK: - Advanced Terrain Generation Helpers
    
    private func applyWorldTypeModifications(height: Double, x: Double, y: Double) -> Double {
        switch worldType {
        case .continental3D:
            // Smooth continental shelves
            let distanceFromEdge = min(x, 1-x, y, 1-y) * 4
            return height * min(1.0, distanceFromEdge)
            
        case .archipelago3D:
            // Create distinct islands
            let islandPattern = noise2D(x * 3, y * 3) + noise2D(x * 6, y * 6) * 0.5
            return islandPattern > 0.1 ? height : min(height, -15.0)
            
        case .canyon3D:
            // Create dramatic canyon systems
            let canyonPattern = abs(noise2D(x * 8, y * 4))
            return canyonPattern < 0.3 ? height - 80.0 : height + 20.0
            
        case .cavern3D:
            // Underground cave networks
            return height - 20.0
            
        case .skylands3D:
            // Floating island platforms
            let platformNoise = noise2D(x * 4, y * 4)
            return platformNoise > 0.2 ? height + 60.0 : max(height, 0.0)
            
        case .abyss3D:
            // Deep oceanic trenches
            let trenchPattern = noise2D(x * 2, y * 8)
            return trenchPattern < -0.3 ? height - 100.0 : height
            
        case .volcano3D:
            // Volcanic peaks and craters
            let centerDistance = sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2))
            let volcanoHeight = max(0, 1.0 - centerDistance * 3.0) * 120.0
            return height + volcanoHeight
        }
    }
    
    private func simulateErosion() {
        // Simple erosion simulation - smooth high areas, deepen valleys
        var newHeightMap = heightMap
        
        for _ in 0..<5 { // 5 erosion passes
            for row in 1..<(gridHeight-1) {
                for col in 1..<(gridWidth-1) {
                    let currentHeight = heightMap[row][col]
                    let neighbors = [
                        heightMap[row-1][col], heightMap[row+1][col],
                        heightMap[row][col-1], heightMap[row][col+1]
                    ]
                    
                    let avgNeighborHeight = neighbors.reduce(0.0, +) / Double(neighbors.count)
                    let erosionRate = erosionMap[row][col] * 0.1
                    
                    // Erode towards average of neighbors
                    newHeightMap[row][col] = currentHeight + (avgNeighborHeight - currentHeight) * erosionRate
                }
            }
            heightMap = newHeightMap
        }
    }
    
    private func determineBiome(temperature: Double, moisture: Double, height: Double, x: Double, y: Double) -> BiomeType? {
        // Special height-based biomes
        if height > 80 { return .alpine }
        if height < -30 && moisture > 0.7 { return .wetlands }
        if abs(x - 0.5) < 0.1 || abs(y - 0.5) < 0.1 { return .coastal } // Near edges
        
        // Temperature-moisture based biome selection
        for biome in BiomeType.allCases {
            if biome.temperatureRange.contains(temperature) && biome.moistureRange.contains(moisture) {
                // Add some randomness for biome boundaries
                let biomeNoise = noise2D(x * 10, y * 10)
                if biomeNoise > -0.3 { // 70% chance to use this biome
                    return biome
                }
            }
        }
        
        // Fallback biome
        return .temperateGrassland
    }
    
    private func calculateSlope(row: Int, col: Int) -> Double {
        guard row > 0, row < gridHeight-1, col > 0, col < gridWidth-1 else { return 0.0 }
        
        let currentHeight = heightMap[row][col]
        let neighbors = [
            heightMap[row-1][col], heightMap[row+1][col],
            heightMap[row][col-1], heightMap[row][col+1]
        ]
        
        let maxHeightDiff = neighbors.map { abs($0 - currentHeight) }.max() ?? 0.0
        return min(1.0, maxHeightDiff / 50.0) // Normalize slope
    }
    
    private func generateAdvancedLayerTerrain(for layer: TerrainLayer) -> [[ArenaTile3D]] {
        var layerTiles: [[ArenaTile3D]] = []
        
        for row in 0..<gridHeight {
            var tileRow: [ArenaTile3D] = []
            
            for col in 0..<gridWidth {
                let x = bounds.minX + (Double(col) + 0.5) * tileSize.width
                let y = bounds.minY + (Double(row) + 0.5) * tileSize.height
                let height = heightMap[row][col]
                let biome = biomeMap[row][col]
                let temperature = temperatureMap[row][col]
                let moisture = moistureMap[row][col]
                let vegetation = vegetationDensity[row][col]
                
                // Generate terrain based on biome, climate, and layer
                let terrain = generateBiomeBasedTerrain(
                    layer: layer,
                    biome: biome,
                    height: height,
                    temperature: temperature,
                    moisture: moisture,
                    vegetation: vegetation,
                    x: Double(col) / Double(gridWidth),
                    y: Double(row) / Double(gridHeight)
                )
                
                let position3D = Position3D(x, y, height + layer.heightRange.lowerBound)
                
                let tile = ArenaTile3D(
                    terrain: terrain,
                    layer: layer,
                    position: position3D,
                    size: tileSize,
                    height: height
                )
                
                tileRow.append(tile)
            }
            
            layerTiles.append(tileRow)
        }
        
        return layerTiles
    }
    
    private func generateBiomeBasedTerrain(
        layer: TerrainLayer,
        biome: BiomeType?,
        height: Double,
        temperature: Double,
        moisture: Double,
        vegetation: Double,
        x: Double,
        y: Double
    ) -> TerrainType {
        
        // Layer-specific base terrain generation
        let layerBaseTerrain = generateLayerBaseTerrain(layer: layer, height: height)
        
        // Biome-specific modifications
        guard let biome = biome else { return layerBaseTerrain }
        
        let biomeTerrains = biome.primaryTerrains
        let biomeNoise = noise2D(x * 12, y * 12)
        
        // Select terrain based on biome preferences and layer
        switch layer {
        case .underground:
            return generateUndergroundBiomeTerrain(biome: biome, moisture: moisture, biomeNoise: biomeNoise)
        case .surface:
            return generateSurfaceBiomeTerrain(biome: biome, height: height, temperature: temperature, moisture: moisture, biomeNoise: biomeNoise)
        case .canopy:
            return generateCanopyBiomeTerrain(biome: biome, vegetation: vegetation, biomeNoise: biomeNoise)
        case .aerial:
            return generateAerialBiomeTerrain(biome: biome, height: height, biomeNoise: biomeNoise)
        }
    }
    
    private func generateLayerBaseTerrain(layer: TerrainLayer, height: Double) -> TerrainType {
        switch layer {
        case .underground:
            return height < -50 ? .water : .open
        case .surface:
            if height < -10 { return .water }
            if height > 60 { return .hill }
            return .open
        case .canopy:
            return .open
        case .aerial:
            return .open
        }
    }
    
    private func generateUndergroundBiomeTerrain(biome: BiomeType, moisture: Double, biomeNoise: Double) -> TerrainType {
        switch biome {
        case .wetlands, .coastal:
            if biomeNoise > 0.3 { return .water }
            if biomeNoise > -0.2 { return .swamp }
            return .open
        case .desert:
            if biomeNoise > 0.5 { return .wall }  // Rock formations
            return .open
        default:
            if biomeNoise > 0.4 { return .wall }
            if moisture > 0.7 && biomeNoise > 0.0 { return .water }
            if biomeNoise < -0.4 { return .food }  // Underground resources
            return .open
        }
    }
    
    private func generateSurfaceBiomeTerrain(biome: BiomeType, height: Double, temperature: Double, moisture: Double, biomeNoise: Double) -> TerrainType {
        switch biome {
        case .desert:
            if biomeNoise > 0.6 { return .hill }
            if biomeNoise > 0.3 { return .sand }
            if biomeNoise < -0.7 { return .food }  // Oasis
            return .open
        case .tropicalRainforest, .temperateForest, .borealForest:
            if biomeNoise > 0.4 { return .forest }
            if biomeNoise > 0.0 { return .food }   // Rich forest resources
            if biomeNoise < -0.5 { return .water } // Forest streams
            return .open
        case .wetlands:
            if biomeNoise > 0.2 { return .water }
            if biomeNoise > -0.2 { return .swamp }
            if biomeNoise < -0.5 { return .food }
            return .open
        case .alpine, .tundra:
            if temperature < 0.3 && biomeNoise > 0.3 { return .ice }
            if biomeNoise > 0.5 { return .hill }
            if biomeNoise < -0.6 { return .food }
            return .open
        case .coastal:
            if height < 5 && biomeNoise > 0.0 { return .water }
            if biomeNoise > 0.4 { return .sand }
            if biomeNoise < -0.4 { return .food }
            return .open
        default: // Grasslands, Savanna
            if biomeNoise > 0.6 { return .hill }
            if biomeNoise > 0.2 { return .food }   // Abundant grassland resources
            if biomeNoise < -0.6 { return .water }
            return .open
        }
    }
    
    private func generateCanopyBiomeTerrain(biome: BiomeType, vegetation: Double, biomeNoise: Double) -> TerrainType {
        let vegetationThreshold = biome.vegetationDensity
        
        if vegetation < vegetationThreshold * 0.3 {
            return .open  // No canopy in low vegetation areas
        }
        
        switch biome {
        case .tropicalRainforest:
            if biomeNoise > 0.2 { return .forest }  // Dense canopy
            if biomeNoise > -0.3 { return .food }   // Canopy fruits
            return .open
        case .temperateForest, .borealForest:
            if biomeNoise > 0.4 { return .forest }
            if biomeNoise > 0.0 { return .food }
            if biomeNoise < -0.4 { return .wind }   // Canopy air currents
            return .open
        case .savanna:
            if biomeNoise > 0.6 { return .forest }  // Scattered trees
            if biomeNoise > 0.2 { return .food }
            return .open
        default:
            if biomeNoise > 0.5 { return .food }
            if biomeNoise < -0.3 { return .wind }
            return .open
        }
    }
    
    private func generateAerialBiomeTerrain(biome: BiomeType, height: Double, biomeNoise: Double) -> TerrainType {
        // Aerial layer is mostly open with wind currents and occasional resources
        if height > 100 && biomeNoise > 0.4 {
            return .wind  // Strong high-altitude winds
        }
        
        if biomeNoise > 0.7 {
            return .food  // Aerial resources (insects, etc.)
        }
        
        if biomeNoise > 0.2 && biomeNoise < 0.4 {
            return .wind  // Air currents
        }
        
        return .open
    }
    
    private func applyTerrainPostProcessing() {
        // Calculate vegetation density based on biome and climate
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                if let biome = biomeMap[row][col] {
                    let temperature = temperatureMap[row][col]
                    let moisture = moistureMap[row][col]
                    let height = heightMap[row][col]
                    
                    // Base vegetation from biome
                    var vegetation = biome.vegetationDensity
                    
                    // Modify based on climate
                    vegetation *= temperature * 0.5 + 0.5  // Temperature factor
                    vegetation *= moisture * 0.7 + 0.3     // Moisture factor
                    
                    // Altitude penalty
                    if height > 50 {
                        vegetation *= max(0.1, 1.0 - (height - 50) / 100.0)
                    }
                    
                    vegetationDensity[row][col] = max(0.0, min(1.0, vegetation))
                }
            }
        }
        
        // Smooth terrain transitions
        smoothTerrainTransitions()
        
        // Add terrain features (rivers, paths, etc.)
        addTerrainFeatures()
    }
    
    private func smoothTerrainTransitions() {
        // Smooth biome boundaries to prevent harsh transitions
        for layer in TerrainLayer.allCases {
            guard var layerTiles = tiles[layer] else { continue }
            
            for row in 1..<(gridHeight-1) {
                for col in 1..<(gridWidth-1) {
                    let currentTerrain = layerTiles[row][col].terrain
                    let neighbors = [
                        layerTiles[row-1][col].terrain,
                        layerTiles[row+1][col].terrain,
                        layerTiles[row][col-1].terrain,
                        layerTiles[row][col+1].terrain
                    ]
                    
                    // If this tile is very different from neighbors, consider smoothing
                    let differentNeighbors = neighbors.filter { $0 != currentTerrain }.count
                    if differentNeighbors >= 3 {
                        // Replace with most common neighbor terrain
                        let neighborCounts = Dictionary(grouping: neighbors, by: { $0 }).mapValues { $0.count }
                        if let mostCommon = neighborCounts.max(by: { $0.value < $1.value })?.key {
                            layerTiles[row][col] = ArenaTile3D(
                                terrain: mostCommon,
                                layer: layer,
                                position: layerTiles[row][col].position,
                                size: layerTiles[row][col].size,
                                height: layerTiles[row][col].height
                            )
                        }
                    }
                }
            }
            
            tiles[layer] = layerTiles
        }
    }
    
    private func addTerrainFeatures() {
        // Add rivers in surface layer
        addRivers()
        
        // Add cave systems in underground layer
        addCaveSystems()
        
        // Add wind corridors in aerial layer
        addWindCorridors()
    }
    
    private func addRivers() {
        guard var surfaceTiles = tiles[.surface] else { return }
        
        // Simple river generation - flow from high to low areas
        let riverCount = Int.random(in: 1...3)
        
        for _ in 0..<riverCount {
            let startRow = Int.random(in: 0..<gridHeight)
            let startCol = Int.random(in: 0..<gridWidth)
            
            var currentRow = startRow
            var currentCol = startCol
            
            // Follow gradient downhill
            for _ in 0..<min(gridWidth, gridHeight) {
                guard currentRow >= 0, currentRow < gridHeight, currentCol >= 0, currentCol < gridWidth else { break }
                
                // Make this tile water
                surfaceTiles[currentRow][currentCol] = ArenaTile3D(
                    terrain: .water,
                    layer: .surface,
                    position: surfaceTiles[currentRow][currentCol].position,
                    size: surfaceTiles[currentRow][currentCol].size,
                    height: surfaceTiles[currentRow][currentCol].height
                )
                
                // Find lowest neighbor
                var lowestHeight = heightMap[currentRow][currentCol]
                var nextRow = currentRow
                var nextCol = currentCol
                
                for dRow in -1...1 {
                    for dCol in -1...1 {
                        let newRow = currentRow + dRow
                        let newCol = currentCol + dCol
                        
                        guard newRow >= 0, newRow < gridHeight, newCol >= 0, newCol < gridWidth else { continue }
                        
                        if heightMap[newRow][newCol] < lowestHeight {
                            lowestHeight = heightMap[newRow][newCol]
                            nextRow = newRow
                            nextCol = newCol
                        }
                    }
                }
                
                // If no lower neighbor found, stop
                if nextRow == currentRow && nextCol == currentCol { break }
                
                currentRow = nextRow
                currentCol = nextCol
            }
        }
        
        tiles[.surface] = surfaceTiles
    }
    
    private func addCaveSystems() {
        guard var undergroundTiles = tiles[.underground] else { return }
        
        // Create cave tunnels
        let caveCount = Int.random(in: 2...4)
        
        for _ in 0..<caveCount {
            let startRow = Int.random(in: 0..<gridHeight)
            let startCol = Int.random(in: 0..<gridWidth)
            
            var currentRow = startRow
            var currentCol = startCol
            
            // Random walk to create cave system
            for _ in 0..<Int.random(in: 20...50) {
                guard currentRow >= 0, currentRow < gridHeight, currentCol >= 0, currentCol < gridWidth else { break }
                
                // Clear this tile
                undergroundTiles[currentRow][currentCol] = ArenaTile3D(
                    terrain: .open,
                    layer: .underground,
                    position: undergroundTiles[currentRow][currentCol].position,
                    size: undergroundTiles[currentRow][currentCol].size,
                    height: undergroundTiles[currentRow][currentCol].height
                )
                
                // Random walk
                currentRow += Int.random(in: -1...1)
                currentCol += Int.random(in: -1...1)
            }
        }
        
        tiles[.underground] = undergroundTiles
    }
    
    private func addWindCorridors() {
        guard var aerialTiles = tiles[.aerial] else { return }
        
        // Create wind corridors for flying creatures
        let corridorCount = Int.random(in: 3...6)
        
        for _ in 0..<corridorCount {
            let isHorizontal = Bool.random()
            
            if isHorizontal {
                let row = Int.random(in: 0..<gridHeight)
                for col in 0..<gridWidth {
                    if Double.random(in: 0...1) < 0.7 { // 70% chance for wind
                        aerialTiles[row][col] = ArenaTile3D(
                            terrain: .wind,
                            layer: .aerial,
                            position: aerialTiles[row][col].position,
                            size: aerialTiles[row][col].size,
                            height: aerialTiles[row][col].height
                        )
                    }
                }
            } else {
                let col = Int.random(in: 0..<gridWidth)
                for row in 0..<gridHeight {
                    if Double.random(in: 0...1) < 0.7 { // 70% chance for wind
                        aerialTiles[row][col] = ArenaTile3D(
                            terrain: .wind,
                            layer: .aerial,
                            position: aerialTiles[row][col].position,
                            size: aerialTiles[row][col].size,
                            height: aerialTiles[row][col].height
                        )
                    }
                }
            }
        }
        
        tiles[.aerial] = aerialTiles
    }
    
    // MARK: - 3D Pathfinding & Queries
    
    /// Find a valid spawn position in 3D space
    func findSpawnPosition3D(preferredLayer: TerrainLayer = .surface) -> Position3D {
        for _ in 0..<100 { // Try 100 random positions
            let x = Double.random(in: bounds.minX...bounds.maxX)
            let y = Double.random(in: bounds.minY...bounds.maxY)
            let z = Double.random(in: preferredLayer.heightRange)
            
            let position = Position3D(x, y, z)
            
            if isValidPosition(position) {
                return position
            }
        }
        
        // Fallback to center of preferred layer
        return Position3D(
            bounds.midX, 
            bounds.midY, 
            preferredLayer.heightRange.lowerBound + 
            (preferredLayer.heightRange.upperBound - preferredLayer.heightRange.lowerBound) / 2
        )
    }
    
    /// Check if a 3D position is valid (not inside walls, etc.)
    func isValidPosition(_ position: Position3D) -> Bool {
        guard bounds.contains(position.position2D) else { return false }
        
        // Find the appropriate layer
        guard let layer = TerrainLayer.allCases.first(where: { $0.heightRange.contains(position.z) }) else {
            return false
        }
        
        guard let layerTiles = tiles[layer] else { return false }
        
        // Find the tile at this position
        let col = Int((position.x - bounds.minX) / tileSize.width)
        let row = Int((position.y - bounds.minY) / tileSize.height)
        
        guard row >= 0, row < gridHeight, col >= 0, col < gridWidth else { return false }
        
        let tile = layerTiles[row][col]
        return tile.terrain.isPassable
    }
    
    /// Get terrain at a 3D position
    func getTerrainAt(_ position: Position3D) -> TerrainType? {
        guard bounds.contains(position.position2D) else { return nil }
        
        // Find the appropriate layer
        guard let layer = TerrainLayer.allCases.first(where: { $0.heightRange.contains(position.z) }) else {
            return nil
        }
        
        guard let layerTiles = tiles[layer] else { return nil }
        
        // Find the tile at this position
        let col = Int((position.x - bounds.minX) / tileSize.width)
        let row = Int((position.y - bounds.minY) / tileSize.height)
        
        guard row >= 0, row < gridHeight, col >= 0, col < gridWidth else { return nil }
        
        return layerTiles[row][col].terrain
    }
    
    /// Get height at a 2D position
    func getHeightAt(_ position: CGPoint) -> Double {
        let col = Int((position.x - bounds.minX) / tileSize.width)
        let row = Int((position.y - bounds.minY) / tileSize.height)
        
        guard row >= 0, row < gridHeight, col >= 0, col < gridWidth else { return 0.0 }
        
        return heightMap[row][col]
    }
    
    // MARK: - Backward Compatibility
    
    /// Get 2D tiles for the surface layer (backward compatibility)
    var surfaceTiles: [[ArenaTile3D]] {
        return tiles[.surface] ?? []
    }
    
    /// Convert to 2D arena tiles (for existing systems)
    func get2DTiles() -> [[ArenaTile]] {
        guard let surfaceLayer = tiles[.surface] else { return [] }
        
        return surfaceLayer.map { row in
            row.map { tile3D in
                ArenaTile(
                    terrain: tile3D.terrain,
                    position: tile3D.position.position2D,
                    size: tile3D.size
                )
            }
        }
    }
    
    /// Get terrain at a 2D position (for backward compatibility)
    func terrainAt(_ position: CGPoint) -> TerrainType {
        // Convert to grid coordinates
        let col = Int((position.x - bounds.minX) / (bounds.width / Double(gridWidth)))
        let row = Int((position.y - bounds.minY) / (bounds.height / Double(gridHeight)))
        
        // Bounds check
        guard row >= 0, row < gridHeight, col >= 0, col < gridWidth,
              let surfaceLayer = tiles[.surface] else {
            return .open
        }
        
        return surfaceLayer[row][col].terrain
    }
    
    /// Get movement modifiers at a 2D position (for backward compatibility)
    func movementModifiers(at position: CGPoint, for dna: BugDNA) -> (speed: Double, vision: Double, energy: Double) {
        let terrain = terrainAt(position)
        return (
            speed: terrain.speedMultiplier(for: dna),
            vision: terrain.visionMultiplier(for: dna),
            energy: terrain.energyCostMultiplier(for: dna)
        )
    }
    
    /// Find a spawn position (for backward compatibility)
    func findSpawnPosition() -> CGPoint {
        // Find a random open position on the surface
        let maxAttempts = 100
        for _ in 0..<maxAttempts {
            let x = Double.random(in: bounds.minX...bounds.maxX)
            let y = Double.random(in: bounds.minY...bounds.maxY)
            let position = CGPoint(x: x, y: y)
            
            let terrain = terrainAt(position)
            if terrain == .open || terrain == .hill {
                return position
            }
        }
        
        // Fallback to center if no suitable position found
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Get tiles of a specific type (for backward compatibility)
    func tilesOfType(_ terrainType: TerrainType) -> [ArenaTile] {
        guard let surfaceLayer = tiles[.surface] else { return [] }
        
        var matchingTiles: [ArenaTile] = []
        for row in surfaceLayer {
            for tile3D in row {
                if tile3D.terrain == terrainType {
                    let tile2D = ArenaTile(
                        terrain: tile3D.terrain,
                        position: tile3D.position.position2D,
                        size: tile3D.size
                    )
                    matchingTiles.append(tile2D)
                }
            }
        }
        return matchingTiles
    }
    
    /// Create a temporary Arena object for backward compatibility
    func createTempArena() -> Arena {
        return Arena(bounds: bounds)
    }
}

// MARK: - Biome System

/// Biome types for realistic ecosystem generation
enum BiomeType: String, CaseIterable {
    case tundra = "Tundra"
    case borealForest = "Boreal Forest"
    case temperateForest = "Temperate Forest"
    case temperateGrassland = "Temperate Grassland"
    case desert = "Desert"
    case savanna = "Savanna"
    case tropicalRainforest = "Tropical Rainforest"
    case wetlands = "Wetlands"
    case alpine = "Alpine"
    case coastal = "Coastal"
    
    /// Temperature range for this biome (0.0 to 1.0)
    var temperatureRange: ClosedRange<Double> {
        switch self {
        case .tundra: return 0.0...0.2
        case .borealForest: return 0.1...0.4
        case .temperateForest: return 0.3...0.7
        case .temperateGrassland: return 0.4...0.8
        case .desert: return 0.6...1.0
        case .savanna: return 0.7...0.9
        case .tropicalRainforest: return 0.8...1.0
        case .wetlands: return 0.2...0.6
        case .alpine: return 0.0...0.3
        case .coastal: return 0.4...0.8
        }
    }
    
    /// Moisture range for this biome (0.0 to 1.0)
    var moistureRange: ClosedRange<Double> {
        switch self {
        case .tundra: return 0.1...0.4
        case .borealForest: return 0.4...0.8
        case .temperateForest: return 0.5...0.9
        case .temperateGrassland: return 0.2...0.6
        case .desert: return 0.0...0.2
        case .savanna: return 0.2...0.5
        case .tropicalRainforest: return 0.8...1.0
        case .wetlands: return 0.9...1.0
        case .alpine: return 0.3...0.7
        case .coastal: return 0.6...1.0
        }
    }
    
    /// Vegetation density for this biome (0.0 to 1.0)
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
    
    /// Primary terrain types for this biome
    var primaryTerrains: [TerrainType] {
        switch self {
        case .tundra: return [.open, .ice, .water]
        case .borealForest: return [.forest, .open, .hill]
        case .temperateForest: return [.forest, .hill, .open]
        case .temperateGrassland: return [.open, .hill, .food]
        case .desert: return [.sand, .open, .hill]
        case .savanna: return [.open, .food, .hill]
        case .tropicalRainforest: return [.forest, .food, .water]
        case .wetlands: return [.water, .swamp, .food]
        case .alpine: return [.hill, .ice, .open]
        case .coastal: return [.open, .water, .sand]
        }
    }
}

// MARK: - 3D World Types

enum WorldType3D: String, CaseIterable {
    case continental3D = "Continental 3D"
    case archipelago3D = "Archipelago 3D"
    case canyon3D = "Canyon 3D"
    case cavern3D = "Cavern 3D"
    case skylands3D = "Skylands 3D"
    case abyss3D = "Abyss 3D"
    case volcano3D = "Volcano 3D"
    
    /// Generate height value for terrain
    func generateHeight(at x: Double, y: Double) -> Double {
        switch self {
        case .continental3D:
            // Rolling hills and plains
            return noise2D(x * 3, y * 3) * 40.0
            
        case .archipelago3D:
            // Islands with water
            let islandNoise = noise2D(x * 2, y * 2)
            return islandNoise > 0.2 ? islandNoise * 30.0 : -20.0
            
        case .canyon3D:
            // Deep valleys and high mesas
            let canyonNoise = noise2D(x * 4, y * 2)
            return canyonNoise > 0.5 ? 60.0 : -40.0
            
        case .cavern3D:
            // Underground cave system
            return noise2D(x * 5, y * 5) * 20.0 - 30.0
            
        case .skylands3D:
            // Floating islands
            let skyNoise = noise2D(x * 3, y * 3)
            return skyNoise > 0.3 ? 80.0 + skyNoise * 40.0 : 10.0
            
        case .abyss3D:
            // Deep underwater trenches
            return noise2D(x * 2, y * 4) * 30.0 - 60.0
            
        case .volcano3D:
            // Volcanic peaks and lava flows
            let volcanoNoise = noise2D(x * 2, y * 2)
            return volcanoNoise > 0.4 ? volcanoNoise * 80.0 : volcanoNoise * 20.0
        }
    }
    
    /// Generate terrain type for a specific layer and position
    func generateTerrain(at x: Double, y: Double, height: Double, layer: TerrainLayer, 
                        gridX: Int, gridY: Int, gridWidth: Int, gridHeight: Int) -> TerrainType {
        
        let centerX = Double(gridWidth) / 2.0
        let centerY = Double(gridHeight) / 2.0
        let distanceFromCenter = sqrt(pow(Double(gridX) - centerX, 2) + pow(Double(gridY) - centerY, 2))
        let maxDistance = sqrt(centerX * centerX + centerY * centerY)
        let normalizedDistance = distanceFromCenter / maxDistance
        
        // Layer-specific terrain generation
        switch layer {
        case .underground:
            return generateUndergroundTerrain(height: height, distance: normalizedDistance)
        case .surface:
            return generateSurfaceTerrain(height: height, distance: normalizedDistance)
        case .canopy:
            return generateCanopyTerrain(height: height, distance: normalizedDistance)
        case .aerial:
            return generateAerialTerrain(height: height, distance: normalizedDistance)
        }
    }
    
    private func generateUndergroundTerrain(height: Double, distance: Double) -> TerrainType {
        if Double.random(in: 0...1) < 0.3 { return .wall }  // Cave walls
        if Double.random(in: 0...1) < 0.1 { return .water } // Underground pools
        if Double.random(in: 0...1) < 0.05 { return .food } // Cave resources
        return .open
    }
    
    private func generateSurfaceTerrain(height: Double, distance: Double) -> TerrainType {
        if height < -10 { return .water }
        if height > 50 { return .hill }
        if Double.random(in: 0...1) < 0.15 { return .wall }
        if Double.random(in: 0...1) < 0.1 { return .food }
        if Double.random(in: 0...1) < 0.05 { return .predator }
        return .open
    }
    
    private func generateCanopyTerrain(height: Double, distance: Double) -> TerrainType {
        if Double.random(in: 0...1) < 0.2 { return .wall }  // Tree branches
        if Double.random(in: 0...1) < 0.15 { return .food } // Canopy resources
        if Double.random(in: 0...1) < 0.1 { return .wind }  // Windy areas
        return .open
    }
    
    private func generateAerialTerrain(height: Double, distance: Double) -> TerrainType {
        if Double.random(in: 0...1) < 0.3 { return .wind }  // Air currents
        if Double.random(in: 0...1) < 0.05 { return .food } // Aerial resources
        return .open
    }
    
    /// Get temperature modifier for world type
    func getTemperatureModifier(x: Double, y: Double) -> Double {
        switch self {
        case .continental3D:
            return noise2D(x * 2, y * 2) * 0.3
        case .archipelago3D:
            return 0.2  // Islands are warmer
        case .canyon3D:
            return -0.1  // Canyons are cooler
        case .cavern3D:
            return -0.3  // Underground is cooler
        case .skylands3D:
            return -0.2  // High altitude is cooler
        case .abyss3D:
            return -0.4  // Deep ocean is cold
        case .volcano3D:
            let centerDistance = sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2))
            return max(0, 1.0 - centerDistance * 2.0) * 0.5  // Hot near volcano center
        }
    }
    
    /// Get moisture modifier for world type
    func getMoistureModifier(x: Double, y: Double) -> Double {
        switch self {
        case .continental3D:
            return noise2D(x * 3, y * 3) * 0.2
        case .archipelago3D:
            return 0.3  // Islands have high moisture
        case .canyon3D:
            return -0.2  // Canyons are dry
        case .cavern3D:
            return 0.1  // Caves have moderate moisture
        case .skylands3D:
            return -0.1  // High altitude is drier
        case .abyss3D:
            return 0.4  // Ocean areas are very moist
        case .volcano3D:
            let centerDistance = sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2))
            return centerDistance > 0.3 ? 0.0 : -0.3  // Dry near volcano, normal elsewhere
        }
    }
}

// MARK: - Noise Generation

/// Simple 2D noise function for terrain generation
func noise2D(_ x: Double, _ y: Double) -> Double {
    let xi = Int(x) & 255
    let yi = Int(y) & 255
    let xf = x - floor(x)
    let yf = y - floor(y)
    
    let u = fade(xf)
    let v = fade(yf)
    
    let aa = hash(xi) &+ yi
    let ab = hash(xi) &+ yi &+ 1
    let ba = hash(xi &+ 1) &+ yi
    let bb = hash(xi &+ 1) &+ yi &+ 1
    
    let x1 = lerp(grad(hash(aa), xf, yf), grad(hash(ba), xf - 1, yf), u)
    let x2 = lerp(grad(hash(ab), xf, yf - 1), grad(hash(bb), xf - 1, yf - 1), u)
    
    return lerp(x1, x2, v)
}

private func fade(_ t: Double) -> Double {
    return t * t * t * (t * (t * 6 - 15) + 10)
}

private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    return a + t * (b - a)
}

private func grad(_ hash: Int, _ x: Double, _ y: Double) -> Double {
    let h = hash & 3
    let u = h < 2 ? x : y
    let v = h < 2 ? y : x
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
}

private func hash(_ x: Int) -> Int {
    var h = x
    h ^= h >> 16
    h = h &* 0x85ebca6b  // Use overflow multiplication
    h ^= h >> 13
    h = h &* 0xc2b2ae35  // Use overflow multiplication
    h ^= h >> 16
    return h & 255
}