//
//  DashboardView.swift
//  HealthOptimizer
//
//  Main dashboard showing overview and quick actions
//

import SwiftUI
import SwiftData

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
                              recommendation.status == .completed {
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
    
    private var apiKeyWarning: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.orange)
                Text("API Key Required")
                    .font(.headline)
            }
            
            Text("To generate personalized recommendations, please add your Anthropic API key.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showAPIKeySheet = true }) {
                Text("Add API Key")
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
    @State private var apiKey = ""
    @State private var showKey = false
    @State private var saveSuccess = false
    
    private let keychainService = KeychainService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anthropic API Key")
                            .font(.headline)
                        
                        Text("Your API key is stored securely in the device keychain and never sent to any server except Anthropic.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        if showKey {
                            TextField("sk-ant-...", text: $apiKey)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("sk-ant-...", text: $apiKey)
                                .textContentType(.password)
                        }
                        
                        Button(action: { showKey.toggle() }) {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Get your API key from console.anthropic.com")
                }
                
                Section {
                    Button(action: saveAPIKey) {
                        HStack {
                            Text("Save API Key")
                            Spacer()
                            if saveSuccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(apiKey.isEmpty)
                    
                    if keychainService.hasAPIKey(for: .claude) {
                        Button(role: .destructive, action: deleteAPIKey) {
                            Text("Remove API Key")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if let existingKey = keychainService.getAPIKey(for: .claude) {
                    apiKey = existingKey
                }
            }
        }
    }
    
    private func saveAPIKey() {
        if keychainService.saveAPIKey(apiKey, for: .claude) {
            saveSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                saveSuccess = false
            }
        }
    }
    
    private func deleteAPIKey() {
        keychainService.deleteAPIKey(for: .claude)
        apiKey = ""
    }
}

// MARK: - Preview

#Preview {
    DashboardView(viewModel: DashboardViewModel.preview)
        .modelContainer(for: UserProfile.self, inMemory: true)
}
