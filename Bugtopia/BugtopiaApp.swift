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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
