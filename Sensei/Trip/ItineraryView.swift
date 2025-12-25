import SwiftUI
import GoogleMaps
import CoreLocation

struct ItineraryView: View {
    @Binding var itinerary: Itinerary
    @State private var selectedDay: Int = 1
    @State private var mapView: GMSMapView?
    @State private var markers: [GMSMarker] = []
    @State private var polylines: [GMSPolyline] = []
    @State private var isGeocoding = false
    @Binding var isGenerating: Bool
    @Environment(\.dismiss) var dismiss
    
    init(itinerary: Binding<Itinerary>, isGenerating: Binding<Bool>) {
        self._itinerary = itinerary
        self._isGenerating = isGenerating
    }
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    let bgGradient = LinearGradient(
        colors: [
            Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)),
            Color(#colorLiteral(red: 0.07, green: 0.12, blue: 0.11, alpha: 1))
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var currentDay: ItineraryDay? {
        itinerary.days.first { $0.dayNumber == selectedDay }
    }
    
    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(itinerary.location)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(itinerary.numberOfDays) days • \(itinerary.priceRange) budget")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 28))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Day Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(1...itinerary.numberOfDays, id: \.self) { dayNum in
                                DayButton(
                                    dayNumber: dayNum,
                                    isSelected: selectedDay == dayNum,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedDay = dayNum
                                            updateMapMarkers()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)
                }
                .background(cardColor.opacity(0.95))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                
                // Map View - Larger and better positioned
                ZStack {
                    GoogleMapViewWithMarkers(
                        activities: currentDay?.activities ?? [],
                        onMapReady: { mapView in
                            self.mapView = mapView
                            updateMapMarkers()
                        }
                    )
                    .frame(height: 400)
                    .clipped()
                    
                    // Loading overlay for map
                    if isGeocoding {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: accentGreen))
                                .scaleEffect(1.2)
                            Text("Loading map...")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                    }
                }
                
                // Activities List
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if isGenerating {
                            // Loading State
                            VStack(spacing: 24) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: accentGreen))
                                    .scaleEffect(1.8)
                                
                                VStack(spacing: 8) {
                                    Text("Generating your itinerary...")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("This may take a moment")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 80)
                        } else if let day = currentDay, !day.activities.isEmpty {
                            Text("Activities")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            ForEach(day.activities) { activity in
                                ActivityCard(activity: activity) {
                                    // Center map on activity
                                    if let coordinate = activity.coordinate {
                                        mapView?.animate(to: GMSCameraPosition(
                                            target: coordinate,
                                            zoom: 15
                                        ))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        } else if !isGenerating {
                            VStack(spacing: 16) {
                                Image(systemName: "map")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("No activities found for this day")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(accentGreen)
            }
        }
        .onAppear {
            // Geocode city location immediately to show map
            Task {
                await geocodeCityLocation()
            }
            
            // Only geocode activities if itinerary is ready (not generating)
            if !isGenerating && !itinerary.days.isEmpty {
                Task {
                    await geocodeActivities()
                }
            }
        }
        .onChange(of: isGenerating) { generating in
            if !generating && !itinerary.days.isEmpty {
                Task {
                    await geocodeActivities()
                }
            }
        }
        .onChange(of: itinerary.days) { _ in
            // When itinerary days are updated, refresh markers
            if !isGenerating {
                updateMapMarkers()
            }
        }
        .onChange(of: selectedDay) { _ in
            updateMapMarkers()
        }
        .onChange(of: itinerary.days) { newDays in
            // When itinerary days are updated (activities generated), refresh everything
            if !isGenerating && !newDays.isEmpty {
                Task {
                    await geocodeActivities()
                }
            }
        }
    }
    
    func geocodeCityLocation() async {
        // Geocode the city location to show it on the map immediately
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(itinerary.location)
            if let placemark = placemarks.first,
               let coordinate = placemark.location?.coordinate {
                await MainActor.run {
                    // Center map on city location
                    if let mapView = mapView {
                        let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 12)
                        mapView.animate(to: camera)
                        print("📍 Map centered on city: \(itinerary.location)")
                    }
                }
            }
        } catch {
            print("⚠️ Geocoding failed for city location \(itinerary.location): \(error)")
        }
    }
    
    func geocodeActivities() async {
        isGeocoding = true
        let geocoder = CLGeocoder()
        var updatedDays: [ItineraryDay] = []
        
        // First, geocode the main location to get a center point (if not already done)
        var mainLocationCoordinate: CLLocationCoordinate2D?
        do {
            let placemarks = try await geocoder.geocodeAddressString(itinerary.location)
            if let placemark = placemarks.first,
               let coordinate = placemark.location?.coordinate {
                mainLocationCoordinate = coordinate
            }
        } catch {
            print("Geocoding failed for main location \(itinerary.location): \(error)")
        }
        
        for day in itinerary.days {
            var updatedActivities: [Activity] = []
            
            for activity in day.activities {
                var updatedActivity = activity
                
                // Only geocode if coordinates are missing
                if activity.latitude == nil || activity.longitude == nil {
                    // Try full address first
                    let address = "\(activity.location), \(itinerary.location)"
                    var geocoded = false
                    
                    do {
                        let placemarks = try await geocoder.geocodeAddressString(address)
                        if let placemark = placemarks.first,
                           let coordinate = placemark.location?.coordinate {
                            updatedActivity = Activity(
                                id: activity.id,
                                name: activity.name,
                                description: activity.description,
                                time: activity.time,
                                location: activity.location,
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude,
                                category: activity.category
                            )
                            geocoded = true
                        }
                    } catch {
                        print("Geocoding failed for \(activity.location): \(error)")
                    }
                    
                    // If geocoding failed, try just the activity location name
                    if !geocoded {
                        do {
                            let placemarks = try await geocoder.geocodeAddressString(activity.location)
                            if let placemark = placemarks.first,
                               let coordinate = placemark.location?.coordinate {
                                updatedActivity = Activity(
                                    id: activity.id,
                                    name: activity.name,
                                    description: activity.description,
                                    time: activity.time,
                                    location: activity.location,
                                    latitude: coordinate.latitude,
                                    longitude: coordinate.longitude,
                                    category: activity.category
                                )
                            }
                        } catch {
                            print("Geocoding failed for \(activity.location) (second attempt): \(error)")
                        }
                    }
                }
                
                updatedActivities.append(updatedActivity)
            }
            
            updatedDays.append(ItineraryDay(
                id: day.id,
                dayNumber: day.dayNumber,
                activities: updatedActivities
            ))
        }
        
        await MainActor.run {
            itinerary = Itinerary(
                id: itinerary.id,
                location: itinerary.location,
                numberOfDays: itinerary.numberOfDays,
                priceRange: itinerary.priceRange,
                genres: itinerary.genres,
                days: updatedDays
            )
            isGeocoding = false
            
            // Set initial map position to main location if available
            if let coordinate = mainLocationCoordinate, let mapView = mapView {
                let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 12)
                mapView.animate(to: camera)
            }
            
            updateMapMarkers()
        }
    }
    
    func updateMapMarkers() {
        guard let mapView = mapView, let day = currentDay else { return }
        
        // Clear existing markers and routes
        mapView.clear()
        markers.removeAll()
        polylines.removeAll()
        
        // Filter activities with valid coordinates
        let activitiesWithCoordinates = day.activities.compactMap { activity -> (Activity, CLLocationCoordinate2D)? in
            guard let coordinate = activity.coordinate else { return nil }
            return (activity, coordinate)
        }
        
        guard !activitiesWithCoordinates.isEmpty else { return }
        
        // Add custom markers for each activity
        var bounds = GMSCoordinateBounds()
        
        for (index, (activity, coordinate)) in activitiesWithCoordinates.enumerated() {
            // Create custom marker with category-based icon
            let marker = GMSMarker(position: coordinate)
            marker.title = activity.name
            marker.snippet = "\(activity.time) • \(activity.category)"
            marker.icon = getMarkerIcon(for: activity.category, index: index)
            marker.map = mapView
            markers.append(marker)
            
            bounds = bounds.includingCoordinate(coordinate)
        }
        
        // Draw routes between activities in order
        if activitiesWithCoordinates.count > 1 {
            drawRouteBetweenActivities(activitiesWithCoordinates.map { $0.1 }, on: mapView)
        }
        
        // Fit map to show all markers with padding
        let update = GMSCameraUpdate.fit(bounds, withPadding: 80)
        mapView.animate(with: update)
    }
    
    func getMarkerIcon(for category: String, index: Int) -> UIImage? {
        let iconName: String
        let backgroundColor: UIColor
        let iconColor: UIColor
        
        // Choose icon and colors based on category
        switch category.lowercased() {
        case let cat where cat.contains("restaurant") || cat.contains("food") || cat.contains("cafe"):
            iconName = "fork.knife"
            backgroundColor = UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0) // Elegant red
            iconColor = .white
        case let cat where cat.contains("hotel") || cat.contains("accommodation") || cat.contains("stay"):
            iconName = "bed.double.fill"
            backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0) // Elegant blue
            iconColor = .white
        case let cat where cat.contains("attraction") || cat.contains("sight") || cat.contains("monument"):
            iconName = "camera.fill"
            backgroundColor = accentGreen.toUIColor() // App accent green
            iconColor = .white
        case let cat where cat.contains("activity") || cat.contains("experience"):
            iconName = "figure.walk"
            backgroundColor = UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0) // Elegant orange
            iconColor = .white
        default:
            iconName = "mappin.circle.fill"
            backgroundColor = accentGreen.toUIColor()
            iconColor = .white
        }
        
        // Create elegant marker with icon and number badge
        let markerSize: CGFloat = 50
        let iconSize: CGFloat = 24
        let badgeSize: CGFloat = 20
        let shadowOffset: CGFloat = 2
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: markerSize + shadowOffset, height: markerSize + shadowOffset + badgeSize / 2))
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Draw shadow
            cgContext.setShadow(
                offset: CGSize(width: shadowOffset, height: shadowOffset),
                blur: 4,
                color: UIColor.black.withAlphaComponent(0.3).cgColor
            )
            
            // Draw circular marker background
            let circleRect = CGRect(x: shadowOffset / 2, y: shadowOffset / 2, width: markerSize, height: markerSize)
            let circlePath = UIBezierPath(ovalIn: circleRect)
            
            // Fill with gradient-like effect (darker at bottom)
            backgroundColor.setFill()
            circlePath.fill()
            
            // Draw inner highlight for depth
            let highlightRect = CGRect(x: circleRect.minX + 4, y: circleRect.minY + 4, width: markerSize - 8, height: markerSize - 8)
            let highlightPath = UIBezierPath(ovalIn: highlightRect)
            UIColor.white.withAlphaComponent(0.2).setFill()
            highlightPath.fill()
            
            // Draw white border
            UIColor.white.setStroke()
            circlePath.lineWidth = 3
            circlePath.stroke()
            
            // Draw icon in center
            if let icon = UIImage(systemName: iconName) {
                let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
                let sizedIcon = icon.withConfiguration(config)
                let iconRect = CGRect(
                    x: circleRect.midX - iconSize / 2,
                    y: circleRect.midY - iconSize / 2,
                    width: iconSize,
                    height: iconSize
                )
                sizedIcon.withTintColor(iconColor, renderingMode: .alwaysTemplate).draw(in: iconRect)
            }
            
            // Draw elegant number badge at top-right
            let badgeRect = CGRect(
                x: circleRect.maxX - badgeSize - 4,
                y: circleRect.minY - badgeSize / 2 + 2,
                width: badgeSize,
                height: badgeSize
            )
            let badgePath = UIBezierPath(ovalIn: badgeRect)
            
            // Badge with gradient effect
            UIColor.white.setFill()
            badgePath.fill()
            accentGreen.toUIColor().setStroke()
            badgePath.lineWidth = 2.5
            badgePath.stroke()
            
            // Draw number text in badge
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: accentGreen.toUIColor(),
                .paragraphStyle: paragraphStyle
            ]
            let numberText = "\(index + 1)"
            let textSize = numberText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: badgeRect.midX - textSize.width / 2,
                y: badgeRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            numberText.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    func drawRouteBetweenActivities(_ coordinates: [CLLocationCoordinate2D], on mapView: GMSMapView) {
        // Draw a simple polyline connecting activities in order
        guard coordinates.count > 1 else { return }
        
        // Create path from coordinates array
        // GMSPath is immutable, so we need to create it from an array
        let mutablePath = GMSMutablePath()
        for coordinate in coordinates {
            mutablePath.add(coordinate)
        }
        
        let polyline = GMSPolyline(path: mutablePath)
        polyline.strokeColor = accentGreen.toUIColor()
        polyline.strokeWidth = 4.0
        polyline.geodesic = true
        polyline.map = mapView
        polylines.append(polyline)
        
        // For better routes, you would use Google Directions API here
        // For now, we'll draw a simple straight-line route
        print("📍 Drawing route between \(coordinates.count) locations")
    }
}

// MARK: - Supporting Views

struct DayButton: View {
    let dayNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    
    var body: some View {
        Button(action: onTap) {
            Text("Day \(dayNumber)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            accentGreen
                        } else {
                            cardColor.opacity(0.6)
                        }
                    }
                )
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: isSelected ? accentGreen.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityCard: View {
    let activity: Activity
    let onTap: () -> Void
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // Time Badge - More prominent
                VStack(spacing: 4) {
                    Text(activity.time)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentGreen)
                    Circle()
                        .fill(accentGreen)
                        .frame(width: 5, height: 5)
                    Spacer()
                }
                .frame(width: 65)
                .padding(.top, 4)
                
                // Activity Details
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(activity.name)
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(activity.description)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(3)
                        }
                        
                        Spacer()
                        
                        // Category Badge - Better styled
                        Text(activity.category)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accentGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(accentGreen.opacity(0.15))
                            .cornerRadius(12)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(accentGreen.opacity(0.8))
                            .font(.system(size: 13))
                        Text(activity.location)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top, 4)
            }
            .padding(18)
            .background(cardColor)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Map View with Markers

struct GoogleMapViewWithMarkers: UIViewRepresentable {
    let activities: [Activity]
    let onMapReady: (GMSMapView) -> Void
    
    func makeUIView(context: Context) -> GMSMapView {
        // Start with a default camera - will be updated when city is geocoded
        // Use a proper frame size to ensure tiles load correctly
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 10)
        let mapView = GMSMapView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 400), camera: camera)
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = false
        mapView.settings.myLocationButton = false
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Apply dark theme
        do {
            if let styleURL = Bundle.main.url(forResource: "map_style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                // Enhanced dark style that's more elegant
                mapView.mapStyle = try GMSMapStyle(jsonString: """
                [
                  {
                    "featureType": "all",
                    "elementType": "geometry",
                    "stylers": [{"color": "#1a1f2e"}]
                  },
                  {
                    "featureType": "all",
                    "elementType": "labels.text.stroke",
                    "stylers": [{"color": "#1a1f2e"}]
                  },
                  {
                    "featureType": "all",
                    "elementType": "labels.text.fill",
                    "stylers": [{"color": "#8a8a8a"}]
                  },
                  {
                    "featureType": "water",
                    "elementType": "geometry",
                    "stylers": [{"color": "#0e1621"}]
                  },
                  {
                    "featureType": "road",
                    "elementType": "geometry",
                    "stylers": [{"color": "#2a2f3e"}]
                  },
                  {
                    "featureType": "poi",
                    "elementType": "labels",
                    "stylers": [{"visibility": "off"}]
                  }
                ]
                """)
            }
        } catch {
            print("Error setting map style: \(error)")
        }
        
        DispatchQueue.main.async {
            onMapReady(mapView)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Ensure map view has proper frame for tile loading
        // This is critical for tiles to load correctly
        DispatchQueue.main.async {
            let screenWidth = UIScreen.main.bounds.width
            if mapView.frame.width != screenWidth || mapView.frame.height != 400 {
                mapView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 400)
                // Force map to refresh tiles
                mapView.setNeedsDisplay()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        // Handle map interactions if needed
    }
}

extension Color {
    func toUIColor() -> UIColor {
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        return UIColor(
            red: components[0],
            green: components[1],
            blue: components[2],
            alpha: components.count > 3 ? components[3] : 1
        )
    }
}

