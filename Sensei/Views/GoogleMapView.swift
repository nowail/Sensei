import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var showsUserLocation: Bool
    
    func makeUIView(context: Context) -> GMSMapView {
        // Default to user's location or a default location (Islamabad, Pakistan)
        let defaultLatitude: CLLocationDegrees = 33.6844
        let defaultLongitude: CLLocationDegrees = 73.0479
        
        let camera = GMSCameraPosition.camera(
            withLatitude: locationManager.location?.coordinate.latitude ?? defaultLatitude,
            longitude: locationManager.location?.coordinate.longitude ?? defaultLongitude,
            zoom: 15.0
        )
        
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.isMyLocationEnabled = showsUserLocation
        mapView.settings.myLocationButton = showsUserLocation
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        
        // Style: Dark theme to match app
        do {
            if let styleURL = Bundle.main.url(forResource: "map_style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }
        } catch {
            print("⚠️ Could not load map style: \(error)")
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update camera position when location changes
        if let location = locationManager.location {
            let camera = GMSCameraPosition.camera(
                withTarget: location.coordinate,
                zoom: mapView.camera.zoom
            )
            mapView.animate(to: camera)
        }
        
        mapView.isMyLocationEnabled = showsUserLocation
        mapView.settings.myLocationButton = showsUserLocation
    }
}

// MARK: - Map View Wrapper with Permission Handling
struct MapViewContainer: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var showsUserLocation = true
    @State private var showPermissionAlert = false
    
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
            
            GoogleMapView(locationManager: locationManager, showsUserLocation: $showsUserLocation)
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
            // Request permission - the delegate callback will handle starting location updates
            // Don't check authorizationStatus here - it will be updated by the callback
            locationManager.requestPermission()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            // When permission is granted via callback, start location updates
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

