//
//  ContentView.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import SwiftUI

struct ContentView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar is intentionally left blank to be hidden by default.
            // All statistics and controls are now part of the SimulationView.
            Text("")
        } detail: {
            SimulationView()
        }
        .navigationSplitViewStyle(.balanced)
    }
}
