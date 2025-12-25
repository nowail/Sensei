import UIKit
import FirebaseCore
import GoogleSignIn
import GoogleMaps
import GooglePlaces

class AppDelegate: NSObject, UIApplicationDelegate {
    private static var isGoogleMapsInitialized = false
    private static var isGooglePlacesInitialized = false
    private static let initializationLock = NSLock()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FirebaseApp.configure()
        
        // Use lock to prevent race conditions during initialization
        Self.initializationLock.lock()
        defer { Self.initializationLock.unlock() }
        
        // Get API key
        var apiKey: String?
        if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
            apiKey = key
        } else if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let key = plist["API_KEY"] as? String {
            apiKey = key
        }
        
        guard let key = apiKey else {
            print("⚠️ Google Maps/Places API key not found")
            return true
        }
        
        // Initialize Google Maps (only once to avoid multiple instances warning)
        // This must be done before creating any GMSMapView instances
        if !Self.isGoogleMapsInitialized {
            GMSServices.provideAPIKey(key)
            Self.isGoogleMapsInitialized = true
            print("✅ Google Maps initialized with API key: \(String(key.prefix(15)))...")
        } else {
            print("⚠️ Google Maps already initialized - skipping to prevent multiple instances")
        }
        
        // Initialize Google Places (only once) - must be done before any GMSPlacesClient usage
        // This prevents the CCTClearcutUploader multiple instances warning
        if !Self.isGooglePlacesInitialized {
            GMSPlacesClient.provideAPIKey(key)
            Self.isGooglePlacesInitialized = true
            print("✅ Google Places initialized with API key: \(String(key.prefix(15)))...")
        } else {
            print("⚠️ Google Places already initialized - skipping to prevent multiple instances")
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
