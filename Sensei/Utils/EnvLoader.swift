import Foundation

class EnvLoader {
    static let shared = EnvLoader()
    
    private var env: [String: String] = [:]
    
    private init() {
        loadEnvFile()
    }
    
    private func loadEnvFile() {
        // Try to find .env file in the bundle or project directory
        guard let envPath = findEnvFile() else {
            print("⚠️ .env file not found")
            return
        }
        
        do {
            let envContent = try String(contentsOfFile: envPath, encoding: .utf8)
            parseEnvContent(envContent)
            print("✅ Loaded .env file from: \(envPath)")
        } catch {
            print("⚠️ Error reading .env file: \(error)")
        }
    }
    
    private func findEnvFile() -> String? {
        // Try multiple locations
        let possiblePaths = [
            // In project root
            "/Users/dev/Sensei/.env",
            // In app bundle (for production)
            Bundle.main.path(forResource: ".env", ofType: nil),
            // Current directory
            FileManager.default.currentDirectoryPath + "/.env"
        ]
        
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    private func parseEnvContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Parse KEY=VALUE format
            if let range = trimmed.range(of: "=") {
                let key = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                var value = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                
                // Remove quotes if present
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) || 
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }
                
                env[key] = value
            }
        }
    }
    
    func get(_ key: String) -> String? {
        // First check environment variables (set in Xcode scheme)
        if let envValue = ProcessInfo.processInfo.environment[key], !envValue.isEmpty {
            return envValue
        }
        // Then check .env file
        return env[key]
    }
}

