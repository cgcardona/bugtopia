//
//  TerritoryUI.swift
//  Bugtopia
//
//  Created by Assistant on 8/1/25.
//

import SwiftUI

/// Displays territory information for the selected population
struct TerritoryStatusView: View {
    let territoryManager: TerritoryManager
    let speciationManager: SpeciationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.orange)
                Text("Territory Control")
                    .font(.headline)
            }
            
            if territoryManager.territories.isEmpty {
                Text("No claimed territories yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(territoryManager.territories) { territory in
                    VStack(alignment: .leading) {
                        Text(populationName(for: territory.populationId))
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(populationColor(for: territory.populationId))
                        
                        StatRow(label: "Quality", value: String(format: "%.2f", territory.quality))
                        StatRow(label: "Area", value: "\(Int(territory.area.width))x\(Int(territory.area.height))")
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func populationName(for id: UUID) -> String {
        return speciationManager.populations.first { $0.id == id }?.name ?? "Unknown Population"
    }
    
    private func populationColor(for id: UUID) -> Color {
        if let pop = speciationManager.populations.first(where: { $0.id == id }) {
            return Color(hue: pop.specializationTendencies.averageTraits.avgColorHue, saturation: 1.0, brightness: 1.0)
        }
        return .gray
    }
}

/// Draws population territories on the simulation canvas
struct TerritoryOverlay: View {
    let territoryManager: TerritoryManager
    let speciationManager: SpeciationManager
    let canvasSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            for territory in territoryManager.territories {
                let rect = CGRect(
                    x: territory.area.minX * (size.width / 800.0),
                    y: territory.area.minY * (size.height / 600.0),
                    width: territory.area.width * (size.width / 800.0),
                    height: territory.area.height * (size.height / 600.0)
                )
                
                let territoryColor = populationColor(for: territory.populationId)
                
                context.fill(Path(rect), with: .color(territoryColor.opacity(0.15)))
                context.stroke(Path(rect), with: .color(territoryColor.opacity(0.4)), lineWidth: 1.5)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func populationColor(for id: UUID) -> Color {
        if let pop = speciationManager.populations.first(where: { $0.id == id }) {
            return Color(hue: pop.specializationTendencies.averageTraits.avgColorHue, saturation: 1.0, brightness: 1.0)
        }
        return .gray
    }
}
