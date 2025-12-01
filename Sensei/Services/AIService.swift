import Foundation

class AIService {
    static let shared = AIService()
    
    private let apiKey = AIConfig.openAIAPIKey
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let model = AIConfig.model
    
    private init() {}
    
    func sendMessage(_ userMessage: String, conversationHistory: [ChatMessage]) async throws -> String {
        // Prepare conversation history for the API
        var messages: [[String: Any]] = []
        
        // Add system message to set context
        messages.append([
            "role": "system",
            "content": "You are a helpful travel assistant for a trip expense tracking app called Sensei. Help users track expenses, manage budgets, and plan their trips. Be friendly, concise, and helpful."
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
        
        // Create request
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        // Check if API key is set (not the placeholder)
        guard apiKey != "YOUR_OPENAI_API_KEY" && !apiKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.apiError("Invalid response from server")
        }
        
        // Handle different HTTP status codes
        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 401:
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.apiError("Rate limit exceeded. Please try again in a moment.")
        case 500...599:
            throw AIError.apiError("Server error. Please try again later.")
        default:
            // Try to parse error message from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            } else {
                throw AIError.apiError("API request failed with status code: \(httpResponse.statusCode)")
            }
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError("Failed to parse API response")
        }
        
        return content
    }
}

enum AIError: Error {
    case apiError(String)
    case parseError(String)
    case invalidAPIKey
}

