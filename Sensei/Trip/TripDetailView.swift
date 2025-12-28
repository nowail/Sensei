import SwiftUI
import ContactsUI

struct TripDetailView: View {
    @ObservedObject var tripStore: TripStore
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) var dismiss
    
    @State private var trip: Trip
    @State private var searchText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showAddFriend = false
    @State private var showContactPicker = false
    @State private var newFriendName: String = ""
    @State private var filteredMessages: [ChatMessage] = []
    @State private var messageToScrollTo: UUID? = nil
    @StateObject private var messageStore: ChatMessageStore
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    let bgGradient = LinearGradient(
        colors: [
            Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)),
            Color(#colorLiteral(red: 0.07, green: 0.12, blue: 0.11, alpha: 1))
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    init(trip: Trip, tripStore: TripStore, navigationPath: Binding<NavigationPath>) {
        self._trip = State(initialValue: trip)
        self.tripStore = tripStore
        self._navigationPath = navigationPath
        _messageStore = StateObject(wrappedValue: ChatMessageStore(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Trip Header
                    VStack(alignment: .leading, spacing: 16) {
                        // Trip Name
                        HStack {
                            Text(trip.name)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Status Badge
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(trip.isOngoing ? accentGreen : Color.gray.opacity(0.6))
                                    .frame(width: 8, height: 8)
                                Text(trip.isOngoing ? "Ongoing" : "Past")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(cardColor.opacity(0.8))
                            .cornerRadius(12)
                        }
                        
                        // Info Row
                        HStack(spacing: 20) {
                            // Members
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(accentGreen)
                                    .font(.system(size: 16))
                                Text("\(trip.members.count) members")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            // Start Date
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 14))
                                Text(formatDateShort(trip.startDate))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // End Date
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 14))
                                Text(formatDateShort(trip.endDate))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        ZStack {
                            cardColor
                            LinearGradient(
                                colors: [
                                    accentGreen.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .cornerRadius(24)
                    .shadow(color: accentGreen.opacity(0.15), radius: 20, x: 0, y: 8)
                    
                    // MARK: - Search Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Messages")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.5))
                            
                            TextField("Search in messages...", text: $searchText)
                                .foregroundColor(.white)
                                .onChange(of: searchText) { newValue in
                                    searchMessages(query: newValue)
                                }
                        }
                        .padding()
                        .background(cardColor.opacity(0.8))
                        .cornerRadius(16)
                        
                        if !searchText.isEmpty && !filteredMessages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(filteredMessages.count) results")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                ForEach(filteredMessages.prefix(5)) { message in
                                    Button {
                                        navigateToMessage(message)
                                    } label: {
                                        MessageSearchResult(message: message)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.top, 8)
                        } else if !searchText.isEmpty && filteredMessages.isEmpty {
                            Text("No results found")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(cardColor)
                    .cornerRadius(20)
                    
                    // MARK: - Members Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Members")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // Add member input
                        HStack {
                            TextField("Type member name...", text: $newFriendName)
                                .padding()
                                .background(cardColor.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .onSubmit {
                                    addMemberFromText()
                                }
                            
                            Button(action: { addMemberFromText() }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(accentGreen)
                            }
                            .disabled(newFriendName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        // Contact picker button
                        Button {
                            showContactPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Add from Contacts")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(accentGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(cardColor.opacity(0.8))
                            .cornerRadius(14)
                        }
                        
                        ForEach(trip.members, id: \.self) { member in
                            MemberRow(
                                name: member,
                                canRemove: trip.members.count > 1, // Can't remove if only one member
                                onRemove: {
                                    removeMember(member)
                                }
                            )
                        }
                    }
                    .padding()
                    .background(cardColor)
                    .cornerRadius(20)
                    
                    // MARK: - Trip Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trip Statistics")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            StatCard(
                                icon: "message.fill",
                                value: "\(trip.messageCount)",
                                label: "Messages"
                            )
                            
                            StatCard(
                                icon: "person.2.fill",
                                value: "\(trip.members.count)",
                                label: "Members"
                            )
                            
                            StatCard(
                                icon: "calendar",
                                value: "\(daysBetween(start: trip.startDate, end: trip.endDate))",
                                label: "Days"
                            )
                        }
                    }
                    .padding()
                    .background(cardColor)
                    .cornerRadius(20)
                    
                    // MARK: - Delete Trip Button
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Trip")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(cardColor.opacity(0.8))
                        .cornerRadius(16)
                    }
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(accentGreen)
            }
        }
        .alert("Delete Trip", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("Are you sure you want to delete this trip? This action cannot be undone.")
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView { contactName in
                addMemberFromContact(contactName)
            }
        }
        .onAppear {
            messageStore.loadMessages(for: trip.id)
            // Don't show results on initial load - only when searching
            filteredMessages = []
        }
        .onChange(of: tripStore.trips) { _ in
            // Sync trip from store when it's updated
            if let updatedTrip = tripStore.trips.first(where: { $0.id == trip.id }) {
                trip = updatedTrip
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d-MMM-yyyy"
        return formatter.string(from: date)
    }
    
    func daysBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(1, components.day ?? 1)
    }
    
    func searchMessages(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            filteredMessages = []
        } else {
            filteredMessages = messageStore.messages.filter { message in
                switch message.type {
                case .text(let text):
                    return text.localizedCaseInsensitiveContains(trimmedQuery)
                case .image:
                    return false
                case .audio:
                    return false
                case .systemEvent(let event):
                    // Search in system event messages
                    switch event {
                    case .memberAdded(let member, let tripName):
                        return member.localizedCaseInsensitiveContains(trimmedQuery) || 
                               tripName.localizedCaseInsensitiveContains(trimmedQuery)
                    case .memberRemoved(let member, let tripName):
                        return member.localizedCaseInsensitiveContains(trimmedQuery) || 
                               tripName.localizedCaseInsensitiveContains(trimmedQuery)
                    }
                }
            }
        }
    }
    
    func addMemberFromText() {
        let trimmedName = newFriendName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trip.members.contains(trimmedName) else {
            newFriendName = ""
            return
        }
        
        var updatedTrip = trip
        updatedTrip.members.append(trimmedName)
        trip = updatedTrip
        
        Task {
            await tripStore.updateTrip(updatedTrip)
        }
        
        newFriendName = ""
    }
    
    func addMemberFromContact(_ contactName: String) {
        let trimmedName = contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trip.members.contains(trimmedName) else {
            return
        }
        
        var updatedTrip = trip
        updatedTrip.members.append(trimmedName)
        trip = updatedTrip
        
        Task {
            await tripStore.updateTrip(updatedTrip)
        }
    }
    
    func removeMember(_ member: String) {
        guard trip.members.count > 1 else { return } // Can't remove last member
        
        var updatedTrip = trip
        updatedTrip.members.removeAll { $0 == member }
        trip = updatedTrip
        
        Task {
            await tripStore.updateTrip(updatedTrip)
        }
    }
    
    func deleteTrip() {
        Task {
            await tripStore.deleteTrip(trip)
            await MainActor.run {
                // Dismiss the detail view and navigate back to home
                dismiss()
                // Clear navigation path to go back to home
                navigationPath.removeLast(navigationPath.count)
            }
        }
    }
    
    func navigateToMessage(_ message: ChatMessage) {
        // Dismiss the detail view to go back to chat
        dismiss()
        // Store the message ID to scroll to
        messageToScrollTo = message.id
        // Post a notification that we want to scroll to this message
        NotificationCenter.default.post(
            name: NSNotification.Name("ScrollToMessage"),
            object: nil,
            userInfo: ["messageId": message.id]
        )
    }
}

// MARK: - Supporting Views

struct MemberRow: View {
    let name: String
    let canRemove: Bool
    let onRemove: () -> Void
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 24))
            
            Text(name)
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Spacer()
            
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.system(size: 22))
                }
            }
        }
        .padding()
        .background(cardColor.opacity(0.8))
        .cornerRadius(14)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(accentGreen)
                .font(.system(size: 24))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(cardColor.opacity(0.8))
        .cornerRadius(16)
    }
}

struct MessageSearchResult: View {
    let message: ChatMessage
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.isFromAI ? "brain.head.profile" : "person.fill")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.isFromAI ? "AI Assistant" : "You")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                if case .text(let text) = message.type {
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(cardColor.opacity(0.6))
        .cornerRadius(12)
    }
}

