import SwiftUI

struct LoginView: View {
    
    @State private var email = ""
    
    // MARK: - Custom Colors
    let deepGreen = Color(#colorLiteral(red: 0.039, green: 0.078, blue: 0.071, alpha: 1))     // #0A1412
    let tealGlow = Color(#colorLiteral(red: 0.047, green: 0.329, blue: 0.282, alpha: 1))      // #0B3930
    let accentTeal = Color(#colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1))    // #4EC8A8
    
    var body: some View {
        ZStack {
            // Background
            deepGreen
                .ignoresSafeArea()
            
            // Soft teal glow
            Circle()
                .fill(accentTeal.opacity(0.18))
                .blur(radius: 160)
                .offset(x: -140, y: -240)
            
            VStack(spacing: 22) {
                
                VStack(spacing: 6) {
                    Text("Welcome back")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Sign in to your account")
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.top, 10)
                
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 14))
                    
                    HStack {
                        TextField("username@gmail.com", text: $email)
                            .foregroundColor(.white)
                            .keyboardType(.emailAddress)
                        
                        // Check button
                        ZStack {
                            Circle()
                                .fill(accentTeal)
                                .frame(width: 34, height: 34)
                                .shadow(color: accentTeal.opacity(0.6), radius: 16)
                            
                            Image(systemName: "checkmark")
                                .foregroundColor(deepGreen)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .cornerRadius(16)
                }
                
                Text("or")
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 4)
                
                // Social Buttons
                socialButton(icon: "globe", text: "Continue with Google")
                socialButton(icon: "xmark", text: "Continue with X")
                
                // Sign up
                HStack {
                    Text("Don’t have an account?")
                        .foregroundColor(.white.opacity(0.45))
                    Button(action: {}) {
                        Text("Sign up")
                            .foregroundColor(accentTeal)
                    }
                }
                .font(.system(size: 14))
                .padding(.top, 6)
                
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(Color.white.opacity(0.06))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 36)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Social Login Button
    func socialButton(icon: String, text: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.9))
                Text(text)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
}

#Preview {
    LoginView()
}
