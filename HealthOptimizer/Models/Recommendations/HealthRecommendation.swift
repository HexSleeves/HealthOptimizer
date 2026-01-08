//
//  HealthRecommendation.swift
//  HealthOptimizer
//
//  Combined health recommendation model from AI
//

import Foundation
import SwiftData

// MARK: - Health Recommendation

/// Complete health recommendation set from AI analysis
/// This is the main output model that combines all recommendation types
@Model
final class HealthRecommendation {

    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    /// Status of the recommendation generation
    var status: RecommendationStatus

    /// Overall health summary from AI analysis
    var healthSummary: String

    /// Key insights identified by AI
    var keyInsights: [String]

    /// Priority actions to focus on
    var priorityActions: [String]

    /// Serialized supplement plan (JSON)
    var supplementPlanData: Data?

    /// Serialized workout plan (JSON)
    var workoutPlanData: Data?

    /// Serialized diet plan (JSON)
    var dietPlanData: Data?

    /// General lifestyle recommendations
    var lifestyleRecommendations: [String]

    /// Medical disclaimers and warnings
    var disclaimers: [String]

    /// Suggested follow-up timeline (weeks)
    var suggestedReviewWeeks: Int

    // MARK: - Computed Properties

    /// Decoded supplement plan
    nonisolated var supplementPlan: SupplementPlan? {
        get {
            guard let data = supplementPlanData else { return nil }
            return try? JSONDecoder().decode(SupplementPlan.self, from: data)
        }
        set {
            supplementPlanData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Decoded workout plan
    nonisolated var workoutPlan: WorkoutPlan? {
        get {
            guard let data = workoutPlanData else { return nil }
            return try? JSONDecoder().decode(WorkoutPlan.self, from: data)
        }
        set {
            workoutPlanData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Decoded diet plan
    nonisolated var dietPlan: DietPlan? {
        get {
            guard let data = dietPlanData else { return nil }
            return try? JSONDecoder().decode(DietPlan.self, from: data)
        }
        set {
            dietPlanData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Initialization

    init(
        status: RecommendationStatus = .pending,
        healthSummary: String = "",
        keyInsights: [String] = [],
        priorityActions: [String] = [],
        lifestyleRecommendations: [String] = [],
        disclaimers: [String] = [],
        suggestedReviewWeeks: Int = 8
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = status
        self.healthSummary = healthSummary
        self.keyInsights = keyInsights
        self.priorityActions = priorityActions
        self.lifestyleRecommendations = lifestyleRecommendations
        self.disclaimers = disclaimers
        self.suggestedReviewWeeks = suggestedReviewWeeks
    }

    /// Update timestamp
    func markUpdated() {
        updatedAt = Date()
    }
}

// MARK: - Recommendation Status

/// Status of recommendation generation
enum RecommendationStatus: String, Codable {
    case pending = "Pending"
    case generating = "Generating"
    case completed = "Completed"
    case failed = "Failed"
    case needsUpdate = "Needs Update"
}

// MARK: - AI Response Model

/// Structure for parsing AI API response
/// This intermediate model is used to parse the raw AI response before
/// mapping to our domain models
struct AIHealthRecommendationResponse: Codable {
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

// MARK: - Sample Data

extension HealthRecommendation {
    /// Sample recommendation for previews
    static var sample: HealthRecommendation {
        let recommendation = HealthRecommendation(
            status: .completed,
            healthSummary: "Based on your profile, you're a 35-year-old male with prediabetes looking to lose weight and build muscle. Your current activity level is moderate, but there's room for improvement in sleep and stress management. Your goals are achievable with the right approach.",
            keyInsights: [
                "Prediabetes requires focus on blood sugar management through diet and exercise",
                "Sleep duration of 6.5 hours may be impacting recovery and metabolic health",
                "High stress levels can affect cortisol and weight management",
                "Current BMI of 26.2 puts you in the overweight category",
                "Good foundation with existing gym access and intermediate fitness level"
            ],
            priorityActions: [
                "Implement blood sugar-friendly eating patterns",
                "Increase sleep to 7-8 hours per night",
                "Add stress management practices",
                "Start structured resistance training program",
                "Begin recommended supplement protocol"
            ],
            lifestyleRecommendations: [
                "Take a 10-15 minute walk after meals to help with blood sugar",
                "Practice deep breathing or meditation for 10 minutes daily",
                "Reduce screen time 1 hour before bed",
                "Keep consistent sleep and wake times, even on weekends",
                "Stay hydrated - aim for 3 liters of water daily"
            ],
            disclaimers: [
                "These recommendations are for informational purposes only and do not constitute medical advice.",
                "Consult your healthcare provider before starting any new supplement, diet, or exercise program.",
                "With prediabetes, regular monitoring and medical supervision are essential.",
                "If you experience any adverse effects, discontinue and consult a healthcare professional."
            ],
            suggestedReviewWeeks: 8
        )
        recommendation.supplementPlan = SupplementPlan.sample
        recommendation.workoutPlan = WorkoutPlan.sample
        recommendation.dietPlan = DietPlan.sample
        return recommendation
    }
}
