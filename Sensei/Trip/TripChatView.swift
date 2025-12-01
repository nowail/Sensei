import SwiftUI
import AVFoundation
import PhotosUI

struct TripChatView: View {
    
    let tripName: String
    let members: [String]
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                
                // HEADER
                Text(tripName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(messages) { msg in
                            MessageBubble(message: msg)
                        }
                    }
                    .padding()
                }
                
                // MESSAGE INPUT BAR
                HStack(spacing: 12) {
                    
                    // Camera button
                    Button(action: { showImagePicker = true }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                    }
                    
                    // Mic button
                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                            .foregroundColor(isRecording ? .red : .white)
                            .font(.system(size: 22))
                    }
                    
                    // TextField
                    TextField("Type an expense note…", text: $inputText)
                        .padding(12)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    
                    // Send button
                    Button(action: sendTextMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, onImagePicked: handleImageMessage)
        }
    }
    
    // SEND A TEXT MESSAGE
    func sendTextMessage() {
        guard !inputText.isEmpty else { return }
        
        messages.append(ChatMessage(type: .text(inputText)))
        inputText = ""
    }
    
    // HANDLE IMAGE MESSAGE
    func handleImageMessage(_ img: UIImage) {
        messages.append(ChatMessage(type: .image(img)))
    }
    
    // AUDIO RECORDING
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default)
        try? audioSession.setActive(true)

        let path = FileManager.default.temporaryDirectory.appendingPathComponent("audio.m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try? AVAudioRecorder(url: path, settings: settings)
        audioRecorder?.record()
        isRecording = true
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        if let url = audioRecorder?.url {
            messages.append(ChatMessage(type: .audio(url)))
        }
    }
}
