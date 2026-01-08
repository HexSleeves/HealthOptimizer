//
//  GeminiAIService.swift
//  HealthOptimizer
//
//  Google Gemini API implementation via Firebase AI Logic
//  Uses Firebase SDK for authentication and API access
//

import Foundation
import FirebaseCore
import FirebaseAI

// MARK: - Gemini AI Service

/// Implementation of AIServiceProtocol using Google's Gemini models via Firebase
final class GeminiAIService: AIServiceProtocol {
    
    // MARK: - Properties
    
    private let promptBuilder: AIPromptBuilder
    private var generativeModel: GenerativeModel?
    
    var providerName: String { "Gemini (Google)" }
    var provider: AIProvider { .gemini }
    
    var isConfigured: Bool {
        GeminiAIService.isFirebaseConfigured
    }
    
    /// Check if Firebase is properly configured
    static var isFirebaseConfigured: Bool {
        // Check if Firebase has been configured
        return FirebaseApp.app() != nil
    }
    
    // MARK: - Initialization
    
    init(promptBuilder: AIPromptBuilder = AIPromptBuilder()) {
        self.promptBuilder = promptBuilder
        setupModel()
    }
    
    private func setupModel() {
        guard GeminiAIService.isFirebaseConfigured else {
            return
        }
        
        // Get selected model from settings
        let modelName = AISettings.shared.selectedProvider == .gemini 
            ? AISettings.shared.selectedModel 
            : AIProvider.gemini.defaultModel
        
        // Initialize the Gemini model via Firebase AI Logic
        // Using the Gemini Developer API (not Vertex AI)
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        
        // Configure generation settings
        let config = GenerationConfig(
            temperature: 0.7,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 8192,
            responseMIMEType: "application/json"
        )
        
        generativeModel = ai.generativeModel(
            modelName: modelName,
            generationConfig: config
        )
    }
    
    // MARK: - AIServiceProtocol
    
    func generateRecommendations(for profile: UserProfile) async throws -> AIHealthRecommendationResponse {
        guard isConfigured else {
            throw AIServiceError.firebaseNotConfigured
        }
        
        // Reinitialize model in case settings changed
        setupModel()
        
        guard let model = generativeModel else {
            throw AIServiceError.notConfigured
        }
        
        // Build prompts
        let systemPrompt = promptBuilder.buildSystemPrompt()
        let userPrompt = promptBuilder.buildUserPrompt(for: profile)
        
        // Combine prompts for Gemini (it handles system instructions differently)
        let fullPrompt = """
        \(systemPrompt)
        
        ---
        
        \(userPrompt)
        """
        
        do {
            // Generate content
            let response = try await model.generateContent(fullPrompt)
            
            // Extract text from response
            guard let text = response.text else {
                throw AIServiceError.invalidResponse
            }
            
            // Parse the JSON response
            return try parseResponse(text)
            
        } catch let error as AIServiceError {
            throw error
        } catch {
            // Map Firebase/Gemini errors
            throw mapGeminiError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func parseResponse(_ content: String) throws -> AIHealthRecommendationResponse {
        // Extract JSON from response (handles markdown code blocks)
        let jsonString = extractJSON(from: content)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AIHealthRecommendationResponse.self, from: jsonData)
        } catch {
            throw AIServiceError.parsingError(underlying: error)
        }
    }
    
    /// Extract JSON from response text (handles markdown code blocks)
    private func extractJSON(from text: String) -> String {
        // Try to find JSON in code blocks first
        if let jsonMatch = text.range(of: "```json\n([\\s\\S]*?)\n```", options: .regularExpression) {
            var json = String(text[jsonMatch])
            json = json.replacingOccurrences(of: "```json\n", with: "")
            json = json.replacingOccurrences(of: "\n```", with: "")
            return json
        }
        
        // Try plain code blocks
        if let jsonMatch = text.range(of: "```\n([\\s\\S]*?)\n```", options: .regularExpression) {
            var json = String(text[jsonMatch])
            json = json.replacingOccurrences(of: "```\n", with: "")
            json = json.replacingOccurrences(of: "\n```", with: "")
            return json
        }
        
        // Try to find raw JSON object
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        
        return text
    }
    
    private func mapGeminiError(_ error: Error) -> AIServiceError {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("rate") || errorString.contains("quota") {
            return .rateLimited
        } else if errorString.contains("api key") || errorString.contains("authentication") {
            return .invalidAPIKey
        } else if errorString.contains("timeout") {
            return .timeout
        } else if errorString.contains("network") || errorString.contains("connection") {
            return .networkError(underlying: error)
        } else {
            return .unknown(underlying: error)
        }
    }
}

// MARK: - Firebase Configuration Helper

/// Helper to configure Firebase if not already done
enum FirebaseConfiguration {
    
    /// Configure Firebase if needed
    /// Call this in your AppDelegate or App init
    static func configureIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    /// Check if GoogleService-Info.plist exists
    static var hasGoogleServicePlist: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }
}
