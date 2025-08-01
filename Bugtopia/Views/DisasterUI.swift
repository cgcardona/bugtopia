//
//  DisasterUI.swift
//  Bugtopia
//
//  UI components for displaying natural disasters and their effects
//

import SwiftUI

/// Small indicator for active disasters
struct DisasterIndicator: View {
    var disasterManager: DisasterManager
    
    var body: some View {
        HStack(spacing: 4) {
            if disasterManager.activeDisasters.isEmpty {
                Text("🌿")
                    .font(.title2)
                Text("Peaceful")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                let primaryDisaster = disasterManager.activeDisasters.first!
                Text(primaryDisaster.type.icon)
                    .font(.title2)
                Text(primaryDisaster.type.name)
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(disasterManager.activeDisasters.isEmpty ? Color.green.opacity(0.2) : Color.red.opacity(0.2)))
        .cornerRadius(10)
    }
}

/// Detailed view for current disasters and their effects
struct DisasterStatusView: View {
    var disasterManager: DisasterManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🌋 Natural Disasters")
                    .font(.headline)
                Spacer()
            }
            
            if disasterManager.activeDisasters.isEmpty {
                HStack {
                    Text("🌿")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("All Clear")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("No active disasters. Bugs can thrive safely.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.1)))
            } else {
                ForEach(disasterManager.activeDisasters, id: \.id) { disaster in
                    DisasterEventView(disaster: disaster)
                }
            }
            
            Divider()
            
            // Recent disasters
            if !disasterManager.recentDisasters.isEmpty {
                Text("Recent Events:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(disasterManager.recentDisasters.suffix(3), id: \.id) { disaster in
                    HStack {
                        Text(disaster.type.icon)
                            .font(.caption)
                        Text("\(disaster.type.name) - Intensity: \(String(format: "%.1f", disaster.intensity))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            // Survival tips
            Text("Survival Guide:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if disasterManager.activeDisasters.isEmpty {
                Text("Peaceful times are perfect for reproduction and exploration!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                let tips = getSurvivalTips(for: disasterManager.activeDisasters)
                ForEach(tips, id: \.self) { tip in
                    Text("• \(tip)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))
    }
    
    private func getSurvivalTips(for disasters: [DisasterEvent]) -> [String] {
        var tips: [String] = []
        
        for disaster in disasters {
            switch disaster.type {
            case .flood:
                tips.append("Stay on high ground and conserve energy for swimming")
            case .earthquake:
                tips.append("Brace for displacement and avoid unstable terrain")
            case .wildfire:
                tips.append("Flee quickly before the fire spreads - visibility is low")
            case .volcanic:
                tips.append("Avoid toxic ash clouds and lava flows")
            }
        }
        
        if tips.isEmpty {
            tips.append("Multiple disasters active - extreme caution advised!")
        }
        
        return tips
    }
}

/// Individual disaster event display
struct DisasterEventView: View {
    let disaster: DisasterEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(disaster.type.icon)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(disaster.type.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Intensity: \(String(format: "%.1f", disaster.intensity)) • Radius: \(Int(disaster.currentRadius))px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Text(disaster.type.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Disaster Progress Bar
            VStack(alignment: .leading, spacing: 2) {
                Text("Event Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: disaster.progress)
                    .accentColor(disasterColor(for: disaster.type))
                    .frame(height: 4)
                
                Text("\(disaster.duration - disaster.ticksActive) ticks remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
            
            // Effects summary
            let effects = disaster.currentEffects
            HStack {
                DisasterEffectChip(
                    icon: "🏃‍♂️",
                    effect: formatModifier(effects.movementSpeedModifier)
                )
                DisasterEffectChip(
                    icon: "👁️",
                    effect: formatModifier(effects.visionRangeModifier)
                )
                DisasterEffectChip(
                    icon: "⚡",
                    effect: formatModifier(effects.energyDrainModifier)
                )
                if effects.directDamage > 0 {
                    DisasterEffectChip(
                        icon: "💀",
                        effect: String(format: "%.1f", effects.directDamage)
                    )
                }
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(disasterColor(for: disaster.type).opacity(0.1)))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(disasterColor(for: disaster.type).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func disasterColor(for type: DisasterType) -> Color {
        switch type {
        case .flood: return .blue
        case .earthquake: return .brown
        case .wildfire: return .red
        case .volcanic: return .orange
        }
    }
    
    private func formatModifier(_ value: Double) -> String {
        let percentage = Int((value - 1.0) * 100)
        if percentage > 0 {
            return "+\(percentage)%"
        } else if percentage < 0 {
            return "\(percentage)%"
        } else {
            return "±0%"
        }
    }
}

/// Small effect indicator chip
struct DisasterEffectChip: View {
    let icon: String
    let effect: String
    
    var body: some View {
        HStack(spacing: 2) {
            Text(icon)
                .font(.caption2)
            Text(effect)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.gray.opacity(0.2)))
    }
}

/// Visual overlay for disaster effects on the canvas
struct DisasterOverlay: View {
    var disasterManager: DisasterManager
    let canvasSize: CGSize
    
    var body: some View {
        ForEach(disasterManager.activeDisasters, id: \.id) { disaster in
            DisasterEffectOverlay(disaster: disaster, canvasSize: canvasSize)
        }
    }
}

/// Individual disaster visual effect
struct DisasterEffectOverlay: View {
    let disaster: DisasterEvent
    let canvasSize: CGSize
    
    var body: some View {
        ZStack {
            // Disaster radius indicator
            Circle()
                .stroke(disasterColor(for: disaster.type).opacity(0.3), lineWidth: 2)
                .frame(width: disaster.currentRadius * 2, height: disaster.currentRadius * 2)
                .position(x: disaster.epicenter.x, y: disaster.epicenter.y)
            
            // Disaster-specific effects
            switch disaster.type {
            case .flood:
                FloodEffectView(disaster: disaster, canvasSize: canvasSize)
            case .earthquake:
                EarthquakeEffectView(disaster: disaster, canvasSize: canvasSize)
            case .wildfire:
                FireEffectView(disaster: disaster, canvasSize: canvasSize)
            case .volcanic:
                VolcanicEffectView(disaster: disaster, canvasSize: canvasSize)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func disasterColor(for type: DisasterType) -> Color {
        switch type {
        case .flood: return .blue
        case .earthquake: return .brown
        case .wildfire: return .red
        case .volcanic: return .orange
        }
    }
}

// MARK: - Disaster Effect Views

struct FloodEffectView: View {
    let disaster: DisasterEvent
    let canvasSize: CGSize
    @State private var waveOffset: Double = 0
    
    var body: some View {
        // Rippling water effect
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.blue.opacity(0.3),
                        Color.blue.opacity(0.1)
                    ],
                    center: .center,
                    startRadius: disaster.currentRadius * 0.3,
                    endRadius: disaster.currentRadius
                )
            )
            .frame(width: disaster.currentRadius * 2, height: disaster.currentRadius * 2)
            .position(x: disaster.epicenter.x, y: disaster.epicenter.y)
            .scaleEffect(1.0 + sin(waveOffset) * 0.1)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    waveOffset = .pi * 2
                }
            }
    }
}

struct EarthquakeEffectView: View {
    let disaster: DisasterEvent
    let canvasSize: CGSize
    @State private var shakeOffset: CGPoint = .zero
    
    var body: some View {
        // Shaking effect with crack lines
        ZStack {
            // Crack lines radiating from epicenter
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * .pi / 4
                let endX = disaster.epicenter.x + cos(angle) * disaster.currentRadius
                let endY = disaster.epicenter.y + sin(angle) * disaster.currentRadius
                
                Path { path in
                    path.move(to: disaster.epicenter)
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(Color.brown.opacity(0.4), lineWidth: 2)
            }
        }
        .offset(x: shakeOffset.x, y: shakeOffset.y)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                let intensity = disaster.intensityAt(disaster.epicenter) * 5
                shakeOffset = CGPoint(
                    x: Double.random(in: -intensity...intensity),
                    y: Double.random(in: -intensity...intensity)
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    shakeOffset = .zero
                }
            }
        }
    }
}

struct FireEffectView: View {
    let disaster: DisasterEvent
    let canvasSize: CGSize
    @State private var fireAnimation: Double = 0
    
    var body: some View {
        // Spreading fire effect
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.red.opacity(0.6),
                        Color.orange.opacity(0.4),
                        Color.yellow.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: disaster.currentRadius
                )
            )
            .frame(width: disaster.currentRadius * 2, height: disaster.currentRadius * 2)
            .position(x: disaster.epicenter.x, y: disaster.epicenter.y)
            .scaleEffect(0.8 + sin(fireAnimation) * 0.2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    fireAnimation = .pi
                }
            }
    }
}

struct VolcanicEffectView: View {
    let disaster: DisasterEvent
    let canvasSize: CGSize
    @State private var ashAnimation: Double = 0
    
    var body: some View {
        ZStack {
            // Lava flow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.red.opacity(0.8),
                            Color.orange.opacity(0.5),
                            Color.gray.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: disaster.currentRadius * 0.7
                    )
                )
                .frame(width: disaster.currentRadius * 1.4, height: disaster.currentRadius * 1.4)
                .position(x: disaster.epicenter.x, y: disaster.epicenter.y)
            
            // Ash cloud
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: disaster.currentRadius * 2.5, height: disaster.currentRadius * 2.5)
                .position(x: disaster.epicenter.x, y: disaster.epicenter.y - disaster.currentRadius * 0.3)
                .scaleEffect(0.8 + sin(ashAnimation) * 0.3)
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                ashAnimation = .pi * 2
            }
        }
    }
}