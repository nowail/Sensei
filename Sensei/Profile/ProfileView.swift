import SwiftUI

struct ProfileView: View {
    let userName: String
    let userId: String
    
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showLogoutAlert = false
    
    let bgGradient = LinearGradient(
        colors: [
            Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)),
            Color(#colorLiteral(red: 0.07, green: 0.12, blue: 0.11, alpha: 1))
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgGradient.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Profile Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(accentGreen.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                Text(String(userName.prefix(1)).uppercased())
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(accentGreen)
                            }
                            
                            Text(userName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(userId)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        
                        // Account Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            profileRow(icon: "person.fill", title: "Edit Profile", action: {})
                            profileRow(icon: "bell.fill", title: "Notifications", action: {})
                            profileRow(icon: "lock.fill", title: "Privacy & Security", action: {})
                        }
                        
                        // App Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Settings")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            profileRow(icon: "globe", title: "Language", subtitle: "English", action: {})
                            profileRow(icon: "coloncurrencysign.circle.fill", title: "Currency", subtitle: "PKR", action: {})
                            profileRow(icon: "paintbrush.fill", title: "Theme", subtitle: "Dark", action: {})
                        }
                        
                        // About
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            profileRow(icon: "info.circle.fill", title: "Version", subtitle: "1.0.0", action: {})
                            profileRow(icon: "doc.text.fill", title: "Terms & Privacy", action: {})
                            profileRow(icon: "questionmark.circle.fill", title: "Help & Support", action: {})
                        }
                        
                        // Logout Button
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .padding(.top, 20)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    // TODO: Implement sign out
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private func profileRow(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(accentGreen)
                    .font(.system(size: 20))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 12))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.system(size: 14))
            }
            .padding()
            .background(cardColor)
            .cornerRadius(16)
        }
    }
}

#Preview {
    ProfileView(userName: "Test User", userId: "test@sensei.com")
}

