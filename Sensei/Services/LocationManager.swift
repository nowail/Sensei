import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        
        // Don't check authorizationStatus synchronously - wait for delegate callback
        // This prevents UI unresponsiveness warnings
        // The locationManagerDidChangeAuthorization will be called automatically
        // and will update authorizationStatus properly
        
        // Check if location services are enabled
        if !CLLocationManager.locationServicesEnabled() {
            errorMessage = "Location services are disabled. Please enable them in Settings."
        }
    }
    
    func requestPermission() {
        // Request permission asynchronously to avoid blocking UI
        // Don't check authorizationStatus here - let the delegate callback handle state
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        // Check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are disabled. Please enable them in Settings."
            print("❌ Location services are disabled")
            return
        }
        
        // Don't check authorizationStatus synchronously here
        // The delegate callback will start updates when permission is granted
        // Just start updating - CLLocationManager will handle authorization internally
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        self.errorMessage = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        
        switch clError?.code {
        case .denied:
            self.errorMessage = "Location access denied. Please enable it in Settings."
            stopUpdatingLocation()
        case .locationUnknown:
            // Location is unknown - this is temporary, don't show error
            // The location manager will keep trying
            print("⚠️ Location unknown, will retry...")
            // Don't set errorMessage for this - it's a temporary state
        case .network:
            self.errorMessage = "Network error. Please check your connection."
            stopUpdatingLocation()
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
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // This callback is called automatically when authorization changes
        // This is the ONLY place we should check authorization status
        // Never check it synchronously - always wait for this callback
        let newStatus = manager.authorizationStatus
        authorizationStatus = newStatus
        
        switch newStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            // Start updating location now that we have permission
            if CLLocationManager.locationServicesEnabled() {
                // Small delay to ensure everything is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.locationManager.startUpdatingLocation()
                }
            }
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable it in Settings."
            stopUpdatingLocation()
        case .notDetermined:
            // Status is not determined - don't do anything here
            // The view will call requestPermission() when needed
            break
        @unknown default:
            break
        }
    }
}

