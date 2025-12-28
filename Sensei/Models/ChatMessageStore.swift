import Foundation
import CoreData
import SwiftUI

class ChatMessageStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    
    var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func loadMessages(for tripId: UUID) {
        let request: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "tripId == %@", tripId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChatMessageEntity.timestamp, ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            messages = entities.compactMap { entity in
                convertEntityToMessage(entity)
            }
        } catch {
            print("Error loading messages: \(error)")
            messages = []
        }
    }
    
    func saveMessage(_ message: ChatMessage, for tripId: UUID) {
        let entity = ChatMessageEntity(context: context)
        entity.id = message.id
        entity.tripId = tripId
        entity.timestamp = message.timestamp
        entity.isFromAI = message.isFromAI
        entity.messageType = message.typeString
        
        switch message.type {
        case .text(let text):
            entity.content = text
        case .image(let image):
            entity.content = "Image"
            entity.imageData = image.jpegData(compressionQuality: 0.8)
        case .audio(let url):
            entity.content = "Audio"
            entity.audioURL = url.absoluteString
        case .systemEvent(let event):
            switch event {
            case .memberAdded(let member, let tripName):
                entity.content = "SYSTEM:\(member):ADDED:\(tripName)"
            case .memberRemoved(let member, let tripName):
                entity.content = "SYSTEM:\(member):REMOVED:\(tripName)"
            }
        }
        
        do {
            try context.save()
            messages.append(message)
            print("✅ Message saved locally")
        } catch {
            print("❌ Error saving message locally: \(error)")
        }
        
        // Sync to Supabase
        Task {
            do {
                print("🔍 Attempting to sync message to Supabase: tripId=\(tripId), messageId=\(message.id)")
                try await SupabaseService.shared.insertMessage(message, tripId: tripId)
                print("✅ Message synced to Supabase successfully")
            } catch {
                print("❌ Error syncing message to Supabase: \(error)")
                print("❌ Error type: \(type(of: error))")
                if let nsError = error as NSError? {
                    print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
                    print("❌ Error userInfo: \(nsError.userInfo)")
                }
            }
        }
    }
    
    private func convertEntityToMessage(_ entity: ChatMessageEntity) -> ChatMessage? {
        guard let id = entity.id,
              let messageType = entity.messageType else { return nil }
        
        let messageTypeEnum: MessageType
        
        switch messageType {
        case "text":
            guard let content = entity.content else { return nil }
            messageTypeEnum = .text(content)
        case "image":
            guard let imageData = entity.imageData,
                  let image = UIImage(data: imageData) else { return nil }
            messageTypeEnum = .image(image)
        case "audio":
            guard let audioURLString = entity.audioURL,
                  let url = URL(string: audioURLString) else { return nil }
            messageTypeEnum = .audio(url)
        case "systemEvent":
            guard let content = entity.content else { return nil }
            // Parse system event: SYSTEM:memberName:EVENT:tripName
            let parts = content.components(separatedBy: ":")
            if parts.count >= 4 && parts[0] == "SYSTEM" {
                let memberName = parts[1]
                let eventType = parts[2]
                let tripName = parts[3]
                if eventType == "ADDED" {
                    messageTypeEnum = .systemEvent(.memberAdded(memberName, tripName))
                } else if eventType == "REMOVED" {
                    messageTypeEnum = .systemEvent(.memberRemoved(memberName, tripName))
                } else {
                    return nil
                }
            } else {
                return nil
            }
        default:
            return nil
        }
        
        return ChatMessage(
            id: id,
            type: messageTypeEnum,
            isFromAI: entity.isFromAI,
            timestamp: entity.timestamp ?? Date()
        )
    }
}

