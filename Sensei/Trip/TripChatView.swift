import SwiftUI
import AVFoundation
import PhotosUI

struct TripChatView: View {
    
    let trip: Trip
    @ObservedObject var tripStore: TripStore
    @Binding var navigationPath: NavigationPath
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording = false
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)),
                    Color(#colorLiteral(red: 0.07, green: 0.12, blue: 0.11, alpha: 1))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // HEADER
                VStack(spacing: 4) {
                    Text(trip.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(trip.members.count) members")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(cardColor.opacity(0.5))
                
                // MESSAGES
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            if messages.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white.opacity(0.3))
                                    Text("No messages yet")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.system(size: 16))
                                    Text("Start the conversation!")
                                        .foregroundColor(.white.opacity(0.4))
                                        .font(.system(size: 14))
                                }
                                .padding(.top, 60)
                            }
                            
                            ForEach(messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // MESSAGE INPUT BAR
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12) {
                        // Camera button
                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 22))
                                .frame(width: 40, height: 40)
                        }
                        
                        // Mic button
                        Button(action: toggleRecording) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                                .foregroundColor(isRecording ? .red : .white.opacity(0.8))
                                .font(.system(size: 22))
                                .frame(width: 40, height: 40)
                        }
                        
                        // TextField
                        TextField("Type an expense note…", text: $inputText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(cardColor)
                            .cornerRadius(24)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        // Send button
                        Button(action: sendTextMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(inputText.isEmpty ? .white.opacity(0.3) : accentGreen)
                                .font(.system(size: 22))
                                .frame(width: 40, height: 40)
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(cardColor.opacity(0.3))
                }
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
        
        // Add to ongoing trips when message is sent
        tripStore.addMessageToTrip(tripId: trip.id)
    }
    
    // HANDLE IMAGE MESSAGE
    func handleImageMessage(_ img: UIImage) {
        messages.append(ChatMessage(type: .image(img)))
        tripStore.addMessageToTrip(tripId: trip.id)
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
            tripStore.addMessageToTrip(tripId: trip.id)
        }
    }
}
