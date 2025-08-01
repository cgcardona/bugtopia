//
//  EcosystemUI.swift
//  Bugtopia
//
//  Created by Assistant on 8/1/25.
//

import SwiftUI

/// Shows ecosystem health and resource status
struct EcosystemStatusView: View {
    let ecosystemManager: EcosystemManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Ecosystem Health")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Resource Health
            VStack(alignment: .leading, spacing: 8) {
                Text("Resource Availability")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    ProgressView(value: ecosystemManager.globalResourceHealth)
                        .progressViewStyle(LinearProgressViewStyle(tint: resourceHealthColor))
                        .frame(height: 6)
                    
                    Text("\(Int(ecosystemManager.globalResourceHealth * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
                
                Text(resourceHealthDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Population Pressure
            VStack(alignment: .leading, spacing: 8) {
                Text("Population Pressure")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    ProgressView(value: min(1.0, ecosystemManager.averagePopulationPressure / 10.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: populationPressureColor))
                        .frame(height: 6)
                    
                    Text("\(String(format: "%.1f", ecosystemManager.averagePopulationPressure))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
                
                Text(populationPressureDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Carrying Capacity
            VStack(alignment: .leading, spacing: 8) {
                Text("Carrying Capacity")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    ProgressView(value: min(1.0, ecosystemManager.carryingCapacityUtilization))
                        .progressViewStyle(LinearProgressViewStyle(tint: carryingCapacityColor))
                        .frame(height: 6)
                    
                    Text("\(Int(ecosystemManager.carryingCapacityUtilization * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
                
                Text(carryingCapacityDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Ecosystem Age
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Ecosystem Age: \(ecosystemManager.ecosystemAge) generations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Ecosystem Status Alert
            if ecosystemManager.isEcosystemStressed {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("Ecosystem under stress!")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var resourceHealthColor: Color {
        let health = ecosystemManager.globalResourceHealth
        if health > 0.7 { return .green }
        if health > 0.4 { return .yellow }
        return .red
    }
    
    private var resourceHealthDescription: String {
        let health = ecosystemManager.globalResourceHealth
        if health > 0.8 { return "Abundant resources" }
        if health > 0.6 { return "Good resource availability" }
        if health > 0.4 { return "Moderate resource scarcity" }
        if health > 0.2 { return "Severe resource depletion" }
        return "Critical resource shortage"
    }
    
    private var populationPressureColor: Color {
        let pressure = ecosystemManager.averagePopulationPressure
        if pressure < 3.0 { return .green }
        if pressure < 6.0 { return .yellow }
        return .red
    }
    
    private var populationPressureDescription: String {
        let pressure = ecosystemManager.averagePopulationPressure
        if pressure < 2.0 { return "Low density, plenty of space" }
        if pressure < 5.0 { return "Moderate population density" }
        if pressure < 8.0 { return "High density, competition increasing" }
        return "Overcrowded, intense competition"
    }
    
    private var carryingCapacityColor: Color {
        let utilization = ecosystemManager.carryingCapacityUtilization
        if utilization < 0.7 { return .green }
        if utilization < 1.0 { return .yellow }
        return .red
    }
    
    private var carryingCapacityDescription: String {
        let utilization = ecosystemManager.carryingCapacityUtilization
        if utilization < 0.6 { return "Well below capacity" }
        if utilization < 0.8 { return "Approaching capacity" }
        if utilization < 1.0 { return "Near carrying capacity" }
        if utilization < 1.2 { return "Over capacity, stress increasing" }
        return "Severely overcrowded"
    }
}

/// Mini ecosystem indicator for top bar
struct EcosystemIndicator: View {
    let ecosystemManager: EcosystemManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: ecosystemManager.isEcosystemStressed ? "leaf.fill" : "leaf")
                .foregroundColor(ecosystemManager.isEcosystemStressed ? .red : .green)
                .font(.system(size: 14, weight: .medium))
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Ecosystem")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(ecosystemStatusText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(ecosystemManager.isEcosystemStressed ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        )
    }
    
    private var ecosystemStatusText: String {
        if ecosystemManager.isEcosystemStressed {
            return "Stressed"
        }
        
        let health = ecosystemManager.globalResourceHealth
        if health > 0.8 { return "Thriving" }
        if health > 0.6 { return "Healthy" }
        if health > 0.4 { return "Stable" }
        return "Declining"
    }
}

/// Visual overlay showing resource zones and their health
struct EcosystemOverlay: View {
    let ecosystemManager: EcosystemManager
    let canvasSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Draw resource zones if ecosystem is stressed (to help visualize the problem)
            if ecosystemManager.isEcosystemStressed {
                for zone in ecosystemManager.resourceZones {
                    let centerX = zone.position.x * (size.width / 800.0)
                    let centerY = zone.position.y * (size.height / 600.0)
                    let radius = zone.radius * min(size.width / 800.0, size.height / 600.0)
                    
                    let center = CGPoint(x: centerX, y: centerY)
                    let circle = Path(ellipseIn: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                    
                    // Color based on zone health
                    let alpha = zone.health > 0.5 ? 0.1 : 0.2
                    let color = zone.health > 0.7 ? Color.green : 
                               zone.health > 0.4 ? Color.yellow : Color.red
                    
                    context.fill(circle, with: .color(color.opacity(alpha)))
                    context.stroke(circle, with: .color(color.opacity(0.3)), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#if DEBUG
struct EcosystemUI_Previews: PreviewProvider {
    static var previews: some View {
        let mockEcosystem = EcosystemManager()
        
        VStack {
            EcosystemIndicator(ecosystemManager: mockEcosystem)
            EcosystemStatusView(ecosystemManager: mockEcosystem)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif