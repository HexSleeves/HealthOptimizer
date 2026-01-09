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

  func generateRecommendations(for profile: UserProfile) async throws
    -> AIHealthRecommendationResponse
  {
    guard let apiKey = keychainService.getAPIKey(for: .openAI) else {
      throw AIServiceError.notConfigured
    }

    // Initialize client with current API key
    let configuration = OpenAI.Configuration(
      token: apiKey,
      timeoutInterval: 120.0
    )
    let client = OpenAI(configuration: configuration)

    // Build prompts
    let systemPrompt = promptBuilder.buildSystemPrompt()
    let userPrompt = promptBuilder.buildUserPrompt(for: profile)

    // Get selected model from settings
    let modelName =
      AISettings.shared.selectedProvider == .openAI
      ? AISettings.shared.selectedModel
      : AIProvider.openAI.defaultModel

    // Create chat query with proper message types
    let query = ChatQuery(
      messages: [
        .system(.init(content: .textContent(systemPrompt))),
        .user(.init(content: .string(userPrompt))),
      ],
      model: modelName,
      responseFormat: .jsonObject,
      temperature: 0.7
    )

    do {
      let result = try await client.chats(query: query)

      // Extract response content
      guard let choice = result.choices.first,
        let content = choice.message.content
      else {
        throw AIServiceError.invalidResponse
      }

      // Parse the JSON response
      return try parseResponse(content)

    } catch let error as AIServiceError {
      throw error
    } catch {
      // Check for common OpenAI errors
      let errorMessage = error.localizedDescription.lowercased()
      if errorMessage.contains("rate") || errorMessage.contains("limit") {
        throw AIServiceError.rateLimited
      } else if errorMessage.contains("invalid") && errorMessage.contains("key") {
        throw AIServiceError.invalidAPIKey
      } else if errorMessage.contains("timeout") {
        throw AIServiceError.timeout
      }
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
      let decoder = AIJSONCoding.makeDecoder()
      return try decoder.decode(AIHealthRecommendationResponse.self, from: jsonData)
    } catch {
      #if DEBUG
      print("[AI][OpenAI] decode failed: \(AIJSONCoding.debugDescribeDecodingError(error))")
      print("[AI][OpenAI] json chars: \(jsonString.count)")
      print("[AI][OpenAI] \(AIJSONCoding.debugSummarizeTopLevelJSON(from: jsonData))")
      print("[AI][OpenAI] json snippet:\n\(AIJSONCoding.debugSnippet(jsonString))")
      #endif
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
      let endIndex = text.lastIndex(of: "}")
    {
      return String(text[startIndex...endIndex])
    }

    return text
  }
}
