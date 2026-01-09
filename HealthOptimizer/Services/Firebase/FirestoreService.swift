//
//  FirestoreService.swift
//  HealthOptimizer
//
//  Firestore database service for cloud sync
//

import FirebaseFirestore
import Foundation

// MARK: - Firestore Service

/// Service for syncing data with Firebase Firestore
@MainActor
final class FirestoreService {

  // MARK: - Singleton

  static let shared = FirestoreService()

  // MARK: - Properties

  private let db = Firestore.firestore()
  private let authService = AuthService.shared

  // MARK: - Collection References

  private var userDocument: DocumentReference? {
    guard let userId = authService.currentUser?.uid else { return nil }
    return db.collection("users").document(userId)
  }

  private var profileDocument: DocumentReference? {
    userDocument?.collection("data").document("profile")
  }

  private var recommendationsCollection: CollectionReference? {
    userDocument?.collection("recommendations")
  }

  private var progressCollection: CollectionReference? {
    userDocument?.collection("progress")
  }

  // MARK: - Initialization

  private init() {
    // Configure Firestore settings
    let settings = FirestoreSettings()
    settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024) // 100MB cache
    db.settings = settings
  }

  // MARK: - User Profile

  /// Save user profile to Firestore
  func saveProfile(_ profile: UserProfile) async throws {
    guard let docRef = profileDocument else {
      throw FirestoreError.notAuthenticated
    }

    let data = try encodeProfile(profile)
    try await docRef.setData(data, merge: true)
    print("[FirestoreService] Profile saved successfully")
  }

  /// Fetch user profile from Firestore
  func fetchProfile() async throws -> UserProfileDTO? {
    guard let docRef = profileDocument else {
      throw FirestoreError.notAuthenticated
    }

    let snapshot = try await docRef.getDocument()

    guard snapshot.exists, let data = snapshot.data() else {
      return nil
    }

    return try decodeProfile(from: data)
  }

  /// Delete user profile from Firestore
  func deleteProfile() async throws {
    guard let docRef = profileDocument else {
      throw FirestoreError.notAuthenticated
    }

    try await docRef.delete()
    print("[FirestoreService] Profile deleted successfully")
  }

  // MARK: - Recommendations

  /// Save recommendation to Firestore
  func saveRecommendation(_ recommendation: HealthRecommendation) async throws {
    guard let collectionRef = recommendationsCollection else {
      throw FirestoreError.notAuthenticated
    }

    let data = try encodeRecommendation(recommendation)
    try await collectionRef.document(recommendation.id.uuidString).setData(data)
    print("[FirestoreService] Recommendation saved successfully")
  }

  /// Fetch all recommendations from Firestore
  func fetchRecommendations() async throws -> [HealthRecommendationDTO] {
    guard let collectionRef = recommendationsCollection else {
      throw FirestoreError.notAuthenticated
    }

    let snapshot = try await collectionRef
      .order(by: "createdAt", descending: true)
      .limit(to: 10)
      .getDocuments()

    return try snapshot.documents.compactMap { doc in
      try decodeRecommendation(from: doc.data())
    }
  }

  /// Fetch latest recommendation from Firestore
  func fetchLatestRecommendation() async throws -> HealthRecommendationDTO? {
    guard let collectionRef = recommendationsCollection else {
      throw FirestoreError.notAuthenticated
    }

    let snapshot = try await collectionRef
      .order(by: "createdAt", descending: true)
      .limit(to: 1)
      .getDocuments()

    guard let doc = snapshot.documents.first else {
      return nil
    }

    return try decodeRecommendation(from: doc.data())
  }

  /// Delete a recommendation from Firestore
  func deleteRecommendation(id: UUID) async throws {
    guard let collectionRef = recommendationsCollection else {
      throw FirestoreError.notAuthenticated
    }

    try await collectionRef.document(id.uuidString).delete()
    print("[FirestoreService] Recommendation deleted successfully")
  }

  // MARK: - Progress Entries

  /// Save progress entry to Firestore
  func saveProgressEntry(_ entry: ProgressEntryDTO) async throws {
    guard let collectionRef = progressCollection else {
      throw FirestoreError.notAuthenticated
    }

    let data = try encodeProgressEntry(entry)
    try await collectionRef.document(entry.id.uuidString).setData(data)
    print("[FirestoreService] Progress entry saved successfully")
  }

  /// Fetch progress entries from Firestore
  func fetchProgressEntries(from startDate: Date, to endDate: Date) async throws -> [ProgressEntryDTO] {
    guard let collectionRef = progressCollection else {
      throw FirestoreError.notAuthenticated
    }

    let snapshot = try await collectionRef
      .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
      .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
      .order(by: "date", descending: false)
      .getDocuments()

    return try snapshot.documents.compactMap { doc in
      try decodeProgressEntry(from: doc.data())
    }
  }

  // MARK: - Delete All User Data

  /// Delete all user data from Firestore
  func deleteAllUserData() async throws {
    guard let userDoc = userDocument else {
      throw FirestoreError.notAuthenticated
    }

    // Delete profile
    try? await profileDocument?.delete()

    // Delete recommendations
    if let recsCollection = recommendationsCollection {
      let recsSnapshot = try await recsCollection.getDocuments()
      for doc in recsSnapshot.documents {
        try await doc.reference.delete()
      }
    }

    // Delete progress entries
    if let progressCol = progressCollection {
      let progressSnapshot = try await progressCol.getDocuments()
      for doc in progressSnapshot.documents {
        try await doc.reference.delete()
      }
    }

    // Delete user document
    try await userDoc.delete()

    print("[FirestoreService] All user data deleted successfully")
  }

  // MARK: - Encoding Helpers

  private func encodeProfile(_ profile: UserProfile) throws -> [String: Any] {
    return [
      "id": profile.id.uuidString,
      "displayName": profile.displayName as Any,
      "createdAt": Timestamp(date: profile.createdAt),
      "updatedAt": Timestamp(date: profile.updatedAt),
      "age": profile.age,
      "biologicalSex": profile.biologicalSex.rawValue,
      "heightCm": profile.heightCm,
      "weightKg": profile.weightKg,
      "bodyFatPercentage": profile.bodyFatPercentage as Any,
      "waistCircumferenceCm": profile.waistCircumferenceCm as Any,
      "healthConditions": profile.healthConditions.map { $0.rawValue },
      "familyHistoryNotes": profile.familyHistoryNotes as Any,
      "allergies": profile.allergies,
      "currentMedications": profile.currentMedications.map { encodeMedication($0) },
      "currentSupplements": profile.currentSupplements.map { encodeSupplement($0) },
      "fitnessLevel": profile.fitnessLevel.rawValue,
      "weeklyActivityDays": profile.weeklyActivityDays,
      "currentActivities": profile.currentActivities.map { $0.rawValue },
      "physicalLimitations": profile.physicalLimitations,
      "hasGymAccess": profile.hasGymAccess,
      "availableWorkoutMinutes": profile.availableWorkoutMinutes,
      "dietType": profile.dietType.rawValue,
      "foodIntolerances": profile.foodIntolerances,
      "foodsToAvoid": profile.foodsToAvoid,
      "favoriteFoods": profile.favoriteFoods,
      "dailyCalorieTarget": profile.dailyCalorieTarget as Any,
      "mealsPerDay": profile.mealsPerDay,
      "cookingSkillLevel": profile.cookingSkillLevel.rawValue,
      "weeklyMealPrepHours": profile.weeklyMealPrepHours,
      "averageSleepHours": profile.averageSleepHours,
      "sleepQuality": profile.sleepQuality.rawValue,
      "stressLevel": profile.stressLevel.rawValue,
      "occupationType": profile.occupationType.rawValue,
      "dailyWaterIntakeLiters": profile.dailyWaterIntakeLiters,
      "alcoholConsumption": profile.alcoholConsumption.rawValue,
      "caffeineCupsPerDay": profile.caffeineCupsPerDay,
      "smokingStatus": profile.smokingStatus.rawValue,
      "healthGoals": profile.healthGoals.map { $0.rawValue },
      "goalTimelineWeeks": profile.goalTimelineWeeks,
      "additionalNotes": profile.additionalNotes as Any
    ]
  }

  private func encodeMedication(_ med: Medication) -> [String: Any] {
    return [
      "name": med.name,
      "dosage": med.dosage,
      "frequency": med.frequency.rawValue,
      "purpose": med.purpose as Any
    ]
  }

  private func encodeSupplement(_ supp: CurrentSupplement) -> [String: Any] {
    return [
      "name": supp.name,
      "dosage": supp.dosage,
      "frequency": supp.frequency.rawValue
    ]
  }

  private func encodeRecommendation(_ rec: HealthRecommendation) throws -> [String: Any] {
    var data: [String: Any] = [
      "id": rec.id.uuidString,
      "createdAt": Timestamp(date: rec.createdAt),
      "updatedAt": Timestamp(date: rec.updatedAt),
      "status": rec.status.rawValue,
      "healthSummary": rec.healthSummary,
      "keyInsights": rec.keyInsights,
      "priorityActions": rec.priorityActions,
      "lifestyleRecommendations": rec.lifestyleRecommendations,
      "disclaimers": rec.disclaimers,
      "suggestedReviewWeeks": rec.suggestedReviewWeeks
    ]

    // Encode plans as JSON strings for simplicity
    if let supplementPlan = rec.supplementPlan {
      let jsonData = try JSONEncoder().encode(supplementPlan)
      data["supplementPlanJSON"] = String(data: jsonData, encoding: .utf8)
    }

    if let workoutPlan = rec.workoutPlan {
      let jsonData = try JSONEncoder().encode(workoutPlan)
      data["workoutPlanJSON"] = String(data: jsonData, encoding: .utf8)
    }

    if let dietPlan = rec.dietPlan {
      let jsonData = try JSONEncoder().encode(dietPlan)
      data["dietPlanJSON"] = String(data: jsonData, encoding: .utf8)
    }

    return data
  }

  private func encodeProgressEntry(_ entry: ProgressEntryDTO) throws -> [String: Any] {
    return [
      "id": entry.id.uuidString,
      "date": Timestamp(date: entry.date),
      "weight": entry.weight as Any,
      "bodyFatPercentage": entry.bodyFatPercentage as Any,
      "waistCircumference": entry.waistCircumference as Any,
      "notes": entry.notes as Any,
      "mood": entry.mood as Any,
      "energyLevel": entry.energyLevel as Any,
      "sleepHours": entry.sleepHours as Any,
      "workoutsCompleted": entry.workoutsCompleted as Any,
      "supplementsAdherence": entry.supplementsAdherence as Any,
      "dietAdherence": entry.dietAdherence as Any
    ]
  }

  // MARK: - Decoding Helpers

  private func decodeProfile(from data: [String: Any]) throws -> UserProfileDTO {
    guard let idString = data["id"] as? String,
          let id = UUID(uuidString: idString),
          let age = data["age"] as? Int,
          let biologicalSexRaw = data["biologicalSex"] as? String,
          let biologicalSex = BiologicalSex(rawValue: biologicalSexRaw),
          let heightCm = data["heightCm"] as? Double,
          let weightKg = data["weightKg"] as? Double else {
      throw FirestoreError.decodingFailed
    }

    return UserProfileDTO(
      id: id,
      displayName: data["displayName"] as? String,
      createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
      updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
      age: age,
      biologicalSex: biologicalSex,
      heightCm: heightCm,
      weightKg: weightKg,
      bodyFatPercentage: data["bodyFatPercentage"] as? Double,
      waistCircumferenceCm: data["waistCircumferenceCm"] as? Double,
      healthConditions: (data["healthConditions"] as? [String])?.compactMap { HealthCondition(rawValue: $0) } ?? [],
      familyHistoryNotes: data["familyHistoryNotes"] as? String,
      allergies: data["allergies"] as? [String] ?? [],
      currentMedications: (data["currentMedications"] as? [[String: Any]])?.map { decodeMedication($0) } ?? [],
      currentSupplements: (data["currentSupplements"] as? [[String: Any]])?.map { decodeSupplement($0) } ?? [],
      fitnessLevel: FitnessLevel(rawValue: data["fitnessLevel"] as? String ?? "") ?? .beginner,
      weeklyActivityDays: data["weeklyActivityDays"] as? Int ?? 0,
      currentActivities: (data["currentActivities"] as? [String])?.compactMap { ActivityType(rawValue: $0) } ?? [],
      physicalLimitations: data["physicalLimitations"] as? [String] ?? [],
      hasGymAccess: data["hasGymAccess"] as? Bool ?? false,
      availableWorkoutMinutes: data["availableWorkoutMinutes"] as? Int ?? 30,
      dietType: DietType(rawValue: data["dietType"] as? String ?? "") ?? .omnivore,
      foodIntolerances: data["foodIntolerances"] as? [String] ?? [],
      foodsToAvoid: data["foodsToAvoid"] as? [String] ?? [],
      favoriteFoods: data["favoriteFoods"] as? [String] ?? [],
      dailyCalorieTarget: data["dailyCalorieTarget"] as? Int,
      mealsPerDay: data["mealsPerDay"] as? Int ?? 3,
      cookingSkillLevel: CookingSkillLevel(rawValue: data["cookingSkillLevel"] as? String ?? "") ?? .intermediate,
      weeklyMealPrepHours: data["weeklyMealPrepHours"] as? Double ?? 3,
      averageSleepHours: data["averageSleepHours"] as? Double ?? 7,
      sleepQuality: SleepQuality(rawValue: data["sleepQuality"] as? String ?? "") ?? .fair,
      stressLevel: StressLevel(rawValue: data["stressLevel"] as? String ?? "") ?? .moderate,
      occupationType: OccupationType(rawValue: data["occupationType"] as? String ?? "") ?? .sedentary,
      dailyWaterIntakeLiters: data["dailyWaterIntakeLiters"] as? Double ?? 2,
      alcoholConsumption: ConsumptionFrequency(rawValue: data["alcoholConsumption"] as? String ?? "") ?? .rarely,
      caffeineCupsPerDay: data["caffeineCupsPerDay"] as? Int ?? 2,
      smokingStatus: SmokingStatus(rawValue: data["smokingStatus"] as? String ?? "") ?? .never,
      healthGoals: (data["healthGoals"] as? [String])?.compactMap { HealthGoal(rawValue: $0) } ?? [],
      goalTimelineWeeks: data["goalTimelineWeeks"] as? Int ?? 12,
      additionalNotes: data["additionalNotes"] as? String
    )
  }

  private func decodeMedication(_ data: [String: Any]) -> Medication {
    Medication(
      name: data["name"] as? String ?? "",
      dosage: data["dosage"] as? String ?? "",
      frequency: MedicationFrequency(rawValue: data["frequency"] as? String ?? "") ?? .daily,
      purpose: data["purpose"] as? String
    )
  }

  private func decodeSupplement(_ data: [String: Any]) -> CurrentSupplement {
    CurrentSupplement(
      name: data["name"] as? String ?? "",
      dosage: data["dosage"] as? String ?? "",
      frequency: MedicationFrequency(rawValue: data["frequency"] as? String ?? "") ?? .daily
    )
  }

  private func decodeRecommendation(from data: [String: Any]) throws -> HealthRecommendationDTO {
    guard let idString = data["id"] as? String,
          let id = UUID(uuidString: idString) else {
      throw FirestoreError.decodingFailed
    }

    var supplementPlan: SupplementPlan?
    if let jsonString = data["supplementPlanJSON"] as? String,
       let jsonData = jsonString.data(using: .utf8) {
      supplementPlan = try? JSONDecoder().decode(SupplementPlan.self, from: jsonData)
    }

    var workoutPlan: WorkoutPlan?
    if let jsonString = data["workoutPlanJSON"] as? String,
       let jsonData = jsonString.data(using: .utf8) {
      workoutPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: jsonData)
    }

    var dietPlan: DietPlan?
    if let jsonString = data["dietPlanJSON"] as? String,
       let jsonData = jsonString.data(using: .utf8) {
      dietPlan = try? JSONDecoder().decode(DietPlan.self, from: jsonData)
    }

    return HealthRecommendationDTO(
      id: id,
      createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
      updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
      status: RecommendationStatus(rawValue: data["status"] as? String ?? "") ?? .pending,
      healthSummary: data["healthSummary"] as? String ?? "",
      keyInsights: data["keyInsights"] as? [String] ?? [],
      priorityActions: data["priorityActions"] as? [String] ?? [],
      supplementPlan: supplementPlan,
      workoutPlan: workoutPlan,
      dietPlan: dietPlan,
      lifestyleRecommendations: data["lifestyleRecommendations"] as? [String] ?? [],
      disclaimers: data["disclaimers"] as? [String] ?? [],
      suggestedReviewWeeks: data["suggestedReviewWeeks"] as? Int ?? 8
    )
  }

  private func decodeProgressEntry(from data: [String: Any]) throws -> ProgressEntryDTO {
    guard let idString = data["id"] as? String,
          let id = UUID(uuidString: idString) else {
      throw FirestoreError.decodingFailed
    }

    return ProgressEntryDTO(
      id: id,
      date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
      weight: data["weight"] as? Double,
      bodyFatPercentage: data["bodyFatPercentage"] as? Double,
      waistCircumference: data["waistCircumference"] as? Double,
      notes: data["notes"] as? String,
      mood: data["mood"] as? Int,
      energyLevel: data["energyLevel"] as? Int,
      sleepHours: data["sleepHours"] as? Double,
      workoutsCompleted: data["workoutsCompleted"] as? Int,
      supplementsAdherence: data["supplementsAdherence"] as? Int,
      dietAdherence: data["dietAdherence"] as? Int
    )
  }
}

// MARK: - Firestore Errors

enum FirestoreError: LocalizedError {
  case notAuthenticated
  case decodingFailed
  case encodingFailed
  case documentNotFound

  var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      return "You must be signed in to sync data."
    case .decodingFailed:
      return "Failed to read data from cloud."
    case .encodingFailed:
      return "Failed to prepare data for upload."
    case .documentNotFound:
      return "Requested data not found."
    }
  }
}

// MARK: - Data Transfer Objects

/// DTO for transferring profile data to/from Firestore
struct UserProfileDTO {
  var id: UUID
  var displayName: String?
  var createdAt: Date
  var updatedAt: Date
  var age: Int
  var biologicalSex: BiologicalSex
  var heightCm: Double
  var weightKg: Double
  var bodyFatPercentage: Double?
  var waistCircumferenceCm: Double?
  var healthConditions: [HealthCondition]
  var familyHistoryNotes: String?
  var allergies: [String]
  var currentMedications: [Medication]
  var currentSupplements: [CurrentSupplement]
  var fitnessLevel: FitnessLevel
  var weeklyActivityDays: Int
  var currentActivities: [ActivityType]
  var physicalLimitations: [String]
  var hasGymAccess: Bool
  var availableWorkoutMinutes: Int
  var dietType: DietType
  var foodIntolerances: [String]
  var foodsToAvoid: [String]
  var favoriteFoods: [String]
  var dailyCalorieTarget: Int?
  var mealsPerDay: Int
  var cookingSkillLevel: CookingSkillLevel
  var weeklyMealPrepHours: Double
  var averageSleepHours: Double
  var sleepQuality: SleepQuality
  var stressLevel: StressLevel
  var occupationType: OccupationType
  var dailyWaterIntakeLiters: Double
  var alcoholConsumption: ConsumptionFrequency
  var caffeineCupsPerDay: Int
  var smokingStatus: SmokingStatus
  var healthGoals: [HealthGoal]
  var goalTimelineWeeks: Int
  var additionalNotes: String?
}

/// DTO for transferring recommendation data to/from Firestore
struct HealthRecommendationDTO {
  var id: UUID
  var createdAt: Date
  var updatedAt: Date
  var status: RecommendationStatus
  var healthSummary: String
  var keyInsights: [String]
  var priorityActions: [String]
  var supplementPlan: SupplementPlan?
  var workoutPlan: WorkoutPlan?
  var dietPlan: DietPlan?
  var lifestyleRecommendations: [String]
  var disclaimers: [String]
  var suggestedReviewWeeks: Int
}

/// DTO for transferring progress entry data to/from Firestore
struct ProgressEntryDTO {
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
}
