//
//  OnboardingViewModel.swift
//  HealthOptimizer
//
//  ViewModel managing onboarding flow state and data collection
//

import Foundation
import SwiftUI

// MARK: - Onboarding Step

/// Enumeration of onboarding steps
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case basicInfo
    case healthConditions
    case medications
    case fitness
    case diet
    case lifestyle
    case goals
    case review

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .basicInfo: return "Basic Information"
        case .healthConditions: return "Health Conditions"
        case .medications: return "Medications & Supplements"
        case .fitness: return "Fitness Profile"
        case .diet: return "Dietary Preferences"
        case .lifestyle: return "Lifestyle"
        case .goals: return "Your Goals"
        case .review: return "Review"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return "Let's get started"
        case .basicInfo: return "Tell us about yourself"
        case .healthConditions: return "Your medical history"
        case .medications: return "What you're currently taking"
        case .fitness: return "Your activity level"
        case .diet: return "How you eat"
        case .lifestyle: return "Daily habits"
        case .goals: return "What you want to achieve"
        case .review: return "Confirm your information"
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .basicInfo: return "person.fill"
        case .healthConditions: return "heart.text.square.fill"
        case .medications: return "pills.fill"
        case .fitness: return "figure.run"
        case .diet: return "fork.knife"
        case .lifestyle: return "moon.stars.fill"
        case .goals: return "target"
        case .review: return "checkmark.circle.fill"
        }
    }

    /// Progress percentage (0-1)
    var progress: Double {
        Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}

// MARK: - Onboarding View Model

/// Observable ViewModel for onboarding flow
@Observable
final class OnboardingViewModel {

    // MARK: - Navigation State

    var currentStep: OnboardingStep = .welcome
    var showingValidationError = false
    var validationErrorMessage = ""

    // MARK: - Basic Info

    var displayName: String = ""
    var age: Int = 30
    var biologicalSex: BiologicalSex = .male
    var heightCm: Double = 170
    var weightKg: Double = 70
    var bodyFatPercentage: Double?
    var waistCircumferenceCm: Double?

    // MARK: - Health Conditions

    var selectedConditions: Set<HealthCondition> = []
    var familyHistoryNotes: String = ""
    var allergies: [String] = []
    var newAllergy: String = ""

    // MARK: - Medications & Supplements

    var currentMedications: [Medication] = []
    var currentSupplements: [CurrentSupplement] = []

    // MARK: - Fitness

    var fitnessLevel: FitnessLevel = .beginner
    var weeklyActivityDays: Int = 3
    var selectedActivities: Set<ActivityType> = []
    var physicalLimitations: [String] = []
    var hasGymAccess: Bool = false
    var availableWorkoutMinutes: Int = 45

    // MARK: - Diet

    var dietType: DietType = .omnivore
    var foodIntolerances: [String] = []
    var foodsToAvoid: [String] = []
    var favoriteFoods: [String] = []
    var mealsPerDay: Int = 3
    var cookingSkillLevel: CookingSkillLevel = .intermediate
    var weeklyMealPrepHours: Double = 3

    // MARK: - Lifestyle

    var averageSleepHours: Double = 7
    var sleepQuality: SleepQuality = .fair
    var stressLevel: StressLevel = .moderate
    var occupationType: OccupationType = .sedentary
    var dailyWaterIntakeLiters: Double = 2.0
    var alcoholConsumption: ConsumptionFrequency = .rarely
    var caffeineCupsPerDay: Int = 2
    var smokingStatus: SmokingStatus = .never

    // MARK: - Goals

    var selectedGoals: Set<HealthGoal> = []
    var goalTimelineWeeks: Int = 12
    var additionalNotes: String = ""

    // MARK: - Computed Properties

    /// Calculate BMI from current inputs
    var calculatedBMI: Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }

    var bmiCategory: BMICategory {
        switch calculatedBMI {
        case ..<18.5: return .underweight
        case 18.5..<25: return .normal
        case 25..<30: return .overweight
        default: return .obese
        }
    }

    /// Check if current step is valid
    var isCurrentStepValid: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .basicInfo:
            return age >= 13 && age <= 120 && heightCm >= 100 && heightCm <= 250 && weightKg >= 20 && weightKg <= 300
        case .healthConditions:
            return true // Optional
        case .medications:
            return true // Optional
        case .fitness:
            return true
        case .diet:
            return true
        case .lifestyle:
            return averageSleepHours >= 0 && averageSleepHours <= 24
        case .goals:
            return !selectedGoals.isEmpty
        case .review:
            return true
        }
    }

    /// Check if we can proceed to next step
    var canProceed: Bool {
        isCurrentStepValid
    }

    /// Check if we can go back
    var canGoBack: Bool {
        currentStep.rawValue > 0
    }

    /// Progress value for progress bar
    var progress: Double {
        currentStep.progress
    }

    // MARK: - Navigation Methods

    /// Move to next step
    func nextStep() {
        guard canProceed else {
            showValidationError()
            return
        }

        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = next
            }
        }
    }

    /// Move to previous step
    func previousStep() {
        if let previous = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = previous
            }
        }
    }

    /// Jump to a specific step
    func goToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    private func showValidationError() {
        switch currentStep {
        case .basicInfo:
            validationErrorMessage = "Please enter valid age (13-120), height (100-250cm), and weight (20-300kg)."
        case .goals:
            validationErrorMessage = "Please select at least one health goal."
        default:
            validationErrorMessage = "Please complete all required fields."
        }
        showingValidationError = true
    }

    // MARK: - Data Management

    /// Add an allergy
    func addAllergy() {
        let trimmed = newAllergy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !allergies.contains(trimmed) else { return }
        allergies.append(trimmed)
        newAllergy = ""
    }

    /// Remove an allergy
    func removeAllergy(_ allergy: String) {
        allergies.removeAll { $0 == allergy }
    }

    /// Add a medication
    func addMedication(name: String, dosage: String, frequency: MedicationFrequency) {
        let medication = Medication(name: name, dosage: dosage, frequency: frequency)
        currentMedications.append(medication)
    }

    /// Remove a medication
    func removeMedication(_ medication: Medication) {
        currentMedications.removeAll { $0.id == medication.id }
    }

    /// Add a supplement
    func addSupplement(name: String, dosage: String, frequency: MedicationFrequency) {
        let supplement = CurrentSupplement(name: name, dosage: dosage, frequency: frequency)
        currentSupplements.append(supplement)
    }

    /// Remove a supplement
    func removeSupplement(_ supplement: CurrentSupplement) {
        currentSupplements.removeAll { $0.id == supplement.id }
    }

    /// Toggle a health condition
    func toggleCondition(_ condition: HealthCondition) {
        if selectedConditions.contains(condition) {
            selectedConditions.remove(condition)
        } else {
            // Remove "none" if selecting a condition
            if condition != .none {
                selectedConditions.remove(.none)
            } else {
                // Clear all if selecting "none"
                selectedConditions.removeAll()
            }
            selectedConditions.insert(condition)
        }
    }

    /// Toggle an activity
    func toggleActivity(_ activity: ActivityType) {
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }

    /// Toggle a goal
    func toggleGoal(_ goal: HealthGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    // MARK: - Profile Creation

    /// Create a UserProfile from the collected data
    func createProfile() -> UserProfile {
        return UserProfile(
            displayName: displayName.isEmpty ? nil : displayName,
            age: age,
            biologicalSex: biologicalSex,
            heightCm: heightCm,
            weightKg: weightKg,
            bodyFatPercentage: bodyFatPercentage,
            waistCircumferenceCm: waistCircumferenceCm,
            healthConditions: Array(selectedConditions),
            familyHistoryNotes: familyHistoryNotes.isEmpty ? nil : familyHistoryNotes,
            allergies: allergies,
            currentMedications: currentMedications,
            currentSupplements: currentSupplements,
            fitnessLevel: fitnessLevel,
            weeklyActivityDays: weeklyActivityDays,
            currentActivities: Array(selectedActivities),
            physicalLimitations: physicalLimitations,
            hasGymAccess: hasGymAccess,
            availableWorkoutMinutes: availableWorkoutMinutes,
            dietType: dietType,
            foodIntolerances: foodIntolerances,
            foodsToAvoid: foodsToAvoid,
            favoriteFoods: favoriteFoods,
            mealsPerDay: mealsPerDay,
            cookingSkillLevel: cookingSkillLevel,
            weeklyMealPrepHours: weeklyMealPrepHours,
            averageSleepHours: averageSleepHours,
            sleepQuality: sleepQuality,
            stressLevel: stressLevel,
            occupationType: occupationType,
            dailyWaterIntakeLiters: dailyWaterIntakeLiters,
            alcoholConsumption: alcoholConsumption,
            caffeineCupsPerDay: caffeineCupsPerDay,
            smokingStatus: smokingStatus,
            healthGoals: Array(selectedGoals),
            goalTimelineWeeks: goalTimelineWeeks,
            additionalNotes: additionalNotes.isEmpty ? nil : additionalNotes
        )
    }

    /// Reset the onboarding state
    func reset() {
        currentStep = .welcome
        displayName = ""
        age = 30
        biologicalSex = .male
        heightCm = 170
        weightKg = 70
        bodyFatPercentage = nil
        selectedConditions = []
        allergies = []
        currentMedications = []
        currentSupplements = []
        fitnessLevel = .beginner
        weeklyActivityDays = 3
        selectedActivities = []
        physicalLimitations = []
        hasGymAccess = false
        dietType = .omnivore
        selectedGoals = []
        goalTimelineWeeks = 12
    }
}
