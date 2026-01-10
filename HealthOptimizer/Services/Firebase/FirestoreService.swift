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

    // Encode plans as nested Firestore documents
    if let supplementPlan = rec.supplementPlan {
      data["supplementPlan"] = encodeSupplementPlan(supplementPlan)
    }

    if let workoutPlan = rec.workoutPlan {
      data["workoutPlan"] = encodeWorkoutPlan(workoutPlan)
    }

    if let dietPlan = rec.dietPlan {
      data["dietPlan"] = encodeDietPlan(dietPlan)
    }

    return data
  }

  // MARK: - Supplement Plan Encoding

  private func encodeSupplementPlan(_ plan: SupplementPlan) -> [String: Any] {
    return [
      "id": plan.id.uuidString,
      "supplements": plan.supplements.map { encodeSupplementRecommendation($0) },
      "generalGuidelines": plan.generalGuidelines,
      "warnings": plan.warnings,
      "interactionNotes": plan.interactionNotes,
      "createdAt": Timestamp(date: plan.createdAt)
    ]
  }

  private func encodeSupplementRecommendation(_ supp: SupplementRecommendation) -> [String: Any] {
    return [
      "id": supp.id.uuidString,
      "name": supp.name,
      "alternateNames": supp.alternateNames,
      "dosage": supp.dosage,
      "unit": supp.unit,
      "timing": supp.timing.rawValue,
      "frequency": supp.frequency.rawValue,
      "withFood": supp.withFood,
      "priority": supp.priority.rawValue,
      "reasoning": supp.reasoning,
      "scientificBacking": supp.scientificBacking,
      "benefits": supp.benefits,
      "potentialSideEffects": supp.potentialSideEffects,
      "interactions": supp.interactions,
      "contraindications": supp.contraindications,
      "qualityNotes": supp.qualityNotes as Any,
      "estimatedMonthlyCost": supp.estimatedMonthlyCost as Any,
      "duration": supp.duration as Any
    ]
  }

  // MARK: - Workout Plan Encoding

  private func encodeWorkoutPlan(_ plan: WorkoutPlan) -> [String: Any] {
    return [
      "id": plan.id.uuidString,
      "name": plan.name,
      "description": plan.description,
      "durationWeeks": plan.durationWeeks,
      "daysPerWeek": plan.daysPerWeek,
      "workoutDays": plan.workoutDays.map { encodeWorkoutDay($0) },
      "restDayGuidelines": plan.restDayGuidelines,
      "warmupGuidelines": plan.warmupGuidelines,
      "cooldownGuidelines": plan.cooldownGuidelines,
      "progressionNotes": plan.progressionNotes,
      "equipmentNeeded": plan.equipmentNeeded,
      "difficultyLevel": plan.difficultyLevel.rawValue,
      "estimatedCaloriesBurnedPerSession": plan.estimatedCaloriesBurnedPerSession,
      "createdAt": Timestamp(date: plan.createdAt)
    ]
  }

  private func encodeWorkoutDay(_ day: WorkoutDay) -> [String: Any] {
    return [
      "id": day.id.uuidString,
      "dayNumber": day.dayNumber,
      "name": day.name,
      "focus": day.focus.map { $0.rawValue },
      "workoutType": day.workoutType.rawValue,
      "exercises": day.exercises.map { encodeExercise($0) },
      "estimatedDuration": day.estimatedDuration,
      "notes": day.notes as Any
    ]
  }

  private func encodeExercise(_ exercise: Exercise) -> [String: Any] {
    return [
      "id": exercise.id.uuidString,
      "name": exercise.name,
      "muscleGroups": exercise.muscleGroups.map { $0.rawValue },
      "sets": exercise.sets,
      "reps": exercise.reps,
      "restSeconds": exercise.restSeconds,
      "weight": exercise.weight as Any,
      "tempo": exercise.tempo as Any,
      "rpe": exercise.rpe as Any,
      "instructions": exercise.instructions,
      "tips": exercise.tips,
      "commonMistakes": exercise.commonMistakes,
      "alternatives": exercise.alternatives,
      "videoURL": exercise.videoURL as Any,
      "isSuperset": exercise.isSuperset,
      "supersetWith": exercise.supersetWith as Any
    ]
  }

  // MARK: - Diet Plan Encoding

  private func encodeDietPlan(_ plan: DietPlan) -> [String: Any] {
    return [
      "id": plan.id.uuidString,
      "name": plan.name,
      "description": plan.description,
      "dailyCalories": plan.dailyCalories,
      "macros": encodeMacroTargets(plan.macros),
      "mealSchedule": plan.mealSchedule.map { encodeMealTemplate($0) },
      "sampleMealPlan": plan.sampleMealPlan.map { encodeDayMealPlan($0) },
      "generalGuidelines": plan.generalGuidelines,
      "foodsToInclude": plan.foodsToInclude,
      "foodsToLimit": plan.foodsToLimit,
      "hydrationGuidelines": plan.hydrationGuidelines,
      "mealTimingGuidelines": plan.mealTimingGuidelines,
      "snackingGuidelines": plan.snackingGuidelines,
      "createdAt": Timestamp(date: plan.createdAt)
    ]
  }

  private func encodeMacroTargets(_ macros: MacroTargets) -> [String: Any] {
    return [
      "proteinGrams": macros.proteinGrams,
      "proteinPercentage": macros.proteinPercentage,
      "carbsGrams": macros.carbsGrams,
      "carbsPercentage": macros.carbsPercentage,
      "fatGrams": macros.fatGrams,
      "fatPercentage": macros.fatPercentage,
      "fiberGrams": macros.fiberGrams,
      "sugarLimitGrams": macros.sugarLimitGrams,
      "sodiumLimitMg": macros.sodiumLimitMg
    ]
  }

  private func encodeMealTemplate(_ template: MealTemplate) -> [String: Any] {
    return [
      "id": template.id.uuidString,
      "mealType": template.mealType.rawValue,
      "targetCalories": template.targetCalories,
      "targetProtein": template.targetProtein,
      "targetCarbs": template.targetCarbs,
      "targetFat": template.targetFat,
      "suggestedTime": template.suggestedTime,
      "guidelines": template.guidelines
    ]
  }

  private func encodeDayMealPlan(_ dayPlan: DayMealPlan) -> [String: Any] {
    return [
      "id": dayPlan.id.uuidString,
      "dayNumber": dayPlan.dayNumber,
      "dayName": dayPlan.dayName,
      "meals": dayPlan.meals.map { encodeMeal($0) },
      "totalCalories": dayPlan.totalCalories,
      "totalProtein": dayPlan.totalProtein,
      "totalCarbs": dayPlan.totalCarbs,
      "totalFat": dayPlan.totalFat,
      "notes": dayPlan.notes as Any
    ]
  }

  private func encodeMeal(_ meal: Meal) -> [String: Any] {
    return [
      "id": meal.id.uuidString,
      "mealType": meal.mealType.rawValue,
      "name": meal.name,
      "description": meal.description,
      "ingredients": meal.ingredients.map { encodeIngredient($0) },
      "instructions": meal.instructions,
      "prepTimeMinutes": meal.prepTimeMinutes,
      "cookTimeMinutes": meal.cookTimeMinutes,
      "servings": meal.servings,
      "calories": meal.calories,
      "protein": meal.protein,
      "carbs": meal.carbs,
      "fat": meal.fat,
      "fiber": meal.fiber,
      "tips": meal.tips,
      "substitutions": meal.substitutions,
      "mealPrepFriendly": meal.mealPrepFriendly,
      "tags": meal.tags
    ]
  }

  private func encodeIngredient(_ ingredient: Ingredient) -> [String: Any] {
    return [
      "id": ingredient.id.uuidString,
      "name": ingredient.name,
      "amount": ingredient.amount,
      "unit": ingredient.unit,
      "notes": ingredient.notes as Any,
      "isOptional": ingredient.isOptional
    ]
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

    // Decode plans from structured Firestore data
    var supplementPlan: SupplementPlan?
    if let planData = data["supplementPlan"] as? [String: Any] {
      supplementPlan = decodeSupplementPlan(from: planData)
    } else if let jsonString = data["supplementPlanJSON"] as? String,
              let jsonData = jsonString.data(using: .utf8) {
      // Legacy: fall back to JSON string decoding for existing data
      supplementPlan = try? JSONDecoder().decode(SupplementPlan.self, from: jsonData)
    }

    var workoutPlan: WorkoutPlan?
    if let planData = data["workoutPlan"] as? [String: Any] {
      workoutPlan = decodeWorkoutPlan(from: planData)
    } else if let jsonString = data["workoutPlanJSON"] as? String,
              let jsonData = jsonString.data(using: .utf8) {
      // Legacy: fall back to JSON string decoding for existing data
      workoutPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: jsonData)
    }

    var dietPlan: DietPlan?
    if let planData = data["dietPlan"] as? [String: Any] {
      dietPlan = decodeDietPlan(from: planData)
    } else if let jsonString = data["dietPlanJSON"] as? String,
              let jsonData = jsonString.data(using: .utf8) {
      // Legacy: fall back to JSON string decoding for existing data
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

  // MARK: - Supplement Plan Decoding

  private func decodeSupplementPlan(from data: [String: Any]) -> SupplementPlan {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
    let supplements = (data["supplements"] as? [[String: Any]])?.compactMap { decodeSupplementRecommendation(from: $0) } ?? []

    return SupplementPlan(
      id: id,
      supplements: supplements,
      generalGuidelines: data["generalGuidelines"] as? String ?? "",
      warnings: data["warnings"] as? [String] ?? [],
      interactionNotes: data["interactionNotes"] as? [String] ?? [],
      createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    )
  }

  private func decodeSupplementRecommendation(from data: [String: Any]) -> SupplementRecommendation {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()

    return SupplementRecommendation(
      id: id,
      name: data["name"] as? String ?? "",
      alternateNames: data["alternateNames"] as? [String] ?? [],
      dosage: data["dosage"] as? String ?? "",
      unit: data["unit"] as? String ?? "mg",
      timing: SupplementTiming(rawValue: data["timing"] as? String ?? "") ?? .morning,
      frequency: SupplementFrequency(rawValue: data["frequency"] as? String ?? "") ?? .daily,
      withFood: data["withFood"] as? Bool ?? true,
      priority: SupplementPriority(rawValue: data["priority"] as? String ?? "") ?? .recommended,
      reasoning: data["reasoning"] as? String ?? "",
      scientificBacking: data["scientificBacking"] as? String ?? "",
      benefits: data["benefits"] as? [String] ?? [],
      potentialSideEffects: data["potentialSideEffects"] as? [String] ?? [],
      interactions: data["interactions"] as? [String] ?? [],
      contraindications: data["contraindications"] as? [String] ?? [],
      qualityNotes: data["qualityNotes"] as? String,
      estimatedMonthlyCost: data["estimatedMonthlyCost"] as? String,
      duration: data["duration"] as? String
    )
  }

  // MARK: - Workout Plan Decoding

  private func decodeWorkoutPlan(from data: [String: Any]) -> WorkoutPlan {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
    let workoutDays = (data["workoutDays"] as? [[String: Any]])?.compactMap { decodeWorkoutDay(from: $0) } ?? []

    return WorkoutPlan(
      id: id,
      name: data["name"] as? String ?? "Custom Workout Plan",
      description: data["description"] as? String ?? "",
      durationWeeks: data["durationWeeks"] as? Int ?? 8,
      daysPerWeek: data["daysPerWeek"] as? Int ?? 4,
      workoutDays: workoutDays,
      restDayGuidelines: data["restDayGuidelines"] as? String ?? "",
      warmupGuidelines: data["warmupGuidelines"] as? String ?? "",
      cooldownGuidelines: data["cooldownGuidelines"] as? String ?? "",
      progressionNotes: data["progressionNotes"] as? String ?? "",
      equipmentNeeded: data["equipmentNeeded"] as? [String] ?? [],
      difficultyLevel: FitnessLevel(rawValue: data["difficultyLevel"] as? String ?? "") ?? .intermediate,
      estimatedCaloriesBurnedPerSession: data["estimatedCaloriesBurnedPerSession"] as? String ?? "",
      createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    )
  }

  private func decodeWorkoutDay(from data: [String: Any]) -> WorkoutDay {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
    let focus = (data["focus"] as? [String])?.compactMap { MuscleGroup(rawValue: $0) } ?? []
    let exercises = (data["exercises"] as? [[String: Any]])?.compactMap { decodeExercise(from: $0) } ?? []

    return WorkoutDay(
      id: id,
      dayNumber: data["dayNumber"] as? Int ?? 1,
      name: data["name"] as? String ?? "",
      focus: focus,
      workoutType: WorkoutType(rawValue: data["workoutType"] as? String ?? "") ?? .strength,
      exercises: exercises,
      estimatedDuration: data["estimatedDuration"] as? Int ?? 45,
      notes: data["notes"] as? String
    )
  }

  private func decodeExercise(from data: [String: Any]) -> Exercise {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
    let muscleGroups = (data["muscleGroups"] as? [String])?.compactMap { MuscleGroup(rawValue: $0) } ?? []

    return Exercise(
      id: id,
      name: data["name"] as? String ?? "",
      muscleGroups: muscleGroups,
      sets: data["sets"] as? Int ?? 3,
      reps: data["reps"] as? String ?? "10",
      restSeconds: data["restSeconds"] as? Int ?? 60,
      weight: data["weight"] as? String,
      tempo: data["tempo"] as? String,
      rpe: data["rpe"] as? Int,
      instructions: data["instructions"] as? String ?? "",
      tips: data["tips"] as? [String] ?? [],
      commonMistakes: data["commonMistakes"] as? [String] ?? [],
      alternatives: data["alternatives"] as? [String] ?? [],
      videoURL: data["videoURL"] as? String,
      isSuperset: data["isSuperset"] as? Bool ?? false,
      supersetWith: data["supersetWith"] as? String
    )
  }

  // MARK: - Diet Plan Decoding

  private func decodeDietPlan(from data: [String: Any]) -> DietPlan {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
    let macros = (data["macros"] as? [String: Any]).map { decodeMacroTargets(from: $0) } ?? MacroTargets()
    let mealSchedule = (data["mealSchedule"] as? [[String: Any]])?.compactMap { decodeMealTemplate(from: $0) } ?? []
    let sampleMealPlan = (data["sampleMealPlan"] as? [[String: Any]])?.compactMap { decodeDayMealPlan(from: $0) } ?? []

    return DietPlan(
      id: id,
      name: data["name"] as? String ?? "Custom Diet Plan",
      description: data["description"] as? String ?? "",
      dailyCalories: data["dailyCalories"] as? Int ?? 2000,
      macros: macros,
      mealSchedule: mealSchedule,
      sampleMealPlan: sampleMealPlan,
      generalGuidelines: data["generalGuidelines"] as? [String] ?? [],
      foodsToInclude: data["foodsToInclude"] as? [String] ?? [],
      foodsToLimit: data["foodsToLimit"] as? [String] ?? [],
      hydrationGuidelines: data["hydrationGuidelines"] as? String ?? "",
      mealTimingGuidelines: data["mealTimingGuidelines"] as? String ?? "",
      snackingGuidelines: data["snackingGuidelines"] as? String ?? "",
      createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    )
  }

  private func decodeMacroTargets(from data: [String: Any]) -> MacroTargets {
    return MacroTargets(
      proteinGrams: data["proteinGrams"] as? Int ?? 150,
      proteinPercentage: data["proteinPercentage"] as? Int ?? 30,
      carbsGrams: data["carbsGrams"] as? Int ?? 200,
      carbsPercentage: data["carbsPercentage"] as? Int ?? 40,
      fatGrams: data["fatGrams"] as? Int ?? 67,
      fatPercentage: data["fatPercentage"] as? Int ?? 30,
      fiberGrams: data["fiberGrams"] as? Int ?? 30,
      sugarLimitGrams: data["sugarLimitGrams"] as? Int ?? 50,
      sodiumLimitMg: data["sodiumLimitMg"] as? Int ?? 2300
    )
  }

  private func decodeMealTemplate(from data: [String: Any]) -> MealTemplate {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()

    return MealTemplate(
      id: id,
      mealType: MealType(rawValue: data["mealType"] as? String ?? "") ?? .lunch,
      targetCalories: data["targetCalories"] as? Int ?? 0,
      targetProtein: data["targetProtein"] as? Int ?? 0,
      targetCarbs: data["targetCarbs"] as? Int ?? 0,
      targetFat: data["targetFat"] as? Int ?? 0,
      suggestedTime: data["suggestedTime"] as? String ?? "",
      guidelines: data["guidelines"] as? String ?? ""
    )
  }

  private func decodeDayMealPlan(from data: [String: Any]) -> DayMealPlan {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
    let meals = (data["meals"] as? [[String: Any]])?.compactMap { decodeMeal(from: $0) } ?? []

    return DayMealPlan(
      id: id,
      dayNumber: data["dayNumber"] as? Int ?? 1,
      dayName: data["dayName"] as? String ?? "",
      meals: meals,
      totalCalories: data["totalCalories"] as? Int ?? 0,
      totalProtein: data["totalProtein"] as? Int ?? 0,
      totalCarbs: data["totalCarbs"] as? Int ?? 0,
      totalFat: data["totalFat"] as? Int ?? 0,
      notes: data["notes"] as? String
    )
  }

  private func decodeMeal(from data: [String: Any]) -> Meal {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
    let ingredients = (data["ingredients"] as? [[String: Any]])?.compactMap { decodeIngredient(from: $0) } ?? []

    return Meal(
      id: id,
      mealType: MealType(rawValue: data["mealType"] as? String ?? "") ?? .lunch,
      name: data["name"] as? String ?? "",
      description: data["description"] as? String ?? "",
      ingredients: ingredients,
      instructions: data["instructions"] as? [String] ?? [],
      prepTimeMinutes: data["prepTimeMinutes"] as? Int ?? 10,
      cookTimeMinutes: data["cookTimeMinutes"] as? Int ?? 15,
      servings: data["servings"] as? Int ?? 1,
      calories: data["calories"] as? Int ?? 0,
      protein: data["protein"] as? Int ?? 0,
      carbs: data["carbs"] as? Int ?? 0,
      fat: data["fat"] as? Int ?? 0,
      fiber: data["fiber"] as? Int ?? 0,
      tips: data["tips"] as? [String] ?? [],
      substitutions: data["substitutions"] as? [String: String] ?? [:],
      mealPrepFriendly: data["mealPrepFriendly"] as? Bool ?? false,
      tags: data["tags"] as? [String] ?? []
    )
  }

  private func decodeIngredient(from data: [String: Any]) -> Ingredient {
    let id = (data["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()

    // Handle amount as Int or Double
    let amount: Double
    if let doubleValue = data["amount"] as? Double {
      amount = doubleValue
    } else if let intValue = data["amount"] as? Int {
      amount = Double(intValue)
    } else {
      amount = 0
    }

    return Ingredient(
      id: id,
      name: data["name"] as? String ?? "",
      amount: amount,
      unit: data["unit"] as? String ?? "",
      notes: data["notes"] as? String,
      isOptional: data["isOptional"] as? Bool ?? false
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
