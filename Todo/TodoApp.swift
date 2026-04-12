import SwiftUI
import UIKit
import UserNotifications
import ActivityKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
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
                    firebaseService.fetchDailyLogs()
                    let nodes = firebaseService.nodes.isEmpty ? SeedData.getSeedNodes() : firebaseService.nodes
                    let rings = HomeView.buildRings(nodes: nodes)
                    LiveActivityManager.shared.update(rings: rings, nodes: nodes)
                }
                .onChange(of: firebaseService.nodes) { _, nodes in
                    let rings = HomeView.buildRings(nodes: nodes)
                    LiveActivityManager.shared.update(rings: rings, nodes: nodes)
                    firebaseService.saveTodayLog(nodes: nodes)
                }
        }
    }
}
