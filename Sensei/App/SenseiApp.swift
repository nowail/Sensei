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

    var body: some Scene {
            WindowGroup {
                LoginView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
}
