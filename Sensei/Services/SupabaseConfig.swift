import Foundation

struct SupabaseConfig {
    // ============================================
    // SUPABASE CONFIGURATION
    // ============================================
    // Get these from your Supabase project settings:
    // https://app.supabase.com/project/_/settings/api
    
    // Your Supabase project URL
    static let supabaseURL: String = {
        // First try environment variable
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty {
            return url
        }
        // Fallback - replace with your actual Supabase URL
        return "https://tyvvxnafhoxttoaepxak.supabase.co"
    }()
    
    // Your Supabase anon/public key
    static let supabaseAnonKey: String = {
        // First try environment variable
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty {
            return key
        }
        // Fallback - replace with your actual Supabase anon key
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5dnZ4bmFmaG94dHRvYWVweGFrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4MDk0OTQsImV4cCI6MjA4MTM4NTQ5NH0.f9HtXD-m2hQ4MxolZ1X2C6xB3hm1gPVz5-OXD5_CRVk"
    }()
}

