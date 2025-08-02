//
//  VoxelPathfinding.swift
//  Bugtopia
//
//  Advanced 3D pathfinding system for voxel-based bug movement
//

import Foundation

// MARK: - Pathfinding Node

class PathNode {
    let voxel: Voxel
    let gCost: Double      // Distance from start
    let hCost: Double      // Heuristic distance to goal
    let parent: PathNode?
    
    var fCost: Double { return gCost + hCost }
    
    init(voxel: Voxel, gCost: Double, hCost: Double, parent: PathNode? = nil) {
        self.voxel = voxel
        self.gCost = gCost
        self.hCost = hCost
        self.parent = parent
    }
}

extension PathNode: Equatable {
    static func == (lhs: PathNode, rhs: PathNode) -> Bool {
        return lhs.voxel.gridPosition.x == rhs.voxel.gridPosition.x &&
               lhs.voxel.gridPosition.y == rhs.voxel.gridPosition.y &&
               lhs.voxel.gridPosition.z == rhs.voxel.gridPosition.z
    }
}

extension PathNode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(voxel.gridPosition.x)
        hasher.combine(voxel.gridPosition.y)
        hasher.combine(voxel.gridPosition.z)
    }
}

// MARK: - 3D Pathfinding Engine

class VoxelPathfinding {
    private let voxelWorld: VoxelWorld
    
    init(voxelWorld: VoxelWorld) {
        self.voxelWorld = voxelWorld
    }
    
    // MARK: - A* Pathfinding
    
    func findPath(from startPos: Position3D, 
                  to goalPos: Position3D, 
                  for species: SpeciesType, 
                  with dna: BugDNA,
                  maxDistance: Double = 100.0) -> [Voxel]? {
        
        guard let startVoxel = voxelWorld.getVoxel(at: startPos),
              let goalVoxel = voxelWorld.getVoxel(at: goalPos) else {
            return nil
        }
        
        // Check if goal is reachable for this species
        guard goalVoxel.canMoveTo(direction: .north, for: species, with: dna) else {
            return nil
        }
        
        var openSet: Set<PathNode> = []
        var closedSet: Set<PathNode> = []
        var nodeMap: [String: PathNode] = [:]
        
        let startNode = PathNode(
            voxel: startVoxel,
            gCost: 0,
            hCost: heuristic(from: startVoxel, to: goalVoxel)
        )
        
        openSet.insert(startNode)
        nodeMap[voxelKey(startVoxel)] = startNode
        
        while !openSet.isEmpty {
            // Find node with lowest fCost
            let currentNode = openSet.min { $0.fCost < $1.fCost }!
            openSet.remove(currentNode)
            closedSet.insert(currentNode)
            
            // Check if we reached the goal
            if currentNode.voxel.gridPosition.x == goalVoxel.gridPosition.x &&
               currentNode.voxel.gridPosition.y == goalVoxel.gridPosition.y &&
               currentNode.voxel.gridPosition.z == goalVoxel.gridPosition.z {
                return reconstructPath(from: currentNode)
            }
            
            // Check if we've exceeded max distance
            if currentNode.gCost > maxDistance {
                continue
            }
            
            // Explore neighbors
            let neighbors = voxelWorld.getAdjacentVoxels(to: currentNode.voxel)
            
            for (direction, neighborVoxel) in neighbors {
                // Check if this neighbor can be moved to
                guard currentNode.voxel.canMoveTo(direction: direction, for: species, with: dna) else {
                    continue
                }
                
                let neighborKey = voxelKey(neighborVoxel)
                
                // Skip if already processed
                if closedSet.contains(where: { voxelKey($0.voxel) == neighborKey }) {
                    continue
                }
                
                let movementCost = neighborVoxel.movementCost(for: species, with: dna)
                let tentativeGCost = currentNode.gCost + movementCost
                
                let existingNode = nodeMap[neighborKey]
                
                if existingNode == nil || tentativeGCost < existingNode!.gCost {
                    let neighborNode = PathNode(
                        voxel: neighborVoxel,
                        gCost: tentativeGCost,
                        hCost: heuristic(from: neighborVoxel, to: goalVoxel),
                        parent: currentNode
                    )
                    
                    nodeMap[neighborKey] = neighborNode
                    openSet.insert(neighborNode)
                    
                    // Remove old node if it exists
                    if let oldNode = existingNode {
                        openSet.remove(oldNode)
                    }
                }
            }
        }
        
        return nil // No path found
    }
    
    // MARK: - Movement Validation
    
    func canMoveTo(from currentPos: Position3D, 
                   to targetPos: Position3D, 
                   for species: SpeciesType, 
                   with dna: BugDNA) -> Bool {
        
        guard let _ = voxelWorld.getVoxel(at: currentPos),
              let targetVoxel = voxelWorld.getVoxel(at: targetPos) else {
            return false
        }
        
        // Check if target voxel is passable for this species
        let movementCost = targetVoxel.movementCost(for: species, with: dna)
        return movementCost != Double.infinity
    }
    
    func getValidMoves(from position: Position3D, 
                       for species: SpeciesType, 
                       with dna: BugDNA) -> [Direction3D: Voxel] {
        
        guard let currentVoxel = voxelWorld.getVoxel(at: position) else {
//            print("⚠️ Bug at \(position) - no current voxel found")
            return [:]
        }
        
        var validMoves: [Direction3D: Voxel] = [:]
        let neighbors = voxelWorld.getAdjacentVoxels(to: currentVoxel)
        
        for (direction, neighborVoxel) in neighbors {
            if currentVoxel.canMoveTo(direction: direction, for: species, with: dna) {
                validMoves[direction] = neighborVoxel
            }
        }
        
        if validMoves.isEmpty {
//            print("⚠️ Bug at \(position) has NO valid moves! Adjacent: \(neighbors.count), Current: \(currentVoxel.transitionType)")
        }
        
        return validMoves
    }
    
    // MARK: - Layer Transition Analysis
    
    func findLayerTransitions(from currentLayer: TerrainLayer, 
                             near position: Position3D, 
                             for species: SpeciesType, 
                             with dna: BugDNA,
                             searchRadius: Double = 20.0) -> [Voxel] {
        
        var transitions: [Voxel] = []
        let currentGridPos = voxelWorld.worldToGrid(position)
        let searchRange = Int(searchRadius / voxelWorld.voxelSize)
        
        for x in max(0, currentGridPos.x - searchRange)...min(voxelWorld.dimensions.width - 1, currentGridPos.x + searchRange) {
            for y in max(0, currentGridPos.y - searchRange)...min(voxelWorld.dimensions.height - 1, currentGridPos.y + searchRange) {
                for z in 0..<voxelWorld.dimensions.depth {
                    if let voxel = voxelWorld.getVoxel(at: (x, y, z)) {
                        // Check if this voxel provides layer transition
                        if voxel.layer != currentLayer && isLayerTransition(voxel: voxel, for: species, with: dna) {
                            transitions.append(voxel)
                        }
                    }
                }
            }
        }
        
        return transitions
    }
    
    private func isLayerTransition(voxel: Voxel, for species: SpeciesType, with dna: BugDNA) -> Bool {
        switch voxel.transitionType {
        case .ramp, .climb, .swim, .tunnel, .flight:
            return voxel.movementCost(for: species, with: dna) != Double.infinity
        default:
            return false
        }
    }
    
    // MARK: - Utility Functions
    
    private func heuristic(from: Voxel, to: Voxel) -> Double {
        let dx = Double(abs(from.gridPosition.x - to.gridPosition.x))
        let dy = Double(abs(from.gridPosition.y - to.gridPosition.y))
        let dz = Double(abs(from.gridPosition.z - to.gridPosition.z))
        
        // 3D Manhattan distance with slight preference for horizontal movement
        return dx + dy + (dz * 1.2)
    }
    
    private func reconstructPath(from node: PathNode) -> [Voxel] {
        var path: [Voxel] = []
        var current: PathNode? = node
        
        while let currentNode = current {
            path.insert(currentNode.voxel, at: 0)
            current = currentNode.parent
        }
        
        return path
    }
    
    private func voxelKey(_ voxel: Voxel) -> String {
        return "\(voxel.gridPosition.x),\(voxel.gridPosition.y),\(voxel.gridPosition.z)"
    }
}

// MARK: - Bug Movement Integration

extension Bug {
    
    // MARK: - Voxel-Based Movement
    
    func updateVoxelPosition(in voxelWorld: VoxelWorld, pathfinding: VoxelPathfinding, decision: BugOutputs) {
        guard isAlive else { return }
        
        let currentVoxel = voxelWorld.getVoxel(at: position3D)
        guard currentVoxel != nil else { return }
        
        // Get valid moves from current position
        let validMoves = pathfinding.getValidMoves(from: position3D, for: dna.speciesTraits.speciesType, with: dna)
        
        if validMoves.isEmpty {
            // Stuck! Try to find escape route
            handleStuckPosition(in: voxelWorld, pathfinding: pathfinding)
            return
        }
        
        // Determine movement intention from neural network
        let intendedDirection = determineMovementDirection(decision: decision, validMoves: validMoves)
        
        if let targetVoxel = validMoves[intendedDirection] {
            // Move to the target voxel
            moveToVoxel(targetVoxel, in: voxelWorld)
        } else {
            // Try alternative movement
            tryAlternativeMovement(validMoves: validMoves, decision: decision, in: voxelWorld)
        }
    }
    
    private func determineMovementDirection(decision: BugOutputs, validMoves: [Direction3D: Voxel]) -> Direction3D {
        var bestDirection: Direction3D = .north
        var bestScore: Double = -1.0
        
        for (direction, voxel) in validMoves {
            let score = calculateDirectionScore(direction: direction, voxel: voxel, decision: decision)
            if score > bestScore {
                bestScore = score
                bestDirection = direction
            }
        }
        
        return bestDirection
    }
    
    private func calculateDirectionScore(direction: Direction3D, voxel: Voxel, decision: BugOutputs) -> Double {
        var score = 0.0
        
        // Neural network movement preferences
        switch direction {
        case .north: score += decision.moveY < 0 ? abs(decision.moveY) : 0
        case .south: score += decision.moveY > 0 ? decision.moveY : 0
        case .east: score += decision.moveX > 0 ? decision.moveX : 0
        case .west: score += decision.moveX < 0 ? abs(decision.moveX) : 0
        case .up: score += decision.moveZ > 0 ? decision.moveZ : 0
        case .down: score += decision.moveZ < 0 ? abs(decision.moveZ) : 0
        }
        
        // Layer change preference
        if direction == .up || direction == .down {
            score += abs(decision.layerChange) * 0.5
        }
        
        // Environmental factors
        score += voxel.light * 0.1  // Slight preference for lit areas
        score -= voxel.movementCost(for: dna.speciesTraits.speciesType, with: dna) * 0.1  // Avoid costly movement
        
        // Resource attraction
        if voxel.hasFood {
            score += voxel.foodDensity * 0.3
        }
        
        return score
    }
    
    private func moveToVoxel(_ targetVoxel: Voxel, in voxelWorld: VoxelWorld) {
        // Calculate proper surface position
        let newPosition = calculateSurfacePosition(for: targetVoxel, in: voxelWorld)
        updatePosition3D(newPosition)
        
        // Update current layer
        currentLayer = targetVoxel.layer
        
        // Apply movement energy cost
        let movementCost = targetVoxel.movementCost(for: dna.speciesTraits.speciesType, with: dna)
        energy -= movementCost * 0.1 * (2.0 - dna.energyEfficiency)
        
        // Check for resources at new position
        if targetVoxel.hasFood && energy < Bug.maxEnergy * 0.8 {
            consumeVoxelResource(targetVoxel)
        }
        
        // Update 2D position for compatibility
        position = newPosition.position2D
    }
    
    private func calculateSurfacePosition(for voxel: Voxel, in voxelWorld: VoxelWorld) -> Position3D {
        let voxelSize = voxelWorld.voxelSize
        
        // If it's a passable voxel (air, water), bug can move through it
        if voxel.transitionType.isPassable {
            return voxel.position
        }
        
        // For solid/semi-solid terrain, position bug on the surface
        // Find the top surface of the solid voxel
        let surfacePosition = Position3D(
            voxel.position.x,
            voxel.position.y,
            voxel.position.z + (voxelSize / 2.0) // Position on top of voxel
        )
        
        return surfacePosition
    }
    
    private func tryAlternativeMovement(validMoves: [Direction3D: Voxel], decision: BugOutputs, in voxelWorld: VoxelWorld) {
        // If preferred direction is blocked, try the next best option
        let sortedMoves = validMoves.sorted { (first, second) in
            let firstScore = calculateDirectionScore(direction: first.key, voxel: first.value, decision: decision)
            let secondScore = calculateDirectionScore(direction: second.key, voxel: second.value, decision: decision)
            return firstScore > secondScore
        }
        
        if let (_, bestVoxel) = sortedMoves.first {
            moveToVoxel(bestVoxel, in: voxelWorld)
        }
    }
    
    private func handleStuckPosition(in voxelWorld: VoxelWorld, pathfinding: VoxelPathfinding) {
        // Try to find layer transitions to escape
        let transitions = pathfinding.findLayerTransitions(
            from: currentLayer,
            near: position3D,
            for: dna.speciesTraits.speciesType,
            with: dna,
            searchRadius: 10.0
        )
        
        if let escapeVoxel = transitions.first {
            // Move towards the nearest transition
            if let path = pathfinding.findPath(
                from: position3D,
                to: escapeVoxel.position,
                for: dna.speciesTraits.speciesType,
                with: dna,
                maxDistance: 20.0
            ), path.count > 1 {
                moveToVoxel(path[1], in: voxelWorld)  // Move to next step in path
            }
        } else {
            // Emergency teleport to nearest safe voxel  
            let safePosition3D = voxelWorld.findSpawnPosition()
            if let safeVoxel = voxelWorld.getVoxel(at: safePosition3D) {
                let surfacePosition = calculateSurfacePosition(for: safeVoxel, in: voxelWorld)
                updatePosition3D(surfacePosition)
                position = surfacePosition.position2D
            } else {
                updatePosition3D(safePosition3D)
                position = safePosition3D.position2D
            }
//            print("⚠️ Bug \(id) emergency relocated due to stuck position")
        }
    }
    
    private func consumeVoxelResource(_ voxel: Voxel) {
        guard let resourceType = voxel.resourceType else { return }
        
        let nutritionGain = resourceType.nutritionValue * voxel.foodDensity
        energy = min(Bug.maxEnergy, energy + nutritionGain)
        
        // Reduce resource density (simulating consumption)
        // Note: In a full implementation, we'd need to modify the voxel in the world
    }
    
    // MARK: - Voxel-Based Pathfinding
    
    func findPathToFood(in voxelWorld: VoxelWorld, pathfinding: VoxelPathfinding, maxDistance: Double = 50.0) -> [Voxel]? {
        // Find nearest food voxel
        let nearbyVoxels = findNearbyVoxels(in: voxelWorld, radius: maxDistance)
        let foodVoxels = nearbyVoxels.filter { $0.hasFood }
        
        guard let nearestFood = foodVoxels.min(by: { 
            distance3D(to: $0.position) < distance3D(to: $1.position) 
        }) else {
            return nil
        }
        
        return pathfinding.findPath(
            from: position3D,
            to: nearestFood.position,
            for: dna.speciesTraits.speciesType,
            with: dna,
            maxDistance: maxDistance
        )
    }
    
    func findPathToLayer(_ targetLayer: TerrainLayer, in voxelWorld: VoxelWorld, pathfinding: VoxelPathfinding) -> [Voxel]? {
        let transitions = pathfinding.findLayerTransitions(
            from: currentLayer,
            near: position3D,
            for: dna.speciesTraits.speciesType,
            with: dna,
            searchRadius: 30.0
        )
        
        let targetTransitions = transitions.filter { $0.layer == targetLayer }
        
        guard let nearestTransition = targetTransitions.min(by: {
            distance3D(to: $0.position) < distance3D(to: $1.position)
        }) else {
            return nil
        }
        
        return pathfinding.findPath(
            from: position3D,
            to: nearestTransition.position,
            for: dna.speciesTraits.speciesType,
            with: dna,
            maxDistance: 100.0
        )
    }
    
    private func findNearbyVoxels(in voxelWorld: VoxelWorld, radius: Double) -> [Voxel] {
        var nearbyVoxels: [Voxel] = []
        let currentGridPos = voxelWorld.worldToGrid(position3D)
        let searchRange = Int(radius / voxelWorld.voxelSize)
        
        for x in max(0, currentGridPos.x - searchRange)...min(voxelWorld.dimensions.width - 1, currentGridPos.x + searchRange) {
            for y in max(0, currentGridPos.y - searchRange)...min(voxelWorld.dimensions.height - 1, currentGridPos.y + searchRange) {
                for z in max(0, currentGridPos.z - searchRange)...min(voxelWorld.dimensions.depth - 1, currentGridPos.z + searchRange) {
                    if let voxel = voxelWorld.getVoxel(at: (x, y, z)) {
                        let distance = distance3D(to: voxel.position)
                        if distance <= radius {
                            nearbyVoxels.append(voxel)
                        }
                    }
                }
            }
        }
        
        return nearbyVoxels
    }
}
