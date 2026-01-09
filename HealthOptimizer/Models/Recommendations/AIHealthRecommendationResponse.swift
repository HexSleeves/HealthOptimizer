//
//  AIHealthRecommendationResponse.swift
//  HealthOptimizer
//
//  Intermediate model for parsing AI provider JSON
//

import Foundation

/// Structure for parsing AI API response.
///
/// This intermediate model is used to parse the raw AI response before
/// mapping to our domain models.
struct AIHealthRecommendationResponse: Codable, Sendable {
  var healthSummary: String
  var keyInsights: [String]
  var priorityActions: [String]
  var supplementPlan: SupplementPlan
  var workoutPlan: WorkoutPlan
  var dietPlan: DietPlan
  var lifestyleRecommendations: [String]
  var disclaimers: [String]
  var suggestedReviewWeeks: Int
}
