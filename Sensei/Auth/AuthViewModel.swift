import SwiftUI
import FirebaseAuth
import GoogleSignIn

class AuthViewModel: ObservableObject {

    @Published var user: User?
    @Published var userName: String = ""
    @Published var userId: String = ""  // Track current user ID
    
    init() {
        self.user = Auth.auth().currentUser
        self.userName = user?.displayName ?? ""
        self.userId = user?.email ?? user?.uid ?? ""
    }
    
    // Single Google sign-in function with completion
    func signInWithGoogle(completion: @escaping (Bool) -> Void) {
        guard let presentingVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            print("❌ No root view controller found")
            completion(false)
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
            if let error = error {
                print("❌ Google sign-in error:", error.localizedDescription)
                completion(false)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("❌ Failed to get Google tokens")
                completion(false)
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("❌ Firebase sign-in error:", error.localizedDescription)
                    completion(false)
                    return
                }
                
                self.user = authResult?.user
                // Prefer Firebase displayName, fall back to Google profile name
                self.userName = authResult?.user.displayName ?? user.profile?.name ?? "User"
                self.userId = authResult?.user.email ?? authResult?.user.uid ?? ""
                
                // Create/update user in Supabase
                if let email = authResult?.user.email {
                    Task {
                        do {
                            try await SupabaseService.shared.upsertUser(
                                email: email,
                                name: self.userName
                            )
                            print("✅ User synced to Supabase: \(email)")
                        } catch {
                            print("⚠️ Error syncing user to Supabase: \(error)")
                        }
                    }
                }
                
                print("✅ SUCCESS: User is signed in:", authResult?.user.email ?? "")
                completion(true)
            }
        }
    }
}
