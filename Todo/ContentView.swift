//
//  ContentView.swift
//  Todo
//
//  Created by Matar Roll on 29/03/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var service: FirebaseService

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("דף הבית", systemImage: "house.fill")
                }

            BoardView()
                .tabItem {
                    Label("רשימה", systemImage: "list.bullet")
                }

            DetectiveBoardView()
                .tabItem {
                    Label("לוח בלש", systemImage: "pin.map.fill")
                }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseService.shared)
}
