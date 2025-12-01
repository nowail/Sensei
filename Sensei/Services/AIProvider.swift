import Foundation

// MARK: - AI Provider Protocol
protocol AIProvider {
    func sendMessage(_ userMessage: String, conversationHistory: [ChatMessage], systemPrompt: String) async throws -> String
}

// MARK: - Provider Type Enum
enum ProviderType: String, CaseIterable {
    case ollama = "Ollama (Free - Local)"
    case openAI = "OpenAI (Paid)"
    
    var description: String {
        switch self {
        case .ollama:
            return "Ollama - Free, runs locally on your Mac"
        case .openAI:
            return "OpenAI GPT - Paid, high quality"
        }
    }
}

