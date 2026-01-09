//
//  DashboardView.swift
//  HealthOptimizer
//
//  Main dashboard showing overview and quick actions
//

import SwiftData
import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {

  // MARK: - Properties

  @Bindable var viewModel: DashboardViewModel
  @State private var showAPIKeySheet = false

  // MARK: - Body

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // Greeting
          greetingSection

          // Quick Stats
          if viewModel.userProfile != nil {
            quickStatsSection
          }

          // AI Configuration Check
          if !viewModel.isAIConfigured {
            apiKeyWarning
          }

          // Recommendation Status
          if viewModel.isGeneratingRecommendations {
            generatingView
          } else if let recommendation = viewModel.currentRecommendation,
            recommendation.status == .completed
          {
            recommendationSummary(recommendation)
          } else {
            noRecommendationsView
          }

          Spacer()
            .frame(height: 100)
        }
        .padding(.top)
      }
      .navigationTitle("Dashboard")
      .refreshable {
        viewModel.loadData()
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { showAPIKeySheet = true }) {
            Image(systemName: "gearshape.fill")
          }
        }
      }
      .sheet(isPresented: $showAPIKeySheet) {
        APIKeySettingsSheet()
      }
      .alert("Error", isPresented: $viewModel.showingError) {
        Button("OK", role: .cancel) {
          viewModel.dismissError()
        }
      } message: {
        if let error = viewModel.error {
          Text(error.localizedDescription)
        }
      }
    }
  }

  // MARK: - Greeting Section

  private var greetingSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(greetingText)
        .font(.title)
        .fontWeight(.bold)

      if let name = viewModel.userProfile?.displayName, !name.isEmpty {
        Text("Welcome back, \(name)!")
          .font(.subheadline)
          .foregroundColor(.secondary)
      } else {
        Text("Your personalized health journey")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal)
  }

  private var greetingText: String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 0..<12: return "Good Morning"
    case 12..<17: return "Good Afternoon"
    default: return "Good Evening"
    }
  }

  // MARK: - Quick Stats Section

  private var quickStatsSection: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
      ForEach(viewModel.quickStats) { stat in
        QuickStatCard(stat: stat)
      }
    }
    .padding(.horizontal)
  }

  // MARK: - API Key Warning

  @EnvironmentObject private var aiSettings: AISettings

  private var apiKeyWarning: some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "key.fill")
          .foregroundColor(.orange)
        Text("AI Provider Not Configured")
          .font(.headline)
      }

      Text(
        "Configure \(aiSettings.selectedProvider.rawValue) to generate personalized recommendations."
      )
      .font(.subheadline)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)

      Text(aiSettings.selectedProvider.setupInstructions)
        .font(.caption)
        .foregroundColor(.secondary)

      Button(action: { showAPIKeySheet = true }) {
        Text("Configure AI Provider")
          .font(.subheadline)
          .fontWeight(.semibold)
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
    }
    .padding()
    .background(Color.orange.opacity(0.1))
    .cornerRadius(12)
    .padding(.horizontal)
  }

  // MARK: - Generating View

  private var generatingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Generating Your Recommendations")
        .font(.headline)

      Text(viewModel.generationProgress)
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text("This may take a minute...")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(40)
    .frame(maxWidth: .infinity)
    .background(Color(.systemGray6))
    .cornerRadius(16)
    .padding(.horizontal)
  }

  // MARK: - No Recommendations View

  private var noRecommendationsView: some View {
    VStack(spacing: 20) {
      Image(systemName: "sparkles")
        .font(.system(size: 50))
        .foregroundColor(.accentColor)

      Text("Ready for Your Plan?")
        .font(.headline)

      Text("Generate personalized supplement, workout, and diet recommendations powered by AI.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button(action: generateRecommendations) {
        HStack {
          Image(systemName: "wand.and.stars")
          Text("Generate Recommendations")
        }
        .font(.headline)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(12)
      }
      .disabled(!viewModel.isAIConfigured)
    }
    .padding(30)
    .frame(maxWidth: .infinity)
    .background(Color(.systemGray6))
    .cornerRadius(16)
    .padding(.horizontal)
  }

  // MARK: - Recommendation Summary

  private func recommendationSummary(_ recommendation: HealthRecommendation) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header
      HStack {
        VStack(alignment: .leading) {
          Text("Your Health Plan")
            .font(.headline)
          if let age = viewModel.recommendationAge {
            Text("Generated \(age)")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        Button(action: generateRecommendations) {
          Label("Refresh", systemImage: "arrow.clockwise")
            .font(.caption)
        }
        .disabled(!viewModel.isAIConfigured)
      }

      // Summary
      Text(recommendation.healthSummary)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .lineLimit(4)

      // Key Insights
      if !recommendation.keyInsights.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Key Insights")
            .font(.subheadline)
            .fontWeight(.semibold)

          ForEach(recommendation.keyInsights.prefix(3), id: \.self) { insight in
            HStack(alignment: .top, spacing: 8) {
              Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
              Text(insight)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }
      }

      // Priority Actions
      if !recommendation.priorityActions.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Priority Actions")
            .font(.subheadline)
            .fontWeight(.semibold)

          ForEach(recommendation.priorityActions.prefix(3), id: \.self) { action in
            HStack(alignment: .top, spacing: 8) {
              Image(systemName: "arrow.right.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
              Text(action)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }
      }

      // Quick summary of plans
      HStack(spacing: 12) {
        PlanSummaryCard(
          title: "Supplements",
          count: recommendation.supplementPlan?.supplements.count ?? 0,
          icon: "pills.fill",
          color: .green
        )

        PlanSummaryCard(
          title: "Workouts",
          count: recommendation.workoutPlan?.daysPerWeek ?? 0,
          icon: "dumbbell.fill",
          color: .orange,
          suffix: "days/wk"
        )

        PlanSummaryCard(
          title: "Calories",
          count: recommendation.dietPlan?.dailyCalories ?? 0,
          icon: "flame.fill",
          color: .red,
          suffix: "kcal"
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    .padding(.horizontal)
  }

  // MARK: - Methods

  private func generateRecommendations() {
    Task {
      await viewModel.generateRecommendations()
    }
  }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
  let stat: QuickStat

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: stat.icon)
          .foregroundColor(stat.color)
        Spacer()
      }

      Text(stat.value)
        .font(.title2)
        .fontWeight(.bold)

      Text(stat.subtitle)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
  }
}

// MARK: - Plan Summary Card

struct PlanSummaryCard: View {
  let title: String
  let count: Int
  let icon: String
  let color: Color
  var suffix: String = ""

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .foregroundColor(color)

      Text("\(count)")
        .font(.headline)

      if !suffix.isEmpty {
        Text(suffix)
          .font(.caption2)
          .foregroundColor(.secondary)
      } else {
        Text(title)
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(color.opacity(0.1))
    .cornerRadius(8)
  }
}

// MARK: - API Key Settings Sheet

struct APIKeySettingsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var aiSettings: AISettings

  // API Keys for each provider
  @State private var claudeAPIKey = ""
  @State private var openAIAPIKey = ""
  @State private var showClaudeKey = false
  @State private var showOpenAIKey = false
  @State private var saveSuccess: AIProvider? = nil

  private let keychainService = KeychainService.shared

  var body: some View {
    NavigationStack {
      Form {
        // Provider Selection
        Section {
          Picker("AI Provider", selection: $aiSettings.selectedProvider) {
            ForEach(AIProvider.allCases) { provider in
              HStack {
                Image(systemName: provider.icon)
                Text(provider.rawValue)
              }
              .tag(provider)
            }
          }

          // Model Selection
          Picker("Model", selection: $aiSettings.selectedModel) {
            ForEach(aiSettings.selectedProvider.availableModels, id: \.self) { model in
              Text(model).tag(model)
            }
          }
        } header: {
          Text("AI Provider")
        } footer: {
          Text(aiSettings.selectedProvider.description)
        }

        // Claude Configuration
        Section {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: AIProvider.claude.icon)
                .foregroundColor(.purple)
              Text("Claude (Anthropic)")
                .font(.headline)
              Spacer()
              if keychainService.hasAPIKey(for: .claude) {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.green)
              }
            }
          }

          HStack {
            if showClaudeKey {
              TextField("sk-ant-...", text: $claudeAPIKey)
                .textContentType(.password)
                .autocorrectionDisabled()
            } else {
              SecureField("sk-ant-...", text: $claudeAPIKey)
                .textContentType(.password)
            }

            Button(action: { showClaudeKey.toggle() }) {
              Image(systemName: showClaudeKey ? "eye.slash" : "eye")
                .foregroundColor(.secondary)
            }
          }

          HStack {
            Button(action: { saveAPIKey(for: .claude, key: claudeAPIKey) }) {
              Text("Save")
            }
            .disabled(claudeAPIKey.isEmpty)

            if saveSuccess == .claude {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            }

            Spacer()

            if keychainService.hasAPIKey(for: .claude) {
              Button(role: .destructive, action: { deleteAPIKey(for: .claude) }) {
                Text("Remove")
              }
            }
          }
        } header: {
          Text("Claude API Key")
        } footer: {
          Text("Get your API key from console.anthropic.com")
        }

        // OpenAI Configuration
        Section {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: AIProvider.openAI.icon)
                .foregroundColor(.green)
              Text("GPT (OpenAI)")
                .font(.headline)
              Spacer()
              if keychainService.hasAPIKey(for: .openAI) {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.green)
              }
            }
          }

          HStack {
            if showOpenAIKey {
              TextField("sk-...", text: $openAIAPIKey)
                .textContentType(.password)
                .autocorrectionDisabled()
            } else {
              SecureField("sk-...", text: $openAIAPIKey)
                .textContentType(.password)
            }

            Button(action: { showOpenAIKey.toggle() }) {
              Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                .foregroundColor(.secondary)
            }
          }

          HStack {
            Button(action: { saveAPIKey(for: .openAI, key: openAIAPIKey) }) {
              Text("Save")
            }
            .disabled(openAIAPIKey.isEmpty)

            if saveSuccess == .openAI {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            }

            Spacer()

            if keychainService.hasAPIKey(for: .openAI) {
              Button(role: .destructive, action: { deleteAPIKey(for: .openAI) }) {
                Text("Remove")
              }
            }
          }
        } header: {
          Text("OpenAI API Key")
        } footer: {
          Text("Get your API key from platform.openai.com")
        }

        // Gemini/Firebase Configuration
        Section {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: AIProvider.gemini.icon)
                .foregroundColor(.blue)
              Text("Gemini (Google/Firebase)")
                .font(.headline)
              Spacer()
              if GeminiAIService.isFirebaseConfigured {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.green)
              } else {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.red)
              }
            }
          }

          if GeminiAIService.isFirebaseConfigured {
            Text("Firebase is configured and ready to use.")
              .font(.caption)
              .foregroundColor(.green)
          } else {
            Text("Add GoogleService-Info.plist to your Xcode project to enable Gemini.")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        } header: {
          Text("Gemini Configuration")
        } footer: {
          Text(
            "Gemini uses Firebase AI Logic. Configure your Firebase project at console.firebase.google.com"
          )
        }

        // Status Summary
        Section {
          HStack {
            Text("Available Providers")
            Spacer()
            Text("\(AIServiceFactory.availableProviders().count)")
              .foregroundColor(.secondary)
          }

          ForEach(AIProvider.allCases) { provider in
            HStack {
              Image(systemName: provider.icon)
                .foregroundColor(isProviderConfigured(provider) ? .green : .gray)
              Text(provider.rawValue)
              Spacer()
              if isProviderConfigured(provider) {
                Text("Ready")
                  .font(.caption)
                  .foregroundColor(.green)
              } else {
                Text("Not Configured")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
        } header: {
          Text("Status")
        }
      }
      .navigationTitle("AI Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
      .onAppear {
        loadExistingKeys()
      }
      .onChange(of: aiSettings.selectedProvider) { _, newProvider in
        // Update model to provider's default if current model isn't available
        if !newProvider.availableModels.contains(aiSettings.selectedModel) {
          aiSettings.selectedModel = newProvider.defaultModel
        }
      }
    }
  }

  private func loadExistingKeys() {
    if let key = keychainService.getAPIKey(for: .claude) {
      claudeAPIKey = key
    }
    if let key = keychainService.getAPIKey(for: .openAI) {
      openAIAPIKey = key
    }
  }

  private func saveAPIKey(for provider: AIProvider, key: String) {
    if keychainService.saveAPIKey(key, for: provider) {
      saveSuccess = provider
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        saveSuccess = nil
      }
    }
  }

  private func deleteAPIKey(for provider: AIProvider) {
    keychainService.deleteAPIKey(for: provider)
    switch provider {
    case .claude:
      claudeAPIKey = ""
    case .openAI:
      openAIAPIKey = ""
    case .gemini:
      break  // Gemini doesn't use API key
    }
  }

  private func isProviderConfigured(_ provider: AIProvider) -> Bool {
    switch provider {
    case .claude:
      return keychainService.hasAPIKey(for: .claude)
    case .openAI:
      return keychainService.hasAPIKey(for: .openAI)
    case .gemini:
      return GeminiAIService.isFirebaseConfigured
    }
  }
}

// MARK: - Preview

private struct DashboardPreview: View {
  @State private var viewModel = DashboardViewModel(
    aiService: MockAIService(),
    persistenceService: .shared
  )

  var body: some View {
    DashboardView(viewModel: viewModel)
      .modelContainer(for: UserProfile.self, inMemory: true)
      .environmentObject(AISettings.shared)
      .onAppear {
        viewModel.userProfile = UserProfile(
          displayName: "John",
          age: 35,
          biologicalSex: .male,
          heightCm: 180,
          weightKg: 85,
          fitnessLevel: .intermediate,
          weeklyActivityDays: 3,
          averageSleepHours: 6.5
        )
      }
  }
}

#Preview {
  DashboardPreview()
}
