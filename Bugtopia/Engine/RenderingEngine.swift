//
//  RenderingEngine.swift
//  Bugtopia
//
//  Created by RealityKit Developer on 12/20/24.
//  Feature Flag System for SceneKit ↔ RealityKit Migration
//

import SwiftUI
import Foundation

/// 🚀 Rendering Engine Selection
/// Allows seamless switching between SceneKit and RealityKit during migration
enum RenderingEngine: String, CaseIterable {
    case sceneKit = "SceneKit"
    case realityKit = "RealityKit"
    
    var displayName: String {
        switch self {
        case .sceneKit:
            return "🏗️ SceneKit (Legacy)"
        case .realityKit:
            return "🚀 RealityKit (Future)"
        }
    }
    
    var description: String {
        switch self {
        case .sceneKit:
            return "Stable, mature 3D rendering. Full feature set."
        case .realityKit:
            return "Next-generation spatial computing. Enhanced visuals."
        }
    }
    
    var isExperimental: Bool {
        switch self {
        case .sceneKit:
            return false
        case .realityKit:
            return true // Mark as experimental during migration
        }
    }
}

/// 🎛️ Rendering Configuration Manager
/// Centralized management of rendering engine selection and feature flags
@Observable
class RenderingConfiguration {
    
    // MARK: - Singleton Instance
    
    static let shared = RenderingConfiguration()
    
    // MARK: - Core Configuration
    
    /// Currently active rendering engine
    var activeEngine: RenderingEngine = .sceneKit {
        didSet {
            UserDefaults.standard.set(activeEngine.rawValue, forKey: "ActiveRenderingEngine")
            print("🔄 [RenderingConfig] Switched to \(activeEngine.displayName)")
        }
    }
    
    /// Whether to show performance overlay
    var showPerformanceOverlay: Bool = false {
        didSet {
            UserDefaults.standard.set(showPerformanceOverlay, forKey: "ShowPerformanceOverlay")
        }
    }
    
    /// Whether to enable debug mode
    var debugMode: Bool = false {
        didSet {
            UserDefaults.standard.set(debugMode, forKey: "RenderingDebugMode")
        }
    }
    
    // MARK: - Migration Feature Flags
    
    /// Enable parallel rendering for comparison
    var enableParallelRendering: Bool = false
    
    /// Force high-quality rendering (may impact performance)
    var forceHighQuality: Bool = false
    
    /// Enable experimental spatial features
    var enableSpatialFeatures: Bool = false
    
    // MARK: - Performance Targets
    
    /// Target frame rate for rendering
    var targetFPS: Double = 60.0
    
    /// Maximum entity count before optimization kicks in
    var maxEntityCount: Int = 200
    
    /// Enable automatic LOD system
    var enableLOD: Bool = true
    
    // MARK: - Initialization
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration Management
    
    /// Load configuration from UserDefaults
    private func loadConfiguration() {
        if let engineString = UserDefaults.standard.string(forKey: "ActiveRenderingEngine"),
           let engine = RenderingEngine(rawValue: engineString) {
            activeEngine = engine
        }
        
        showPerformanceOverlay = UserDefaults.standard.bool(forKey: "ShowPerformanceOverlay")
        debugMode = UserDefaults.standard.bool(forKey: "RenderingDebugMode")
    }
    
    /// Reset to default configuration
    func resetToDefaults() {
        activeEngine = .sceneKit
        showPerformanceOverlay = false
        debugMode = false
        enableParallelRendering = false
        forceHighQuality = false
        enableSpatialFeatures = false
        targetFPS = 60.0
        maxEntityCount = 200
        enableLOD = true
    }
    
    /// Get configuration summary for debugging
    func getConfigurationSummary() -> String {
        return """
        🎛️ Rendering Configuration Summary:
        • Engine: \(activeEngine.displayName)
        • Performance Overlay: \(showPerformanceOverlay ? "Enabled" : "Disabled")
        • Debug Mode: \(debugMode ? "Enabled" : "Disabled")
        • Target FPS: \(targetFPS)
        • Max Entities: \(maxEntityCount)
        • LOD System: \(enableLOD ? "Enabled" : "Disabled")
        """
    }
}

/// 🎮 Rendering Engine Selector View
/// UI component for switching between rendering engines
struct RenderingEngineSelector: View {
    @State private var config = RenderingConfiguration.shared
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                Text("Rendering Engine")
                    .font(.headline)
                Spacer()
            }
            
            // Engine Selection
            VStack(spacing: 12) {
                ForEach(RenderingEngine.allCases, id: \.self) { engine in
                    engineRow(for: engine)
                }
            }
            
            // Performance Options
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Show Performance Overlay", isOn: $config.showPerformanceOverlay)
                Toggle("Debug Mode", isOn: $config.debugMode)
                
                if config.activeEngine == .realityKit {
                    Toggle("Experimental Spatial Features", isOn: $config.enableSpatialFeatures)
                        .foregroundColor(.orange)
                }
            }
            .padding(.top)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .alert("Rendering Engine Switch", isPresented: $showAlert) {
            Button("Switch") {
                // Confirm switch
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Switching rendering engines will restart the 3D view. Continue?")
        }
    }
    
    /// Individual engine selection row
    private func engineRow(for engine: RenderingEngine) -> some View {
        Button(action: {
            switchToEngine(engine)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(engine.displayName)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(config.activeEngine == engine ? .semibold : .regular)
                        
                        if engine.isExperimental {
                            Text("EXPERIMENTAL")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(engine.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if config.activeEngine == engine {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                config.activeEngine == engine 
                ? Color.blue.opacity(0.1)
                : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        config.activeEngine == engine 
                        ? Color.blue 
                        : Color.gray.opacity(0.3),
                        lineWidth: config.activeEngine == engine ? 2 : 1
                    )
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Switch to selected engine
    private func switchToEngine(_ engine: RenderingEngine) {
        if engine != config.activeEngine {
            config.activeEngine = engine
        }
    }
}

// MARK: - Feature Flag Helpers

/// Conditional rendering based on active engine
@ViewBuilder
func ConditionalRenderer<SceneKitContent: View, RealityKitContent: View>(
    @ViewBuilder sceneKit: () -> SceneKitContent,
    @ViewBuilder realityKit: () -> RealityKitContent
) -> some View {
    let config = RenderingConfiguration.shared
    
    if config.activeEngine == .realityKit {
        realityKit()
    } else {
        sceneKit()
    }
}

/// Performance-aware entity limit
func getOptimalEntityCount() -> Int {
    let config = RenderingConfiguration.shared
    
    switch config.activeEngine {
    case .sceneKit:
        return 180 // Current SceneKit limit
    case .realityKit:
        return config.maxEntityCount // Configurable for testing
    }
}

/// Check if advanced features are available
func areAdvancedFeaturesAvailable() -> Bool {
    let config = RenderingConfiguration.shared
    return config.activeEngine == .realityKit && config.enableSpatialFeatures
}

// MARK: - Preview

#Preview {
    RenderingEngineSelector()
        .frame(width: 400)
        .padding()
}
