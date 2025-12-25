import SwiftUI

struct PlanTripView: View {
    @StateObject private var locationProvider = LocationDataProvider.shared
    @State private var selectedCountry: Country?
    @State private var selectedCity: City?
    @State private var availableCities: [City] = []
    @State private var numberOfDays: Int = 3
    @State private var priceRange: PriceRange = .medium
    @State private var selectedGenres: Set<TripGenre> = []
    @State private var showLocationPicker = false
    @State private var isGenerating = false
    @State private var generatedItinerary: Itinerary?
    @State private var showItinerary = false
    @State private var errorMessage: String?
    @State private var showAPITest = false
    @State private var apiTestResult: String = ""
    @State private var isTestingAPI = false
    
    private var location: String {
        if let city = selectedCity, let country = selectedCountry {
            return "\(city.name), \(country.name)"
        }
        return ""
    }
    
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
    
    enum PriceRange: String, CaseIterable {
        case budget = "Budget"
        case medium = "Medium"
        case luxury = "Luxury"
        
        var icon: String {
            switch self {
            case .budget: return "dollarsign.circle.fill"
            case .medium: return "dollarsign.circle"
            case .luxury: return "dollarsign.square.fill"
            }
        }
        
        var description: String {
            switch self {
            case .budget: return "Economical options"
            case .medium: return "Moderate spending"
            case .luxury: return "Premium experiences"
            }
        }
    }
    
    enum TripGenre: String, CaseIterable {
        case family = "Family"
        case solo = "Solo"
        case parties = "Parties"
        case adventure = "Adventure"
        case romantic = "Romantic"
        case business = "Business"
        case cultural = "Cultural"
        case relaxation = "Relaxation"
        
        var icon: String {
            switch self {
            case .family: return "figure.2.and.child.holdinghands"
            case .solo: return "person.fill"
            case .parties: return "party.popper.fill"
            case .adventure: return "mountain.2.fill"
            case .romantic: return "heart.fill"
            case .business: return "briefcase.fill"
            case .cultural: return "building.columns.fill"
            case .relaxation: return "beach.umbrella.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgGradient.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Plan Your Trip")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Let's create the perfect itinerary for you")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                // API Test Button
                                Button(action: {
                                    testAPIs()
                                }) {
                                    Image(systemName: "wifi.slash")
                                        .foregroundColor(accentGreen)
                                        .font(.system(size: 18))
                                        .padding(8)
                                        .background(cardColor.opacity(0.8))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // API Test Result
                        if !apiTestResult.isEmpty {
                            Text(apiTestResult)
                                .font(.system(size: 13))
                                .foregroundColor(apiTestResult.contains("✅") ? accentGreen : .red.opacity(0.8))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(cardColor.opacity(0.8))
                                .cornerRadius(12)
                        }
                        
                        // MARK: - Location Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Destination")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            // Country Picker
                            Menu {
                                ForEach(locationProvider.countries) { country in
                                    Button(action: {
                                        selectedCountry = country
                                        selectedCity = nil // Reset city when country changes
                                        availableCities = [] // Clear cities
                                        
                                        // Fetch cities from Google Places
                                        locationProvider.fetchCities(for: country) { cities in
                                            availableCities = cities
                                        }
                                    }) {
                                        HStack {
                                            Text(country.name)
                                            if selectedCountry?.id == country.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(accentGreen)
                                        .font(.system(size: 18))
                                    
                                    Text(selectedCountry?.name ?? "Select Country")
                                        .foregroundColor(selectedCountry == nil ? .white.opacity(0.5) : .white)
                                        .font(.system(size: 16))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.system(size: 12))
                                }
                                .padding()
                                .background(cardColor)
                                .cornerRadius(16)
                            }
                            
                            // City Picker (only show if country is selected)
                            if let country = selectedCountry {
                                if locationProvider.isLoadingCities {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: accentGreen))
                                        Text("Loading cities...")
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.system(size: 14))
                                    }
                                    .padding()
                                    .background(cardColor)
                                    .cornerRadius(16)
                                } else {
                                    Menu {
                                        if availableCities.isEmpty {
                                            Text("No cities found")
                                                .foregroundColor(.white.opacity(0.5))
                                        } else {
                                            ForEach(availableCities) { city in
                                                Button(action: {
                                                    selectedCity = city
                                                }) {
                                                    HStack {
                                                        Text(city.name)
                                                        if selectedCity?.id == city.id {
                                                            Image(systemName: "checkmark")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(accentGreen)
                                                .font(.system(size: 18))
                                            
                                            Text(selectedCity?.name ?? "Select City")
                                                .foregroundColor(selectedCity == nil ? .white.opacity(0.5) : .white)
                                                .font(.system(size: 16))
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.white.opacity(0.5))
                                                .font(.system(size: 12))
                                        }
                                        .padding()
                                        .background(cardColor)
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(cardColor.opacity(0.8))
                        .cornerRadius(20)
                        
                        // MARK: - Number of Days Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(accentGreen)
                                    .font(.system(size: 20))
                                
                                Text("\(numberOfDays) days")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                Stepper("", value: $numberOfDays, in: 1...30)
                                    .labelsHidden()
                            }
                            .padding()
                            .background(cardColor)
                            .cornerRadius(16)
                        }
                        .padding()
                        .background(cardColor.opacity(0.8))
                        .cornerRadius(20)
                        
                        // MARK: - Price Range Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Price Range")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(PriceRange.allCases, id: \.self) { range in
                                    PriceRangeCard(
                                        range: range,
                                        isSelected: priceRange == range,
                                        onTap: { priceRange = range }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(cardColor.opacity(0.8))
                        .cornerRadius(20)
                        
                        // MARK: - Genre Selection Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trip Style")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Select all that apply")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(TripGenre.allCases, id: \.self) { genre in
                                    GenreCard(
                                        genre: genre,
                                        isSelected: selectedGenres.contains(genre),
                                        onTap: {
                                            if selectedGenres.contains(genre) {
                                                selectedGenres.remove(genre)
                                            } else {
                                                selectedGenres.insert(genre)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(cardColor.opacity(0.8))
                        .cornerRadius(20)
                        
                        // MARK: - Generate Plan Button
                        Button(action: generatePlan) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1))))
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGenerating ? "Generating..." : "Generate Trip Plan")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentGreen)
                            .cornerRadius(20)
                            .shadow(color: accentGreen.opacity(0.3), radius: 20, y: 8)
                        }
                        .disabled(selectedCity == nil || selectedGenres.isEmpty || isGenerating)
                        .opacity(selectedCity == nil || selectedGenres.isEmpty || isGenerating ? 0.5 : 1.0)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red.opacity(0.8))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(cardColor.opacity(0.8))
                                .cornerRadius(12)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showItinerary) {
            if generatedItinerary != nil {
                NavigationStack {
                    ItineraryView(itinerary: Binding(
                        get: { generatedItinerary ?? Itinerary(location: "", numberOfDays: 0, priceRange: "", genres: [], days: []) },
                        set: { generatedItinerary = $0 }
                    ), isGenerating: $isGenerating)
                }
            }
        }
    }
    
    func testAPIs() {
        isTestingAPI = true
        apiTestResult = "Testing APIs..."
        
        Task {
            var results: [String] = []
            
            // Test OpenAI
            print("🔍 Testing OpenAI API...")
            let openAITest = await APITestService.shared.testOpenAIAPI()
            var openAIResult = "OpenAI: \(openAITest.message)"
            if let time = openAITest.responseTime {
                openAIResult += " (\(String(format: "%.2f", time))s)"
            }
            results.append(openAIResult)
            
            // Test Google Maps
            print("🔍 Testing Google Maps API...")
            let mapsTest = APITestService.shared.testGoogleMapsAPI()
            results.append("Google Maps: \(mapsTest.message)")
            
            // Test Google Places with actual API call
            print("🔍 Testing Google Places API...")
            let placesTest = await APITestService.shared.testGooglePlacesAPI()
            var placesResult = "Google Places: \(placesTest.message)"
            if let time = placesTest.responseTime {
                placesResult += " (\(String(format: "%.2f", time))s)"
            }
            results.append(placesResult)
            
            let finalResult = results.joined(separator: "\n\n")
            
            await MainActor.run {
                apiTestResult = finalResult
                isTestingAPI = false
                print("✅ API Tests Complete:\n\(finalResult)")
            }
        }
    }
    
    func generatePlan() {
        guard let city = selectedCity, !selectedGenres.isEmpty else { return }
        
        isGenerating = true
        errorMessage = nil
        
        // Create a placeholder itinerary to show immediately
        let placeholderItinerary = Itinerary(
            location: location,
            numberOfDays: numberOfDays,
            priceRange: priceRange.rawValue,
            genres: selectedGenres.map { $0.rawValue },
            days: []
        )
        
        generatedItinerary = placeholderItinerary
        showItinerary = true
        
        Task {
            do {
                let genresList = selectedGenres.map { $0.rawValue }
                let response = try await AIService.shared.generateItinerary(
                    location: location,
                    numberOfDays: numberOfDays,
                    priceRange: priceRange.rawValue,
                    genres: genresList
                )
                
                // Parse JSON response
                if let itinerary = parseItineraryResponse(response) {
                    await MainActor.run {
                        generatedItinerary = itinerary
                        isGenerating = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Failed to parse itinerary. Please try again."
                        isGenerating = false
                        showItinerary = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error generating itinerary: \(error.localizedDescription)"
                    isGenerating = false
                    showItinerary = false
                }
            }
        }
    }
    
    func parseItineraryResponse(_ response: String) -> Itinerary? {
        // Extract JSON from response (might have markdown code blocks)
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if jsonString.hasPrefix("```") {
            let lines = jsonString.components(separatedBy: .newlines)
            if lines.count > 2 {
                jsonString = lines.dropFirst().dropLast().joined(separator: "\n")
            }
        }
        
        // Remove any leading/trailing text before/after JSON
        // Find first { and last } safely
        guard let firstBraceIndex = jsonString.firstIndex(of: "{"),
              let lastBraceIndex = jsonString.lastIndex(of: "}"),
              firstBraceIndex < lastBraceIndex else {
            print("❌ Failed to find JSON boundaries in response")
            return nil
        }
        
        // Safely extract JSON substring
        let startIndex = firstBraceIndex
        let endIndex = jsonString.index(after: lastBraceIndex)
        
        // Verify indices are valid
        guard startIndex < endIndex,
              endIndex <= jsonString.endIndex else {
            print("❌ Invalid JSON indices")
            return nil
        }
        
        jsonString = String(jsonString[startIndex..<endIndex])
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let daysArray = json["days"] as? [[String: Any]] else {
            print("Failed to parse JSON: \(jsonString)")
            return nil
        }
        
        var itineraryDays: [ItineraryDay] = []
        
        for dayDict in daysArray {
            guard let dayNumber = dayDict["dayNumber"] as? Int,
                  let activitiesArray = dayDict["activities"] as? [[String: Any]] else {
                continue
            }
            
            var activities: [Activity] = []
            
            for activityDict in activitiesArray {
                guard let name = activityDict["name"] as? String,
                      let description = activityDict["description"] as? String,
                      let time = activityDict["time"] as? String,
                      let location = activityDict["location"] as? String,
                      let category = activityDict["category"] as? String else {
                    continue
                }
                
                // Geocode location to get coordinates (async, will be done later)
                let activity = Activity(
                    name: name,
                    description: description,
                    time: time,
                    location: location,
                    category: category
                )
                activities.append(activity)
            }
            
            if !activities.isEmpty {
                itineraryDays.append(ItineraryDay(dayNumber: dayNumber, activities: activities))
            }
        }
        
        if itineraryDays.isEmpty {
            return nil
        }
        
        // Sort days by day number
        itineraryDays.sort { $0.dayNumber < $1.dayNumber }
        
        return Itinerary(
            location: location,
            numberOfDays: numberOfDays,
            priceRange: priceRange.rawValue,
            genres: selectedGenres.map { $0.rawValue },
            days: itineraryDays
        )
    }
}

// MARK: - Supporting Views

struct PriceRangeCard: View {
    let range: PlanTripView.PriceRange
    let isSelected: Bool
    let onTap: () -> Void
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: range.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? accentGreen : .white.opacity(0.6))
                
                Text(range.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Text(range.description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? accentGreen.opacity(0.2) : cardColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentGreen : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct GenreCard: View {
    let genre: PlanTripView.TripGenre
    let isSelected: Bool
    let onTap: () -> Void
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: genre.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? accentGreen : .white.opacity(0.6))
                    .frame(width: 30)
                
                Text(genre.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentGreen)
                        .font(.system(size: 20))
                }
            }
            .padding()
            .background(isSelected ? accentGreen.opacity(0.2) : cardColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? accentGreen : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

#Preview {
    PlanTripView()
}

