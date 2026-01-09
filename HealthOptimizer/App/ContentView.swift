//
//  ContentView.swift
//  HealthOptimizer
//
//  Root view that determines navigation flow based on app state
//

import SwiftData
import SwiftUI

/// Root content view that manages the main navigation flow
/// Shows auth for unauthenticated users, onboarding for new users, or main app for returning users
struct ContentView: View {

  // MARK: - Environment

  @Environment(\.modelContext) private var modelContext

  // MARK: - State

  @State private var authService = AuthService.shared
  @State private var syncService = SyncService.shared

  // MARK: - Queries

  /// Query to check if a user profile exists
  @Query private var userProfiles: [UserProfile]

  // MARK: - State

  /// Tracks if onboarding has been completed this session
  @State private var hasCompletedOnboarding = false

  /// Tracks if initial sync has been performed
  @State private var hasPerformedInitialSync = false

  /// Current user profile (if exists)
  private var currentProfile: UserProfile? {
    userProfiles.first
  }

  /// Determines if user should see onboarding
  private var shouldShowOnboarding: Bool {
    currentProfile == nil && !hasCompletedOnboarding
  }

  // MARK: - Body

  var body: some View {
    Group {
      if !authService.isSignedIn {
        // Not signed in - show auth
        AuthView()
          .transition(.opacity)
      } else if syncService.isSyncing && !hasPerformedInitialSync {
        // Syncing data from cloud
        SyncingView()
          .transition(.opacity)
      } else if shouldShowOnboarding {
        // Signed in but no profile - show onboarding
        OnboardingContainerView(onComplete: handleOnboardingComplete)
          .transition(.opacity)
      } else {
        // Signed in with profile - show main app
        MainTabView()
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: authService.isSignedIn)
    .animation(.easeInOut(duration: 0.3), value: shouldShowOnboarding)
    .onChange(of: authService.isSignedIn) { _, isSignedIn in
      if isSignedIn {
        performInitialSync()
      } else {
        hasPerformedInitialSync = false
        hasCompletedOnboarding = false
      }
    }
    .onAppear {
      if authService.isSignedIn && !hasPerformedInitialSync {
        performInitialSync()
      }
    }
  }

  // MARK: - Methods

  /// Perform initial sync when user signs in
  private func performInitialSync() {
    Task {
      await syncService.performFullSync()
      hasPerformedInitialSync = true
    }
  }

  /// Handles completion of onboarding flow
  /// - Parameter profile: The newly created user profile
  private func handleOnboardingComplete(profile: UserProfile) {
    // Insert the new profile into SwiftData
    modelContext.insert(profile)

    // Try to save immediately
    do {
      try modelContext.save()
      hasCompletedOnboarding = true

      // Sync to cloud
      Task {
        await syncService.syncProfile(profile)
      }
    } catch {
      print("Error saving profile: \(error)")
    }
  }
}

// MARK: - Syncing View

struct SyncingView: View {
  var body: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Syncing your data...")
        .font(.headline)

      Text("This will only take a moment")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
  }
}

// MARK: - Preview

#Preview {
  ContentView()
    .modelContainer(for: UserProfile.self, inMemory: true)
    .environmentObject(AISettings.shared)
}
