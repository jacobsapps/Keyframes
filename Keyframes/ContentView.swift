//
//  ContentView.swift
//  Keyframes
//
//  Created by Jacob Bartlett on 01/08/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WeightlifterView()
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("Weightlifter")
                }
            
            MapKeyframeView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            ProgressBarView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Progress")
                }
            
            DNA3DView()
                .tabItem {
                    Image(systemName: "person.and.background.striped.horizontal")
                    Text("3D DNA")
                }
        }
    }
}

#Preview {
    ContentView()
}
