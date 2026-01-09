//
//  HealthCondition.swift
//  HealthOptimizer
//
//  Health conditions and medical history models
//

import Foundation

// MARK: - Health Condition

/// Common health conditions that affect supplementation, diet, and exercise recommendations
/// IMPORTANT: This is not an exhaustive list. Users should always consult healthcare providers.
enum HealthCondition: String, Codable, CaseIterable, Identifiable, Sendable {
  // Metabolic
  case diabetes = "Type 2 Diabetes"
  case prediabetes = "Prediabetes"
  case insulinResistance = "Insulin Resistance"
  case metabolicSyndrome = "Metabolic Syndrome"
  case hypothyroidism = "Hypothyroidism"
  case hyperthyroidism = "Hyperthyroidism"

  // Cardiovascular
  case highBloodPressure = "High Blood Pressure"
  case highCholesterol = "High Cholesterol"
  case heartDisease = "Heart Disease"
  case arrhythmia = "Arrhythmia"

  // Digestive
  case ibs = "IBS (Irritable Bowel Syndrome)"
  case ibd = "IBD (Crohn's/Colitis)"
  case gerd = "GERD/Acid Reflux"
  case celiac = "Celiac Disease"
  case gallstones = "Gallstones/Gallbladder Issues"

  // Musculoskeletal
  case arthritis = "Arthritis"
  case osteoporosis = "Osteoporosis"
  case backPain = "Chronic Back Pain"
  case fibromyalgia = "Fibromyalgia"

  // Mental Health
  case anxiety = "Anxiety"
  case depression = "Depression"
  case adhd = "ADHD"
  case insomnia = "Insomnia/Sleep Disorders"

  // Hormonal
  case pcos = "PCOS"
  case endometriosis = "Endometriosis"
  case lowTestosterone = "Low Testosterone"
  case menopause = "Menopause/Perimenopause"

  // Autoimmune
  case autoimmune = "Autoimmune Disorder"
  case hashimotos = "Hashimoto's Thyroiditis"
  case lupus = "Lupus"
  case multiplesclerosis = "Multiple Sclerosis"

  // Other
  case anemia = "Anemia"
  case asthma = "Asthma"
  case kidneyDisease = "Kidney Disease"
  case liverDisease = "Liver Disease"
  case cancer = "Cancer (Current/History)"
  case none = "None of the Above"

  var id: String { rawValue }

  /// Category for grouping in UI
  var category: HealthConditionCategory {
    switch self {
    case .diabetes, .prediabetes, .insulinResistance, .metabolicSyndrome, .hypothyroidism,
      .hyperthyroidism:
      return .metabolic
    case .highBloodPressure, .highCholesterol, .heartDisease, .arrhythmia:
      return .cardiovascular
    case .ibs, .ibd, .gerd, .celiac, .gallstones:
      return .digestive
    case .arthritis, .osteoporosis, .backPain, .fibromyalgia:
      return .musculoskeletal
    case .anxiety, .depression, .adhd, .insomnia:
      return .mentalHealth
    case .pcos, .endometriosis, .lowTestosterone, .menopause:
      return .hormonal
    case .autoimmune, .hashimotos, .lupus, .multiplesclerosis:
      return .autoimmune
    case .anemia, .asthma, .kidneyDisease, .liverDisease, .cancer, .none:
      return .other
    }
  }

  /// Important contraindications to consider
  var supplementContraindications: [String] {
    switch self {
    case .highBloodPressure:
      return ["Licorice root", "High-dose caffeine", "Ephedra"]
    case .diabetes, .prediabetes:
      return ["High-dose chromium (monitor blood sugar)"]
    case .heartDisease, .arrhythmia:
      return ["Stimulants", "High-dose caffeine", "Ephedra"]
    case .kidneyDisease:
      return ["High-dose vitamin C", "High protein supplements", "Potassium"]
    case .liverDisease:
      return ["Kava", "High-dose vitamin A", "High-dose niacin"]
    case .autoimmune, .hashimotos, .lupus, .multiplesclerosis:
      return ["Immune-boosting supplements (use caution)"]
    default:
      return []
    }
  }
}

// MARK: - Health Condition Category

/// Categories for organizing health conditions in the UI
enum HealthConditionCategory: String, CaseIterable, Identifiable {
  case metabolic = "Metabolic"
  case cardiovascular = "Cardiovascular"
  case digestive = "Digestive"
  case musculoskeletal = "Musculoskeletal"
  case mentalHealth = "Mental Health"
  case hormonal = "Hormonal"
  case autoimmune = "Autoimmune"
  case other = "Other"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .metabolic: return "flame.fill"
    case .cardiovascular: return "heart.fill"
    case .digestive: return "stomach"
    case .musculoskeletal: return "figure.stand"
    case .mentalHealth: return "brain.head.profile"
    case .hormonal: return "waveform.path.ecg"
    case .autoimmune: return "shield.fill"
    case .other: return "cross.case.fill"
    }
  }

  /// Get conditions for this category
  var conditions: [HealthCondition] {
    HealthCondition.allCases.filter { $0.category == self }
  }
}
