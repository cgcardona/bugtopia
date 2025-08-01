//
//  SimulationView.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import SwiftUI

/// Main view for displaying and controlling the evolutionary simulation
struct SimulationView: View {
    
    @State private var simulationEngine: SimulationEngine
    @State private var showingStatistics = true
    @State private var selectedBug: Bug?
    
    init(worldSize: CGSize = CGSize(width: 800, height: 600)) {
        let bounds = CGRect(origin: .zero, size: worldSize)
        _simulationEngine = State(initialValue: SimulationEngine(worldBounds: bounds))
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Statistics Panel (if shown)
                    if showingStatistics {
                        statisticsPanel
                            .frame(width: 300)
                            .background(Color(NSColor.controlBackgroundColor))
                    }
                }
            }
        }
        .navigationTitle("Bugtopia Evolution Simulator")
        .onAppear {
            // Auto-start simulation
            simulationEngine.start()
        }
        .onDisappear {
            simulationEngine.pause()
        }
    }
    
    // MARK: - Control Panel
    
    private var controlPanel: some View {
        HStack {
            // Play/Pause Button
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
            
            // Reset Button
            Button("Reset") {
                simulationEngine.reset()
            }
            .buttonStyle(.bordered)
            
            Divider()
                .frame(height: 30)
            
            // Generation Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Generation: \(simulationEngine.currentGeneration)")
                    .font(.headline)
                Text("Population: \(simulationEngine.statistics.aliveBugs)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 30)
            
            // Speed/Performance Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Avg Energy: \(String(format: "%.1f", simulationEngine.statistics.averageEnergy))")
                    .font(.caption)
                Text("Food: \(simulationEngine.statistics.totalFood)")
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
                Image(systemName: showingStatistics ? "sidebar.right" : "sidebar.left")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Simulation Canvas
    
    private var simulationCanvas: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Scale the simulation to fit the canvas
                let scaleX = size.width / simulationEngine.arena.bounds.width
                let scaleY = size.height / simulationEngine.arena.bounds.height
                let scale = min(scaleX, scaleY)
                
                            // Transform context to simulation coordinates
            context.scaleBy(x: scale, y: scale)
            
            // Draw arena terrain
            drawTerrain(context: context)
            
            // Draw food
            drawFood(context: context)
            
            // Draw bugs
            drawBugs(context: context)
                
                // Draw selected bug info
                if let selected = selectedBug {
                    drawBugInfo(context: context, bug: selected)
                }
            }
            .onTapGesture { location in
                selectBugNear(location, canvasSize: geometry.size)
            }
        }
    }
    
    // MARK: - Drawing Functions
    
    private func drawTerrain(context: GraphicsContext) {
        // Draw terrain tiles
        for row in simulationEngine.arena.tiles {
            for tile in row {
                // Skip open terrain (black background)
                guard tile.terrain != .open else { continue }
                
                let rect = tile.rect
                let path = Path(rect)
                
                // Fill terrain with appropriate color
                context.fill(path, with: .color(tile.terrain.color))
                
                // Add terrain-specific visual effects
                switch tile.terrain {
                case .water:
                    // Animated water effect with slight transparency variation
                    let waveOffset = sin(Double(simulationEngine.tickCount) * 0.1) * 0.1
                    let waterColor = tile.terrain.color.opacity(0.6 + waveOffset)
                    context.fill(path, with: .color(waterColor))
                    
                case .hill:
                    // Add elevation shading
                    let gradient = Gradient(colors: [
                        tile.terrain.color,
                        tile.terrain.color.opacity(0.7)
                    ])
                    context.fill(path, with: .linearGradient(gradient, startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
                    
                case .shadow:
                    // Darker, more ominous appearance
                    context.fill(path, with: .color(Color.black.opacity(0.8)))
                    
                case .predator:
                    // Pulsing red danger zones
                    let pulseIntensity = sin(Double(simulationEngine.tickCount) * 0.2) * 0.2 + 0.3
                    let predatorColor = Color.red.opacity(pulseIntensity)
                    context.fill(path, with: .color(predatorColor))
                    
                case .wind:
                    // Flowing wind pattern
                    let windIntensity = sin(Double(simulationEngine.tickCount) * 0.15) * 0.1 + 0.2
                    let windColor = Color.cyan.opacity(windIntensity)
                    context.fill(path, with: .color(windColor))
                    
                case .food:
                    // Rich, fertile areas
                    context.fill(path, with: .color(Color.green.opacity(0.3)))
                    
                case .wall:
                    // Solid walls with border
                    context.fill(path, with: .color(tile.terrain.color))
                    context.stroke(path, with: .color(.gray.opacity(0.8)), lineWidth: 1)
                    
                default:
                    context.fill(path, with: .color(tile.terrain.color))
                }
            }
        }
    }
    
    private func drawFood(context: GraphicsContext) {
        for food in simulationEngine.foods {
            let rect = CGRect(x: food.x - 2, y: food.y - 2, width: 4, height: 4)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(.green)
            )
        }
    }
    
    private func drawBugs(context: GraphicsContext) {
        for bug in simulationEngine.bugs {
            guard bug.isAlive else { continue }
            
            let radius = bug.visualRadius
            let rect = CGRect(
                x: bug.position.x - radius,
                y: bug.position.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            
            // Bug body
            let bugPath = Path(ellipseIn: rect)
            context.fill(bugPath, with: .color(bug.dna.color))
            
            // Energy indicator (brightness)
            let energyAlpha = min(1.0, bug.energy / Bug.maxEnergy)
            let energyRect = CGRect(
                x: bug.position.x - radius * 0.7,
                y: bug.position.y - radius * 0.7,
                width: radius * 1.4,
                height: radius * 1.4
            )
            context.fill(
                Path(ellipseIn: energyRect),
                with: .color(bug.dna.color.opacity(energyAlpha))
            )
            
            // Velocity indicator (small arrow)
            if bug.velocity.x != 0 || bug.velocity.y != 0 {
                drawVelocityArrow(context: context, bug: bug, radius: radius)
            }
            
            // Vision range (for selected bug) - adjusted for terrain
            if bug.id == selectedBug?.id {
                let terrainModifiers = simulationEngine.arena.movementModifiers(at: bug.position, for: bug.dna)
                let effectiveVision = bug.dna.visionRadius * terrainModifiers.vision
                
                let visionRect = CGRect(
                    x: bug.position.x - effectiveVision,
                    y: bug.position.y - effectiveVision,
                    width: effectiveVision * 2,
                    height: effectiveVision * 2
                )
                context.stroke(
                    Path(ellipseIn: visionRect),
                    with: .color(.white.opacity(0.4)),
                    lineWidth: 1.5
                )
                
                // Show current terrain effect
                drawTerrainInfo(context: context, bug: bug, at: bug.position)
            }
        }
    }
    
    private func drawVelocityArrow(context: GraphicsContext, bug: Bug, radius: Double) {
        let arrowLength = radius * 1.5
        let velocity = bug.velocity
        let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        
        guard speed > 0.1 else { return }
        
        let normalizedX = velocity.x / speed
        let normalizedY = velocity.y / speed
        
        let arrowEnd = CGPoint(
            x: bug.position.x + normalizedX * arrowLength,
            y: bug.position.y + normalizedY * arrowLength
        )
        
        var arrowPath = Path()
        arrowPath.move(to: bug.position)
        arrowPath.addLine(to: arrowEnd)
        
        context.stroke(arrowPath, with: .color(.white.opacity(0.7)), lineWidth: 2)
    }
    
    private func drawBugInfo(context: GraphicsContext, bug: Bug) {
        let currentTerrain = simulationEngine.arena.terrainAt(bug.position)
        let modifiers = simulationEngine.arena.movementModifiers(at: bug.position, for: bug.dna)
        
        let infoText = """
        Gen: \(bug.generation) | Energy: \(String(format: "%.1f", bug.energy))
        Terrain: \(currentTerrain.rawValue.capitalized)
        Speed: \(String(format: "%.2f", bug.dna.speed)) (×\(String(format: "%.2f", modifiers.speed)))
        Vision: \(String(format: "%.1f", bug.dna.visionRadius)) (×\(String(format: "%.2f", modifiers.vision)))
        """
        
        let textPosition = CGPoint(
            x: bug.position.x + bug.visualRadius + 10,
            y: bug.position.y - 30
        )
        
        context.draw(
            Text(infoText)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white),
            at: textPosition
        )
    }
    
    private func drawTerrainInfo(context: GraphicsContext, bug: Bug, at position: CGPoint) {
        let currentTerrain = simulationEngine.arena.terrainAt(position)
        let modifiers = simulationEngine.arena.movementModifiers(at: position, for: bug.dna)
        
        // Draw a small indicator showing terrain effects
        let indicatorRect = CGRect(
            x: position.x - 8,
            y: position.y + bug.visualRadius + 5,
            width: 16,
            height: 16
        )
        
        context.fill(
            Path(roundedRect: indicatorRect, cornerRadius: 3),
            with: .color(currentTerrain.color.opacity(0.8))
        )
        
        // Show speed modifier with color coding
        let speedColor: Color = modifiers.speed > 1.0 ? .green : (modifiers.speed < 0.8 ? .red : .yellow)
        context.stroke(
            Path(roundedRect: indicatorRect, cornerRadius: 3),
            with: .color(speedColor),
            lineWidth: 2
        )
    }
    
    // MARK: - Interaction
    
    private func selectBugNear(_ location: CGPoint, canvasSize: CGSize) {
        // Convert tap location from view coordinates to simulation coordinates
        let scaleX = canvasSize.width / simulationEngine.arena.bounds.width
        let scaleY = canvasSize.height / simulationEngine.arena.bounds.height
        let scale = min(scaleX, scaleY)
        
        // Transform tap coordinates to simulation space
        let simulationX = location.x / scale
        let simulationY = location.y / scale
        let simulationLocation = CGPoint(x: simulationX, y: simulationY)
        
        let tolerance: Double = 15.0 // Tolerance in simulation coordinates
        
        selectedBug = simulationEngine.bugs.first { bug in
            let distance = sqrt(
                pow(bug.position.x - simulationLocation.x, 2) +
                pow(bug.position.y - simulationLocation.y, 2)
            )
            return distance < tolerance
        }
        
        // Debug output
        if let selected = selectedBug {
            print("🐛 Selected bug at (\(Int(selected.position.x)), \(Int(selected.position.y))) - Generation \(selected.generation)")
        }
    }
    
    // MARK: - Statistics Panel
    
    private var statisticsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("Population Statistics")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    StatRow(label: "Total Bugs", value: "\(simulationEngine.statistics.totalBugs)")
                    StatRow(label: "Alive", value: "\(simulationEngine.statistics.aliveBugs)")
                    StatRow(label: "Generation", value: "\(simulationEngine.statistics.currentGeneration)")
                    StatRow(label: "Food Items", value: "\(simulationEngine.statistics.totalFood)")
                    
                    Divider()
                    
                    Text("Genetic Averages")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    StatRow(label: "Speed", value: String(format: "%.2f", simulationEngine.statistics.averageSpeed))
                    StatRow(label: "Vision", value: String(format: "%.1f", simulationEngine.statistics.averageVision))
                    StatRow(label: "Efficiency", value: String(format: "%.2f", simulationEngine.statistics.averageEfficiency))
                    StatRow(label: "Aggression", value: String(format: "%.2f", simulationEngine.statistics.averageAggression))
                    
                    Divider()
                    
                    Text("Environmental Adaptations")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    StatRow(label: "Strength", value: String(format: "%.2f", simulationEngine.statistics.averageStrength))
                    StatRow(label: "Memory", value: String(format: "%.2f", simulationEngine.statistics.averageMemory))
                    StatRow(label: "Stickiness", value: String(format: "%.2f", simulationEngine.statistics.averageStickiness))
                    StatRow(label: "Camouflage", value: String(format: "%.2f", simulationEngine.statistics.averageCamouflage))
                    StatRow(label: "Curiosity", value: String(format: "%.2f", simulationEngine.statistics.averageCuriosity))
                    
                    Divider()
                    
                    Text("Current Averages")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    StatRow(label: "Energy", value: String(format: "%.1f", simulationEngine.statistics.averageEnergy))
                    StatRow(label: "Age", value: String(format: "%.0f", simulationEngine.statistics.averageAge))
                }
                
                if let selected = selectedBug {
                    Divider()
                    
                    Text("Selected Bug")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🧬 Physical DNA")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        StatRow(label: "Speed", value: String(format: "%.2f", selected.dna.speed))
                        StatRow(label: "Vision", value: String(format: "%.1f", selected.dna.visionRadius))
                        StatRow(label: "Efficiency", value: String(format: "%.2f", selected.dna.energyEfficiency))
                        StatRow(label: "Size", value: String(format: "%.2f", selected.dna.size))
                        StatRow(label: "Strength", value: String(format: "%.2f", selected.dna.strength))
                        StatRow(label: "Memory", value: String(format: "%.2f", selected.dna.memory))
                        StatRow(label: "Stickiness", value: String(format: "%.2f", selected.dna.stickiness))
                        StatRow(label: "Camouflage", value: String(format: "%.2f", selected.dna.camouflage))
                        StatRow(label: "Aggression", value: String(format: "%.2f", selected.dna.aggression))
                        StatRow(label: "Curiosity", value: String(format: "%.2f", selected.dna.curiosity))
                        
                        Text("🧠 Neural Network")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .padding(.top, 8)
                        
                        StatRow(label: "Topology", value: "\(selected.dna.neuralDNA.topology.map(String.init).joined(separator: "-"))")
                        StatRow(label: "Weights", value: "\(selected.dna.neuralDNA.weights.count)")
                        StatRow(label: "Biases", value: "\(selected.dna.neuralDNA.biases.count)")
                        StatRow(label: "Layers", value: "\(selected.dna.neuralDNA.topology.count)")
                        
                        if let decision = selected.lastDecision {
                            Text("🎯 Current Decision")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .padding(.top, 8)
                            
                            StatRow(label: "Move X", value: String(format: "%.2f", decision.moveX))
                            StatRow(label: "Move Y", value: String(format: "%.2f", decision.moveY))
                            StatRow(label: "Aggression", value: String(format: "%.2f", decision.aggression))
                            StatRow(label: "Exploration", value: String(format: "%.2f", decision.exploration))
                            StatRow(label: "Social", value: String(format: "%.2f", decision.social))
                            StatRow(label: "Reproduction", value: String(format: "%.2f", decision.reproduction))
                        }
                        
                        Text("📊 Current State")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        StatRow(label: "Generation", value: "\(selected.generation)")
                        StatRow(label: "Energy", value: String(format: "%.1f", selected.energy))
                        StatRow(label: "Age", value: "\(selected.age)")
                        StatRow(label: "Can Reproduce", value: selected.canReproduce ? "Yes" : "No")
                        
                        let currentTerrain = simulationEngine.arena.terrainAt(selected.position)
                        let modifiers = simulationEngine.arena.movementModifiers(at: selected.position, for: selected.dna)
                        
                        Text("🌍 Current Environment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        StatRow(label: "Terrain", value: currentTerrain.rawValue.capitalized)
                        StatRow(label: "Speed Modifier", value: String(format: "×%.2f", modifiers.speed))
                        StatRow(label: "Vision Modifier", value: String(format: "×%.2f", modifiers.vision))
                        StatRow(label: "Energy Cost", value: String(format: "×%.2f", modifiers.energyCost))
                        StatRow(label: "Terrain Fitness", value: String(format: "%.1f", selected.dna.terrainFitness(for: currentTerrain)))
                    }
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
