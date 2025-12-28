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
        case .systemEvent: return "systemEvent"
        }
    }
    
    var isSystemMessage: Bool {
        if case .systemEvent = type {
            return true
        }
        return false
    }
}

enum MessageType {
    case text(String)
    case image(UIImage)
    case audio(URL)
    case systemEvent(SystemEventType)
}

enum SystemEventType {
    case memberAdded(String, String) // member name, trip name
    case memberRemoved(String, String) // member name, trip name
}
