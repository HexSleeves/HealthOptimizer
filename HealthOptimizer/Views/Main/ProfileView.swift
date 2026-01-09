//
//  ProfileView.swift
//  HealthOptimizer
//
//  User profile and settings view
//

import SwiftData
import SwiftUI

// MARK: - Profile View

struct ProfileView: View {

  @Environment(\.modelContext) private var modelContext
  @Query private var userProfiles: [UserProfile]

  @State private var authService = AuthService.shared
  @State private var syncService = SyncService.shared

  @State private var showAPISettings = false
  @State private var showDeleteConfirmation = false
  @State private var showSignOutConfirmation = false
  @State private var showDeleteAccountConfirmation = false
  @State private var showExportSheet = false
  @State private var exportData: Data?
  @State private var clearDataOnSignOut = false

  private var profile: UserProfile? {
    userProfiles.first
  }

  var body: some View {
    NavigationStack {
      List {
        // Account Section
        Section {
          if let user = authService.currentUser {
            HStack(spacing: 16) {
              // Avatar
              ZStack {
                Circle()
                  .fill(
                    LinearGradient(
                      colors: [.blue, .purple],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    )
                  )
                  .frame(width: 60, height: 60)

                Text(profile?.displayName?.prefix(1).uppercased() ?? user.email?.prefix(1).uppercased() ?? "U")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(.white)
              }

              VStack(alignment: .leading, spacing: 4) {
                Text(profile?.displayName ?? "Health Optimizer User")
                  .font(.headline)

                if let email = user.email {
                  Text(email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                if let createdAt = profile?.createdAt {
                  Text("Member since \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
              }
            }
            .padding(.vertical, 8)
          }
        }

        if let profile = profile {
          // Health Stats
          Section("Health Statistics") {
            StatRow(label: "Age", value: "\(profile.age) years")
            StatRow(label: "Height", value: String(format: "%.0f cm", profile.heightCm))
            StatRow(label: "Weight", value: String(format: "%.1f kg", profile.weightKg))
            StatRow(
              label: "BMI",
              value: String(format: "%.1f (%@)", profile.bmi, profile.bmiCategory.rawValue))
            StatRow(label: "BMR", value: "\(Int(profile.estimatedBMR)) cal/day")
            StatRow(label: "TDEE", value: "\(Int(profile.estimatedTDEE)) cal/day")
          }

          // Goals
          Section("Your Goals") {
            if profile.healthGoals.isEmpty {
              Text("No goals set")
                .foregroundColor(.secondary)
            } else {
              ForEach(profile.healthGoals.prefix(5), id: \.rawValue) { goal in
                Label(goal.rawValue, systemImage: goal.icon)
              }
              if profile.healthGoals.count > 5 {
                Text("+\(profile.healthGoals.count - 5) more")
                  .foregroundColor(.secondary)
              }
            }
          }

          // Conditions
          if !profile.healthConditions.isEmpty && profile.healthConditions != [.none] {
            Section("Health Conditions") {
              ForEach(profile.healthConditions.filter { $0 != .none }, id: \.rawValue) {
                condition in
                Text(condition.rawValue)
              }
            }
          }
        }

        // Sync Status
        Section("Sync") {
          HStack {
            Label("Cloud Sync", systemImage: "icloud.fill")
            Spacer()
            if syncService.isSyncing {
              ProgressView()
            } else if let lastSync = syncService.lastSyncDate {
              Text("Last: \(lastSync.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
              Text("Not synced")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          Button(action: {
            Task {
              await syncService.performFullSync()
            }
          }) {
            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
          }
          .disabled(syncService.isSyncing)
        }

        // Settings
        Section("Settings") {
          Button(action: { showAPISettings = true }) {
            Label("AI Configuration", systemImage: "key.fill")
          }

          NavigationLink {
            PrivacyInfoView()
          } label: {
            Label("Privacy & Data", systemImage: "lock.shield.fill")
          }
        }

        // Data Management
        Section("Data Management") {
          Button(action: exportUserData) {
            Label("Export My Data", systemImage: "square.and.arrow.up")
          }

          Button(role: .destructive, action: { showDeleteConfirmation = true }) {
            Label("Delete All Data", systemImage: "trash")
          }
        }

        // Account
        Section("Account") {
          Button(action: { showSignOutConfirmation = true }) {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
          }

          Button(role: .destructive, action: { showDeleteAccountConfirmation = true }) {
            Label("Delete Account", systemImage: "person.crop.circle.badge.xmark")
          }
        }

        // About
        Section("About") {
          HStack {
            Text("Version")
            Spacer()
            Text(AppConfig.version)
              .foregroundColor(.secondary)
          }
        }
      }
      .navigationTitle("Profile")
      .sheet(isPresented: $showAPISettings) {
        APIKeySettingsSheet()
      }
      .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          deleteAllData()
        }
      } message: {
        Text(
          "This will permanently delete your profile and all recommendations. This cannot be undone."
        )
      }
      .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
        Button("Sign Out (Keep Data)") {
          signOut(clearData: false)
        }
        Button("Sign Out & Clear Data", role: .destructive) {
          signOut(clearData: true)
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Your data is saved in the cloud and will sync when you sign back in.")
      }
      .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
        Button("Cancel", role: .cancel) {}
        Button("Delete Account", role: .destructive) {
          deleteAccount()
        }
      } message: {
        Text(
          "This will permanently delete your account and all data from both your device and the cloud. This cannot be undone."
        )
      }
      .sheet(isPresented: $showExportSheet) {
        if let data = exportData {
          ShareSheet(data: data)
        }
      }
    }
  }

  // MARK: - Methods

  private func exportUserData() {
    Task { @MainActor in
      do {
        exportData = try PersistenceService.shared.exportUserData()
        showExportSheet = true
      } catch {
        print("Export error: \(error)")
      }
    }
  }

  private func deleteAllData() {
    Task { @MainActor in
      do {
        try PersistenceService.shared.deleteAllData()
        try await FirestoreService.shared.deleteAllUserData()
        KeychainService.shared.deleteAPIKey(for: .claude)
      } catch {
        print("Delete error: \(error)")
      }
    }
  }

  private func signOut(clearData: Bool) {
    syncService.handleSignOut(clearLocalData: clearData)
    try? authService.signOut()
  }

  private func deleteAccount() {
    Task {
      do {
        try await syncService.handleAccountDeletion()
      } catch {
        print("Delete account error: \(error)")
      }
    }
  }
}

// MARK: - Stat Row

struct StatRow: View {
  let label: String
  let value: String

  var body: some View {
    HStack {
      Text(label)
      Spacer()
      Text(value)
        .foregroundColor(.secondary)
    }
  }
}

// MARK: - Privacy Info View

struct PrivacyInfoView: View {
  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 12) {
          Label("Your Privacy Matters", systemImage: "lock.shield.fill")
            .font(.headline)

          Text("HealthOptimizer is designed with your privacy as a top priority.")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
      }

      Section("Data Storage") {
        PrivacyRow(
          icon: "iphone",
          title: "Local Storage",
          description:
            "Your health data is stored locally on your device using encrypted storage."
        )

        PrivacyRow(
          icon: "icloud.fill",
          title: "Cloud Sync",
          description: "Data syncs to Firebase when signed in, enabling multi-device access and backup."
        )
      }

      Section("AI Processing") {
        PrivacyRow(
          icon: "brain",
          title: "Anonymized Requests",
          description:
            "When generating recommendations, only health metrics are sent - never your name or identifying information."
        )

        PrivacyRow(
          icon: "key",
          title: "Your API Key",
          description:
            "Your API key is stored in the secure iOS Keychain and used only for AI requests."
        )
      }

      Section("Your Rights") {
        PrivacyRow(
          icon: "square.and.arrow.up",
          title: "Data Export",
          description: "Export all your data at any time in a readable format."
        )

        PrivacyRow(
          icon: "trash",
          title: "Data Deletion",
          description: "Permanently delete all your data from device and cloud whenever you choose."
        )
      }

      Section {
        Text(
          "HIPAA Notice: This app is designed with HIPAA-awareness in mind, but is not a covered entity. For medical decisions, always consult healthcare professionals."
        )
        .font(.caption)
        .foregroundColor(.secondary)
      }
    }
    .navigationTitle("Privacy & Data")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Privacy Row

struct PrivacyRow: View {
  let icon: String
  let title: String
  let description: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon)
        .foregroundColor(.accentColor)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)
        Text(description)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
  let data: Data

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
      "health_data_export.json")
    try? data.write(to: tempURL)
    return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
  ProfileView()
    .modelContainer(for: UserProfile.self, inMemory: true)
}
