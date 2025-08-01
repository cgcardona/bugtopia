//
//  Species.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

/// Different species types in the ecosystem
enum SpeciesType: String, CaseIterable, Codable, Equatable, Hashable {
    case herbivore = "herbivore"
    case carnivore = "carnivore"
    case omnivore = "omnivore"
    case scavenger = "scavenger"
    
    /// Primary food source for this species
    var primaryFoodSource: FoodSource {
        switch self {
        case .herbivore:
            return .plants
        case .carnivore:
            return .prey
        case .omnivore:
            return .mixed
        case .scavenger:
            return .carrion
        }
    }
    
    /// Base color for species identification
    var baseColor: Color {
        switch self {
        case .herbivore:
            return .green
        case .carnivore:
            return .red
        case .omnivore:
            return .orange
        case .scavenger:
            return .purple
        }
    }
    
    /// Species emoji for UI
    var emoji: String {
        switch self {
        case .herbivore:
            return "🌱"
        case .carnivore:
            return "🦁"
        case .omnivore:
            return "🐻"
        case .scavenger:
            return "🦅"
        }
    }
    
    /// Can this species hunt other bugs?
    var canHunt: Bool {
        switch self {
        case .herbivore:
            return false
        case .carnivore, .omnivore:
            return true
        case .scavenger:
            return false // Only eats dead bugs
        }
    }
    
    /// Can this species eat plants/food items?
    var canEatPlants: Bool {
        switch self {
        case .herbivore, .omnivore:
            return true
        case .carnivore:
            return false
        case .scavenger:
            return true // Opportunistic
        }
    }
}

/// What different species can eat
enum FoodSource: String, CaseIterable, Equatable, Hashable {
    case plants = "plants"
    case prey = "prey"
    case mixed = "mixed"
    case carrion = "carrion"
}

/// Hunting behavior for predators
struct HuntingBehavior: Codable, Equatable, Hashable {
    /// How aggressively this bug hunts (0.0 to 1.0)
    let huntingIntensity: Double
    
    /// Maximum distance to detect prey
    let preyDetectionRange: Double
    
    /// Speed bonus when chasing prey
    let chaseSpeedMultiplier: Double
    
    /// Energy cost per hunting attempt
    let huntingEnergyCost: Double
    
    /// Stealth ability to avoid detection
    let stealthLevel: Double
    
    /// Pack hunting coordination ability
    let packCoordination: Double
    
    init(
        huntingIntensity: Double = 0.5,
        preyDetectionRange: Double = 50.0,
        chaseSpeedMultiplier: Double = 1.2,
        huntingEnergyCost: Double = 2.0,
        stealthLevel: Double = 0.3,
        packCoordination: Double = 0.1
    ) {
        self.huntingIntensity = max(0.0, min(1.0, huntingIntensity))
        self.preyDetectionRange = max(20.0, min(150.0, preyDetectionRange))
        self.chaseSpeedMultiplier = max(1.0, min(3.0, chaseSpeedMultiplier))
        self.huntingEnergyCost = max(0.5, min(5.0, huntingEnergyCost))
        self.stealthLevel = max(0.0, min(1.0, stealthLevel))
        self.packCoordination = max(0.0, min(1.0, packCoordination))
    }
    
    /// Creates random hunting behavior for evolution
    static func random() -> HuntingBehavior {
        return HuntingBehavior(
            huntingIntensity: Double.random(in: 0.2...0.9),
            preyDetectionRange: Double.random(in: 30...120),
            chaseSpeedMultiplier: Double.random(in: 1.1...2.0),
            huntingEnergyCost: Double.random(in: 1.0...3.0),
            stealthLevel: Double.random(in: 0.1...0.8),
            packCoordination: Double.random(in: 0.0...0.6)
        )
    }
    
    /// Mutates hunting behavior
    func mutated(mutationRate: Double = 0.15, mutationStrength: Double = 0.2) -> HuntingBehavior {
        func mutate(_ value: Double, range: ClosedRange<Double>) -> Double {
            if Double.random(in: 0...1) < mutationRate {
                let mutation = Double.random(in: -mutationStrength...mutationStrength)
                return max(range.lowerBound, min(range.upperBound, value + mutation))
            }
            return value
        }
        
        return HuntingBehavior(
            huntingIntensity: mutate(huntingIntensity, range: 0.0...1.0),
            preyDetectionRange: mutate(preyDetectionRange, range: 20.0...150.0),
            chaseSpeedMultiplier: mutate(chaseSpeedMultiplier, range: 1.0...3.0),
            huntingEnergyCost: mutate(huntingEnergyCost, range: 0.5...5.0),
            stealthLevel: mutate(stealthLevel, range: 0.0...1.0),
            packCoordination: mutate(packCoordination, range: 0.0...1.0)
        )
    }
    
    /// Combines two hunting behaviors through crossover
    static func crossover(_ parent1: HuntingBehavior, _ parent2: HuntingBehavior) -> HuntingBehavior {
        return HuntingBehavior(
            huntingIntensity: Bool.random() ? parent1.huntingIntensity : parent2.huntingIntensity,
            preyDetectionRange: Bool.random() ? parent1.preyDetectionRange : parent2.preyDetectionRange,
            chaseSpeedMultiplier: Bool.random() ? parent1.chaseSpeedMultiplier : parent2.chaseSpeedMultiplier,
            huntingEnergyCost: Bool.random() ? parent1.huntingEnergyCost : parent2.huntingEnergyCost,
            stealthLevel: Bool.random() ? parent1.stealthLevel : parent2.stealthLevel,
            packCoordination: Bool.random() ? parent1.packCoordination : parent2.packCoordination
        )
    }
}

/// Defensive behavior for prey
struct DefensiveBehavior: Codable, Equatable, Hashable {
    /// How quickly this bug detects predators (0.0 to 1.0)
    let predatorDetection: Double
    
    /// Speed bonus when fleeing from predators
    let fleeSpeedMultiplier: Double
    
    /// How far to maintain distance from predators
    let fleeDistance: Double
    
    /// Energy cost of panic/flee response
    let fleeEnergyCost: Double
    
    /// Ability to hide/camouflage when threatened
    let hidingSkill: Double
    
    /// Tendency to group together for safety
    let flockingTendency: Double
    
    /// Ability to fight back when cornered
    let counterAttackSkill: Double
    
    init(
        predatorDetection: Double = 0.5,
        fleeSpeedMultiplier: Double = 1.3,
        fleeDistance: Double = 60.0,
        fleeEnergyCost: Double = 1.5,
        hidingSkill: Double = 0.3,
        flockingTendency: Double = 0.4,
        counterAttackSkill: Double = 0.1
    ) {
        self.predatorDetection = max(0.0, min(1.0, predatorDetection))
        self.fleeSpeedMultiplier = max(1.0, min(3.0, fleeSpeedMultiplier))
        self.fleeDistance = max(30.0, min(200.0, fleeDistance))
        self.fleeEnergyCost = max(0.5, min(4.0, fleeEnergyCost))
        self.hidingSkill = max(0.0, min(1.0, hidingSkill))
        self.flockingTendency = max(0.0, min(1.0, flockingTendency))
        self.counterAttackSkill = max(0.0, min(1.0, counterAttackSkill))
    }
    
    /// Creates random defensive behavior for evolution
    static func random() -> DefensiveBehavior {
        return DefensiveBehavior(
            predatorDetection: Double.random(in: 0.2...0.9),
            fleeSpeedMultiplier: Double.random(in: 1.1...2.5),
            fleeDistance: Double.random(in: 40...150),
            fleeEnergyCost: Double.random(in: 1.0...3.0),
            hidingSkill: Double.random(in: 0.0...0.8),
            flockingTendency: Double.random(in: 0.1...0.8),
            counterAttackSkill: Double.random(in: 0.0...0.5)
        )
    }
    
    /// Mutates defensive behavior
    func mutated(mutationRate: Double = 0.15, mutationStrength: Double = 0.2) -> DefensiveBehavior {
        func mutate(_ value: Double, range: ClosedRange<Double>) -> Double {
            if Double.random(in: 0...1) < mutationRate {
                let mutation = Double.random(in: -mutationStrength...mutationStrength)
                return max(range.lowerBound, min(range.upperBound, value + mutation))
            }
            return value
        }
        
        return DefensiveBehavior(
            predatorDetection: mutate(predatorDetection, range: 0.0...1.0),
            fleeSpeedMultiplier: mutate(fleeSpeedMultiplier, range: 1.0...3.0),
            fleeDistance: mutate(fleeDistance, range: 30.0...200.0),
            fleeEnergyCost: mutate(fleeEnergyCost, range: 0.5...4.0),
            hidingSkill: mutate(hidingSkill, range: 0.0...1.0),
            flockingTendency: mutate(flockingTendency, range: 0.0...1.0),
            counterAttackSkill: mutate(counterAttackSkill, range: 0.0...1.0)
        )
    }
    
    /// Combines two defensive behaviors through crossover
    static func crossover(_ parent1: DefensiveBehavior, _ parent2: DefensiveBehavior) -> DefensiveBehavior {
        return DefensiveBehavior(
            predatorDetection: Bool.random() ? parent1.predatorDetection : parent2.predatorDetection,
            fleeSpeedMultiplier: Bool.random() ? parent1.fleeSpeedMultiplier : parent2.fleeSpeedMultiplier,
            fleeDistance: Bool.random() ? parent1.fleeDistance : parent2.fleeDistance,
            fleeEnergyCost: Bool.random() ? parent1.fleeEnergyCost : parent2.fleeEnergyCost,
            hidingSkill: Bool.random() ? parent1.hidingSkill : parent2.hidingSkill,
            flockingTendency: Bool.random() ? parent1.flockingTendency : parent2.flockingTendency,
            counterAttackSkill: Bool.random() ? parent1.counterAttackSkill : parent2.counterAttackSkill
        )
    }
}

/// Complete species definition with ecological behaviors
struct SpeciesTraits: Codable, Equatable, Hashable {
    let speciesType: SpeciesType
    let huntingBehavior: HuntingBehavior?
    let defensiveBehavior: DefensiveBehavior?
    
    /// Energy gained from successful hunt
    let huntEnergyGain: Double
    
    /// Energy gained from eating plants
    let plantEnergyGain: Double
    
    /// Base metabolic rate modifier for this species
    let metabolicRate: Double
    
    /// Size modifier affecting hunting success and detection
    let sizeModifier: Double
    
    init(
        speciesType: SpeciesType,
        huntingBehavior: HuntingBehavior? = nil,
        defensiveBehavior: DefensiveBehavior? = nil,
        huntEnergyGain: Double = 40.0,
        plantEnergyGain: Double = 25.0,
        metabolicRate: Double = 1.0,
        sizeModifier: Double = 1.0
    ) {
        self.speciesType = speciesType
        self.huntingBehavior = huntingBehavior
        self.defensiveBehavior = defensiveBehavior
        self.huntEnergyGain = max(10.0, min(80.0, huntEnergyGain))
        self.plantEnergyGain = max(5.0, min(50.0, plantEnergyGain))
        self.metabolicRate = max(0.5, min(2.0, metabolicRate))
        self.sizeModifier = max(0.5, min(3.0, sizeModifier))
    }
    
    /// Creates species traits for a specific type
    static func forSpecies(_ type: SpeciesType) -> SpeciesTraits {
        switch type {
        case .herbivore:
            return SpeciesTraits(
                speciesType: .herbivore,
                huntingBehavior: nil,
                defensiveBehavior: DefensiveBehavior.random(),
                huntEnergyGain: 0.0,
                plantEnergyGain: Double.random(in: 20...35),
                metabolicRate: Double.random(in: 0.8...1.1),
                sizeModifier: Double.random(in: 0.7...1.2)
            )
            
        case .carnivore:
            return SpeciesTraits(
                speciesType: .carnivore,
                huntingBehavior: HuntingBehavior.random(),
                defensiveBehavior: DefensiveBehavior.random(),
                huntEnergyGain: Double.random(in: 35...60),
                plantEnergyGain: 0.0,
                metabolicRate: Double.random(in: 1.1...1.4),
                sizeModifier: Double.random(in: 1.2...2.0)
            )
            
        case .omnivore:
            return SpeciesTraits(
                speciesType: .omnivore,
                huntingBehavior: HuntingBehavior.random(),
                defensiveBehavior: DefensiveBehavior.random(),
                huntEnergyGain: Double.random(in: 25...45),
                plantEnergyGain: Double.random(in: 15...30),
                metabolicRate: Double.random(in: 0.9...1.2),
                sizeModifier: Double.random(in: 0.9...1.5)
            )
            
        case .scavenger:
            return SpeciesTraits(
                speciesType: .scavenger,
                huntingBehavior: nil,
                defensiveBehavior: DefensiveBehavior.random(),
                huntEnergyGain: Double.random(in: 20...40), // From carrion
                plantEnergyGain: Double.random(in: 10...25),
                metabolicRate: Double.random(in: 0.7...1.0),
                sizeModifier: Double.random(in: 0.8...1.3)
            )
        }
    }
    
    /// Mutates species traits
    func mutated(mutationRate: Double = 0.1, mutationStrength: Double = 0.15) -> SpeciesTraits {
        func mutate(_ value: Double, range: ClosedRange<Double>) -> Double {
            if Double.random(in: 0...1) < mutationRate {
                let mutation = Double.random(in: -mutationStrength...mutationStrength)
                return max(range.lowerBound, min(range.upperBound, value + mutation))
            }
            return value
        }
        
        return SpeciesTraits(
            speciesType: speciesType,
            huntingBehavior: huntingBehavior?.mutated(mutationRate: mutationRate, mutationStrength: mutationStrength),
            defensiveBehavior: defensiveBehavior?.mutated(mutationRate: mutationRate, mutationStrength: mutationStrength),
            huntEnergyGain: mutate(huntEnergyGain, range: 10.0...80.0),
            plantEnergyGain: mutate(plantEnergyGain, range: 5.0...50.0),
            metabolicRate: mutate(metabolicRate, range: 0.5...2.0),
            sizeModifier: mutate(sizeModifier, range: 0.5...3.0)
        )
    }
    
    /// Combines two species traits through crossover (within same species)
    static func crossover(_ parent1: SpeciesTraits, _ parent2: SpeciesTraits) -> SpeciesTraits {
        // Only crossover within same species type
        guard parent1.speciesType == parent2.speciesType else {
            return parent1 // Return first parent if different species
        }
        
        var newHuntingBehavior: HuntingBehavior? = nil
        if let hunt1 = parent1.huntingBehavior, let hunt2 = parent2.huntingBehavior {
            newHuntingBehavior = HuntingBehavior.crossover(hunt1, hunt2)
        } else {
            newHuntingBehavior = parent1.huntingBehavior ?? parent2.huntingBehavior
        }
        
        var newDefensiveBehavior: DefensiveBehavior? = nil
        if let def1 = parent1.defensiveBehavior, let def2 = parent2.defensiveBehavior {
            newDefensiveBehavior = DefensiveBehavior.crossover(def1, def2)
        } else {
            newDefensiveBehavior = parent1.defensiveBehavior ?? parent2.defensiveBehavior
        }
        
        return SpeciesTraits(
            speciesType: parent1.speciesType,
            huntingBehavior: newHuntingBehavior,
            defensiveBehavior: newDefensiveBehavior,
            huntEnergyGain: Bool.random() ? parent1.huntEnergyGain : parent2.huntEnergyGain,
            plantEnergyGain: Bool.random() ? parent1.plantEnergyGain : parent2.plantEnergyGain,
            metabolicRate: Bool.random() ? parent1.metabolicRate : parent2.metabolicRate,
            sizeModifier: Bool.random() ? parent1.sizeModifier : parent2.sizeModifier
        )
    }
}