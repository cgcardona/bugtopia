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
                .buttonStyle(.bordered)
            
                Button(action: {
                simulationEngine.reset()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
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
            
            // Simulation Stats
            VStack(alignment: .leading, spacing: 2) {
                Text("Generation: \(simulationEngine.currentGeneration)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Population: \(simulationEngine.bugs.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Toggle Statistics
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingStatistics.toggle()
                }
            }) {
                Image(systemName: showingStatistics ? "sidebar.right" : "sidebar.left")
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
                    
                    let averageEnergy = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.energy).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageSpeed = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.speed).reduce(0, +) / Double(simulationEngine.bugs.count)
                    let averageSize = simulationEngine.bugs.isEmpty ? 0 : simulationEngine.bugs.map(\.dna.size).reduce(0, +) / Double(simulationEngine.bugs.count)
                    
                    StatRow(label: "⚡ Energy", value: String(format: "%.1f", averageEnergy))
                    StatRow(label: "🏃 Speed", value: String(format: "%.2f", averageSpeed))
                    StatRow(label: "📏 Size", value: String(format: "%.2f", averageSize))
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