//
//  StateViolationDetector.swift
//  Bugtopia
//
//  Created by Assistant on 2025-01-11.
//

import SwiftUI
import Foundation

#if DEBUG
/// Advanced state violation detector with stack trace capture
class StateViolationDetector {
    static let shared = StateViolationDetector()
    
    private var isInViewUpdate = false
    private var viewUpdateStack: [String] = []
    
    private init() {
        setupGlobalStateDetection()
    }
    
    /// Set up global detection for state violations
    private func setupGlobalStateDetection() {
        // Swizzle or intercept state changes if needed
        print("🔍 [STATE-DETECTOR] Initialized state violation detection")
    }
    
    /// Call this at the start of any view update
    func enterViewUpdate(viewName: String) {
        isInViewUpdate = true
        viewUpdateStack.append(viewName)
        
        print("🔄 [VIEW-UPDATE] Started: \(viewName) (depth: \(viewUpdateStack.count))")
    }
    
    /// Call this at the end of any view update
    func exitViewUpdate(viewName: String) {
        if let index = viewUpdateStack.firstIndex(of: viewName) {
            viewUpdateStack.remove(at: index)
        }
        
        if viewUpdateStack.isEmpty {
            isInViewUpdate = false
        }
        
        print("🔄 [VIEW-UPDATE] Ended: \(viewName) (depth: \(viewUpdateStack.count))")
    }
    
    /// Track any state modification with full context
    func logStateModification(
        property: String,
        value: Any,
        viewType: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let location = "\(fileName):\(line) in \(function)"
        
        let stackTrace = Thread.callStackSymbols.prefix(10).joined(separator: "\n  ")
        
        if isInViewUpdate {
            print("""
            ⚠️ [STATE-VIOLATION] DETECTED!
            Property: \(property) = \(value)
            View Type: \(viewType)
            Location: \(location)
            View Update Stack: \(viewUpdateStack.joined(separator: " → "))
            
            Stack Trace:
              \(stackTrace)
            
            """)
        } else {
            print("✅ [STATE-SAFE] \(property) = \(value) in \(viewType) at \(location)")
        }
    }
}

/// Property wrapper to automatically detect state modifications
@propertyWrapper
struct TrackedState<Value>: DynamicProperty {
    @State private var value: Value
    private let name: String
    private let viewType: String
    
    init(wrappedValue: Value, name: String = "Unknown", viewType: String = "Unknown") {
        self._value = State(wrappedValue: wrappedValue)
        self.name = name
        self.viewType = viewType
    }
    
    var wrappedValue: Value {
        get {
            value
        }
        nonmutating set {
            StateViolationDetector.shared.logStateModification(
                property: name,
                value: newValue,
                viewType: viewType
            )
            value = newValue
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

/// View modifier to automatically track view updates
struct ViewUpdateTracker: ViewModifier {
    let viewName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                StateViolationDetector.shared.enterViewUpdate(viewName: "\(viewName).onAppear")
                DispatchQueue.main.async {
                    StateViolationDetector.shared.exitViewUpdate(viewName: "\(viewName).onAppear")
                }
            }
            .onDisappear {
                StateViolationDetector.shared.enterViewUpdate(viewName: "\(viewName).onDisappear")
                DispatchQueue.main.async {
                    StateViolationDetector.shared.exitViewUpdate(viewName: "\(viewName).onDisappear")
                }
            }
    }
}

extension View {
    func trackViewUpdates(name: String) -> some View {
        self.modifier(ViewUpdateTracker(viewName: name))
    }
}

/// Macro to easily log state changes with automatic location capture
func logStateChange<T>(
    _ newValue: T,
    to stateVar: inout T,
    property: String,
    viewType: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    StateViolationDetector.shared.logStateModification(
        property: property,
        value: newValue,
        viewType: viewType,
        file: file,
        function: function,
        line: line
    )
    stateVar = newValue
}

#endif
