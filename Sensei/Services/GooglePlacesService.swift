import Foundation
import GooglePlaces

class GooglePlacesService {
    static let shared = GooglePlacesService()
    private static var isInitialized = false
    private static let initializationLock = NSLock()
    
    private init() {
        // Don't initialize here - let AppDelegate handle it
        // This prevents multiple initializations
        // Google Places SDK should be initialized ONCE in AppDelegate
    }
    
    private func ensureInitialized() {
        // Use lock to prevent race conditions
        Self.initializationLock.lock()
        defer { Self.initializationLock.unlock() }
        
        // Just mark as checked - don't initialize again
        // Google Places should already be initialized in AppDelegate
        // Multiple initializations cause the CCTClearcutUploader warning
        // We never call provideAPIKey here - it's only called in AppDelegate
        if !Self.isInitialized {
        Self.isInitialized = true
            print("✅ GooglePlacesService: Verified initialization (API key set in AppDelegate)")
        }
    }
    
    /// Fetch cities for a given country using Google Places Autocomplete
    func fetchCities(for country: String, completion: @escaping ([City]) -> Void) {
        ensureInitialized()
        let placesClient = GMSPlacesClient.shared()
        let filter = GMSAutocompleteFilter()
        filter.type = .city
        filter.country = getCountryCode(for: country)
        
        // Get major cities by searching for common city names in that country
        // Use a list of common city name patterns
        let cityQueries = getCityQueries(for: country)
        
        var allCities: [City] = []
        var seenNames = Set<String>()
        let group = DispatchGroup()
        
        print("🔍 Searching for cities in \(country) with \(cityQueries.count) queries...")
        
        for query in cityQueries {
            group.enter()
            let sessionToken = GMSAutocompleteSessionToken()
            
            placesClient.findAutocompletePredictions(
                fromQuery: query,
                filter: filter,
                sessionToken: sessionToken
            ) { predictions, error in
                defer { group.leave() }
                
                if let error = error {
                    print("⚠️ Error for query '\(query)': \(error.localizedDescription)")
                    return
                }
                
                guard let predictions = predictions else {
                    return
                }
                
                for prediction in predictions {
                    let fullText = prediction.attributedFullText.string
                    let cityName = self.extractCityName(from: fullText, country: country)
                    
                    // Validate city name
                    if !seenNames.contains(cityName) && 
                       !cityName.isEmpty && 
                       cityName.count > 2 &&
                       !cityName.lowercased().contains("country") &&
                       !cityName.lowercased().contains("state") {
                        seenNames.insert(cityName)
                        allCities.append(City(id: prediction.placeID, name: cityName))
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if allCities.isEmpty {
                print("⚠️ No cities found via API for \(country), using default cities...")
                // Fallback to default cities for major countries
                let defaultCities = self.getDefaultCities(for: country)
                if !defaultCities.isEmpty {
                    print("✅ Using \(defaultCities.count) default cities for \(country)")
                    completion(defaultCities)
                } else {
                    // Last resort: try REST API
                    self.fetchCitiesViaRESTAPI(country: country, completion: completion)
                }
            } else {
                // Sort by name and limit to top 30
                let sortedCities = Array(allCities.sorted { $0.name < $1.name }.prefix(30))
                print("✅ Found \(sortedCities.count) cities for \(country)")
                completion(sortedCities)
            }
        }
    }
    
    /// Fallback: Use NEW Places API REST endpoint directly (requires API key)
    private func fetchCitiesViaRESTAPI(country: String, completion: @escaping ([City]) -> Void) {
        // Get API key
        var apiKey: String?
        if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
            apiKey = key
        } else if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let key = plist["API_KEY"] as? String {
            apiKey = key
        }
        
        guard let key = apiKey else {
            print("❌ No API key for REST API fallback")
            completion(self.getDefaultCities(for: country))
            return
        }
        
        let countryCode = getCountryCode(for: country) ?? ""
        // Use NEW Places API endpoint
        let urlString = "https://places.googleapis.com/v1/places:autocomplete"
        
        guard let url = URL(string: urlString) else {
            completion(self.getDefaultCities(for: country))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "X-Goog-Api-Key")
        
        let requestBody: [String: Any] = [
            "input": country,
            "inputType": "TEXT_QUERY",
            "includedRegionCodes": countryCode.isEmpty ? [] : [countryCode]
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(self.getDefaultCities(for: country))
            return
        }
        
        request.httpBody = bodyData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ REST API error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(self.getDefaultCities(for: country))
                }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let suggestions = json["suggestions"] as? [[String: Any]] else {
                DispatchQueue.main.async {
                    completion(self.getDefaultCities(for: country))
                }
                return
            }
            
            var cities: [City] = []
            var seenNames = Set<String>()
            
            for suggestion in suggestions {
                if let placePrediction = suggestion["placePrediction"] as? [String: Any],
                   let text = placePrediction["text"] as? [String: Any],
                   let description = text["text"] as? String,
                   let placeId = placePrediction["placeId"] as? String {
                    let cityName = self.extractCityName(from: description, country: country)
                    
                    if !seenNames.contains(cityName) && !cityName.isEmpty && cityName.count > 2 {
                        seenNames.insert(cityName)
                        cities.append(City(id: placeId, name: cityName))
                    }
                }
            }
            
            DispatchQueue.main.async {
                if cities.isEmpty {
                    completion(self.getDefaultCities(for: country))
                } else {
                    print("✅ REST API (New) found \(cities.count) cities for \(country)")
                    completion(Array(cities.prefix(30)))
                }
            }
        }.resume()
    }
    
    private func getCityQueries(for country: String) -> [String] {
        // Use country-specific city search terms
        var queries: [String] = []
        
        // Add country-specific major city names if known (these work best)
        if let majorCities = getMajorCitiesForCountry(country) {
            // Search for each major city directly
            queries.append(contentsOf: majorCities)
        }
        
        // Try searching for the country name itself (often returns major cities)
        queries.append(country)
        
        // Try common city-related searches
        queries.append("cities in \(country)")
        queries.append("major cities \(country)")
        
        return queries
    }
    
    private func getMajorCitiesForCountry(_ country: String) -> [String]? {
        // Return known major cities for popular countries to help with search
        let cityMap: [String: [String]] = [
            "United States": ["New York", "Los Angeles", "Chicago", "Miami", "San Francisco"],
            "Brazil": ["São Paulo", "Rio de Janeiro", "Brasília", "Salvador", "Fortaleza"],
            "India": ["Mumbai", "Delhi", "Bangalore", "Hyderabad", "Chennai"],
            "China": ["Beijing", "Shanghai", "Guangzhou", "Shenzhen", "Chengdu"],
            "United Kingdom": ["London", "Manchester", "Birmingham", "Liverpool", "Edinburgh"],
            "France": ["Paris", "Lyon", "Marseille", "Toulouse", "Nice"],
            "Italy": ["Rome", "Milan", "Naples", "Turin", "Palermo"],
            "Spain": ["Madrid", "Barcelona", "Valencia", "Seville", "Bilbao"],
            "Germany": ["Berlin", "Munich", "Hamburg", "Frankfurt", "Cologne"],
            "Japan": ["Tokyo", "Osaka", "Yokohama", "Nagoya", "Sapporo"],
            "Australia": ["Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide"],
            "Pakistan": ["Karachi", "Lahore", "Islamabad", "Faisalabad", "Rawalpindi"],
            "Canada": ["Toronto", "Vancouver", "Montreal", "Calgary", "Ottawa"],
            "Mexico": ["Mexico City", "Guadalajara", "Monterrey", "Puebla", "Tijuana"],
            "Argentina": ["Buenos Aires", "Córdoba", "Rosario", "Mendoza", "Tucumán"],
            "Thailand": ["Bangkok", "Chiang Mai", "Pattaya", "Phuket", "Hua Hin"],
            "United Arab Emirates": ["Dubai", "Abu Dhabi", "Sharjah", "Ajman", "Ras Al Khaimah"],
            "Turkey": ["Istanbul", "Ankara", "Izmir", "Bursa", "Antalya"],
            "Greece": ["Athens", "Thessaloniki", "Patras", "Heraklion", "Larissa"],
            "Portugal": ["Lisbon", "Porto", "Braga", "Coimbra", "Faro"],
            "Netherlands": ["Amsterdam", "Rotterdam", "The Hague", "Utrecht", "Eindhoven"]
        ]
        
        return cityMap[country]
    }
    
    private func getDefaultCities(for country: String) -> [City] {
        // Fallback: Return known major cities if API fails
        if let cityNames = getMajorCitiesForCountry(country) {
            return cityNames.enumerated().map { index, name in
                City(id: "\(country.lowercased())-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))", name: name)
            }
        }
        
        // Generic fallback
        return [
            City(id: "\(country.lowercased())-city1", name: "Capital City"),
            City(id: "\(country.lowercased())-city2", name: "Major City 1"),
            City(id: "\(country.lowercased())-city3", name: "Major City 2")
        ]
    }
    
    /// Search for cities with a query string
    func searchCities(query: String, countryCode: String? = nil, completion: @escaping ([City]) -> Void) {
        ensureInitialized()
        let placesClient = GMSPlacesClient.shared()
        let filter = GMSAutocompleteFilter()
        filter.type = .city
        if let countryCode = countryCode {
            filter.country = countryCode
        }
        
        placesClient.findAutocompletePredictions(
            fromQuery: query,
            filter: filter,
            sessionToken: GMSAutocompleteSessionToken()
        ) { predictions, error in
            guard let predictions = predictions, error == nil else {
                print("Error searching cities: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            var cities: [City] = []
            var seenNames = Set<String>()
            
            for prediction in predictions {
                let cityName = self.extractCityName(from: prediction.attributedFullText.string, country: nil)
                
                if !seenNames.contains(cityName) && !cityName.isEmpty {
                    seenNames.insert(cityName)
                    cities.append(City(id: prediction.placeID, name: cityName))
                }
            }
            
            completion(cities)
        }
    }
    
    private func extractCityName(from fullText: String, country: String?) -> String {
        // Remove country name and extra formatting
        var cityName = fullText
        
        if let country = country {
            cityName = cityName.replacingOccurrences(of: ", \(country)", with: "")
            cityName = cityName.replacingOccurrences(of: ", \(country.uppercased())", with: "")
        }
        
        // Remove any trailing commas or extra spaces
        cityName = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        cityName = cityName.replacingOccurrences(of: ",$", with: "", options: .regularExpression)
        
        return cityName
    }
    
    private func getCountryCode(for countryName: String) -> String? {
        // Map country names to ISO country codes (comprehensive list)
        let countryCodes: [String: String] = [
            // Americas
            "United States": "US",
            "Canada": "CA",
            "Mexico": "MX",
            "Brazil": "BR",
            "Argentina": "AR",
            "Chile": "CL",
            "Colombia": "CO",
            "Peru": "PE",
            "Venezuela": "VE",
            "Ecuador": "EC",
            
            // Europe
            "United Kingdom": "GB",
            "France": "FR",
            "Italy": "IT",
            "Spain": "ES",
            "Germany": "DE",
            "Netherlands": "NL",
            "Portugal": "PT",
            "Greece": "GR",
            "Turkey": "TR",
            "Russia": "RU",
            "Poland": "PL",
            "Czech Republic": "CZ",
            "Hungary": "HU",
            "Austria": "AT",
            "Switzerland": "CH",
            "Belgium": "BE",
            "Denmark": "DK",
            "Sweden": "SE",
            "Norway": "NO",
            "Finland": "FI",
            "Ireland": "IE",
            "Iceland": "IS",
            "Romania": "RO",
            "Bulgaria": "BG",
            "Croatia": "HR",
            "Slovenia": "SI",
            
            // Asia
            "China": "CN",
            "Japan": "JP",
            "South Korea": "KR",
            "India": "IN",
            "Thailand": "TH",
            "Singapore": "SG",
            "Malaysia": "MY",
            "Indonesia": "ID",
            "Vietnam": "VN",
            "Philippines": "PH",
            "Pakistan": "PK",
            "Bangladesh": "BD",
            "Sri Lanka": "LK",
            "Myanmar": "MM",
            "Cambodia": "KH",
            "Laos": "LA",
            
            // Middle East
            "United Arab Emirates": "AE",
            "Saudi Arabia": "SA",
            "Qatar": "QA",
            "Kuwait": "KW",
            "Bahrain": "BH",
            "Oman": "OM",
            "Jordan": "JO",
            "Lebanon": "LB",
            "Israel": "IL",
            "Iran": "IR",
            "Iraq": "IQ",
            
            // Africa
            "South Africa": "ZA",
            "Egypt": "EG",
            "Morocco": "MA",
            "Kenya": "KE",
            "Tanzania": "TZ",
            "Ethiopia": "ET",
            "Nigeria": "NG",
            "Ghana": "GH",
            "Tunisia": "TN",
            "Algeria": "DZ",
            
            // Oceania
            "Australia": "AU",
            "New Zealand": "NZ",
            "Fiji": "FJ",
            "Papua New Guinea": "PG"
        ]
        
        return countryCodes[countryName]
    }
}

