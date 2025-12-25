import Foundation

class APITestService {
    static let shared = APITestService()
    
    private init() {}
    
    /// Test OpenAI API key and connection
    func testOpenAIAPI() async -> (isValid: Bool, message: String, responseTime: TimeInterval?) {
        let startTime = Date()
        
        // Check if API key exists
        let apiKey = AIConfig.openAIAPIKey
        guard !apiKey.isEmpty else {
            return (false, "❌ OpenAI API key is not configured. Please set OPENAI_API_KEY in .env file or environment variables.", nil)
        }
        
        guard apiKey != "YOUR_OPENAI_API_KEY" else {
            return (false, "❌ OpenAI API key is set to placeholder value. Please set a valid API key.", nil)
        }
        
        // Test with a simple API call
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // 10 second timeout
        
        let requestBody: [String: Any] = [
            "model": AIConfig.openAIModel,
            "messages": [
                ["role": "user", "content": "Say 'API test successful' if you can read this."]
            ],
            "max_tokens": 20,
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "❌ Invalid response from server", responseTime)
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Parse response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    return (true, "✅ OpenAI API is working! Response: \(content.trimmingCharacters(in: .whitespacesAndNewlines))", responseTime)
                } else {
                    return (true, "✅ OpenAI API is working! (Response received in \(String(format: "%.2f", responseTime))s)", responseTime)
                }
                
            case 401:
                return (false, "❌ Invalid API key. Please check your OPENAI_API_KEY.", responseTime)
                
            case 429:
                return (false, "⚠️ Rate limit exceeded. Please try again later.", responseTime)
                
            case 500...599:
                return (false, "❌ OpenAI server error. Please try again later.", responseTime)
                
            default:
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return (false, "❌ Error: \(message)", responseTime)
                } else {
                    return (false, "❌ API request failed with status code: \(httpResponse.statusCode)", responseTime)
                }
            }
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    return (false, "❌ Request timed out after \(String(format: "%.1f", responseTime))s. Check your internet connection.", responseTime)
                case .notConnectedToInternet:
                    return (false, "❌ No internet connection.", responseTime)
                default:
                    return (false, "❌ Network error: \(urlError.localizedDescription)", responseTime)
                }
            }
            return (false, "❌ Error: \(error.localizedDescription)", responseTime)
        }
    }
    
    /// Test Google Places API with actual API call
    func testGooglePlacesAPI() async -> (isValid: Bool, message: String, responseTime: TimeInterval?) {
        let startTime = Date()
        
        // Check if API key exists
        var apiKey: String?
        if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
            apiKey = key
        } else if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let key = plist["API_KEY"] as? String {
            apiKey = key
        }
        
        guard let key = apiKey, !key.isEmpty else {
            return (false, "❌ Google Places API key not found in Info.plist or GoogleService-Info.plist", nil)
        }
        
        // Test with actual API call using NEW Places API (not legacy)
        let testQuery = "Paris, France"
        // Use the new Places API endpoint
        let urlString = "https://places.googleapis.com/v1/places:autocomplete?key=\(key)"
        
        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURL) else {
            return (false, "❌ Failed to create API request URL", nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "X-Goog-Api-Key")
        request.timeoutInterval = 10.0
        
        // New Places API request body
        let requestBody: [String: Any] = [
            "input": testQuery,
            "inputType": "TEXT_QUERY",
            "includedRegionCodes": ["FR"]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "❌ Invalid response from Google Places API", responseTime)
            }
            
            switch httpResponse.statusCode {
            case 200:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let suggestions = json["suggestions"] as? [[String: Any]], !suggestions.isEmpty {
                        return (true, "✅ Google Places API (New) is working! Found \(suggestions.count) results for '\(testQuery)'", responseTime)
                    } else {
                        return (true, "✅ Google Places API (New) responded (no results for test query)", responseTime)
                    }
                }
                return (true, "✅ Google Places API (New) responded (response time: \(String(format: "%.2f", responseTime))s)", responseTime)
                
            case 400:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return (false, "❌ Google Places API error: \(message)", responseTime)
                }
                return (false, "❌ Google Places API bad request. Check API key and enable Places API (New) in Google Cloud Console.", responseTime)
            case 403:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return (false, "❌ Google Places API denied: \(message)", responseTime)
                }
                return (false, "❌ Google Places API access forbidden. Check API key and enable Places API (New) in Google Cloud Console.", responseTime)
            default:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return (false, "❌ Google Places API error: \(message)", responseTime)
                }
                return (false, "❌ Google Places API error: HTTP \(httpResponse.statusCode)", responseTime)
            }
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    return (false, "❌ Google Places API request timed out after \(String(format: "%.1f", responseTime))s", responseTime)
                case .notConnectedToInternet:
                    return (false, "❌ No internet connection for Google Places API", responseTime)
                default:
                    return (false, "❌ Network error: \(urlError.localizedDescription)", responseTime)
                }
            }
            return (false, "❌ Error: \(error.localizedDescription)", responseTime)
        }
    }
    
    /// Test Google Maps API (check if map can be initialized)
    func testGoogleMapsAPI() -> (isValid: Bool, message: String) {
        // Check if API key exists
        var apiKey: String?
        if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
            apiKey = key
        } else if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let key = plist["API_KEY"] as? String {
            apiKey = key
        }
        
        guard let key = apiKey, !key.isEmpty else {
            return (false, "❌ Google Maps API key not found in Info.plist or GoogleService-Info.plist")
        }
        
        // Test if Maps SDK is initialized
        // We can check by trying to create a map view (but we'll just verify the key exists and is valid format)
        if key.hasPrefix("AIza") && key.count > 30 {
            return (true, "✅ Google Maps API key found and format looks valid: \(String(key.prefix(15)))...")
        } else {
            return (false, "❌ Google Maps API key format appears invalid")
        }
    }
}

