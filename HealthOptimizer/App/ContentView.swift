//
//  ContentView.swift
//  HealthOptimizer
//
//  Root view that determines navigation flow based on app state
//

import SwiftUI
import SwiftData

/// Root content view that manages the main navigation flow
/// Shows onboarding for new users or main app for returning users
struct ContentView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    /// Query to check if a user profile exists
    @Query private var userProfiles: [UserProfile]

    // MARK: - State

    /// Tracks if onboarding has been completed this session
    @State private var hasCompletedOnboarding = false

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
            if shouldShowOnboarding {
                OnboardingContainerView(onComplete: handleOnboardingComplete)
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: shouldShowOnboarding)
    }

    // MARK: - Methods

    /// Handles completion of onboarding flow
    /// - Parameter profile: The newly created user profile
    private func handleOnboardingComplete(profile: UserProfile) {
        // Insert the new profile into SwiftData
        modelContext.insert(profile)

        // Try to save immediately
        do {
            try modelContext.save()
            hasCompletedOnboarding = true
        } catch {
            print("Error saving profile: \(error)")
            // In production, show an error alert
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
