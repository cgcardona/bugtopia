//
//  Bug.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

/// Represents an individual bug in the simulation with position, energy, and behavior
@Observable
class Bug: Identifiable, Hashable {
    
    // MARK: - Identity
    
    let id = UUID()
    let dna: BugDNA
    let generation: Int
    
    // MARK: - Physical State
    
    var position: CGPoint
    var velocity: CGPoint
    var energy: Double
    var age: Int
    
    // MARK: - Behavioral State
    
    var targetFood: CGPoint?
    var lastMovementTime: TimeInterval
    var reproductionCooldown: Int
    
    // MARK: - Constants
    
    static let maxEnergy: Double = 100.0
    static let initialEnergy: Double = 50.0
    static let energyLossPerTick: Double = 0.5
    static let reproductionThreshold: Double = 70.0
    static let reproductionCost: Double = 30.0
    static let maxAge: Int = 1000
    
    // MARK: - Computed Properties
    
    /// Whether the bug is alive (has energy and not too old)
    var isAlive: Bool {
        return energy > 0 && age < Self.maxAge
    }
    
    /// Whether the bug can reproduce
    var canReproduce: Bool {
        return energy >= Self.reproductionThreshold && reproductionCooldown <= 0 && age > 50
    }
    
    /// Current movement speed based on DNA and energy
    var currentSpeed: Double {
        let energyMultiplier = min(1.0, energy / 50.0) // Slower when low energy
        return dna.speed * energyMultiplier * 2.0
    }
    
    /// Visual radius for rendering
    var visualRadius: Double {
        return dna.size * 5.0
    }
    
    // MARK: - Initialization
    
    init(dna: BugDNA, position: CGPoint, generation: Int = 0) {
        self.dna = dna
        self.position = position
        self.generation = generation
        self.velocity = CGPoint.zero
        self.energy = Self.initialEnergy
        self.age = 0
        self.lastMovementTime = 0
        self.reproductionCooldown = 0
    }
    
    /// Creates a bug with random DNA at a random position
    static func random(in bounds: CGRect, generation: Int = 0) -> Bug {
        let randomPosition = CGPoint(
            x: Double.random(in: bounds.minX...bounds.maxX),
            y: Double.random(in: bounds.minY...bounds.maxY)
        )
        return Bug(dna: BugDNA.random(), position: randomPosition, generation: generation)
    }
    
    // MARK: - Simulation Updates
    
    /// Updates the bug's state for one simulation tick
    func update(in arena: Arena, foods: [CGPoint], otherBugs: [Bug]) {
        guard isAlive else { return }
        
        age += 1
        reproductionCooldown = max(0, reproductionCooldown - 1)
        
        // Get terrain modifiers for current position
        let modifiers = arena.movementModifiers(at: position, for: dna)
        
        // Lose energy based on efficiency and terrain
        let baseLoss = Self.energyLossPerTick * dna.energyEfficiency
        let terrainLoss = baseLoss * modifiers.energyCost
        energy -= terrainLoss
        
        // Behavioral updates with terrain awareness
        updateTargetFood(foods: foods, arena: arena)
        updateMovement(in: arena)
        checkFoodConsumption(foods: foods)
        handleBugInteractions(otherBugs: otherBugs)
        handleTerrainEffects(arena: arena)
        
        // Clamp energy
        energy = max(0, min(Self.maxEnergy, energy))
    }
    
    /// Finds and targets the nearest food within vision range, accounting for terrain
    private func updateTargetFood(foods: [CGPoint], arena: Arena) {
        // Get current vision modifier from terrain
        let modifiers = arena.movementModifiers(at: position, for: dna)
        let effectiveVision = dna.visionRadius * modifiers.vision
        
        let visibleFoods = foods.filter { food in
            let dist = distance(to: food)
            
            // Check if food is within vision range
            if dist > effectiveVision { return false }
            
            // Simple line-of-sight check for walls
            let steps = max(1, Int(dist / 10)) // Check every 10 units, minimum 1 step
            for i in 0...steps {
                let t = steps > 0 ? Double(i) / Double(steps) : 0.0
                let checkPoint = CGPoint(
                    x: position.x + (food.x - position.x) * t,
                    y: position.y + (food.y - position.y) * t
                )
                
                if arena.terrainAt(checkPoint) == .wall {
                    return false // Blocked by wall
                }
            }
            
            return true
        }
        
        // Prioritize food based on distance and terrain difficulty
        targetFood = visibleFoods.min { food1, food2 in
            let dist1 = distance(to: food1)
            let dist2 = distance(to: food2)
            
            // Factor in terrain difficulty for pathfinding
            let terrain1 = arena.terrainAt(food1)
            let terrain2 = arena.terrainAt(food2)
            
            let cost1 = dist1 * terrain1.energyCostMultiplier(for: dna)
            let cost2 = dist2 * terrain2.energyCostMultiplier(for: dna)
            
            return cost1 < cost2
        }
    }
    
    /// Updates movement based on current target and terrain constraints
    private func updateMovement(in arena: Arena) {
        var newVelocity = CGPoint.zero
        
        // Get current terrain modifiers
        let modifiers = arena.movementModifiers(at: position, for: dna)
        let terrainSpeed = currentSpeed * modifiers.speed
        
        // Move toward target food if available
        if let target = targetFood {
            // Use memory for smarter pathfinding
            if dna.memory > 0.7 {
                // Smart pathfinding for high-memory bugs
                let path = arena.findPath(from: position, to: target, for: dna)
                if path.count > 1 {
                    let nextWaypoint = path[1]
                    let direction = normalize(CGPoint(x: nextWaypoint.x - position.x, y: nextWaypoint.y - position.y))
                    newVelocity = CGPoint(x: direction.x * terrainSpeed, y: direction.y * terrainSpeed)
                }
            } else {
                // Direct movement for low-memory bugs
                let direction = normalize(CGPoint(x: target.x - position.x, y: target.y - position.y))
                newVelocity = CGPoint(x: direction.x * terrainSpeed, y: direction.y * terrainSpeed)
            }
        } else {
            // Exploration behavior based on curiosity
            let explorationChance = 0.05 + (dna.curiosity * 0.15) // 5-20% chance based on curiosity
            
            if Double.random(in: 0...1) < explorationChance {
                let randomAngle = Double.random(in: 0...(2 * Double.pi))
                newVelocity = CGPoint(
                    x: cos(randomAngle) * terrainSpeed * 0.6,
                    y: sin(randomAngle) * terrainSpeed * 0.6
                )
            } else {
                // Continue in current direction with terrain influence
                newVelocity = CGPoint(x: velocity.x * 0.9, y: velocity.y * 0.9)
            }
        }
        
        // Calculate proposed new position
        let proposedPosition = CGPoint(
            x: position.x + newVelocity.x,
            y: position.y + newVelocity.y
        )
        
        // Check if the proposed position is passable
        if arena.isPassable(proposedPosition, for: dna) {
            velocity = newVelocity
            position = proposedPosition
        } else {
            // Try to slide along walls or find alternative route
            let alternativePositions = [
                CGPoint(x: position.x + newVelocity.x, y: position.y), // Try X only
                CGPoint(x: position.x, y: position.y + newVelocity.y), // Try Y only
                CGPoint(x: position.x - newVelocity.y * 0.5, y: position.y + newVelocity.x * 0.5), // Try perpendicular
                CGPoint(x: position.x + newVelocity.y * 0.5, y: position.y - newVelocity.x * 0.5)  // Try other perpendicular
            ]
            
            for altPos in alternativePositions {
                if arena.isPassable(altPos, for: dna) {
                    velocity = CGPoint(x: altPos.x - position.x, y: altPos.y - position.y)
                    position = altPos
                    break
                }
            }
            
            // If completely stuck, reduce velocity
            if !arena.isPassable(position, for: dna) {
                velocity = CGPoint(x: velocity.x * 0.5, y: velocity.y * 0.5)
            }
        }
        
        // Keep bug within arena bounds
        position.x = max(arena.bounds.minX, min(arena.bounds.maxX, position.x))
        position.y = max(arena.bounds.minY, min(arena.bounds.maxY, position.y))
    }
    
    /// Checks if bug is close enough to consume food
    private func checkFoodConsumption(foods: [CGPoint]) {
        guard let target = targetFood else { return }
        
        if distance(to: target) < visualRadius {
            energy += 15.0 // Energy gained from food
            targetFood = nil
        }
    }
    
    /// Handles interactions with other bugs
    private func handleBugInteractions(otherBugs: [Bug]) {
        for other in otherBugs {
            guard other.id != self.id else { continue }
            
            let dist = distance(to: other.position)
            if dist < (visualRadius + other.visualRadius) {
                // Simple interaction based on aggression
                if dna.aggression > 0.6 && other.dna.aggression < 0.4 {
                    // Aggressive bug steals some energy
                    let stolenEnergy = min(5.0, other.energy * 0.1)
                    energy += stolenEnergy
                    other.energy -= stolenEnergy
                }
            }
        }
    }
    
    /// Attempts to reproduce with another compatible bug
    func reproduce(with partner: Bug) -> Bug? {
        guard canReproduce && partner.canReproduce else { return nil }
        guard distance(to: partner.position) < max(visualRadius, partner.visualRadius) else { return nil }
        
        // Create offspring with crossover and mutation
        let childDNA = BugDNA.crossover(dna, partner.dna).mutated()
        let childPosition = CGPoint(
            x: (position.x + partner.position.x) / 2.0,
            y: (position.y + partner.position.y) / 2.0
        )
        
        // Pay reproduction cost
        energy -= Self.reproductionCost
        partner.energy -= Self.reproductionCost
        
        // Set cooldown
        reproductionCooldown = 100
        partner.reproductionCooldown = 100
        
        return Bug(dna: childDNA, position: childPosition, generation: max(generation, partner.generation) + 1)
    }
    
    /// Handles special terrain effects and hazards
    private func handleTerrainEffects(arena: Arena) {
        let currentTerrain = arena.terrainAt(position)
        
        switch currentTerrain {
        case .predator:
            // Predator zones are dangerous - lose energy unless well-adapted
            let survivalAbility = max(dna.aggression, dna.camouflage)
            if survivalAbility < 0.4 {
                energy -= 2.0 // Extra energy loss in dangerous areas
            }
            
        case .shadow:
            // Shadow zones make bugs "lost" and consume extra energy unless they have good memory
            if dna.memory < 0.5 {
                energy -= 0.5 // Confusion penalty
            }
            
        case .water:
            // Water is difficult to cross without proper adaptations
            let waterAbility = (dna.speed + (2.0 - dna.energyEfficiency)) / 2.0
            if waterAbility < 0.5 {
                energy -= 1.5 // Drowning/struggling penalty
            }
            
        case .wind:
            // Wind areas affect smaller bugs more
            if dna.size < 0.8 {
                // Small bugs get blown around, affecting their movement
                let windEffect = (1.0 - dna.size) * 0.3
                velocity.x += Double.random(in: -windEffect...windEffect)
                velocity.y += Double.random(in: -windEffect...windEffect)
            }
            
        case .food:
            // Food-rich areas provide small energy bonuses
            if Double.random(in: 0...1) < 0.1 { // 10% chance per tick
                energy += 2.0
            }
            
        default:
            break
        }
    }
    
    // MARK: - Utility Functions
    
    /// Calculates distance to a point
    private func distance(to point: CGPoint) -> Double {
        let dx = position.x - point.x
        let dy = position.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Normalizes a vector
    private func normalize(_ vector: CGPoint) -> CGPoint {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y)
        guard length > 0 && length.isFinite else { return CGPoint.zero }
        return CGPoint(x: vector.x / length, y: vector.y / length)
    }
    
    // MARK: - Hashable & Equatable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Bug, rhs: Bug) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Extensions

extension Bug: CustomStringConvertible {
    var description: String {
        return "Bug(gen: \(generation), energy: \(String(format: "%.1f", energy)), age: \(age))"
    }
}