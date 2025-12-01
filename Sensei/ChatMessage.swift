import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let type: MessageType
}

enum MessageType {
    case text(String)
    case image(UIImage)
    case audio(URL)
}
