//
//  WeatherUI.swift
//  Bugtopia
//
//  UI components for displaying weather patterns and effects
//

import SwiftUI

/// Main weather status display
struct WeatherStatusView: View {
    let weatherManager: WeatherManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current weather header
            HStack {
                Text(weatherManager.currentWeather.emoji)
                    .font(.title2)
                Text(weatherManager.currentWeather.name)
                    .font(.headline)
                    .foregroundColor(weatherManager.currentWeather.color)
                Spacer()
                Text("Intensity: \(Int(weatherManager.weatherIntensity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Weather progress bar
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: weatherManager.weatherProgress)
                    .accentColor(weatherManager.currentWeather.color)
                    .frame(height: 6)
                
                Text("\(weatherManager.weatherDuration) ticks until weather change")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
            
            Divider()
            
            // Weather effects
            Text("Environmental Effects")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            let effects = weatherManager.currentEffects
            VStack(alignment: .leading, spacing: 2) {
                WeatherEffectRow(
                    icon: "🏃‍♂️",
                    label: "Movement Speed",
                    value: formatMultiplier(effects.movementSpeedModifier)
                )
                WeatherEffectRow(
                    icon: "👁️",
                    label: "Vision Range", 
                    value: formatMultiplier(effects.visionRangeModifier)
                )
                WeatherEffectRow(
                    icon: "⚡",
                    label: "Energy Drain",
                    value: formatMultiplier(effects.energyDrainModifier)
                )
                WeatherEffectRow(
                    icon: "🍎",
                    label: "Food Spawn Rate",
                    value: formatMultiplier(effects.foodSpawnRateModifier)
                )
                WeatherEffectRow(
                    icon: "🔧",
                    label: "Construction Speed",
                    value: formatMultiplier(effects.constructionSpeedModifier)
                )
            }
            
            Divider()
            
            // Survival advice
            Text("Survival Strategy")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(effects.behaviorRecommendation)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Recent weather events
            if !weatherManager.recentWeatherEvents.isEmpty {
                Divider()
                
                Text("Recent Weather Events")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(weatherManager.recentWeatherEvents.suffix(3), id: \.id) { event in
                    WeatherEventRow(event: event)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatMultiplier(_ value: Double) -> String {
        let percentage = Int(value * 100)
        if percentage == 100 {
            return "Normal"
        } else if percentage > 100 {
            return "+\(percentage - 100)%"
        } else {
            return "-\(100 - percentage)%"
        }
    }
}

/// Individual weather effect row display
struct WeatherEffectRow: View {
    let icon: String
    let label: String  
    let value: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.caption)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

/// Weather event history row
struct WeatherEventRow: View {
    let event: WeatherEvent
    
    var body: some View {
        HStack {
            Text(event.type.emoji)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(event.type.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(relativeTimeString(from: event.startTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if event.isActive {
                Text("Active")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(event.type.color.opacity(0.2))
                    .foregroundColor(event.type.color)
                    .cornerRadius(4)
            } else {
                Text("Past")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let elapsed = Date().timeIntervalSince(date)
        
        if elapsed < 60 {
            return "Just now"
        } else if elapsed < 3600 {
            let minutes = Int(elapsed / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(elapsed / 3600)
            return "\(hours)h ago"
        }
    }
}

/// Compact weather indicator for toolbar/header
struct WeatherIndicator: View {
    let weatherManager: WeatherManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text(weatherManager.currentWeather.emoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(weatherManager.currentWeather.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(weatherManager.currentWeather.color)
                
                Text("\(Int(weatherManager.weatherIntensity * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Weather visualization overlay for the simulation canvas
struct WeatherOverlay: View {
    let weatherManager: WeatherManager
    let canvasSize: CGSize
    
    var body: some View {
        ZStack {
            // Weather-specific visual effects
            switch weatherManager.currentWeather {
            case .rain:
                RainEffect(intensity: weatherManager.weatherIntensity, canvasSize: canvasSize)
                
            case .blizzard:
                SnowEffect(intensity: weatherManager.weatherIntensity, canvasSize: canvasSize)
                
            case .fog:
                FogEffect(intensity: weatherManager.weatherIntensity)
                
            case .storm:
                StormEffect(intensity: weatherManager.weatherIntensity, canvasSize: canvasSize)
                
            case .drought:
                HeatShimmerEffect(intensity: weatherManager.weatherIntensity)
                
            case .clear:
                EmptyView()
            }
        }
        .allowsHitTesting(false) // Let touches pass through to simulation
    }
}

/// Rain particle effect
struct RainEffect: View {
    let intensity: Double
    let canvasSize: CGSize
    @State private var animationPhase: Double = 0
    
    var body: some View {
        ZStack {
            // Rain overlay tint
            Rectangle()
                .fill(Color.blue.opacity(0.1 * intensity))
            
            // Animated rain drops
            ForEach(0..<Int(50 * intensity), id: \.self) { _ in
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 1, height: 10)
                    .position(
                        x: Double.random(in: 0...canvasSize.width),
                        y: Double.random(in: -100...canvasSize.height) + animationPhase * 200
                    )
            }
        }
        .onAppear {
            // 🔧 FIXED: Defer state modifications to prevent warnings during view updates
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    animationPhase = 1.0
                }
            }
        }
    }
}

/// Snow particle effect  
struct SnowEffect: View {
    let intensity: Double
    let canvasSize: CGSize
    @State private var animationPhase: Double = 0
    
    var body: some View {
        ZStack {
            // Blizzard overlay
            Rectangle()
                .fill(Color.white.opacity(0.3 * intensity))
            
            // Animated snow
            ForEach(0..<Int(100 * intensity), id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: 3)
                    .position(
                        x: Double.random(in: 0...canvasSize.width) + sin(animationPhase * 2) * 20,
                        y: Double.random(in: -50...canvasSize.height) + animationPhase * 150
                    )
            }
        }
        .onAppear {
            // 🔧 FIXED: Defer state modifications to prevent warnings during view updates
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    animationPhase = 1.0
                }
            }
        }
    }
}

/// Fog overlay effect
struct FogEffect: View {
    let intensity: Double
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.4 * intensity),
                        Color.gray.opacity(0.2 * intensity),
                        Color.gray.opacity(0.3 * intensity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

/// Storm lightning effect
struct StormEffect: View {
    let intensity: Double
    let canvasSize: CGSize
    @State private var showLightning = false
    
    var body: some View {
        ZStack {
            // Storm clouds
            Rectangle()
                .fill(Color.purple.opacity(0.2 * intensity))
            
            // Lightning flashes
            if showLightning {
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .animation(.easeInOut(duration: 0.1), value: showLightning)
            }
        }
        .onReceive(Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()) { _ in
            // 🔧 FIXED: Defer state modifications to prevent warnings during view updates
            DispatchQueue.main.async {
                if Double.random(in: 0...1) < intensity {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        showLightning = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.1)) {
                            showLightning = false
                        }
                    }
                }
            }
        }
    }
}

/// Heat shimmer effect for drought
struct HeatShimmerEffect: View {
    let intensity: Double
    @State private var shimmerPhase: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.1 * intensity),
                        Color.yellow.opacity(0.05 * intensity),
                        Color.red.opacity(0.08 * intensity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(1.0 + 0.01 * intensity * sin(shimmerPhase))
            .onAppear {
                // 🔧 FIXED: Defer state modifications to prevent warnings during view updates
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        shimmerPhase = .pi * 2
                    }
                }
            }
    }
}