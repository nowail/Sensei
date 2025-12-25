//
//  SenseiApp.swift
//  Sensei
//
//  Created by Dev on 30/11/2025.
//

import SwiftUI

@main
struct SenseiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let persistenceController = PersistenceController.shared

    init() {
        // Load .env file on app startup
        _ = EnvLoader.shared
    }

    var body: some Scene {
            WindowGroup {
                // TEMPORARY: Start directly from Dashboard (skip login)
                // TODO: Revert to LoginView() when done testing
                MainTabView(userName: "Test User", userId: "test@sensei.com")
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
}
