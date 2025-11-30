//
//  SenseiApp.swift
//  Sensei
//
//  Created by Dev on 30/11/2025.
//

import SwiftUI

@main
struct SenseiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
