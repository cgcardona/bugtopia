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
            
            // Draw resources
            drawResources(context: context)
            
            // Draw construction sites
            drawConstructionSites(context: context)
            
            // Draw tools
            drawTools(context: context)
            
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
            
            // Selection highlight and info (for selected bug)
            if bug.id == selectedBug?.id {
                let terrainModifiers = simulationEngine.arena.movementModifiers(at: bug.position, for: bug.dna)
                let effectiveVision = bug.dna.visionRadius * terrainModifiers.vision
                
                // Selection highlight - centered on bug
                let selectionSize = max(radius * 2.5, 20.0) // Minimum 20 pixels
                let selectionRect = CGRect(
                    x: bug.position.x - selectionSize/2,
                    y: bug.position.y - selectionSize/2,
                    width: selectionSize,
                    height: selectionSize
                )
                context.stroke(
                    Path(roundedRect: selectionRect, cornerRadius: 4),
                    with: .color(.yellow),
                    lineWidth: 2.5
                )
                
                // Vision range circle
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
                
                // Show current terrain effect - positioned to the side
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
        
        // Draw a small indicator showing terrain effects - positioned to the side of the bug
        let indicatorRect = CGRect(
            x: position.x + bug.visualRadius + 8,  // Position to the right of the bug
            y: position.y - 8,                    // Centered vertically on the bug
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
    
    // MARK: - Tool System Rendering
    
    /// Draws resource nodes in the arena
    private func drawResources(context: GraphicsContext) {
        for resource in simulationEngine.resources {
            guard resource.isAvailable else { continue }
            
            let size: Double = 12.0
            let rect = CGRect(
                x: resource.position.x - size/2,
                y: resource.position.y - size/2,
                width: size,
                height: size
            )
            
            // Resource background
            context.fill(
                Path(ellipseIn: rect),
                with: .color(resource.type.color)
            )
            
            // Quantity indicator (size represents amount)
            let quantitySize = size * (Double(resource.quantity) / 10.0) * 0.7
            let quantityRect = CGRect(
                x: resource.position.x - quantitySize/2,
                y: resource.position.y - quantitySize/2,
                width: quantitySize,
                height: quantitySize
            )
            
            context.fill(
                Path(ellipseIn: quantityRect),
                with: .color(resource.type.color.opacity(0.8))
            )
            
            // Resource type indicator
            context.draw(
                Text(resource.type.emoji)
                    .font(.system(size: 8)),
                at: CGPoint(x: resource.position.x, y: resource.position.y + size/2 + 8),
                anchor: .center
            )
        }
    }
    
    /// Draws construction blueprints and progress
    private func drawConstructionSites(context: GraphicsContext) {
        for blueprint in simulationEngine.blueprints {
            let size = blueprint.type.energyCost / 2.0 // Size based on complexity
            let rect = CGRect(
                x: blueprint.position.x - size/2,
                y: blueprint.position.y - size/2,
                width: size,
                height: size
            )
            
            // Construction site outline
            context.stroke(
                Path(roundedRect: rect, cornerRadius: 4),
                with: .color(.orange),
                style: StrokeStyle(lineWidth: 2, dash: [4, 4])
            )
            
            // Progress indicator
            let progress = blueprint.completionPercentage
            let progressRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width * progress,
                height: rect.height
            )
            
            context.fill(
                Path(roundedRect: progressRect, cornerRadius: 4),
                with: .color(.orange.opacity(0.3))
            )
            
            // Tool type indicator
            context.draw(
                Text(blueprint.type.emoji)
                    .font(.system(size: 14)),
                at: blueprint.position,
                anchor: .center
            )
            
            // Progress percentage
            if progress > 0.1 {
                context.draw(
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 8))
                        .foregroundColor(.white),
                    at: CGPoint(x: blueprint.position.x, y: blueprint.position.y + size/2 + 12),
                    anchor: .center
                )
            }
        }
    }
    
    /// Draws completed tools in the arena
    private func drawTools(context: GraphicsContext) {
        for tool in simulationEngine.tools {
            guard tool.isUsable else { continue }
            
            let rect = CGRect(
                x: tool.position.x - tool.size.width/2,
                y: tool.position.y - tool.size.height/2,
                width: tool.size.width,
                height: tool.size.height
            )
            
            // Tool body with durability fade
            let alpha = tool.durability
            context.fill(
                Path(roundedRect: rect, cornerRadius: 3),
                with: .color(tool.type.color.opacity(alpha))
            )
            
            // Tool border
            context.stroke(
                Path(roundedRect: rect, cornerRadius: 3),
                with: .color(.gray),
                lineWidth: 1
            )
            
            // Tool icon
            context.draw(
                Text(tool.type.emoji)
                    .font(.system(size: min(tool.size.width, tool.size.height) * 0.6)),
                at: tool.position,
                anchor: .center
            )
            
            // Durability indicator
            if tool.durability < 0.5 {
                let warningColor: Color = tool.durability < 0.2 ? .red : .yellow
                context.stroke(
                    Path(roundedRect: rect, cornerRadius: 3),
                    with: .color(warningColor),
                    style: StrokeStyle(lineWidth: 2, dash: [2, 2])
                )
            }
            
            // Usage count for frequently used tools
            if tool.uses > 5 {
                context.draw(
                    Text("×\(tool.uses)")
                        .font(.system(size: 6))
                        .foregroundColor(.white),
                    at: CGPoint(x: tool.position.x, y: tool.position.y - tool.size.height/2 - 8),
                    anchor: .center
                )
            }
        }
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
                        Text("\(selected.dna.speciesTraits.speciesType.emoji) \(selected.dna.speciesTraits.speciesType.rawValue.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(selected.dna.speciesTraits.speciesType.baseColor)
                            .fontWeight(.bold)
                        
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
                        
                        if selected.dna.speciesTraits.speciesType.canHunt, let hunting = selected.dna.speciesTraits.huntingBehavior {
                            Text("🦁 Hunting Traits")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                            
                            StatRow(label: "Hunt Intensity", value: String(format: "%.2f", hunting.huntingIntensity))
                            StatRow(label: "Detection Range", value: String(format: "%.0f", hunting.preyDetectionRange))
                            StatRow(label: "Chase Speed", value: String(format: "%.2fx", hunting.chaseSpeedMultiplier))
                            StatRow(label: "Stealth", value: String(format: "%.2f", hunting.stealthLevel))
                        }
                        
                        if let defensive = selected.dna.speciesTraits.defensiveBehavior {
                            Text("🛡️ Defensive Traits")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .padding(.top, 8)
                            
                            StatRow(label: "Predator Detection", value: String(format: "%.2f", defensive.predatorDetection))
                            StatRow(label: "Flee Speed", value: String(format: "%.2fx", defensive.fleeSpeedMultiplier))
                            StatRow(label: "Hiding Skill", value: String(format: "%.2f", defensive.hidingSkill))
                            StatRow(label: "Flocking", value: String(format: "%.2f", defensive.flockingTendency))
                        }
                        
                        // Engineering & Tool Traits
                        Text("🔧 Engineering Traits")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .padding(.top, 8)
                        
                        StatRow(label: "Tool Crafting", value: String(format: "%.2f", selected.dna.toolDNA.toolCrafting))
                        StatRow(label: "Tool Proficiency", value: String(format: "%.2f", selected.dna.toolDNA.toolProficiency))
                        StatRow(label: "Tool Vision", value: String(format: "%.2f", selected.dna.toolDNA.toolVision))
                        StatRow(label: "Construction Drive", value: String(format: "%.2f", selected.dna.toolDNA.constructionDrive))
                        StatRow(label: "Carrying Capacity", value: String(format: "%.1f", selected.dna.toolDNA.carryingCapacity))
                        StatRow(label: "Resource Gathering", value: String(format: "%.2f", selected.dna.toolDNA.resourceGathering))
                        StatRow(label: "Engineering IQ", value: String(format: "%.2f", selected.dna.toolDNA.engineeringIntelligence))
                        StatRow(label: "Collaboration", value: String(format: "%.2f", selected.dna.toolDNA.collaborationTendency))
                        
                        // Current Construction Project
                        if let project = selected.currentProject {
                            Text("🏗️ Current Project")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                            
                            StatRow(label: "Building", value: "\(project.type.emoji) \(project.type.rawValue.capitalized)")
                            StatRow(label: "Progress", value: "\(Int(project.completionPercentage * 100))%")
                            StatRow(label: "Resources Needed", value: "\(project.requiredResources.count)")
                            StatRow(label: "Resources Gathered", value: "\(project.gatheredResources.values.reduce(0, +))")
                        }
                        
                        // Carried Resources
                        if !selected.carriedResources.isEmpty {
                            Text("📦 Inventory")
                                .font(.subheadline)
                                .foregroundColor(.brown)
                                .padding(.top, 8)
                            
                            ForEach(Array(selected.carriedResources.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { resourceType in
                                if let quantity = selected.carriedResources[resourceType], quantity > 0 {
                                    StatRow(label: "\(resourceType.emoji) \(resourceType.rawValue.capitalized)", value: "\(quantity)")
                                }
                            }
                            StatRow(label: "Capacity Used", value: "\(selected.carriedResources.values.reduce(0, +))/\(selected.maxCarryingCapacity)")
                        }
                        
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
                            StatRow(label: "Hunting", value: String(format: "%.2f", decision.hunting))
                            StatRow(label: "Fleeing", value: String(format: "%.2f", decision.fleeing))
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
