import Foundation

// MARK: - Ollama Provider (FREE - Runs Locally)
// Install Ollama from https://ollama.ai
// Then run: ollama pull llama3.2 (or any other model)
class OllamaProvider: AIProvider {
    private let baseURL: String
    private let model: String
    
    init(baseURL: String = "http://localhost:11434", model: String = "llama3.2") {
        self.baseURL = baseURL
        self.model = model
    }
    
    func sendMessage(_ userMessage: String, conversationHistory: [ChatMessage], systemPrompt: String) async throws -> String {
        var messages: [[String: Any]] = []
        
        // Add system message
        messages.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // Add conversation history
        for chatMessage in conversationHistory {
            if case .text(let content) = chatMessage.type {
                messages.append([
                    "role": chatMessage.isFromAI ? "assistant" : "user",
                    "content": content
                ])
            }
        }
        
        // Add current user message
        messages.append([
            "role": "user",
            "content": userMessage
        ])
        
        let url = URL(string: "\(baseURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.apiError("Ollama is not running. Please install from https://ollama.ai and start it.")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError("Failed to parse Ollama response")
        }
        
        return content
    }
}

