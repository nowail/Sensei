import SwiftUI

struct WelcomeView: View {
    let userName: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Welcome")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text(userName.isEmpty ? "Nice to see you 👋" : userName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    WelcomeView(userName: "Pehlaj")
}
