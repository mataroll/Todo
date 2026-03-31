//
//  TodoApp.swift
//  Todo
//
//  Created by Matar Roll on 29/03/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import UserNotifications
import ActivityKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    let cache = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
    let settings = FirestoreSettings()
    settings.cacheSettings = cache
    Firestore.firestore().settings = settings
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
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
                .onChange(of: firebaseService.nodes) { _, nodes in
                    let rings = HomeView.buildRings(nodes: nodes)
                    LiveActivityManager.shared.update(rings: rings)
                }
        }
    }
}
