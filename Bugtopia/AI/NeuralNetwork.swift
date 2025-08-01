//
//  NeuralNetwork.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

/// Activation functions for neural network nodes
enum ActivationType: String, CaseIterable, Codable {
    case sigmoid = "sigmoid"
    case hyperbolicTangent = "tanh"
    case relu = "relu"
    case linear = "linear"
    
    func activate(_ input: Double) -> Double {
        switch self {
        case .sigmoid:
            return 1.0 / (1.0 + exp(-input))
        case .hyperbolicTangent:
            return Foundation.tanh(input)  // Explicitly use Foundation's tanh
        case .relu:
            return max(0, input)
        case .linear:
            return input
        }
    }
    
    /// Derivative for backpropagation (though we'll use evolution instead)
    func derivative(_ output: Double) -> Double {
        switch self {
        case .sigmoid:
            return output * (1.0 - output)
        case .hyperbolicTangent:
            return 1.0 - (output * output)
        case .relu:
            return output > 0 ? 1.0 : 0.0
        case .linear:
            return 1.0
        }
    }
}

/// Neural network architecture that can evolve
struct NeuralDNA: Codable, Hashable {
    
    // MARK: - Network Structure
    
    /// Number of neurons in each layer [input, hidden1, hidden2, ..., output]
    let topology: [Int]
    
    /// All connection weights (flattened from layer matrices)
    let weights: [Double]
    
    /// Bias values for each non-input neuron
    let biases: [Double]
    
    /// Activation function for each layer
    let activations: [ActivationType]
    
    // MARK: - Network Configuration
    
    static let inputCount = 50  // 28 base + 6 weather + 6 disaster + 6 ecosystem + 4 territory inputs  // Sensory inputs (expanded for predator/prey + edge detection + seasonal + weather + disaster awareness)
    static let outputCount = 8   // Motor outputs (expanded for hunting/fleeing)
    static let maxHiddenLayers = 8    // Allow much deeper networks (up to 10 total layers!)
    static let maxNeuronsPerLayer = 32 // Allow wider networks for complex processing
    
    // MARK: - Initialization
    
    /// Creates a neural network with specific architecture
    init(topology: [Int], weights: [Double], biases: [Double], activations: [ActivationType]) {
        self.topology = topology
        self.weights = weights
        self.biases = biases
        self.activations = activations
    }
    
    /// Creates a random neural network
    static func random() -> NeuralDNA {
        // Random topology: always starts with inputCount and ends with outputCount
        let hiddenLayerCount = Int.random(in: 1...maxHiddenLayers)
        var topology = [inputCount]
        
        for i in 0..<hiddenLayerCount {
            // Create more varied layer sizes - some narrow, some wide
            let layerSize: Int
            if i == 0 {
                // First hidden layer can be wide for feature detection
                layerSize = Int.random(in: 8...maxNeuronsPerLayer)
            } else if i == hiddenLayerCount - 1 {
                // Last hidden layer typically narrower before output
                layerSize = Int.random(in: 4...16)
            } else {
                // Middle layers vary widely
                layerSize = Int.random(in: 3...maxNeuronsPerLayer)
            }
            topology.append(layerSize)
        }
        topology.append(outputCount)
        
        // Calculate total weights needed
        var totalWeights = 0
        var totalBiases = 0
        
        for i in 0..<(topology.count - 1) {
            totalWeights += topology[i] * topology[i + 1]
            totalBiases += topology[i + 1]
        }
        
        // Generate random weights and biases
        let weights = (0..<totalWeights).map { _ in 
            Double.random(in: -2.0...2.0)
        }
        
        let biases = (0..<totalBiases).map { _ in 
            Double.random(in: -1.0...1.0)
        }
        
        // Random activation functions for each layer (except input)
        let activations = (0..<topology.count).map { i in
            if i == 0 {
                return ActivationType.linear // Input layer
            } else if i == topology.count - 1 {
                return ActivationType.hyperbolicTangent // Output layer (-1 to 1 range)
            } else {
                return ActivationType.allCases.randomElement() ?? .sigmoid
            }
        }
        
        return NeuralDNA(topology: topology, weights: weights, biases: biases, activations: activations)
    }
    
    // MARK: - Genetic Operations
    
    /// Creates offspring by crossing over two neural networks
    static func crossover(_ parent1: NeuralDNA, _ parent2: NeuralDNA) -> NeuralDNA {
        // If topologies are different, use the simpler one and adapt
        let baseParent = parent1.topology.count <= parent2.topology.count ? parent1 : parent2
        let otherParent = parent1.topology.count <= parent2.topology.count ? parent2 : parent1
        
        var newWeights: [Double] = []
        var newBiases: [Double] = []
        
        // Crossover weights and biases
        let minWeights = min(baseParent.weights.count, otherParent.weights.count)
        let minBiases = min(baseParent.biases.count, otherParent.biases.count)
        
        for i in 0..<minWeights {
            newWeights.append(Bool.random() ? baseParent.weights[i] : otherParent.weights[i])
        }
        
        // Fill remaining weights from base parent
        if baseParent.weights.count > minWeights {
            newWeights.append(contentsOf: baseParent.weights[minWeights...])
        }
        
        for i in 0..<minBiases {
            newBiases.append(Bool.random() ? baseParent.biases[i] : otherParent.biases[i])
        }
        
        // Fill remaining biases from base parent
        if baseParent.biases.count > minBiases {
            newBiases.append(contentsOf: baseParent.biases[minBiases...])
        }
        
        // Crossover activations
        var newActivations: [ActivationType] = []
        let minActivations = min(baseParent.activations.count, otherParent.activations.count)
        
        for i in 0..<minActivations {
            newActivations.append(Bool.random() ? baseParent.activations[i] : otherParent.activations[i])
        }
        
        // Fill remaining activations from base parent
        if baseParent.activations.count > minActivations {
            newActivations.append(contentsOf: baseParent.activations[minActivations...])
        }
        
        return NeuralDNA(
            topology: baseParent.topology,
            weights: newWeights,
            biases: newBiases,
            activations: newActivations
        )
    }
    
    /// Creates a mutated version of this neural network
    func mutated(mutationRate: Double = 0.1, mutationStrength: Double = 0.3) -> NeuralDNA {
        var newWeights = weights
        var newBiases = biases
        var newTopology = topology
        var newActivations = activations
        
        // Mutate weights
        for i in 0..<newWeights.count {
            if Double.random(in: 0...1) < mutationRate {
                let mutation = Double.random(in: -mutationStrength...mutationStrength)
                newWeights[i] = max(-5.0, min(5.0, newWeights[i] + mutation))
            }
        }
        
        // Mutate biases
        for i in 0..<newBiases.count {
            if Double.random(in: 0...1) < mutationRate {
                let mutation = Double.random(in: -mutationStrength...mutationStrength)
                newBiases[i] = max(-3.0, min(3.0, newBiases[i] + mutation))
            }
        }
        
        // Structural mutations (rare but powerful)
        if Double.random(in: 0...1) < mutationRate * 0.05 { // 5% of mutation rate
            // Major structural changes
            
            // Chance to add a hidden layer (network growth!)
            if Double.random(in: 0...1) < 0.3 && newTopology.count < (Self.maxHiddenLayers + 2) {
                let insertPosition = Int.random(in: 1..<(newTopology.count - 1)) // Don't insert before input or after output
                let newLayerSize = Int.random(in: 3...16)
                newTopology.insert(newLayerSize, at: insertPosition)
                
                // Add corresponding activation
                let newActivation = ActivationType.allCases.randomElement() ?? .sigmoid
                newActivations.insert(newActivation, at: insertPosition)
                
                // Recalculate weights and biases for new structure
                return NeuralDNA.random() // For now, regenerate (in future could preserve some weights)
            }
            
            // Chance to remove a hidden layer (network pruning)
            if Double.random(in: 0...1) < 0.2 && newTopology.count > 3 { // Keep at least 1 hidden layer
                let removePosition = Int.random(in: 1..<(newTopology.count - 1))
                newTopology.remove(at: removePosition)
                newActivations.remove(at: removePosition)
                
                // Recalculate weights and biases for new structure
                return NeuralDNA.random() // For now, regenerate
            }
            
            // Change activation functions
            for i in 1..<(newActivations.count - 1) { // Don't change input/output layers
                if Double.random(in: 0...1) < 0.2 {
                    newActivations[i] = ActivationType.allCases.randomElement() ?? newActivations[i]
                }
            }
        }
        
        return NeuralDNA(
            topology: newTopology,
            weights: newWeights,
            biases: newBiases,
            activations: newActivations
        )
    }
}

/// Actual neural network that executes forward passes
class NeuralNetwork {
    
    private let dna: NeuralDNA
    private var layers: [[Double]] = []
    
    init(dna: NeuralDNA) {
        self.dna = dna
        
        // Initialize layer arrays
        for neuronCount in dna.topology {
            layers.append(Array(repeating: 0.0, count: neuronCount))
        }
    }
    
    /// Forward pass through the network
    func predict(inputs: [Double]) -> [Double] {
        guard inputs.count == dna.topology[0] else {
            print("⚠️ Input size mismatch: expected \(dna.topology[0]), got \(inputs.count)")
            return Array(repeating: 0.0, count: dna.topology.last ?? 1)
        }
        
        // Set input layer
        layers[0] = inputs
        
        var weightIndex = 0
        var biasIndex = 0
        
        // Forward propagate through each layer
        for layerIndex in 1..<layers.count {
            let prevLayerSize = layers[layerIndex - 1].count
            let currentLayerSize = layers[layerIndex].count
            let activation = dna.activations[layerIndex]
            
            for neuronIndex in 0..<currentLayerSize {
                var sum = dna.biases[biasIndex + neuronIndex]
                
                // Calculate weighted sum from previous layer
                for prevNeuronIndex in 0..<prevLayerSize {
                    sum += layers[layerIndex - 1][prevNeuronIndex] * dna.weights[weightIndex]
                    weightIndex += 1
                }
                
                // Apply activation function
                layers[layerIndex][neuronIndex] = activation.activate(sum)
            }
            
            biasIndex += currentLayerSize
        }
        
        return layers.last ?? []
    }
}

/// Input/Output definitions for bug neural networks
struct BugSensors {
    
    /// Creates sensory input vector for neural network (including seasonal, weather, and disaster awareness)
    static func createInputs(
        bug: Bug,
        arena: Arena,
        foods: [CGPoint],
        otherBugs: [Bug],
        seasonalManager: SeasonalManager,
        weatherManager: WeatherManager,
        disasterManager: DisasterManager,
        ecosystemManager: EcosystemManager,
        territoryManager: TerritoryManager
    ) -> [Double] {
        
        var inputs: [Double] = []
        
        // Energy status (0-1)
        inputs.append(bug.energy / Bug.maxEnergy)
        
        // Age status (0-1)
        inputs.append(Double(bug.age) / Double(Bug.maxAge))
        
        // Current terrain effects
        let modifiers = arena.movementModifiers(at: bug.position, for: bug.dna)
        inputs.append(modifiers.speed)
        inputs.append(modifiers.vision)
        inputs.append(modifiers.energyCost)
        
        // Nearest food direction and distance (normalized)
        if let nearestFood = foods.min(by: { bug.distance(to: $0) < bug.distance(to: $1) }) {
            let distance = bug.distance(to: nearestFood)
            let maxDistance = arena.bounds.width // Normalize by arena size
            
            inputs.append(min(1.0, distance / maxDistance))
            
            // Food direction (normalized)
            let dx = (nearestFood.x - bug.position.x) / maxDistance
            let dy = (nearestFood.y - bug.position.y) / maxDistance
            inputs.append(max(-1.0, min(1.0, dx)))
            inputs.append(max(-1.0, min(1.0, dy)))
        } else {
            inputs.append(1.0) // No food = max distance
            inputs.append(0.0)
            inputs.append(0.0)
        }
        
        // Predator detection (nearest predator)
        let predators = otherBugs.filter { $0.id != bug.id && $0.dna.speciesTraits.speciesType.canHunt && $0.dna.speciesTraits.speciesType != bug.dna.speciesTraits.speciesType }
        if let nearestPredator = predators.min(by: { bug.distance(to: $0.position) < bug.distance(to: $1.position) }) {
            let distance = bug.distance(to: nearestPredator.position)
            let maxDistance = arena.bounds.width
            inputs.append(min(1.0, distance / maxDistance))
            
            // Predator direction (normalized)
            let dx = (nearestPredator.position.x - bug.position.x) / maxDistance
            let dy = (nearestPredator.position.y - bug.position.y) / maxDistance
            inputs.append(max(-1.0, min(1.0, dx)))
            inputs.append(max(-1.0, min(1.0, dy)))
        } else {
            inputs.append(1.0) // No predators
            inputs.append(0.0)
            inputs.append(0.0)
        }
        
        // Prey detection (for carnivores/omnivores)
        if bug.dna.speciesTraits.speciesType.canHunt {
            let prey = otherBugs.filter { $0.id != bug.id && $0.dna.speciesTraits.speciesType != bug.dna.speciesTraits.speciesType }
            if let nearestPrey = prey.min(by: { bug.distance(to: $0.position) < bug.distance(to: $1.position) }) {
                let distance = bug.distance(to: nearestPrey.position)
                let maxDistance = arena.bounds.width
                inputs.append(min(1.0, distance / maxDistance))
                
                // Prey direction (normalized)
                let dx = (nearestPrey.position.x - bug.position.x) / maxDistance
                let dy = (nearestPrey.position.y - bug.position.y) / maxDistance
                inputs.append(max(-1.0, min(1.0, dx)))
                inputs.append(max(-1.0, min(1.0, dy)))
            } else {
                inputs.append(1.0) // No prey
                inputs.append(0.0)
                inputs.append(0.0)
            }
        } else {
            // Herbivores don't hunt
            inputs.append(1.0)
            inputs.append(0.0)
            inputs.append(0.0)
        }
        
        // Edge proximity detection (helps neural networks learn edge avoidance)
        let edgeDistanceX = min(bug.position.x - arena.bounds.minX, arena.bounds.maxX - bug.position.x)
        let edgeDistanceY = min(bug.position.y - arena.bounds.minY, arena.bounds.maxY - bug.position.y)
        let maxEdgeDistance = min(arena.bounds.width, arena.bounds.height) / 2.0
        
        // Normalized edge distances (0 = at edge, 1 = far from edge)
        inputs.append(min(1.0, edgeDistanceX / maxEdgeDistance))
        inputs.append(min(1.0, edgeDistanceY / maxEdgeDistance))
        
        // Direction to arena center (helps bugs navigate toward safer areas)
        let centerX = arena.bounds.midX
        let centerY = arena.bounds.midY
        let centerDx = (centerX - bug.position.x) / arena.bounds.width
        let centerDy = (centerY - bug.position.y) / arena.bounds.height
        inputs.append(max(-1.0, min(1.0, centerDx)))
        inputs.append(max(-1.0, min(1.0, centerDy)))
        
        // Current velocity (normalized)
        inputs.append(max(-1.0, min(1.0, bug.velocity.x / 10.0)))
        inputs.append(max(-1.0, min(1.0, bug.velocity.y / 10.0)))
        
        // SEASONAL AWARENESS - Critical for planning and adaptation
        // Current season indicators (one-hot encoding)
        let seasonalInputs = seasonalManager.seasonalInputs  // [spring, summer, fall, winter]
        inputs.append(contentsOf: seasonalInputs)
        
        // Season progress (0.0 to 1.0) - how far through current season
        inputs.append(seasonalManager.seasonProgress)
        
        // Environmental pressures from current season
        inputs.append(seasonalManager.currentSeason.foodAbundance)      // Food availability
        inputs.append(seasonalManager.currentSeason.energyDrainModifier) // Energy requirements
        inputs.append(seasonalManager.currentSeason.reproductionModifier) // Breeding opportunity
        
        // Weather awareness (6 inputs)
        let weatherInputs = weatherManager.weatherInputs
        inputs.append(contentsOf: weatherInputs)
        
                // Disaster awareness (6 inputs)
        let disasterInputs = disasterManager.disasterInputs
        inputs.append(contentsOf: disasterInputs)
        
        // Ecosystem awareness (6 inputs)
        let ecosystemInputs = ecosystemManager.ecosystemInputs
        inputs.append(contentsOf: ecosystemInputs)
        
        // Territory awareness (4 inputs)
        let territoryInputs = territoryManager.getTerritoryInputs(at: bug.position, for: bug.populationId)
        inputs.append(contentsOf: territoryInputs)

        return inputs
    }
}

struct BugOutputs {
    let moveX: Double        // Desired X velocity (-1 to 1)
    let moveY: Double        // Desired Y velocity (-1 to 1)
    let aggression: Double   // Aggressive behavior intensity (0 to 1)
    let exploration: Double  // Exploration vs exploitation (0 to 1)
    let social: Double       // Social seeking behavior (0 to 1)
    let reproduction: Double // Reproduction seeking (0 to 1)
    let hunting: Double      // Hunting behavior intensity (0 to 1)
    let fleeing: Double      // Fleeing behavior intensity (0 to 1)
    
    init(from outputs: [Double]) {
        moveX = outputs.count > 0 ? max(-1.0, min(1.0, outputs[0])) : 0.0
        moveY = outputs.count > 1 ? max(-1.0, min(1.0, outputs[1])) : 0.0
        aggression = outputs.count > 2 ? max(0.0, min(1.0, outputs[2])) : 0.0
        exploration = outputs.count > 3 ? max(0.0, min(1.0, outputs[3])) : 0.0
        social = outputs.count > 4 ? max(0.0, min(1.0, outputs[4])) : 0.0
        reproduction = outputs.count > 5 ? max(0.0, min(1.0, outputs[5])) : 0.0
        hunting = outputs.count > 6 ? max(0.0, min(1.0, outputs[6])) : 0.0
        fleeing = outputs.count > 7 ? max(0.0, min(1.0, outputs[7])) : 0.0
    }
}

// MARK: - Extensions

// Bug already has distance(to:) method defined in Bug.swift