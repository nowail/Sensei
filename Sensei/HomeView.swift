import SwiftUI

struct HomeView: View {
    let userName: String
    
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

    var body: some View {
        NavigationStack {
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
                        NavigationLink(destination: NewTripView()) {
                            startTripCard
                        }
                        
                        // MARK: - Ongoing Trips
                        Text("Ongoing Trips")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        ongoingTripCard(title: "Naran Valley Trip", spent: "92,100", owe: "2,300")
                        
                        // MARK: - Past Trips
                        Text("Past Trips")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        pastTripRow(name: "Turkey Trip 🇹🇷")
                        pastTripRow(name: "Skardu Adventure ⛰️")
                        pastTripRow(name: "Murree Weekend 🌲")
                        
                        // MARK: - AI Suggestions
                        aiSuggestionBox
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
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
}

#Preview {
    HomeView(userName: "Pehlaj")
}
