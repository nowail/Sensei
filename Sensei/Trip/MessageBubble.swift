import SwiftUI
import AVKit

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                
                switch message.type {
                    
                case .text(let text):
                    Text(text)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.25))
                        .cornerRadius(14)
                    
                case .image(let img):
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .cornerRadius(12)
                
                case .audio(let url):
                    AudioMessagePlayer(url: url)
                }
            }
            Spacer()
        }
    }
}
