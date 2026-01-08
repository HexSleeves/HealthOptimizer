//
//  OpenAIService.swift
//  HealthOptimizer
//
//  OpenAI GPT API implementation for health recommendations
//  Uses the MacPaw OpenAI Swift package
//

import Foundation
import OpenAI

// MARK: - OpenAI Service

/// Implementation of AIServiceProtocol using OpenAI's GPT models
final class OpenAIService: AIServiceProtocol {
    
    // MARK: - Properties
    
    private let keychainService: KeychainServiceProtocol
    private let promptBuilder: AIPromptBuilder
    private var openAIClient: OpenAI?
    
    var providerName: String { "GPT (OpenAI)" }
    var provider: AIProvider { .openAI }
    
    var isConfigured: Bool {
        keychainService.getAPIKey(for: .openAI) != nil
    }
    
    // MARK: - Initialization
    
    init(
        keychainService: KeychainServiceProtocol = KeychainService.shared,
        promptBuilder: AIPromptBuilder = AIPromptBuilder()
    ) {
        self.keychainService = keychainService
        self.promptBuilder = promptBuilder
    }
    
    // MARK: - AIServiceProtocol
    
    func generateRecommendations(for profile: UserProfile) async throws -> AIHealthRecommendationResponse {
        guard let apiKey = keychainService.getAPIKey(for: .openAI) else {
            throw AIServiceError.notConfigured
        }
        
        // Initialize or reinitialize client with current API key
        let configuration = OpenAI.Configuration(
            token: apiKey,
            timeoutInterval: 120.0
        )
        let client = OpenAI(configuration: configuration)
        
        // Build prompts
        let systemPrompt = promptBuilder.buildSystemPrompt()
        let userPrompt = promptBuilder.buildUserPrompt(for: profile)
        
        // Get selected model from settings
        let model = AISettings.shared.selectedModel
        
        // Create chat query
        let query = ChatQuery(
            messages: [
                .system(.init(content: systemPrompt)),
                .user(.init(content: .string(userPrompt)))
            ],
            model: model,
            responseFormat: .jsonObject,  // Request JSON response
            temperature: 0.7
        )
        
        do {
            let result = try await client.chats(query: query)
            
            // Extract response content
            guard let choice = result.choices.first,
                  let content = choice.message.content else {
                throw AIServiceError.invalidResponse
            }
            
            // Parse the JSON response
            return try parseResponse(content)
            
        } catch let error as OpenAIError {
            throw mapOpenAIError(error)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.networkError(underlying: error)
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
    
    private func mapOpenAIError(_ error: OpenAIError) -> AIServiceError {
        switch error {
        case .apiError(let apiError):
            // Check for specific API error types
            if apiError.message.contains("rate_limit") {
                return .rateLimited
            } else if apiError.message.contains("invalid_api_key") || apiError.message.contains("Incorrect API key") {
                return .invalidAPIKey
            } else {
                return .serverError(statusCode: 0, message: apiError.message)
            }
        case .emptyData:
            return .invalidResponse
        case .invalidData:
            return .invalidResponse
        default:
            return .unknown(underlying: error)
        }
    }
}

// MARK: - OpenAI Error Extension

/// OpenAI SDK errors that we need to handle
enum OpenAIError: Error {
    case apiError(APIErrorResponse)
    case emptyData
    case invalidData
    case jsonDecodingFailure(Error)
    case invalidURL
}

/// API error response structure
struct APIErrorResponse: Codable {
    let message: String
    let type: String?
    let code: String?
}
