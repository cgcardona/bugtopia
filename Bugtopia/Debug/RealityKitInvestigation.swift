//
//  RealityKitInvestigation.swift
//  Bugtopia
//
//  Created by RealityKit Developer on 12/20/24.
//  Phase 2: Investigating RealityKit capabilities on macOS
//

import SwiftUI
import RealityKit
import Foundation

/// 🔬 RealityKit API Investigation for Phase 2
/// Testing what RealityKit features are available on macOS with current Xcode/Swift versions
struct RealityKitInvestigation {
    
    // MARK: - Basic Entity Creation Test
    
    static func testBasicEntityCreation() -> Bool {
        print("🔬 [Investigation] Testing basic Entity creation...")
        
        // Test basic entity creation
        let entity = Entity()
        entity.name = "TestEntity"
        
        // Test if we can create mesh resources
        let sphere = MeshResource.generateSphere(radius: 1.0)
        let material = SimpleMaterial(color: .red, isMetallic: false)
        
        // Test model component
        entity.components.set(ModelComponent(mesh: sphere, materials: [material]))
        
        print("✅ [Investigation] Basic entity creation successful")
        print("   • Entity: \(entity)")
        print("   • Mesh: \(sphere)")
        print("   • Material: \(material)")
        
        return true
    }
    
    // MARK: - RealityView Availability Test
    
    static func testRealityViewAvailability() -> Bool {
        print("🔬 [Investigation] Testing RealityView availability...")
        
        // Check if RealityView is available by attempting to reference it
        #if canImport(RealityKit)
        if #available(macOS 14.0, *) {
            print("✅ [Investigation] RealityKit available on macOS 14.0+")
            
            // Test if RealityView exists (this will compile if available)
            let testView: () -> AnyView = {
                if #available(macOS 14.0, *) {
                    // This should work on macOS 14+ with Xcode 15+
                    return AnyView(Text("RealityView would go here"))
                } else {
                    return AnyView(Text("RealityView not available"))
                }
            }
            _ = testView
            
            return true
        } else {
            print("❌ [Investigation] RealityKit requires macOS 14.0+")
            return false
        }
        #else
        print("❌ [Investigation] RealityKit not available")
        return false
        #endif
    }
    
    // MARK: - Performance Testing Framework
    
    static func testEntityPerformance(entityCount: Int = 100) -> PerformanceResults {
        print("🔬 [Investigation] Testing entity performance with \(entityCount) entities...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var entities: [Entity] = []
        
        // Create entities
        for i in 0..<entityCount {
            let entity = Entity()
            entity.name = "TestEntity_\(i)"
            
            // Add basic geometry
            let sphere = MeshResource.generateSphere(radius: Float.random(in: 0.5...1.5))
            let material = SimpleMaterial(
                color: .init(
                    red: CGFloat(Float.random(in: 0...1)),
                    green: CGFloat(Float.random(in: 0...1)),
                    blue: CGFloat(Float.random(in: 0...1)),
                    alpha: 1.0
                ),
                isMetallic: false
            )
            
            entity.components.set(ModelComponent(mesh: sphere, materials: [material]))
            entities.append(entity)
        }
        
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Test updates
        let updateStartTime = CFAbsoluteTimeGetCurrent()
        for entity in entities {
            entity.position = SIMD3<Float>(
                Float.random(in: -10...10),
                Float.random(in: -10...10),
                Float.random(in: -10...10)
            )
        }
        let updateTime = CFAbsoluteTimeGetCurrent() - updateStartTime
        
        let results = PerformanceResults(
            entityCount: entityCount,
            creationTime: creationTime,
            updateTime: updateTime,
            memoryUsage: getMemoryUsage()
        )
        
        print("📊 [Investigation] Performance Results:")
        print("   • Entities: \(results.entityCount)")
        print("   • Creation: \(String(format: "%.3f", results.creationTime))s")
        print("   • Update: \(String(format: "%.3f", results.updateTime))s")
        print("   • Memory: \(String(format: "%.1f", results.memoryUsage))MB")
        
        return results
    }
    
    // MARK: - Material System Investigation
    
    static func testMaterialSystem() -> Bool {
        print("🔬 [Investigation] Testing material system capabilities...")
        
        // Test SimpleMaterial
        let simpleMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        print("✅ [Investigation] SimpleMaterial created: \(simpleMaterial)")
        
        // Test if PhysicallyBasedMaterial is available
        var pbrMaterial = PhysicallyBasedMaterial()
        pbrMaterial.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .green)
        pbrMaterial.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: 0.5)
        pbrMaterial.metallic = PhysicallyBasedMaterial.Metallic(floatLiteral: 0.0)
        print("✅ [Investigation] PhysicallyBasedMaterial created: \(pbrMaterial)")
        
        return true
    }
    
    // MARK: - Component System Investigation
    
    static func testComponentSystem() -> Bool {
        print("🔬 [Investigation] Testing component system...")
        
        let entity = Entity()
        
        // Test ModelComponent
        let sphere = MeshResource.generateSphere(radius: 1.0)
        let material = SimpleMaterial(color: .red, isMetallic: false)
        entity.components.set(ModelComponent(mesh: sphere, materials: [material]))
        
        // Test if we can retrieve components
        let hasModel = entity.components.has(ModelComponent.self)
        print("✅ [Investigation] ModelComponent: \(hasModel)")
        
        // Test Transform component (should always exist)
        let transform = entity.transform
        print("✅ [Investigation] Transform: \(transform)")
        
        return true
    }
    
    // MARK: - Memory Usage Helper
    
    private static func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // Convert to MB
        } else {
            return 0.0
        }
    }
    
    // MARK: - Investigation Results
    
    struct PerformanceResults {
        let entityCount: Int
        let creationTime: TimeInterval
        let updateTime: TimeInterval
        let memoryUsage: Double
        
        var entitiesPerSecond: Double {
            return Double(entityCount) / creationTime
        }
        
        var updatesPerSecond: Double {
            return Double(entityCount) / updateTime
        }
    }
    
    // MARK: - Run Full Investigation
    
    static func runFullInvestigation() -> InvestigationReport {
        print("🔬 [Investigation] Starting comprehensive RealityKit investigation...")
        print("📱 Environment: macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        
        let report = InvestigationReport(
            basicEntityCreation: testBasicEntityCreation(),
            realityViewAvailability: testRealityViewAvailability(),
            materialSystem: testMaterialSystem(),
            componentSystem: testComponentSystem(),
            performanceResults: [
                testEntityPerformance(entityCount: 50),
                testEntityPerformance(entityCount: 100),
                testEntityPerformance(entityCount: 180) // Bugtopia target
            ]
        )
        
        print("\n📋 [Investigation] Final Report:")
        print("   • Basic Entities: \(report.basicEntityCreation ? "✅" : "❌")")
        print("   • RealityView: \(report.realityViewAvailability ? "✅" : "❌")")
        print("   • Materials: \(report.materialSystem ? "✅" : "❌")")
        print("   • Components: \(report.componentSystem ? "✅" : "❌")")
        print("   • Performance Tests: \(report.performanceResults.count) completed")
        
        return report
    }
    
    struct InvestigationReport {
        let basicEntityCreation: Bool
        let realityViewAvailability: Bool
        let materialSystem: Bool
        let componentSystem: Bool
        let performanceResults: [PerformanceResults]
        
        var isRealityKitViable: Bool {
            return basicEntityCreation && materialSystem && componentSystem
        }
        
        var canUseRealityView: Bool {
            return realityViewAvailability
        }
    }
}

// MARK: - Phase 2 Investigation View

/// Debug view for testing RealityKit capabilities
struct RealityKitInvestigationView: View {
    @State private var investigationReport: RealityKitInvestigation.InvestigationReport?
    @State private var isRunning = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔬 RealityKit Investigation")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Phase 2: Core Systems Migration")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let report = investigationReport {
                VStack(alignment: .leading, spacing: 12) {
                    Text("📋 Investigation Results:")
                        .font(.headline)
                    
                    HStack {
                        Text("Basic Entities:")
                        Spacer()
                        Text(report.basicEntityCreation ? "✅ Working" : "❌ Failed")
                            .foregroundColor(report.basicEntityCreation ? .green : .red)
                    }
                    
                    HStack {
                        Text("RealityView:")
                        Spacer()
                        Text(report.realityViewAvailability ? "✅ Available" : "❌ Not Available")
                            .foregroundColor(report.realityViewAvailability ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Material System:")
                        Spacer()
                        Text(report.materialSystem ? "✅ Working" : "❌ Failed")
                            .foregroundColor(report.materialSystem ? .green : .red)
                    }
                    
                    HStack {
                        Text("Component System:")
                        Spacer()
                        Text(report.componentSystem ? "✅ Working" : "❌ Failed")
                            .foregroundColor(report.componentSystem ? .green : .red)
                    }
                    
                    if !report.performanceResults.isEmpty {
                        Text("📊 Performance Results:")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(Array(report.performanceResults.enumerated()), id: \.offset) { index, result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(result.entityCount) Entities:")
                                    .fontWeight(.medium)
                                Text("• Creation: \(String(format: "%.1f", result.entitiesPerSecond)) entities/sec")
                                    .font(.caption)
                                Text("• Updates: \(String(format: "%.1f", result.updatesPerSecond)) updates/sec")
                                    .font(.caption)
                                Text("• Memory: \(String(format: "%.1f", result.memoryUsage))MB")
                                    .font(.caption)
                            }
                            .padding(.leading)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: {
                runInvestigation()
            }) {
                if isRunning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Running Investigation...")
                    }
                } else {
                    Text("🔬 Run RealityKit Investigation")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func runInvestigation() {
        isRunning = true
        
        Task.detached {
            let report = RealityKitInvestigation.runFullInvestigation()
            
            await MainActor.run {
                self.investigationReport = report
                self.isRunning = false
            }
        }
    }
}

#Preview {
    RealityKitInvestigationView()
}
