import SwiftUI

struct MapScreen: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var centerOnLocation = false
    
    var body: some View {
        // Note: No NavigationStack here - we're already in HomeView's NavigationStack
        // This prevents nested NavigationStack issues
        MapViewContainer(centerOnUserLocation: $centerOnLocation)
                .navigationTitle("Map")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                        // Center map on user location
                        print("📍 Location button tapped")
                        if locationManager.authorizationStatus == .authorizedWhenInUse || 
                           locationManager.authorizationStatus == .authorizedAlways {
                            // Ensure location is being updated
                            locationManager.startUpdatingLocation()
                            
                            // Check if location is available
                            if let location = locationManager.location {
                                print("📍 Current location available: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                            } else {
                                print("📍 Location not available yet, will wait for update...")
                            }
                            
                            // Trigger map to center on location
                            centerOnLocation = true
                            print("📍 Set centerOnLocation = true")
                        } else {
                            // Request permission first
                            print("📍 Requesting location permission...")
                            locationManager.requestPermission()
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .foregroundColor(Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1)))
                    }
                }
        }
    }
}

#Preview {
    MapScreen()
}

