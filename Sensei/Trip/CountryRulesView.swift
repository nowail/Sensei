import SwiftUI

struct CountryRulesView: View {
    let countryRules: CountryRules
    @State private var isExpanded: Bool = true
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(accentGreen)
                            .font(.system(size: 18))
                        
                        Text("\(countryRules.countryName) Travel Rules")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardColor)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Rules Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Group rules by category
                    let groupedRules = Dictionary(grouping: countryRules.rules) { $0.category }
                    
                    ForEach(CountryRules.Rule.RuleCategory.allCases, id: \.self) { category in
                        if let rules = groupedRules[category], !rules.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Category Header
                                HStack(spacing: 6) {
                                    Image(systemName: categoryIcon(for: category))
                                        .foregroundColor(accentGreen)
                                        .font(.system(size: 14))
                                    
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(accentGreen)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                
                                // Rules in this category
                                ForEach(rules) { rule in
                                    RuleRow(rule: rule)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
                .background(cardColor.opacity(0.8))
            }
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentGreen.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
    
    private func categoryIcon(for category: CountryRules.Rule.RuleCategory) -> String {
        switch category {
        case .customs: return "suitcase.fill"
        case .laws: return "scale.3d"
        case .culture: return "hand.raised.fill"
        case .safety: return "shield.fill"
        case .money: return "dollarsign.circle.fill"
        case .transportation: return "car.fill"
        case .general: return "info.circle.fill"
        }
    }
}

struct RuleRow: View {
    let rule: CountryRules.Rule
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var importanceColor: Color {
        switch rule.importance {
        case .critical:
            return .red.opacity(0.8)
        case .important:
            return .orange.opacity(0.8)
        case .goodToKnow:
            return accentGreen
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Importance Indicator
            Circle()
                .fill(importanceColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(rule.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Importance Badge
                    Text(rule.importance.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(importanceColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(importanceColor.opacity(0.15))
                        .cornerRadius(8)
                }
                
                Text(rule.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(nil)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(cardColor.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

extension CountryRules.Rule.RuleCategory: CaseIterable {
    static var allCases: [CountryRules.Rule.RuleCategory] {
        [.customs, .laws, .culture, .safety, .money, .transportation, .general]
    }
}

