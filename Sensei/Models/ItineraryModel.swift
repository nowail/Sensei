import Foundation
import CoreLocation

struct Itinerary: Identifiable, Codable {
    var id: UUID
    var location: String
    var numberOfDays: Int
    var priceRange: String
    var genres: [String]
    var days: [ItineraryDay]
    var createdAt: Date
    
    init(id: UUID = UUID(), location: String, numberOfDays: Int, priceRange: String, genres: [String], days: [ItineraryDay]) {
        self.id = id
        self.location = location
        self.numberOfDays = numberOfDays
        self.priceRange = priceRange
        self.genres = genres
        self.days = days
        self.createdAt = Date()
    }
}

struct ItineraryDay: Identifiable, Codable, Equatable {
    var id: UUID
    var dayNumber: Int
    var activities: [Activity]
    
    init(id: UUID = UUID(), dayNumber: Int, activities: [Activity]) {
        self.id = id
        self.dayNumber = dayNumber
        self.activities = activities
    }
    
    static func == (lhs: ItineraryDay, rhs: ItineraryDay) -> Bool {
        return lhs.id == rhs.id && 
               lhs.dayNumber == rhs.dayNumber && 
               lhs.activities == rhs.activities
    }
}

struct Activity: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var time: String
    var location: String
    var latitude: Double?
    var longitude: Double?
    var category: String // e.g., "Restaurant", "Attraction", "Hotel"
    
    init(id: UUID = UUID(), name: String, description: String, time: String, location: String, latitude: Double? = nil, longitude: Double? = nil, category: String) {
        self.id = id
        self.name = name
        self.description = description
        self.time = time
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.description == rhs.description &&
               lhs.time == rhs.time &&
               lhs.location == rhs.location &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.category == rhs.category
    }
}

