//
//  ClaudeAIService.swift
//  HealthOptimizer
//
//  Claude (Anthropic) API implementation for health recommendations
//

import Foundation

// MARK: - Claude AI Service

/// Implementation of AIServiceProtocol using Anthropic's Claude API
final class ClaudeAIService: AIServiceProtocol {

    // MARK: - Properties

    private let baseURL = AppConfig.API.claudeBaseURL
    private let model = AppConfig.API.claudeModel
    private let maxTokens = AppConfig.API.maxTokens
    private let keychainService: KeychainServiceProtocol
    private let promptBuilder: AIPromptBuilder

    var providerName: String { "Claude (Anthropic)" }
    var provider: AIProvider { .claude }

    var isConfigured: Bool {
        keychainService.getAPIKey(for: .claude) != nil
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
        guard let apiKey = keychainService.getAPIKey(for: .claude) else {
            throw AIServiceError.notConfigured
        }

        // Build the prompt
        let systemPrompt = promptBuilder.buildSystemPrompt()
        let userPrompt = promptBuilder.buildUserPrompt(for: profile)

        // Create request
        let request = try createRequest(
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt
        )

        // Execute request
        let (data, response) = try await executeRequest(request)

        // Handle response
        try handleHTTPResponse(response)

        // Parse response
        return try parseResponse(data)
    }

    // MARK: - Private Methods

    private func createRequest(
        apiKey: String,
        systemPrompt: String,
        userPrompt: String
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 120  // 2 minutes for complex responses

        let body = ClaudeRequestBody(
            model: model,
            maxTokens: maxTokens,
            system: systemPrompt,
            messages: [
                ClaudeMessage(role: "user", content: userPrompt)
            ]
        )

        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func executeRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            if error.code == .timedOut {
                throw AIServiceError.timeout
            }
            throw AIServiceError.networkError(underlying: error)
        } catch {
            throw AIServiceError.networkError(underlying: error)
        }
    }

    private func handleHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return  // Success
        case 401:
            throw AIServiceError.invalidAPIKey
        case 429:
            throw AIServiceError.rateLimited
        case 500...599:
            throw AIServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: "Server error"
            )
        default:
            throw AIServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: "Unexpected status code"
            )
        }
    }

    private func parseResponse(_ data: Data) throws -> AIHealthRecommendationResponse {
        do {
            // First, parse the Claude API response structure
            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

            // Extract the text content from the response
            guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
                  let responseText = textContent.text else {
                throw AIServiceError.invalidResponse
            }

            // The response should be JSON - find and extract it
            let jsonString = extractJSON(from: responseText)

            guard let jsonData = jsonString.data(using: .utf8) else {
                throw AIServiceError.invalidResponse
            }

            // Parse the health recommendation from the JSON
            let recommendation = try JSONDecoder().decode(
                AIHealthRecommendationResponse.self,
                from: jsonData
            )

            return recommendation

        } catch let error as AIServiceError {
            throw error
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
}

// MARK: - Claude API Models

/// Request body for Claude API
private struct ClaudeRequestBody: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

/// Message in Claude API request/response
private struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

/// Response from Claude API
private struct ClaudeResponse: Decodable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContentBlock]
    let model: String
    let stopReason: String?
    let usage: ClaudeUsage

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case usage
    }
}

/// Content block in Claude response
private struct ClaudeContentBlock: Decodable {
    let type: String
    let text: String?
}

/// Usage statistics from Claude
private struct ClaudeUsage: Decodable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}
