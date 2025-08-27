//
//  Communication.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation
import SwiftUI

// MARK: - Signal System

/// Types of signals bugs can emit and receive
enum SignalType: String, CaseIterable, Codable, Equatable, Hashable {
    case foodFound = "food_found"           // "I found food here!"
    case dangerAlert = "danger_alert"       // "Predator nearby!"
    case huntCall = "hunt_call"             // "Join me in hunting!"
    case mateCall = "mate_call"             // "Looking for a mate"
    case territoryMark = "territory_mark"   // "This is my territory"
    case helpRequest = "help_request"       // "I need assistance"
    case groupForm = "group_form"           // "Let's form a group"
    case retreat = "retreat"                // "Everyone scatter!"
    case foodShare = "food_share"           // "I'm sharing food with the group!"
    
    /// Visual representation for debugging
    var emoji: String {
        switch self {
        case .foodFound: return "🍃"
        case .dangerAlert: return "⚠️"
        case .huntCall: return "🎯"
        case .mateCall: return "💕"
        case .territoryMark: return "🏴"
        case .helpRequest: return "🆘"
        case .groupForm: return "🤝"
        case .retreat: return "🏃"
        case .foodShare: return "🍯"
        }
    }
    
    /// Signal strength/priority (higher = more urgent)
    var priority: Double {
        switch self {
        case .retreat, .dangerAlert: return 1.0        // Highest priority
        case .helpRequest, .huntCall: return 0.8       // High priority
        case .foodFound, .groupForm, .foodShare: return 0.6        // Medium priority
        case .mateCall, .territoryMark: return 0.4     // Lower priority
        }
    }
}

/// A signal emitted by a bug
struct Signal: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let type: SignalType
    let position: CGPoint      // Where the signal was emitted
    let emitterId: UUID        // Who sent it
    let strength: Double       // Signal intensity (0.0 to 1.0)
    let timestamp: TimeInterval // When it was created
    let data: SignalData?      // Additional context
    
    /// How far this signal can travel
    var range: Double {
        return strength * 100.0 // Base range multiplied by strength
    }
    
    /// Signal fades over time
    func currentStrength(at time: TimeInterval) -> Double {
        let age = time - timestamp
        let maxAge: TimeInterval = 5.0 // Signals last 5 seconds
        let decay = max(0.0, (maxAge - age) / maxAge)
        return strength * decay
    }
    
    /// Whether signal is still active
    func isActive(at time: TimeInterval) -> Bool {
        return currentStrength(at: time) > 0.1
    }
}

/// Additional data that can be attached to signals
struct SignalData: Codable, Equatable, Hashable {
    let foodPosition: Position3D?   // For food_found and food_share signals
    let threatId: UUID?             // For danger_alert signals
    let huntTargetId: UUID?         // For hunt_call signals
    let energyLevel: Double?        // For help_request and food_share signals
    let groupSize: Int?             // For group_form signals
    
    init(foodPosition: Position3D? = nil, 
         threatId: UUID? = nil, 
         huntTargetId: UUID? = nil, 
         energyLevel: Double? = nil, 
         groupSize: Int? = nil) {
        self.foodPosition = foodPosition
        self.threatId = threatId
        self.huntTargetId = huntTargetId
        self.energyLevel = energyLevel
        self.groupSize = groupSize
    }
}

// MARK: - Communication Abilities

/// Communication traits that evolve in bugs
struct CommunicationDNA: Codable, Equatable, Hashable {
    /// How far this bug can send signals (0.0 to 1.0)
    let signalStrength: Double
    
    /// How well this bug can detect incoming signals (0.0 to 1.0) 
    let signalSensitivity: Double
    
    /// How often this bug sends signals (0.0 to 1.0)
    let communicationFrequency: Double
    
    /// How much this bug trusts signals from others (0.0 to 1.0)
    let signalTrust: Double
    
    /// How likely to respond to group calls (0.0 to 1.0)
    let socialResponseRate: Double
    
    /// How long this bug remembers received signals in ticks
    let signalMemory: Int
    
    // MARK: - Generation
    
    static func random() -> CommunicationDNA {
        return CommunicationDNA(
            signalStrength: Double.random(in: 0.1...1.0),
            signalSensitivity: Double.random(in: 0.1...1.0),
            communicationFrequency: Double.random(in: 0.0...1.0),
            signalTrust: Double.random(in: 0.2...0.9),
            socialResponseRate: Double.random(in: 0.0...1.0),
            signalMemory: Int.random(in: 30...300) // 1-10 seconds at 30 FPS
        )
    }
    
    // MARK: - Genetic Operations
    
    func mutated(mutationRate: Double = 0.1, mutationStrength: Double = 0.2) -> CommunicationDNA {
        return CommunicationDNA(
            signalStrength: mutateValue(signalStrength, rate: mutationRate, strength: mutationStrength),
            signalSensitivity: mutateValue(signalSensitivity, rate: mutationRate, strength: mutationStrength),
            communicationFrequency: mutateValue(communicationFrequency, rate: mutationRate, strength: mutationStrength),
            signalTrust: mutateValue(signalTrust, rate: mutationRate, strength: mutationStrength, min: 0.1, max: 1.0),
            socialResponseRate: mutateValue(socialResponseRate, rate: mutationRate, strength: mutationStrength),
            signalMemory: Int(mutateValue(Double(signalMemory), rate: mutationRate, strength: mutationStrength * 50, min: 30, max: 300))
        )
    }
    
    static func crossover(parent1: CommunicationDNA, parent2: CommunicationDNA) -> CommunicationDNA {
        return CommunicationDNA(
            signalStrength: Double.random(in: 0...1) < 0.5 ? parent1.signalStrength : parent2.signalStrength,
            signalSensitivity: Double.random(in: 0...1) < 0.5 ? parent1.signalSensitivity : parent2.signalSensitivity,
            communicationFrequency: Double.random(in: 0...1) < 0.5 ? parent1.communicationFrequency : parent2.communicationFrequency,
            signalTrust: Double.random(in: 0...1) < 0.5 ? parent1.signalTrust : parent2.signalTrust,
            socialResponseRate: Double.random(in: 0...1) < 0.5 ? parent1.socialResponseRate : parent2.socialResponseRate,
            signalMemory: Double.random(in: 0...1) < 0.5 ? parent1.signalMemory : parent2.signalMemory
        )
    }
    
    // MARK: - Helper
    
    private func mutateValue(_ value: Double, rate: Double, strength: Double, min: Double = 0.0, max: Double = 1.0) -> Double {
        guard Double.random(in: 0...1) < rate else { return value }
        let mutation = Double.random(in: -strength...strength)
        return Swift.max(min, Swift.min(max, value + mutation))
    }
}

// MARK: - Group Behaviors

/// A group of bugs working together
struct BugGroup: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    var members: Set<UUID>          // Bug IDs in this group
    var leader: UUID?               // Current group leader
    var formation: GroupFormation   // How the group moves
    var objective: GroupObjective   // What the group is trying to do
    var territory: CGRect?          // Group's claimed territory
    var lastActivity: TimeInterval  // When group last did something
    
    /// Whether this group is still active
    func isActive(at time: TimeInterval) -> Bool {
        let maxInactivity: TimeInterval = 10.0 // Groups dissolve after 10 seconds of inactivity
        return (time - lastActivity) < maxInactivity && members.count > 1
    }
}

/// How groups arrange themselves spatially
enum GroupFormation: String, CaseIterable, Codable, Equatable, Hashable {
    case cluster = "cluster"        // Tight formation
    case line = "line"              // Line formation
    case circle = "circle"          // Circular formation
    case wedge = "wedge"            // V-shaped formation
    case scatter = "scatter"        // Loose formation
}

/// What groups are trying to accomplish
enum GroupObjective: String, CaseIterable, Codable, Equatable, Hashable {
    case hunt = "hunt"              // Coordinate hunting
    case forage = "forage"          // Search for food together
    case defend = "defend"          // Protect territory
    case migrate = "migrate"        // Move to new area
    case reproduce = "reproduce"    // Coordinate mating
    case explore = "explore"        // Scout new territories
}

// MARK: - Extensions

extension Signal {
    /// Calculate distance from signal origin to a point
    func distance(to point: CGPoint) -> Double {
        let dx = position.x - point.x
        let dy = position.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Whether a bug at given position can receive this signal
    func canReach(position: CGPoint, at time: TimeInterval) -> Bool {
        let currentStr = currentStrength(at: time)
        let dist = distance(to: position)
        return currentStr > 0.1 && dist <= (currentStr * 100.0)
    }
}