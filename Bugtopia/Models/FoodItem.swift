//
//  FoodItem.swift
//  Bugtopia
//
//  Created by Claude on 8/2/25.
//

import Foundation
import SwiftUI

/// Represents different types of food with varying energy values, colors, and rarity
struct FoodItem: Identifiable, Codable, Hashable, Equatable {
    let id = UUID()
    let position: Position3D
    let type: FoodType
    let energyValue: Double
    let targetSpecies: SpeciesType
    
    /// Creates a food item at the specified position
    init(position: Position3D, type: FoodType, targetSpecies: SpeciesType) {
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
enum FoodType: String, CaseIterable, Codable, Hashable {
    // Herbivore Foods
    case plum = "plum"
    case apple = "apple" 
    case orange = "orange"
    case melon = "melon"
    case blackberry = "blackberry"
    
    // Carnivore Foods
    case tuna = "tuna"
    case mediumSteak = "mediumSteak"
    case rawFlesh = "rawFlesh"
    case rawSteak = "rawSteak"
    case grilledSteak = "grilledSteak"
    
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
        case .blackberry: return 35.0  // Sweet berries (common)
        
        // Carnivore foods
        case .tuna: return 25.0  // High protein fish
        case .mediumSteak: return 55.0  // Premium cooked steak
        case .rawFlesh: return 40.0  // Raw meat - high protein but uncooked
        case .rawSteak: return 50.0  // Raw steak - premium cut, high protein
        case .grilledSteak: return 60.0  // Grilled steak - perfectly cooked, highest energy
        
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
        case .blackberry: return Color.black
        case .tuna: return Color(red: 0.8, green: 0.4, blue: 0.4) // Pinkish tuna color
        case .mediumSteak: return Color(red: 0.7, green: 0.3, blue: 0.2) // Medium-rare steak color
        case .rawFlesh: return Color(red: 0.9, green: 0.2, blue: 0.2) // Deep red raw flesh
        case .rawSteak: return Color(red: 0.8, green: 0.2, blue: 0.2) // Raw steak color
        case .grilledSteak: return Color(red: 0.6, green: 0.3, blue: 0.2) // Grilled steak color
        case .seeds: return Color.yellow
        case .nuts: return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown
        }
    }
    
    /// Rarity level affecting spawn chance
    var rarity: FoodRarity {
        switch self {
        case .plum, .apple, .blackberry: return .common      // 70% of spawns
        case .orange, .melon: return .rare      // 30% of spawns
        case .tuna, .mediumSteak, .rawFlesh, .rawSteak, .grilledSteak: return .common       // For carnivores
        case .seeds, .nuts: return .common      // For omnivores
        }
    }
    
    /// Which species types can eat this food
    var compatibleSpecies: [SpeciesType] {
        switch self {
        case .plum, .apple, .orange, .melon, .blackberry:
            return [.herbivore, .omnivore]
        case .tuna, .mediumSteak, .rawFlesh, .rawSteak, .grilledSteak:
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
        case .blackberry: return "Blackberry"
        case .tuna: return "Tuna"
        case .mediumSteak: return "Medium Steak"
        case .rawFlesh: return "Raw Flesh"
        case .rawSteak: return "Raw Steak"
        case .grilledSteak: return "Grilled Steak"
        case .seeds: return "Seeds"
        case .nuts: return "Nuts"
        }
    }
    
    /// Preferred biomes where this food naturally occurs
    var preferredBiomes: [BiomeType] {
        switch self {
        case .plum: return [.temperateForest, .borealForest]
        case .apple: return [.temperateForest, .temperateGrassland]
        case .orange: return [.tropicalRainforest, .savanna]
        case .melon: return [.temperateGrassland, .savanna]
        case .blackberry: return [.temperateForest, .borealForest, .temperateGrassland]
        case .tuna: return [.coastal] // Deep ocean fish
        case .mediumSteak: return [.temperateGrassland, .savanna] // Premium cooked meat
        case .rawFlesh: return [.tundra, .savanna, .desert] // Scavenged from harsh environments
        case .rawSteak: return [.temperateGrassland, .savanna] // Premium raw cut
        case .grilledSteak: return [.temperateGrassland, .savanna] // Premium grilled cuisine
        case .seeds: return [.temperateGrassland, .desert, .savanna]
        case .nuts: return [.temperateForest, .borealForest, .tropicalRainforest]
        }
    }
    
    /// Preferred seasons when this food is most abundant
    var preferredSeasons: [Season] {
        switch self {
        case .plum: return [.summer, .fall] // Fruit ripening time
        case .apple: return [.fall] // Classic harvest season
        case .orange: return [.winter, .spring] // Citrus season
        case .melon: return [.summer] // Peak summer fruit
        case .blackberry: return [.summer, .fall] // Berry season
        case .tuna: return [.summer, .fall] // Peak tuna season
        case .mediumSteak: return [.fall, .winter] // Premium cooking season
        case .rawFlesh: return [.winter, .spring] // Scavenging season
        case .rawSteak: return [.fall, .winter] // Premium hunting season
        case .grilledSteak: return [.summer, .fall] // Grilling season
        case .seeds: return [.fall] // Seed collection time
        case .nuts: return [.fall] // Nut gathering season
        }
    }
}

/// Food rarity levels affecting spawn frequency
enum FoodRarity: String, CaseIterable, Codable, Hashable {
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
        // 🎆 ORGANIC FOOD DIVERSITY: Natural distribution across all 8 food types!
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
    
    /// Randomly selects biome-appropriate food for a species type
    static func randomFoodFor(species: SpeciesType, biome: BiomeType) -> FoodType {
        // 🌍 BIOME-AWARE FOOD: Natural distribution based on ecosystem
        let compatibleFoods = foodsFor(species: species)
        let biomeFoods = compatibleFoods.filter { $0.preferredBiomes.contains(biome) }
        
        // If biome has preferred foods, use them with low probability for maximum variety
        if !biomeFoods.isEmpty && Double.random(in: 0...1) < 0.15 {
            return randomFoodFromList(biomeFoods)
        }
        
        // Otherwise, fall back to any compatible food
        return randomFoodFor(species: species)
    }
    
    /// Randomly selects seasonal food for a species type
    static func randomFoodFor(species: SpeciesType, season: Season) -> FoodType {
        // 🍂 SEASONAL FOOD: Dynamic distribution based on time of year
        let compatibleFoods = foodsFor(species: species)
        let seasonalFoods = compatibleFoods.filter { $0.preferredSeasons.contains(season) }
        
        // If season has preferred foods, use them with low probability for maximum variety
        if !seasonalFoods.isEmpty && Double.random(in: 0...1) < 0.15 {
            return randomFoodFromList(seasonalFoods)
        }
        
        // Otherwise, fall back to any compatible food
        return randomFoodFor(species: species)
    }
    
    /// Randomly selects biome and season appropriate food for a species type
    static func randomFoodFor(species: SpeciesType, biome: BiomeType, season: Season) -> FoodType {
        // 🌟 ECOSYSTEM MASTERY: All 8 food types with photorealistic PBR materials!
        /* AAA TESTING HISTORY - All food types successfully tested:
        ✅ .plum    - Photorealistic plum with stem indent and natural asymmetry
        ✅ .apple   - Natural apple shape with waist tapering and stem indentation
        ✅ .orange  - Citrus segments with surface texture and realistic proportions
        ✅ .melon   - Netted cantaloupe surface with ridge patterns and oblate shape
        ✅ .meat    - Organic chunky meat with marbling detail and irregular surface
        ✅ .fish    - Streamlined aquatic shape with fin ridges and metallic scales
        ✅ .seeds   - Clustered seed arrangement with surface bumps and asymmetry
        ✅ .nuts    - Mixed nut shells with cracks, ridges, and natural variation
        */
        
        let compatibleFoods = foodsFor(species: species)
        let biomeFoods = compatibleFoods.filter { $0.preferredBiomes.contains(biome) }
        let seasonalFoods = compatibleFoods.filter { $0.preferredSeasons.contains(season) }
        
        // Perfect match: both biome and season (MUCH reduced probability for maximum variety)
        let perfectMatch = biomeFoods.filter { seasonalFoods.contains($0) }
        if !perfectMatch.isEmpty && Double.random(in: 0...1) < 0.15 {
            return randomFoodFromList(perfectMatch)
        }
        
        // Good match: biome preferred (MUCH reduced probability)
        if !biomeFoods.isEmpty && Double.random(in: 0...1) < 0.10 {
            return randomFoodFromList(biomeFoods)
        }
        
        // Decent match: season preferred (MUCH reduced probability)
        if !seasonalFoods.isEmpty && Double.random(in: 0...1) < 0.05 {
            return randomFoodFromList(seasonalFoods)
        }
        
        // Fallback to any compatible food
        return randomFoodFor(species: species)
    }
    
    /// Helper to select random food from list with rarity weighting
    private static func randomFoodFromList(_ foods: [FoodType]) -> FoodType {
        // 🎲 NATURAL SELECTION: Rarity-weighted food distribution
        guard !foods.isEmpty else { return .plum }
        
        let commonFoods = foods.filter { $0.rarity == .common }
        let rareFoods = foods.filter { $0.rarity == .rare }
        
        let random = Double.random(in: 0...1)
        
        if random < 0.7 && !commonFoods.isEmpty {
            return commonFoods.randomElement()!
        } else if !rareFoods.isEmpty {
            return rareFoods.randomElement()!
        } else {
            return foods.randomElement() ?? .plum
        }
    }
}