//
//  OnboardingContainerView.swift
//  HealthOptimizer
//
//  Container view managing the multi-step onboarding flow
//

import SwiftUI

// MARK: - Onboarding Container View

/// Main container for the onboarding flow
struct OnboardingContainerView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = OnboardingViewModel()
    let onComplete: (UserProfile) -> Void
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator (hidden on welcome)
                if viewModel.currentStep != .welcome {
                    ProgressHeader(viewModel: viewModel)
                }
                
                // Main content
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(viewModel.currentStep)
                
                Spacer()
                
                // Navigation buttons
                NavigationButtons(viewModel: viewModel, onComplete: handleComplete)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .alert("Validation Error", isPresented: $viewModel.showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.validationErrorMessage)
            }
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeView()
        case .basicInfo:
            BasicInfoView(viewModel: viewModel)
        case .healthConditions:
            HealthConditionsView(viewModel: viewModel)
        case .medications:
            MedicationsView(viewModel: viewModel)
        case .fitness:
            FitnessAssessmentView(viewModel: viewModel)
        case .diet:
            DietPreferencesView(viewModel: viewModel)
        case .lifestyle:
            LifestyleView(viewModel: viewModel)
        case .goals:
            GoalsView(viewModel: viewModel)
        case .review:
            ReviewView(viewModel: viewModel)
        }
    }
    
    // MARK: - Methods
    
    private func handleComplete() {
        let profile = viewModel.createProfile()
        onComplete(profile)
    }
}

// MARK: - Progress Header

/// Header showing onboarding progress
struct ProgressHeader: View {
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * viewModel.progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 4)
            
            // Step indicator
            HStack {
                Image(systemName: viewModel.currentStep.icon)
                    .foregroundColor(.accentColor)
                Text(viewModel.currentStep.title)
                    .font(.headline)
                Spacer()
                Text("Step \(viewModel.currentStep.rawValue) of \(OnboardingStep.allCases.count - 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - Navigation Buttons

/// Bottom navigation buttons for onboarding
struct NavigationButtons: View {
    let viewModel: OnboardingViewModel
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Back button
            if viewModel.canGoBack {
                Button(action: viewModel.previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            
            // Next/Complete button
            Button(action: {
                if viewModel.currentStep == .review {
                    onComplete()
                } else {
                    viewModel.nextStep()
                }
            }) {
                HStack {
                    Text(viewModel.currentStep == .review ? "Get Started" : 
                         viewModel.currentStep == .welcome ? "Begin" : "Continue")
                    Image(systemName: viewModel.currentStep == .review ? "checkmark" : "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canProceed ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canProceed)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView { profile in
        print("Profile created: \(profile.id)")
    }
}
