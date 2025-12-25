import Foundation
import UIKit

// MARK: - OpenAI Provider (PAID)
class OpenAIProvider: AIProvider {
    private let apiKey: String
    private let model: String
    
    init(apiKey: String, model: String) {
        self.apiKey = apiKey
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
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.apiError("Invalid response from server")
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.apiError("Rate limit exceeded. Please try again in a moment.")
        case 500...599:
            throw AIError.apiError("Server error. Please try again later.")
        default:
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            } else {
                throw AIError.apiError("API request failed with status code: \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError("Failed to parse API response")
        }
        
        return content
    }
    
    func sendMessageWithTokens(_ userMessage: String, conversationHistory: [ChatMessage], systemPrompt: String, maxTokens: Int) async throws -> String {
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
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": maxTokens
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.apiError("Invalid response from server")
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.apiError("Rate limit exceeded. Please try again in a moment.")
        case 500...599:
            throw AIError.apiError("Server error. Please try again later.")
        default:
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            } else {
                throw AIError.apiError("API request failed with status code: \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError("Failed to parse API response")
        }
        
        return content
    }
    
    // Generate image using DALL-E API
    func generateImage(prompt: String) async throws -> UIImage {
        // Check if API key is set
        guard !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY" else {
            print("❌ OpenAI API key not configured for image generation")
            throw AIError.invalidAPIKey
        }
        
        print("🎨 Requesting image generation from DALL-E...")
        let url = URL(string: "https://api.openai.com/v1/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "standard"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📤 Sending image generation request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📥 Received response from DALL-E API")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.apiError("Invalid response from server")
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.apiError("Rate limit exceeded. Please try again in a moment.")
        case 500...599:
            throw AIError.apiError("Server error. Please try again later.")
        default:
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            } else {
                throw AIError.apiError("Image generation failed with status code: \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstImage = dataArray.first,
              let imageUrlString = firstImage["url"] as? String,
              let imageUrl = URL(string: imageUrlString) else {
            throw AIError.parseError("Failed to parse image generation response")
        }
        
        // Download the image
        print("📥 Downloading image from: \(imageUrlString)")
        let (imageData, imageResponse) = try await URLSession.shared.data(from: imageUrl)
        
        guard let httpImageResponse = imageResponse as? HTTPURLResponse,
              httpImageResponse.statusCode == 200,
              let image = UIImage(data: imageData) else {
            print("❌ Failed to download or decode image")
            throw AIError.parseError("Failed to download generated image")
        }
        
        print("✅ Image downloaded and decoded successfully (size: \(imageData.count) bytes)")
        return image
    }
}

