//
//  StateModificationTracker.swift
//  Bugtopia
//
//  Created by Assistant on 2025-01-11.
//

import SwiftUI
import Foundation

/// Debug utility to track and identify SwiftUI state modifications during view updates
class StateModificationTracker {
    static let shared = StateModificationTracker()
    
    private var isViewUpdating = false
    private var stateModifications: [StateModificationEvent] = []
    
    private init() {}
    
    struct StateModificationEvent {
        let timestamp: Date
        let propertyName: String
        let viewType: String
        let stackTrace: [String]
        let isViewUpdateContext: Bool
    }
    
    /// Call this at the beginning of view update cycles
    func startViewUpdate(viewType: String) {
        isViewUpdating = true
        print("🔍 [STATE-DEBUG] View update started: \(viewType)")
    }
    
    /// Call this at the end of view update cycles
    func endViewUpdate(viewType: String) {
        isViewUpdating = false
        print("🔍 [STATE-DEBUG] View update ended: \(viewType)")
    }
    
    /// Call this whenever you modify @State variables
    func trackStateModification(propertyName: String, viewType: String, value: Any) {
        let stackTrace = Thread.callStackSymbols
        let event = StateModificationEvent(
            timestamp: Date(),
            propertyName: propertyName,
            viewType: viewType,
            stackTrace: stackTrace,
            isViewUpdateContext: isViewUpdating
        )
        
        stateModifications.append(event)
        
        if isViewUpdating {
            print("⚠️ [STATE-VIOLATION] Modifying \(propertyName) in \(viewType) during view update!")
            print("💡 [STATE-DEBUG] Stack trace (top 5):")
            for (index, symbol) in stackTrace.prefix(5).enumerated() {
                print("   \(index): \(symbol)")
            }
        } else {
            print("✅ [STATE-SAFE] Modified \(propertyName) in \(viewType) outside view update")
        }
    }
    
    /// Generate a report of all state modifications
    func generateReport() -> String {
        let violations = stateModifications.filter { $0.isViewUpdateContext }
        let safe = stateModifications.filter { !$0.isViewUpdateContext }
        
        var report = """
        🔍 SwiftUI State Modification Report
        =====================================
        Total modifications: \(stateModifications.count)
        Violations (during view updates): \(violations.count)
        Safe modifications: \(safe.count)
        
        """
        
        if !violations.isEmpty {
            report += "\n⚠️ VIOLATIONS FOUND:\n"
            for (index, violation) in violations.enumerated() {
                report += """
                \(index + 1). \(violation.propertyName) in \(violation.viewType)
                   Time: \(violation.timestamp)
                   Stack trace preview: \(violation.stackTrace.first ?? "No stack trace")
                
                """
            }
        }
        
        return report
    }
    
    /// Clear all tracked events
    func clearEvents() {
        stateModifications.removeAll()
        print("🔍 [STATE-DEBUG] Cleared all tracked events")
    }
}

/// SwiftUI View extension to easily track view updates
extension View {
    func trackStateModifications(viewType: String) -> some View {
        self
            .onAppear {
                StateModificationTracker.shared.startViewUpdate(viewType: "\(viewType).onAppear")
                // Defer to ensure we capture the end of the cycle
                DispatchQueue.main.async {
                    StateModificationTracker.shared.endViewUpdate(viewType: "\(viewType).onAppear")
                }
            }
            .onDisappear {
                StateModificationTracker.shared.startViewUpdate(viewType: "\(viewType).onDisappear")
                DispatchQueue.main.async {
                    StateModificationTracker.shared.endViewUpdate(viewType: "\(viewType).onDisappear")
                }
            }
    }
}

#if DEBUG
/// Debugging View Modifier to detect excessive view redraws
struct ViewRedrawDetector: ViewModifier {
    let viewName: String
    @State private var redrawCount = 0
    
    func body(content: Content) -> some View {
        let _ = {
            redrawCount += 1
            if redrawCount > 1 {
                print("🔄 [VIEW-REDRAW] \(viewName) redrawn \(redrawCount) times")
            }
            return redrawCount
        }()
        
        content
            .background(redrawCount > 10 ? Color.red.opacity(0.1) : Color.clear)
    }
}

extension View {
    func detectRedraws(viewName: String) -> some View {
        self.modifier(ViewRedrawDetector(viewName: viewName))
    }
}
#endif

/// Macro-like function to track state modifications easily
func trackStateChange<T>(_ newValue: T, propertyName: String, viewType: String, stateVar: inout T) {
    StateModificationTracker.shared.trackStateModification(
        propertyName: propertyName,
        viewType: viewType,
        value: newValue
    )
    stateVar = newValue
}
