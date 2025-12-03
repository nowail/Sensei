import Foundation

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
    
    init(id: UUID = UUID(), name: String, members: [String], startDate: Date, endDate: Date, userId: String) {
        self.id = id
        self.name = name
        self.members = members
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
        self.lastMessageDate = nil
        self.messageCount = 0
        self.userId = userId
    }
    
    var isOngoing: Bool {
        guard let lastMessageDate = lastMessageDate else {
            return false // No messages yet, not ongoing
        }
        return lastMessageDate > Date().addingTimeInterval(-7 * 24 * 60 * 60) // Active in last 7 days
    }
    
    var isPast: Bool {
        return endDate < Date()
    }
}
