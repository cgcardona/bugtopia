//
//  NeuralEnergyManager.swift
//  Bugtopia
//
//  Neural Energy Economics System
//  Makes intelligence cost energy - creating trade-offs between brain power and survival
//

import Foundation
import SwiftUI

/// Manages neural energy consumption and adaptive brain scaling
@Observable
class NeuralEnergyManager {
    
    // MARK: - Energy Cost Configuration
    
    /// Base energy cost per neuron per tick
    static let baseNeuronCost: Double = 0.002
    
    /// Energy cost per connection (weight) per tick
    static let baseConnectionCost: Double = 0.0005
    
    /// Energy cost per layer (complexity penalty)
    static let baseLayerCost: Double = 0.01
    
    /// Minimum energy threshold before brain pruning kicks in
    static let brainPruningThreshold: Double = 20.0
    
    /// Maximum energy threshold for brain growth
    static let brainGrowthThreshold: Double = 80.0
    
    /// Energy efficiency bonus range for neural optimization
    static let efficiencyBonusRange: Double = 0.5
    
    // MARK: - Neural Energy Calculations
    
    /// Calculate total neural energy cost for a bug's brain
    static func calculateNeuralEnergyCost(for neuralDNA: NeuralDNA, efficiency: Double) -> Double {
        let totalNeurons = neuralDNA.topology.reduce(0, +)
        let totalConnections = calculateTotalConnections(topology: neuralDNA.topology)
        let totalLayers = neuralDNA.topology.count
        
        // Base costs
        let neuronCost = Double(totalNeurons) * baseNeuronCost
        let connectionCost = Double(totalConnections) * baseConnectionCost
        let layerCost = Double(totalLayers) * baseLayerCost
        
        let baseCost = neuronCost + connectionCost + layerCost
        
        // Apply efficiency modifier (better efficiency = lower cost)
        let efficiencyMultiplier = 2.0 - efficiency // Inverted: 0.5 efficiency = 1.5x cost, 1.5 efficiency = 0.5x cost
        
        return baseCost * efficiencyMultiplier
    }
    
    /// Calculate total number of connections in a neural network
    private static func calculateTotalConnections(topology: [Int]) -> Int {
        var totalConnections = 0
        for i in 0..<(topology.count - 1) {
            totalConnections += topology[i] * topology[i + 1]
        }
        return totalConnections
    }
    
    /// Get neural complexity score (for visualization and analysis)
    static func calculateComplexityScore(for neuralDNA: NeuralDNA) -> Double {
        let totalNeurons = neuralDNA.topology.reduce(0, +)
        let totalConnections = calculateTotalConnections(topology: neuralDNA.topology)
        let totalLayers = neuralDNA.topology.count
        
        // Weighted complexity score
        return Double(totalNeurons) * 0.4 + Double(totalConnections) * 0.4 + Double(totalLayers) * 0.2
    }
    
    // MARK: - Adaptive Brain Scaling
    
    /// Determine if a bug should prune its neural network due to low energy
    static func shouldPruneNetwork(currentEnergy: Double, neuralCost: Double) -> Bool {
        return currentEnergy < brainPruningThreshold && neuralCost > currentEnergy * 0.15
    }
    
    /// Determine if a bug can grow its neural network due to abundant energy
    static func canGrowNetwork(currentEnergy: Double, neuralCost: Double) -> Bool {
        return currentEnergy > brainGrowthThreshold && neuralCost < currentEnergy * 0.05
    }
    
    /// Create a pruned version of a neural network (remove smallest layer)
    static func pruneNetwork(_ neuralDNA: NeuralDNA) -> NeuralDNA {
        guard neuralDNA.topology.count > 3 else { return neuralDNA } // Don't prune below input-hidden-output
        
        // Find the smallest hidden layer to remove
        var newTopology = neuralDNA.topology
        var smallestLayerIndex = 1 // Start from first hidden layer
        var smallestLayerSize = newTopology[1]
        
        for i in 1..<(newTopology.count - 1) { // Skip input and output layers
            if newTopology[i] < smallestLayerSize {
                smallestLayerSize = newTopology[i]
                smallestLayerIndex = i
            }
        }
        
        // Remove the smallest layer
        newTopology.remove(at: smallestLayerIndex)
        
        // Regenerate weights and biases for new topology
        return NeuralDNA.random(topology: newTopology)
    }
    
    /// Create a grown version of a neural network (add new layer)
    static func growNetwork(_ neuralDNA: NeuralDNA) -> NeuralDNA {
        guard neuralDNA.topology.count < NeuralDNA.maxHiddenLayers + 2 else { return neuralDNA } // Don't exceed max layers
        
        var newTopology = neuralDNA.topology
        
        // Add a new hidden layer of moderate size
        let newLayerSize = Int.random(in: 4...12)
        let insertPosition = Int.random(in: 1..<newTopology.count) // Insert anywhere in hidden layers
        
        newTopology.insert(newLayerSize, at: insertPosition)
        
        // Regenerate weights and biases for new topology
        return NeuralDNA.random(topology: newTopology)
    }
    
    // MARK: - Energy Efficiency Evolution
    
    /// Calculate neural efficiency bonus based on network optimization
    static func calculateEfficiencyBonus(for neuralDNA: NeuralDNA) -> Double {
        let complexity = calculateComplexityScore(for: neuralDNA)
        let totalLayers = neuralDNA.topology.count
        
        // Reward balanced architectures over extremely complex ones
        let balanceScore = 1.0 / (1.0 + complexity / 100.0) // Diminishing returns on complexity
        let depthPenalty = totalLayers > 6 ? Double(totalLayers - 6) * 0.05 : 0.0 // Penalty for very deep networks
        
        let efficiencyBonus = (balanceScore - depthPenalty) * efficiencyBonusRange
        return max(-efficiencyBonusRange, min(efficiencyBonusRange, efficiencyBonus))
    }
    
    // MARK: - Intelligence Metrics
    
    /// Calculate intelligence score based on neural complexity and efficiency
    static func calculateIntelligenceScore(for neuralDNA: NeuralDNA, efficiency: Double) -> Double {
        let complexity = calculateComplexityScore(for: neuralDNA)
        let efficiencyBonus = calculateEfficiencyBonus(for: neuralDNA)
        let energyCost = calculateNeuralEnergyCost(for: neuralDNA, efficiency: efficiency)
        
        // Intelligence = complexity adjusted for efficiency and energy cost
        let rawIntelligence = complexity + (efficiencyBonus * 20.0)
        let costPenalty = energyCost * 10.0 // Higher cost reduces effective intelligence
        
        return max(0, rawIntelligence - costPenalty)
    }
}

// MARK: - Neural DNA Extensions

extension NeuralDNA {
    /// Create a random neural network with specific topology
    static func random(topology: [Int]) -> NeuralDNA {
        // Calculate total weights and biases needed
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
        
        // Random activation functions for each layer
        let activations = topology.map { _ in 
            ActivationType.allCases.randomElement()!
        }
        
        return NeuralDNA(
            topology: topology,
            weights: weights,
            biases: biases,
            activations: activations
        )
    }
}