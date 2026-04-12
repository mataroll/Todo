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
                    Label("לוח בלש", image: "BoardIcon")
                }

            MoneyView()
                .tabItem {
                    Label("כסף", systemImage: "banknote")
                }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseService.shared)
}
