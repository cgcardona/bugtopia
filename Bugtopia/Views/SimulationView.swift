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
    
    // 🎯 Bug Selection Callback
    var onBugSelected: ((Bug?) -> Void)?
    
    // Lazy initialization ensures Arena3DView is created only once when first accessed
    lazy var arena3DView: Arena3DView = {
        return Arena3DView(simulationEngine: engine, onBugSelected: { [weak self] bug in
            // Dynamic callback that uses the current onBugSelected value
            self?.onBugSelected?(bug)
        })
    }()
    
    init(worldSize: CGSize = CGSize(width: 2000, height: 1500)) {
        let bounds = CGRect(origin: .zero, size: worldSize)
        self.engine = SimulationEngine(worldBounds: bounds)
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
    
    // 🎯 Bug Selection Handler
    private func handleBugSelection(_ bug: Bug?) {
        selectedBug = bug
        if let bug = bug {
            print("🎯 [UI] Selected bug: \(bug.id.uuidString.prefix(8)) - Age: \(bug.age), Energy: \(String(format: "%.1f", bug.energy))")
        } else {
            print("🎯 [UI] Deselected bug")
        }
    }
    
    // 🎯 Selected Bug Display
    @ViewBuilder
    private func selectedBugView(bug: Bug) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bug Header
            HStack {
                Text("🐛 Selected Bug")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Deselect") {
                    selectedBug = nil
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
            
            // Basic Stats
            VStack(alignment: .leading, spacing: 6) {
                StatRow(label: "ID", value: bug.id.uuidString.prefix(8).description)
                StatRow(label: "🧬 Species", value: bug.dna.speciesTraits.speciesType.rawValue.capitalized)
                StatRow(label: "📅 Age", value: "\(bug.age)")
                StatRow(label: "⚡ Energy", value: String(format: "%.1f/%.0f", bug.energy, Bug.maxEnergy))
                StatRow(label: "🔋 Status", value: bug.isAlive ? "Alive" : "Dead")
                StatRow(label: "🧬 Generation", value: "\(bug.generation)")
            }
            
            // Physical & 3D Movement Traits
            VStack(alignment: .leading, spacing: 4) {
                Text("🏃 Physical Traits")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                StatRow(label: "Size", value: String(format: "%.2f", bug.dna.size))
                StatRow(label: "Speed", value: String(format: "%.2f", bug.dna.speed))
                StatRow(label: "Vision", value: String(format: "%.1f", bug.dna.visionRadius))
                StatRow(label: "Strength", value: String(format: "%.2f", bug.dna.strength))
                StatRow(label: "Memory", value: String(format: "%.2f", bug.dna.memory))
                StatRow(label: "Aggression", value: String(format: "%.2f", bug.dna.aggression))
                StatRow(label: "Curiosity", value: String(format: "%.2f", bug.dna.curiosity))
            }
            
            // 3D Movement Capabilities
            VStack(alignment: .leading, spacing: 4) {
                Text("🌍 3D Movement")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                StatRow(label: "🕊️ Wing Span", value: String(format: "%.2f %@", bug.dna.wingSpan, bug.canFly ? "(Can Fly)" : ""))
                StatRow(label: "🏊 Diving Depth", value: String(format: "%.2f %@", bug.dna.divingDepth, bug.canSwim ? "(Can Swim)" : ""))
                StatRow(label: "🧗 Climbing Grip", value: String(format: "%.2f %@", bug.dna.climbingGrip, bug.canClimb ? "(Can Climb)" : ""))
                StatRow(label: "⛰️ Altitude Pref", value: String(format: "%.2f", bug.dna.altitudePreference))
                StatRow(label: "💨 Pressure Tol", value: String(format: "%.2f", bug.dna.pressureTolerance))
            }
            
            // Neural Network Architecture & Stats
            neuralNetworkStatsView(for: bug)
            
            // Current Neural Activity
            if let decision = bug.lastDecision {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚡ Current Neural Activity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    StatRow(label: "🏃 Movement X", value: String(format: "%.2f", decision.moveX))
                    StatRow(label: "🏃 Movement Y", value: String(format: "%.2f", decision.moveY))
                    StatRow(label: "🕊️ Movement Z", value: String(format: "%.2f", decision.moveZ))
                    StatRow(label: "🌍 Layer Change", value: String(format: "%.2f", decision.layerChange))
                    StatRow(label: "😱 Fleeing", value: String(format: "%.2f", decision.fleeing))
                    StatRow(label: "🦁 Hunting", value: String(format: "%.2f", decision.hunting))
                    StatRow(label: "🔍 Exploration", value: String(format: "%.2f", decision.exploration))
                    StatRow(label: "👥 Social", value: String(format: "%.2f", decision.social))
                    StatRow(label: "💕 Reproduction", value: String(format: "%.2f", decision.reproduction))
                    StatRow(label: "⚔️ Aggression", value: String(format: "%.2f", decision.aggression))
                }
            }
            
            // Behavioral State
            VStack(alignment: .leading, spacing: 4) {
                Text("🎭 Behavior")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                StatRow(label: "Has Target", value: bug.targetFood != nil ? "Yes" : "No")
                StatRow(label: "Threat", value: bug.predatorThreat != nil ? "Detected" : "None")
                StatRow(label: "Layer", value: bug.currentLayer.rawValue.capitalized)
            }
        }
        .padding()
        .background(Color(NSColor.controlAccentColor).opacity(0.1))
        .cornerRadius(8)
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
        .onAppear {
            // 🎯 Set up bug selection callback
            print("🎯 [UI-SETUP] Setting up bug selection callback")
            engineManager.onBugSelected = handleBugSelection
            print("🎯 [UI-SETUP] Bug selection callback connected")
        }
    }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 🧠 Neural Network Stats View
    @ViewBuilder
    private func neuralNetworkStatsView(for bug: Bug) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🧠 Neural Network")
                .font(.subheadline)
                .fontWeight(.medium)
            
            let neuralDNA = bug.dna.neuralDNA
            let complexityScore = NeuralEnergyManager.calculateComplexityScore(for: neuralDNA)
            let totalNeurons = neuralDNA.topology.reduce(0, +)
            
            // Calculate total connections manually since the method is private
            let totalConnections = calculateNeuralConnections(topology: neuralDNA.topology)
            
            StatRow(label: "🏗️ Layers", value: "\(neuralDNA.topology.count) (\(neuralDNA.topology.count - 2) hidden)")
            StatRow(label: "🔬 Neurons", value: "\(totalNeurons)")
            StatRow(label: "🔗 Connections", value: "\(totalConnections)")
            StatRow(label: "🎯 Complexity", value: String(format: "%.1f", complexityScore))
            StatRow(label: "⚡ Neural Energy", value: String(format: "%.2f", bug.dna.neuralEnergyEfficiency))
            StatRow(label: "🧠 Plasticity", value: String(format: "%.2f", bug.dna.brainPlasticity))
            
            // Network topology visualization
            let topologyStr = neuralDNA.topology.map(String.init).joined(separator: "→")
            StatRow(label: "📊 Architecture", value: topologyStr)
            
            // Activation functions
            let activationStr = neuralDNA.activations.map { $0.rawValue }.joined(separator: ", ")
            StatRow(label: "🎛️ Activations", value: activationStr)
        }
    }
    
    // Helper function to calculate neural network connections
    private func calculateNeuralConnections(topology: [Int]) -> Int {
        var totalConnections = 0
        for i in 0..<(topology.count - 1) {
            totalConnections += topology[i] * topology[i + 1]
        }
        return totalConnections
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
                
                // PHASE 1 DEBUG: Manual debug trigger
                Button(action: {
                    engineManager.arena3DView.triggerPhase1Debug()
                }) {
                    Text("🔍 Debug")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
                
                // 🎮 AAA PERFORMANCE: Performance report
                Button(action: {
                    engineManager.arena3DView.triggerPerformanceAnalysis()
                }) {
                    Text("📊 Perf")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                

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
                    .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                        // 🔄 FORCE SwiftUI to call updateNSView regularly for continuous visual updates
                        // This triggers the Arena3DView update cycle every 100ms (10 FPS)
                        engineManager.arena3DView.triggerVisualUpdate()
                    }
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
                
                // 🎯 Selected Bug Display
                if let selectedBug = selectedBug {
                    selectedBugView(bug: selectedBug)
                    Divider()
                } else {
                    Text("🎯 Click a bug to select it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 4)
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