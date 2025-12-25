import SwiftUI

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
                    Task {
                        await tripStore.loadTrips()
                    }
                    // Refresh trip categories immediately and periodically
                    tripStore.refreshTripCategories()
                    startRefreshTimer()
                }
                .onDisappear {
                    stopRefreshTimer()
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
                    
                    // MARK: - Start New Trip Card
                    Button {
                        navigationPath.append(NavigationDestination.newTrip)
                    } label: {
                        startTripCard
                    }
                    
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
                                pastTripRow(name: trip.name)
                            }
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
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
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
    
    // MARK: Card — Start a New Trip
    var startTripCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Start a New Trip")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Create a trip & add friends")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 14))
            }
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 46, height: 46)
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium))
            }
        }
        .padding()
        .background(cardColor)
        .cornerRadius(18)
        .shadow(color: glowGreen.opacity(0.15), radius: 20, x: 0, y: 8)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(trip.name)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
            
            HStack(spacing: 12) {
                if trip.messageCount > 0 {
                    Text("\(trip.messageCount) messages")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14))
                }
                
                if let lastMessageDate = trip.lastMessageDate {
                    Text(formatDate(lastMessageDate))
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 12))
                }
            }
            
            Text("\(trip.members.count) members")
                .foregroundColor(glowGreen.opacity(0.8))
                .font(.system(size: 14, weight: .medium))
        }
        .padding()
        .background(cardColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: Past Trip Row
    func pastTripRow(name: String) -> some View {
        HStack {
            Text(name)
                .foregroundColor(.white)
                .font(.system(size: 16))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.4))
        }
        .padding()
        .background(cardColor.opacity(0.8))
        .cornerRadius(14)
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
    
    // MARK: AI Suggestion Box
    var aiSuggestionBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AI Suggestions")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
            
            Text("You're close to overspending on food compared to trips with similar budgets.")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 14))
                .lineSpacing(4)
        }
        .padding()
        .background(cardColor)
        .cornerRadius(16)
        .shadow(color: glowGreen.opacity(0.1), radius: 15, y: 6)
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
}

#Preview {
    HomeView(userName: "Pehlaj", userId: "test@example.com")
}
