import SwiftUI
import AVFoundation

struct AudioMessagePlayer: View {
    let url: URL
    @State private var player: AVAudioPlayer?
    
    var body: some View {
        Button(action: playAudio) {
            HStack {
                Image(systemName: "waveform")
                Text("Play Audio")
            }
            .padding(12)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(12)
            .foregroundColor(.white)
        }
    }
    
    func playAudio() {
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
