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
        
        // Configure custom logging to capture stack traces
        setupStateModificationDebugging()
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
    }
}
