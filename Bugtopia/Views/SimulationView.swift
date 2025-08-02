//
//  SimulationView.swift
//  Bugtopia
//
//  Created by Assistant on 8/1/25.
//

import SwiftUI

/// Main view for displaying and controlling the evolutionary simulation
struct SimulationView: View {
    
    @State private var simulationEngine: SimulationEngine
    @State private var showingStatistics = true
    @State private var selectedBug: Bug?
    @State private var is3DMode = true  // Default to 3D mode since we've fully migrated to Arena3D  // NEW: Toggle for 3D visualization
    // Removed old arena3D - now using voxelWorld from SimulationEngine
    
    init(worldSize: CGSize = CGSize(width: 800, height: 600)) {
        let bounds = CGRect(origin: .zero, size: worldSize)
        let engine = SimulationEngine(worldBounds: bounds)
        _simulationEngine = State(wrappedValue: engine)
        // VoxelWorld is now initialized and managed by SimulationEngine
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
            
            // 🚀 3D MODE TOGGLE - TO INFINITY AND BEYOND!
            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    is3DMode.toggle()
                    // VoxelWorld is always available from SimulationEngine
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: is3DMode ? "cube.fill" : "cube")
                        .font(.title2)
                    Text(is3DMode ? "3D" : "2D")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(is3DMode ? .white : .primary)
            }
            .buttonStyle(.borderedProminent)
            .tint(is3DMode ? .blue : .gray)
            
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
                if is3DMode {
                    // 🚀 EPIC 3D VOXEL VISUALIZATION - TO INFINITY AND BEYOND!
                    Arena3DView(
                        simulationEngine: simulationEngine
                    )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    } else {
                        // 2D Canvas with 3D compatibility
               Canvas { context, size in
                            // Clear the canvas
                            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                            
                            // Scale factor for 2D display
                            let scaleX = size.width / simulationEngine.voxelWorld.worldBounds.width
                            let scaleY = size.height / simulationEngine.voxelWorld.worldBounds.height
                            
                            // Apply scaling transform
                            var scaledContext = context
                            scaledContext.scaleBy(x: scaleX, y: scaleY)
                            
                            // Draw terrain
                            drawTerrain(context: scaledContext)
            
            // Draw resources
                            drawResources(context: scaledContext)
            
            // Draw bugs
                            drawBugs(context: scaledContext)
                
                // Draw selected bug info
                            if let selectedBug = selectedBug {
                                drawBugInfo(context: scaledContext, bug: selectedBug)
                }
            }
            .onTapGesture { location in
                selectBugNear(location, canvasSize: geometry.size)
            }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
            }
        }
    }
    
    // MARK: - Missing Function Stubs
    
    private func drawTerrain(context: GraphicsContext) {
        // TODO: Implement terrain drawing
    }
    
    private func drawResources(context: GraphicsContext) {
        // TODO: Implement resource drawing
    }
    
    private func drawBugs(context: GraphicsContext) {
        // TODO: Implement bug drawing
    }
    
    private func drawBugInfo(context: GraphicsContext, bug: Bug) {
        // TODO: Implement bug info drawing
    }
    
    private func selectBugNear(_ location: CGPoint, canvasSize: CGSize) {
        // TODO: Implement bug selection
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