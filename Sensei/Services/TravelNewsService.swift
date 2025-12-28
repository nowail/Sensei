import Foundation

struct TravelNewsItem: Identifiable {
    let id: UUID
    let title: String
    let source: String
    let publishedAt: Date?
    
    init(id: UUID = UUID(), title: String, source: String, publishedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.source = source
        self.publishedAt = publishedAt
    }
}

class TravelNewsService: ObservableObject {
    static let shared = TravelNewsService()
    
    @Published var newsItems: [TravelNewsItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var apiKey: String {
        // First try environment variable
        if let envKey = ProcessInfo.processInfo.environment["NEWS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Then try .env file
        if let envKey = EnvLoader.shared.get("NEWS_API_KEY"), !envKey.isEmpty {
            return envKey
        }
        // Fallback - user needs to set this
        return ""
    }
    
    private let baseURL = "https://newsapi.org/v2"
    private var lastFetchTime: Date?
    private var currentCacheKey: String = ""
    private let cacheDuration: TimeInterval = 3600 // Cache for 1 hour
    
    private init() {
        // Load default/fallback news items
        loadDefaultNews()
    }
    
    /// Fetch travel news from NewsAPI
    /// - Parameter locations: Array of location names (countries, cities) to filter news by
    func fetchTravelNews(locations: [String] = []) async {
        // Check cache (but invalidate if locations changed)
        let locationKey = locations.sorted().joined(separator: ",")
        let cacheKey = "\(lastFetchTime?.timeIntervalSince1970 ?? 0)_\(locationKey)"
        
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheDuration,
           !newsItems.isEmpty,
           currentCacheKey == cacheKey {
            print("📰 Using cached travel news")
            return
        }
        
        currentCacheKey = cacheKey
        
        guard !apiKey.isEmpty else {
            print("⚠️ NewsAPI key not configured, using default news")
            await MainActor.run {
                // Update default news with locations if provided
                if !locations.isEmpty {
                    loadDefaultNews(locations: locations)
                }
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Build search query based on locations
        var searchQuery = ""
        
        if !locations.isEmpty {
            // Use locations in the search query
            let locationTerms = locations.prefix(3).joined(separator: " OR ") // Limit to 3 locations
            let travelKeywords = ["travel", "airline", "airport", "tourism", "flight"]
            let randomKeyword = travelKeywords.randomElement() ?? "travel"
            
            // Combine location with travel keyword: "(Turkey OR Pakistan) AND travel"
            searchQuery = "(\(locationTerms)) AND \(randomKeyword)"
        } else {
            // Fallback to general travel news
            let keywords = ["travel", "airline", "airport", "tourism", "flight", "vacation"]
            searchQuery = keywords.randomElement() ?? "travel"
        }
        
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
        let urlString = "\(baseURL)/everything?q=\(encodedQuery)&sortBy=publishedAt&language=en&pageSize=15&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Invalid URL"
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TravelNewsError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw TravelNewsError.unauthorized
            case 429:
                throw TravelNewsError.rateLimitExceeded
            default:
                throw TravelNewsError.apiError("NewsAPI returned status code: \(httpResponse.statusCode)")
            }
            
            // Parse JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let articles = json["articles"] as? [[String: Any]] else {
                throw TravelNewsError.parseError("Failed to parse NewsAPI response")
            }
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            var fetchedNews: [TravelNewsItem] = []
            
            for article in articles {
                guard let title = article["title"] as? String,
                      !title.isEmpty,
                      let source = article["source"] as? [String: Any],
                      let sourceName = source["name"] as? String else {
                    continue
                }
                
                // Skip if title contains unwanted keywords
                let lowerTitle = title.lowercased()
                if lowerTitle.contains("breaking") && lowerTitle.contains("live") {
                    continue
                }
                
                var publishedDate: Date?
                if let publishedAtString = article["publishedAt"] as? String {
                    publishedDate = dateFormatter.date(from: publishedAtString)
                }
                
                let newsItem = TravelNewsItem(
                    title: title,
                    source: sourceName,
                    publishedAt: publishedDate
                )
                fetchedNews.append(newsItem)
            }
            
            await MainActor.run {
                if !fetchedNews.isEmpty {
                    newsItems = fetchedNews
                    lastFetchTime = Date()
                    print("✅ Fetched \(fetchedNews.count) travel news items for locations: \(locations.isEmpty ? "general" : locations.joined(separator: ", "))")
                } else {
                    print("⚠️ No travel news items found, using defaults")
                    // Use personalized defaults if locations provided
                    if !locations.isEmpty {
                        loadDefaultNews(locations: locations)
                    }
                }
                isLoading = false
            }
        } catch {
            print("⚠️ Error fetching travel news: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                // Use personalized defaults if locations provided
                if !locations.isEmpty {
                    loadDefaultNews(locations: locations)
                }
                isLoading = false
            }
        }
    }
    
    /// Load default/fallback news items
    /// - Parameter locations: Optional locations to personalize default news
    private func loadDefaultNews(locations: [String] = []) {
        var defaultNews: [TravelNewsItem] = []
        
        if !locations.isEmpty {
            // Create location-specific default news
            let location = locations.first ?? "your destination"
            defaultNews = [
                TravelNewsItem(
                    title: "Latest travel updates and news for \(location)",
                    source: "Travel News"
                ),
                TravelNewsItem(
                    title: "New flights and routes to \(location) announced",
                    source: "Aviation Weekly"
                ),
                TravelNewsItem(
                    title: "Travel tips and insights for visiting \(location)",
                    source: "Travel Guide"
                ),
                TravelNewsItem(
                    title: "Airline industry updates: Routes to \(location)",
                    source: "Flight News"
                ),
                TravelNewsItem(
                    title: "Tourism trends and updates for \(location)",
                    source: "Travel Insights"
                )
            ]
        } else {
            // General default news
            defaultNews = [
                TravelNewsItem(
                    title: "New direct flights connecting major travel destinations announced",
                    source: "Travel News"
                ),
                TravelNewsItem(
                    title: "Airline industry sees record passenger numbers this season",
                    source: "Aviation Weekly"
                ),
                TravelNewsItem(
                    title: "Top 10 travel destinations for 2024 revealed by travel experts",
                    source: "Travel Guide"
                ),
                TravelNewsItem(
                    title: "Airport security updates: New streamlined process for international travelers",
                    source: "Travel Security"
                ),
                TravelNewsItem(
                    title: "Sustainable travel trends: Eco-friendly hotels and carbon-neutral flights on the rise",
                    source: "Green Travel"
                ),
                TravelNewsItem(
                    title: "Travel tech: New apps help travelers find best deals and avoid crowds",
                    source: "Tech Travel"
                ),
                TravelNewsItem(
                    title: "Airlines introduce new routes to popular vacation spots",
                    source: "Flight News"
                ),
                TravelNewsItem(
                    title: "Travel insurance tips: What every traveler should know before booking",
                    source: "Travel Insurance"
                )
            ]
        }
        
        newsItems = defaultNews
    }
}

enum TravelNewsError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case apiError(String)
    case parseError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL for news request"
        case .invalidResponse:
            return "Invalid response from NewsAPI"
        case .unauthorized:
            return "Unauthorized - check your NewsAPI key"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .apiError(let message):
            return "NewsAPI error: \(message)"
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}

