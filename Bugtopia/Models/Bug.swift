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
    var populationId: UUID?  // Population this bug belongs to (for territorial behavior)
    
    // MARK: - Physical State
    
    var position: CGPoint  // 2D position (for backward compatibility)
    var position3D: Position3D  // 3D position (x, y, z coordinates)
    var velocity: CGPoint  // 2D velocity (for backward compatibility)
    var velocity3D: Position3D  // 3D velocity including vertical movement
    var energy: Double
    var age: Int
    
    // MARK: - 3D Movement Capabilities
    
    var currentLayer: TerrainLayer = .surface  // Current terrain layer
    var canFly: Bool { return dna.wingSpan > 0.5 }  // Flight capability
    var canSwim: Bool { return dna.divingDepth > 0.3 }  // Swimming capability  
    var canClimb: Bool { return dna.climbingGrip > 0.4 }  // Climbing capability
    var verticalMovementCooldown: Int = 0  // Cooldown for layer changes
    
    // MARK: - Neural Intelligence
    
    private let neuralNetwork: NeuralNetwork
    var lastDecision: BugOutputs?
    
    // ✅ DEBUG: Track update cycles to understand movement stopping patterns
    private var updateCount: Int = 0
    
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
    
    // MARK: - Neural Energy Economics State
    
    var brainPruningEvents: Int = 0                  // Number of times brain was pruned
    var brainGrowthEvents: Int = 0                   // Number of times brain grew
    
    // MARK: - Internal State Cache
    
    private var cachedCanReproduce: Bool = false     // Cached reproduction status for internal use
    
    // MARK: - Constants
    
    static let maxEnergy: Double = 100.0
    static let initialEnergy: Double = 80.0  // Increased from 50 to give more survival time
    static let energyLossPerTick: Double = 0.08  // Reduced to 0.08 for better sustainability (2.4/sec)
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
    
    /// Whether the bug can reproduce (season-aware)
    func canReproduce(seasonalManager: SeasonalManager) -> Bool {
        let baseThreshold = 55.0
        let seasonalThreshold = seasonalManager.adjustedReproductionThreshold(baseThreshold: baseThreshold)
        return energy >= seasonalThreshold && reproductionCooldown <= 0 && age > 30
    }
    
    /// Current movement speed based on DNA and energy
    var currentSpeed: Double {
        let energyMultiplier = max(0.0, min(1.0, energy / 50.0)) // Slower when low energy, never negative
        let speed = dna.speed * energyMultiplier * 2.0
        

        
        return speed
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
        self.position3D = Position3D(from: position, z: 5.0)  // Continental surface height - middle of surface range (-30 to 10)
        self.generation = generation
        self.velocity = CGPoint.zero
        self.velocity3D = Position3D(0, 0, 0)
        self.energy = Self.initialEnergy
        self.age = 0
        self.neuralNetwork = NeuralNetwork(dna: dna.neuralDNA)
        self.lastMovementTime = 0
        self.reproductionCooldown = 0
        self.huntingCooldown = 0
        self.fleeingCooldown = 0
    }
    
    /// Creates a bug with 3D positioning
    init(dna: BugDNA, position3D: Position3D, generation: Int = 0) {
        self.dna = dna
        self.position = position3D.position2D
        self.position3D = position3D
        self.generation = generation
        self.velocity = CGPoint.zero
        self.velocity3D = Position3D(0, 0, 0)
        self.energy = Self.initialEnergy
        self.age = 0
        self.neuralNetwork = NeuralNetwork(dna: dna.neuralDNA)
        self.lastMovementTime = 0
        self.reproductionCooldown = 0
        self.huntingCooldown = 0
        self.fleeingCooldown = 0
        
        // Set initial layer based on Z coordinate
        self.currentLayer = TerrainLayer.allCases.first { $0.heightRange.contains(position3D.z) } ?? .surface
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
    /// ✅ DEBUG: Enhanced tick tracking to understand movement stopping patterns
    func update(
        in arena: Arena,
        foods: [FoodItem],
        otherBugs: [Bug],
        seasonalManager: SeasonalManager,
        weatherManager: WeatherManager,
        disasterManager: DisasterManager,
        ecosystemManager: EcosystemManager,
        territoryManager: TerritoryManager
    ) {
        guard isAlive else { return }
        
        // ✅ DEBUG: Track update cycles to understand movement stopping patterns
        updateCount += 1
        
        age += 1
        reproductionCooldown = max(0, reproductionCooldown - 1)
        huntingCooldown = max(0, huntingCooldown - 1)
        fleeingCooldown = max(0, fleeingCooldown - 1)
        signalCooldown = max(0, signalCooldown - 1)
        constructionCooldown = max(0, constructionCooldown - 1)
        
        // Clear consumed food marker from previous tick
        consumedFood = nil
        
        // Update cached reproduction status for internal use
        cachedCanReproduce = canReproduce(seasonalManager: seasonalManager)
        
        // Get terrain modifiers for current position
        let modifiers = arena.movementModifiers(at: position, for: dna)
        
        // Get disaster effects at current position
        let disasterEffects = disasterManager.getDisasterEffectsAt(position)
        
        // Lose energy based on efficiency, terrain, species metabolic rate, season, weather, and disasters
        let baseLoss = Self.energyLossPerTick * dna.energyEfficiency * dna.speciesTraits.metabolicRate
        let terrainLoss = baseLoss * modifiers.energyCost
        let seasonalLoss = seasonalManager.adjustedEnergyDrain(baseDrain: terrainLoss)
        let weatherEffects = weatherManager.currentEffects
        let weatherDrain = seasonalLoss * weatherEffects.energyDrainModifier
        let disasterDrain = weatherDrain * disasterEffects.energyDrainModifier
        
        // Neural energy consumption - intelligence costs energy!
        let neuralEnergyCost = NeuralEnergyManager.calculateNeuralEnergyCost(
            for: dna.neuralDNA, 
            efficiency: dna.neuralEnergyEfficiency
        )
        
        let oldEnergy = energy
        energy -= disasterDrain + neuralEnergyCost
        
        // Apply weather-specific damage
        energy -= weatherEffects.coldDamage + weatherEffects.heatDamage
        
        // Apply disaster damage (direct health damage)
        energy -= disasterEffects.directDamage
        
        // 🔧 DEBUG: Track core energy drain sources
        let coreEnergyLoss = oldEnergy - energy
        
        // 🔧 FIX: Clamp energy immediately after applying damage to prevent negative energy
        energy = max(0, min(Self.maxEnergy, energy))
        
        // All bugs use neural networks immediately for consistent 3D movement
        if false {  // Disabled: age < 3
            
            // Simple movement for newborns
            let safeSpeed = max(0.1, currentSpeed) // Ensure positive speed
            velocity = CGPoint(
                x: Double.random(in: -safeSpeed...safeSpeed),
                y: Double.random(in: -safeSpeed...safeSpeed)
            )
            position.x += velocity.x
            position.y += velocity.y
            handleBoundaryCollisions(arena: arena)
            return
        }
        
        // Neural network decision making
        makeNeuralDecision(
            in: arena,
            foods: foods,
            otherBugs: otherBugs,
            seasonalManager: seasonalManager,
            weatherManager: weatherManager,
            disasterManager: disasterManager,
            ecosystemManager: ecosystemManager,
            territoryManager: territoryManager
        )
        
        // Adaptive brain scaling based on energy availability
        performAdaptiveBrainScaling(neuralEnergyCost: neuralEnergyCost)
        
        // Execute decisions based on species and neural outputs
        updatePredatorPreyTargets(otherBugs: otherBugs)
        // 🚶 CONTINENTAL WORLD: Re-enable 2D movement system (voxel pathfinding disabled)
        executeMovement(in: arena, modifiers: modifiers, seasonalManager: seasonalManager, weatherManager: weatherManager, disasterManager: disasterManager)
        
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
        
        // Energy management optimized - removed debug logging
        
        // Clamp energy
        energy = max(0, min(Self.maxEnergy, energy))
    }
    
    /// Uses neural network to make behavioral decisions
    private func makeNeuralDecision(
        in arena: Arena,
        foods: [FoodItem],
        otherBugs: [Bug],
        seasonalManager: SeasonalManager,
        weatherManager: WeatherManager,
        disasterManager: DisasterManager,
        ecosystemManager: EcosystemManager,
        territoryManager: TerritoryManager
    ) {
        // Create sensory inputs for neural network (including seasonal, weather, and disaster awareness)
        let inputs = BugSensors.createInputs(
            bug: self,
            arena: arena,
            foods: foods,
            otherBugs: otherBugs,
            seasonalManager: seasonalManager,
            weatherManager: weatherManager,
            disasterManager: disasterManager,
            ecosystemManager: ecosystemManager,
            territoryManager: territoryManager
        )
        
        // Get neural network outputs
        let rawOutputs = neuralNetwork.predict(inputs: inputs)
        
        lastDecision = BugOutputs(from: rawOutputs)
        

        
        // Neural network can override hardcoded food targeting
        if let decision = lastDecision {
            // 🍎 FOOD TARGETING FIX: Only clear food targets when actively exploring AND well-fed
            if decision.exploration > 0.7 && energy > 70.0 {  // Raised threshold and added energy condition
                targetFood = nil
            } else if dna.speciesTraits.speciesType.canEatPlants {
                // Use traditional food seeking when exploitation mode (for herbivores/omnivores)
                updateTargetFood(foods: foods, arena: arena)
            }
        }
    }
    
    /// Executes movement based on neural network decision
    private func executeMovement(in arena: Arena, modifiers: (speed: Double, vision: Double, energyCost: Double), seasonalManager: SeasonalManager, weatherManager: WeatherManager, disasterManager: DisasterManager) {
        

        guard let decision = lastDecision else {
            // Fallback to random movement if no decision
            velocity = CGPoint(x: Double.random(in: -1...1), y: Double.random(in: -1...1))
            return
        }
        
        // Check for stuck bugs (very small neural outputs)
        if abs(decision.moveX) < 0.01 && abs(decision.moveY) < 0.01 {
            // Apply small random movement to unstick bugs
            velocity = CGPoint(x: Double.random(in: -0.1...0.1), y: Double.random(in: -0.1...0.1))
            return
        }
        
        // Apply terrain, seasonal, weather, and disaster speed modifiers
        let baseSpeed = seasonalManager.adjustedMovementSpeed(baseSpeed: currentSpeed)
        let terrainSpeed = baseSpeed * modifiers.speed
        let weatherSpeed = terrainSpeed * weatherManager.currentEffects.movementSpeedModifier
        let disasterEffects = disasterManager.getDisasterEffectsAt(position)
        let rawFinalSpeed = weatherSpeed * disasterEffects.movementSpeedModifier
        let finalSpeed = max(0.01, rawFinalSpeed) // 🔧 FIX: Prevent negative/zero speeds
        
        // Only log critical speed problems
        let debugId = String(id.uuidString.prefix(8))
        if rawFinalSpeed <= 0.01 {

        }
        
        // Neural network controls movement direction with enhanced X-axis exploration
        var neuralVelocity = CGPoint(
            x: decision.moveX * finalSpeed * 8.0, // Increased to 8x for more dramatic X movement
            y: decision.moveY * finalSpeed * 5.0  // Keep Y at 5x for comparison
        )
        
        // ✅ ENHANCED DEBUG: Log when bugs stop moving after successful movement
        if abs(neuralVelocity.x) < 0.1 && abs(neuralVelocity.y) < 0.1 && Int.random(in: 1...50) == 1 {



        }
        
        // Apply disaster displacement force (earthquakes, floods, etc.)
        let displacementForce = disasterManager.getDisplacementForce(at: position)
        neuralVelocity.x += displacementForce.x * 2.0  // Amplify displacement effect
        neuralVelocity.y += displacementForce.y * 2.0
        
        // Behavioral priority system: fleeing > hunting > food seeking > exploration
        var finalVelocity = neuralVelocity
        
        // 1. FLEEING - highest priority
        if let threat = predatorThreat, decision.fleeing > 0.5 {
            let fleeDirection = normalize(CGPoint(x: position.x - threat.position.x, y: position.y - threat.position.y))
            let fleeSpeedMultiplier = dna.speciesTraits.defensiveBehavior?.fleeSpeedMultiplier ?? 1.3
            let fleeVelocity = CGPoint(
                x: fleeDirection.x * finalSpeed * fleeSpeedMultiplier,
                y: fleeDirection.y * finalSpeed * fleeSpeedMultiplier
            )
            finalVelocity = fleeVelocity
            
            // Energy cost for fleeing (reduced from 1.5 to 0.15 for sustainability)
            let fleeCost = (dna.speciesTraits.defensiveBehavior?.fleeEnergyCost ?? 1.5) * 0.1
            energy -= fleeCost
            
            // ✅ DEBUG: Log energy costs that might stop movement

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
        // 3. FOOD SEEKING - third priority (lowered threshold to encourage more exploration)
        else if let target = targetFood, decision.exploration < 0.4 {
            let rawDirection = CGPoint(x: target.x - position.x, y: target.y - position.y)
            let distanceToFood = sqrt(rawDirection.x * rawDirection.x + rawDirection.y * rawDirection.y)
            
            // 🔧 FIX: Avoid normalize() bug when on top of food - use pure neural movement instead
            if distanceToFood < 2.0 {
                // Too close to food - use pure neural movement to prevent sticking
                finalVelocity = neuralVelocity
                
                // Too close to food - use pure neural movement
            } else {
                let direction = normalize(rawDirection)
                let foodVelocity = CGPoint(
                    x: direction.x * terrainSpeed,
                    y: direction.y * terrainSpeed
                )
                
                // Blend food seeking with neural movement (60% food, 40% neural)
                finalVelocity = CGPoint(
                    x: foodVelocity.x * 0.6 + neuralVelocity.x * 0.4,
                    y: foodVelocity.y * 0.6 + neuralVelocity.y * 0.4
                )
                
                // Food seeking blend applied
            }
        }
        // 4. PURE NEURAL EXPLORATION - lowest priority
        
        velocity = finalVelocity
        
        // Calculate proposed new position
        let proposedPosition = CGPoint(
            x: position.x + velocity.x,
            y: position.y + velocity.y
        )
        
        // 🔧 DEBUG: Calculate movement distance for logging (before position changes)
        let moved = sqrt((proposedPosition.x - position.x) * (proposedPosition.x - position.x) + 
                       (proposedPosition.y - position.y) * (proposedPosition.y - position.y))
        
        // Check if the proposed position is passable
        if arena.isPassable(proposedPosition, for: dna) {
            let debugId = String(id.uuidString.prefix(8))
            
            // 🔧 CRITICAL DEBUG: Track X vs Y movement to identify the X-axis issue
            let oldPos = position
            let deltaX = abs(proposedPosition.x - oldPos.x)
            let deltaY = abs(proposedPosition.y - oldPos.y)
            
                    // ✅ ENHANCED: Log movement success and compare with stopping
        if deltaX > 1.0 || deltaY > 1.0 {
            
            
            // ✅ DEBUG: Log successful movement conditions for comparison
            if Int.random(in: 1...20) == 1 {
                
            }
        }
            
            // Track movement stopping indicators
            if deltaX < 0.1 && deltaY < 0.1 && (abs(decision.moveX) > 0.1 || abs(decision.moveY) > 0.1) && Int.random(in: 1...50) == 1 {

            }
            
            position = proposedPosition
            
            // Position updated
            
            // 🌍 TERRAIN FOLLOWING: Update 3D position with terrain height following
            if currentLayer == .surface {
                // For surface bugs, calculate terrain height at new position
                let terrainHeight = arena.getTerrainHeight(at: position)
                let newZ = max(terrainHeight + 0.5, position3D.z - 2.0) // Gradual descent to terrain, minimum 0.5 above
                updatePosition3D(Position3D(from: position, z: newZ))
            } else {
                // Non-surface bugs keep their Z coordinate
                updatePosition3D(Position3D(from: position, z: position3D.z))
            }
            
            // CRITICAL: 3D position sync debug - only for significant movement

        } else {
            // Neural network should learn to avoid walls, but provide basic collision
            // Position blocked - no debug spam
            velocity = CGPoint(x: velocity.x * -0.5, y: velocity.y * -0.5)
        }
        
        // Keep bug within arena bounds with bouncing behavior
        let posBeforeBoundary = position
        handleBoundaryCollisions(arena: arena)
        
        // 🔧 DEBUG: Check if boundary collision is overriding movement
        if moved > 0.5 && Int.random(in: 1...50) == 1 {
            let debugId = String(id.uuidString.prefix(8))
            let boundaryClamped = sqrt((position.x - posBeforeBoundary.x) * (position.x - posBeforeBoundary.x) + 
                                     (position.y - posBeforeBoundary.y) * (position.y - posBeforeBoundary.y))

        }
        
        // Handle 3D movement and layer changes based on neural decision  
        handle3DMovement(decision: decision)
        
        // Keep bug within 3D terrain bounds (AFTER 3D movement to prevent falling through)
        handle3DBoundaryCollisions()
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
            
            // PACK HUNTING: Identify pack members hunting the same target
            let packMembers = otherBugs.filter { packmate in
                packmate.id != self.id &&
                packmate.currentGroup == self.currentGroup &&
                packmate.currentGroup != nil &&
                (packmate.groupRole == .hunter || packmate.groupRole == .leader) &&
                packmate.targetPrey?.id == closestPrey.id &&
                distance(to: packmate.position) < 150.0  // Pack coordination range
            }
            
            // Pack hunting coordination - closer = more effective
            let packCoordinationRange = 75.0 
            let closePackMembers = packMembers.filter { distance(to: $0.position) < packCoordinationRange }
            
            // Successful hunt if close enough and conditions are met
            if huntDistance < visualRadius * 0.5 {
                let huntSuccess = calculateHuntSuccess(prey: closestPrey, huntingBehavior: huntingBehavior, packMembers: closePackMembers)
                
                if Double.random(in: 0...1) < huntSuccess {
                    // Successful hunt! - PACK ENERGY SHARING
                    let energyGained = min(dna.speciesTraits.huntEnergyGain, 50.0) // Cap energy gain
                    let actualEnergyTransfer = min(energyGained, closestPrey.energy) // Can't drain more than prey has
                    
                    // Pack sharing: distribute energy among pack members  
                    let totalHunters = closePackMembers.count + 1 // Include self
                    let energyPerHunter = actualEnergyTransfer / Double(totalHunters)
                    
                    // Give energy to self
                    energy += energyPerHunter
                    
                    // Share energy with pack members (they get automatic rewards for participation!)
                    for packmate in closePackMembers {
                        packmate.energy += energyPerHunter
                    }
                    
                    // Prey loses EXACTLY what all predators gain (no energy creation)
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
    
    /// Calculates hunting success probability with pack hunting bonuses
    private func calculateHuntSuccess(prey: Bug, huntingBehavior: HuntingBehavior, packMembers: [Bug] = []) -> Double {
        let sizeAdvantage = (dna.size / prey.dna.size) * 0.3
        let speedAdvantage = (dna.speed / prey.dna.speed) * 0.2
        let stealthBonus = huntingBehavior.stealthLevel * 0.2
        let preyDefense = prey.dna.speciesTraits.defensiveBehavior?.counterAttackSkill ?? 0.0
        let preyCamouflage = prey.dna.camouflage * 0.15
        
        // PACK HUNTING BONUSES - coordinated attacks are MUCH more effective!
        let packSize = packMembers.count + 1 // Include self
        let packBonus: Double
        switch packSize {
        case 1: packBonus = 0.0                    // Solo hunting (baseline)
        case 2: packBonus = 0.25                   // Duo: +25% success
        case 3: packBonus = 0.45                   // Trio: +45% success  
        case 4: packBonus = 0.60                   // Squad: +60% success
        default: packBonus = 0.75                  // Large pack: +75% success (max)
        }
        
        // Pack coordination bonus based on communication DNA
        let coordinationBonus = dna.communicationDNA.socialResponseRate * 0.2 * Double(packSize - 1)
        
        let baseSuccess = huntingBehavior.huntingIntensity * 0.4
        let totalSuccess = baseSuccess + sizeAdvantage + speedAdvantage + stealthBonus + packBonus + coordinationBonus - preyDefense - preyCamouflage
        
        return max(0.05, min(0.95, totalSuccess)) // Clamp between 5% and 95%
    }
    
    /// Finds and targets the nearest food within vision range, accounting for terrain
    private func updateTargetFood(foods: [FoodItem], arena: Arena) {
        // Get current vision modifier from terrain
        let modifiers = arena.movementModifiers(at: position, for: dna)
        let effectiveVision = dna.visionRadius * modifiers.vision
        
        let visibleFoods = foods.filter { food in
            let dist = distance(to: food.position)
            
            // Check if food is within vision range
            if dist > effectiveVision { return false }
            
            // Simple line-of-sight check for walls
            let steps = max(1, Int(dist / 10)) // Check every 10 units, minimum 1 step
            for i in 0...steps {
                let t = steps > 0 ? Double(i) / Double(steps) : 0.0
                let checkPoint = CGPoint(
                    x: position.x + (food.position.x - position.x) * t,
                    y: position.y + (food.position.y - position.y) * t
                )
                
                if arena.terrainAt(checkPoint) == .wall {
                    return false // Blocked by wall
                }
            }
            
            return true
        }
        
        // Prioritize food based on distance and terrain difficulty
        targetFood = visibleFoods.min { food1, food2 in
            let dist1 = distance(to: food1.position)
            let dist2 = distance(to: food2.position)
            
            // Factor in terrain difficulty for pathfinding
            let terrain1 = arena.terrainAt(food1.position)
            let terrain2 = arena.terrainAt(food2.position)
            
            let cost1 = dist1 * terrain1.energyCostMultiplier(for: dna)
            let cost2 = dist2 * terrain2.energyCostMultiplier(for: dna)
            
            return cost1 < cost2
        }?.position
        
        // 🐛 DEBUG: Log food targeting patterns to check for X-axis bias
        if let target = targetFood, Int.random(in: 1...30) == 1 {
            let debugId = String(id.uuidString.prefix(8))
            let deltaX = target.x - position.x
            let deltaY = target.y - position.y

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
        
        // Small energy penalty for hitting boundaries (reduced from 0.2 to 0.05)
        if bounced {
            energy -= 0.05 // Further reduced energy cost for hitting walls
            
            // Add randomization to prevent getting stuck in corners
            let randomAngle = Double.random(in: 0...(2 * Double.pi))
            let randomSpeed = Double.random(in: 0.3...0.8) * currentSpeed
            velocity.x += cos(randomAngle) * randomSpeed * 0.2 // Reduced randomization
            velocity.y += sin(randomAngle) * randomSpeed * 0.2
        }
    }
    
    /// Handles 3D boundary collisions to prevent bugs from falling through terrain
    private func handle3DBoundaryCollisions() {
        let minZ = -100.0  // Underground limit (matches TerrainLayer.underground.lowerBound)
        let maxZ = 200.0   // Aerial limit (matches TerrainLayer.aerial.upperBound)
        _ = 0.7  // Energy loss on bounce
        
        // First, enforce absolute world bounds
        if position3D.z < minZ {
            let newPosition = Position3D(position3D.x, position3D.y, minZ + 1.0)  // Slightly above minimum
            updatePosition3D(newPosition)
            velocity3D.z = max(0, abs(velocity3D.z) * 0.5)  // Bounce up with reduced speed
            energy -= 0.02  // Reduced energy penalty (was 0.1)
        } else if position3D.z > maxZ {
            let newPosition = Position3D(position3D.x, position3D.y, maxZ - 1.0)  // Slightly below maximum
            updatePosition3D(newPosition)
            velocity3D.z = min(0, -abs(velocity3D.z) * 0.5)  // Bounce down with reduced speed
            energy -= 0.02  // Reduced energy penalty (was 0.1)
        }
        
        // Second, ensure bugs stay within valid terrain layers based on their capabilities
        let validLayer = TerrainLayer.allCases.first { $0.heightRange.contains(position3D.z) } ?? .surface
        
        // If bug is in a layer they can't access, move them to a safe layer
        var shouldRelocate = false
        switch validLayer {
        case .underground:
            shouldRelocate = !canSwim && !canClimb
        case .aerial:
            shouldRelocate = !canFly
        case .canopy:
            shouldRelocate = !canClimb && !canFly
        case .surface:
            shouldRelocate = false  // All bugs can access surface
        }
        
        if shouldRelocate || validLayer != currentLayer {
            // Find the best accessible layer for this bug
            let accessibleLayers = TerrainLayer.allCases.filter { layer in
                switch layer {
                case .underground: return canSwim || canClimb
                case .aerial: return canFly
                case .canopy: return canClimb || canFly
                case .surface: return true  // Always accessible
                }
            }
            
            // Choose the closest accessible layer, preferring surface
            let targetLayer = accessibleLayers.contains(.surface) ? .surface : (accessibleLayers.first ?? .surface)
            let targetZ = targetLayer.heightRange.lowerBound + 
                         (targetLayer.heightRange.upperBound - targetLayer.heightRange.lowerBound) / 2
            let correctedPosition = Position3D(position3D.x, position3D.y, targetZ)
            updatePosition3D(correctedPosition)
            
            // Reset vertical velocity to prevent immediate re-collision
            velocity3D.z = 0.0
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
    
    /// Checks if bug is close enough to consume food with resource sharing mechanics
    private func checkFoodConsumption(foods: [FoodItem]) {
        guard dna.speciesTraits.speciesType.canEatPlants else { return }
        
        // Find the closest food within consumption range 
        let consumptionRange = max(8.0, visualRadius * 1.5)  // Reduced range for more realistic consumption
        
        if let nearestFood = foods.min(by: { distance(to: $0.position) < distance(to: $1.position) }) {
            let distanceToFood = distance(to: nearestFood.position)
            
            if distanceToFood < consumptionRange {
                // Mark this food as consumed so other bugs can't also eat it
                consumedFood = nearestFood.position
                
                // Food consumption tracking (cleaned up logging)
                
                // 🍯 RESOURCE SHARING: Share with group members if social enough
                let shouldShare = currentGroup != nil && 
                                dna.communicationDNA.socialResponseRate > 0.7 &&
                                energy > 50.0 // Only share if we have spare energy
                
                if shouldShare {
                    // GENEROUS SHARING: Split food energy with nearby group members
                    let shareableEnergy = nearestFood.energyValue * 0.6 // Keep 60% for self
                    let personalEnergy = nearestFood.energyValue * 0.4  // Share 40% with group
                    
                    energy += personalEnergy
                    
                    // Signal that food is being shared
                    _ = emitSignal(
                        type: .foodShare,
                        strength: 0.6,
                        data: SignalData(foodPosition: nearestFood.position, energyLevel: shareableEnergy)
                    )
                } else {
                    // Normal consumption - keep all energy
                    energy += nearestFood.energyValue
                }
                
                // Clear target if this was the targeted food
                if targetFood == nearestFood.position {
                    targetFood = nil
                }
            }
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
                
                // Social behavior based on neural decision - FIXED: Much smaller bonus, shared not doubled
                if decision.social > 0.6 && other.lastDecision?.social ?? 0 > 0.6 {
                    // Small social interaction bonus - but not enough to sustain life
                    let socialBonus = 0.1  // Reduced from 1.0 to 0.1
                    energy += socialBonus
                    // Don't give bonus to both bugs - that doubles the effect
                    // other.energy += socialBonus  // REMOVED: Prevents energy duplication
                }
            }
        }
    }
    
    /// Attempts to reproduce with another compatible bug using neural decision
    func reproduce(with partner: Bug, seasonalManager: SeasonalManager) -> Bug? {
        guard canReproduce(seasonalManager: seasonalManager) && partner.canReproduce(seasonalManager: seasonalManager) else { return nil }
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
    private func processSignals(in arena: Arena, foods: [FoodItem], otherBugs: [Bug]) -> Signal? {
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
                    
                    // PACK HUNTING COORDINATION: Join the pack hunt
                    targetPrey = huntTarget
                    huntingCooldown = 0 // Ready to hunt immediately
                    
                    // Form hunting pack if not already in one
                    if currentGroup == nil {
                        currentGroup = signal.emitterId // Join caller's hunting pack
                        groupRole = .hunter
                    }
                    
                    // If already in a hunting group, prioritize this target
                    if let group = currentGroup, 
                       groupRole == .hunter || groupRole == .leader {
                        targetPrey = huntTarget
                    }
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
                
            case .foodShare:
                // RESOURCE SHARING: Receive shared food energy from group members
                if currentGroup == signal.emitterId || 
                   (currentGroup != nil && currentGroup == otherBugs.first(where: { $0.id == signal.emitterId })?.currentGroup),
                   dna.communicationDNA.socialResponseRate > 0.6,
                   let sharedEnergy = signal.data?.energyLevel {
                    
                    // Only take shared food if we're nearby and hungry
                    let distanceToShare = distance(to: signal.position)
                    if distanceToShare < 50.0 && energy < 70.0 {
                        // Take a portion of the shared energy
                        let energyPortion = min(sharedEnergy * 0.3, 20.0) // Max 20 energy from sharing
                        energy += energyPortion
                        
                        // Show gratitude by increasing social bonds (future feature)
                        // This could enhance group cohesion over time
                    }
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
    func generateSignals(in arena: Arena, foods: [FoodItem], otherBugs: [Bug]) -> Signal? {
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
        
        // Hunt call for carnivores - enhanced pack hunting
        if decision.hunting > 0.7,
           let prey = targetPrey,
           dna.speciesTraits.speciesType.canHunt {
            
            // Become pack leader if not already in a group
            if currentGroup == nil {
                currentGroup = id // Use own ID as pack identifier
                groupRole = .leader
            }
            
            return emitSignal(
                type: .huntCall,
                strength: min(0.9, 0.7 + dna.communicationDNA.signalStrength * 0.2), // Stronger signal for pack coordination
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
            return cachedCanReproduce ? 0.9 : 0.1
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
            if cachedCanReproduce {
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
    
    // MARK: - Neural Energy Economics
    
    /// Performs adaptive brain scaling based on energy availability and neural costs
    private func performAdaptiveBrainScaling(neuralEnergyCost: Double) {
        // Only apply brain scaling if the bug has high enough brain plasticity
        guard dna.brainPlasticity > 0.3 else { return }
        
        // Check if we should prune the network due to low energy
        if NeuralEnergyManager.shouldPruneNetwork(currentEnergy: energy, neuralCost: neuralEnergyCost) {
            // Only prune if the bug has a tendency to do so
            if dna.neuralPruningTendency > Double.random(in: 0...1) {
                let prunedNetwork = NeuralEnergyManager.pruneNetwork(dna.neuralDNA)
                // Update the bug's neural DNA (this is a simplification - in reality we'd need mutable DNA)
                // For now, we'll just track that pruning occurred
                brainPruningEvents += 1
            }
        }
        
        // Check if we can grow the network due to abundant energy
        else if NeuralEnergyManager.canGrowNetwork(currentEnergy: energy, neuralCost: neuralEnergyCost) {
            // Only grow if the bug has high brain plasticity
            if dna.brainPlasticity > Double.random(in: 0...1) {
                let grownNetwork = NeuralEnergyManager.growNetwork(dna.neuralDNA)
                // Update the bug's neural DNA (this is a simplification - in reality we'd need mutable DNA)
                // For now, we'll just track that growth occurred
                brainGrowthEvents += 1
            }
        }
    }
    
    // MARK: - Hashable & Equatable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Bug, rhs: Bug) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - 3D Movement & Positioning
    
    /// Update 3D position maintaining 2D compatibility with proper terrain following
    func updatePosition3D(_ newPosition: Position3D) {
        // 🌍 TERRAIN FOLLOWING: Allow surface bugs to follow terrain height changes
        if currentLayer == .surface {
            // Surface bugs should follow terrain contours instead of fixed height
            // Allow Z changes for terrain following, but limit extreme changes
            let maxHeightChange = 5.0  // Prevent teleporting through terrain
            let heightDelta = abs(newPosition.z - position3D.z)
            
            if heightDelta <= maxHeightChange {
                position3D = newPosition  // Allow natural terrain following
            } else {
                // Gradual height adjustment for large terrain changes
                let direction = newPosition.z > position3D.z ? 1.0 : -1.0
                let adjustedZ = position3D.z + (direction * maxHeightChange)
                position3D = Position3D(newPosition.x, newPosition.y, adjustedZ)
            }
        } else {
            position3D = newPosition  // Non-surface layers can move freely
        }
        position = position3D.position2D  // Keep 2D position in sync
        
        // Update current layer based on Z coordinate
        currentLayer = TerrainLayer.allCases.first { $0.heightRange.contains(position3D.z) } ?? .surface
    }
    
    /// Attempt to change terrain layer (fly up, dive down, etc.)
    func attemptLayerChange(to targetLayer: TerrainLayer, in arena3D: Arena3D) -> Bool {
        guard verticalMovementCooldown <= 0 else { return false }
        
        // Check if bug has the capability for this layer
        switch targetLayer {
        case .aerial:
            guard canFly else { return false }
        case .underground:
            guard canSwim || canClimb else { return false }  // Swimming for underwater, climbing for caves
        case .canopy:
            guard canClimb || canFly else { return false }
        case .surface:
            break  // All bugs can access surface
        }
        
        // Calculate energy cost for layer change
        let layerDistance = abs(currentLayer.heightRange.lowerBound - targetLayer.heightRange.lowerBound)
        let energyCost = layerDistance * 0.01 * (2.0 - dna.energyEfficiency)
        
        guard energy >= energyCost else { return false }
        
        // Find valid position in target layer
        let targetZ = targetLayer.heightRange.lowerBound + 
                     (targetLayer.heightRange.upperBound - targetLayer.heightRange.lowerBound) / 2
        let targetPosition = Position3D(position3D.x, position3D.y, targetZ)
        
        if arena3D.isValidPosition(targetPosition) {
            updatePosition3D(targetPosition)
            energy -= energyCost
            verticalMovementCooldown = 30  // 1 second cooldown at 30 FPS
            return true
        }
        
        return false
    }
    
    /// Get preferred layer based on altitude preference and capabilities
    func getPreferredLayer() -> TerrainLayer {
        let preference = dna.altitudePreference
        
        // Map altitude preference to layers
        if preference > 0.5 && canFly {
            return .aerial
        } else if preference > 0.0 && (canClimb || canFly) {
            return .canopy
        } else if preference < -0.5 && (canSwim || canClimb) {
            return .underground
        } else {
            return .surface
        }
    }
    
    /// Calculate 3D movement speed based on current layer and capabilities
    func getMovementSpeed3D() -> Double {
        var baseSpeed = dna.speed
        
        // Layer-specific speed modifiers
        switch currentLayer {
        case .aerial:
            if canFly {
                baseSpeed *= 1.5  // Flying is faster
            } else {
                baseSpeed *= 0.1  // Can't really move in air without flight
            }
        case .underground:
            if canSwim {
                baseSpeed *= 0.8  // Swimming is slower
            } else if canClimb {
                baseSpeed *= 0.6  // Cave crawling is slow
            } else {
                baseSpeed *= 0.3  // Very difficult without proper adaptation
            }
        case .canopy:
            if canClimb {
                baseSpeed *= 1.2  // Good at tree movement
            } else if canFly {
                baseSpeed *= 1.3  // Flying through trees
            } else {
                baseSpeed *= 0.5  // Struggling in trees
            }
        case .surface:
            baseSpeed *= 1.0  // Normal ground movement
        }
        
        return baseSpeed
    }
    
    /// Check if bug can interact with another bug in 3D space
    func canInteract3D(with otherBug: Bug, maxDistance: Double = 30.0) -> Bool {
        let distance3D = position3D.distance(to: otherBug.position3D)
        return distance3D <= maxDistance
    }
    
    /// Get 3D distance to a target position
    func distance3D(to target: Position3D) -> Double {
        return position3D.distance(to: target)
    }
    
    /// Handle 3D movement based on neural network decisions
    private func handle3DMovement(decision: BugOutputs) {
        // 🚨 CONTINENTAL WORLD: Disable Z-axis movement for surface bugs
        if currentLayer == .surface {
            velocity3D.z = 0.0
            return  // Skip all 3D movement logic for surface bugs
        }
        
        // Decrement vertical movement cooldown
        verticalMovementCooldown = max(0, verticalMovementCooldown - 1)
        
        // Handle vertical movement (Z-axis) with capability restrictions
        if abs(decision.moveZ) > 0.1 {
            let verticalMovement = decision.moveZ * getMovementSpeed3D() * 0.3  // Much slower vertical movement
            let proposedZ = position3D.z + verticalMovement
            
            // Check if the bug can actually move to this Z level based on capabilities
            let targetLayer = TerrainLayer.allCases.first { $0.heightRange.contains(proposedZ) } ?? .surface
            var canMoveToLayer = true
            
            switch targetLayer {
            case .underground:
                canMoveToLayer = canSwim || canClimb
            case .aerial:
                canMoveToLayer = canFly
            case .canopy:
                canMoveToLayer = canClimb || canFly
            case .surface:
                canMoveToLayer = true  // All bugs can access surface
            }
            
            if canMoveToLayer && energy > 5.0 {  // Require minimum energy for vertical movement
                // Keep within world bounds and apply the movement
                let clampedZ = max(-99.0, min(199.0, proposedZ))  // Stay slightly within bounds
                let newPosition3D = Position3D(position3D.x, position3D.y, clampedZ)
                
                // Update position and layer
                updatePosition3D(newPosition3D)
                
                // Reduced energy cost for vertical movement (was 0.05, now 0.01)
                energy -= abs(verticalMovement) * 0.01 * (2.0 - dna.energyEfficiency)
            } else {
                // Can't move vertically - reset vertical velocity to prevent accumulation
                velocity3D.z = 0.0
            }
        }
        
        // Handle layer change desires
        if decision.layerChange > 0.7 && verticalMovementCooldown <= 0 {
            // Determine target layer based on neural preference and capabilities
            let targetLayer = determineTargetLayer(decision: decision)
            
            if targetLayer != currentLayer {
                // Create a 3D arena for layer change (this will need to be passed in later)
                // For now, we'll simulate the layer change logic
                attemptLayerChangeBasedOnNeural(to: targetLayer, decision: decision)
            }
        }
    }
    
    /// Determine target layer based on neural decision and capabilities
    private func determineTargetLayer(decision: BugOutputs) -> TerrainLayer {
        // If bug wants to move up and can fly
        if decision.moveZ > 0.5 && canFly {
            return currentLayer == .surface ? .canopy : 
                   currentLayer == .canopy ? .aerial : currentLayer
        }
        // If bug wants to move down and can swim/climb
        else if decision.moveZ < -0.5 && (canSwim || canClimb) {
            return currentLayer == .aerial ? .canopy :
                   currentLayer == .canopy ? .surface :
                   currentLayer == .surface ? .underground : currentLayer
        }
        // If bug prefers its genetically preferred layer
        else if decision.layerChange > 0.5 {
            return getPreferredLayer()
        }
        
        return currentLayer  // Stay in current layer
    }
    
    /// Attempt layer change based on neural decision (simplified version without Arena3D)
    private func attemptLayerChangeBasedOnNeural(to targetLayer: TerrainLayer, decision: BugOutputs) {
        // Check if bug has the capability for this layer
        let canAccessLayer: Bool
        switch targetLayer {
        case .aerial:
            canAccessLayer = canFly
        case .underground:
            canAccessLayer = canSwim || canClimb
        case .canopy:
            canAccessLayer = canClimb || canFly
        case .surface:
            canAccessLayer = true  // All bugs can access surface
        }
        
        guard canAccessLayer else { return }
        
        // Calculate energy cost for layer change
        let layerDistance = abs(currentLayer.heightRange.lowerBound - targetLayer.heightRange.lowerBound)
        let energyCost = layerDistance * 0.01 * (2.0 - dna.energyEfficiency)
        
        guard energy >= energyCost else { return }
        
        // Move to target layer
        let targetZ = targetLayer.heightRange.lowerBound + 
                     (targetLayer.heightRange.upperBound - targetLayer.heightRange.lowerBound) / 2
        let targetPosition = Position3D(position3D.x, position3D.y, targetZ)
        
        updatePosition3D(targetPosition)
        energy -= energyCost
        verticalMovementCooldown = 30  // 1 second cooldown at 30 FPS
    }
    
    /// 3D boundary collision handling for Arena3D
    private func handleBoundaryCollisions3D(arena3D: Arena3D) {
        let buffer = visualRadius
        let damping = 0.7
        var bounced = false
        
        // Handle X boundaries
        if position.x <= arena3D.bounds.minX + buffer {
            position.x = arena3D.bounds.minX + buffer
            if velocity.x < 0 {
                velocity.x *= -damping
                bounced = true
            }
        } else if position.x >= arena3D.bounds.maxX - buffer {
            position.x = arena3D.bounds.maxX - buffer
            if velocity.x > 0 {
                velocity.x *= -damping
                bounced = true
            }
        }
        
        // Handle Y boundaries
        if position.y <= arena3D.bounds.minY + buffer {
            position.y = arena3D.bounds.minY + buffer
            if velocity.y < 0 {
                velocity.y *= -damping
                bounced = true
            }
        } else if position.y >= arena3D.bounds.maxY - buffer {
            position.y = arena3D.bounds.maxY - buffer
            if velocity.y > 0 {
                velocity.y *= -damping
                bounced = true
            }
        }
        
        if bounced {
            energy -= 0.2
            // Sync 3D position
            updatePosition3D(Position3D(from: position, z: position3D.z))
        }
    }
    
    /// 3D edge proximity penalty
    private func applyEdgeProximityPenalty3D(arena3D: Arena3D) {
        let edgeDistance = min(
            min(position.x - arena3D.bounds.minX, arena3D.bounds.maxX - position.x),
            min(position.y - arena3D.bounds.minY, arena3D.bounds.maxY - position.y)
        )
        
        if edgeDistance < 50.0 {
            let proximityFactor = (50.0 - edgeDistance) / 50.0
            energy -= proximityFactor * 0.05
        }
    }
    

}

// MARK: - Extensions

extension Bug: CustomStringConvertible {
    var description: String {
        return "Bug(gen: \(generation), energy: \(String(format: "%.1f", energy)), age: \(age))"
    }
}