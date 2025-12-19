import SwiftUI

struct PersonalExpensesView: View {
    let userId: String
    
    let bgGradient = LinearGradient(
        colors: [
            Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)),
            Color(#colorLiteral(red: 0.07, green: 0.12, blue: 0.11, alpha: 1))
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgGradient.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header
                        Text("Personal Expenses")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        // Summary Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Total Spent")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("PKR 0")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("This month")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardColor)
                        .cornerRadius(20)
                        
                        // Categories Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("By Category")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Placeholder categories
                            categoryRow(icon: "fork.knife", name: "Food & Dining", amount: "PKR 0", percentage: 0)
                            categoryRow(icon: "car.fill", name: "Transport", amount: "PKR 0", percentage: 0)
                            categoryRow(icon: "house.fill", name: "Accommodation", amount: "PKR 0", percentage: 0)
                            categoryRow(icon: "ticket.fill", name: "Activities", amount: "PKR 0", percentage: 0)
                        }
                        
                        // Recent Expenses
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Expenses")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("No expenses yet")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 16))
                                
                                Text("Start tracking your expenses")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(.system(size: 14))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Add expense action
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(accentGreen)
                            .font(.system(size: 24))
                    }
                }
            }
        }
    }
    
    private func categoryRow(icon: String, name: String, amount: String, percentage: Double) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentGreen.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(accentGreen)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                Text("\(Int(percentage))% of total")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 12))
            }
            
            Spacer()
            
            Text(amount)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
        }
        .padding()
        .background(cardColor)
        .cornerRadius(16)
    }
}

#Preview {
    PersonalExpensesView(userId: "test@sensei.com")
}

