//
//  NeuralEnergyUI.swift
//  Bugtopia
//
//  Neural Energy Economics UI Components
//  Visualizes intelligence costs, brain scaling, and energy efficiency
//

import SwiftUI

// MARK: - Neural Energy Indicator

/// Shows neural energy consumption status in the top bar
struct NeuralEnergyIndicator: View {
    let bugs: [Bug]
    
    private var averageNeuralCost: Double {
        guard !bugs.isEmpty else { return 0 }
        let totalCost = bugs.map { bug in
            NeuralEnergyManager.calculateNeuralEnergyCost(
                for: bug.dna.neuralDNA, 
                efficiency: bug.dna.neuralEnergyEfficiency
            )
        }.reduce(0, +)
        return totalCost / Double(bugs.count)
    }
    
    private var averageIntelligence: Double {
        guard !bugs.isEmpty else { return 0 }
        let totalIntelligence = bugs.map { bug in
            NeuralEnergyManager.calculateIntelligenceScore(
                for: bug.dna.neuralDNA, 
                efficiency: bug.dna.neuralEnergyEfficiency
            )
        }.reduce(0, +)
        return totalIntelligence / Double(bugs.count)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Neural Energy")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(averageNeuralCost, specifier: "%.3f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(averageNeuralCost > 0.02 ? .red : .primary)
                    
                    Text("⚡")
                        .font(.caption2)
                }
            }
            
            Divider()
                .frame(height: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Intelligence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(averageIntelligence, specifier: "%.1f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text("🧠")
                        .font(.caption2)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Neural Energy Status View

/// Detailed neural energy statistics panel
struct NeuralEnergyStatusView: View {
    let bugs: [Bug]
    
    private var neuralStats: (avgCost: Double, avgEfficiency: Double, avgIntelligence: Double, avgComplexity: Double) {
        guard !bugs.isEmpty else { return (0, 0, 0, 0) }
        
        let costs = bugs.map { NeuralEnergyManager.calculateNeuralEnergyCost(for: $0.dna.neuralDNA, efficiency: $0.dna.neuralEnergyEfficiency) }
        let efficiencies = bugs.map { $0.dna.neuralEnergyEfficiency }
        let intelligences = bugs.map { NeuralEnergyManager.calculateIntelligenceScore(for: $0.dna.neuralDNA, efficiency: $0.dna.neuralEnergyEfficiency) }
        let complexities = bugs.map { NeuralEnergyManager.calculateComplexityScore(for: $0.dna.neuralDNA) }
        
        return (
            avgCost: costs.reduce(0, +) / Double(bugs.count),
            avgEfficiency: efficiencies.reduce(0, +) / Double(bugs.count),
            avgIntelligence: intelligences.reduce(0, +) / Double(bugs.count),
            avgComplexity: complexities.reduce(0, +) / Double(bugs.count)
        )
    }
    
    private var brainScalingStats: (totalPruning: Int, totalGrowth: Int) {
        let totalPruning = bugs.map { $0.brainPruningEvents }.reduce(0, +)
        let totalGrowth = bugs.map { $0.brainGrowthEvents }.reduce(0, +)
        return (totalPruning, totalGrowth)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("Neural Energy Economics")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            // Energy Cost Metrics
            VStack(alignment: .leading, spacing: 8) {
                Label("Energy Consumption", systemImage: "bolt.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                HStack {
                    Text("Average Cost:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(neuralStats.avgCost, specifier: "%.4f") ⚡/tick")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(neuralStats.avgCost > 0.02 ? .red : .primary)
                }
                
                HStack {
                    Text("Efficiency:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(neuralStats.avgEfficiency, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(neuralStats.avgEfficiency < 1.0 ? .green : .orange)
                }
            }
            
            // Intelligence Metrics
            VStack(alignment: .leading, spacing: 8) {
                Label("Intelligence Metrics", systemImage: "brain")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                HStack {
                    Text("Intelligence Score:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(neuralStats.avgIntelligence, specifier: "%.1f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Brain Complexity:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(neuralStats.avgComplexity, specifier: "%.1f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
            }
            
            // Brain Scaling Events
            VStack(alignment: .leading, spacing: 8) {
                Label("Adaptive Scaling", systemImage: "arrow.up.and.down.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.indigo)
                
                HStack {
                    Text("Brain Pruning:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(brainScalingStats.totalPruning) events")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Brain Growth:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(brainScalingStats.totalGrowth) events")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            // Intelligence vs Efficiency Trade-off
            VStack(alignment: .leading, spacing: 8) {
                Label("Trade-off Analysis", systemImage: "scale.3d")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.teal)
                
                let efficiencyRatio = neuralStats.avgIntelligence / max(0.001, neuralStats.avgCost * 100)
                
                HStack {
                    Text("Intelligence/Cost Ratio:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(efficiencyRatio, specifier: "%.1f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(efficiencyRatio > 50 ? .green : efficiencyRatio > 25 ? .orange : .red)
                }
                
                Text("Higher ratios indicate better intelligence per energy cost")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Neural Energy Overlay

/// Visual overlay showing neural energy consumption on the simulation canvas
struct NeuralEnergyOverlay: View {
    let bugs: [Bug]
    let canvasSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Draw neural energy cost indicators for each bug
            for bug in bugs {
                let neuralCost = NeuralEnergyManager.calculateNeuralEnergyCost(
                    for: bug.dna.neuralDNA, 
                    efficiency: bug.dna.neuralEnergyEfficiency
                )
                
                // Scale position to canvas
                let scaledX = (bug.position.x / 800.0) * size.width
                let scaledY = (bug.position.y / 600.0) * size.height
                let position = CGPoint(x: scaledX, y: scaledY)
                
                // Only show indicators for high-cost brains
                if neuralCost > 0.015 {
                    // Draw energy cost indicator
                    let costIntensity = min(1.0, neuralCost / 0.05)
                    let color = Color.red.opacity(costIntensity * 0.6)
                    
                    // Pulsing circle to indicate neural energy drain
                    let pulseRadius = 8.0 + sin(Date().timeIntervalSince1970 * 4) * 3.0
                    
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: position.x - pulseRadius/2,
                            y: position.y - pulseRadius/2,
                            width: pulseRadius,
                            height: pulseRadius
                        )),
                        with: .color(color)
                    )
                    
                    // Draw brain icon for very high intelligence
                    let intelligence = NeuralEnergyManager.calculateIntelligenceScore(
                        for: bug.dna.neuralDNA, 
                        efficiency: bug.dna.neuralEnergyEfficiency
                    )
                    
                    if intelligence > 30 {
                        // Simple brain representation
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: position.x - 3,
                                y: position.y - 3,
                                width: 6,
                                height: 6
                            )),
                            with: .color(.purple.opacity(0.8))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false) // Allow taps to pass through to the canvas below
    }
}

// MARK: - Individual Bug Neural Energy Details

/// Detailed neural energy information for a selected bug
struct BugNeuralEnergyDetails: View {
    let bug: Bug
    
    private var neuralCost: Double {
        NeuralEnergyManager.calculateNeuralEnergyCost(
            for: bug.dna.neuralDNA, 
            efficiency: bug.dna.neuralEnergyEfficiency
        )
    }
    
    private var intelligence: Double {
        NeuralEnergyManager.calculateIntelligenceScore(
            for: bug.dna.neuralDNA, 
            efficiency: bug.dna.neuralEnergyEfficiency
        )
    }
    
    private var complexity: Double {
        NeuralEnergyManager.calculateComplexityScore(for: bug.dna.neuralDNA)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("🧠 Neural Network Architecture", systemImage: "brain.head.profile")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                // Neural Architecture Details
                HStack {
                    Text("Network Layers:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(bug.dna.neuralDNA.topology.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Total Neurons:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(bug.dna.neuralDNA.topology.reduce(0, +))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Total Weights:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(bug.dna.neuralDNA.weights.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Architecture:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(bug.dna.neuralDNA.topology.map { "\($0)" }.joined(separator: "-"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Energy Economics
                HStack {
                    Text("Energy Cost:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(neuralCost, specifier: "%.4f") ⚡/tick")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(neuralCost > 0.02 ? .red : .primary)
                }
                
                HStack {
                    Text("Intelligence:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(intelligence, specifier: "%.1f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Brain Complexity:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(complexity, specifier: "%.1f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
                
                HStack {
                    Text("Neural Efficiency:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(bug.dna.neuralEnergyEfficiency, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(bug.dna.neuralEnergyEfficiency < 1.0 ? .green : .orange)
                }
                
                HStack {
                    Text("Brain Plasticity:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(bug.dna.brainPlasticity, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.teal)
                }
                
                if bug.brainPruningEvents > 0 || bug.brainGrowthEvents > 0 {
                    Divider()
                    
                    HStack {
                        Text("Brain Scaling:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("↓\(bug.brainPruningEvents) ↑\(bug.brainGrowthEvents)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.indigo)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}