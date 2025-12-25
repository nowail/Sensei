import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private var isUpdatingLocation = false  // Track if location updates are already running
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone // Update on any movement
        locationManager.pausesLocationUpdatesAutomatically = false // Don't pause updates
        locationManager.allowsBackgroundLocationUpdates = false // We only need foreground location
        locationManager.activityType = .otherNavigation // Optimize for navigation-like usage
        
        // Don't check authorizationStatus synchronously - wait for delegate callback
        // This prevents UI unresponsiveness warnings
        // The locationManagerDidChangeAuthorization will be called automatically
        // and will update authorizationStatus properly
        
        // Note: We never call locationManager.authorizationStatus directly
        // The locationManagerDidChangeAuthorization delegate method will be called
        // automatically when the location manager is ready, and it will update
        // our @Published authorizationStatus property safely
        // Location services check will be done when needed (in startUpdatingLocation)
    }
    
    func requestPermission() {
        // Request permission asynchronously to avoid blocking UI
        // Don't check authorizationStatus here - let the delegate callback handle state
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        // Prevent duplicate calls - if already updating, don't start again
        if isUpdatingLocation {
            print("⚠️ Location updates already running - skipping duplicate call")
            return
        }
        
        // This method should only be called after authorization is granted
        // The delegate callback will call this automatically when permission is granted
        // We check authorizationStatus from the @Published property (updated by delegate callback)
        // This avoids synchronous authorization checks
        
        // Only start if we're already authorized (from the published property, not direct check)
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // Start location updates
            // Note: locationServicesEnabled() is a static method that just checks system settings
            // It doesn't check authorization status, so the warning is a false positive
            // We'll let the location manager handle errors if services are disabled
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard !self.isUpdatingLocation else {
                    print("⚠️ Location updates already running - skipping")
                    return
                }
                
                // Check if location services are enabled at system level
                if !CLLocationManager.locationServicesEnabled() {
                    print("❌ CRITICAL: Location services are DISABLED in iOS Settings")
                    print("   Go to: Settings → Privacy → Location Services → Turn ON")
                    self.errorMessage = "Location services are disabled. Please enable them in Settings → Privacy → Location Services"
                    return
                }
                
                self.isUpdatingLocation = true
                print("🔄 Starting location updates...")
                print("   - Authorization status: \(self.authorizationStatus.rawValue)")
                print("   - Location services: ENABLED ✅")
                print("   - Current location: \(self.location?.coordinate.latitude ?? 0), \(self.location?.coordinate.longitude ?? 0)")
                print("   - Desired accuracy: \(self.locationManager.desiredAccuracy)")
                print("   - Distance filter: \(self.locationManager.distanceFilter)")
                
                // Start continuous location updates
                self.locationManager.startUpdatingLocation()
                print("   - ✅ startUpdatingLocation() called")
                
                // Also request a one-time location update for immediate results
                // This can help get location faster, especially on first load
                print("   - Requesting one-time location update...")
                self.locationManager.requestLocation()
                print("   - ✅ requestLocation() called")
            }
        } else {
            // If not authorized, request permission first
            // The delegate callback will start updates after authorization
            print("⚠️ Cannot start location updates - not authorized (status: \(authorizationStatus.rawValue))")
            requestPermission()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isUpdatingLocation = false
        print("🛑 Stopped location updates")
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { 
            print("⚠️ didUpdateLocations called but no location in array")
            return 
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let wasNil = self.location == nil
            self.location = location
            self.errorMessage = nil
            
            print("✅ Location updated successfully: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("   Accuracy: \(location.horizontalAccuracy) meters")
            print("   Timestamp: \(location.timestamp)")
            
            // If this is the first location we've received, log it prominently
            if wasNil {
                print("🎯 FIRST LOCATION RECEIVED - Blue dot should appear now!")
                print("📍 Map should center on: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch clError?.code {
            case .denied:
                self.errorMessage = "Location access denied. Please enable it in Settings."
                print("❌ Location access denied")
                self.stopUpdatingLocation()
            case .locationUnknown:
                // Location is unknown - this is temporary, don't show error
                // The location manager will keep trying
                print("⚠️ Location unknown, will retry...")
                print("   This is NORMAL - GPS needs time to get a fix")
                print("   💡 SIMULATOR: Simulator → Features → Location → Custom Location")
                print("   💡 DEVICE: Go outdoors, wait 10-30 seconds")
                // Don't set errorMessage for this - it's a temporary state
            case .network:
                self.errorMessage = "Network error. Please check your connection."
                print("❌ Network error getting location")
                self.stopUpdatingLocation()
            case .headingFailure:
                // Ignore heading failures
                break
            default:
                // Only show error for significant failures
                if clError?.code != .locationUnknown {
                    self.errorMessage = error.localizedDescription
                    print("❌ Location error: \(error.localizedDescription), code: \(clError?.code.rawValue ?? -1)")
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // This callback is called automatically when authorization changes
        // This is the ONLY place we should check authorization status
        // Never check it synchronously - always wait for this callback
        // Note: This delegate method is already called on the main thread by the system
        // Accessing authorizationStatus here is safe and is the recommended approach
        let newStatus = manager.authorizationStatus
        authorizationStatus = newStatus
        updateLocationBasedOnAuthorization(newStatus)
    }
    
    private func updateLocationBasedOnAuthorization(_ newStatus: CLAuthorizationStatus) {
        switch newStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            print("✅ Location permission granted - starting location updates")
            // Start updating location now that we have permission
            // Use startUpdatingLocation() which handles location services check internally
            // Small delay to ensure everything is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.startUpdatingLocation()
            }
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable it in Settings."
            print("❌ Location access denied or restricted")
            stopUpdatingLocation()
        case .notDetermined:
            // Status is not determined - don't do anything here
            // The view will call requestPermission() when needed
            print("⏳ Location permission not determined yet")
            break
        @unknown default:
            break
        }
    }
}

