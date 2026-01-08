//
//  HealthOptimizerApp.swift
//  HealthOptimizer
//
//  AI-Powered Health Optimization App
//  Main application entry point
//

import SwiftUI
import SwiftData

/// Main application entry point
/// Configures SwiftData container and determines initial view based on onboarding status
@main
struct HealthOptimizerApp: App {

    // MARK: - SwiftData Configuration

    /// Shared model container for persistence
    /// Includes all model types that need to be persisted
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            HealthRecommendation.self,
            ProgressEntry.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,  // Persist to disk
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // In production, handle this more gracefully
            // Consider showing an error screen or attempting recovery
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}

// MARK: - App Configuration

/// Global app configuration constants
enum AppConfig {
    static let appName = "HealthOptimizer"
    static let version = "1.0.0"

    /// Minimum iOS version requirement
    static let minimumIOSVersion = 17.0

    /// API Configuration
    enum API {
        static let claudeBaseURL = "https://api.anthropic.com/v1"
        static let claudeModel = "claude-sonnet-4-20250514"
        static let maxTokens = 4096
    }

    /// Privacy and compliance
    enum Privacy {
        static let dataRetentionDays = 365
        static let requiresBiometricAuth = false
    }
}
