import Foundation

struct CountryRules: Identifiable, Codable {
    let id: UUID
    let countryName: String
    let rules: [Rule]
    let lastUpdated: Date
    
    struct Rule: Identifiable, Codable {
        let id: UUID
        let title: String
        let description: String
        let category: RuleCategory
        let importance: Importance
        
        enum RuleCategory: String, Codable {
            case customs = "Customs & Entry"
            case laws = "Laws & Regulations"
            case culture = "Culture & Etiquette"
            case safety = "Safety & Health"
            case money = "Money & Currency"
            case transportation = "Transportation"
            case general = "General"
        }
        
        enum Importance: String, Codable {
            case critical = "Critical"
            case important = "Important"
            case goodToKnow = "Good to Know"
        }
    }
}

// Database model for Supabase
struct DatabaseCountryRules: Codable {
    let id: String
    let countryName: String
    let rules: [DatabaseRule]
    let lastUpdated: Date
    
    struct DatabaseRule: Codable {
        let id: String
        let title: String
        let description: String
        let category: String
        let importance: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case countryName = "country_name"
        case rules
        case lastUpdated = "last_updated"
    }
    
    func toCountryRules() -> CountryRules? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        
        let convertedRules = rules.compactMap { dbRule -> CountryRules.Rule? in
            guard let ruleId = UUID(uuidString: dbRule.id),
                  let category = CountryRules.Rule.RuleCategory(rawValue: dbRule.category),
                  let importance = CountryRules.Rule.Importance(rawValue: dbRule.importance) else {
                return nil
            }
            
            return CountryRules.Rule(
                id: ruleId,
                title: dbRule.title,
                description: dbRule.description,
                category: category,
                importance: importance
            )
        }
        
        return CountryRules(
            id: uuid,
            countryName: countryName,
            rules: convertedRules,
            lastUpdated: lastUpdated
        )
    }
    
    static func from(countryRules: CountryRules) -> DatabaseCountryRules {
        let dbRules = countryRules.rules.map { rule in
            DatabaseRule(
                id: rule.id.uuidString,
                title: rule.title,
                description: rule.description,
                category: rule.category.rawValue,
                importance: rule.importance.rawValue
            )
        }
        
        return DatabaseCountryRules(
            id: countryRules.id.uuidString,
            countryName: countryRules.countryName,
            rules: dbRules,
            lastUpdated: countryRules.lastUpdated
        )
    }
}

