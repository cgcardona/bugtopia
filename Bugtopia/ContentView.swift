//
//  ContentView.swift
//  Bugtopia
//
//  Created by Gabriel Cardona on 7/31/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            // Sidebar for future features like saved simulations, presets, etc.
            VStack(alignment: .leading, spacing: 16) {
                Text("🧬 Bugtopia")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Text("Evolutionary Simulation")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Features:")
                        .font(.headline)
                        .padding(.top)
                    
                    Label("Genetic Algorithm", systemImage: "dna")
                    Label("Real-time Evolution", systemImage: "timer")
                    Label("Interactive Controls", systemImage: "gamecontroller")
                    Label("Performance Statistics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .font(.subheadline)
                
                Spacer()
                
                Text("Click bugs to inspect their DNA and watch evolution in action!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(minWidth: 250)
        } detail: {
            SimulationView()
        }
        .navigationSplitViewStyle(.balanced)
    }
}
