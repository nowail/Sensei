import SwiftUI
import AVKit

struct MessageBubble: View {
    let message: ChatMessage
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                
                switch message.type {
                    
                case .text(let text):
                    Text(text)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
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
                                .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                        )
                    
                case .image(let img):
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(accentGreen.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                
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
            Spacer()
        }
    }
}
