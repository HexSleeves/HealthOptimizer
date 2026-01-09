//
//  HealthOptimizerApp.swift
//  HealthOptimizer
//
//  AI-Powered Health Optimization App
//  Main application entry point
//

import FirebaseCore
import SwiftData
import SwiftUI

/// Main application entry point
/// Configures SwiftData container and determines initial view based on onboarding status
@main
struct HealthOptimizerApp: App {

  // MARK: - App Delegate

  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  // MARK: - SwiftData Configuration

  /// Shared model container for persistence
  /// Includes all model types that need to be persisted
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      UserProfile.self,
      HealthRecommendation.self,
      ProgressEntry.self,
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
        .environmentObject(AISettings.shared)
    }
  }
}

// MARK: - App Delegate

/// AppDelegate for Firebase configuration
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Configure Firebase if GoogleService-Info.plist exists
    if FirebaseConfiguration.hasGoogleServicePlist {
      FirebaseApp.configure()
      print("[HealthOptimizer] Firebase configured successfully")
    } else {
      print("[HealthOptimizer] Firebase not configured - GoogleService-Info.plist not found")
    }
    return true
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
    // Claude
    static let claudeBaseURL = "https://api.anthropic.com/v1"
    static let claudeModel = "claude-sonnet-4-20250514"
    static let maxTokens = 8192

    // OpenAI
    static let openAIModel = "gpt-4o"

    // Gemini
    static let geminiModel = "gemini-2.5-flash"
  }

  /// Privacy and compliance
  enum Privacy {
    static let dataRetentionDays = 365
    static let requiresBiometricAuth = false
  }
}
