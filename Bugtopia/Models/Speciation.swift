//
//  Speciation.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

// MARK: - Speciation System

/// Represents a distinct population group that may become a separate species
struct Population: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let name: String                    // Species name (e.g., "Aquatic Builders", "Hill Hunters")  
    let foundingGeneration: Int         // When this population was established
    var currentGeneration: Int          // Current generation count
    var bugIds: Set<UUID>               // Bugs belonging to this population
    var territories: Set<CGPoint>       // Preferred habitat locations
    var specializationTendencies: SpecializationProfile
    
    /// Geographic center of this population
    var centroid: CGPoint {
        guard !territories.isEmpty else { return CGPoint.zero }
        let totalX = territories.reduce(0.0) { $0 + $1.x }
        let totalY = territories.reduce(0.0) { $0 + $1.y }
        return CGPoint(x: totalX / Double(territories.count), y: totalY / Double(territories.count))
    }
    
    /// Population size
    var size: Int {
        return bugIds.count
    }
    
    /// Age of this population in generations
    var age: Int {
        return currentGeneration - foundingGeneration
    }
    
    /// Whether this population is large enough to be considered a stable species
    var isViableSpecies: Bool {
        return size >= 5 && age >= 2 // Much more reasonable requirements
    }
    
    /// Add a bug to this population
    mutating func addBug(_ bugId: UUID, at location: CGPoint) {
        bugIds.insert(bugId)
        territories.insert(location)
    }
    
    /// Remove a bug from this population
    mutating func removeBug(_ bugId: UUID) {
        bugIds.remove(bugId)
    }
    
    /// Update territories based on current bug locations
    mutating func updateTerritories(bugLocations: [UUID: CGPoint]) {
        territories.removeAll()
        for bugId in bugIds {
            if let location = bugLocations[bugId] {
                territories.insert(location)
            }
        }
    }
}

/// Tracks specialization tendencies of a population
struct SpecializationProfile: Codable, Equatable, Hashable {
    // Ecological specializations
    var terrainPreference: [TerrainType: Double] = [:]
    var averageTraits: SpeciesAverages
    var behavioralTendencies: BehavioralProfile
    
    /// Initialize with default values
    init() {
        self.averageTraits = SpeciesAverages()
        self.behavioralTendencies = BehavioralProfile()
        
        // Initialize terrain preferences
        for terrain in TerrainType.allCases {
            terrainPreference[terrain] = 0.1 // Start with low preference for all
        }
    }
    
    /// Update specialization based on population's bugs
    mutating func updateFromBugs(_ bugs: [Bug]) {
        guard !bugs.isEmpty else { return }
        
        // Calculate average traits
        averageTraits.updateFromBugs(bugs)
        
        // Update behavioral tendencies
        behavioralTendencies.updateFromBugs(bugs)
        
        // Update terrain preferences based on where bugs spend time
        // This would be tracked over time in a real implementation
    }
    
    /// Calculate genetic distance from another population
    func geneticDistance(to other: SpecializationProfile) -> Double {
        let traitDistance = averageTraits.distance(to: other.averageTraits)
        let behavioralDistance = behavioralTendencies.distance(to: other.behavioralTendencies)
        return (traitDistance + behavioralDistance) / 2.0
    }
}

/// Average genetic traits for a population
struct SpeciesAverages: Codable, Equatable, Hashable {
    var speed: Double = 0.0
    var visionRadius: Double = 0.0
    var energyEfficiency: Double = 0.0
    var size: Double = 0.0
    var strength: Double = 0.0
    var memory: Double = 0.0
    var stickiness: Double = 0.0
    var camouflage: Double = 0.0
    var aggression: Double = 0.0
    var curiosity: Double = 0.0
    
    // Tool traits
    var toolCrafting: Double = 0.0
    var toolProficiency: Double = 0.0
    var constructionDrive: Double = 0.0
    
    // Communication traits
    var signalStrength: Double = 0.0
    var socialResponseRate: Double = 0.0
    var avgColorHue: Double = 0.0
    
    /// Update averages from a collection of bugs
    mutating func updateFromBugs(_ bugs: [Bug]) {
        guard !bugs.isEmpty else { return }
        let count = Double(bugs.count)
        
        speed = bugs.map { $0.dna.speed }.reduce(0, +) / count
        visionRadius = bugs.map { $0.dna.visionRadius }.reduce(0, +) / count
        energyEfficiency = bugs.map { $0.dna.energyEfficiency }.reduce(0, +) / count
        size = bugs.map { $0.dna.size }.reduce(0, +) / count
        strength = bugs.map { $0.dna.strength }.reduce(0, +) / count
        memory = bugs.map { $0.dna.memory }.reduce(0, +) / count
        stickiness = bugs.map { $0.dna.stickiness }.reduce(0, +) / count
        camouflage = bugs.map { $0.dna.camouflage }.reduce(0, +) / count
        aggression = bugs.map { $0.dna.aggression }.reduce(0, +) / count
        curiosity = bugs.map { $0.dna.curiosity }.reduce(0, +) / count
        
        toolCrafting = bugs.map { $0.dna.toolDNA.toolCrafting }.reduce(0, +) / count
        toolProficiency = bugs.map { $0.dna.toolDNA.toolProficiency }.reduce(0, +) / count
        constructionDrive = bugs.map { $0.dna.toolDNA.constructionDrive }.reduce(0, +) / count
        
        signalStrength = bugs.map { $0.dna.communicationDNA.signalStrength }.reduce(0, +) / count
        socialResponseRate = bugs.map { $0.dna.communicationDNA.socialResponseRate }.reduce(0, +) / count
        avgColorHue = bugs.map { $0.dna.colorHue }.reduce(0, +) / count
    }
    
    /// Calculate genetic distance to another population
    func distance(to other: SpeciesAverages) -> Double {
        let differences = [
            abs(speed - other.speed),
            abs(visionRadius - other.visionRadius) / 100.0, // Scale vision to 0-1 range
            abs(energyEfficiency - other.energyEfficiency),
            abs(size - other.size),
            abs(strength - other.strength),
            abs(memory - other.memory),
            abs(stickiness - other.stickiness),
            abs(camouflage - other.camouflage),
            abs(aggression - other.aggression),
            abs(curiosity - other.curiosity),
            abs(toolCrafting - other.toolCrafting),
            abs(toolProficiency - other.toolProficiency),
            abs(constructionDrive - other.constructionDrive),
            abs(signalStrength - other.signalStrength),
            abs(socialResponseRate - other.socialResponseRate)
        ]
        
        return differences.reduce(0, +) / Double(differences.count)
    }
}

/// Behavioral tendencies of a population
struct BehavioralProfile: Codable, Equatable, Hashable {
    var huntingFrequency: Double = 0.0      // How often they hunt
    var constructionActivity: Double = 0.0   // How much they build
    var socialCohesion: Double = 0.0         // How much they group together
    var explorationDrive: Double = 0.0       // How much they explore vs stay put
    var reproductionRate: Double = 0.0       // How frequently they reproduce
    
    /// Update from bugs
    mutating func updateFromBugs(_ bugs: [Bug]) {
        guard !bugs.isEmpty else { return }
        let count = Double(bugs.count)
        
        // These would be tracked over time in a full implementation
        // For now, estimate from genetic traits
        huntingFrequency = Double(bugs.filter { $0.dna.speciesTraits.speciesType.canHunt }.count) / count
        constructionActivity = bugs.map { $0.dna.toolDNA.constructionDrive }.reduce(0, +) / count
        socialCohesion = bugs.map { $0.dna.communicationDNA.socialResponseRate }.reduce(0, +) / count
        explorationDrive = bugs.map { $0.dna.curiosity }.reduce(0, +) / count
        reproductionRate = 0.5 // Would be tracked empirically
    }
    
    /// Calculate behavioral distance to another population
    func distance(to other: BehavioralProfile) -> Double {
        let differences = [
            abs(huntingFrequency - other.huntingFrequency),
            abs(constructionActivity - other.constructionActivity),
            abs(socialCohesion - other.socialCohesion),
            abs(explorationDrive - other.explorationDrive),
            abs(reproductionRate - other.reproductionRate)
        ]
        
        return differences.reduce(0, +) / Double(differences.count)
    }
}

// MARK: - Speciation Events

/// Types of speciation events that can occur
enum SpeciationEvent: Codable, Equatable, Hashable {
    case populationSplit(parentId: UUID, offspring1Id: UUID, offspring2Id: UUID)
    case migration(populationId: UUID, fromTerritory: CGPoint, toTerritory: CGPoint)
    case extinction(populationId: UUID, cause: ExtinctionCause)
    case hybridization(population1Id: UUID, population2Id: UUID, hybridId: UUID)
    case isolation(populationId: UUID, isolationType: IsolationType)
    
    /// Human-readable description
    var description: String {
        switch self {
        case .populationSplit(_, _, _):
            return "Population split into two groups"
        case .migration(_, let from, let to):
            return "Population migrated from (\(Int(from.x)), \(Int(from.y))) to (\(Int(to.x)), \(Int(to.y)))"
        case .extinction(_, let cause):
            return "Population extinct: \(cause.description)"
        case .hybridization(_, _, _):
            return "Two populations hybridized"
        case .isolation(_, let type):
            return "Population isolated: \(type.description)"
        }
    }
}

/// Causes of population extinction
enum ExtinctionCause: String, Codable, Equatable, Hashable, CaseIterable {
    case smallPopulation = "population too small"
    case resourceDepletion = "resource depletion"
    case predation = "excessive predation"
    case environmentalChange = "environmental change"
    case geneticBottleneck = "genetic bottleneck"
    
    var description: String {
        return rawValue
    }
}

/// Types of reproductive isolation
enum IsolationType: String, Codable, Equatable, Hashable, CaseIterable {
    case geographic = "geographic separation"
    case behavioral = "behavioral differences"
    case temporal = "different breeding times"
    case genetic = "genetic incompatibility"
    
    var description: String {
        return rawValue
    }
}

// MARK: - Reproductive Compatibility

/// Calculates reproductive compatibility between two bugs
struct ReproductiveCompatibility {
    
    /// Calculate compatibility score between two bugs (0.0 = incompatible, 1.0 = fully compatible)
    static func compatibility(between bug1: Bug, and bug2: Bug, populations: [Population]) -> Double {
        // Same population = high compatibility
        if let pop1 = populations.first(where: { $0.bugIds.contains(bug1.id) }),
           let pop2 = populations.first(where: { $0.bugIds.contains(bug2.id) }),
           pop1.id == pop2.id {
            return 0.95 // Very high but not perfect to allow for some variation
        }
        
        // Calculate genetic distance
        let geneticDistance = calculateGeneticDistance(bug1.dna, bug2.dna)
        
        // Calculate geographic distance
        let geographicDistance = bug1.distance(to: bug2.position)
        let maxDistance = 200.0 // Maximum meaningful distance
        let geographicFactor = max(0.0, 1.0 - (geographicDistance / maxDistance))
        
        // Calculate species compatibility  
        let speciesCompatibility = bug1.dna.speciesTraits.speciesType == bug2.dna.speciesTraits.speciesType ? 1.0 : 0.3
        
        // Combined compatibility score
        let geneticCompatibility = max(0.0, 1.0 - geneticDistance)
        
        return (geneticCompatibility * 0.5 + geographicFactor * 0.2 + speciesCompatibility * 0.3)
    }
    
    /// Calculate genetic distance between two DNA profiles
    private static func calculateGeneticDistance(_ dna1: BugDNA, _ dna2: BugDNA) -> Double {
        let traitDifferences = [
            abs(dna1.speed - dna2.speed),
            abs(dna1.visionRadius - dna2.visionRadius) / 100.0,
            abs(dna1.energyEfficiency - dna2.energyEfficiency),
            abs(dna1.size - dna2.size),
            abs(dna1.strength - dna2.strength),
            abs(dna1.memory - dna2.memory),
            abs(dna1.stickiness - dna2.stickiness),
            abs(dna1.camouflage - dna2.camouflage),
            abs(dna1.aggression - dna2.aggression),
            abs(dna1.curiosity - dna2.curiosity),
        ]
        
        return traitDifferences.reduce(0, +) / Double(traitDifferences.count)
    }
}

// MARK: - Population Naming

/// Generates interesting names for populations based on their characteristics
struct PopulationNamer {
    
    private static let terrainAdjectives: [TerrainType: [String]] = [
        .water: ["Aquatic", "Marine", "Tidal", "Flowing", "Deep"],
        .hill: ["Mountain", "Highland", "Peak", "Ridge", "Alpine"],
        .wall: ["Cliff", "Stone", "Rocky", "Fortress", "Boulder"],
        .shadow: ["Shadow", "Dark", "Shade", "Twilight", "Hidden"],
        .predator: ["Danger", "Wild", "Fierce", "Savage", "Battle"],
        .wind: ["Storm", "Gale", "Swift", "Windy", "Soaring"],
        .food: ["Garden", "Fertile", "Abundant", "Harvest", "Plenty"],
        .open: ["Plains", "Open", "Free", "Wandering", "Vast"]
    ]
    
    private static let behaviorAdjectives = [
        // Based on species type
        "Hunter", "Grazer", "Scavenger", "Omnivore",
        // Based on tool use
        "Builder", "Crafter", "Engineer", "Architect", "Constructor",
        // Based on social behavior
        "Pack", "Solitary", "Social", "Cooperative", "Tribal",
        // Based on general traits
        "Swift", "Strong", "Clever", "Stealthy", "Brave", "Curious"
    ]
    
    private static let creatureNouns = [
        "Bugs", "Crawlers", "Runners", "Seekers", "Builders", "Hunters",
        "Wanderers", "Scouts", "Workers", "Guardians", "Explorers", "Survivors"
    ]
    
    /// Generate a name for a population based on their specialization
    static func generateName(for population: Population, dominantTerrain: TerrainType?) -> String {
        var components: [String] = []
        
        // Add terrain-based adjective
        if let terrain = dominantTerrain,
           let adjectives = terrainAdjectives[terrain] {
            components.append(adjectives.randomElement() ?? "Wild")
        }
        
        // Add behavior-based adjective
        components.append(behaviorAdjectives.randomElement() ?? "Adaptive")
        
        // Add creature noun
        let noun = creatureNouns.randomElement() ?? "Species"
        components.append(noun)
        
        return components.joined(separator: " ")
    }
}