//
//  AIServiceProtocol.swift
//  HealthOptimizer
//
//  Protocol abstraction for AI service integration
//  Allows swapping between different AI providers (Claude, GPT, etc.)
//

import Foundation

// MARK: - AI Service Protocol

/// Protocol defining the interface for AI health recommendation services
/// Implementations can use Claude, GPT, or other AI providers
protocol AIServiceProtocol {

    /// Generate health recommendations based on user profile
    /// - Parameter profile: The user's health profile
    /// - Returns: Complete health recommendation response
    /// - Throws: AIServiceError if generation fails
    func generateRecommendations(for profile: UserProfile) async throws -> AIHealthRecommendationResponse

    /// Check if the service is properly configured and ready
    var isConfigured: Bool { get }

    /// The name of the AI provider for display
    var providerName: String { get }
}

// MARK: - AI Service Error

/// Errors that can occur during AI service operations
enum AIServiceError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case networkError(underlying: Error)
    case rateLimited
    case invalidResponse
    case parsingError(underlying: Error)
    case serverError(statusCode: Int, message: String)
    case timeout
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI service is not configured. Please add your API key in Settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your API key in Settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limited. Please try again in a few minutes."
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .parsingError(let error):
            return "Failed to parse AI response: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .timeout:
            return "Request timed out. Please try again."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notConfigured, .invalidAPIKey:
            return "Go to Settings and enter a valid API key."
        case .networkError:
            return "Check your internet connection and try again."
        case .rateLimited:
            return "Wait a few minutes before trying again."
        case .timeout:
            return "The request took too long. Try again with a stable connection."
        default:
            return "Try again. If the problem persists, contact support."
        }
    }
}

// MARK: - AI Service Factory

/// Factory for creating AI service instances
enum AIServiceFactory {

    /// Create the default AI service (Claude)
    static func createDefault() -> AIServiceProtocol {
        return ClaudeAIService()
    }

    /// Create a specific AI service by provider name
    static func create(provider: AIProvider) -> AIServiceProtocol {
        switch provider {
        case .claude:
            return ClaudeAIService()
        // Add other providers here in the future
        // case .openAI:
        //     return OpenAIService()
        }
    }
}

// MARK: - AI Provider

/// Supported AI providers
enum AIProvider: String, CaseIterable, Identifiable {
    case claude = "Claude (Anthropic)"
    // case openAI = "GPT (OpenAI)"  // Future implementation

    var id: String { rawValue }

    var apiKeyName: String {
        switch self {
        case .claude: return "ANTHROPIC_API_KEY"
        }
    }
}

// MARK: - AI Request Context

/// Additional context that can be passed to AI requests
struct AIRequestContext {
    var focusAreas: [HealthGoal]?  // Specific areas to emphasize
    var excludeSupplements: [String]?  // Supplements to exclude
    var preferredWorkoutStyle: WorkoutType?
    var budgetConstraint: BudgetLevel?
    var additionalInstructions: String?

    init(
        focusAreas: [HealthGoal]? = nil,
        excludeSupplements: [String]? = nil,
        preferredWorkoutStyle: WorkoutType? = nil,
        budgetConstraint: BudgetLevel? = nil,
        additionalInstructions: String? = nil
    ) {
        self.focusAreas = focusAreas
        self.excludeSupplements = excludeSupplements
        self.preferredWorkoutStyle = preferredWorkoutStyle
        self.budgetConstraint = budgetConstraint
        self.additionalInstructions = additionalInstructions
    }
}

/// Budget constraints for recommendations
enum BudgetLevel: String, Codable, CaseIterable {
    case budget = "Budget-Friendly"
    case moderate = "Moderate"
    case premium = "Premium"
}
