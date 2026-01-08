//
//  AIServiceProtocol.swift
//  HealthOptimizer
//
//  Protocol abstraction for AI service integration
//  Allows swapping between different AI providers (Claude, OpenAI, Gemini)
//

import Foundation

// MARK: - AI Service Protocol

/// Protocol defining the interface for AI health recommendation services
/// Implementations can use Claude, OpenAI GPT, Google Gemini, or other AI providers
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
    
    /// The provider type
    var provider: AIProvider { get }
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
    case firebaseNotConfigured
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
        case .firebaseNotConfigured:
            return "Firebase is not configured. Please add GoogleService-Info.plist to your project."
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
        case .firebaseNotConfigured:
            return "Add GoogleService-Info.plist to your Xcode project and configure Firebase."
        default:
            return "Try again. If the problem persists, contact support."
        }
    }
}

// MARK: - AI Service Factory

/// Factory for creating AI service instances
enum AIServiceFactory {
    
    /// Create the default AI service based on what's configured
    static func createDefault() -> AIServiceProtocol {
        // Try to find first configured provider
        let keychain = KeychainService.shared
        
        if keychain.hasAPIKey(for: .claude) {
            return ClaudeAIService()
        } else if keychain.hasAPIKey(for: .openAI) {
            return OpenAIService()
        } else if GeminiAIService.isFirebaseConfigured {
            return GeminiAIService()
        }
        
        // Default to Claude (user will need to configure)
        return ClaudeAIService()
    }
    
    /// Create a specific AI service by provider
    static func create(provider: AIProvider) -> AIServiceProtocol {
        switch provider {
        case .claude:
            return ClaudeAIService()
        case .openAI:
            return OpenAIService()
        case .gemini:
            return GeminiAIService()
        }
    }
    
    /// Get all available (configured) services
    static func availableProviders() -> [AIProvider] {
        let keychain = KeychainService.shared
        var providers: [AIProvider] = []
        
        if keychain.hasAPIKey(for: .claude) {
            providers.append(.claude)
        }
        if keychain.hasAPIKey(for: .openAI) {
            providers.append(.openAI)
        }
        if GeminiAIService.isFirebaseConfigured {
            providers.append(.gemini)
        }
        
        return providers
    }
}

// MARK: - AI Provider

/// Supported AI providers
enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case claude = "Claude (Anthropic)"
    case openAI = "GPT (OpenAI)"
    case gemini = "Gemini (Google)"
    
    var id: String { rawValue }
    
    var apiKeyName: String {
        switch self {
        case .claude: return "ANTHROPIC_API_KEY"
        case .openAI: return "OPENAI_API_KEY"
        case .gemini: return "GOOGLE_AI_KEY"  // Uses Firebase, no direct API key needed
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .claude, .openAI: return true
        case .gemini: return false  // Uses Firebase configuration
        }
    }
    
    var icon: String {
        switch self {
        case .claude: return "brain.head.profile"
        case .openAI: return "sparkles"
        case .gemini: return "wand.and.stars"
        }
    }
    
    var description: String {
        switch self {
        case .claude:
            return "Anthropic's Claude - excellent for nuanced health analysis"
        case .openAI:
            return "OpenAI's GPT models - powerful general-purpose AI"
        case .gemini:
            return "Google's Gemini via Firebase - integrated with Google services"
        }
    }
    
    var setupInstructions: String {
        switch self {
        case .claude:
            return "Get your API key from console.anthropic.com"
        case .openAI:
            return "Get your API key from platform.openai.com"
        case .gemini:
            return "Configure Firebase in your project with GoogleService-Info.plist"
        }
    }
    
    /// Default model for each provider
    var defaultModel: String {
        switch self {
        case .claude: return "claude-sonnet-4-20250514"
        case .openAI: return "gpt-4o"
        case .gemini: return "gemini-2.0-flash"
        }
    }
    
    /// Available models for each provider
    var availableModels: [String] {
        switch self {
        case .claude:
            return ["claude-sonnet-4-20250514", "claude-3-5-sonnet-20241022", "claude-3-haiku-20240307"]
        case .openAI:
            return ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
        case .gemini:
            return ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-pro"]
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
    var preferredModel: String?  // Override default model
    
    init(
        focusAreas: [HealthGoal]? = nil,
        excludeSupplements: [String]? = nil,
        preferredWorkoutStyle: WorkoutType? = nil,
        budgetConstraint: BudgetLevel? = nil,
        additionalInstructions: String? = nil,
        preferredModel: String? = nil
    ) {
        self.focusAreas = focusAreas
        self.excludeSupplements = excludeSupplements
        self.preferredWorkoutStyle = preferredWorkoutStyle
        self.budgetConstraint = budgetConstraint
        self.additionalInstructions = additionalInstructions
        self.preferredModel = preferredModel
    }
}

/// Budget constraints for recommendations
enum BudgetLevel: String, Codable, CaseIterable {
    case budget = "Budget-Friendly"
    case moderate = "Moderate"
    case premium = "Premium"
}

// MARK: - AI Settings

/// User preferences for AI provider
class AISettings: ObservableObject {
    static let shared = AISettings()
    
    private let defaults = UserDefaults.standard
    private let selectedProviderKey = "selectedAIProvider"
    private let selectedModelKey = "selectedAIModel"
    
    @Published var selectedProvider: AIProvider {
        didSet {
            defaults.set(selectedProvider.rawValue, forKey: selectedProviderKey)
        }
    }
    
    @Published var selectedModel: String {
        didSet {
            defaults.set(selectedModel, forKey: selectedModelKey)
        }
    }
    
    private init() {
        // Load saved provider or default to claude
        if let savedProvider = defaults.string(forKey: selectedProviderKey),
           let provider = AIProvider(rawValue: savedProvider) {
            self.selectedProvider = provider
        } else {
            self.selectedProvider = .claude
        }
        
        // Load saved model or use provider default
        if let savedModel = defaults.string(forKey: selectedModelKey) {
            self.selectedModel = savedModel
        } else {
            self.selectedModel = AIProvider.claude.defaultModel
        }
    }
    
    /// Get the currently configured AI service
    func currentService() -> AIServiceProtocol {
        AIServiceFactory.create(provider: selectedProvider)
    }
    
    /// Check if selected provider is configured
    var isCurrentProviderConfigured: Bool {
        currentService().isConfigured
    }
}
