import Foundation

struct AIConfig {
    // ============================================
    // CHOOSE YOUR AI PROVIDER (Change providerType)
    // ============================================
    // Options:
    // - .ollama (FREE - runs locally on your Mac)
    // - .openAI (PAID - but high quality)
    
    static let providerType: ProviderType = .openAI  // 👈 Using OpenAI - API key loaded from .env file or environment variable
    
    // ============================================
    // OLLAMA CONFIGURATION (FREE - Local)
    // ============================================
    // Install: https://ollama.ai
    // Then run: ollama pull llama3.2 (or qwen2.5, mistral, phi, etc.)
    static let ollamaBaseURL = "http://localhost:11434"
    static let ollamaModel = "qwen2.5"  // Options: "qwen2.5", "qwen2", "llama3.2", "mistral", "phi", etc.
    
    // ============================================
    // OPENAI CONFIGURATION (PAID)
    // ============================================
    // Get API key: https://platform.openai.com/api-keys
    // Set your API key as an environment variable: OPENAI_API_KEY
    // Or create a local AIConfig.local.swift file (gitignored) with your key
    static var openAIAPIKey: String {
        // First try environment variable (from Xcode scheme)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Then try .env file
        if let envKey = EnvLoader.shared.get("OPENAI_API_KEY"), !envKey.isEmpty {
            return envKey
        }
        // Fallback to empty string - user must set it
        return ""
    }
    static let openAIModel = "gpt-4o-mini"  // Cheaper option. Or "gpt-4" for better quality
}
