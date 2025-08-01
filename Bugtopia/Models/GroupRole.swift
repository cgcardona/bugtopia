//
//  GroupRole.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import Foundation

/// Roles that bugs can take within groups
enum GroupRole: String, CaseIterable, Codable, Equatable, Hashable {
    case leader = "leader"           // Leads the group, makes decisions
    case member = "member"           // Regular group member
    case scout = "scout"            // Explores ahead, sends signals
    case guardian = "guardian"       // Protects the group
    case forager = "forager"        // Specializes in finding food
    case hunter = "hunter"          // Leads hunting expeditions
    
    /// Emoji representation for debugging
    var emoji: String {
        switch self {
        case .leader: return "👑"
        case .member: return "🐛" 
        case .scout: return "🔍"
        case .guardian: return "🛡️"
        case .forager: return "🌾"
        case .hunter: return "🎯"
        }
    }
    
    /// Priority level (higher = more important role)
    var priority: Double {
        switch self {
        case .leader: return 1.0
        case .guardian, .hunter: return 0.8
        case .scout, .forager: return 0.6
        case .member: return 0.4
        }
    }
}