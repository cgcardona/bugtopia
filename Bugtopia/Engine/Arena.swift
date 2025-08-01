//
//  Arena.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

/// Represents different types of terrain in the simulation arena
enum TerrainType: String, CaseIterable {
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
    
    /// Determines terrain type based on position and procedural rules
    private func generateTerrainForPosition(row: Int, col: Int) -> TerrainType {
        let centerX = Double(gridWidth) / 2.0
        let centerY = Double(gridHeight) / 2.0
        let distanceFromCenter = sqrt(pow(Double(col) - centerX, 2) + pow(Double(row) - centerY, 2))
        let maxDistance = sqrt(pow(centerX, 2) + pow(centerY, 2))
        let normalizedDistance = distanceFromCenter / maxDistance
        
        // Use multiple noise layers for more complex terrain
        let noise1 = Double.random(in: 0...1)
        let noise2 = Double.random(in: 0...1)
        let combinedNoise = (noise1 + noise2 * 0.5) / 1.5
        
        // Randomized edge barriers (not always walls)
        if col == 0 || col == gridWidth - 1 || row == 0 || row == gridHeight - 1 {
            let edgeNoise = Double.random(in: 0...1)
            if edgeNoise < 0.7 {
                return .wall
            } else if edgeNoise < 0.85 {
                return .water
            } else if edgeNoise < 0.95 {
                return .hill
            } else {
                return .open // Occasional gaps in the border!
            }
        }
        
        // Distance-based terrain probability (varies by distance from center)
        let innerThreshold = 0.3
        let outerThreshold = 0.7
        
        if normalizedDistance < innerThreshold {
            // Inner area - more open with some features
            if combinedNoise < 0.08 {
                return .food
            } else if combinedNoise < 0.12 {
                return .water
            } else if combinedNoise < 0.15 {
                return .hill
            } else if combinedNoise < 0.17 {
                return .wall
            }
        } else if normalizedDistance < outerThreshold {
            // Middle ring - mixed terrain
            if combinedNoise < 0.06 {
                return .wall
            } else if combinedNoise < 0.10 {
                return .water
            } else if combinedNoise < 0.14 {
                return .hill
            } else if combinedNoise < 0.16 {
                return .shadow
            } else if combinedNoise < 0.18 {
                return .predator
            } else if combinedNoise < 0.21 {
                return .wind
            } else if combinedNoise < 0.24 {
                return .food
            }
        } else {
            // Outer ring - harsher terrain
            if combinedNoise < 0.10 {
                return .wall
            } else if combinedNoise < 0.15 {
                return .predator
            } else if combinedNoise < 0.20 {
                return .shadow
            } else if combinedNoise < 0.25 {
                return .wind
            } else if combinedNoise < 0.28 {
                return .hill
            } else if combinedNoise < 0.30 {
                return .water
            }
        }
        
        // Add some random scattered features
        let scatterNoise = Double.random(in: 0...1)
        if scatterNoise < 0.05 {
            return [.wall, .water, .hill, .food].randomElement() ?? .open
        }
        
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
            
            for row in max(1, centerRow - actualRadius)...min(gridHeight - 2, centerRow + actualRadius) {
                for col in max(1, centerCol - actualRadius)...min(gridWidth - 2, centerCol + actualRadius) {
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
            let position = CGPoint(
                x: Double.random(in: bounds.minX + 50...bounds.maxX - 50),
                y: Double.random(in: bounds.minY + 50...bounds.maxY - 50)
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