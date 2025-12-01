import Foundation

class AIService {
    static let shared = AIService()
    
    private var provider: AIProvider
    
    private init() {
        // Initialize with the configured provider
        self.provider = AIService.createProvider()
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
                fatalError("OpenAI API key not configured")
            }
            return OpenAIProvider(
                apiKey: AIConfig.openAIAPIKey,
                model: AIConfig.openAIModel
            )
        }
    }
    
    func sendMessage(_ userMessage: String, conversationHistory: [ChatMessage]) async throws -> String {
        let systemPrompt = "You are a helpful travel assistant for a trip expense tracking app called Sensei. Help users track expenses, manage budgets, and plan their trips. Be friendly, concise, and helpful."
        
        return try await provider.sendMessage(userMessage, conversationHistory: conversationHistory, systemPrompt: systemPrompt)
    }
}

enum AIError: Error {
    case apiError(String)
    case parseError(String)
    case invalidAPIKey
}

