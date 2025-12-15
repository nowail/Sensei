import Foundation
import Combine

class TripStore: ObservableObject {
    @Published var trips: [Trip] = []
    
    let userId: String
    private var userEmail: String {
        userId.contains("@") ? userId : "" // Use email if available
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
        } catch {
            print("❌ Error adding trip to Supabase: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            // Fallback to local storage
            await MainActor.run {
                trips.append(newTrip)
                saveTripsLocally()
            }
        }
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
    
    var ongoingTrips: [Trip] {
        trips.filter { $0.isOngoing && !$0.isPast }
    }
    
    var pastTrips: [Trip] {
        trips.filter { $0.isPast }
    }
    
    @MainActor
    func loadTrips() async {
        do {
            let fetchedTrips = try await SupabaseService.shared.fetchTrips(userEmail: userEmail)
            trips = fetchedTrips
        } catch {
            print("❌ Error loading trips from Supabase: \(error)")
            // Fallback to local storage
            loadTripsLocally()
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
