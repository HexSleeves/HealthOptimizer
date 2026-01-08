//
//  PersistenceService.swift
//  HealthOptimizer
//
//  SwiftData persistence management and data operations
//

import Foundation
import SwiftData

// MARK: - Persistence Service

/// Service for managing SwiftData persistence operations
@MainActor
final class PersistenceService {

    // MARK: - Singleton

    static let shared = PersistenceService()

    // MARK: - Properties

    /// Model container for SwiftData
    let container: ModelContainer

    /// Main context for UI operations
    var mainContext: ModelContext {
        container.mainContext
    }

    // MARK: - Initialization

    private init() {
        let schema = Schema([
            UserProfile.self,
            HealthRecommendation.self,
            ProgressEntry.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - User Profile Operations

    /// Fetch the current user profile
    func fetchUserProfile() -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let profiles = try mainContext.fetch(descriptor)
            return profiles.first
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }

    /// Save a user profile
    func saveUserProfile(_ profile: UserProfile) throws {
        mainContext.insert(profile)
        try mainContext.save()
    }

    /// Update an existing profile
    func updateUserProfile(_ profile: UserProfile) throws {
        profile.markUpdated()
        try mainContext.save()
    }

    /// Delete a user profile and all associated data
    func deleteUserProfile(_ profile: UserProfile) throws {
        mainContext.delete(profile)
        try mainContext.save()
    }

    // MARK: - Recommendation Operations

    /// Fetch the latest recommendation
    func fetchLatestRecommendation() -> HealthRecommendation? {
        let descriptor = FetchDescriptor<HealthRecommendation>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let recommendations = try mainContext.fetch(descriptor)
            return recommendations.first
        } catch {
            print("Error fetching recommendation: \(error)")
            return nil
        }
    }

    /// Fetch all recommendations
    func fetchAllRecommendations() -> [HealthRecommendation] {
        let descriptor = FetchDescriptor<HealthRecommendation>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try mainContext.fetch(descriptor)
        } catch {
            print("Error fetching recommendations: \(error)")
            return []
        }
    }

    /// Save a new recommendation
    func saveRecommendation(_ recommendation: HealthRecommendation) throws {
        mainContext.insert(recommendation)
        try mainContext.save()
    }

    /// Delete old recommendations (keep last N)
    func pruneOldRecommendations(keepLast count: Int = 5) throws {
        let recommendations = fetchAllRecommendations()
        if recommendations.count > count {
            for recommendation in recommendations.dropFirst(count) {
                mainContext.delete(recommendation)
            }
            try mainContext.save()
        }
    }

    // MARK: - Progress Entry Operations

    /// Fetch progress entries within a date range
    func fetchProgressEntries(from startDate: Date, to endDate: Date) -> [ProgressEntry] {
        let predicate = #Predicate<ProgressEntry> { entry in
            entry.date >= startDate && entry.date <= endDate
        }

        let descriptor = FetchDescriptor<ProgressEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            return try mainContext.fetch(descriptor)
        } catch {
            print("Error fetching progress entries: \(error)")
            return []
        }
    }

    /// Fetch all progress entries
    func fetchAllProgressEntries() -> [ProgressEntry] {
        let descriptor = FetchDescriptor<ProgressEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try mainContext.fetch(descriptor)
        } catch {
            print("Error fetching progress entries: \(error)")
            return []
        }
    }

    /// Save a progress entry
    func saveProgressEntry(_ entry: ProgressEntry) throws {
        mainContext.insert(entry)
        try mainContext.save()
    }

    // MARK: - Data Management

    /// Delete all user data (for account reset)
    func deleteAllData() throws {
        // Delete all profiles
        let profiles = try mainContext.fetch(FetchDescriptor<UserProfile>())
        for profile in profiles {
            mainContext.delete(profile)
        }

        // Delete all recommendations
        let recommendations = try mainContext.fetch(FetchDescriptor<HealthRecommendation>())
        for rec in recommendations {
            mainContext.delete(rec)
        }

        // Delete all progress entries
        let entries = try mainContext.fetch(FetchDescriptor<ProgressEntry>())
        for entry in entries {
            mainContext.delete(entry)
        }

        try mainContext.save()
    }

    /// Export user data as JSON (for data portability)
    func exportUserData() throws -> Data {
        struct ExportData: Codable {
            var exportDate: Date
            var profile: UserProfileExport?
            var progressEntries: [ProgressEntryExport]
        }

        struct UserProfileExport: Codable {
            var age: Int
            var biologicalSex: String
            var heightCm: Double
            var weightKg: Double
            var healthConditions: [String]
            var healthGoals: [String]
            var createdAt: Date
        }

        struct ProgressEntryExport: Codable {
            var date: Date
            var weight: Double?
            var notes: String?
        }

        let profile = fetchUserProfile()
        let progressEntries = fetchAllProgressEntries()

        let exportData = ExportData(
            exportDate: Date(),
            profile: profile.map { p in
                UserProfileExport(
                    age: p.age,
                    biologicalSex: p.biologicalSex.rawValue,
                    heightCm: p.heightCm,
                    weightKg: p.weightKg,
                    healthConditions: p.healthConditions.map { $0.rawValue },
                    healthGoals: p.healthGoals.map { $0.rawValue },
                    createdAt: p.createdAt
                )
            },
            progressEntries: progressEntries.map { e in
                ProgressEntryExport(
                    date: e.date,
                    weight: e.weight,
                    notes: e.notes
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }
}
