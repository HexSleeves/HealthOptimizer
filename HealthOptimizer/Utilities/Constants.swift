//
//  Constants.swift
//  HealthOptimizer
//
//  App-wide constants and configuration values
//

import Foundation
import SwiftUI

// MARK: - UI Constants

enum UIConstants {
  static let cornerRadius: CGFloat = 12
  static let smallCornerRadius: CGFloat = 8
  static let standardPadding: CGFloat = 16
  static let smallPadding: CGFloat = 8
  static let largePadding: CGFloat = 24

  static let iconSizeSmall: CGFloat = 20
  static let iconSizeMedium: CGFloat = 24
  static let iconSizeLarge: CGFloat = 32

  static let animationDuration: Double = 0.3
  static let shortAnimationDuration: Double = 0.15
}

// MARK: - Health Constants

enum HealthConstants {
  // Age limits
  static let minimumAge = 13
  static let maximumAge = 120

  // Height limits (cm)
  static let minimumHeight = 100.0
  static let maximumHeight = 250.0

  // Weight limits (kg)
  static let minimumWeight = 30.0
  static let maximumWeight = 300.0

  // BMI categories
  static let bmiUnderweight = 18.5
  static let bmiNormal = 25.0
  static let bmiOverweight = 30.0

  // Sleep recommendations
  static let recommendedSleepMin = 7.0
  static let recommendedSleepMax = 9.0

  // Water intake (liters)
  static let recommendedWaterMin = 2.0
  static let recommendedWaterMax = 3.5

  // Exercise recommendations
  static let minimumExerciseDaysPerWeek = 3
  static let optimalExerciseDaysPerWeek = 5
}

// MARK: - Validation Messages

enum ValidationMessages {
  static let invalidAge =
    "Please enter a valid age between \(HealthConstants.minimumAge) and \(HealthConstants.maximumAge)."
  static let invalidHeight =
    "Please enter a valid height between \(Int(HealthConstants.minimumHeight)) and \(Int(HealthConstants.maximumHeight)) cm."
  static let invalidWeight =
    "Please enter a valid weight between \(Int(HealthConstants.minimumWeight)) and \(Int(HealthConstants.maximumWeight)) kg."
  static let noGoalsSelected = "Please select at least one health goal."
  static let invalidAPIKey = "Please enter a valid API key."
}

// MARK: - Accessibility

enum AccessibilityLabels {
  static let backButton = "Go back"
  static let nextButton = "Continue to next step"
  static let submitButton = "Submit form"
  static let closeButton = "Close"
  static let refreshButton = "Refresh content"
  static let settingsButton = "Open settings"
}

// MARK: - User Defaults Keys

enum UserDefaultsKeys {
  static let hasCompletedOnboarding = "hasCompletedOnboarding"
  static let lastRecommendationDate = "lastRecommendationDate"
  static let preferredUnits = "preferredUnits"
  static let notificationsEnabled = "notificationsEnabled"
}

// MARK: - Notification Names

extension Notification.Name {
  static let profileUpdated = Notification.Name("profileUpdated")
  static let recommendationsGenerated = Notification.Name("recommendationsGenerated")
  static let apiKeyChanged = Notification.Name("apiKeyChanged")
}

// MARK: - App Colors

enum AppColors {
  static let primary = Color.accentColor
  static let secondary = Color(.systemGray)
  static let background = Color(.systemGroupedBackground)
  static let cardBackground = Color(.systemBackground)

  static let success = Color.green
  static let warning = Color.orange
  static let error = Color.red
  static let info = Color.blue

  static let supplementColor = Color.green
  static let workoutColor = Color.orange
  static let dietColor = Color.blue
  static let profileColor = Color.purple
}
