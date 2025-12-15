import Foundation
import Supabase
import UIKit

class SupabaseService {
    static let shared = SupabaseService()
    
    private var _client: SupabaseClient?
    private var client: SupabaseClient {
        if let existing = _client {
            return existing
        }
        guard SupabaseConfig.supabaseURL != "YOUR_SUPABASE_URL",
              SupabaseConfig.supabaseAnonKey != "YOUR_SUPABASE_ANON_KEY" else {
            fatalError("Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables or update SupabaseConfig.swift")
        }
        
        let newClient = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        _client = newClient
        return newClient
    }
    
    private init() {
    }
    
    // MARK: - User Operations
    
    /// Create or update a user in the database
    func upsertUser(email: String, name: String?) async throws {
        let user = DatabaseUser(
            email: email,
            name: name ?? "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await client.database
            .from("users")
            .upsert(user, onConflict: "email")
            .execute()
    }
    
    /// Get user by email
    func getUser(email: String) async throws -> DatabaseUser? {
        let response: [DatabaseUser] = try await client.database
            .from("users")
            .select()
            .eq("email", value: email)
            .execute()
            .value
        
        return response.first
    }
    
    // MARK: - Trip Operations
    
    /// Fetch all trips for a user
    func fetchTrips(userEmail: String) async throws -> [Trip] {
        let response: [DatabaseTrip] = try await client.database
            .from("trips")
            .select()
            .eq("user_email", value: userEmail)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.map { $0.toTrip() }
    }
    
    /// Insert a new trip
    func insertTrip(_ trip: Trip, userEmail: String) async throws {
        let dbTrip = DatabaseTrip.from(trip: trip, userEmail: userEmail)
        
        print("🔍 Inserting trip to Supabase: \(dbTrip.name), userEmail: \(dbTrip.userEmail)")
        
        try await client.database
            .from("trips")
            .insert(dbTrip)
            .execute()
        
        print("✅ Trip inserted successfully")
    }
    
    /// Update an existing trip
    func updateTrip(_ trip: Trip, userEmail: String) async throws {
        let dbTrip = DatabaseTrip.from(trip: trip, userEmail: userEmail)
        
        try await client.database
            .from("trips")
            .update(dbTrip)
            .eq("id", value: trip.id.uuidString)
            .eq("user_email", value: userEmail)
            .execute()
    }
    
    /// Delete a trip
    func deleteTrip(tripId: UUID, userEmail: String) async throws {
        try await client.database
            .from("trips")
            .delete()
            .eq("id", value: tripId.uuidString)
            .eq("user_email", value: userEmail)
            .execute()
    }
    
    // MARK: - Message Operations
    
    /// Fetch all messages for a trip
    func fetchMessages(tripId: UUID) async throws -> [ChatMessage] {
        let response: [DatabaseMessage] = try await client.database
            .from("messages")
            .select()
            .eq("trip_id", value: tripId.uuidString)
            .order("timestamp", ascending: true)
            .execute()
            .value
        
        return response.compactMap { $0.toChatMessage() }
    }
    
    /// Insert a new message
    func insertMessage(_ message: ChatMessage, tripId: UUID) async throws {
        let dbMessage = DatabaseMessage.from(message: message, tripId: tripId)
        
        print("🔍 Inserting message to Supabase: tripId=\(tripId), type=\(dbMessage.messageType)")
        
        try await client.database
            .from("messages")
            .insert(dbMessage)
            .execute()
        
        print("✅ Message inserted successfully")
    }
}

// MARK: - Database Models

struct DatabaseUser: Codable {
    let email: String
    let name: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case email
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DatabaseTrip: Codable {
    let id: String
    let name: String
    let members: [String]
    let startDate: Date
    let endDate: Date
    let userEmail: String
    let createdAt: Date
    let lastMessageDate: Date?
    let messageCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case members
        case startDate = "start_date"
        case endDate = "end_date"
        case userEmail = "user_email"
        case createdAt = "created_at"
        case lastMessageDate = "last_message_date"
        case messageCount = "message_count"
    }
    
    static func from(trip: Trip, userEmail: String) -> DatabaseTrip {
        DatabaseTrip(
            id: trip.id.uuidString,
            name: trip.name,
            members: trip.members,
            startDate: trip.startDate,
            endDate: trip.endDate,
            userEmail: userEmail,
            createdAt: trip.createdAt,
            lastMessageDate: trip.lastMessageDate,
            messageCount: trip.messageCount
        )
    }
    
    func toTrip() -> Trip {
        let tripId = UUID(uuidString: id) ?? UUID()
        // Create trip with all properties
        var trip = Trip(
            id: tripId,
            name: name,
            members: members,
            startDate: startDate,
            endDate: endDate,
            userId: userEmail
        )
        // Restore additional properties that aren't in init
        trip.createdAt = createdAt
        trip.lastMessageDate = lastMessageDate
        trip.messageCount = messageCount
        return trip
    }
}

struct DatabaseMessage: Codable {
    let id: String
    let tripId: String
    let messageType: String
    let content: String?
    let imageData: Data?
    let audioURL: String?
    let isFromAI: Bool
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case messageType = "message_type"
        case content
        case imageData = "image_data"
        case audioURL = "audio_url"
        case isFromAI = "is_from_ai"
        case timestamp
    }
    
    static func from(message: ChatMessage, tripId: UUID) -> DatabaseMessage {
        var content: String?
        var imageData: Data?
        var audioURL: String?
        let messageType: String
        
        switch message.type {
        case .text(let text):
            messageType = "text"
            content = text
        case .image(let image):
            messageType = "image"
            imageData = image.jpegData(compressionQuality: 0.8)
            content = "Image"
        case .audio(let url):
            messageType = "audio"
            audioURL = url.absoluteString
            content = "Audio"
        }
        
        return DatabaseMessage(
            id: message.id.uuidString,
            tripId: tripId.uuidString,
            messageType: messageType,
            content: content,
            imageData: imageData,
            audioURL: audioURL,
            isFromAI: message.isFromAI,
            timestamp: message.timestamp
        )
    }
    
    func toChatMessage() -> ChatMessage? {
        guard let id = UUID(uuidString: id) else { return nil }
        
        let chatMessageType: MessageType
        
        switch self.messageType {
        case "text":
            guard let content = content else { return nil }
            chatMessageType = .text(content)
        case "image":
            guard let imageData = imageData,
                  let image = UIImage(data: imageData) else { return nil }
            chatMessageType = .image(image)
        case "audio":
            guard let audioURL = audioURL,
                  let url = URL(string: audioURL) else { return nil }
            chatMessageType = .audio(url)
        default:
            return nil
        }
        
        return ChatMessage(
            id: id,
            type: chatMessageType,
            isFromAI: isFromAI,
            timestamp: timestamp
        )
    }
}

