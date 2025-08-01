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
    
    // MARK: - Neural Intelligence
    
    private let neuralNetwork: NeuralNetwork
    var lastDecision: BugOutputs?
    
    // MARK: - Behavioral State
    
    var targetFood: CGPoint?
    var consumedFood: CGPoint?     // Food consumed this tick (for removal)
    var targetPrey: Bug?
    var predatorThreat: Bug?
    var lastMovementTime: TimeInterval
    var reproductionCooldown: Int
    var huntingCooldown: Int
    var fleeingCooldown: Int
    
    // MARK: - Communication & Social State
    
    var recentSignals: [Signal] = []        // Signals received recently
    var lastSignalTime: TimeInterval = 0    // When last signal was sent
    var currentGroup: UUID?                 // Group this bug belongs to
    var groupRole: GroupRole = .member      // Role within the group
    var signalCooldown: Int = 0             // Cooldown between signals
    
    // MARK: - Tool & Construction State
    
    var carriedResources: [ResourceType: Int] = [:]  // Resources currently carried
    var currentProject: ToolBlueprint?               // Tool being constructed
    var constructionCooldown: Int = 0                // Cooldown after construction
    var lastToolUse: TimeInterval = 0                // When last used a tool
    var knownTools: Set<UUID> = []                   // Tools this bug is aware of
    
    // MARK: - Constants
    
    static let maxEnergy: Double = 100.0
    static let initialEnergy: Double = 80.0  // Increased from 50 to give more survival time
    static let energyLossPerTick: Double = 0.12  // Further reduced to 0.12 (3.6/sec)
    static let reproductionThreshold: Double = 55.0  // Reduced to make reproduction easier
    static let reproductionCost: Double = 20.0  // Reduced from 30 to encourage reproduction
    static let maxAge: Int = 1000
    static let huntingCooldownTime: Int = 30     // Ticks between hunting attempts
    static let fleeingCooldownTime: Int = 50     // Ticks to maintain flee state
    static let signalCooldownTime: Int = 15      // Minimum ticks between signals
    static let constructionCooldownTime: Int = 60   // Ticks between construction attempts
    
    // MARK: - Computed Properties
    
    /// Whether the bug is alive (has energy and not too old)
    var isAlive: Bool {
        return energy > 0 && age < Self.maxAge
    }
    
    /// Whether the bug can reproduce
    var canReproduce: Bool {
        return energy >= Self.reproductionThreshold && reproductionCooldown <= 0 && age > 30 // Reduced age requirement
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
    
    /// Convenient access to hunting behavior
    var huntingBehavior: HuntingBehavior? {
        return dna.speciesTraits.huntingBehavior
    }
    
    /// Convenient access to defensive behavior
    var defensiveBehavior: DefensiveBehavior? {
        return dna.speciesTraits.defensiveBehavior
    }
    
    /// Current carrying capacity based on DNA traits
    var maxCarryingCapacity: Int {
        return Int(dna.toolDNA.carryingCapacity * 10) // Base capacity of 2-20 resources
    }
    
    /// Current weight being carried
    var currentWeight: Double {
        return carriedResources.reduce(0.0) { total, entry in
            let (resourceType, quantity) = entry
            return total + (resourceType.weight * Double(quantity))
        }
    }
    
    /// Whether this bug can carry more resources
    var canCarryMore: Bool {
        let totalItems = carriedResources.values.reduce(0, +)
        return totalItems < maxCarryingCapacity && currentWeight < dna.toolDNA.carryingCapacity * 20
    }
    
    // MARK: - Initialization
    
    init(dna: BugDNA, position: CGPoint, generation: Int = 0) {
        self.dna = dna
        self.position = position
        self.generation = generation
        self.velocity = CGPoint.zero
        self.energy = Self.initialEnergy
        self.age = 0
        self.neuralNetwork = NeuralNetwork(dna: dna.neuralDNA)
        self.lastMovementTime = 0
        self.reproductionCooldown = 0
        self.huntingCooldown = 0
        self.fleeingCooldown = 0
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
    
    /// Updates the bug's state for one simulation tick using neural network decisions
    func update(in arena: Arena, foods: [CGPoint], otherBugs: [Bug]) {
        guard isAlive else { return }
        
        age += 1
        reproductionCooldown = max(0, reproductionCooldown - 1)
        huntingCooldown = max(0, huntingCooldown - 1)
        fleeingCooldown = max(0, fleeingCooldown - 1)
        signalCooldown = max(0, signalCooldown - 1)
        constructionCooldown = max(0, constructionCooldown - 1)
        
        // Clear consumed food marker from previous tick
        consumedFood = nil
        
        // Get terrain modifiers for current position
        let modifiers = arena.movementModifiers(at: position, for: dna)
        
        // Lose energy based on efficiency, terrain, and species metabolic rate
        let baseLoss = Self.energyLossPerTick * dna.energyEfficiency * dna.speciesTraits.metabolicRate
        let terrainLoss = baseLoss * modifiers.energyCost
        energy -= terrainLoss
        
        // Performance optimization: Skip complex behaviors for very young bugs
        if age < 10 {
            // Simple movement for newborns
            let safeSpeed = max(0.1, currentSpeed) // Ensure positive speed
            velocity = CGPoint(
                x: Double.random(in: -safeSpeed...safeSpeed),
                y: Double.random(in: -safeSpeed...safeSpeed)
            )
            position.x += velocity.x
            position.y += velocity.y
            handleBoundaryCollisions(arena: arena)
            energy = max(0, min(Self.maxEnergy, energy))
            return
        }
        
        // Neural network decision making (with timeout protection)
        makeNeuralDecision(in: arena, foods: foods, otherBugs: otherBugs)
        
        // Execute decisions based on species and neural outputs
        updatePredatorPreyTargets(otherBugs: otherBugs)
        executeMovement(in: arena, modifiers: modifiers)
        
        // Species-specific behaviors
        if dna.speciesTraits.speciesType.canEatPlants {
            checkFoodConsumption(foods: foods)
        }
        
        if dna.speciesTraits.speciesType.canHunt && huntingCooldown == 0 {
            handleHuntingBehavior(otherBugs: otherBugs)
        }
        
        handleBugInteractions(otherBugs: otherBugs)
        handleTerrainEffects(arena: arena)
        
        // Process communications (internal method)
        processSignals(in: arena, foods: foods, otherBugs: otherBugs)
        
        // Tool and construction behaviors
        if dna.toolDNA.constructionDrive > 0.3 && constructionCooldown <= 0 {
            considerConstruction(in: arena, otherBugs: otherBugs)
        }
        
        // Edge proximity penalty - discourages clustering near boundaries
        applyEdgeProximityPenalty(arena: arena)
        
        // Clamp energy
        energy = max(0, min(Self.maxEnergy, energy))
    }
    
    /// Uses neural network to make behavioral decisions
    private func makeNeuralDecision(in arena: Arena, foods: [CGPoint], otherBugs: [Bug]) {
        // Create sensory inputs for neural network
        let inputs = BugSensors.createInputs(bug: self, arena: arena, foods: foods, otherBugs: otherBugs)
        
        // Get neural network outputs
        let rawOutputs = neuralNetwork.predict(inputs: inputs)
        lastDecision = BugOutputs(from: rawOutputs)
        
        // Neural network can override hardcoded food targeting
        if let decision = lastDecision {
            // High exploration tendency means ignore current food and wander
            if decision.exploration > 0.7 {
                targetFood = nil
            } else if dna.speciesTraits.speciesType.canEatPlants {
                // Use traditional food seeking when exploitation mode (for herbivores/omnivores)
                updateTargetFood(foods: foods, arena: arena)
            }
        }
    }
    
    /// Executes movement based on neural network decision
    private func executeMovement(in arena: Arena, modifiers: (speed: Double, vision: Double, energyCost: Double)) {
        guard let decision = lastDecision else {
            // Fallback to random movement if no decision
            velocity = CGPoint(x: Double.random(in: -1...1), y: Double.random(in: -1...1))
            return
        }
        
        let terrainSpeed = currentSpeed * modifiers.speed
        
        // Neural network controls movement direction
        let neuralVelocity = CGPoint(
            x: decision.moveX * terrainSpeed,
            y: decision.moveY * terrainSpeed
        )
        
        // Behavioral priority system: fleeing > hunting > food seeking > exploration
        var finalVelocity = neuralVelocity
        
        // 1. FLEEING - highest priority
        if let threat = predatorThreat, decision.fleeing > 0.5 {
            let fleeDirection = normalize(CGPoint(x: position.x - threat.position.x, y: position.y - threat.position.y))
            let fleeSpeedMultiplier = dna.speciesTraits.defensiveBehavior?.fleeSpeedMultiplier ?? 1.3
            let fleeVelocity = CGPoint(
                x: fleeDirection.x * terrainSpeed * fleeSpeedMultiplier,
                y: fleeDirection.y * terrainSpeed * fleeSpeedMultiplier
            )
            finalVelocity = fleeVelocity
            
            // Energy cost for fleeing
            energy -= dna.speciesTraits.defensiveBehavior?.fleeEnergyCost ?? 1.5
        }
        // 2. HUNTING - second priority
        else if let prey = targetPrey, decision.hunting > 0.5, dna.speciesTraits.speciesType.canHunt {
            let huntDirection = normalize(CGPoint(x: prey.position.x - position.x, y: prey.position.y - position.y))
            let chaseSpeedMultiplier = dna.speciesTraits.huntingBehavior?.chaseSpeedMultiplier ?? 1.2
            let huntVelocity = CGPoint(
                x: huntDirection.x * terrainSpeed * chaseSpeedMultiplier,
                y: huntDirection.y * terrainSpeed * chaseSpeedMultiplier
            )
            
            // Blend hunting direction with neural movement (70% hunting, 30% neural)
            finalVelocity = CGPoint(
                x: huntVelocity.x * 0.7 + neuralVelocity.x * 0.3,
                y: huntVelocity.y * 0.7 + neuralVelocity.y * 0.3
            )
        }
        // 3. FOOD SEEKING - third priority
        else if let target = targetFood, decision.exploration < 0.7 {
            let direction = normalize(CGPoint(x: target.x - position.x, y: target.y - position.y))
            let foodVelocity = CGPoint(
                x: direction.x * terrainSpeed,
                y: direction.y * terrainSpeed
            )
            
            // Blend food seeking with neural movement (60% food, 40% neural)
            finalVelocity = CGPoint(
                x: foodVelocity.x * 0.6 + neuralVelocity.x * 0.4,
                y: foodVelocity.y * 0.6 + neuralVelocity.y * 0.4
            )
        }
        // 4. PURE NEURAL EXPLORATION - lowest priority
        
        velocity = finalVelocity
        
        // Calculate proposed new position
        let proposedPosition = CGPoint(
            x: position.x + velocity.x,
            y: position.y + velocity.y
        )
        
        // Check if the proposed position is passable
        if arena.isPassable(proposedPosition, for: dna) {
            position = proposedPosition
        } else {
            // Neural network should learn to avoid walls, but provide basic collision
            velocity = CGPoint(x: velocity.x * -0.5, y: velocity.y * -0.5)
        }
        
        // Keep bug within arena bounds with bouncing behavior
        handleBoundaryCollisions(arena: arena)
    }
    
    /// Updates predator and prey targets based on neural network decisions
    private func updatePredatorPreyTargets(otherBugs: [Bug]) {
        guard let decision = lastDecision else { return }
        
        // Clear old targets if neural network decides to stop hunting/fleeing
        if decision.hunting < 0.3 {
            targetPrey = nil
        }
        if decision.fleeing < 0.3 {
            predatorThreat = nil
        }
        
        // Update predator threat if fleeing behavior is high
        if decision.fleeing > 0.6 {
            let potentialPredators = otherBugs.filter { other in
                other.id != self.id &&
                other.dna.speciesTraits.speciesType.canHunt &&
                other.dna.speciesTraits.speciesType != self.dna.speciesTraits.speciesType &&
                distance(to: other.position) < (dna.speciesTraits.defensiveBehavior?.predatorDetection ?? 0.5) * 100
            }
            
            predatorThreat = potentialPredators.min(by: { distance(to: $0.position) < distance(to: $1.position) })
        }
        
        // Update prey target if hunting behavior is high and this bug can hunt
        if decision.hunting > 0.6 && dna.speciesTraits.speciesType.canHunt {
            let potentialPrey = otherBugs.filter { other in
                other.id != self.id &&
                other.dna.speciesTraits.speciesType != self.dna.speciesTraits.speciesType &&
                distance(to: other.position) < (dna.speciesTraits.huntingBehavior?.preyDetectionRange ?? 50.0)
            }
            
            targetPrey = potentialPrey.min(by: { distance(to: $0.position) < distance(to: $1.position) })
        }
    }
    
    /// Handles hunting behavior for carnivores and omnivores
    private func handleHuntingBehavior(otherBugs: [Bug]) {
        guard let huntingBehavior = dna.speciesTraits.huntingBehavior,
              let decision = lastDecision,
              decision.hunting > 0.5 else { return }
        
        // Performance limit: Only check first 10 nearby bugs
        let nearbyBugs = Array(otherBugs.prefix(10))
        
        // Find nearby prey with distance pre-filtering for performance
        let nearbyPrey = nearbyBugs.filter { other in
            other.id != self.id &&
            other.isAlive &&
            other.dna.speciesTraits.speciesType != self.dna.speciesTraits.speciesType
        }.filter { other in
            distance(to: other.position) < min(huntingBehavior.preyDetectionRange, 100.0) // Cap detection range
        }
        
        // Only attempt hunting on closest prey
        if let closestPrey = nearbyPrey.min(by: { distance(to: $0.position) < distance(to: $1.position) }) {
            let huntDistance = distance(to: closestPrey.position)
            
            // Successful hunt if close enough and conditions are met
            if huntDistance < visualRadius * 0.5 {
                let huntSuccess = calculateHuntSuccess(prey: closestPrey, huntingBehavior: huntingBehavior)
                
                if Double.random(in: 0...1) < huntSuccess {
                    // Successful hunt! - FIXED: Energy conservation
                    let energyGained = min(dna.speciesTraits.huntEnergyGain, 50.0) // Cap energy gain
                    let actualEnergyTransfer = min(energyGained, closestPrey.energy) // Can't drain more than prey has
                    
                    energy += actualEnergyTransfer
                    
                    // Prey loses EXACTLY what predator gains (no energy creation)
                    closestPrey.energy -= actualEnergyTransfer
                    
                    huntingCooldown = Self.huntingCooldownTime
                } else {
                    // Failed hunt - energy cost
                    energy -= min(huntingBehavior.huntingEnergyCost, 10.0) // Cap energy loss
                    huntingCooldown = Self.huntingCooldownTime / 2
                }
            }
        }
    }
    
    /// Calculates hunting success probability
    private func calculateHuntSuccess(prey: Bug, huntingBehavior: HuntingBehavior) -> Double {
        let sizeAdvantage = (dna.size / prey.dna.size) * 0.3
        let speedAdvantage = (dna.speed / prey.dna.speed) * 0.2
        let stealthBonus = huntingBehavior.stealthLevel * 0.2
        let preyDefense = prey.dna.speciesTraits.defensiveBehavior?.counterAttackSkill ?? 0.0
        let preyCamouflage = prey.dna.camouflage * 0.15
        
        let baseSuccess = huntingBehavior.huntingIntensity * 0.4
        let totalSuccess = baseSuccess + sizeAdvantage + speedAdvantage + stealthBonus - preyDefense - preyCamouflage
        
        return max(0.05, min(0.95, totalSuccess)) // Clamp between 5% and 95%
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
                if path.count > 1, path.indices.contains(1) {
                    let nextWaypoint = path[1]
                    let direction = normalize(CGPoint(x: nextWaypoint.x - position.x, y: nextWaypoint.y - position.y))
                    newVelocity = CGPoint(x: direction.x * terrainSpeed, y: direction.y * terrainSpeed)
                } else if let firstWaypoint = path.first {
                    // Fallback to direct movement if pathfinding fails
                    let direction = normalize(CGPoint(x: firstWaypoint.x - position.x, y: firstWaypoint.y - position.y))
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
        
        // Keep bug within arena bounds with bouncing behavior
        handleBoundaryCollisions(arena: arena)
    }
    
    /// Handles boundary collisions with proper bouncing physics
    private func handleBoundaryCollisions(arena: Arena) {
        let buffer = visualRadius // Small buffer to prevent edge sticking
        let damping = 0.7 // Energy loss on bounce
        var bounced = false
        
        // Handle X boundaries
        if position.x <= arena.bounds.minX + buffer {
            position.x = arena.bounds.minX + buffer
            if velocity.x < 0 {
                velocity.x *= -damping // Bounce with energy loss
                bounced = true
            }
        } else if position.x >= arena.bounds.maxX - buffer {
            position.x = arena.bounds.maxX - buffer
            if velocity.x > 0 {
                velocity.x *= -damping // Bounce with energy loss
                bounced = true
            }
        }
        
        // Handle Y boundaries
        if position.y <= arena.bounds.minY + buffer {
            position.y = arena.bounds.minY + buffer
            if velocity.y < 0 {
                velocity.y *= -damping // Bounce with energy loss
                bounced = true
            }
        } else if position.y >= arena.bounds.maxY - buffer {
            position.y = arena.bounds.maxY - buffer
            if velocity.y > 0 {
                velocity.y *= -damping // Bounce with energy loss
                bounced = true
            }
        }
        
        // Moderate energy penalty for hitting boundaries (discourages edge clustering)
        if bounced {
            energy -= 0.2 // Reduced energy cost for hitting walls
            
            // Add randomization to prevent getting stuck in corners
            let randomAngle = Double.random(in: 0...(2 * Double.pi))
            let randomSpeed = Double.random(in: 0.3...0.8) * currentSpeed
            velocity.x += cos(randomAngle) * randomSpeed * 0.2 // Reduced randomization
            velocity.y += sin(randomAngle) * randomSpeed * 0.2
        }
    }
    
    /// Applies energy penalty for being too close to world boundaries
    private func applyEdgeProximityPenalty(arena: Arena) {
        // Calculate distance to nearest edge
        let edgeDistance = min(
            min(position.x - arena.bounds.minX, arena.bounds.maxX - position.x),
            min(position.y - arena.bounds.minY, arena.bounds.maxY - position.y)
        )
        
        // Apply moderate penalties based on proximity to edges
        if edgeDistance < 100.0 { // Within 100 pixels of edge (reduced range)
            let proximityFactor = (100.0 - edgeDistance) / 100.0 // 0.0 to 1.0
            let basePenalty = proximityFactor * 0.08 // Reduced to 0.08 energy loss per tick
            energy -= basePenalty
            
            // Moderate penalty for bugs very close to edges
            if edgeDistance < 30.0 {
                energy -= 0.15 * proximityFactor // Reduced additional penalty
                
                // Gentle movement encouragement away from edges
                if edgeDistance < 15.0 { // Only for bugs very close to edge
                    let pushStrength = 0.3 // Reduced push strength
                    let centerX = arena.bounds.midX
                    let centerY = arena.bounds.midY
                    
                    // Safer division by zero check
                    let deltaX = centerX - position.x
                    let deltaY = centerY - position.y
                    
                    if abs(deltaX) > 0.1 {
                        let pushX = (deltaX / abs(deltaX)) * pushStrength
                        velocity.x += pushX * 0.05 // Gentler push
                    }
                    if abs(deltaY) > 0.1 {
                        let pushY = (deltaY / abs(deltaY)) * pushStrength
                        velocity.y += pushY * 0.05 // Gentler push
                    }
                }
            }
        }
    }
    
    /// Checks if bug is close enough to consume food
    private func checkFoodConsumption(foods: [CGPoint]) {
        guard let target = targetFood,
              dna.speciesTraits.speciesType.canEatPlants else { return }
        
        if distance(to: target) < visualRadius {
            // Mark this food as consumed so other bugs can't also eat it
            consumedFood = target
            
            // Consume food based on species
            let energyGain = dna.speciesTraits.plantEnergyGain
            energy += energyGain
            targetFood = nil
        }
    }
    
    /// Handles interactions with other bugs using neural network decisions
    private func handleBugInteractions(otherBugs: [Bug]) {
        // Anti-clustering system: prevent energy-farming clusters
        let nearbyBugs = otherBugs.filter { distance(to: $0.position) < 60.0 } // Slightly increased detection
        
        if nearbyBugs.count > 4 { // Lower threshold - start penalties earlier
            // Progressive clustering penalty - gets severe with large clusters
            let baseStress = Double(nearbyBugs.count - 4) * 0.15 // Increased penalty per bug
            let clusterSize = nearbyBugs.count
            
            // Exponential penalty for large clusters to break them up
            let exponentialMultiplier = clusterSize > 8 ? Double(clusterSize - 8) * 0.5 : 0.0
            let totalStress = min(baseStress + exponentialMultiplier, 3.0) // Higher max penalty
            
            energy -= totalStress
            
            // Reproduction penalty for clustered bugs
            if clusterSize > 8 { 
                reproductionCooldown = max(reproductionCooldown, 40) // Longer penalty for clusters
            }
        }
        guard let decision = lastDecision else { return }
        
        for other in otherBugs {
            guard other.id != self.id else { continue }
            
            let dist = distance(to: other.position)
            if dist < (visualRadius + other.visualRadius) {
                // Neural network controls aggression level
                let aggressionLevel = decision.aggression * dna.aggression
                
                if aggressionLevel > 0.7 && other.lastDecision?.aggression ?? 0 < 0.3 {
                    // Aggressive neural decision leads to energy theft
                    let stolenEnergy = min(5.0, other.energy * 0.1 * aggressionLevel)
                    energy += stolenEnergy
                    other.energy -= stolenEnergy
                }
                
                // Social behavior based on neural decision
                if decision.social > 0.6 && other.lastDecision?.social ?? 0 > 0.6 {
                    // Mutual social interaction provides small energy bonus
                    let socialBonus = 1.0
                    energy += socialBonus
                    other.energy += socialBonus
                }
            }
        }
    }
    
    /// Attempts to reproduce with another compatible bug using neural decision
    func reproduce(with partner: Bug) -> Bug? {
        guard canReproduce && partner.canReproduce else { return nil }
        guard distance(to: partner.position) < max(visualRadius, partner.visualRadius) else { return nil }
        guard energy > Self.reproductionCost && partner.energy > Self.reproductionCost else { return nil }
        
        // Neural networks must both want to reproduce
        let myDesire = lastDecision?.reproduction ?? 0.5
        let partnerDesire = partner.lastDecision?.reproduction ?? 0.5
        
        // Higher neural reproduction desire increases success chance
        let reproductionChance = (myDesire + partnerDesire) / 2.0
        if Double.random(in: 0...1) > reproductionChance {
            return nil // Neural networks decided against reproduction
        }
        
        // Create offspring with crossover and mutation
        let childDNA = BugDNA.crossover(dna, partner.dna).mutated()
        let childPosition = CGPoint(
            x: (position.x + partner.position.x) / 2.0,
            y: (position.y + partner.position.y) / 2.0
        )
        
        // Pay reproduction cost
        energy -= Self.reproductionCost
        partner.energy -= Self.reproductionCost
        
        // Set shorter cooldown to encourage more reproduction
        reproductionCooldown = 60  // Reduced from 100
        partner.reproductionCooldown = 60
        
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
                energy -= 0.3 // Further reduced to prevent excessive drain
            }
            
        case .shadow:
            // Shadow zones make bugs "lost" and consume extra energy unless they have good memory
            if dna.memory < 0.5 {
                energy -= 0.1 // Further reduced
            }
            
        case .water:
            // Water is difficult to cross without proper adaptations
            let waterAbility = (dna.speed + (2.0 - dna.energyEfficiency)) / 2.0
            if waterAbility < 0.5 {
                energy -= 0.3 // Further reduced
            }
            
        case .wind:
            // Wind areas affect smaller bugs more
            if dna.size < 0.8 {
                // Small bugs get blown around, affecting their movement
                let windEffect = (1.0 - dna.size) * 0.3
                            let safeWindEffect = max(0.1, abs(windEffect)) // Ensure positive wind effect
            velocity.x += Double.random(in: -safeWindEffect...safeWindEffect)
            velocity.y += Double.random(in: -safeWindEffect...safeWindEffect)
            }
            
        case .food:
            // Food-rich areas provide generous, frequent energy bonuses
            if Double.random(in: 0...1) < 0.12 { // Increased chance more
                energy += 2.0 // Higher bonus to help sustain populations
            }
            
        default:
            break
        }
    }
    
    // MARK: - Utility Functions
    
    // MARK: - Communication Methods
    
    /// Emits a signal that other bugs can receive
    func emitSignal(type: SignalType, strength: Double? = nil, data: SignalData? = nil) -> Signal? {
        guard signalCooldown <= 0, 
              dna.communicationDNA.communicationFrequency > Double.random(in: 0...1) else {
            return nil
        }
        
        let actualStrength = strength ?? dna.communicationDNA.signalStrength
        let signal = Signal(
            type: type,
            position: position,
            emitterId: id,
            strength: actualStrength,
            timestamp: Date().timeIntervalSince1970,
            data: data
        )
        
        signalCooldown = Self.signalCooldownTime
        lastSignalTime = Date().timeIntervalSince1970
        
        // Energy cost for signaling
        energy -= actualStrength * 2.0 // Stronger signals cost more energy
        
        return signal
    }
    
    /// Receives and processes incoming signals
    func receiveSignal(_ signal: Signal) {
        let currentTime = Date().timeIntervalSince1970
        
        // Check if signal is strong enough to receive
        guard signal.canReach(position: position, at: currentTime),
              dna.communicationDNA.signalSensitivity > 0.2 else {
            return
        }
        
        // Trust filtering
        let trustThreshold = 1.0 - dna.communicationDNA.signalTrust
        guard Double.random(in: 0...1) > trustThreshold else {
            return // Ignore this signal due to low trust
        }
        
        // Add to recent signals
        recentSignals.append(signal)
        
        // Clean up old signals
        let signalMemoryTime = Double(dna.communicationDNA.signalMemory) / 30.0 // Convert ticks to seconds
        recentSignals.removeAll { currentTime - $0.timestamp > signalMemoryTime }
        
        // Limit memory to prevent overflow
        if recentSignals.count > 20 {
            recentSignals = Array(recentSignals.suffix(20))
        }
    }
    
    /// Decides whether to respond to group calls and signals
    private func processSignals(in arena: Arena, foods: [CGPoint], otherBugs: [Bug]) -> Signal? {
        let currentTime = Date().timeIntervalSince1970
        
        // Process recent signals by priority
        let activeSignals = recentSignals.filter { $0.isActive(at: currentTime) }
        let sortedSignals = activeSignals.sorted { $0.type.priority > $1.type.priority }
        
        for signal in sortedSignals {
            // Respond based on signal type and individual traits
            switch signal.type {
            case .dangerAlert, .retreat:
                if dna.communicationDNA.socialResponseRate > 0.7 {
                    // High social bugs respond to danger alerts
                    if let threatId = signal.data?.threatId,
                       let threat = otherBugs.first(where: { $0.id == threatId }) {
                        predatorThreat = threat
                        fleeingCooldown = Self.fleeingCooldownTime
                    }
                }
                
            case .foodFound:
                if dna.speciesTraits.speciesType.canEatPlants,
                   let foodPos = signal.data?.foodPosition,
                   targetFood == nil {
                    targetFood = foodPos
                }
                
            case .huntCall:
                if dna.speciesTraits.speciesType.canHunt,
                   dna.communicationDNA.socialResponseRate > 0.5,
                   let huntTargetId = signal.data?.huntTargetId,
                   let huntTarget = otherBugs.first(where: { $0.id == huntTargetId }) {
                    targetPrey = huntTarget
                    huntingCooldown = 0 // Ready to hunt immediately
                }
                
            case .groupForm:
                if dna.communicationDNA.socialResponseRate > 0.6 {
                    // Consider joining group
                    return considerJoiningGroup(signal: signal, otherBugs: otherBugs)
                }
                
            case .helpRequest:
                if dna.communicationDNA.socialResponseRate > 0.8,
                   energy > 60 { // Only help if we have spare energy
                    // Move toward the bug requesting help
                    targetFood = signal.position
                }
                
            default:
                break
            }
        }
        
        return nil
    }
    
    /// Considers joining a group based on signal
    private func considerJoiningGroup(signal: Signal, otherBugs: [Bug]) -> Signal? {
        // If already in a group, ignore
        guard currentGroup == nil else { return nil }
        
        // Consider group size and distance
        let distanceToGroup = distance(to: signal.position)
        if distanceToGroup < 100.0, // Close enough to group
           dna.communicationDNA.socialResponseRate > Double.random(in: 0...1) {
            
            // Accept group invitation
            currentGroup = signal.emitterId // Use emitter's ID as group ID temporarily
            groupRole = .member
            
            // Signal acceptance
            return emitSignal(
                type: .groupForm,
                data: SignalData(groupSize: 1)
            )
        }
        
        return nil
    }
    
    /// Generate signals based on current situation and neural network decisions (called by SimulationEngine)
    func generateSignals(in arena: Arena, foods: [CGPoint], otherBugs: [Bug]) -> Signal? {
        guard signalCooldown <= 0,
              let decision = lastDecision else { return nil }
        
        // Neural network influences when to communicate
        if decision.social < 0.3 { return nil } // Low social tendency = no communication
        
        // Generate signals based on current situation
        let currentTime = Date().timeIntervalSince1970
        
        // Danger alert when fleeing
        if decision.fleeing > 0.8, let threat = predatorThreat {
            return emitSignal(
                type: .dangerAlert,
                strength: 0.8,
                data: SignalData(threatId: threat.id)
            )
        }
        
        // Food found signal
        if let food = targetFood,
           dna.speciesTraits.speciesType.canEatPlants,
           Double.random(in: 0...1) < dna.communicationDNA.communicationFrequency {
            return emitSignal(
                type: .foodFound,
                data: SignalData(foodPosition: food)
            )
        }
        
        // Hunt call for carnivores
        if decision.hunting > 0.7,
           let prey = targetPrey,
           dna.speciesTraits.speciesType.canHunt {
            return emitSignal(
                type: .huntCall,
                strength: 0.7,
                data: SignalData(huntTargetId: prey.id)
            )
        }
        
        // Group formation call
        if decision.social > 0.8,
           currentGroup == nil,
           Double.random(in: 0...1) < 0.1 { // Rare event
            return emitSignal(
                type: .groupForm,
                data: SignalData(groupSize: 1)
            )
        }
        
        // Help request when low on energy
        if energy < 30.0,
           Double.random(in: 0...1) < dna.communicationDNA.communicationFrequency {
            return emitSignal(
                type: .helpRequest,
                data: SignalData(energyLevel: energy)
            )
        }
        
        return nil
    }
    
    // MARK: - Tool & Construction Methods
    
    /// Decides whether to start construction projects based on needs and environment
    private func considerConstruction(in arena: Arena, otherBugs: [Bug]) {
        guard currentProject == nil,
              energy > 40.0, // Need enough energy for construction
              dna.toolDNA.constructionDrive > Double.random(in: 0...1) else {
            return
        }
        
        // Analyze environment to determine useful tools
        let currentTerrain = arena.terrainAt(position)
        let nearbyTerrain = scanNearbyTerrain(in: arena)
        
        var constructionPriorities: [ToolType: Double] = [:]
        
        // Water nearby - consider bridge
        if nearbyTerrain.contains(.water) {
            constructionPriorities[.bridge] = 0.8
        }
        
        // Hills nearby - consider ramp
        if nearbyTerrain.contains(.hill) {
            constructionPriorities[.ramp] = 0.6
        }
        
        // Walls nearby - consider tunnel
        if nearbyTerrain.contains(.wall) {
            constructionPriorities[.tunnel] = 0.7
        }
        
        // Group formation - consider nest
        if let group = currentGroup, groupRole == .leader {
            constructionPriorities[.nest] = 0.9
        }
        
        // Predator zones - consider shelter
        if nearbyTerrain.contains(.predator) {
            constructionPriorities[.shelter] = 0.8
        }
        
        // Hunting opportunities - consider trap
        if dna.speciesTraits.speciesType.canHunt && !otherBugs.filter({ isValidPrey($0) }).isEmpty {
            constructionPriorities[.trap] = 0.5
        }
        
        // Simple marker for territory/navigation
        if dna.toolDNA.engineeringIntelligence > 0.7 && Double.random(in: 0...1) < 0.1 {
            constructionPriorities[.marker] = 0.3
        }
        
        // Choose the highest priority tool that we can potentially build
        if let (toolType, _) = constructionPriorities.max(by: { $0.value < $1.value }),
           dna.toolDNA.toolCrafting > 0.4,
           energy > toolType.energyCost {
            
            startConstruction(toolType: toolType)
        }
    }
    
    /// Scans nearby terrain to understand construction opportunities
    private func scanNearbyTerrain(in arena: Arena) -> Set<TerrainType> {
        let scanRadius = dna.toolDNA.toolVision * 100.0 // Vision affects planning distance
        var terrainTypes: Set<TerrainType> = []
        
        // Sample points around the bug
        let samplePoints = 12
        for i in 0..<samplePoints {
            let angle = Double(i) * 2.0 * Double.pi / Double(samplePoints)
            let checkPoint = CGPoint(
                x: position.x + cos(angle) * scanRadius,
                y: position.y + sin(angle) * scanRadius
            )
            
            let terrain = arena.terrainAt(checkPoint)
            terrainTypes.insert(terrain)
        }
        
        return terrainTypes
    }
    
    /// Starts a construction project
    private func startConstruction(toolType: ToolType) {
        let requiredResources = ToolRecipes.requiredResources(for: toolType)
        
        currentProject = ToolBlueprint(
            type: toolType,
            position: position,
            requiredResources: requiredResources,
            gatheredResources: [:],
            builderId: id,
            startTime: Date().timeIntervalSince1970,
            workProgress: 0
        )
        
        constructionCooldown = Self.constructionCooldownTime
        
        // Emit construction signal for cooperation
        if dna.toolDNA.collaborationTendency > 0.5 {
            _ = emitSignal(
                type: .groupForm,
                data: SignalData(groupSize: 1) // TODO: Add construction data
            )
        }
    }
    
    /// Checks if another bug is valid prey for hunting
    private func isValidPrey(_ other: Bug) -> Bool {
        guard other.id != self.id,
              dna.speciesTraits.speciesType.canHunt,
              dna.speciesTraits.speciesType != other.dna.speciesTraits.speciesType else {
            return false
        }
        
        // Simple prey logic - different species and reasonable distance
        let distance = distance(to: other.position)
        return distance < 100.0
    }
    
    /// Gathers resources from the environment
    func gatherResource(from resource: inout Resource) -> Bool {
        guard canCarryMore,
              resource.isAvailable,
              dna.toolDNA.resourceGathering > 0.3 else {
            return false
        }
        
        let gatheringEfficiency = dna.toolDNA.resourceGathering
        let maxGather = Int(gatheringEfficiency * 3.0) + 1
        let gathered = resource.harvest(amount: maxGather)
        
        if gathered > 0 {
            let current = carriedResources[resource.type] ?? 0
            carriedResources[resource.type] = current + gathered
            
            // Energy cost for gathering
            energy -= Double(gathered) * 0.5
            
            return true
        }
        
        return false
    }
    
    /// Contributes resources to a construction project
    func contributeToConstruction(_ blueprint: inout ToolBlueprint) -> Bool {
        guard blueprint.builderId == self.id || dna.toolDNA.collaborationTendency > 0.6 else {
            return false
        }
        
        var contributed = false
        
        for (resourceType, needed) in blueprint.requiredResources {
            let alreadyGathered = blueprint.gatheredResources[resourceType] ?? 0
            let stillNeeded = needed - alreadyGathered
            
            if stillNeeded > 0, let carried = carriedResources[resourceType], carried > 0 {
                let contribution = min(carried, stillNeeded)
                blueprint.addResource(type: resourceType, amount: contribution)
                carriedResources[resourceType] = carried - contribution
                
                if carriedResources[resourceType] == 0 {
                    carriedResources.removeValue(forKey: resourceType)
                }
                
                contributed = true
            }
        }
        
        return contributed
    }
    
    /// Works on construction if at the site
    func workOnConstruction(_ blueprint: inout ToolBlueprint) -> Bool {
        let distanceToSite = distance(to: blueprint.position)
        guard distanceToSite < 20.0, // Must be close to work site
              blueprint.hasAllResources else {
            return false
        }
        
        let workEfficiency = dna.toolDNA.toolCrafting
        let workDone = Int(workEfficiency * 3.0) + 1
        blueprint.addWork(ticks: workDone)
        
        // Energy cost for construction work
        energy -= Double(workDone) * 0.2
        
        return true
    }
    
    /// Uses a tool if available and beneficial
    func useTool(_ tool: inout Tool, in arena: Arena) -> Bool {
        guard tool.isUsable,
              distance(to: tool.position) < 30.0, // Must be close enough
              dna.toolDNA.toolProficiency > 0.3 else {
            return false
        }
        
        let currentTime = Date().timeIntervalSince1970
        
        // Don't use tools too frequently
        guard currentTime - lastToolUse > 1.0 else { return false }
        
        // Check if tool is beneficial in current situation
        let benefit = calculateToolBenefit(tool, in: arena)
        guard benefit > 0.3 else { return false }
        
        // Use the tool
        tool.use()
        lastToolUse = currentTime
        
        // Add tool to known tools
        knownTools.insert(tool.id)
        
        // Apply tool effects based on type
        applyToolEffects(tool)
        
        return true
    }
    
    /// Calculates how beneficial a tool would be to use (needs arena reference)
    private func calculateToolBenefit(_ tool: Tool, in arena: Arena) -> Double {
        let currentTerrain = arena.terrainAt(position)
        
        switch tool.type {
        case .bridge:
            return currentTerrain == .water ? 0.9 : 0.1
        case .tunnel:
            return currentTerrain == .wall ? 0.8 : 0.1
        case .ramp:
            return currentTerrain == .hill ? 0.7 : 0.1
        case .shelter:
            return energy < 40.0 ? 0.8 : 0.2
        case .nest:
            return canReproduce ? 0.9 : 0.1
        case .trap:
            return targetPrey != nil ? 0.6 : 0.1
        case .lever:
            return 0.4 // General utility
        case .marker:
            return 0.3 // Navigation aid
        }
    }
    
    /// Applies effects when using a tool
    private func applyToolEffects(_ tool: Tool) {
        switch tool.type {
        case .shelter:
            energy += 5.0 // Recovery bonus
        case .nest:
            if canReproduce {
                energy += 3.0 // Breeding bonus
            }
        case .trap:
            if let prey = targetPrey, distance(to: prey.position) < 50.0 {
                // Trap increases hunting success
                huntingCooldown = max(0, huntingCooldown - 30)
            }
        default:
            break // Other tools provide passive benefits through ToolEffects
        }
    }
    
    /// Total carrying capacity including tool bonuses
    var totalCarryingCapacity: Int {
        let baseCapacity = maxCarryingCapacity
        // Tools could provide carrying bonuses in the future
        return baseCapacity
    }
    
    /// Calculates distance to a point
    func distance(to point: CGPoint) -> Double {
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