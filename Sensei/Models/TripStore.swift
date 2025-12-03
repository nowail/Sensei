import Foundation
import Combine

class TripStore: ObservableObject {
    @Published var trips: [Trip] = []
    
    let userId: String
    private var userDefaultsKey: String {
        "SavedTrips_\(userId)"
    }
    
    init(userId: String) {
        self.userId = userId
        loadTrips()
    }
    
    func addTrip(_ trip: Trip) {
        var newTrip = trip
        newTrip.userId = userId  // Ensure trip belongs to current user
        trips.append(newTrip)
        saveTrips()
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
            saveTrips()
        }
    }
    
    func addMessageToTrip(tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].messageCount += 1
            trips[index].lastMessageDate = Date()
            saveTrips()
        }
    }
    
    var ongoingTrips: [Trip] {
        trips.filter { $0.isOngoing && !$0.isPast }
    }
    
    var pastTrips: [Trip] {
        trips.filter { $0.isPast }
    }
    
    private func saveTrips() {
        if let encoded = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadTrips() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            trips = decoded
        }
    }
}
