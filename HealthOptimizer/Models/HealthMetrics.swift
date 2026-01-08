//
//  HealthMetrics.swift
//  HealthOptimizer
//
//  Enums and supporting types for health metrics
//

import Foundation

// MARK: - Biological Sex

/// Biological sex for health calculations
/// Used for accurate BMR, hormone considerations, etc.
enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    
    var id: String { rawValue }
}

// MARK: - BMI Categories

/// BMI classification categories
enum BMICategory: String, Codable {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"
    
    var description: String {
        switch self {
        case .underweight:
            return "BMI below 18.5 - Consider consulting a healthcare provider about healthy weight gain."
        case .normal:
            return "BMI 18.5-24.9 - You're in a healthy weight range."
        case .overweight:
            return "BMI 25-29.9 - Consider lifestyle modifications for optimal health."
        case .obese:
            return "BMI 30+ - Consult a healthcare provider for personalized guidance."
        }
    }
    
    var color: String {
        switch self {
        case .underweight: return "yellow"
        case .normal: return "green"
        case .overweight: return "orange"
        case .obese: return "red"
        }
    }
}

// MARK: - Fitness Level

/// Self-assessed fitness level
enum FitnessLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case athlete = "Athlete"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .beginner:
            return "New to exercise or returning after a long break"
        case .intermediate:
            return "Regularly active for 6+ months with good form"
        case .advanced:
            return "Consistently training for 2+ years with structured programs"
        case .athlete:
            return "Competitive athlete or professional-level fitness"
        }
    }
}

// MARK: - Activity Types

/// Types of physical activities
enum ActivityType: String, Codable, CaseIterable, Identifiable {
    case walking = "Walking"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case weightTraining = "Weight Training"
    case yoga = "Yoga"
    case pilates = "Pilates"
    case hiit = "HIIT"
    case crossfit = "CrossFit"
    case sports = "Sports"
    case martialArts = "Martial Arts"
    case dancing = "Dancing"
    case hiking = "Hiking"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .weightTraining: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .hiit: return "bolt.fill"
        case .crossfit: return "figure.strengthtraining.traditional"
        case .sports: return "sportscourt.fill"
        case .martialArts: return "figure.martial.arts"
        case .dancing: return "figure.dance"
        case .hiking: return "figure.hiking"
        case .other: return "figure.mixed.cardio"
        }
    }
}

// MARK: - Sleep Quality

/// Self-assessed sleep quality
enum SleepQuality: String, Codable, CaseIterable, Identifiable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .poor:
            return "Frequently wake up tired, trouble falling/staying asleep"
        case .fair:
            return "Sometimes have sleep issues, occasionally feel unrested"
        case .good:
            return "Generally sleep well, wake up feeling rested most days"
        case .excellent:
            return "Consistently great sleep, always wake up refreshed"
        }
    }
}

// MARK: - Stress Level

/// Self-assessed stress level
enum StressLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .low:
            return "Rarely feel stressed, good work-life balance"
        case .moderate:
            return "Normal day-to-day stress, manageable"
        case .high:
            return "Frequently feel stressed, impacts daily life"
        case .veryHigh:
            return "Constantly stressed, significantly impacts wellbeing"
        }
    }
}

// MARK: - Occupation Type

/// Type of occupation affecting daily activity
enum OccupationType: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Sedentary (Desk Job)"
    case lightlyActive = "Lightly Active (Standing/Walking)"
    case moderatelyActive = "Moderately Active (Physical Work)"
    case veryActive = "Very Active (Labor Intensive)"
    
    var id: String { rawValue }
}

// MARK: - Consumption Frequency

/// Frequency of consumption (alcohol, etc.)
enum ConsumptionFrequency: String, Codable, CaseIterable, Identifiable {
    case never = "Never"
    case rarely = "Rarely (few times/year)"
    case occasionally = "Occasionally (few times/month)"
    case weekly = "Weekly"
    case daily = "Daily"
    
    var id: String { rawValue }
}

// MARK: - Smoking Status

/// Current smoking status
enum SmokingStatus: String, Codable, CaseIterable, Identifiable {
    case never = "Never Smoked"
    case former = "Former Smoker"
    case occasional = "Occasional Smoker"
    case current = "Current Smoker"
    
    var id: String { rawValue }
}

// MARK: - Diet Type

/// Primary diet type
enum DietType: String, Codable, CaseIterable, Identifiable {
    case omnivore = "Omnivore"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case keto = "Ketogenic"
    case paleo = "Paleo"
    case mediterranean = "Mediterranean"
    case glutenFree = "Gluten-Free"
    case halal = "Halal"
    case kosher = "Kosher"
    case other = "Other"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .omnivore: return "Eats all food groups including meat"
        case .vegetarian: return "No meat, may include dairy and eggs"
        case .vegan: return "No animal products"
        case .pescatarian: return "Vegetarian plus fish/seafood"
        case .keto: return "Very low carb, high fat"
        case .paleo: return "Focus on whole foods, no processed foods"
        case .mediterranean: return "Plant-based with healthy fats, fish, and moderate meat"
        case .glutenFree: return "Avoids gluten-containing foods"
        case .halal: return "Follows Islamic dietary laws"
        case .kosher: return "Follows Jewish dietary laws"
        case .other: return "Custom dietary approach"
        }
    }
}

// MARK: - Cooking Skill Level

/// Self-assessed cooking ability
enum CookingSkillLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case professional = "Professional"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .beginner:
            return "Basic cooking, mostly simple recipes"
        case .intermediate:
            return "Comfortable with most recipes, can adapt dishes"
        case .advanced:
            return "Skilled cook, can tackle complex recipes"
        case .professional:
            return "Professional level, culinary training"
        }
    }
}
