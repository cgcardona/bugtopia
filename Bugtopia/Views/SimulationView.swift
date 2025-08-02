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
                    // Main Simulation Canvas
                    simulationCanvas
                        .background(Color.black)
                        .onAppear {
                            // Start simulation on appear
                            simulationEngine.start()
                        }
                        .onDisappear {
                            // Pause simulation when view disappears
                            simulationEngine.pause()
                        }
                    
                    // Side Panel for Statistics
                    if showingStatistics {
                        statisticsPanel
                            .frame(width: 300)
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
    

    
    // MARK: - Statistics Panel
    
    private var statisticsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("🧬 Evolution Analytics")
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
                
                // Simulation Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎮 Simulation Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    StatRow(label: "Generation", value: "\(simulationEngine.currentGeneration)")
                    StatRow(label: "Population", value: "\(simulationEngine.bugs.count)")
                    StatRow(label: "Food Sources", value: "\(simulationEngine.foods.count)")
                    StatRow(label: "Status", value: simulationEngine.isRunning ? "Running" : "Paused")
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