import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var showsUserLocation: Bool
    @Binding var centerOnUserLocation: Bool  // Trigger to center map on user location
    
    func makeUIView(context: Context) -> GMSMapView {
        // Default to user's location or a default location (Islamabad, Pakistan)
        let defaultLatitude: CLLocationDegrees = 33.6844
        let defaultLongitude: CLLocationDegrees = 73.0479
        
        let camera = GMSCameraPosition.camera(
            withLatitude: locationManager.location?.coordinate.latitude ?? defaultLatitude,
            longitude: locationManager.location?.coordinate.longitude ?? defaultLongitude,
            zoom: 15.0
        )
        
        // Create map view - trying without Map ID first to isolate the issue
        // If basic map works, we can add Map ID back
        // Map ID: dafb81ca5bfb5b01a2ee3dcb (available if needed)
        
        // Option 1: Basic map without Map ID (try this first)
        let mapView = GMSMapView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), camera: camera)
        print("🗺️ Created map view WITHOUT Map ID (testing basic functionality)")
        
        // Option 2: Map with Map ID (uncomment if basic map works)
        // let mapID = GMSMapID(identifier: "dafb81ca5bfb5b01a2ee3dcb")
        // let mapView = GMSMapView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), mapID: mapID, camera: camera)
        // print("🗺️ Created map view WITH Map ID: dafb81ca5bfb5b01a2ee3dcb")
        
        // Only enable location features if permission is already granted
        // This prevents the SDK from checking permissions synchronously
        // We'll update this in updateUIView when permissions change
        // Note: Accessing @Published authorizationStatus is safe - it's updated by delegate callback
        let hasPermission = locationManager.authorizationStatus == .authorizedWhenInUse || 
                            locationManager.authorizationStatus == .authorizedAlways
        // Enable location features if permission is granted
        // The built-in location button will handle centering on user location
        mapView.isMyLocationEnabled = showsUserLocation && hasPermission
        mapView.settings.myLocationButton = showsUserLocation && hasPermission  // Enable built-in location button
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        
        // API key should already be set in AppDelegate
        // If the map view is created successfully, the API key is valid
        // We can't directly access the API key from GMSServices, but if we get here,
        // it means the map was initialized successfully
        print("✅ Google Map view created successfully (API key was set in AppDelegate)")
        print("📍 Map camera position: lat=\(camera.target.latitude), lng=\(camera.target.longitude), zoom=\(camera.zoom)")
        print("📐 Map view frame: \(mapView.frame)")
        
        // Set delegate - coordinator is created by makeCoordinator()
               mapView.delegate = context.coordinator
               context.coordinator.mapView = mapView
               print("🔧 Map delegate set to coordinator")
        
        return mapView
    }
    
           func makeCoordinator() -> Coordinator {
               let coordinator = Coordinator()
               coordinator.parent = self
               print("🔧 Map coordinator created")
               return coordinator
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update coordinator's map view reference
        context.coordinator.mapView = mapView
        context.coordinator.parent = self
        
        // Note: Don't call startUpdatingLocation() here - it's already called in:
        // 1. MapViewContainer.onAppear
        // 2. LocationManager.updateLocationBasedOnAuthorization (when permission is granted)
        // Calling it here causes duplicate calls
        // The location manager will handle starting updates when permission is granted
        
        // Check if we have location permission
        let hasPermission = locationManager.authorizationStatus == .authorizedWhenInUse || 
                            locationManager.authorizationStatus == .authorizedAlways
        
        // Center map on user location when button is clicked
        if centerOnUserLocation {
            print("📍 centerOnUserLocation triggered - attempting to center map")
            // Location updates should already be running from onAppear or authorization callback
            // Don't call startUpdatingLocation() here to avoid duplicate calls
            
            // Try to center immediately if location is available
            if let location = locationManager.location {
                context.coordinator.centerMapOnLocation(location)
                
                // Reset the trigger
                DispatchQueue.main.async {
                    self.centerOnUserLocation = false
                }
            } else {
                // If location not available, mark that we should center when it becomes available
                context.coordinator.shouldCenterOnLocation = true
                print("📍 Location not available yet, will center when location updates...")
            }
        }
        
        // Always enable location features if permission is granted
        // This shows the blue location marker (the dot that shows your current location)
        // IMPORTANT: The blue dot will appear automatically when isMyLocationEnabled = true
        // The Google Maps SDK will handle getting the location and showing the dot
        let shouldEnable = showsUserLocation && hasPermission
        if mapView.isMyLocationEnabled != shouldEnable {
            mapView.isMyLocationEnabled = shouldEnable
            mapView.settings.myLocationButton = shouldEnable
            print("📍 Location features \(shouldEnable ? "ENABLED" : "DISABLED")")
            print("   - Blue location dot: \(shouldEnable ? "SHOULD BE VISIBLE (SDK will show it)" : "hidden")")
            print("   - Location button: \(shouldEnable ? "enabled" : "disabled")")
            print("   - Permission status: \(locationManager.authorizationStatus.rawValue)")
            print("   - Has location: \(locationManager.location != nil ? "YES" : "NO")")
            print("   - isMyLocationEnabled on map: \(mapView.isMyLocationEnabled)")
        }
        
        // Force enable if permission is granted (sometimes the SDK needs this)
        if hasPermission {
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
        
        // Automatically center on user location when it first becomes available
        // This ensures the map shows the user's location even if they haven't clicked the button
        if let location = locationManager.location {
            // Always center on first location, or if we're waiting to center
            let shouldCenter = context.coordinator.lastCenteredLocation == nil || context.coordinator.shouldCenterOnLocation
            if shouldCenter {
                context.coordinator.centerMapOnLocation(location)
                context.coordinator.shouldCenterOnLocation = false
                context.coordinator.lastCenteredLocation = location
                print("📍 ✅ Auto-centered map on user location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        } else {
            print("⚠️ No location available yet - authorization: \(locationManager.authorizationStatus.rawValue)")
        }
    }
    
    // MARK: - Coordinator for Map Delegate
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView?
        weak var mapView: GMSMapView?
        var shouldCenterOnLocation = false
        var lastCenteredLocation: CLLocation?  // Track last centered location to avoid unnecessary updates
        
        func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
            print("✅ Map tiles finished rendering successfully - Map is working!")
            self.mapView = mapView
        }
        
        func centerMapOnLocation(_ location: CLLocation) {
            guard let mapView = mapView else {
                print("⚠️ Cannot center map - mapView is nil")
                return
            }
            let camera = GMSCameraPosition.camera(
                withTarget: location.coordinate,
                zoom: 15.0
            )
            mapView.animate(to: camera)
            lastCenteredLocation = location
            print("📍 ✅ Centered map on user location: \(location.coordinate.latitude), \(location.coordinate.longitude), zoom: 15.0")
        }
        
        func mapView(_ mapView: GMSMapView, didFailToLoadWithError error: Error) {
            print("❌ Map failed to load tiles: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain), code: \(nsError.code)")
                print("   User info: \(nsError.userInfo)")
                
                // Common error codes:
                // - 2: Invalid API key
                // - 7: API not enabled
                // - 8: Quota exceeded
                if nsError.code == 2 {
                    print("   ⚠️ ERROR: Invalid API key or Maps SDK for iOS not enabled")
                    print("   💡 SOLUTION: Go to Google Cloud Console → Enable 'Maps SDK for iOS'")
                } else if nsError.code == 7 {
                    print("   ⚠️ ERROR: Maps SDK for iOS API is not enabled")
                    print("   💡 SOLUTION: Google Cloud Console → APIs & Services → Enable 'Maps SDK for iOS'")
                }
            }
        }
        
        func mapView(_ mapView: GMSMapView, didChange cameraPosition: GMSCameraPosition) {
            // Optional: Log camera changes for debugging
        }
        
        func mapViewDidStartTileRendering(_ mapView: GMSMapView) {
            print("🔄 Map started rendering tiles... - This means Maps SDK is working!")
        }
        
        func mapViewSnapshotReady(_ mapView: GMSMapView) {
            print("📸 Map snapshot ready")
        }
        
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            print("📍 Map camera idle at: \(position.target.latitude), \(position.target.longitude)")
            
            // Check if tiles are loading after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // If we get here and no tiles rendered, it's likely Maps SDK not enabled
                print("⏰ 2 seconds passed - checking if tiles loaded...")
                // The didFinishTileRendering should have fired by now if SDK is enabled
            }
        }
    }
}

// MARK: - Map View Wrapper with Permission Handling
struct MapViewContainer: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var showsUserLocation = true
    @State private var showPermissionAlert = false
    @Binding var centerOnUserLocation: Bool  // Trigger to center map (passed from parent)
    @State private var pendingCenter = false  // Track if we're waiting to center
    
    init(centerOnUserLocation: Binding<Bool> = .constant(false)) {
        self._centerOnUserLocation = centerOnUserLocation
    }
    
    let bgGradient = LinearGradient(
        colors: [
            Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)),
            Color(#colorLiteral(red: 0.07, green: 0.12, blue: 0.11, alpha: 1))
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()
            
            // Always show the map - it will work even without location permissions
            // The map will just show without user location features if permission is denied
            GoogleMapView(
                locationManager: locationManager,
                showsUserLocation: $showsUserLocation,
                centerOnUserLocation: $centerOnUserLocation
            )
            .onAppear {
                // Start location updates when map appears
                print("🗺️ Map view appeared - starting location updates")
                locationManager.startUpdatingLocation()
            }
            .onChange(of: centerOnUserLocation) { newValue in
                if newValue {
                    pendingCenter = true
                    locationManager.startUpdatingLocation()
                }
            }
            .onChange(of: locationManager.location) { newLocation in
                // When location becomes available, ensure map centers on it
                if let location = newLocation {
                    print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    // Always center on location when it first becomes available
                    if !pendingCenter {
                        // Force map to update and center
                        DispatchQueue.main.async {
                            centerOnUserLocation = true
                        }
                    } else {
                        pendingCenter = false
                        // Force update by toggling the binding
                        DispatchQueue.main.async {
                            centerOnUserLocation = false
                            centerOnUserLocation = true
                        }
                    }
                }
            }
            .onChange(of: locationManager.authorizationStatus) { newStatus in
                print("📍 Authorization status changed: \(newStatus.rawValue)")
                // When permission is granted, start location updates and center
                if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                    locationManager.startUpdatingLocation()
                    // Center on location once it's available
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let location = locationManager.location {
                            centerOnUserLocation = true
                        }
                    }
                }
            }
                .ignoresSafeArea()
            
            // Permission prompt overlay
            // Use onChange to update UI based on authorization changes (not synchronous check)
            if locationManager.authorizationStatus == .notDetermined {
                VStack(spacing: 16) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    
                    Text("Enable Location")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Sensei needs your location to show your position on the map and provide location-based travel recommendations.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button {
                        locationManager.requestPermission()
                    } label: {
                        Text("Allow Location Access")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1)))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1)))
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                )
                .padding(.horizontal, 20)
            }
            
            // Error message overlay
            if let errorMessage = locationManager.errorMessage,
               locationManager.authorizationStatus == .denied {
                VStack(spacing: 12) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red.opacity(0.8))
                    
                    Text("Location Access Denied")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1)))
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1)))
                )
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            // Request permission if not already determined
            // The map will show regardless, but we want to request permission for location features
            if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
            } else if locationManager.authorizationStatus == .authorizedWhenInUse || 
                      locationManager.authorizationStatus == .authorizedAlways {
                // Already authorized - start location updates
                locationManager.startUpdatingLocation()
            }
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            // When permission is granted, start location updates
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    locationManager.startUpdatingLocation()
                }
            }
        }
    }
}

#Preview {
    MapViewContainer()
}

