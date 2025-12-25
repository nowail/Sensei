import Foundation
import UIKit

class PexelsImageService {
    static let shared = PexelsImageService()
    
    // Pexels API key - Get free key from https://www.pexels.com/api/
    // Steps:
    // 1. Go to https://www.pexels.com/api/
    // 2. Sign up for free account
    // 3. Get your API key
    // 4. Set it as environment variable: PEXELS_API_KEY
    //    Or add to .env file: PEXELS_API_KEY=your_key_here
    // Free tier: 200 requests per hour, 20,000 per month
    private var apiKey: String {
        // First try environment variable - check both spellings (PEXELS and PIXELS)
        if let envKey = ProcessInfo.processInfo.environment["PEXELS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let envKey = ProcessInfo.processInfo.environment["PIXELS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Then try .env file - check both spellings
        if let envKey = EnvLoader.shared.get("PEXELS_API_KEY"), !envKey.isEmpty {
            return envKey
        }
        if let envKey = EnvLoader.shared.get("PIXELS_API_KEY"), !envKey.isEmpty {
            return envKey
        }
        // Fallback - user needs to set this
        return ""
    }
    
    private let baseURL = "https://api.pexels.com/v1"
    
    private init() {}
    
    /// Fetch a travel image for a country/location
    /// - Parameters:
    ///   - country: The country name
    ///   - page: Optional page number for randomization (1-80, Pexels allows up to 80 pages)
    func fetchTravelImage(for country: String, page: Int? = nil) async throws -> UIImage {
        guard !apiKey.isEmpty else {
            print("❌ Pexels API key is missing or empty")
            throw ImageServiceError.apiKeyMissing
        }
        
        print("🔑 Using Pexels API key (length: \(apiKey.count))")
        
        // Search for travel/tourism images of the country
        // Add variety by using different search terms and random page selection
        let searchTerms = [
            "\(country) travel",
            "\(country) tourism",
            "\(country) landscape",
            "\(country) city",
            "\(country) destination"
        ]
        
        // Randomly select a search term for variety
        let randomTerm = searchTerms.randomElement() ?? "\(country) travel"
        
        // Use random page (1-10) for variety, or provided page
        let pageNumber = page ?? Int.random(in: 1...10)
        
        // Get multiple results and pick a random one for more variety
        let perPage = 15 // Get 15 results
        let urlString = "\(baseURL)/search?query=\(randomTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? randomTerm)&per_page=\(perPage)&page=\(pageNumber)&orientation=landscape&size=medium"
        
        guard let url = URL(string: urlString) else {
            throw ImageServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📸 Fetching image from Pexels for: \(country)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageServiceError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw ImageServiceError.unauthorized
        case 429:
            throw ImageServiceError.rateLimitExceeded
        default:
            throw ImageServiceError.apiError("Pexels API returned status code: \(httpResponse.statusCode)")
        }
        
        // Parse JSON response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let photos = json["photos"] as? [[String: Any]],
              !photos.isEmpty else {
            throw ImageServiceError.parseError("No photos found in Pexels API response")
        }
        
        // Randomly select a photo from the results for variety
        let randomPhoto = photos.randomElement()!
        guard let src = randomPhoto["src"] as? [String: Any],
              // Prefer medium size for faster loading, fallback to large, then original
              let imageUrlString = src["medium"] as? String ?? src["large"] as? String ?? src["original"] as? String,
              let imageUrl = URL(string: imageUrlString) else {
            throw ImageServiceError.parseError("Failed to parse photo data from Pexels API response")
        }
        
        print("📸 Selected random photo from \(photos.count) results (using medium size for faster loading)")
        
        print("📥 Downloading image from: \(imageUrlString)")
        
        // Download the image
        let (imageData, imageResponse) = try await URLSession.shared.data(from: imageUrl)
        
        guard let httpImageResponse = imageResponse as? HTTPURLResponse,
              httpImageResponse.statusCode == 200,
              let image = UIImage(data: imageData) else {
            throw ImageServiceError.downloadError("Failed to download or decode image")
        }
        
        print("✅ Image downloaded successfully (size: \(imageData.count) bytes)")
        return image
    }
}

enum ImageServiceError: Error {
    case apiKeyMissing
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case apiError(String)
    case parseError(String)
    case downloadError(String)
    
    var localizedDescription: String {
        switch self {
        case .apiKeyMissing:
            return "Pexels API key not configured. Please set PEXELS_API_KEY environment variable or add it to .env file"
        case .invalidURL:
            return "Invalid URL for image request"
        case .invalidResponse:
            return "Invalid response from Pexels API"
        case .unauthorized:
            return "Unauthorized - check your Pexels API key"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .apiError(let message):
            return "Pexels API error: \(message)"
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        case .downloadError(let message):
            return "Failed to download image: \(message)"
        }
    }
}

