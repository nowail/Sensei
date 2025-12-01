import SwiftUI
import AVFoundation
import PhotosUI
import CoreData

struct TripChatView: View {
    
    let trip: Trip
    @ObservedObject var tripStore: TripStore
    @Binding var navigationPath: NavigationPath
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var messageStore: ChatMessageStore
    
    @State private var inputText: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var isAITyping = false
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    init(trip: Trip, tripStore: TripStore, navigationPath: Binding<NavigationPath>) {
        self.trip = trip
        self.tripStore = tripStore
        self._navigationPath = navigationPath
        // Initialize with a temporary context, will be updated in onAppear
        _messageStore = StateObject(wrappedValue: ChatMessageStore(context: PersistenceController.shared.container.viewContext))
    }
    
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
                            if messageStore.messages.isEmpty {
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
                            
                            ForEach(messageStore.messages) { msg in
                            MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                            
                            // AI Typing Indicator
                            if isAITyping {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("AI Assistant")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.horizontal, 4)
                                        
                                        HStack(spacing: 4) {
                                            ForEach(0..<3) { index in
                                                Circle()
                                                    .fill(Color.white.opacity(0.6))
                                                    .frame(width: 8, height: 8)
                                                    .offset(y: index == 1 ? -5 : 0)
                                                    .animation(
                                                        Animation.easeInOut(duration: 0.6)
                                                            .repeatForever()
                                                            .delay(Double(index) * 0.2),
                                                        value: isAITyping
                                                    )
                        }
                    }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    Color(#colorLiteral(red: 0.30, green: 0.50, blue: 0.70, alpha: 1)).opacity(0.4),
                                                    Color(#colorLiteral(red: 0.30, green: 0.50, blue: 0.70, alpha: 1)).opacity(0.3)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(20)
                                    }
                                    Spacer()
                                }
                                .id("ai-typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onChange(of: messageStore.messages.count) { _ in
                        if let lastMessage = messageStore.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isAITyping) { _ in
                        if isAITyping {
                            withAnimation {
                                proxy.scrollTo("ai-typing", anchor: .bottom)
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
        .onAppear {
            // Update context to use environment context
            messageStore.context = viewContext
            messageStore.loadMessages(for: trip.id)
        }
    }
    
    // SEND A TEXT MESSAGE
    func sendTextMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = inputText
        inputText = ""
        
        // Create and save user message
        let userChatMessage = ChatMessage(type: .text(userMessage), isFromAI: false)
        messageStore.saveMessage(userChatMessage, for: trip.id)
        
        // Add to ongoing trips when message is sent
        tripStore.addMessageToTrip(tripId: trip.id)
        
        // Get AI response
        Task {
            await getAIResponse(userMessage: userMessage)
        }
    }
    
    // GET AI RESPONSE
    @MainActor
    func getAIResponse(userMessage: String) async {
        isAITyping = true
        
        do {
            let aiResponse = try await AIService.shared.sendMessage(
                userMessage,
                conversationHistory: messageStore.messages
            )
            
            // Create and save AI message
            let aiChatMessage = ChatMessage(type: .text(aiResponse), isFromAI: true)
            messageStore.saveMessage(aiChatMessage, for: trip.id)
            
            isAITyping = false
        } catch {
            print("Error getting AI response: \(error)")
            isAITyping = false
            
            // Show specific error message based on error type
            let errorText: String
            if let aiError = error as? AIError {
                switch aiError {
                case .invalidAPIKey:
                    errorText = "⚠️ API key not configured. Please add your OpenAI API key in AIConfig.swift"
                case .apiError(let message):
                    errorText = "⚠️ \(message)"
                case .parseError(let message):
                    errorText = "⚠️ Error parsing response: \(message)"
                }
            } else {
                errorText = "⚠️ Sorry, I'm having trouble responding right now. Please check your internet connection and try again."
            }
            
            // Show error message to user
            let errorMessage = ChatMessage(
                type: .text(errorText),
                isFromAI: true
            )
            messageStore.saveMessage(errorMessage, for: trip.id)
        }
    }
    
    // HANDLE IMAGE MESSAGE
    func handleImageMessage(_ img: UIImage) {
        let imageMessage = ChatMessage(type: .image(img), isFromAI: false)
        messageStore.saveMessage(imageMessage, for: trip.id)
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
            let audioMessage = ChatMessage(type: .audio(url), isFromAI: false)
            messageStore.saveMessage(audioMessage, for: trip.id)
            tripStore.addMessageToTrip(tripId: trip.id)
        }
    }
}
