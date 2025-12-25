import SwiftUI
import AVKit

struct MessageBubble: View {
    let message: ChatMessage
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    let aiColor = Color(#colorLiteral(red: 0.30, green: 0.50, blue: 0.70, alpha: 1))
    
    var body: some View {
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
                    Text(text)
                        .foregroundColor(.white)
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
                }
            }
            
            if !message.isFromAI {
            Spacer()
            }
        }
    }
}
