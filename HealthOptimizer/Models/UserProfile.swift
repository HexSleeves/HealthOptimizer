//
//  UserProfile.swift
//  HealthOptimizer
//
//  Core user profile model containing all health-related data
//  SwiftData model for persistence
//

import Foundation
import SwiftData

/// Main user profile model containing all health information
/// This is the primary data structure for the app
@Model
final class UserProfile {

  // MARK: - Identification

  /// Unique identifier for the profile
  var id: UUID

  /// Display name (optional, for personalization)
  var displayName: String?

  /// Profile creation date
  var createdAt: Date

  /// Last update date
  var updatedAt: Date

  // MARK: - Basic Health Metrics

  /// User's age in years
  var age: Int

  /// Biological sex (affects some health calculations)
  var biologicalSex: BiologicalSex

  /// Height in centimeters
  var heightCm: Double

  /// Weight in kilograms
  var weightKg: Double

  /// Body fat percentage (optional, user-provided or measured)
  var bodyFatPercentage: Double?

  /// Waist circumference in cm (optional, for metabolic health)
  var waistCircumferenceCm: Double?

  // MARK: - Health Conditions

  /// List of existing health conditions
  var healthConditions: [HealthCondition]

  /// Family medical history notes
  var familyHistoryNotes: String?

  /// Known allergies (important for supplement/diet recommendations)
  var allergies: [String]

  // MARK: - Medications & Supplements

  /// Current medications
  var currentMedications: [Medication]

  /// Current supplements being taken
  var currentSupplements: [CurrentSupplement]

  // MARK: - Fitness Profile

  /// Self-assessed fitness level
  var fitnessLevel: FitnessLevel

  /// Weekly activity frequency
  var weeklyActivityDays: Int

  /// Types of activities currently performed
  var currentActivities: [ActivityType]

  /// Any physical limitations or injuries
  var physicalLimitations: [String]

  /// Access to gym equipment
  var hasGymAccess: Bool

  /// Available workout time per session in minutes
  var availableWorkoutMinutes: Int

  // MARK: - Dietary Information

  /// Primary diet type
  var dietType: DietType

  /// Food intolerances
  var foodIntolerances: [String]

  /// Foods to avoid (preferences)
  var foodsToAvoid: [String]

  /// Favorite foods to include
  var favoriteFoods: [String]

  /// Daily calorie target (if known)
  var dailyCalorieTarget: Int?

  /// Number of meals preferred per day
  var mealsPerDay: Int

  /// Cooking skill level
  var cookingSkillLevel: CookingSkillLevel

  /// Weekly meal prep time available in hours
  var weeklyMealPrepHours: Double

  // MARK: - Lifestyle Factors

  /// Average hours of sleep per night
  var averageSleepHours: Double

  /// Sleep quality self-assessment
  var sleepQuality: SleepQuality

  /// Stress level self-assessment
  var stressLevel: StressLevel

  /// Primary occupation type (affects activity level)
  var occupationType: OccupationType

  /// Daily water intake in liters
  var dailyWaterIntakeLiters: Double

  /// Alcohol consumption frequency
  var alcoholConsumption: ConsumptionFrequency

  /// Caffeine consumption cups per day
  var caffeineCupsPerDay: Int

  /// Smoking status
  var smokingStatus: SmokingStatus

  // MARK: - Health Goals

  /// Primary health goals
  var healthGoals: [HealthGoal]

  /// Goal timeline in weeks
  var goalTimelineWeeks: Int

  /// Additional notes or specific requests
  var additionalNotes: String?

  // MARK: - Computed Properties

  /// Calculate BMI from height and weight
  var bmi: Double {
    let heightM = heightCm / 100.0
    return weightKg / (heightM * heightM)
  }

  /// BMI category classification
  var bmiCategory: BMICategory {
    switch bmi {
    case ..<18.5: return .underweight
    case 18.5..<25: return .normal
    case 25..<30: return .overweight
    default: return .obese
    }
  }

  /// Estimated Basal Metabolic Rate using Mifflin-St Jeor equation
  var estimatedBMR: Double {
    let s = biologicalSex == .male ? 5.0 : -161.0
    return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + s
  }

  /// Estimated Total Daily Energy Expenditure
  var estimatedTDEE: Double {
    let activityMultiplier: Double
    switch (weeklyActivityDays, fitnessLevel) {
    case (0...1, _): activityMultiplier = 1.2
    case (2...3, .beginner): activityMultiplier = 1.375
    case (2...3, _): activityMultiplier = 1.55
    case (4...5, _): activityMultiplier = 1.55
    case (6...7, .advanced), (6...7, .athlete): activityMultiplier = 1.9
    default: activityMultiplier = 1.725
    }
    return estimatedBMR * activityMultiplier
  }

  // MARK: - Initialization

  init(
    displayName: String? = nil,
    age: Int,
    biologicalSex: BiologicalSex,
    heightCm: Double,
    weightKg: Double,
    bodyFatPercentage: Double? = nil,
    waistCircumferenceCm: Double? = nil,
    healthConditions: [HealthCondition] = [],
    familyHistoryNotes: String? = nil,
    allergies: [String] = [],
    currentMedications: [Medication] = [],
    currentSupplements: [CurrentSupplement] = [],
    fitnessLevel: FitnessLevel = .beginner,
    weeklyActivityDays: Int = 0,
    currentActivities: [ActivityType] = [],
    physicalLimitations: [String] = [],
    hasGymAccess: Bool = false,
    availableWorkoutMinutes: Int = 30,
    dietType: DietType = .omnivore,
    foodIntolerances: [String] = [],
    foodsToAvoid: [String] = [],
    favoriteFoods: [String] = [],
    dailyCalorieTarget: Int? = nil,
    mealsPerDay: Int = 3,
    cookingSkillLevel: CookingSkillLevel = .intermediate,
    weeklyMealPrepHours: Double = 3,
    averageSleepHours: Double = 7,
    sleepQuality: SleepQuality = .fair,
    stressLevel: StressLevel = .moderate,
    occupationType: OccupationType = .sedentary,
    dailyWaterIntakeLiters: Double = 2.0,
    alcoholConsumption: ConsumptionFrequency = .rarely,
    caffeineCupsPerDay: Int = 2,
    smokingStatus: SmokingStatus = .never,
    healthGoals: [HealthGoal] = [],
    goalTimelineWeeks: Int = 12,
    additionalNotes: String? = nil
  ) {
    self.id = UUID()
    self.createdAt = Date()
    self.updatedAt = Date()
    self.displayName = displayName
    self.age = age
    self.biologicalSex = biologicalSex
    self.heightCm = heightCm
    self.weightKg = weightKg
    self.bodyFatPercentage = bodyFatPercentage
    self.waistCircumferenceCm = waistCircumferenceCm
    self.healthConditions = healthConditions
    self.familyHistoryNotes = familyHistoryNotes
    self.allergies = allergies
    self.currentMedications = currentMedications
    self.currentSupplements = currentSupplements
    self.fitnessLevel = fitnessLevel
    self.weeklyActivityDays = weeklyActivityDays
    self.currentActivities = currentActivities
    self.physicalLimitations = physicalLimitations
    self.hasGymAccess = hasGymAccess
    self.availableWorkoutMinutes = availableWorkoutMinutes
    self.dietType = dietType
    self.foodIntolerances = foodIntolerances
    self.foodsToAvoid = foodsToAvoid
    self.favoriteFoods = favoriteFoods
    self.dailyCalorieTarget = dailyCalorieTarget
    self.mealsPerDay = mealsPerDay
    self.cookingSkillLevel = cookingSkillLevel
    self.weeklyMealPrepHours = weeklyMealPrepHours
    self.averageSleepHours = averageSleepHours
    self.sleepQuality = sleepQuality
    self.stressLevel = stressLevel
    self.occupationType = occupationType
    self.dailyWaterIntakeLiters = dailyWaterIntakeLiters
    self.alcoholConsumption = alcoholConsumption
    self.caffeineCupsPerDay = caffeineCupsPerDay
    self.smokingStatus = smokingStatus
    self.healthGoals = healthGoals
    self.goalTimelineWeeks = goalTimelineWeeks
    self.additionalNotes = additionalNotes
  }

  /// Update the updatedAt timestamp
  func markUpdated() {
    updatedAt = Date()
  }
}

// MARK: - Sample Data

extension UserProfile {
  /// Sample profile for previews and testing
  @MainActor static var sampleProfile: UserProfile {
    UserProfile(
      displayName: "John",
      age: 35,
      biologicalSex: .male,
      heightCm: 180,
      weightKg: 85,
      bodyFatPercentage: 22,
      healthConditions: [.prediabetes],
      allergies: ["Shellfish"],
      fitnessLevel: .intermediate,
      weeklyActivityDays: 3,
      currentActivities: [.weightTraining, .walking],
      hasGymAccess: true,
      availableWorkoutMinutes: 60,
      dietType: .omnivore,
      foodIntolerances: ["Lactose"],
      mealsPerDay: 3,
      cookingSkillLevel: .intermediate,
      averageSleepHours: 6.5,
      sleepQuality: .fair,
      stressLevel: .high,
      occupationType: .sedentary,
      healthGoals: [.loseWeight, .buildMuscle, .improveEnergy],
      goalTimelineWeeks: 16
    )
  }
}
