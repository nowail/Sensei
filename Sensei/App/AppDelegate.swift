import UIKit
import FirebaseCore
import GoogleSignIn
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate {
    private static var isGoogleMapsInitialized = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FirebaseApp.configure()
        
        // Initialize Google Maps (only once to avoid multiple instances warning)
        if !Self.isGoogleMapsInitialized {
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
                GMSServices.provideAPIKey(apiKey)
                Self.isGoogleMapsInitialized = true
                print("✅ Google Maps initialized with API key from Info.plist")
            } else if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                      let plist = NSDictionary(contentsOfFile: path),
                      let apiKey = plist["API_KEY"] as? String {
                GMSServices.provideAPIKey(apiKey)
                Self.isGoogleMapsInitialized = true
                print("✅ Google Maps initialized with API key from GoogleService-Info.plist")
            } else {
                print("⚠️ Google Maps API key not found")
            }
        }
        
        return true
    }

    // Handle Google Sign-In redirect
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        return GIDSignIn.sharedInstance.handle(url)
    }
}
