import SwiftUI
import AVKit

struct MessageBubble: View {
    let message: ChatMessage
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    let aiColor = Color(#colorLiteral(red: 0.30, green: 0.50, blue: 0.70, alpha: 1))
    
    var body: some View {
        // System messages are centered
        if message.isSystemMessage {
            switch message.type {
            case .systemEvent(let event):
                SystemEventView(event: event)
            default:
                EmptyView()
            }
        } else {
            HStack {
                if message.isFromAI {
                    Spacer()
                }
                
                VStack(alignment: message.isFromAI ? .trailing : .leading, spacing: 4) {
                    
                    // Sender label
                    if message.isFromAI {
                        Text("AI Assistant")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 4)
                    }
                    
                    switch message.type {
                    
                case .text(let text):
                    TextWithMentions(text: text)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            message.isFromAI ?
                            LinearGradient(
                                colors: [
                                    aiColor.opacity(0.4),
                                    aiColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    accentGreen.opacity(0.3),
                                    accentGreen.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    message.isFromAI ? aiColor.opacity(0.3) : accentGreen.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    
                case .image(let img):
                    VStack(alignment: .leading, spacing: 8) {
                        // Label for AI-generated images
                        if !message.isFromAI {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                Text("AI Generated")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(accentGreen.opacity(0.8))
                        }
                        
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                            .frame(maxHeight: 250)
                            .cornerRadius(20)
                        .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        message.isFromAI ? aiColor.opacity(0.3) : accentGreen.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                        )
                            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 4)
                
                case .audio(let url):
                    AudioMessagePlayer(url: url)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(cardColor)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                        )
                    
                case .systemEvent:
                    EmptyView() // Handled separately above
                }
                }
                
                if !message.isFromAI {
                Spacer()
                }
            }
        }
    }
}

// MARK: - System Event View
struct SystemEventView: View {
    let event: SystemEventType
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(accentGreen.opacity(0.8))
                
                Text(messageText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                cardColor.opacity(0.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accentGreen.opacity(0.2), lineWidth: 1)
                    )
            )
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    var iconName: String {
        switch event {
        case .memberAdded:
            return "person.badge.plus"
        case .memberRemoved:
            return "person.badge.minus"
        }
    }
    
    var messageText: String {
        switch event {
        case .memberAdded(let memberName, let tripName):
            return "\(memberName) added to \(tripName)"
        case .memberRemoved(let memberName, let tripName):
            return "\(memberName) removed from \(tripName)"
        }
    }
}

// MARK: - Text with Mentions
struct TextWithMentions: View {
    let text: String
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        buildText(from: text)
            .foregroundColor(.white)
    }
    
    @ViewBuilder
    func buildText(from text: String) -> Text {
        // Pattern to match @username
        let mentionPattern = "@([A-Za-z0-9\\s]+?)(?=\\s|$|[.,!?])"
        
        guard let regex = try? NSRegularExpression(pattern: mentionPattern, options: []) else {
            return Text(text)
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if matches.isEmpty {
            return Text(text)
        }
        
        var result = Text("")
        var lastIndex = 0
        
        for match in matches {
            // Add text before mention
            if match.range.location > lastIndex {
                let beforeRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let beforeText = nsString.substring(with: beforeRange)
                result = result + Text(beforeText)
            }
            
            // Add highlighted mention
            let mentionText = nsString.substring(with: match.range)
            result = result + Text(mentionText)
                .foregroundColor(accentGreen)
                .fontWeight(.semibold)
            
            lastIndex = match.range.location + match.range.length
        }
        
        // Add remaining text
        if lastIndex < nsString.length {
            let remainingRange = NSRange(location: lastIndex, length: nsString.length - lastIndex)
            let remainingText = nsString.substring(with: remainingRange)
            result = result + Text(remainingText)
        }
        
        return result
    }
}
