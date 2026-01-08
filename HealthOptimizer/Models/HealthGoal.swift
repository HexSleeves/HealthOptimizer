//
//  HealthGoal.swift
//  HealthOptimizer
//
//  User health goals and objectives models
//

import Foundation

// MARK: - Health Goal

/// Primary health and fitness goals
enum HealthGoal: String, Codable, CaseIterable, Identifiable, Sendable {
    // Weight Management
    case loseWeight = "Lose Weight"
    case gainWeight = "Gain Weight"
    case maintainWeight = "Maintain Current Weight"
    
    // Body Composition
    case buildMuscle = "Build Muscle"
    case loseFat = "Reduce Body Fat"
    case toneUp = "Tone & Define Muscles"
    case bodyRecomposition = "Body Recomposition"
    
    // Performance
    case improveStrength = "Increase Strength"
    case improveEndurance = "Improve Endurance"
    case improveFlexibility = "Improve Flexibility"
    case improveAthletic = "Enhance Athletic Performance"
    
    // Health & Wellness
    case improveEnergy = "Boost Energy Levels"
    case improveSleep = "Better Sleep Quality"
    case reduceStress = "Reduce Stress"
    case improveMood = "Improve Mood"
    case improveDigestion = "Improve Digestion"
    case improveImmunity = "Strengthen Immune System"
    
    // Specific Health
    case heartHealth = "Improve Heart Health"
    case bloodSugar = "Manage Blood Sugar"
    case jointHealth = "Support Joint Health"
    case brainHealth = "Enhance Cognitive Function"
    case boneHealth = "Improve Bone Health"
    case skinHealth = "Improve Skin Health"
    case hormoneBalance = "Balance Hormones"
    
    // Longevity
    case longevity = "Optimize for Longevity"
    case antiAging = "Anti-Aging Support"
    
    var id: String { rawValue }
    
    /// Icon for the goal
    var icon: String {
        switch self {
        case .loseWeight, .loseFat:
            return "arrow.down.circle.fill"
        case .gainWeight, .buildMuscle:
            return "arrow.up.circle.fill"
        case .maintainWeight:
            return "equal.circle.fill"
        case .toneUp, .bodyRecomposition:
            return "figure.stand"
        case .improveStrength:
            return "dumbbell.fill"
        case .improveEndurance:
            return "figure.run"
        case .improveFlexibility:
            return "figure.yoga"
        case .improveAthletic:
            return "trophy.fill"
        case .improveEnergy:
            return "bolt.fill"
        case .improveSleep:
            return "moon.fill"
        case .reduceStress:
            return "leaf.fill"
        case .improveMood:
            return "face.smiling.fill"
        case .improveDigestion:
            return "stomach"
        case .improveImmunity:
            return "shield.fill"
        case .heartHealth:
            return "heart.fill"
        case .bloodSugar:
            return "drop.fill"
        case .jointHealth:
            return "figure.walk"
        case .brainHealth:
            return "brain.head.profile"
        case .boneHealth:
            return "figure.stand"
        case .skinHealth:
            return "sparkles"
        case .hormoneBalance:
            return "waveform.path.ecg"
        case .longevity, .antiAging:
            return "hourglass"
        }
    }
    
    /// Category for grouping
    var category: GoalCategory {
        switch self {
        case .loseWeight, .gainWeight, .maintainWeight:
            return .weightManagement
        case .buildMuscle, .loseFat, .toneUp, .bodyRecomposition:
            return .bodyComposition
        case .improveStrength, .improveEndurance, .improveFlexibility, .improveAthletic:
            return .performance
        case .improveEnergy, .improveSleep, .reduceStress, .improveMood, .improveDigestion, .improveImmunity:
            return .wellness
        case .heartHealth, .bloodSugar, .jointHealth, .brainHealth, .boneHealth, .skinHealth, .hormoneBalance:
            return .specificHealth
        case .longevity, .antiAging:
            return .longevity
        }
    }
    
    /// Brief description of what achieving this goal involves
    var description: String {
        switch self {
        case .loseWeight:
            return "Reduce overall body weight through caloric deficit and exercise"
        case .gainWeight:
            return "Increase body weight through caloric surplus and strength training"
        case .buildMuscle:
            return "Increase muscle mass through progressive resistance training"
        case .improveEnergy:
            return "Optimize nutrition, sleep, and lifestyle for sustained energy"
        case .improveSleep:
            return "Enhance sleep quality and duration for better recovery"
        case .heartHealth:
            return "Support cardiovascular health through diet and exercise"
        case .brainHealth:
            return "Support cognitive function, memory, and mental clarity"
        default:
            return "Work towards this goal with personalized recommendations"
        }
    }
}

// MARK: - Goal Category

/// Categories for organizing health goals
enum GoalCategory: String, CaseIterable, Identifiable {
    case weightManagement = "Weight Management"
    case bodyComposition = "Body Composition"
    case performance = "Performance"
    case wellness = "Health & Wellness"
    case specificHealth = "Specific Health Areas"
    case longevity = "Longevity"
    
    var id: String { rawValue }
    
    /// Goals in this category
    var goals: [HealthGoal] {
        HealthGoal.allCases.filter { $0.category == self }
    }
}

// MARK: - Progress Entry

import SwiftData

/// Tracks user progress over time
@Model
final class ProgressEntry {
    var id: UUID
    var date: Date
    var weight: Double?
    var bodyFatPercentage: Double?
    var waistCircumference: Double?
    var notes: String?
    var mood: Int?  // 1-5 scale
    var energyLevel: Int?  // 1-5 scale
    var sleepHours: Double?
    var workoutsCompleted: Int?
    var supplementsAdherence: Int?  // 0-100 percentage
    var dietAdherence: Int?  // 0-100 percentage
    
    init(
        date: Date = Date(),
        weight: Double? = nil,
        bodyFatPercentage: Double? = nil,
        waistCircumference: Double? = nil,
        notes: String? = nil,
        mood: Int? = nil,
        energyLevel: Int? = nil,
        sleepHours: Double? = nil,
        workoutsCompleted: Int? = nil,
        supplementsAdherence: Int? = nil,
        dietAdherence: Int? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.bodyFatPercentage = bodyFatPercentage
        self.waistCircumference = waistCircumference
        self.notes = notes
        self.mood = mood
        self.energyLevel = energyLevel
        self.sleepHours = sleepHours
        self.workoutsCompleted = workoutsCompleted
        self.supplementsAdherence = supplementsAdherence
        self.dietAdherence = dietAdherence
    }
}
