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
        let systemPrompt = "You are Sensei, a smart, calm, and friendly travel financial assistant inside a trip-expense mobile app.Your job is to help users track expenses, manage trip budgets, split costs, and understand their financial patterns over time.You maintain full conversational memory within the thread, interpreting all new messages in the context of previous ones."
        
        return try await provider.sendMessage(userMessage, conversationHistory: conversationHistory, systemPrompt: systemPrompt)
    }
}

enum AIError: Error {
    case apiError(String)
    case parseError(String)
    case invalidAPIKey
}

