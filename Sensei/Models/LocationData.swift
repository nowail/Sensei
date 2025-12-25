import Foundation

struct Country: Identifiable, Hashable {
    let id: String
    let name: String
    let cities: [City]
}

struct City: Identifiable, Hashable {
    let id: String
    let name: String
}

class LocationDataProvider: ObservableObject {
    static let shared = LocationDataProvider()
    
    @Published var isLoadingCities = false
    
    // Comprehensive list of all countries
    let countries: [Country] = [
        // Americas
        Country(id: "us", name: "United States", cities: []),
        Country(id: "ca", name: "Canada", cities: []),
        Country(id: "mx", name: "Mexico", cities: []),
        Country(id: "br", name: "Brazil", cities: []),
        Country(id: "ar", name: "Argentina", cities: []),
        Country(id: "cl", name: "Chile", cities: []),
        Country(id: "co", name: "Colombia", cities: []),
        Country(id: "pe", name: "Peru", cities: []),
        Country(id: "ve", name: "Venezuela", cities: []),
        Country(id: "ec", name: "Ecuador", cities: []),
        
        // Europe
        Country(id: "uk", name: "United Kingdom", cities: []),
        Country(id: "fr", name: "France", cities: []),
        Country(id: "it", name: "Italy", cities: []),
        Country(id: "es", name: "Spain", cities: []),
        Country(id: "de", name: "Germany", cities: []),
        Country(id: "nl", name: "Netherlands", cities: []),
        Country(id: "pt", name: "Portugal", cities: []),
        Country(id: "gr", name: "Greece", cities: []),
        Country(id: "tr", name: "Turkey", cities: []),
        Country(id: "ru", name: "Russia", cities: []),
        Country(id: "pl", name: "Poland", cities: []),
        Country(id: "cz", name: "Czech Republic", cities: []),
        Country(id: "hu", name: "Hungary", cities: []),
        Country(id: "at", name: "Austria", cities: []),
        Country(id: "ch", name: "Switzerland", cities: []),
        Country(id: "be", name: "Belgium", cities: []),
        Country(id: "dk", name: "Denmark", cities: []),
        Country(id: "se", name: "Sweden", cities: []),
        Country(id: "no", name: "Norway", cities: []),
        Country(id: "fi", name: "Finland", cities: []),
        Country(id: "ie", name: "Ireland", cities: []),
        Country(id: "is", name: "Iceland", cities: []),
        Country(id: "ro", name: "Romania", cities: []),
        Country(id: "bg", name: "Bulgaria", cities: []),
        Country(id: "hr", name: "Croatia", cities: []),
        Country(id: "si", name: "Slovenia", cities: []),
        
        // Asia
        Country(id: "cn", name: "China", cities: []),
        Country(id: "jp", name: "Japan", cities: []),
        Country(id: "kr", name: "South Korea", cities: []),
        Country(id: "in", name: "India", cities: []),
        Country(id: "th", name: "Thailand", cities: []),
        Country(id: "sg", name: "Singapore", cities: []),
        Country(id: "my", name: "Malaysia", cities: []),
        Country(id: "id", name: "Indonesia", cities: []),
        Country(id: "vn", name: "Vietnam", cities: []),
        Country(id: "ph", name: "Philippines", cities: []),
        Country(id: "pk", name: "Pakistan", cities: []),
        Country(id: "bd", name: "Bangladesh", cities: []),
        Country(id: "lk", name: "Sri Lanka", cities: []),
        Country(id: "mm", name: "Myanmar", cities: []),
        Country(id: "kh", name: "Cambodia", cities: []),
        Country(id: "la", name: "Laos", cities: []),
        
        // Middle East
        Country(id: "ae", name: "United Arab Emirates", cities: []),
        Country(id: "sa", name: "Saudi Arabia", cities: []),
        Country(id: "qa", name: "Qatar", cities: []),
        Country(id: "kw", name: "Kuwait", cities: []),
        Country(id: "bh", name: "Bahrain", cities: []),
        Country(id: "om", name: "Oman", cities: []),
        Country(id: "jo", name: "Jordan", cities: []),
        Country(id: "lb", name: "Lebanon", cities: []),
        Country(id: "il", name: "Israel", cities: []),
        Country(id: "ir", name: "Iran", cities: []),
        Country(id: "iq", name: "Iraq", cities: []),
        
        // Africa
        Country(id: "za", name: "South Africa", cities: []),
        Country(id: "eg", name: "Egypt", cities: []),
        Country(id: "ma", name: "Morocco", cities: []),
        Country(id: "ke", name: "Kenya", cities: []),
        Country(id: "tz", name: "Tanzania", cities: []),
        Country(id: "et", name: "Ethiopia", cities: []),
        Country(id: "ng", name: "Nigeria", cities: []),
        Country(id: "gh", name: "Ghana", cities: []),
        Country(id: "tn", name: "Tunisia", cities: []),
        Country(id: "dz", name: "Algeria", cities: []),
        
        // Oceania
        Country(id: "au", name: "Australia", cities: []),
        Country(id: "nz", name: "New Zealand", cities: []),
        Country(id: "fj", name: "Fiji", cities: []),
        Country(id: "pg", name: "Papua New Guinea", cities: [])
    ]
    
    private init() {}
    
    /// Fetch cities for a country using Google Places API
    func fetchCities(for country: Country, completion: @escaping ([City]) -> Void) {
        isLoadingCities = true
        
        GooglePlacesService.shared.fetchCities(for: country.name) { [weak self] cities in
            DispatchQueue.main.async {
                self?.isLoadingCities = false
                completion(cities)
            }
        }
    }
    
    /// Search for cities with a query
    func searchCities(query: String, countryCode: String? = nil, completion: @escaping ([City]) -> Void) {
        isLoadingCities = true
        
        GooglePlacesService.shared.searchCities(query: query, countryCode: countryCode) { [weak self] cities in
            DispatchQueue.main.async {
                self?.isLoadingCities = false
                completion(cities)
            }
        }
    }
}

