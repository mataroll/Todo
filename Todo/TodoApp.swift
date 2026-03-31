//
//  TodoApp.swift
//  Todo
//
//  Created by Matar Roll on 29/03/2026.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct TodoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var firebaseService = FirebaseService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseService)
                .onAppear {
                    firebaseService.startListening()
                }
        }
    }
}
