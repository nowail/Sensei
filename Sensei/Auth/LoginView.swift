import SwiftUI

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

// MARK: - Login View
struct LoginView: View {
    
    @State private var email = ""
    @State private var password = ""
    
    @StateObject var viewModel = AuthViewModel()
    @State private var isSignedIn = false
    
    let backgroundGreen = Color(#colorLiteral(red: 0.067, green: 0.102, blue: 0.094, alpha: 1))
    let cardGreen = Color(#colorLiteral(red: 0.118, green: 0.161, blue: 0.15, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.345, green: 0.576, blue: 0.451, alpha: 1))
    
    var body: some View {
        Group {
            if isSignedIn {
                HomeView(userName: viewModel.userName)
            } else {
        NavigationStack {
            ZStack {
                backgroundGreen.ignoresSafeArea()
                
                VStack(spacing: 36) {
                    
                    Spacer().frame(height: 60)
                    
                    VStack(spacing: 6) {
                        Text("SENSEI")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Login to continue")
                            .foregroundColor(.white.opacity(0.55))
                            .font(.system(size: 15))
                    }
                    
                    VStack(spacing: 22) {
                        
                        forestTextField(placeholder: "Email", text: $email, icon: "envelope")
                        forestSecureField(placeholder: "Password", text: $password, icon: "lock")
                        
                        HStack {
                            Spacer()
                            Button("Forgot password?") {}
                                .foregroundColor(accentGreen)
                        }
                        
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
                        
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.12))
                            Text("or").foregroundColor(.white.opacity(0.4))
                            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.12))
                        }
                        
                        // MARK: Google Login
                        Button(action: {
                            viewModel.signInWithGoogle { success in
                                if success {
                                    isSignedIn = true
                                }
                            }
                        }) {
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
                        }
                    }
                    .padding()
                    .background(cardGreen.opacity(0.9))
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
