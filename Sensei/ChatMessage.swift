import SwiftUI

struct ChatMessage: Identifiable {
    let id: UUID
    let type: MessageType
    let isFromAI: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), type: MessageType, isFromAI: Bool = false, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.isFromAI = isFromAI
        self.timestamp = timestamp
    }
    
    var typeString: String {
        switch type {
        case .text: return "text"
        case .image: return "image"
        case .audio: return "audio"
        }
    }
}

enum MessageType {
    case text(String)
    case image(UIImage)
    case audio(URL)
}
