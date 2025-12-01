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

    var body: some Scene {
            WindowGroup {
                LoginView()
            }
        }
}
