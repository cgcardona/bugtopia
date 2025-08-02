//
//  SimulationView.swift
//  Bugtopia
//
//  Created by Assistant on 8/1/25.
//

import SwiftUI

/// Wrapper class to manage SimulationEngine lifecycle properly with SwiftUI
class SimulationEngineManager: ObservableObject {
    @Published var engine: SimulationEngine
    
    // Lazy initialization ensures Arena3DView is created only once when first accessed
    lazy var arena3DView: Arena3DView = {
        print("🔍 DEBUG: Creating single Arena3DView instance (lazy)")
        return Arena3DView(simulationEngine: engine)
    }()
    
    init(worldSize: CGSize = CGSize(width: 800, height: 600)) {
        print("🔍 DEBUG: SimulationEngineManager.init() called - creating SimulationEngine")
        let bounds = CGRect(origin: .zero, size: worldSize)
        self.engine = SimulationEngine(worldBounds: bounds)
        print("🔍 DEBUG: SimulationEngineManager.init() completed")
    }
}

/// Main view for displaying and controlling the evolutionary simulation
struct SimulationView: View {
    
    @StateObject private var engineManager = SimulationEngineManager()
    @State private var showingStatistics = true
    @State private var selectedBug: Bug?
    // Only VoxelWorld rendering - 2D and Arena3D rendering paths removed
    
    private var simulationEngine: SimulationEngine {
        engineManager.engine
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Control Panel
                controlPanel
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                
                HStack(spacing: 0) {
                    // Left Statistics Panel
                    if showingStatistics {
                        leftStatisticsPanel
                            .frame(width: 280)
                            .background(Color(NSColor.controlBackgroundColor))
                            .transition(.move(edge: .leading))
                    }
                    
                    // Main Simulation Canvas
                    simulationCanvas
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onAppear {
                            // Start simulation on appear
                            simulationEngine.start()
                        }
                        .onDisappear {
                            // Pause simulation when view disappears
                            simulationEngine.pause()
                        }
                    
                    // Right Environmental Panel
                    if showingStatistics {
                        rightEnvironmentalPanel
                            .frame(width: 280)
                            .background(Color(NSColor.controlBackgroundColor))
                            .transition(.move(edge: .trailing))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Control Panel
    
    private var controlPanel: some View {
        HStack(spacing: 12) {
            // Control buttons
            HStack(spacing: 8) {
                Button(action: {
                    if simulationEngine.isRunning {
                        simulationEngine.pause()
                    } else {
                        simulationEngine.start()
                    }
                }) {
                    Image(systemName: simulationEngine.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    simulationEngine.reset()
                }) {
                    Text("Reset")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    simulationEngine.step()
                }) {
                    Image(systemName: "forward.frame.fill")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    simulationEngine.evolveNextGeneration()
                }) {
                    Text("Next Gen")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
                .frame(height: 30)
            
            // Quick Status Indicators
            HStack(spacing: 8) {
                // Weather Indicator
                WeatherIndicator(weatherManager: simulationEngine.weatherManager)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                // Season Indicator
                HStack(spacing: 4) {
                    Text(simulationEngine.seasonalManager.currentSeason.emoji)
                        .font(.title2)
                    Text(simulationEngine.seasonalManager.currentSeason.rawValue.capitalized)
                        .font(.headline)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(simulationEngine.seasonalManager.currentSeason.color.opacity(0.2)))
                
                Text("•")
                    .foregroundColor(.secondary)
                
                // Disaster Indicator
                DisasterIndicator(disasterManager: simulationEngine.disasterManager)
                
                // Ecosystem Indicator
                EcosystemIndicator(ecosystemManager: simulationEngine.ecosystemManager)
            }
            
            Divider()
                .frame(height: 30)
            
            // Generation Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Generation: \(simulationEngine.currentGeneration)")
                    .font(.headline)
                Text("Population: \(simulationEngine.bugs.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 30)
            
            // Quick Performance Stats
            VStack(alignment: .leading, spacing: 2) {
                let averageEnergy = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.energy).reduce(0, +) / Double(simulationEngine.bugs.count)
                Text("Avg Energy: \(String(format: "%.1f", averageEnergy))")
                    .font(.caption)
                Text("Food: \(simulationEngine.foods.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Toggle Statistics
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingStatistics.toggle()
                }
            }) {
                Image(systemName: showingStatistics ? "sidebar.left.and.sidebar.right" : "rectangle.center.inset.filled")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Simulation Canvas
    
    private var simulationCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                // 🚀 EPIC 3D VOXEL VISUALIZATION - TO INFINITY AND BEYOND!
                // Use the single Arena3DView instance to prevent multiple 3D scene creation
                engineManager.arena3DView
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
    }
    

    
    // MARK: - Statistics Panels
    
    private var leftStatisticsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("📊 Population Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                Divider()
                
                // Population Statistics
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎮 Simulation Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    StatRow(label: "🐛 Total Bugs", value: "\(simulationEngine.bugs.count)")
                    StatRow(label: "🧬 Generation", value: "\(simulationEngine.currentGeneration)")
                    StatRow(label: "🍎 Food Sources", value: "\(simulationEngine.foods.count)")
                    StatRow(label: "⚡ Status", value: simulationEngine.isRunning ? "Running" : "Paused")
                    
                    // Generation Progress Bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Generation Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        let generationProgress = Double(simulationEngine.tickCount % simulationEngine.generationLength) / Double(simulationEngine.generationLength)
                        ProgressView(value: generationProgress)
                            .accentColor(.blue)
                            .frame(height: 6)
                        
                        let ticksRemaining = simulationEngine.generationLength - (simulationEngine.tickCount % simulationEngine.generationLength)
                        Text("\(ticksRemaining) ticks until generation \(simulationEngine.currentGeneration + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                Divider()
                
                // Genetic Averages
                VStack(alignment: .leading, spacing: 8) {
                    Text("🧬 Genetic Averages")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    let averageSpeed = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.speed).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageVision = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.visionRadius).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageEfficiency = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.energyEfficiency).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageAggression = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.aggression).reduce(0, +) / Double(simulationEngine.bugs.count)
                    
                    StatRow(label: "🏃 Speed", value: String(format: "%.2f", averageSpeed))
                    StatRow(label: "👁️ Vision", value: String(format: "%.1f", averageVision))
                    StatRow(label: "⚡ Efficiency", value: String(format: "%.2f", averageEfficiency))
                    StatRow(label: "⚔️ Aggression", value: String(format: "%.2f", averageAggression))
                }
                
                Divider()
                
                // Environmental Adaptations
                VStack(alignment: .leading, spacing: 8) {
                    Text("🌍 Environmental Adaptations")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    let averageStrength = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.strength).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageMemory = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.memory).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageStickiness = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.stickiness).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageCamouflage = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.camouflage).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageCuriosity = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.curiosity).reduce(0, +) / Double(simulationEngine.bugs.count)
                    
                    StatRow(label: "💪 Strength", value: String(format: "%.2f", averageStrength))
                    StatRow(label: "🧠 Memory", value: String(format: "%.2f", averageMemory))
                    StatRow(label: "🕷️ Stickiness", value: String(format: "%.2f", averageStickiness))
                    StatRow(label: "🫥 Camouflage", value: String(format: "%.2f", averageCamouflage))
                    StatRow(label: "🔍 Curiosity", value: String(format: "%.2f", averageCuriosity))
                }
                
                Divider()
                
                // Current Averages
                VStack(alignment: .leading, spacing: 8) {
                    Text("📈 Current Averages")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    let averageEnergy = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.energy).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageAge = simulationEngine.bugs.isEmpty ? 0 : Double(simulationEngine.bugs.map(\.age).reduce(0, +)) / Double(simulationEngine.bugs.count)
                    
                    StatRow(label: "⚡ Energy", value: String(format: "%.1f", averageEnergy))
                    StatRow(label: "📅 Age", value: String(format: "%.0f", averageAge))
                }
                
                Divider()
                
                // Population Dynamics
                VStack(alignment: .leading, spacing: 8) {
                    Text("🧬 Population Dynamics")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    let populations = simulationEngine.speciationManager.populations
                    let viableSpecies = populations.filter { $0.isViableSpecies }
                    
                    StatRow(label: "Active Populations", value: "\(populations.count)")
                    StatRow(label: "Viable Species", value: "\(viableSpecies.count)")
                    
                    if let largestPop = populations.max(by: { $0.size < $1.size }) {
                        StatRow(label: "Largest Pop Size", value: "\(largestPop.size)")
                        StatRow(label: "Dominant Species", value: String(largestPop.name.prefix(25)))
                        StatRow(label: "Species Age", value: "\(largestPop.age) gen")
                    }
                    
                    // Recent speciation events
                    let recentEvents = simulationEngine.speciationManager.getRecentEvents(limit: 2)
                    if !recentEvents.isEmpty {
                        Text("Recent Speciation Events:")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .padding(.top, 8)
                        
                        ForEach(recentEvents.indices, id: \.self) { index in
                            Text("• \(recentEvents[index].description)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .padding(.leading, 8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var rightEnvironmentalPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("🌍 Environment Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingStatistics = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                // 🌱 Seasonal Cycles
                SeasonalStatusView(seasonalManager: simulationEngine.seasonalManager)
                
                Divider()
                
                // 🌦️ Weather Information
                WeatherStatusView(weatherManager: simulationEngine.weatherManager)
                
                Divider()
                
                // 🌋 Natural Disasters
                DisasterStatusView(disasterManager: simulationEngine.disasterManager)
                
                Divider()
                
                // 🌿 Ecosystem Health
                EcosystemStatusView(ecosystemManager: simulationEngine.ecosystemManager)
                
                Divider()
                
                // 🧠 Neural Energy Economics
                NeuralEnergyStatusView(bugs: simulationEngine.bugs)
                
                Divider()
                
                // 🗺️ Territories & Speciation
                TerritoryStatusView(territoryManager: simulationEngine.territoryManager, speciationManager: simulationEngine.speciationManager)
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Helper Views

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.caption)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .font(.system(.caption, design: .monospaced))
        }
    }
}