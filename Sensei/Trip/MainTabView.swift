import SwiftUI
import UIKit

struct MainTabView: View {
    let userName: String
    let userId: String
    
    @State private var selectedTab = 0
    
    init(userName: String, userId: String) {
        self.userName = userName
        self.userId = userId
        
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(userName: userName, userId: userId)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Personal Expenses Tab
            PersonalExpensesView(userId: userId)
                .tabItem {
                    Label("Expenses", systemImage: "creditcard.fill")
                }
                .tag(1)
            
            // Profile Tab
            ProfileView(userName: userName, userId: userId)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))) // Deep green accent
    }
}

