//
//  SyncService.swift
//  HealthOptimizer
//
//  Service to sync data between local SwiftData and Firebase Firestore
//

import Foundation
import SwiftData

// MARK: - Sync Service

/// Manages synchronization between local SwiftData storage and Firebase Firestore
@MainActor
@Observable
final class SyncService {

  // MARK: - Singleton

  static let shared = SyncService()

  // MARK: - Dependencies

  private let authService = AuthService.shared
  private let firestoreService = FirestoreService.shared
  private let persistenceService = PersistenceService.shared

  // MARK: - State

  /// Whether a sync is in progress
  private(set) var isSyncing = false

  /// Last sync timestamp
  private(set) var lastSyncDate: Date?

  /// Sync error if any
  private(set) var syncError: Error?

  // MARK: - Initialization

  private init() {}

  // MARK: - Sync Operations

  /// Perform a full sync (download from cloud, then upload local changes)
  func performFullSync() async {
    guard authService.isSignedIn else {
      print("[SyncService] Not signed in, skipping sync")
      return
    }

    isSyncing = true
    syncError = nil

    defer {
      isSyncing = false
      lastSyncDate = Date()
    }

    do {
      // First, try to fetch from cloud
      try await syncFromCloud()

      // Then, push local changes to cloud
      try await syncToCloud()

      print("[SyncService] Full sync completed successfully")
    } catch {
      syncError = error
      print("[SyncService] Sync failed: \(error)")
    }
  }

  /// Download data from Firestore and update local SwiftData
  func syncFromCloud() async throws {
    guard authService.isSignedIn else { return }

    print("[SyncService] Syncing from cloud...")

    // Fetch profile from cloud
    if let cloudProfile = try await firestoreService.fetchProfile() {
      let localProfile = persistenceService.fetchUserProfile()

      // If no local profile or cloud is newer, use cloud data
      if localProfile == nil || cloudProfile.updatedAt > (localProfile?.updatedAt ?? .distantPast) {
        try updateLocalProfile(from: cloudProfile)
        print("[SyncService] Updated local profile from cloud")
      }
    }

    // Fetch latest recommendation from cloud
    if let cloudRec = try await firestoreService.fetchLatestRecommendation() {
      let localRec = persistenceService.fetchLatestRecommendation()

      // If no local or cloud is newer, use cloud data
      if localRec == nil || cloudRec.updatedAt > (localRec?.updatedAt ?? .distantPast) {
        try updateLocalRecommendation(from: cloudRec)
        print("[SyncService] Updated local recommendation from cloud")
      }
    }
  }

  /// Upload local SwiftData to Firestore
  func syncToCloud() async throws {
    guard authService.isSignedIn else { return }

    print("[SyncService] Syncing to cloud...")

    // Upload profile
    if let profile = persistenceService.fetchUserProfile() {
      try await firestoreService.saveProfile(profile)
      print("[SyncService] Uploaded profile to cloud")
    }

    // Upload latest recommendation
    if let recommendation = persistenceService.fetchLatestRecommendation(),
       recommendation.status == .completed {
      try await firestoreService.saveRecommendation(recommendation)
      print("[SyncService] Uploaded recommendation to cloud")
    }
  }

  /// Sync a single profile change to cloud
  func syncProfile(_ profile: UserProfile) async {
    guard authService.isSignedIn else { return }

    do {
      try await firestoreService.saveProfile(profile)
      print("[SyncService] Profile synced to cloud")
    } catch {
      print("[SyncService] Failed to sync profile: \(error)")
    }
  }

  /// Sync a single recommendation to cloud
  func syncRecommendation(_ recommendation: HealthRecommendation) async {
    guard authService.isSignedIn else { return }

    do {
      try await firestoreService.saveRecommendation(recommendation)
      print("[SyncService] Recommendation synced to cloud")
    } catch {
      print("[SyncService] Failed to sync recommendation: \(error)")
    }
  }

  // MARK: - Local Update Helpers

  private func updateLocalProfile(from dto: UserProfileDTO) throws {
    let context = persistenceService.mainContext

    // Delete existing profile if any
    if let existing = persistenceService.fetchUserProfile() {
      context.delete(existing)
    }

    // Create new profile from DTO
    let profile = UserProfile(
      displayName: dto.displayName,
      age: dto.age,
      biologicalSex: dto.biologicalSex,
      heightCm: dto.heightCm,
      weightKg: dto.weightKg,
      bodyFatPercentage: dto.bodyFatPercentage,
      waistCircumferenceCm: dto.waistCircumferenceCm,
      healthConditions: dto.healthConditions,
      familyHistoryNotes: dto.familyHistoryNotes,
      allergies: dto.allergies,
      currentMedications: dto.currentMedications,
      currentSupplements: dto.currentSupplements,
      fitnessLevel: dto.fitnessLevel,
      weeklyActivityDays: dto.weeklyActivityDays,
      currentActivities: dto.currentActivities,
      physicalLimitations: dto.physicalLimitations,
      hasGymAccess: dto.hasGymAccess,
      availableWorkoutMinutes: dto.availableWorkoutMinutes,
      dietType: dto.dietType,
      foodIntolerances: dto.foodIntolerances,
      foodsToAvoid: dto.foodsToAvoid,
      favoriteFoods: dto.favoriteFoods,
      dailyCalorieTarget: dto.dailyCalorieTarget,
      mealsPerDay: dto.mealsPerDay,
      cookingSkillLevel: dto.cookingSkillLevel,
      weeklyMealPrepHours: dto.weeklyMealPrepHours,
      averageSleepHours: dto.averageSleepHours,
      sleepQuality: dto.sleepQuality,
      stressLevel: dto.stressLevel,
      occupationType: dto.occupationType,
      dailyWaterIntakeLiters: dto.dailyWaterIntakeLiters,
      alcoholConsumption: dto.alcoholConsumption,
      caffeineCupsPerDay: dto.caffeineCupsPerDay,
      smokingStatus: dto.smokingStatus,
      healthGoals: dto.healthGoals,
      goalTimelineWeeks: dto.goalTimelineWeeks,
      additionalNotes: dto.additionalNotes
    )

    context.insert(profile)
    try context.save()
  }

  private func updateLocalRecommendation(from dto: HealthRecommendationDTO) throws {
    let context = persistenceService.mainContext

    // Check if recommendation already exists locally
    let existing = persistenceService.fetchAllRecommendations().first { $0.id == dto.id }

    let recommendation: HealthRecommendation
    if let existing = existing {
      recommendation = existing
    } else {
      recommendation = HealthRecommendation()
      context.insert(recommendation)
    }

    // Update properties
    recommendation.status = dto.status
    recommendation.healthSummary = dto.healthSummary
    recommendation.keyInsights = dto.keyInsights
    recommendation.priorityActions = dto.priorityActions
    recommendation.supplementPlan = dto.supplementPlan
    recommendation.workoutPlan = dto.workoutPlan
    recommendation.dietPlan = dto.dietPlan
    recommendation.lifestyleRecommendations = dto.lifestyleRecommendations
    recommendation.disclaimers = dto.disclaimers
    recommendation.suggestedReviewWeeks = dto.suggestedReviewWeeks

    try context.save()
  }

  // MARK: - Account Management

  /// Handle user sign out - clear local data option
  func handleSignOut(clearLocalData: Bool) {
    if clearLocalData {
      do {
        try persistenceService.deleteAllData()
        print("[SyncService] Local data cleared on sign out")
      } catch {
        print("[SyncService] Failed to clear local data: \(error)")
      }
    }
  }

  /// Handle account deletion - delete from cloud and local
  func handleAccountDeletion() async throws {
    // Delete from Firestore first
    try await firestoreService.deleteAllUserData()

    // Then delete local data
    try persistenceService.deleteAllData()

    // Finally delete the auth account
    try await authService.deleteAccount()

    print("[SyncService] Account and all data deleted")
  }
}
