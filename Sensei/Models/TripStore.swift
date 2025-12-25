import Foundation
import Combine

class TripStore: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var refreshTrigger: Date = Date() // Triggers view refresh when date changes
    
    let userId: String
    private var userEmail: String {
        userId.contains("@") ? userId : "" // Use email if available
    }
    
    // Track trips that are currently generating background images to prevent duplicates
    // Use a serial queue for thread-safe access
    private let imageGenerationQueue = DispatchQueue(label: "com.sensei.imageGeneration")
    private var _generatingImages: Set<UUID> = []
    private var generatingImages: Set<UUID> {
        get {
            return imageGenerationQueue.sync { _generatingImages }
        }
        set {
            imageGenerationQueue.sync { _generatingImages = newValue }
        }
    }
    
    private func insertGeneratingImage(_ tripId: UUID) {
        imageGenerationQueue.sync { _generatingImages.insert(tripId) }
    }
    
    private func removeGeneratingImage(_ tripId: UUID) {
        imageGenerationQueue.sync { _generatingImages.remove(tripId) }
    }
    
    private func containsGeneratingImage(_ tripId: UUID) -> Bool {
        return imageGenerationQueue.sync { _generatingImages.contains(tripId) }
    }
    
    init(userId: String) {
        self.userId = userId
        Task {
            await loadTrips()
        }
    }
    
    func addTrip(_ trip: Trip) async {
        var newTrip = trip
        newTrip.userId = userId  // Ensure trip belongs to current user
        
        print("🔍 Adding trip: \(newTrip.name), userEmail: \(userEmail), userId: \(userId)")
        
        do {
            try await SupabaseService.shared.insertTrip(newTrip, userEmail: userEmail)
            print("✅ Trip added to Supabase successfully")
            await MainActor.run {
                trips.append(newTrip)
            }
            
            // Generate background image for the new trip
            Task {
                await generateBackgroundImage(for: newTrip.id)
            }
        } catch {
            print("❌ Error adding trip to Supabase: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            // Fallback to local storage
            await MainActor.run {
        trips.append(newTrip)
                saveTripsLocally()
            }
            
            // Still generate background image even if Supabase save failed
            Task {
                await generateBackgroundImage(for: newTrip.id)
            }
        }
    }
    
    // Generate background image for a trip (only once per trip)
    func generateBackgroundImage(for tripId: UUID) async {
        // Check if already generating or already has image
        if containsGeneratingImage(tripId) {
            print("⏳ Background image already being generated for this trip")
            return
        }
        
        // Safely access trips array on main actor
        let trip: Trip? = await MainActor.run {
            return trips.first(where: { $0.id == tripId })
        }
        
        guard let trip = trip else {
            print("⚠️ Trip not found for image generation")
            return
        }
        
        // Skip if image already exists
        if trip.backgroundImageData != nil {
            print("✅ Trip already has background image, skipping generation")
            return
        }
        
        // Mark as generating to prevent duplicate requests
        insertGeneratingImage(tripId)
        defer {
            removeGeneratingImage(tripId)
        }
        
        // Extract country from trip name
        let country = extractCountryFromTripName(trip.name)
        print("🎨 Generating background image for trip: \(trip.name), country: \(country)")
        
        do {
            let generatedImage = try await AIService.shared.generateImage(for: country)
            print("✅ Background image generated successfully")
            
            // Convert image to data and update trip
            if let imageData = generatedImage.jpegData(compressionQuality: 0.8) {
                var updatedTrip = trip
                updatedTrip.backgroundImageData = imageData
                
                // Update in store and database
                await updateTrip(updatedTrip)
                print("✅ Trip background image saved - will not regenerate")
            }
        } catch {
            print("⚠️ Error generating background image: \(error)")
        }
    }
    
    // Extract country name from trip name
    private func extractCountryFromTripName(_ tripName: String) -> String {
        // Get all country names from LocationDataProvider
        let allCountries = LocationDataProvider.shared.countries.map { $0.name }
        
        // Try common patterns first (flags)
        let patterns = [
            "🇹🇷": "Turkey",
            "🇯🇵": "Japan",
            "🇫🇷": "France",
            "🇮🇹": "Italy",
            "🇪🇸": "Spain",
            "🇬🇧": "United Kingdom",
            "🇩🇪": "Germany",
            "🇨🇦": "Canada",
            "🇺🇸": "United States",
            "🇦🇺": "Australia",
            "🇧🇷": "Brazil",
            "🇲🇽": "Mexico",
            "🇮🇳": "India",
            "🇨🇳": "China",
            "🇰🇷": "South Korea",
            "🇹🇭": "Thailand",
            "🇸🇬": "Singapore",
            "🇬🇷": "Greece",
            "🇵🇹": "Portugal",
            "🇳🇱": "Netherlands",
            "🇵🇰": "Pakistan"
        ]
        
        for (flag, country) in patterns {
            if tripName.contains(flag) {
                return country
            }
        }
        
        // Try to find a country name in the trip name
        for country in allCountries {
            if tripName.localizedCaseInsensitiveContains(country) {
                return country
            }
        }
        
        // Handle patterns like "Tokyo Japan" or "Paris, France" - check last word/component
        let components = tripName.components(separatedBy: CharacterSet(charactersIn: ", "))
        for component in components.reversed() {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            for country in allCountries {
                if trimmed.localizedCaseInsensitiveContains(country) || country.localizedCaseInsensitiveContains(trimmed) {
                    return country
                }
            }
        }
        
        // Default fallback
        let cleaned = tripName.replacingOccurrences(of: "Trip", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Travel Destination" : cleaned
    }
    
    func updateTrip(_ trip: Trip) async {
        do {
            try await SupabaseService.shared.updateTrip(trip, userEmail: userEmail)
            await MainActor.run {
                if let index = trips.firstIndex(where: { $0.id == trip.id }) {
                    trips[index] = trip
                }
            }
        } catch {
            print("❌ Error updating trip in Supabase: \(error)")
            // Fallback to local storage
            await MainActor.run {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
                }
                saveTripsLocally()
            }
        }
    }
    
    func addMessageToTrip(tripId: UUID) async {
        await MainActor.run {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].messageCount += 1
            trips[index].lastMessageDate = Date()
            }
        }
        
        // Update in Supabase
        if let trip = trips.first(where: { $0.id == tripId }) {
            await updateTrip(trip)
        }
    }
    
    func deleteTrip(_ trip: Trip) async {
        do {
            try await SupabaseService.shared.deleteTrip(tripId: trip.id, userEmail: userEmail)
            await MainActor.run {
                trips.removeAll { $0.id == trip.id }
                saveTripsLocally()
            }
            print("✅ Trip deleted successfully")
        } catch {
            print("❌ Error deleting trip from Supabase: \(error)")
            // Still remove from local array
            await MainActor.run {
                trips.removeAll { $0.id == trip.id }
                saveTripsLocally()
            }
        }
    }
    
    var ongoingTrips: [Trip] {
        _ = refreshTrigger // Access refreshTrigger to trigger recomputation when it changes
        return trips.filter { $0.isOngoing }
    }
    
    var pastTrips: [Trip] {
        _ = refreshTrigger // Access refreshTrigger to trigger recomputation when it changes
        return trips.filter { $0.isPast }
    }
    
    /// Refreshes the trip categorization by updating the refresh trigger
    /// This ensures trips move from "Ongoing" to "Past" when dates pass
    func refreshTripCategories() {
        refreshTrigger = Date()
    }
    
    @MainActor
    func loadTrips() async {
        do {
            let fetchedTrips = try await SupabaseService.shared.fetchTrips(userEmail: userEmail)
            trips = fetchedTrips
            
            // Generate background images for trips that don't have them
            for trip in trips where trip.backgroundImageData == nil {
                Task {
                    await generateBackgroundImage(for: trip.id)
                }
            }
        } catch {
            print("❌ Error loading trips from Supabase: \(error)")
            // Fallback to local storage
            loadTripsLocally()
            
            // Generate background images for trips that don't have them
            for trip in trips where trip.backgroundImageData == nil {
                Task {
                    await generateBackgroundImage(for: trip.id)
                }
            }
        }
    }
    
    // MARK: - Local Storage Fallback
    
    private var userDefaultsKey: String {
        "SavedTrips_\(userId)"
    }
    
    private func saveTripsLocally() {
        if let encoded = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadTripsLocally() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            trips = decoded
        }
    }
}
