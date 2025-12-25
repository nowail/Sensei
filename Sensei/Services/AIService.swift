import Foundation

class AIService {
    static let shared = AIService()
    
    private var _provider: AIProvider?
    private var provider: AIProvider {
        if let existing = _provider {
            return existing
        }
        let newProvider = AIService.createProvider()
        _provider = newProvider
        return newProvider
    }
    
    private init() {
        // Lazy initialization - provider will be created on first use
    }
    
    // Factory method to create the appropriate provider
    private static func createProvider() -> AIProvider {
        switch AIConfig.providerType {
        case .ollama:
            return OllamaProvider(
                baseURL: AIConfig.ollamaBaseURL,
                model: AIConfig.ollamaModel
            )
        case .openAI:
            guard AIConfig.openAIAPIKey != "YOUR_OPENAI_API_KEY" && !AIConfig.openAIAPIKey.isEmpty else {
                // Return a mock provider that shows an error message instead of crashing
                return ErrorProvider(errorMessage: "OpenAI API key not configured. Please set OPENAI_API_KEY environment variable or update AIConfig.swift")
            }
            return OpenAIProvider(
                apiKey: AIConfig.openAIAPIKey,
                model: AIConfig.openAIModel
            )
        }
    }
    
    func sendMessage(_ userMessage: String, conversationHistory: [ChatMessage]) async throws -> String {
        let systemPrompt = "You are Sensei, a smart, calm, and friendly travel financial assistant inside a trip-expense mobile app.Your job is to help users track expenses, manage trip budgets, split costs, and understand their financial patterns over time.You maintain full conversational memory within the thread, interpreting all new messages in the context of previous ones."
        
        return try await provider.sendMessage(userMessage, conversationHistory: conversationHistory, systemPrompt: systemPrompt)
    }
    
    func generateItinerary(location: String, numberOfDays: Int, priceRange: String, genres: [String]) async throws -> String {
        let genresText = genres.joined(separator: ", ")
        let prompt = """
        Create a detailed \(numberOfDays)-day travel itinerary for \(location) with a \(priceRange) budget. 
        Trip style: \(genresText).
        
        Format the response as a JSON object with this exact structure:
        {
          "days": [
            {
              "dayNumber": 1,
              "activities": [
                {
                  "name": "Activity name",
                  "description": "Brief description",
                  "time": "09:00 AM",
                  "location": "Full address or location name",
                  "category": "Restaurant/Attraction/Hotel/Activity"
                }
              ]
            }
          ]
        }
        
        Include 3-4 activities per day covering meals, attractions, and experiences. Keep descriptions brief (1 sentence). Make it realistic and enjoyable.
        Return ONLY valid JSON, no additional text or markdown.
        """
        
        let systemPrompt = "You are an expert travel planner. Generate concise, practical itineraries in JSON format only. Always return valid JSON without markdown code blocks or additional text. Keep responses under 1500 tokens."
        
        // Use OpenAI provider directly with optimized token limit for faster generation
        if let openAIProvider = provider as? OpenAIProvider {
            return try await openAIProvider.sendMessageWithTokens(
                prompt,
                conversationHistory: [],
                systemPrompt: systemPrompt,
                maxTokens: 1500
            )
        }
        
        return try await provider.sendMessage(prompt, conversationHistory: [], systemPrompt: systemPrompt)
    }
}

enum AIError: Error {
    case apiError(String)
    case parseError(String)
    case invalidAPIKey
}

// MARK: - Error Provider (for when API key is missing)
class ErrorProvider: AIProvider {
    let errorMessage: String
    
    init(errorMessage: String) {
        self.errorMessage = errorMessage
    }
    
    func sendMessage(_ userMessage: String, conversationHistory: [ChatMessage], systemPrompt: String) async throws -> String {
        throw AIError.invalidAPIKey
    }
}

