//
//  Arena.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

/// Represents different types of terrain in the simulation arena
enum TerrainType: String, CaseIterable, Codable {
    case open = "open"           // Easy movement, no penalties
    case wall = "wall"           // Blocks movement completely
    case water = "water"         // Requires speed/efficiency to cross
    case hill = "hill"           // Requires strength to climb
    case shadow = "shadow"       // Reduces vision radius
    case predator = "predator"   // Aggressive creatures lurk here
    case wind = "wind"           // Affects movement based on size
    case food = "food"           // Rich feeding areas
    
    /// Visual color for terrain rendering
    var color: Color {
        switch self {
        case .open: return Color.black
        case .wall: return Color.gray
        case .water: return Color.blue.opacity(0.6)
        case .hill: return Color.brown.opacity(0.7)
        case .shadow: return Color.black.opacity(0.8)
        case .predator: return Color.red.opacity(0.3)
        case .wind: return Color.cyan.opacity(0.2)
        case .food: return Color.green.opacity(0.3)
        }
    }
    
    /// Whether bugs can move through this terrain
    var isPassable: Bool {
        return self != .wall
    }
    
    /// Speed multiplier when moving through this terrain
    func speedMultiplier(for bug: BugDNA) -> Double {
        switch self {
        case .open: return 1.0
        case .wall: return 0.0 // Cannot pass
        case .water: 
            // Fast bugs with good efficiency can cross water
            let waterAbility = (bug.speed + (2.0 - bug.energyEfficiency)) / 2.0
            let result = waterAbility - 0.5
            return max(0.1, min(1.0, result.isFinite ? result : 0.1))
        case .hill:
            // Strong bugs can climb hills faster
            return max(0.2, min(1.0, bug.strength.isFinite ? bug.strength : 0.2))
        case .shadow: return 0.8 // Slightly slower in shadows
        case .predator: 
            // Aggressive bugs or camouflaged bugs do better
            let survivalAbility = max(bug.aggression, bug.camouflage)
            return max(0.3, min(1.0, survivalAbility.isFinite ? survivalAbility : 0.3))
        case .wind:
            // Larger bugs resist wind better, smaller bugs get blown around
            let windResistance = bug.size
            return max(0.4, min(1.2, windResistance.isFinite ? windResistance : 0.4))
        case .food: return 1.1 // Slightly faster in rich areas
        }
    }
    
    /// Vision multiplier in this terrain
    func visionMultiplier(for bug: BugDNA) -> Double {
        switch self {
        case .shadow: return 0.3 // Very limited vision in shadows
        case .hill: return 1.3 // Better view from high ground
        case .water: return 0.8 // Reflection interferes
        case .predator: return 0.9 // Stress reduces awareness
        default: return 1.0
        }
    }
    
    /// Energy cost multiplier for moving in this terrain
    func energyCostMultiplier(for bug: BugDNA) -> Double {
        let result: Double
        switch self {
        case .water:
            result = 1.6 - (bug.speed * 0.4) // Reduced from 2.0, fast bugs get better efficiency
        case .hill:
            result = 1.8 - (bug.strength * 0.6) // Reduced from 2.5, strength has more impact
        case .wind:
            result = 1.3 - (bug.size * 0.2) // Reduced from 1.5, more manageable
        case .predator:
            result = 1.4 - (bug.camouflage * 0.3) // Reduced from 1.8, less punishing
        default:
            result = 1.0
        }
        
        // Ensure result is finite and within more reasonable bounds
        return max(0.5, min(2.0, result.isFinite ? result : 1.0))  // Reduced max from 5.0 to 2.0
    }
}

/// A single tile in the arena grid
struct ArenaTile {
    let terrain: TerrainType
    let position: CGPoint
    let size: CGSize
    
    /// Check if a point is within this tile
    func contains(_ point: CGPoint) -> Bool {
        let bounds = CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return bounds.contains(point)
    }
    
    /// Get the center rect for rendering
    var rect: CGRect {
        return CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}

/// Manages the environmental arena with terrain, obstacles, and challenges
class Arena {
    
    // MARK: - Properties
    
    let bounds: CGRect
    private(set) var tiles: [[ArenaTile]]
    let tileSize: CGSize
    let gridWidth: Int
    let gridHeight: Int
    
    // MARK: - Initialization
    
    init(bounds: CGRect, tileSize: CGSize = CGSize(width: 40, height: 40)) {
        self.bounds = bounds
        self.tileSize = tileSize
        self.gridWidth = Int(bounds.width / tileSize.width)
        self.gridHeight = Int(bounds.height / tileSize.height)
        self.tiles = []
        
        // Seed random number generator with current time for unique worlds
        srand48(Int(Date().timeIntervalSince1970))
        
        generateTerrain()
    }
    
    // MARK: - Terrain Generation
    
    /// Generates a procedural arena with various terrain types
    private func generateTerrain() {
        tiles = Array(repeating: Array(repeating: ArenaTile(terrain: .open, position: .zero, size: tileSize), count: gridWidth), count: gridHeight)
        
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                let position = CGPoint(
                    x: bounds.minX + (Double(col) + 0.5) * tileSize.width,
                    y: bounds.minY + (Double(row) + 0.5) * tileSize.height
                )
                
                let terrain = generateTerrainForPosition(row: row, col: col)
                tiles[row][col] = ArenaTile(terrain: terrain, position: position, size: tileSize)
            }
        }
        
        // Ensure spawn areas are clear
        clearSpawnAreas()
    }
    
    // MARK: - New Organic Terrain Generation
    
    /// Different world generation types for variety
    private enum WorldType: CaseIterable {
        case archipelago    // Island chains
        case canyon         // Deep valleys and mesas  
        case wetlands       // Lots of water and marshes
        case volcanic       // Hills and harsh terrain
        case plains         // Open areas with scattered features
        case maze           // Complex wall systems
    }
    
    /// Generates organic terrain without forced borders
    private func generateTerrainForPosition(row: Int, col: Int) -> TerrainType {
        // Choose world type based on time-based seed for variety but ensure it's in range
        let worldSeed = abs(Int(Date().timeIntervalSince1970)) % WorldType.allCases.count
        let worldType = WorldType.allCases[worldSeed]
        
        let x = Double(col)
        let y = Double(row)
        let width = Double(gridWidth)
        let height = Double(gridHeight)
        
        // Create spatial correlation using multiple noise octaves
        let noise1 = spatialNoise(x: x, y: y, scale: 0.1)
        let noise2 = spatialNoise(x: x, y: y, scale: 0.05) * 0.5
        let noise3 = spatialNoise(x: x, y: y, scale: 0.2) * 0.25
        let combinedNoise = noise1 + noise2 + noise3
        
        // Distance from edges (for some world types) - fixed for screen coordinates
        let edgeDistance = min(min(x, width - x), min(y, height - y)) / min(width, height) * 2.0
        
        // Generate terrain based on world type
        switch worldType {
        case .archipelago:
            return generateArchipelago(noise: combinedNoise, x: x, y: y, width: width, height: height)
        case .canyon:
            return generateCanyon(noise: combinedNoise, x: x, y: y)
        case .wetlands:
            return generateWetlands(noise: combinedNoise, edgeDistance: edgeDistance)
        case .volcanic:
            return generateVolcanic(noise: combinedNoise, x: x, y: y)
        case .plains:
            return generatePlains(noise: combinedNoise)
        case .maze:
            return generateMaze(noise: combinedNoise, x: x, y: y)
        }
    }
    
    /// Simulates spatial noise using deterministic pseudo-randomness
    private func spatialNoise(x: Double, y: Double, scale: Double) -> Double {
        // Use position-based seeding for spatial correlation
        let seed = Int(x * 73856093) ^ Int(y * 19349663) ^ Int(scale * 83492791)
        srand48(seed)
        return drand48()
    }
    

    
    /// Archipelago world: island chains in water
    private func generateArchipelago(noise: Double, x: Double, y: Double, width: Double, height: Double) -> TerrainType {
        // Create island clusters
        let islandNoise1 = spatialNoise(x: x, y: y, scale: 0.03)
        let islandNoise2 = spatialNoise(x: x + 1000, y: y + 1000, scale: 0.08)
        let islandStrength = (islandNoise1 + islandNoise2 * 0.5) / 1.5
        
        if islandStrength < 0.35 {
            return .water  // Ocean
        } else if islandStrength < 0.45 {
            // Coastlines
            if noise < 0.3 { return .water }
            if noise < 0.6 { return .open }
            return .hill
        } else {
            // Island interiors
            if noise < 0.15 { return .hill }
            if noise < 0.25 { return .food }
            if noise < 0.32 { return .shadow }
            if noise < 0.37 { return .predator }
            if noise < 0.42 { return .wall }
            return .open
        }
    }
    
    /// Canyon world: deep valleys and mesa formations
    private func generateCanyon(noise: Double, x: Double, y: Double) -> TerrainType {
        let valleyNoise = spatialNoise(x: x, y: y, scale: 0.02)
        
        if valleyNoise < 0.2 {
            // Valley floors
            if noise < 0.15 { return .water }     // Creek beds
            if noise < 0.35 { return .food }      // Valley vegetation
            if noise < 0.45 { return .shadow }    // Shaded areas
            return .open
        } else if valleyNoise < 0.4 {
            // Slopes
            if noise < 0.45 { return .hill }
            if noise < 0.55 { return .shadow }
            if noise < 0.60 { return .wind }      // Exposed slopes
            return .open
        } else {
            // Mesa tops and cliff faces
            if noise < 0.50 { return .wall }      // Cliff faces
            if noise < 0.70 { return .hill }      // Mesa tops
            if noise < 0.80 { return .wind }      // Exposed areas
            if noise < 0.85 { return .predator }  // Dangerous cliffs
            return .open
        }
    }
    
    /// Wetlands world: marshes and waterways
    private func generateWetlands(noise: Double, edgeDistance: Double) -> TerrainType {
        if noise < 0.25 { return .water }        // Lots of water
        if noise < 0.35 { return .open }         // Soggy ground
        if noise < 0.4 { return .food }          // Rich wetland vegetation
        if noise < 0.42 { return .shadow }       // Dense vegetation
        if noise < 0.44 { return .predator }     // Dangerous swamps
        if noise < 0.46 { return .hill }         // Occasional dry ground
        if noise < 0.47 { return .wind }         // Open marsh
        return .open
    }
    
    /// Volcanic world: hills and harsh terrain
    private func generateVolcanic(noise: Double, x: Double, y: Double) -> TerrainType {
        let volcanoNoise = spatialNoise(x: x, y: y, scale: 0.04)
        
        if volcanoNoise > 0.8 {
            // Volcanic centers
            if noise < 0.4 { return .predator }  // Lava/dangerous
            if noise < 0.7 { return .hill }      // Volcanic peaks
            return .wall                         // Solid rock
        } else {
            if noise < 0.05 { return .water }    // Rare water sources
            if noise < 0.15 { return .hill }     // Rough terrain
            if noise < 0.18 { return .wall }     // Rock outcrops
            if noise < 0.2 { return .predator }  // Dangerous areas
            if noise < 0.22 { return .wind }     // Ash-blown areas
            if noise < 0.25 { return .shadow }   // Sheltered spots
            if noise < 0.27 { return .food }     // Hardy vegetation
            return .open
        }
    }
    
    /// Plains world: open areas with scattered features
    private func generatePlains(noise: Double) -> TerrainType {
        if noise < 0.05 { return .water }        // Occasional ponds
        if noise < 0.12 { return .hill }         // Gentle hills
        if noise < 0.20 { return .food }         // Fertile patches
        if noise < 0.25 { return .shadow }       // Tree groves
        if noise < 0.28 { return .predator }     // Dangerous areas
        if noise < 0.33 { return .wall }         // Rocky outcrops
        if noise < 0.38 { return .wind }         // Windy areas
        return .open                             // Open plains (now 62% instead of 88%)
    }
    
    /// Maze world: complex wall systems
    private func generateMaze(noise: Double, x: Double, y: Double) -> TerrainType {
        let mazeNoise1 = spatialNoise(x: x, y: y, scale: 0.15)
        let mazeNoise2 = spatialNoise(x: x + 500, y: y + 500, scale: 0.3)
        
        // Create corridor patterns
        if (mazeNoise1 < 0.3 && mazeNoise2 > 0.4) || (mazeNoise1 > 0.7 && mazeNoise2 < 0.6) {
            return .wall  // Maze walls
        }
        
        // Features in open areas
        if noise < 0.12 { return .food }
        if noise < 0.20 { return .predator }
        if noise < 0.28 { return .shadow }
        if noise < 0.33 { return .water }
        if noise < 0.40 { return .hill }
        if noise < 0.45 { return .wind }
        return .open
    }
    
    /// Ensures spawn areas are open terrain with randomized locations
    private func clearSpawnAreas() {
        let spawnRadius = 2
        let numSpawnAreas = Int.random(in: 3...6) // Random number of spawn areas
        
        // Generate random spawn areas instead of fixed corners
        var spawnAreas: [(Int, Int)] = []
        
        for _ in 0..<numSpawnAreas {
            let randomCol = Int.random(in: spawnRadius...(gridWidth - spawnRadius - 1))
            let randomRow = Int.random(in: spawnRadius...(gridHeight - spawnRadius - 1))
            spawnAreas.append((randomCol, randomRow))
        }
        
        // Always ensure at least one spawn area near center for reliability
        let centerCol = gridWidth / 2 + Int.random(in: -2...2)
        let centerRow = gridHeight / 2 + Int.random(in: -2...2)
        spawnAreas.append((centerCol, centerRow))
        
        for (centerCol, centerRow) in spawnAreas {
            // Use variable radius for more organic clearing
            let actualRadius = Int.random(in: 1...spawnRadius)
            
            for row in max(0, centerRow - actualRadius)...min(gridHeight - 1, centerRow + actualRadius) {
                for col in max(0, centerCol - actualRadius)...min(gridWidth - 1, centerCol + actualRadius) {
                    // Clear to open terrain, but occasionally leave some features
                    if Double.random(in: 0...1) < 0.8 { // 80% chance to clear
                        let position = tiles[row][col].position
                        tiles[row][col] = ArenaTile(terrain: .open, position: position, size: tileSize)
                    }
                }
            }
        }
    }
    
    // MARK: - Terrain Queries
    
    /// Gets the terrain type at a specific world position
    func terrainAt(_ position: CGPoint) -> TerrainType {
        let col = Int((position.x - bounds.minX) / tileSize.width)
        let row = Int((position.y - bounds.minY) / tileSize.height)
        
        guard row >= 0 && row < gridHeight && col >= 0 && col < gridWidth else {
            return .wall // Out of bounds
        }
        
        return tiles[row][col].terrain
    }
    
    /// Gets the tile at a specific world position
    func tileAt(_ position: CGPoint) -> ArenaTile? {
        let col = Int((position.x - bounds.minX) / tileSize.width)
        let row = Int((position.y - bounds.minY) / tileSize.height)
        
        guard row >= 0 && row < gridHeight && col >= 0 && col < gridWidth else {
            return nil
        }
        
        return tiles[row][col]
    }
    
    /// Checks if a position is passable for movement
    func isPassable(_ position: CGPoint, for bug: BugDNA) -> Bool {
        let terrain = terrainAt(position)
        
        // Walls are never passable
        if terrain == .wall {
            return false
        }
        
        // Water requires minimum ability
        if terrain == .water {
            let waterAbility = (bug.speed + (2.0 - bug.energyEfficiency)) / 2.0
            return waterAbility > 0.6
        }
        
        return true
    }
    
    /// Gets all tiles of a specific terrain type
    func tilesOfType(_ terrainType: TerrainType) -> [ArenaTile] {
        var result: [ArenaTile] = []
        for row in tiles {
            for tile in row {
                if tile.terrain == terrainType {
                    result.append(tile)
                }
            }
        }
        return result
    }
    
    /// Finds a safe spawn position away from hazards
    func findSpawnPosition() -> CGPoint {
        let maxAttempts = 50
        
        for _ in 0..<maxAttempts {
            // Ensure valid spawn area bounds
            let margin = min(50.0, min(bounds.width, bounds.height) / 4.0) // Adaptive margin
            let minX = bounds.minX + margin
            let maxX = bounds.maxX - margin
            let minY = bounds.minY + margin
            let maxY = bounds.maxY - margin
            
            // Ensure valid range (prevent lowerBound > upperBound)
            let safeMinX = min(minX, maxX - 1)
            let safeMaxX = max(maxX, minX + 1)
            let safeMinY = min(minY, maxY - 1)
            let safeMaxY = max(maxY, minY + 1)
            
            let position = CGPoint(
                x: Double.random(in: safeMinX...safeMaxX),
                y: Double.random(in: safeMinY...safeMaxY)
            )
            
            let terrain = terrainAt(position)
            if terrain == .open || terrain == .food {
                return position
            }
        }
        
        // Fallback to center
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    // MARK: - Movement Helpers
    
    /// Calculates movement modifiers for a bug at a position
    func movementModifiers(at position: CGPoint, for bug: BugDNA) -> (speed: Double, vision: Double, energyCost: Double) {
        let terrain = terrainAt(position)
        
        return (
            speed: terrain.speedMultiplier(for: bug),
            vision: terrain.visionMultiplier(for: bug),
            energyCost: terrain.energyCostMultiplier(for: bug)
        )
    }
    
    /// Finds the best path between two points (simplified pathfinding)
    func findPath(from start: CGPoint, to end: CGPoint, for bug: BugDNA) -> [CGPoint] {
        // Simple direct path for now - could be upgraded to A* later
        let stepSize = min(tileSize.width, tileSize.height) / 2
        let direction = CGPoint(x: end.x - start.x, y: end.y - start.y)
        let distance = sqrt(direction.x * direction.x + direction.y * direction.y)
        
        guard distance > 0 && distance.isFinite else { return [end] }
        
        let normalizedDirection = CGPoint(x: direction.x / distance, y: direction.y / distance)
        var path: [CGPoint] = []
        var current = start
        var steps = 0
        let maxSteps = 100 // Prevent infinite loops
        
        while sqrt(pow(current.x - end.x, 2) + pow(current.y - end.y, 2)) > stepSize && steps < maxSteps {
            steps += 1
            
            let next = CGPoint(
                x: current.x + normalizedDirection.x * stepSize,
                y: current.y + normalizedDirection.y * stepSize
            )
            
            if isPassable(next, for: bug) {
                path.append(next)
                current = next
            } else {
                // Simple obstacle avoidance - try going around
                let perpendicular1 = CGPoint(x: -normalizedDirection.y, y: normalizedDirection.x)
                let perpendicular2 = CGPoint(x: normalizedDirection.y, y: -normalizedDirection.x)
                
                let option1 = CGPoint(x: current.x + perpendicular1.x * stepSize, y: current.y + perpendicular1.y * stepSize)
                let option2 = CGPoint(x: current.x + perpendicular2.x * stepSize, y: current.y + perpendicular2.y * stepSize)
                
                if isPassable(option1, for: bug) {
                    path.append(option1)
                    current = option1
                } else if isPassable(option2, for: bug) {
                    path.append(option2)
                    current = option2
                } else {
                    break // Stuck
                }
            }
        }
        
        path.append(end)
        return path
    }
}