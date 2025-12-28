import SwiftUI
import AVFoundation
import PhotosUI
import CoreData
import Combine

struct TripChatView: View {
    
    @State private var trip: Trip
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
    @State private var showTripDetail = false
    @State private var scrollToMessageId: UUID? = nil
    @State private var showMentionPicker = false
    @State private var mentionQuery = ""
    @State private var mentionStartIndex: Int = 0
    @State private var isInsertingMention = false
    @State private var countryRules: CountryRules?
    @State private var isLoadingRules = false
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    init(trip: Trip, tripStore: TripStore, navigationPath: Binding<NavigationPath>) {
        self._trip = State(initialValue: trip)
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
            
            // WhatsApp-style doodle pattern background
            ChatDoodleBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // HEADER - Clickable to open trip details
                Button {
                    showTripDetail = true
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(trip.members.count) members")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .frame(minHeight: 80)
                    .background(cardColor.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
                
                // MESSAGES
                ScrollViewReader { proxy in
                ScrollView {
                        VStack(spacing: 12) {
                            // Country Rules Section
                            if let rules = countryRules {
                                CountryRulesView(countryRules: rules)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                            } else if isLoadingRules {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: accentGreen))
                                    Text("Loading travel rules...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            }
                            
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
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
                    .onChange(of: scrollToMessageId) { messageId in
                        if let messageId = messageId {
                            // Wait a moment for the view to update, then scroll
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    proxy.scrollTo(messageId, anchor: .center)
                                }
                                // Clear the scroll target
                                scrollToMessageId = nil
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
                    
                    // TextField with mention support
                    ZStack(alignment: .bottom) {
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
                            .onChange(of: inputText) { newValue in
                                // Don't check for mentions if we're currently inserting one
                                guard !isInsertingMention else {
                                    isInsertingMention = false
                                    return
                                }
                                // Check for mentions in real-time
                                checkForMention(in: newValue)
                            }
                            .onSubmit {
                                // Close picker when user submits/enters
                                showMentionPicker = false
                            }
                        
                        // Mention Picker with smooth animation
                        if showMentionPicker {
                            MentionPickerView(
                                members: trip.members,
                                query: mentionQuery,
                                onSelect: { member in
                                    // Set flag to prevent re-opening
                                    isInsertingMention = true
                                    
                                    // Close picker immediately
                                    showMentionPicker = false
                                    mentionQuery = ""
                                    
                                    // Insert mention
                                    insertMention(member)
                                },
                                onDismiss: {
                                    showMentionPicker = false
                                    mentionQuery = ""
                                }
                            )
                            .offset(y: -60)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom)
                                    .combined(with: .opacity)
                                    .combined(with: .scale(scale: 0.96)),
                                removal: .move(edge: .bottom)
                                    .combined(with: .opacity)
                                    .combined(with: .scale(scale: 0.96))
                            ))
                            .zIndex(1000)
                        }
                    }
                    
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
        .sheet(isPresented: $showTripDetail) {
            NavigationStack {
                TripDetailView(trip: trip, tripStore: tripStore, navigationPath: $navigationPath)
            }
        }
        .onAppear {
            // Update context to use environment context
            messageStore.context = viewContext
            messageStore.loadMessages(for: trip.id)
            
            // Load country rules
            Task {
                await loadCountryRules()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToMessage"))) { notification in
            if let userInfo = notification.userInfo,
               let messageId = userInfo["messageId"] as? UUID {
                scrollToMessageId = messageId
            }
        }
        .onChange(of: tripStore.trips) { _ in
            // Update trip if it was modified in TripDetailView
            if let updatedTrip = tripStore.trips.first(where: { $0.id == trip.id }) {
                // Check for member changes
                let oldMembers = Set(trip.members)
                let newMembers = Set(updatedTrip.members)
                
                // Find added members
                let addedMembers = newMembers.subtracting(oldMembers)
                for member in addedMembers {
                    let systemMessage = ChatMessage(
                        type: .systemEvent(.memberAdded(member, updatedTrip.name)),
                        isFromAI: false
                    )
                    messageStore.saveMessage(systemMessage, for: trip.id)
                }
                
                // Find removed members
                let removedMembers = oldMembers.subtracting(newMembers)
                for member in removedMembers {
                    let systemMessage = ChatMessage(
                        type: .systemEvent(.memberRemoved(member, updatedTrip.name)),
                        isFromAI: false
                    )
                    messageStore.saveMessage(systemMessage, for: trip.id)
                }
                
                trip = updatedTrip
            }
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
        Task {
            await tripStore.addMessageToTrip(tripId: trip.id)
        }
        
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
        Task {
            await tripStore.addMessageToTrip(tripId: trip.id)
        }
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
            Task {
                await tripStore.addMessageToTrip(tripId: trip.id)
            }
        }
    }
    
    // MARK: - Country Rules Functions
    
    @MainActor
    func loadCountryRules() async {
        isLoadingRules = true
        
        // Extract country from trip name
        let country = extractCountryFromTripName(trip.name)
        
        guard !country.isEmpty else {
            isLoadingRules = false
            return
        }
        
        do {
            let rules = try await SupabaseService.shared.fetchCountryRules(countryName: country)
            countryRules = rules
        } catch {
            print("⚠️ Error loading country rules: \(error)")
        }
        
        isLoadingRules = false
    }
    
    private func extractCountryFromTripName(_ tripName: String) -> String {
        // Get all country names from LocationDataProvider
        let allCountries = LocationDataProvider.shared.countries.map { $0.name }
        
        // Try common patterns first (flags)
        let patterns: [String: String] = [
            "🇹🇷": "Turkey",
            "🇯🇵": "Japan",
            "🇫🇷": "France",
            "🇮🇹": "Italy",
            "🇪🇸": "Spain",
            "🇬🇧": "United Kingdom",
            "🇩🇪": "Germany",
            "🇨🇦": "Canada",
            "🇺🇸": "United States",
            "🇦🇺": "Australia",
            "🇧🇷": "Brazil",
            "🇲🇽": "Mexico",
            "🇮🇳": "India",
            "🇨🇳": "China",
            "🇰🇷": "South Korea",
            "🇹🇭": "Thailand",
            "🇸🇬": "Singapore",
            "🇬🇷": "Greece",
            "🇵🇹": "Portugal",
            "🇳🇱": "Netherlands",
            "🇵🇰": "Pakistan"
        ]
        
        for (flag, country) in patterns {
            if tripName.contains(flag) {
                return country
            }
        }
        
        // Try to find country name in trip name
        for country in allCountries {
            if tripName.localizedCaseInsensitiveContains(country) {
                return country
            }
        }
        
        // Try common city-to-country mappings
        let cityCountryMap: [String: String] = [
            "New York": "United States",
            "Los Angeles": "United States",
            "London": "United Kingdom",
            "Paris": "France",
            "Tokyo": "Japan",
            "Sydney": "Australia",
            "Toronto": "Canada",
            "Dubai": "United Arab Emirates",
            "Singapore": "Singapore",
            "Bangkok": "Thailand",
            "Istanbul": "Turkey",
            "Rome": "Italy",
            "Barcelona": "Spain",
            "Amsterdam": "Netherlands",
            "Berlin": "Germany",
            "Mumbai": "India",
            "Shanghai": "China",
            "Seoul": "South Korea",
            "Athens": "Greece",
            "Lisbon": "Portugal",
            "Karachi": "Pakistan",
            "Lahore": "Pakistan",
            "Islamabad": "Pakistan"
        ]
        
        for (city, country) in cityCountryMap {
            if tripName.localizedCaseInsensitiveContains(city) {
                return country
            }
        }
        
        // If no match found, try to extract first word (might be country name)
        let components = tripName.components(separatedBy: CharacterSet(charactersIn: " ,-"))
        if let firstComponent = components.first, !firstComponent.isEmpty {
            // Remove emojis and whitespace
            let cleaned = firstComponent.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "[\\p{So}\\p{Cn}]", with: "", options: .regularExpression)
            
            if !cleaned.isEmpty {
                return cleaned
            }
        }
        
        return ""
    }
    
    // MARK: - Mention Functions
    
    func checkForMention(in text: String) {
        // Find the last @ symbol
        guard let lastAtIndex = text.lastIndex(of: "@") else {
            showMentionPicker = false
            return
        }
        
        let afterAt = text.index(after: lastAtIndex)
        
        // Check if @ is at the end - show all members
        if afterAt >= text.endIndex {
            mentionQuery = ""
            mentionStartIndex = text.distance(from: text.startIndex, to: lastAtIndex)
            showMentionPicker = true
            return
        }
        
        // Get text after @
        let remainingText = String(text[afterAt...])
        
        // If there's a space immediately after @ or in the remaining text, mention is complete - close picker
        if remainingText.hasPrefix(" ") || remainingText.contains(" ") {
            // Check if space is right after @ (mention completed)
            if remainingText.hasPrefix(" ") {
                showMentionPicker = false
                return
            }
            
            // Space found later - extract query before space
            if let spaceIndex = remainingText.firstIndex(of: " ") {
                let query = String(remainingText[..<spaceIndex])
                if query.isEmpty {
                    showMentionPicker = false
                    return
                }
                mentionQuery = query
            } else {
                showMentionPicker = false
                return
            }
        } else {
            // No space found - use entire remaining text as query for filtering
            mentionQuery = remainingText
        }
        
        mentionStartIndex = text.distance(from: text.startIndex, to: lastAtIndex)
        showMentionPicker = true
    }
    
    func insertMention(_ member: String) {
        // Find the @ symbol position
        let textBeforeAt = String(inputText.prefix(mentionStartIndex))
        let textAfterAt = inputText[inputText.index(inputText.startIndex, offsetBy: mentionStartIndex + 1)...]
        
        // Find where the mention query ends (space or end of string)
        let queryEnd = textAfterAt.firstIndex(of: " ") ?? textAfterAt.endIndex
        let textAfterQuery = String(textAfterAt[queryEnd...])
        
        // Build new text with mention (add space after mention)
        let mentionText = "@" + member + " "
        let newText = textBeforeAt + mentionText + textAfterQuery
        
        // Update text and ensure picker stays closed
        showMentionPicker = false
        mentionQuery = ""
        inputText = newText
        
        // Reset flag after a brief delay to allow text update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInsertingMention = false
        }
    }
}

// MARK: - Chat Doodle Background
struct ChatDoodleBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Create a repeating pattern of cute doodles
                let patternSize: CGFloat = 180
                let rows = Int(geometry.size.height / patternSize) + 2
                let cols = Int(geometry.size.width / patternSize) + 2
                
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        DoodlePattern(seed: row * cols + col)
                            .frame(width: patternSize, height: patternSize)
                            .position(
                                x: CGFloat(col) * patternSize + patternSize / 2,
                                y: CGFloat(row) * patternSize + patternSize / 2
                            )
                    }
                }
            }
        }
        .opacity(0.12) // More visible and appealing
    }
}

struct DoodlePattern: View {
    let seed: Int
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        ZStack {
            // Cute doodles with variety based on seed
            Group {
                // Hearts
                HeartShape()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(x: 25, y: 35)
                
                HeartShape()
                    .fill(accentGreen.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .offset(x: 140, y: 50)
                
                // Stars/Sparkles
                StarShape()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .offset(x: 60, y: 25)
                
                StarShape()
                    .fill(accentGreen.opacity(0.5))
                    .frame(width: 5, height: 5)
                    .offset(x: 150, y: 90)
                
                StarShape()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .offset(x: 90, y: 120)
                
                // Circles of different sizes
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 5, height: 5)
                    .offset(x: 40, y: 70)
                
                Circle()
                    .fill(accentGreen.opacity(0.4))
                    .frame(width: 4, height: 4)
                    .offset(x: 110, y: 60)
                
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 3, height: 3)
                    .offset(x: 75, y: 100)
                
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 3.5, height: 3.5)
                    .offset(x: 130, y: 30)
                
                // Dots pattern
                ForEach(0..<4) { i in
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 2.5, height: 2.5)
                        .offset(x: CGFloat(20 + i * 35), y: CGFloat(110 + i * 8))
                }
                
                // Curved lines
                Path { path in
                    path.move(to: CGPoint(x: 30, y: 55))
                    path.addQuadCurve(to: CGPoint(x: 50, y: 50), control: CGPoint(x: 40, y: 45))
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                
                Path { path in
                    path.move(to: CGPoint(x: 100, y: 75))
                    path.addQuadCurve(to: CGPoint(x: 120, y: 70), control: CGPoint(x: 110, y: 65))
                }
                .stroke(accentGreen.opacity(0.4), lineWidth: 1.5)
                
                // Arcs/Semicircles
                Path { path in
                    path.addArc(
                        center: CGPoint(x: 80, y: 130),
                        radius: 12,
                        startAngle: .degrees(0),
                        endAngle: .degrees(180),
                        clockwise: false
                    )
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                
                Path { path in
                    path.addArc(
                        center: CGPoint(x: 160, y: 70),
                        radius: 10,
                        startAngle: .degrees(45),
                        endAngle: .degrees(225),
                        clockwise: false
                    )
                }
                .stroke(accentGreen.opacity(0.4), lineWidth: 1.5)
                
                // Small clouds
                CloudShape()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 12, height: 8)
                    .offset(x: 50, y: 85)
                
                // Simple shapes
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .rotationEffect(.degrees(45))
                    .offset(x: 120, y: 115)
            }
        }
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<5 {
            let angle = Double(i) * 4 * .pi / 5 - .pi / 2
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let size = min(rect.width, rect.height) / 2
        
        // Create a simple heart shape
        path.move(to: CGPoint(x: center.x, y: center.y + size * 0.3))
        path.addCurve(
            to: CGPoint(x: center.x - size * 0.5, y: center.y - size * 0.2),
            control1: CGPoint(x: center.x - size * 0.25, y: center.y + size * 0.1),
            control2: CGPoint(x: center.x - size * 0.5, y: center.y - size * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y - size * 0.5),
            control1: CGPoint(x: center.x - size * 0.5, y: center.y - size * 0.4),
            control2: CGPoint(x: center.x - size * 0.25, y: center.y - size * 0.5)
        )
        path.addCurve(
            to: CGPoint(x: center.x + size * 0.5, y: center.y - size * 0.2),
            control1: CGPoint(x: center.x + size * 0.25, y: center.y - size * 0.5),
            control2: CGPoint(x: center.x + size * 0.5, y: center.y - size * 0.4)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + size * 0.3),
            control1: CGPoint(x: center.x + size * 0.5, y: center.y - size * 0.1),
            control2: CGPoint(x: center.x + size * 0.25, y: center.y + size * 0.1)
        )
        path.closeSubpath()
        return path
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let size = min(rect.width, rect.height)
        
        // Simple cloud shape
        path.addEllipse(in: CGRect(x: center.x - size * 0.3, y: center.y - size * 0.2, width: size * 0.4, height: size * 0.4))
        path.addEllipse(in: CGRect(x: center.x - size * 0.1, y: center.y - size * 0.3, width: size * 0.4, height: size * 0.4))
        path.addEllipse(in: CGRect(x: center.x + size * 0.1, y: center.y - size * 0.2, width: size * 0.4, height: size * 0.4))
        return path
    }
}

// MARK: - Mention Picker View
struct MentionPickerView: View {
    let members: [String]
    let query: String
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var filteredMembers: [String] {
        if query.isEmpty {
            return members
        }
        return members.filter { $0.localizedCaseInsensitiveContains(query) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Members list
            if filteredMembers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash.fill")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 32))
                    Text("No members found")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(cardColor.opacity(0.9))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredMembers.enumerated()), id: \.element) { index, member in
                            Button(action: {
                                // Haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                
                                // Close immediately and select
                                onSelect(member)
                            }) {
                                HStack(alignment: .center, spacing: 12) {
                                    // Avatar circle
                                    ZStack(alignment: .center) {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        accentGreen.opacity(0.3),
                                                        accentGreen.opacity(0.2)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "person.fill")
                                            .foregroundColor(accentGreen)
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                    .frame(width: 40, height: 40, alignment: .center)
                                    
                                    Text(member)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Spacer(minLength: 8)
                                    
                                    if !query.isEmpty && member.localizedCaseInsensitiveContains(query) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(accentGreen.opacity(0.6))
                                            .font(.system(size: 16))
                                            .frame(width: 20, height: 20, alignment: .center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .padding(.horizontal, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(MentionButtonStyle())
                            
                            if index < filteredMembers.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: min(240, CGFloat(filteredMembers.count) * 56))
                .background(cardColor.opacity(0.9))
            }
        }
        .background(
            // Blur effect background
            cardColor.opacity(0.98)
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            accentGreen.opacity(0.4),
                            accentGreen.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
        .shadow(color: accentGreen.opacity(0.1), radius: 30, x: 0, y: 0)
        .padding(.horizontal, 16)
    }
}

// Custom button style for mention items
struct MentionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ?
                Color.white.opacity(0.05) :
                Color.clear
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
