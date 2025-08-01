//
//  BugDNA.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

/// Represents the genetic makeup of a bug with evolvable traits
struct BugDNA: Codable, Hashable {
    
    // MARK: - Core Movement Traits
    
    /// Movement speed multiplier (0.1 to 2.0)
    let speed: Double
    
    /// Vision radius in simulation units (10 to 100)
    let visionRadius: Double
    
    /// Energy consumption efficiency (0.5 to 1.5, lower is better)
    let energyEfficiency: Double
    
    /// Bug size affecting collision and visibility (0.5 to 2.0)
    let size: Double
    
    // MARK: - Environmental Adaptation Traits
    
    /// Physical strength for climbing hills and obstacles (0.2 to 1.5)
    let strength: Double
    
    /// Memory/intelligence for pathfinding and maze solving (0.1 to 1.2)
    let memory: Double
    
    /// Grip/stickiness for vertical surfaces and rough terrain (0.3 to 1.3)
    let stickiness: Double
    
    /// Camouflage ability to avoid predators and threats (0.0 to 1.0)
    let camouflage: Double
    
    // MARK: - Behavioral Traits
    
    /// Aggression level affecting interactions (0.0 to 1.0)
    let aggression: Double
    
    /// Exploration vs exploitation tendency (0.0 to 1.0)
    let curiosity: Double
    
    // MARK: - Neural Intelligence
    
    /// Evolvable neural network for decision making
    let neuralDNA: NeuralDNA
    
    // MARK: - Visual Traits
    
    /// Primary color hue (0.0 to 1.0)
    let colorHue: Double
    
    /// Color saturation (0.3 to 1.0)
    let colorSaturation: Double
    
    /// Color brightness (0.4 to 1.0)
    let colorBrightness: Double
    
    // MARK: - Computed Properties
    
    /// SwiftUI Color representation of the bug
    var color: Color {
        Color(hue: colorHue, saturation: colorSaturation, brightness: colorBrightness)
    }
    
    /// Fitness score based on trait optimization and environmental adaptation
    var geneticFitness: Double {
        let speedBonus = speed * 0.15
        let visionBonus = visionRadius * 0.008
        let efficiencyBonus = (2.0 - energyEfficiency) * 0.2
        let strengthBonus = strength * 0.1
        let memoryBonus = memory * 0.12
        let stickinessBonus = stickiness * 0.08
        let camouflageBonus = camouflage * 0.1
        let balanceBonus = (1.0 - abs(aggression - 0.5)) * 0.1
        let curiosityBonus = curiosity * 0.05
        
        return speedBonus + visionBonus + efficiencyBonus + strengthBonus + 
               memoryBonus + stickinessBonus + camouflageBonus + balanceBonus + curiosityBonus
    }
    
    /// Specialized fitness for overcoming specific terrain challenges
    func terrainFitness(for terrainType: TerrainType) -> Double {
        switch terrainType {
        case .water:
            return (speed * 0.4 + (2.0 - energyEfficiency) * 0.4 + stickiness * 0.2)
        case .hill:
            return (strength * 0.6 + size * 0.2 + stickiness * 0.2)
        case .shadow:
            return (visionRadius * 0.01 + memory * 0.4 + curiosity * 0.3)
        case .predator:
            return (aggression * 0.4 + camouflage * 0.4 + speed * 0.2)
        case .wind:
            return (size * 0.5 + strength * 0.3 + stickiness * 0.2)
        case .wall:
            return (memory * 0.5 + curiosity * 0.3 + strength * 0.2)
        case .food:
            return (visionRadius * 0.01 + speed * 0.3 + curiosity * 0.4)
        case .open:
            return geneticFitness
        }
    }
    
    // MARK: - Initialization
    
    /// Creates DNA with specific trait values
    init(speed: Double, visionRadius: Double, energyEfficiency: Double, 
         size: Double, strength: Double, memory: Double, stickiness: Double,
         camouflage: Double, aggression: Double, curiosity: Double,
         neuralDNA: NeuralDNA,
         colorHue: Double, colorSaturation: Double, colorBrightness: Double) {
        self.speed = max(0.1, min(2.0, speed))
        self.visionRadius = max(10, min(100, visionRadius))
        self.energyEfficiency = max(0.5, min(1.5, energyEfficiency))
        self.size = max(0.5, min(2.0, size))
        self.strength = max(0.2, min(1.5, strength))
        self.memory = max(0.1, min(1.2, memory))
        self.stickiness = max(0.3, min(1.3, stickiness))
        self.camouflage = max(0.0, min(1.0, camouflage))
        self.aggression = max(0.0, min(1.0, aggression))
        self.curiosity = max(0.0, min(1.0, curiosity))
        self.neuralDNA = neuralDNA
        self.colorHue = max(0.0, min(1.0, colorHue))
        self.colorSaturation = max(0.3, min(1.0, colorSaturation))
        self.colorBrightness = max(0.4, min(1.0, colorBrightness))
    }
    
    /// Creates random DNA for initial population
    static func random() -> BugDNA {
        return BugDNA(
            speed: Double.random(in: 0.5...1.5),
            visionRadius: Double.random(in: 20...80),
            energyEfficiency: Double.random(in: 0.7...1.3),
            size: Double.random(in: 0.7...1.3),
            strength: Double.random(in: 0.4...1.2),
            memory: Double.random(in: 0.3...1.0),
            stickiness: Double.random(in: 0.5...1.1),
            camouflage: Double.random(in: 0.1...0.9),
            aggression: Double.random(in: 0.2...0.8),
            curiosity: Double.random(in: 0.3...0.8),
            neuralDNA: NeuralDNA.random(),
            colorHue: Double.random(in: 0...1),
            colorSaturation: Double.random(in: 0.5...1.0),
            colorBrightness: Double.random(in: 0.6...1.0)
        )
    }
    
    // MARK: - Genetic Operations
    
    /// Creates offspring DNA by crossing over two parent DNAs
    static func crossover(_ parent1: BugDNA, _ parent2: BugDNA) -> BugDNA {
        // Use uniform crossover - each trait has 50% chance from each parent
        return BugDNA(
            speed: Bool.random() ? parent1.speed : parent2.speed,
            visionRadius: Bool.random() ? parent1.visionRadius : parent2.visionRadius,
            energyEfficiency: Bool.random() ? parent1.energyEfficiency : parent2.energyEfficiency,
            size: Bool.random() ? parent1.size : parent2.size,
            strength: Bool.random() ? parent1.strength : parent2.strength,
            memory: Bool.random() ? parent1.memory : parent2.memory,
            stickiness: Bool.random() ? parent1.stickiness : parent2.stickiness,
            camouflage: Bool.random() ? parent1.camouflage : parent2.camouflage,
            aggression: Bool.random() ? parent1.aggression : parent2.aggression,
            curiosity: Bool.random() ? parent1.curiosity : parent2.curiosity,
            neuralDNA: NeuralDNA.crossover(parent1.neuralDNA, parent2.neuralDNA),
            colorHue: Bool.random() ? parent1.colorHue : parent2.colorHue,
            colorSaturation: Bool.random() ? parent1.colorSaturation : parent2.colorSaturation,
            colorBrightness: Bool.random() ? parent1.colorBrightness : parent2.colorBrightness
        )
    }
    
    /// Creates a mutated version of this DNA
    func mutated(mutationRate: Double = 0.1, mutationStrength: Double = 0.15) -> BugDNA {
        func mutate(_ value: Double, range: ClosedRange<Double>) -> Double {
            if Double.random(in: 0...1) < mutationRate {
                let mutation = Double.random(in: -mutationStrength...mutationStrength)
                return max(range.lowerBound, min(range.upperBound, value + mutation))
            }
            return value
        }
        
        return BugDNA(
            speed: mutate(speed, range: 0.1...2.0),
            visionRadius: mutate(visionRadius, range: 10...100),
            energyEfficiency: mutate(energyEfficiency, range: 0.5...1.5),
            size: mutate(size, range: 0.5...2.0),
            strength: mutate(strength, range: 0.2...1.5),
            memory: mutate(memory, range: 0.1...1.2),
            stickiness: mutate(stickiness, range: 0.3...1.3),
            camouflage: mutate(camouflage, range: 0.0...1.0),
            aggression: mutate(aggression, range: 0.0...1.0),
            curiosity: mutate(curiosity, range: 0.0...1.0),
            neuralDNA: neuralDNA.mutated(mutationRate: mutationRate, mutationStrength: mutationStrength),
            colorHue: mutate(colorHue, range: 0.0...1.0),
            colorSaturation: mutate(colorSaturation, range: 0.3...1.0),
            colorBrightness: mutate(colorBrightness, range: 0.4...1.0)
        )
    }
}

// MARK: - Extensions

extension BugDNA: CustomStringConvertible {
    var description: String {
        return """
        BugDNA(
            speed: \(String(format: "%.2f", speed)),
            vision: \(String(format: "%.1f", visionRadius)),
            efficiency: \(String(format: "%.2f", energyEfficiency)),
            size: \(String(format: "%.2f", size)),
            strength: \(String(format: "%.2f", strength)),
            memory: \(String(format: "%.2f", memory)),
            stickiness: \(String(format: "%.2f", stickiness)),
            camouflage: \(String(format: "%.2f", camouflage)),
            aggression: \(String(format: "%.2f", aggression)),
            curiosity: \(String(format: "%.2f", curiosity))
        )
        """
    }
}