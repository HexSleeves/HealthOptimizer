//
//  DashboardViewModel.swift
//  HealthOptimizer
//
//  ViewModel for main dashboard and recommendation generation
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Dashboard View Model

/// Observable ViewModel for the main dashboard
@Observable
@MainActor
final class DashboardViewModel {

  // MARK: - State

  var userProfile: UserProfile?
  var currentRecommendation: HealthRecommendation?

  var isLoading = false
  var isGeneratingRecommendations = false
  var error: AIServiceError?
  var showingError = false
  var generationProgress: String = ""

  // MARK: - Dependencies

  private var aiService: AIServiceProtocol
  private let persistenceService: PersistenceService

  // MARK: - Initialization

  init(
    aiService: AIServiceProtocol? = nil,
    persistenceService: PersistenceService = .shared
  ) {
    // Use provided service or get from settings
    self.aiService = aiService ?? AISettings.shared.currentService()
    self.persistenceService = persistenceService
  }

  // MARK: - Computed Properties

  var hasRecommendations: Bool {
    currentRecommendation?.status == .completed
  }

  var isAIConfigured: Bool {
    // Check if currently selected provider is configured
    AISettings.shared.isCurrentProviderConfigured
  }

  var currentProviderName: String {
    AISettings.shared.selectedProvider.rawValue
  }

  var recommendationAge: String? {
    guard let date = currentRecommendation?.createdAt else { return nil }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
  }

  var needsRefresh: Bool {
    guard let recommendation = currentRecommendation else { return true }
    // Suggest refresh if recommendations are older than 30 days
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    return recommendation.createdAt < thirtyDaysAgo
  }

  // MARK: - Data Loading

  /// Load user profile and recommendations from storage
  func loadData() {
    isLoading = true
    userProfile = persistenceService.fetchUserProfile()
    currentRecommendation = persistenceService.fetchLatestRecommendation()
    isLoading = false
  }

  // MARK: - Recommendation Generation

  /// Generate new health recommendations using AI
  func generateRecommendations() async {
    // Refresh AI service in case provider changed
    aiService = AISettings.shared.currentService()

    let providerName = aiService.providerName
    print("[HealthOptimizer] Generating recommendations using \(providerName)...")

    guard let profile = userProfile else {
      error = .invalidResponse
      showingError = true
      return
    }

    guard aiService.isConfigured else {
      error = .notConfigured
      showingError = true
      return
    }

    isGeneratingRecommendations = true
    generationProgress = "Analyzing your health profile..."

    // Create a pending recommendation
    let recommendation = HealthRecommendation(status: .generating)

    do {
      try persistenceService.saveRecommendation(recommendation)
      currentRecommendation = recommendation

      generationProgress = "Generating personalized recommendations..."

      // Call AI service
      let response = try await aiService.generateRecommendations(for: profile)

      generationProgress = "Saving your recommendations..."

      // Update recommendation with response data
      recommendation.status = .completed
      recommendation.healthSummary = response.healthSummary
      recommendation.keyInsights = response.keyInsights
      recommendation.priorityActions = response.priorityActions
      recommendation.supplementPlan = response.supplementPlan
      recommendation.workoutPlan = response.workoutPlan
      recommendation.dietPlan = response.dietPlan
      recommendation.lifestyleRecommendations = response.lifestyleRecommendations
      recommendation.disclaimers = response.disclaimers
      recommendation.suggestedReviewWeeks = response.suggestedReviewWeeks
      recommendation.markUpdated()

      try persistenceService.mainContext.save()

      // Prune old recommendations
      try persistenceService.pruneOldRecommendations(keepLast: 5)

      generationProgress = "Complete!"

    } catch let serviceError as AIServiceError {
      recommendation.status = .failed
      error = serviceError
      showingError = true
    } catch {
      recommendation.status = .failed
      self.error = .unknown(underlying: error)
      showingError = true
    }

    isGeneratingRecommendations = false
    generationProgress = ""
  }

  /// Regenerate recommendations (for refresh)
  func refreshRecommendations() async {
    await generateRecommendations()
  }

  // MARK: - Quick Stats

  /// Get quick stats for dashboard display
  var quickStats: [QuickStat] {
    guard let profile = userProfile else { return [] }

    return [
      QuickStat(
        title: "BMI",
        value: String(format: "%.1f", profile.bmi),
        subtitle: profile.bmiCategory.rawValue,
        icon: "scalemass.fill",
        color: colorForBMI(profile.bmiCategory)
      ),
      QuickStat(
        title: "Daily Calories",
        value: "\(Int(profile.estimatedTDEE))",
        subtitle: "TDEE estimate",
        icon: "flame.fill",
        color: .orange
      ),
      QuickStat(
        title: "Activity",
        value: "\(profile.weeklyActivityDays)",
        subtitle: "days/week",
        icon: "figure.run",
        color: .green
      ),
      QuickStat(
        title: "Sleep",
        value: String(format: "%.1f", profile.averageSleepHours),
        subtitle: "hours/night",
        icon: "moon.fill",
        color: .purple
      ),
    ]
  }

  private func colorForBMI(_ category: BMICategory) -> Color {
    switch category {
    case .underweight: return .yellow
    case .normal: return .green
    case .overweight: return .orange
    case .obese: return .red
    }
  }

  // MARK: - Error Handling

  func dismissError() {
    showingError = false
    error = nil
  }
}

// MARK: - Quick Stat Model

/// Model for quick stat display cards
struct QuickStat: Identifiable {
  var id = UUID()
  var title: String
  var value: String
  var subtitle: String
  var icon: String
  var color: Color
}

// MARK: - Preview Helpers

extension DashboardViewModel {
  /// Create a preview instance with sample data
  static var preview: DashboardViewModel {
    let vm = DashboardViewModel(
      aiService: MockAIService(),
      persistenceService: .shared
    )
    vm.userProfile = UserProfile.sampleProfile
    vm.currentRecommendation = HealthRecommendation.sample
    return vm
  }
}

// MARK: - Mock AI Service

/// Mock AI service for previews and testing
final class MockAIService: AIServiceProtocol {
  var isConfigured: Bool { true }
  var providerName: String { "Mock" }
  var provider: AIProvider { .claude }

  func generateRecommendations(for profile: UserProfile) async throws
    -> AIHealthRecommendationResponse
  {
    // Simulate network delay
    try await Task.sleep(nanoseconds: 2_000_000_000)

    return AIHealthRecommendationResponse(
      healthSummary: "Sample health summary",
      keyInsights: ["Insight 1", "Insight 2"],
      priorityActions: ["Action 1", "Action 2"],
      supplementPlan: SupplementPlan.sample,
      workoutPlan: WorkoutPlan.sample,
      dietPlan: DietPlan.sample,
      lifestyleRecommendations: ["Get more sleep"],
      disclaimers: ["Consult your doctor"],
      suggestedReviewWeeks: 8
    )
  }
}
