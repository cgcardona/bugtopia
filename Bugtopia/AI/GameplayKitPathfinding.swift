//
//  GameplayKitPathfinding.swift
//  Bugtopia
//
//  Created by GameplayKit Developer on 1/15/25.
//  MVP: Digital Pheromone Pathfinding System
//

import Foundation
import GameplayKit
import simd

// MARK: - Pheromone System with GameplayKit

/// Digital pheromone trails that bugs can follow for navigation and communication
class PheromoneFieldManager {
    
    // MARK: - Core GameplayKit Components
    
    private let pheromoneNoise: GKNoise
    private let diffusionNoise: GKNoise
    private let obstacleGraph: GKObstacleGraph<GKGraphNode2D>
    
    // MARK: - Pheromone Data Structures
    
    /// 2D grid storing pheromone intensity for different signal types
    private var pheromoneGrid: [[[Double]]] = [] // [x][y][signalType]
    private var pheromoneUpdates: [(position: CGPoint, signalType: SignalType, strength: Double, timestamp: TimeInterval)] = []
    
    // MARK: - Configuration
    
    private let gridResolution: Int
    private let worldBounds: CGRect
    private let cellSize: Double
    private let maxPheromoneAge: TimeInterval = 30.0 // Pheromones fade after 30 seconds
    private let diffusionRate: Double = 0.1 // How fast pheromones spread
    private let decayRate: Double = 0.02 // How fast pheromones fade
    
    // MARK: - Performance Optimization
    
    private var lastUpdateTime: TimeInterval = 0
    private let updateInterval: TimeInterval = 0.1 // Update 10 times per second
    
    init(worldBounds: CGRect, resolution: Int = 2000) {
        self.worldBounds = worldBounds
        self.gridResolution = resolution
        self.cellSize = worldBounds.width / Double(resolution)
        
        // 🎯 GAMEPLAYKIT NOISE: Create sophisticated pheromone diffusion patterns
        let source = GKPerlinNoiseSource(frequency: 0.1, octaveCount: 3, persistence: 0.5, lacunarity: 2.0, seed: Int32.random(in: 0...1000))
        self.pheromoneNoise = GKNoise(source)
        
        // 🌊 DIFFUSION NOISE: Realistic spreading patterns
        let diffusionSource = GKPerlinNoiseSource(frequency: 0.05, octaveCount: 2, persistence: 0.3, lacunarity: 1.5, seed: Int32.random(in: 0...1000))
        self.diffusionNoise = GKNoise(diffusionSource)
        
        // 🗺️ OBSTACLE GRAPH: For advanced pathfinding around terrain
        self.obstacleGraph = GKObstacleGraph<GKGraphNode2D>()
        
        // Initialize pheromone grid for all signal types
        initializePheromoneGrid()
        
        print("🧪 [PHEROMONE] Initialized digital pheromone field with \(resolution)x\(resolution) resolution")
    }
    
    private func initializePheromoneGrid() {
        pheromoneGrid = Array(repeating: 
            Array(repeating: 
                Array(repeating: 0.0, count: SignalType.allCases.count), 
                count: gridResolution), 
            count: gridResolution)
        
        print("🧪 [PHEROMONE] Grid initialized: \(gridResolution)x\(gridResolution)x\(SignalType.allCases.count)")
    }
    
    // MARK: - Pheromone Trail Creation
    
    /// Adds a pheromone signal to the field based on bug communication
    func addPheromoneSignal(_ signal: Signal, bugPosition: CGPoint) {
        let gridX = worldToGridX(signal.position.x)
        let gridY = worldToGridY(signal.position.y)
        
        // Validate grid bounds
        guard isValidGridPosition(x: gridX, y: gridY) else { return }
        
        let signalIndex = SignalType.allCases.firstIndex(of: signal.type) ?? 0
        let currentTime = Date().timeIntervalSince1970
        
        // 🌈 ENHANCED SIGNAL STRENGTH: Each type has unique characteristics
        let baseIntensity = signal.strength * getEnhancedSignalStrength(for: signal.type)
        
        // 🌊 GAMEPLAYKIT ENHANCEMENT: Use noise for realistic trail variation
        let noiseX = Float(signal.position.x / worldBounds.width)
        let noiseY = Float(signal.position.y / worldBounds.height)
        let noiseVector = vector_float2(noiseX, noiseY)
        let noiseValue = pheromoneNoise.value(atPosition: noiseVector)
        
        // Apply noise for natural variation (±20%)
        let noiseMultiplier = 1.0 + (Double(noiseValue) * 0.2)
        let finalIntensity = baseIntensity * noiseMultiplier
        
        // 🛣️ HIGHWAY DETECTION: Food discovery trails can become superhighways
        let currentStrength = pheromoneGrid[gridX][gridY][signalIndex]
        if signal.type == .foodFound && currentStrength > 0.6 {
            // This is becoming a highway! Make it extra strong and spread wider
            createPheromoneHighway(gridX: gridX, gridY: gridY, signalIndex: signalIndex, intensity: finalIntensity)
        } else {
            // Normal pheromone placement with spreading
            addPheromoneWithSpread(gridX: gridX, gridY: gridY, signalIndex: signalIndex, intensity: finalIntensity)
        }
        
        // Track for updates
        pheromoneUpdates.append((
            position: signal.position,
            signalType: signal.type,
            strength: finalIntensity,
            timestamp: currentTime
        ))
        
        // print("🧪 [PHEROMONE] Added \(signal.type.emoji) signal at (\(gridX), \(gridY)) intensity: \(String(format: "%.2f", finalIntensity))")
    }
    
    /// 🌈 Enhanced signal strength based on signal type importance
    private func getEnhancedSignalStrength(for signalType: SignalType) -> Double {
        switch signalType {
        case .helpRequest: return 0.95    // Maximum urgency! 🆘
        case .dangerAlert: return 0.9     // Critical safety information ⚠️
        case .foodFound: return 0.8       // Strong signal for food success! 🍃
        case .retreat: return 0.75        // Important safety routes 🏃
        case .huntCall: return 0.7        // Strong coordination need 🎯
        case .foodShare: return 0.7       // Important social behavior 🍃
        case .mateCall: return 0.6        // Moderate but persistent 💕
        case .groupForm: return 0.5       // Social coordination 🤝
        case .territoryMark: return 0.3   // Baseline exploration 🏴
        }
    }
    
    /// 🛣️ Creates pheromone highways - reinforced successful routes
    private func createPheromoneHighway(gridX: Int, gridY: Int, signalIndex: Int, intensity: Double) {
        // Strengthen the core cell
        pheromoneGrid[gridX][gridY][signalIndex] = min(1.0, pheromoneGrid[gridX][gridY][signalIndex] + intensity * 1.3)
        
        // 🌟 SPREAD TO ADJACENT CELLS: Highways have wider influence
        let highwayRadius = 2 // Larger radius for highways
        
        for dx in -highwayRadius...highwayRadius {
            for dy in -highwayRadius...highwayRadius {
                let adjX = gridX + dx
                let adjY = gridY + dy
                if isValidGridPosition(x: adjX, y: adjY) {
                    let distance = sqrt(Double(dx * dx + dy * dy))
                    let strengthMultiplier = max(0.1, 1.0 - (distance / Double(highwayRadius)))
                    let adjacentStrength = pheromoneGrid[adjX][adjY][signalIndex]
                    pheromoneGrid[adjX][adjY][signalIndex] = min(1.0, adjacentStrength + intensity * 0.5 * strengthMultiplier)
                }
            }
        }
        
        print("🛣️ [HIGHWAY] Created pheromone superhighway at (\(gridX), \(gridY))")
    }
    
    private func addPheromoneWithSpread(gridX: Int, gridY: Int, signalIndex: Int, intensity: Double) {
        // 🌊 REALISTIC SPREADING: Pheromones don't just appear at a single point
        let spreadRadius = 3 // Affect 7x7 area around signal
        
        for dx in -spreadRadius...spreadRadius {
            for dy in -spreadRadius...spreadRadius {
                let targetX = gridX + dx
                let targetY = gridY + dy
                
                guard isValidGridPosition(x: targetX, y: targetY) else { continue }
                
                // Calculate distance falloff
                let distance = sqrt(Double(dx * dx + dy * dy))
                let falloff = max(0.0, 1.0 - (distance / Double(spreadRadius)))
                let spreadIntensity = intensity * falloff
                
                // Add to existing pheromone level
                pheromoneGrid[targetX][targetY][signalIndex] += spreadIntensity
                
                // Cap maximum pheromone intensity
                pheromoneGrid[targetX][targetY][signalIndex] = min(pheromoneGrid[targetX][targetY][signalIndex], 10.0)
            }
        }
    }
    
    // MARK: - Pathfinding Enhancement
    
    /// Find optimal path considering both terrain and pheromone trails
    func findPheromoneEnhancedPath(from start: CGPoint, to goal: CGPoint, for bug: Bug, avoidSignals: [SignalType] = [], seekSignals: [SignalType] = []) -> [CGPoint] {
        
        let startNode = GKGraphNode2D(point: vector_float2(Float(start.x), Float(start.y)))
        let goalNode = GKGraphNode2D(point: vector_float2(Float(goal.x), Float(goal.y)))
        
        // 🗺️ USE GAMEPLAYKIT PATHFINDING: Much more sophisticated than simple A*
        let pathNodes = obstacleGraph.findPath(from: startNode, to: goalNode) as? [GKGraphNode2D]
        
        var enhancedPath: [CGPoint] = []
        
        if let nodes = pathNodes {
            // Convert GameplayKit path to CGPoints
            for node in nodes {
                let point = CGPoint(x: Double(node.position.x), y: Double(node.position.y))
                enhancedPath.append(point)
            }
        } else {
            // Fallback: Direct line with pheromone consideration
            enhancedPath = createPheromoneInfluencedPath(from: start, to: goal, bug: bug, avoidSignals: avoidSignals, seekSignals: seekSignals)
        }
        
        // 🧪 PHEROMONE ENHANCEMENT: Modify path based on chemical trails
        return optimizePathWithPheromones(path: enhancedPath, bug: bug, avoidSignals: avoidSignals, seekSignals: seekSignals)
    }
    
    private func createPheromoneInfluencedPath(from start: CGPoint, to goal: CGPoint, bug: Bug, avoidSignals: [SignalType], seekSignals: [SignalType]) -> [CGPoint] {
        var path: [CGPoint] = []
        let stepCount = 10 // Create 10 waypoints between start and goal
        
        for i in 0...stepCount {
            let t = Double(i) / Double(stepCount)
            let basePoint = CGPoint(
                x: start.x + (goal.x - start.x) * t,
                y: start.y + (goal.y - start.y) * t
            )
            
            // 🧪 PHEROMONE INFLUENCE: Adjust waypoint based on chemical trails
            let adjustedPoint = adjustPointForPheromones(basePoint, bug: bug, avoidSignals: avoidSignals, seekSignals: seekSignals)
            path.append(adjustedPoint)
        }
        
        return path
    }
    
    private func adjustPointForPheromones(_ point: CGPoint, bug: Bug, avoidSignals: [SignalType], seekSignals: [SignalType]) -> CGPoint {
        let gridX = worldToGridX(point.x)
        let gridY = worldToGridY(point.y)
        
        guard isValidGridPosition(x: gridX, y: gridY) else { return point }
        
        var adjustmentX: Double = 0
        var adjustmentY: Double = 0
        let adjustmentStrength: Double = 5.0 // Maximum displacement in world units
        
        // 🚨 AVOIDANCE: Move away from negative pheromones
        for signalType in avoidSignals {
            if let signalIndex = SignalType.allCases.firstIndex(of: signalType) {
                let intensity = pheromoneGrid[gridX][gridY][signalIndex]
                if intensity > 0.1 {
                    // Calculate gradient to move away from high concentration
                    let gradient = calculatePheromoneGradient(at: point, signalIndex: signalIndex)
                    adjustmentX -= gradient.x * intensity * adjustmentStrength
                    adjustmentY -= gradient.y * intensity * adjustmentStrength
                }
            }
        }
        
        // 🎯 SEEKING: Move toward positive pheromones
        for signalType in seekSignals {
            if let signalIndex = SignalType.allCases.firstIndex(of: signalType) {
                let intensity = pheromoneGrid[gridX][gridY][signalIndex]
                if intensity > 0.1 {
                    // Calculate gradient to move toward high concentration
                    let gradient = calculatePheromoneGradient(at: point, signalIndex: signalIndex)
                    adjustmentX += gradient.x * intensity * adjustmentStrength
                    adjustmentY += gradient.y * intensity * adjustmentStrength
                }
            }
        }
        
        // Apply bug-specific sensitivity
        let sensitivity = bug.dna.communicationDNA.signalSensitivity
        adjustmentX *= sensitivity
        adjustmentY *= sensitivity
        
        return CGPoint(
            x: point.x + adjustmentX,
            y: point.y + adjustmentY
        )
    }
    
    private func calculatePheromoneGradient(at point: CGPoint, signalIndex: Int) -> CGPoint {
        let gridX = worldToGridX(point.x)
        let gridY = worldToGridY(point.y)
        
        // Sample neighboring cells to calculate gradient
        let leftIntensity = getPheromoneSafe(x: gridX - 1, y: gridY, signalIndex: signalIndex)
        let rightIntensity = getPheromoneSafe(x: gridX + 1, y: gridY, signalIndex: signalIndex)
        let upIntensity = getPheromoneSafe(x: gridX, y: gridY - 1, signalIndex: signalIndex)
        let downIntensity = getPheromoneSafe(x: gridX, y: gridY + 1, signalIndex: signalIndex)
        
        let gradientX = (rightIntensity - leftIntensity) / 2.0
        let gradientY = (downIntensity - upIntensity) / 2.0
        
        // Normalize gradient
        let magnitude = sqrt(gradientX * gradientX + gradientY * gradientY)
        if magnitude > 0 {
            return CGPoint(x: gradientX / magnitude, y: gradientY / magnitude)
        }
        
        return CGPoint.zero
    }
    
    private func optimizePathWithPheromones(path: [CGPoint], bug: Bug, avoidSignals: [SignalType], seekSignals: [SignalType]) -> [CGPoint] {
        // For MVP, return the path as-is
        // Future: Add waypoint optimization based on pheromone fields
        return path
    }
    
    // MARK: - Pheromone Field Updates
    
    /// Update pheromone field - call this every frame
    func updatePheromoneField() {
        let currentTime = Date().timeIntervalSince1970
        
        // Throttle updates for performance
        if currentTime - lastUpdateTime < updateInterval {
            return
        }
        lastUpdateTime = currentTime
        
        // 🌊 DIFFUSION: Spread pheromones using GameplayKit noise
        applyPheromoneDeiffusion()
        
        // ⏰ DECAY: Natural fading over time
        applyPheromoneDecay()
        
        // 🧹 CLEANUP: Remove old pheromone updates
        cleanupOldPheromoneUpdates(currentTime: currentTime)
    }
    
    private func applyPheromoneDeiffusion() {
        // Create temporary grid for diffusion calculations
        var newGrid = pheromoneGrid
        
        for x in 1..<(gridResolution-1) {
            for y in 1..<(gridResolution-1) {
                for signalIndex in 0..<SignalType.allCases.count {
                    let currentIntensity = pheromoneGrid[x][y][signalIndex]
                    
                    if currentIntensity > 0.01 {
                        // 🌊 GAMEPLAYKIT DIFFUSION: Use noise for realistic spreading patterns
                        let noiseX = Float(x) / Float(gridResolution)
                        let noiseY = Float(y) / Float(gridResolution)
                        let noiseVector = vector_float2(noiseX, noiseY)
                        let diffusionMultiplier = abs(diffusionNoise.value(atPosition: noiseVector))
                        
                        // Calculate diffusion to neighboring cells
                        let diffusionAmount = currentIntensity * diffusionRate * Double(diffusionMultiplier)
                        
                        // Spread to 8 neighboring cells
                        for dx in -1...1 {
                            for dy in -1...1 {
                                if dx == 0 && dy == 0 { continue } // Skip center cell
                                
                                let targetX = x + dx
                                let targetY = y + dy
                                
                                if isValidGridPosition(x: targetX, y: targetY) {
                                    let spreadAmount = diffusionAmount / 8.0 // Equal distribution
                                    newGrid[targetX][targetY][signalIndex] += spreadAmount
                                    newGrid[x][y][signalIndex] -= spreadAmount
                                }
                            }
                        }
                    }
                }
            }
        }
        
        pheromoneGrid = newGrid
    }
    
    private func applyPheromoneDecay() {
        for x in 0..<gridResolution {
            for y in 0..<gridResolution {
                for signalIndex in 0..<SignalType.allCases.count {
                    pheromoneGrid[x][y][signalIndex] *= (1.0 - decayRate)
                    
                    // Remove very weak pheromones
                    if pheromoneGrid[x][y][signalIndex] < 0.001 {
                        pheromoneGrid[x][y][signalIndex] = 0.0
                    }
                }
            }
        }
    }
    
    private func cleanupOldPheromoneUpdates(currentTime: TimeInterval) {
        pheromoneUpdates.removeAll { update in
            currentTime - update.timestamp > maxPheromoneAge
        }
    }
    
    // MARK: - Pheromone Queries
    
    /// Get pheromone intensity at a specific world position
    func getPheromoneIntensity(at position: CGPoint, for signalType: SignalType) -> Double {
        let gridX = worldToGridX(position.x)
        let gridY = worldToGridY(position.y)
        
        guard isValidGridPosition(x: gridX, y: gridY),
              let signalIndex = SignalType.allCases.firstIndex(of: signalType) else {
            return 0.0
        }
        
        return pheromoneGrid[gridX][gridY][signalIndex]
    }
    
    /// Find the direction of strongest pheromone gradient
    func getPheromoneDirection(at position: CGPoint, for signalType: SignalType) -> CGPoint? {
        guard let signalIndex = SignalType.allCases.firstIndex(of: signalType) else { return nil }
        
        let gradient = calculatePheromoneGradient(at: position, signalIndex: signalIndex)
        
        // Return nil if gradient is too weak
        if abs(gradient.x) < 0.01 && abs(gradient.y) < 0.01 {
            return nil
        }
        
        return gradient
    }
    
    // MARK: - Utility Functions
    
    private func worldToGridX(_ worldX: Double) -> Int {
        let normalizedX = (worldX - worldBounds.minX) / worldBounds.width
        return Int(normalizedX * Double(gridResolution)).clamped(to: 0..<gridResolution)
    }
    
    private func worldToGridY(_ worldY: Double) -> Int {
        let normalizedY = (worldY - worldBounds.minY) / worldBounds.height
        return Int(normalizedY * Double(gridResolution)).clamped(to: 0..<gridResolution)
    }
    
    private func isValidGridPosition(x: Int, y: Int) -> Bool {
        return x >= 0 && x < gridResolution && y >= 0 && y < gridResolution
    }
    
    private func getPheromoneSafe(x: Int, y: Int, signalIndex: Int) -> Double {
        guard isValidGridPosition(x: x, y: y) else { return 0.0 }
        return pheromoneGrid[x][y][signalIndex]
    }
    
    // MARK: - Debug Visualization
    
    func getPheromoneVisualizationData() -> [PheromoneVisualizationPoint] {
        var points: [PheromoneVisualizationPoint] = []
        
        for x in stride(from: 0, to: gridResolution, by: 4) { // Sample every 4th cell for performance
            for y in stride(from: 0, to: gridResolution, by: 4) {
                for (signalIndex, signalType) in SignalType.allCases.enumerated() {
                    let intensity = pheromoneGrid[x][y][signalIndex]
                    
                    if intensity > 0.1 { // Only show significant pheromones
                        let worldX = worldBounds.minX + (Double(x) / Double(gridResolution)) * worldBounds.width
                        let worldY = worldBounds.minY + (Double(y) / Double(gridResolution)) * worldBounds.height
                        
                        points.append(PheromoneVisualizationPoint(
                            position: CGPoint(x: worldX, y: worldY),
                            signalType: signalType,
                            intensity: intensity
                        ))
                    }
                }
            }
        }
        
        return points
    }
}

// MARK: - Supporting Types

struct PheromoneVisualizationPoint {
    let position: CGPoint
    let signalType: SignalType
    let intensity: Double
}

// MARK: - Bug Extension for Pheromone Navigation

extension Bug {
    
    /// Enhanced pathfinding that considers pheromone trails
    func findPheromoneEnhancedPath(to target: CGPoint, pheromoneManager: PheromoneFieldManager) -> [CGPoint] {
        
        // Determine which signals to seek/avoid based on bug behavior
        var seekSignals: [SignalType] = []
        var avoidSignals: [SignalType] = []
        
        // 🍃 FOOD SEEKING: Follow food found signals
        if energy < Bug.maxEnergy * 0.6 { // Hungry bugs seek food
            seekSignals.append(.foodFound)
            seekSignals.append(.foodShare)
        }
        
        // 🚨 DANGER AVOIDANCE: Avoid danger signals
        avoidSignals.append(.dangerAlert)
        avoidSignals.append(.retreat)
        
        // 🎯 HUNT COORDINATION: Carnivores follow hunt calls
        if dna.speciesTraits.speciesType.canHunt && energy > Bug.maxEnergy * 0.5 {
            seekSignals.append(.huntCall)
        }
        
        // 🤝 SOCIAL BEHAVIOR: Seek group formation if social
        if dna.communicationDNA.socialResponseRate > 0.7 {
            seekSignals.append(.groupForm)
        }
        
        return pheromoneManager.findPheromoneEnhancedPath(
            from: position,
            to: target,
            for: self,
            avoidSignals: avoidSignals,
            seekSignals: seekSignals
        )
    }
    
    /// Create pheromone trail while moving
    func layPheromoneTrail(signalType: SignalType, strength: Double, pheromoneManager: PheromoneFieldManager) {
        let signal = Signal(
            type: signalType,
            position: position,
            emitterId: id,
            strength: strength,
            timestamp: Date().timeIntervalSince1970,
            data: nil
        )
        
        pheromoneManager.addPheromoneSignal(signal, bugPosition: position)
    }
}

// MARK: - Utility Extensions

extension Int {
    func clamped(to range: Range<Int>) -> Int {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound - 1, self))
    }
}
