import SwiftUI
import Combine

enum NavigationDestination: Hashable {
    case newTrip
    case tripChat(Trip)
    case tripDetail(Trip)
    case map
}

struct HomeView: View {
    let userName: String
    let userId: String
    @StateObject private var tripStore: TripStore
    @State private var navigationPath = NavigationPath()
    @State private var refreshTimer: Timer?
    @State private var searchText: String = ""
    @State private var filteredTrips: [Trip] = []
    @State private var isSearching: Bool = false
    @StateObject private var travelNewsService = TravelNewsService.shared
    @State private var currentNewsIndex: Int = 0
    @State private var newsRotationTimer: Timer?
    @State private var cancellables = Set<AnyCancellable>()
    
    init(userName: String, userId: String) {
        self.userName = userName
        self.userId = userId
        _tripStore = StateObject(wrappedValue: TripStore(userId: userId))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            homeContent
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
                .onAppear {
                    // Only load trips if we don't have any, or refresh categories
                    if tripStore.trips.isEmpty {
                    Task {
                        await tripStore.loadTrips()
                        // Fetch news after trips are loaded
                        await fetchPersonalizedTravelNews()
                        }
                    } else {
                        // Just refresh categories, don't reload trips (prevents glitching)
                        tripStore.refreshTripCategories()
                        // Refresh news with current trips
                        Task {
                            await fetchPersonalizedTravelNews()
                        }
                    }
                    startRefreshTimer()
                    startNewsRotation()
                }
                .onChange(of: tripStore.trips) { oldValue, newValue in
                    // Refresh news when trips change (new trip added, etc.)
                    Task {
                        await fetchPersonalizedTravelNews()
                    }
                }
                .onDisappear {
                    stopRefreshTimer()
                    stopNewsRotation()
                }
        }
    }
    
    private var homeContent: some View {
        ZStack {
            bgGradient.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Welcome Heading
                    Text("Welcome, \(userName) 👋")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // MARK: - Search Bar
                    searchBar
                    
                    // MARK: - Trips List (Filtered or All)
                    if searchText.isEmpty {
                        // Show all trips when not searching
                        // MARK: - Ongoing Trips
                        if !tripStore.ongoingTrips.isEmpty {
                            Text("Ongoing Trips")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            ForEach(tripStore.ongoingTrips) { trip in
                                Button {
                                    navigationPath.append(NavigationDestination.tripChat(trip))
                                } label: {
                                    ongoingTripCardView(trip: trip)
                                }
                                .buttonStyle(TripCardButtonStyle())
                            }
                        }
                        
                        // MARK: - Past Trips
                        if !tripStore.pastTrips.isEmpty {
                            Text("Past Trips")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            ForEach(tripStore.pastTrips) { trip in
                                Button {
                                    navigationPath.append(NavigationDestination.tripChat(trip))
                                } label: {
                                    pastTripRow(trip: trip)
                                }
                                .buttonStyle(TripCardButtonStyle())
                            }
                        }
                        
                        // MARK: - Map Button
                        Button {
                            navigationPath.append(NavigationDestination.map)
                        } label: {
                            mapButtonCard
                        }
                        
                        // MARK: - AI Suggestions
                        aiSuggestionBox
                    } else {
                        // Show filtered trips when searching
                        if isSearching {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: glowGreen))
                                Spacer()
                            }
                            .padding()
                        } else if filteredTrips.isEmpty {
                            Text("No trips found")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.6))
                                .padding()
                        } else {
                            Text("Search Results")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            ForEach(filteredTrips) { trip in
                                Button {
                                    navigationPath.append(NavigationDestination.tripChat(trip))
                                } label: {
                                    if trip.isOngoing {
                                        ongoingTripCardView(trip: trip)
                                    } else {
                                        pastTripRow(trip: trip)
                                    }
                                }
                                .buttonStyle(TripCardButtonStyle())
                            }
                        }
                    }
                    
                    Spacer().frame(height: 100) // Extra space for floating button
                }
                .padding(.horizontal, 20)
            }
            
            // MARK: - Floating New Trip Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        navigationPath.append(NavigationDestination.newTrip)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(glowGreen)
                                .frame(width: 64, height: 64)
                                .shadow(color: glowGreen.opacity(0.4), radius: 20, x: 0, y: 8)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 28, weight: .semibold))
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .newTrip:
            NewTripView(tripStore: tripStore, navigationPath: $navigationPath)
        case .tripChat(let trip):
            TripChatView(trip: trip, tripStore: tripStore, navigationPath: $navigationPath)
        case .tripDetail(let trip):
            TripDetailView(trip: trip, tripStore: tripStore, navigationPath: $navigationPath)
        case .map:
            MapScreen()
        }
    }
    
    // Colors
    let bgGradient = LinearGradient(
        colors: [
            Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)),
            Color(#colorLiteral(red: 0.07, green: 0.12, blue: 0.11, alpha: 1))
        ],
        startPoint: .top, endPoint: .bottom
    )
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let glowGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
}

extension HomeView {
    
    // MARK: - Search Bar
    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 18))
            
            TextField("Search trips by name or chat...", text: $searchText)
                .foregroundColor(.white)
                .font(.system(size: 16))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        await searchTrips(query: newValue)
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    filteredTrips = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 18))
                }
            }
        }
        .padding(16)
        .background(cardColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Search Functionality
    func searchTrips(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedQuery.isEmpty {
            await MainActor.run {
                filteredTrips = []
                isSearching = false
            }
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        var matchingTrips: [Trip] = []
        
        // Search through all trips
        for trip in tripStore.trips {
            // First, check if trip name matches
            if trip.name.localizedCaseInsensitiveContains(trimmedQuery) {
                matchingTrips.append(trip)
                continue
            }
            
            // Then, search through messages
            do {
                let messages = try await SupabaseService.shared.fetchMessages(tripId: trip.id)
                
                // Check if any message content matches
                let hasMatchingMessage = messages.contains { message in
                    switch message.type {
                    case .text(let text):
                        return text.localizedCaseInsensitiveContains(trimmedQuery)
                    case .image, .audio:
                        return false
                    case .systemEvent(let event):
                        switch event {
                        case .memberAdded(let member, _):
                            return member.localizedCaseInsensitiveContains(trimmedQuery)
                        case .memberRemoved(let member, _):
                            return member.localizedCaseInsensitiveContains(trimmedQuery)
                        }
                    }
                }
                
                if hasMatchingMessage {
                    matchingTrips.append(trip)
                }
            } catch {
                print("⚠️ Error fetching messages for trip \(trip.id): \(error)")
            }
        }
        
        await MainActor.run {
            filteredTrips = matchingTrips
            isSearching = false
        }
    }
    
    // MARK: Card — Ongoing Trip
    func ongoingTripCard(title: String, spent: String, owe: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
            
            Text("Total Spent: PKR \(spent)")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 14))
            
            Text("You Owe: PKR \(owe)")
                .foregroundColor(Color(#colorLiteral(red: 0.3, green: 0.85, blue: 0.65, alpha: 1)))
                .font(.system(size: 15, weight: .semibold))
        }
        .padding()
        .background(cardColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
    
    // MARK: Card — Ongoing Trip View
    func ongoingTripCardView(trip: Trip) -> some View {
        ZStack(alignment: .leading) {
            // Background Image
            if let backgroundImage = trip.backgroundImage {
                GeometryReader { geometry in
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .overlay(
                    // Dark gradient overlay for text readability
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                // Fallback to solid color if no image
                cardColor
            }
            
            // Content
        VStack(alignment: .leading, spacing: 6) {
            Text(trip.name)
                .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold))
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            
            HStack(spacing: 12) {
                if trip.messageCount > 0 {
                    Text("\(trip.messageCount) messages")
                            .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 14))
                            .shadow(color: .black.opacity(0.3), radius: 2)
                }
                
                if let lastMessageDate = trip.lastMessageDate {
                    Text(formatDate(lastMessageDate))
                            .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 12))
                            .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
            
            Text("\(trip.members.count) members")
                    .foregroundColor(glowGreen)
                    .font(.system(size: 14, weight: .semibold))
                    .shadow(color: .black.opacity(0.3), radius: 2)
        }
        .padding()
        }
        .frame(height: 140)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: Past Trip Row
    func pastTripRow(trip: Trip) -> some View {
        ZStack {
            // Background Image
            if let backgroundImage = trip.backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipped()
                    .overlay(
                        // Dark gradient overlay for text readability
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                // Fallback to solid color with gradient
                LinearGradient(
                    colors: [
                        cardColor.opacity(0.9),
                        cardColor.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Content - Centered
            VStack(spacing: 8) {
                // Trip Name - Centered and prominent
                Text(trip.name)
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold))
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                
                // Additional Info Row
                HStack(spacing: 16) {
                    // Members count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                        Text("\(trip.members.count)")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    
                    // Message count (if any)
                    if trip.messageCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 12))
                            Text("\(trip.messageCount)")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Last message date (if available)
                    if let lastMessageDate = trip.lastMessageDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text(formatShortDate(lastMessageDate))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            
            // Chevron indicator on the right
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(height: 100)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: date)?.contains(Date()) ?? false {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    // MARK: Map Button Card
    var mapButtonCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("View Map")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("See your location & nearby places")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 14))
            }
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 46, height: 46)
                Image(systemName: "map.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium))
            }
        }
        .padding()
        .background(cardColor)
        .cornerRadius(18)
        .shadow(color: glowGreen.opacity(0.15), radius: 20, x: 0, y: 8)
    }
    
    // MARK: AI Suggestion Box (Travel News)
    var aiSuggestionBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundColor(glowGreen)
                    .font(.system(size: 16))
                Text("Travel News")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                
                if travelNewsService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: glowGreen))
                        .scaleEffect(0.8)
                }
            }
            
            if !travelNewsService.newsItems.isEmpty {
                let currentNews = travelNewsService.newsItems[currentNewsIndex]
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(currentNews.title)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 14, weight: .medium))
                        .lineSpacing(4)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    
                    HStack {
                        Text(currentNews.source)
                            .foregroundColor(glowGreen.opacity(0.8))
                            .font(.system(size: 12, weight: .medium))
                        
                        if let date = currentNews.publishedAt {
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            Text(formatNewsDate(date))
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 11))
                        }
                    }
                }
                .id(currentNews.id) // Force view refresh on change
                .animation(.easeInOut(duration: 0.5), value: currentNewsIndex)
            } else {
                Text("Loading travel news...")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))
            }
            
            // News indicator dots
            if travelNewsService.newsItems.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<min(travelNewsService.newsItems.count, 5), id: \.self) { index in
                        Circle()
                            .fill(index == currentNewsIndex ? glowGreen : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentNewsIndex)
                    }
                    if travelNewsService.newsItems.count > 5 {
                        Text("+\(travelNewsService.newsItems.count - 5)")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 10))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(cardColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            glowGreen.opacity(0.3),
                            glowGreen.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: glowGreen.opacity(0.15), radius: 20, y: 8)
    }
    
    func formatNewsDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Refresh Timer
    private func startRefreshTimer() {
        // Refresh every minute to check if trips should move to "Past"
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            tripStore.refreshTripCategories()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - News Rotation Timer
    private func startNewsRotation() {
        // Rotate news every 10 seconds using Timer.publish
        Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // Use DispatchQueue to update state on main thread
                DispatchQueue.main.async {
                    rotateToNextNews()
                }
            }
            .store(in: &cancellables)
    }
    
    private func stopNewsRotation() {
        cancellables.removeAll()
    }
    
    private func rotateToNextNews() {
        guard !travelNewsService.newsItems.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentNewsIndex = (currentNewsIndex + 1) % travelNewsService.newsItems.count
        }
    }
    
    // MARK: - Personalized News Fetching
    private func fetchPersonalizedTravelNews() async {
        // Extract locations from user's trips (prioritize ongoing trips)
        var locations: [String] = []
        
        // Get locations from ongoing trips first (most relevant)
        let ongoingLocations = tripStore.ongoingTrips.map { trip in
            tripStore.extractCountryFromTripName(trip.name)
        }.filter { !$0.isEmpty && $0 != "Travel Destination" }
        
        // Get locations from past trips (still relevant)
        let pastLocations = tripStore.pastTrips.prefix(2).map { trip in
            tripStore.extractCountryFromTripName(trip.name)
        }.filter { !$0.isEmpty && $0 != "Travel Destination" }
        
        // Combine and remove duplicates, prioritize ongoing
        let combined = ongoingLocations + pastLocations
        locations = Array(Set(combined))
        
        // Limit to 3 locations to avoid overly complex queries
        locations = Array(locations.prefix(3))
        
        if !locations.isEmpty {
            print("🌍 Fetching personalized travel news for: \(locations.joined(separator: ", "))")
        } else {
            print("🌍 No specific locations found, fetching general travel news")
        }
        
        await travelNewsService.fetchTravelNews(locations: locations)
    }
}

// MARK: - Button Style for Trip Cards
struct TripCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    HomeView(userName: "Pehlaj", userId: "test@example.com")
}
