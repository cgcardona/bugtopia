//
//  SeasonalUI.swift
//  Bugtopia
//
//  Created by AI Assistant on Phase 6 Implementation
//

import SwiftUI

/// UI components for displaying seasonal information
struct SeasonalStatusView: View {
    let seasonalManager: SeasonalManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current season header
            HStack {
                Text(seasonalManager.currentSeason.emoji)
                    .font(.title2)
                Text(seasonalManager.currentSeason.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(seasonalManager.currentSeason.color)
            }
            
            // Season progress bar
            VStack(alignment: .leading, spacing: 4) {
                Text("Season Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: seasonalManager.seasonProgress)
                    .accentColor(seasonalManager.currentSeason.color)
                    .frame(height: 6)
                
                Text("\(seasonalManager.ticksUntilNextSeason) ticks until \(seasonalManager.currentSeason.next.emoji) \(seasonalManager.currentSeason.next.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Year counter
            Text("Year \(seasonalManager.yearCount + 1)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Seasonal effects
            VStack(alignment: .leading, spacing: 4) {
                Text("Environmental Effects")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                EffectRow(
                    icon: "🍎",
                    label: "Food Abundance",
                    value: String(format: "%.1fx", seasonalManager.currentSeason.foodAbundance)
                )
                
                EffectRow(
                    icon: "💨",
                    label: "Movement Speed",
                    value: String(format: "%.1fx", seasonalManager.currentSeason.movementModifier)
                )
                
                EffectRow(
                    icon: "⚡",
                    label: "Energy Drain",
                    value: String(format: "%.1fx", seasonalManager.currentSeason.energyDrainModifier)
                )
                
                EffectRow(
                    icon: "💕",
                    label: "Reproduction",
                    value: String(format: "%.1fx", seasonalManager.currentSeason.reproductionModifier)
                )
                
                EffectRow(
                    icon: "🔧",
                    label: "Construction",
                    value: String(format: "%.1fx", seasonalManager.currentSeason.constructionModifier)
                )
            }
            
            // Behavioral suggestions
            VStack(alignment: .leading, spacing: 4) {
                Text("Seasonal Behaviors")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if seasonalManager.isBreedingSeason {
                    BehaviorChip(icon: "💕", text: "Breeding Season", color: .pink)
                }
                
                if seasonalManager.isHoardingSeason {
                    BehaviorChip(icon: "📦", text: "Hoarding Time", color: .orange)
                }
                
                if seasonalManager.isShelterSeason {
                    BehaviorChip(icon: "🏠", text: "Seek Shelter", color: .blue)
                }
                
                if seasonalManager.isExpansionSeason {
                    BehaviorChip(icon: "🚀", text: "Expand & Build", color: .green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EffectRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.caption)
                .frame(width: 20, alignment: .leading)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct BehaviorChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}
