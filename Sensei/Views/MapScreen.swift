import SwiftUI

struct MapScreen: View {
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        NavigationStack {
            MapViewContainer()
                .navigationTitle("Map")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            // Center on user location
                            if let location = locationManager.location {
                                // This will be handled by the map view update
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .foregroundColor(Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1)))
                        }
                    }
                }
        }
    }
}

#Preview {
    MapScreen()
}

