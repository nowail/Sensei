import SwiftUI

struct LoginView: View {
    
    @State private var email = ""
    @State private var password = ""
    
    // MARK: - Soft Forest Colors
    let backgroundGreen = Color(#colorLiteral(red: 0.067, green: 0.102, blue: 0.094, alpha: 1))   // #112A23 deep forest
    let cardGreen = Color(#colorLiteral(red: 0.118, green: 0.161, blue: 0.15, alpha: 1))          // #1E3328 matte card
    let accentGreen = Color(#colorLiteral(red: 0.345, green: 0.576, blue: 0.451, alpha: 1))       // #588F73 muted accent
    
    var body: some View {
        
        ZStack {
            // MARK: - Background Color
            backgroundGreen
                .ignoresSafeArea()
            
            VStack(spacing: 36) {
                
                Spacer().frame(height: 60)
                
                // MARK: - Title
                VStack(spacing: 6) {
                    Text("SENSEI")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Login to continue")
                        .foregroundColor(.white.opacity(0.55))
                        .font(.system(size: 15))
                }
                
                
                // MARK: - Card Section
                VStack(spacing: 22) {
                    
                    // MARK: - Email Field
                    forestTextField(
                        placeholder: "Email",
                        text: $email,
                        icon: "envelope"
                    )
                    
                    // MARK: - Password Field
                    forestSecureField(
                        placeholder: "Password",
                        text: $password,
                        icon: "lock"
                    )
                    
                    // MARK: - Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot password?") { }
                            .foregroundColor(accentGreen)
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    // MARK: - Login Button
                    Button(action: {}) {
                        Text("Log In")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(backgroundGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentGreen)
                            .cornerRadius(14)
                    }
                    .padding(.top, 10)
                    
                    // MARK: - Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.12))
                        Text("or")
                            .foregroundColor(.white.opacity(0.4))
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.12))
                    }
                    
                    // MARK: - Google Login Button
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image("google-icon")
                                .resizable()
                                .frame(width: 22, height: 22)
                            
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(cardGreen.opacity(0.9))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                }
                .padding()
                .background(cardGreen.opacity(0.9))
                .cornerRadius(24)
                .padding(.horizontal, 20)
                
                
                Spacer()
                
                // MARK: - Sign Up
                HStack {
                    Text("Don’t have an account?")
                        .foregroundColor(.white.opacity(0.55))
                    Button("Sign Up") {}
                        .foregroundColor(accentGreen)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.bottom, 24)
            }
        }
    }
}


// MARK: - Forest TextField
func forestTextField(placeholder: String, text: Binding<String>, icon: String) -> some View {
    HStack(spacing: 12) {
        
        Image(systemName: icon)
            .foregroundColor(.white.opacity(0.45))
        
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.30))
                    .font(.system(size: 15))
            }
            
            TextField("", text: text)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .cornerRadius(14)
    .overlay(
        RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
    )
}


// MARK: - Forest SecureField
func forestSecureField(placeholder: String, text: Binding<String>, icon: String) -> some View {
    HStack(spacing: 12) {
        
        Image(systemName: icon)
            .foregroundColor(.white.opacity(0.45))
        
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.30))
                    .font(.system(size: 15))
            }
            
            SecureField("", text: text)
                .foregroundColor(.white)
        }
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .cornerRadius(14)
    .overlay(
        RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
    )
}


#Preview {
    LoginView()
}
