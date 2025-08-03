//
//  FoodItem.swift
//  Bugtopia
//
//  Created by Claude on 8/2/25.
//

import Foundation
import SwiftUI

/// Represents different types of food with varying energy values, colors, and rarity
struct FoodItem: Identifiable, Equatable {
    let id = UUID()
    let position: CGPoint
    let type: FoodType
    let energyValue: Double
    let targetSpecies: SpeciesType
    
    /// Creates a food item at the specified position
    init(position: CGPoint, type: FoodType, targetSpecies: SpeciesType) {
        self.position = position
        self.type = type
        self.energyValue = type.energyValue
        self.targetSpecies = targetSpecies
    }
    
    static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Different food types with their properties
enum FoodType: String, CaseIterable {
    // Herbivore Foods
    case plum = "plum"
    case apple = "apple" 
    case orange = "orange"
    case melon = "melon"
    
    // Future: Carnivore Foods (for expansion)
    case meat = "meat"
    case fish = "fish"
    
    // Future: Omnivore Foods
    case seeds = "seeds"
    case nuts = "nuts"
    
    /// Energy value this food provides
    var energyValue: Double {
        switch self {
        // Herbivore foods
        case .plum: return 25.0     // Base energy (common)
        case .apple: return 30.0    // 2x multiplier 
        case .orange: return 40.0   // 5x multiplier (rare)
        case .melon: return 60.0    // 10x multiplier (rare)
        
        // Carnivore foods (future)
        case .meat: return 45.0
        case .fish: return 35.0
        
        // Omnivore foods (future)
        case .seeds: return 20.0
        case .nuts: return 25.0
        }
    }
    
    /// Visual color for this food type
    var color: Color {
        switch self {
        case .plum: return Color.purple
        case .apple: return Color.red
        case .orange: return Color.orange
        case .melon: return Color.green
        case .meat: return Color.brown
        case .fish: return Color.blue
        case .seeds: return Color.yellow
        case .nuts: return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown
        }
    }
    
    /// Rarity level affecting spawn chance
    var rarity: FoodRarity {
        switch self {
        case .plum, .apple: return .common      // 70% of spawns
        case .orange, .melon: return .rare      // 30% of spawns
        case .meat, .fish: return .common       // For carnivores
        case .seeds, .nuts: return .common      // For omnivores
        }
    }
    
    /// Which species types can eat this food
    var compatibleSpecies: [SpeciesType] {
        switch self {
        case .plum, .apple, .orange, .melon:
            return [.herbivore, .omnivore]
        case .meat, .fish:
            return [.carnivore, .omnivore]
        case .seeds, .nuts:
            return [.omnivore] // Could be eaten by all but optimized for omnivores
        }
    }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .plum: return "Plum"
        case .apple: return "Apple"
        case .orange: return "Orange"
        case .melon: return "Melon"
        case .meat: return "Meat"
        case .fish: return "Fish"
        case .seeds: return "Seeds"
        case .nuts: return "Nuts"
        }
    }
}

/// Food rarity levels affecting spawn frequency
enum FoodRarity: String, CaseIterable {
    case common = "common"      // 70% spawn chance
    case rare = "rare"          // 30% spawn chance
    case legendary = "legendary" // 5% spawn chance (future)
    
    /// Spawn probability for this rarity level
    var spawnChance: Double {
        switch self {
        case .common: return 0.7
        case .rare: return 0.3
        case .legendary: return 0.05
        }
    }
}

/// Helper for generating food based on species and rarity
extension FoodType {
    /// Returns all food types suitable for a given species
    static func foodsFor(species: SpeciesType) -> [FoodType] {
        return FoodType.allCases.filter { foodType in
            foodType.compatibleSpecies.contains(species)
        }
    }
    
    /// Generates a random food type for a species based on rarity weights
    static func randomFoodFor(species: SpeciesType) -> FoodType {
        let availableFoods = foodsFor(species: species)
        
        // Create weighted selection based on rarity
        let commonFoods = availableFoods.filter { $0.rarity == .common }
        let rareFoods = availableFoods.filter { $0.rarity == .rare }
        
        let random = Double.random(in: 0...1)
        
        if random < 0.7 && !commonFoods.isEmpty {
            // 70% chance for common foods
            return commonFoods.randomElement()!
        } else if !rareFoods.isEmpty {
            // 30% chance for rare foods
            return rareFoods.randomElement()!
        } else {
            // Fallback to any available food
            return availableFoods.randomElement() ?? .plum
        }
    }
}