//
//  BugtopiaApp.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import SwiftUI
import os.log

@main
struct BugtopiaApp: App {
    
    init() {
        // Enable SwiftUI state debugging with stack traces
        setenv("IDESwiftUIStateDebug", "1", 1)
        setenv("SWIFTUI_DEBUG", "1", 1)
        
        // 🔍 Enhanced debugging for state modification warnings
        setenv("SWIFTUI_ENABLE_STATE_DEBUG", "1", 1)
        setenv("SWIFTUI_ENABLE_VIEW_DEBUG", "1", 1)
        setenv("OS_ACTIVITY_MODE", "enable", 1)
        
        // Configure custom logging to capture stack traces
//        setupStateModificationDebugging()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupStateModificationDebugging() {
        // Enable enhanced debugging for state modification issues
        // Note: Custom print overrides are not supported in Swift
        // Instead, we rely on environment variables and SwiftUI debugging flags
        print("🔍 Bugtopia Debug Mode: State modification debugging enabled")
        print("🔧 Environment variables set for enhanced SwiftUI debugging")
        
        // 📍 STACK TRACE INSTRUCTIONS:
        print("📍 To enable stack traces for state modification warnings:")
        print("   1. In Xcode, go to Debug Navigator (⌘+7)")
        print("   2. Set symbolic breakpoint on: -[UIView(AdditionalLayoutSupport) _is_layout]")
        print("   3. Set symbolic breakpoint on: -[NSView _postViewUpdateActions]")
        print("   4. Add breakpoint condition: (BOOL)[[$arg2 description] containsString:@\"state\"]")
        print("   5. Run with Debug → Capture View Hierarchy for visual debugging")
        print("🚨 If you see state modification warnings, use the breakpoints above to trace them")
    }
}
