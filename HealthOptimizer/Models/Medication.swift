//
//  Medication.swift
//  HealthOptimizer
//
//  Models for medications and current supplements
//

import Foundation

// MARK: - Medication

/// Represents a current medication the user is taking
/// Important for checking interactions with supplements
struct Medication: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var purpose: String?
    var startDate: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        dosage: String = "",
        frequency: MedicationFrequency = .daily,
        purpose: String? = nil,
        startDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.purpose = purpose
        self.startDate = startDate
    }
}

// MARK: - Medication Frequency

/// How often a medication is taken
enum MedicationFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case asNeeded = "As Needed"
    case daily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case threeTimesDaily = "Three Times Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var id: String { rawValue }
}

// MARK: - Current Supplement

/// Represents a supplement the user is currently taking
/// Used to avoid duplication and check for interactions
struct CurrentSupplement: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var brand: String?
    var startDate: Date?
    var reasonForTaking: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        dosage: String = "",
        frequency: MedicationFrequency = .daily,
        brand: String? = nil,
        startDate: Date? = nil,
        reasonForTaking: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.brand = brand
        self.startDate = startDate
        self.reasonForTaking = reasonForTaking
    }
}

// MARK: - Common Medications Reference

/// Reference data for common medication categories
/// Helps with interaction checking and AI prompts
enum MedicationCategory: String, CaseIterable {
    case bloodPressure = "Blood Pressure Medications"
    case cholesterol = "Cholesterol Medications (Statins)"
    case diabetes = "Diabetes Medications"
    case bloodThinners = "Blood Thinners"
    case thyroid = "Thyroid Medications"
    case antidepressants = "Antidepressants"
    case anxiolytics = "Anti-Anxiety Medications"
    case painRelievers = "Pain Relievers"
    case hormones = "Hormone Therapy"
    case immunosuppressants = "Immunosuppressants"
    case other = "Other"
    
    /// Common examples of medications in this category
    var examples: [String] {
        switch self {
        case .bloodPressure:
            return ["Lisinopril", "Amlodipine", "Metoprolol", "Losartan"]
        case .cholesterol:
            return ["Atorvastatin", "Simvastatin", "Rosuvastatin"]
        case .diabetes:
            return ["Metformin", "Insulin", "Glipizide", "Ozempic"]
        case .bloodThinners:
            return ["Warfarin", "Aspirin", "Eliquis", "Xarelto"]
        case .thyroid:
            return ["Levothyroxine", "Synthroid", "Armour Thyroid"]
        case .antidepressants:
            return ["Sertraline", "Escitalopram", "Bupropion", "Fluoxetine"]
        case .anxiolytics:
            return ["Alprazolam", "Lorazepam", "Buspirone"]
        case .painRelievers:
            return ["Ibuprofen", "Acetaminophen", "Naproxen", "Tramadol"]
        case .hormones:
            return ["Birth Control", "HRT", "Testosterone"]
        case .immunosuppressants:
            return ["Prednisone", "Methotrexate", "Humira"]
        case .other:
            return []
        }
    }
    
    /// Known supplement interactions for this medication category
    var knownInteractions: [String] {
        switch self {
        case .bloodThinners:
            return ["Vitamin K", "Fish Oil (high dose)", "Vitamin E (high dose)", "Ginkgo", "Garlic (high dose)"]
        case .thyroid:
            return ["Iron", "Calcium", "Soy"]
        case .diabetes:
            return ["Chromium", "Alpha-lipoic acid", "Berberine"]
        case .bloodPressure:
            return ["Potassium", "Licorice root", "St. John's Wort"]
        case .antidepressants:
            return ["St. John's Wort", "5-HTP", "SAMe"]
        case .immunosuppressants:
            return ["Echinacea", "Immune boosters"]
        default:
            return []
        }
    }
}
