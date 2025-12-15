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
        entity.timestamp = Date()
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
                try await SupabaseService.shared.insertMessage(message, tripId: tripId)
                print("✅ Message synced to Supabase")
            } catch {
                print("❌ Error syncing message to Supabase: \(error)")
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

