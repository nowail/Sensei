import Foundation
import UIKit

struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var members: [String]
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var lastMessageDate: Date?
    var messageCount: Int
    var userId: String  // Track which user owns this trip
    var backgroundImageData: Data?  // AI-generated background image
    
    init(id: UUID = UUID(), name: String, members: [String], startDate: Date, endDate: Date, userId: String, backgroundImageData: Data? = nil) {
        self.id = id
        self.name = name
        self.members = members
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
        self.lastMessageDate = nil
        self.messageCount = 0
        self.userId = userId
        self.backgroundImageData = backgroundImageData
    }
    
    var backgroundImage: UIImage? {
        guard let data = backgroundImageData else { return nil }
        return UIImage(data: data)
    }
    
    var isOngoing: Bool {
        // A trip is ongoing if its end date (calendar day) hasn't passed yet
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tripEndDay = calendar.startOfDay(for: endDate)
        return tripEndDay >= today
    }
    
    var isPast: Bool {
        // A trip is past if its end date (calendar day) has passed
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tripEndDay = calendar.startOfDay(for: endDate)
        return tripEndDay < today
    }
}
