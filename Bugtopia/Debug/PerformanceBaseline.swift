//
//  PerformanceBaseline.swift
//  Bugtopia
//
//  Created by RealityKit Developer on 12/20/24.
//  Performance Baseline & Benchmarking for SceneKit → RealityKit Migration
//

import Foundation
import SwiftUI
import Combine

/// 📊 Performance Baseline Tracker
/// Monitors and compares performance between SceneKit and RealityKit implementations
@Observable
class PerformanceBaseline {
    
    // MARK: - Singleton
    
    static let shared = PerformanceBaseline()
    
    // MARK: - Performance Metrics
    
    struct PerformanceSnapshot {
        let timestamp: Date
        let renderingEngine: RenderingEngine
        let fps: Double
        let bugCount: Int
        let foodCount: Int
        let generation: Int
        let memoryUsage: Double // MB
        let cpuUsage: Double // %
        let frameTime: Double // ms
        
        var summary: String {
            """
            \(renderingEngine.displayName):
            • FPS: \(String(format: "%.1f", fps))
            • Entities: \(bugCount + foodCount)
            • Memory: \(String(format: "%.1f", memoryUsage))MB
            • CPU: \(String(format: "%.1f", cpuUsage))%
            • Frame Time: \(String(format: "%.2f", frameTime))ms
            """
        }
        
        var csvRow: String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return "\(dateFormatter.string(from: timestamp)),\(renderingEngine.rawValue),\(fps),\(bugCount),\(foodCount),\(generation),\(memoryUsage),\(cpuUsage),\(frameTime)"
        }
    }
    
    // MARK: - Baseline Data
    
    private(set) var sceneKitBaseline: [PerformanceSnapshot] = []
    private(set) var realityKitBaseline: [PerformanceSnapshot] = []
    private(set) var isRecording: Bool = false
    
    // MARK: - Current Session
    
    private var sessionStartTime: Date?
    private var frameCount: Int = 0
    private var lastFPSUpdate: Date = Date()
    private var fpsBuffer: [Double] = []
    
    // MARK: - Publishers
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        loadBaselineData()
    }
    
    // MARK: - Recording Control
    
    /// Start performance recording session
    func startRecording() {
        isRecording = true
        sessionStartTime = Date()
        frameCount = 0
        lastFPSUpdate = Date()
        fpsBuffer.removeAll()
        
        print("📊 [Performance] Started baseline recording session")
    }
    
    /// Stop performance recording session
    func stopRecording() {
        isRecording = false
        sessionStartTime = nil
        
        print("📊 [Performance] Stopped baseline recording session")
        saveBaselineData()
    }
    
    /// Record a performance snapshot
    func recordSnapshot(
        simulationEngine: SimulationEngine,
        fps: Double = 0.0,
        memoryUsage: Double = 0.0,
        cpuUsage: Double = 0.0,
        frameTime: Double = 0.0
    ) {
        guard isRecording else { return }
        
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            renderingEngine: RenderingConfiguration.shared.activeEngine,
            fps: fps,
            bugCount: simulationEngine.bugs.count,
            foodCount: simulationEngine.foods.count,
            generation: simulationEngine.currentGeneration,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            frameTime: frameTime
        )
        
        switch RenderingConfiguration.shared.activeEngine {
        case .sceneKit:
            sceneKitBaseline.append(snapshot)
        case .realityKit:
            realityKitBaseline.append(snapshot)
        }
        
        // Limit baseline data to prevent memory issues
        if sceneKitBaseline.count > 1000 {
            sceneKitBaseline.removeFirst(500)
        }
        if realityKitBaseline.count > 1000 {
            realityKitBaseline.removeFirst(500)
        }
    }
    
    // MARK: - Analysis
    
    /// Get performance comparison between engines
    func getPerformanceComparison() -> PerformanceComparison? {
        guard !sceneKitBaseline.isEmpty || !realityKitBaseline.isEmpty else { return nil }
        
        let sceneKitAvg = calculateAverageMetrics(sceneKitBaseline)
        let realityKitAvg = calculateAverageMetrics(realityKitBaseline)
        
        return PerformanceComparison(
            sceneKit: sceneKitAvg,
            realityKit: realityKitAvg
        )
    }
    
    /// Calculate average metrics for snapshots
    private func calculateAverageMetrics(_ snapshots: [PerformanceSnapshot]) -> AverageMetrics? {
        guard !snapshots.isEmpty else { return nil }
        
        let avgFPS = snapshots.map { $0.fps }.reduce(0, +) / Double(snapshots.count)
        let avgMemory = snapshots.map { $0.memoryUsage }.reduce(0, +) / Double(snapshots.count)
        let avgCPU = snapshots.map { $0.cpuUsage }.reduce(0, +) / Double(snapshots.count)
        let avgFrameTime = snapshots.map { $0.frameTime }.reduce(0, +) / Double(snapshots.count)
        let avgEntityCount = snapshots.map { $0.bugCount + $0.foodCount }.reduce(0, +) / snapshots.count
        
        return AverageMetrics(
            fps: avgFPS,
            memoryUsage: avgMemory,
            cpuUsage: avgCPU,
            frameTime: avgFrameTime,
            entityCount: Double(avgEntityCount),
            sampleCount: snapshots.count
        )
    }
    
    /// Export baseline data to CSV
    func exportBaselineData() -> String {
        var csv = "timestamp,engine,fps,bugs,food,generation,memory_mb,cpu_percent,frame_time_ms\n"
        
        let allSnapshots = (sceneKitBaseline + realityKitBaseline).sorted { $0.timestamp < $1.timestamp }
        
        for snapshot in allSnapshots {
            csv += snapshot.csvRow + "\n"
        }
        
        return csv
    }
    
    /// Clear all baseline data
    func clearBaseline() {
        sceneKitBaseline.removeAll()
        realityKitBaseline.removeAll()
        saveBaselineData()
        
        print("📊 [Performance] Cleared all baseline data")
    }
    
    // MARK: - Persistence
    
    private func saveBaselineData() {
        let data = BaselineData(sceneKit: sceneKitBaseline, realityKit: realityKitBaseline)
        
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "PerformanceBaseline")
        }
    }
    
    private func loadBaselineData() {
        guard let data = UserDefaults.standard.data(forKey: "PerformanceBaseline"),
              let decoded = try? JSONDecoder().decode(BaselineData.self, from: data) else {
            return
        }
        
        sceneKitBaseline = decoded.sceneKit
        realityKitBaseline = decoded.realityKit
    }
}

// MARK: - Supporting Types

struct PerformanceComparison {
    let sceneKit: AverageMetrics?
    let realityKit: AverageMetrics?
    
    var improvement: PerformanceImprovement? {
        guard let sceneKit = sceneKit, let realityKit = realityKit else { return nil }
        
        return PerformanceImprovement(
            fpsImprovement: (realityKit.fps - sceneKit.fps) / sceneKit.fps * 100,
            memoryImprovement: (sceneKit.memoryUsage - realityKit.memoryUsage) / sceneKit.memoryUsage * 100,
            cpuImprovement: (sceneKit.cpuUsage - realityKit.cpuUsage) / sceneKit.cpuUsage * 100,
            frameTimeImprovement: (sceneKit.frameTime - realityKit.frameTime) / sceneKit.frameTime * 100
        )
    }
}

struct AverageMetrics: Codable {
    let fps: Double
    let memoryUsage: Double
    let cpuUsage: Double
    let frameTime: Double
    let entityCount: Double
    let sampleCount: Int
}

struct PerformanceImprovement {
    let fpsImprovement: Double
    let memoryImprovement: Double
    let cpuImprovement: Double
    let frameTimeImprovement: Double
    
    var summary: String {
        """
        🚀 RealityKit vs SceneKit Performance:
        • FPS: \(fpsImprovement > 0 ? "+" : "")\(String(format: "%.1f", fpsImprovement))%
        • Memory: \(memoryImprovement > 0 ? "+" : "")\(String(format: "%.1f", memoryImprovement))%
        • CPU: \(cpuImprovement > 0 ? "+" : "")\(String(format: "%.1f", cpuImprovement))%
        • Frame Time: \(frameTimeImprovement > 0 ? "+" : "")\(String(format: "%.1f", frameTimeImprovement))%
        """
    }
}

private struct BaselineData: Codable {
    let sceneKit: [PerformanceBaseline.PerformanceSnapshot]
    let realityKit: [PerformanceBaseline.PerformanceSnapshot]
}

// MARK: - Codable Extensions

extension PerformanceBaseline.PerformanceSnapshot: Codable {
    enum CodingKeys: String, CodingKey {
        case timestamp, renderingEngine, fps, bugCount, foodCount, generation, memoryUsage, cpuUsage, frameTime
    }
}

extension RenderingEngine: Codable {}

// MARK: - Performance Monitor View

/// 📊 Performance monitoring UI component
struct PerformanceMonitorView: View {
    @State private var baseline = PerformanceBaseline.shared
    @State private var showExportSheet = false
    @State private var exportedData = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.green)
                Text("Performance Baseline")
                    .font(.headline)
                
                Spacer()
                
                recordingIndicator
            }
            
            // Performance Summary
            if let comparison = baseline.getPerformanceComparison() {
                performanceComparisonView(comparison)
            } else {
                Text("No baseline data recorded yet")
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            // Controls
            HStack(spacing: 12) {
                Button(baseline.isRecording ? "Stop Recording" : "Start Recording") {
                    if baseline.isRecording {
                        baseline.stopRecording()
                    } else {
                        baseline.startRecording()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Export Data") {
                    exportedData = baseline.exportBaselineData()
                    showExportSheet = true
                }
                .disabled(baseline.sceneKitBaseline.isEmpty && baseline.realityKitBaseline.isEmpty)
                
                Button("Clear Data") {
                    baseline.clearBaseline()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .sheet(isPresented: $showExportSheet) {
            NavigationView {
                ScrollView {
                    Text(exportedData)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                }
                .navigationTitle("Performance Data")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            showExportSheet = false
                        }
                    }
                }
            }
        }
    }
    
    private var recordingIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(baseline.isRecording ? Color.red : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(baseline.isRecording ? "Recording" : "Not Recording")
                .font(.caption)
                .foregroundColor(baseline.isRecording ? .red : .secondary)
        }
    }
    
    private func performanceComparisonView(_ comparison: PerformanceComparison) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let sceneKit = comparison.sceneKit {
                performanceMetricsRow("SceneKit", metrics: sceneKit, color: .orange)
            }
            
            if let realityKit = comparison.realityKit {
                performanceMetricsRow("RealityKit", metrics: realityKit, color: .blue)
            }
            
            if let improvement = comparison.improvement {
                Text(improvement.summary)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 4)
            }
        }
    }
    
    private func performanceMetricsRow(_ title: String, metrics: AverageMetrics, color: Color) -> some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(color)
                .frame(width: 80, alignment: .leading)
            
            Text("FPS: \(String(format: "%.1f", metrics.fps))")
                .frame(width: 80, alignment: .leading)
            
            Text("Mem: \(String(format: "%.0f", metrics.memoryUsage))MB")
                .frame(width: 90, alignment: .leading)
            
            Text("Entities: \(String(format: "%.0f", metrics.entityCount))")
                .frame(width: 90, alignment: .leading)
            
            Text("(\(metrics.sampleCount) samples)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }
}

// MARK: - Preview

#Preview {
    PerformanceMonitorView()
        .frame(width: 500)
        .padding()
}
