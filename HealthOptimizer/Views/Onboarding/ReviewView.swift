//
//  ReviewView.swift
//  HealthOptimizer
//
//  Final review view before completing onboarding
//

import SwiftUI

// MARK: - Review View

struct ReviewView: View {
    
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Review Your Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Make sure everything looks correct before we generate your personalized recommendations.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Basic Info Summary
                ReviewSection(title: "Basic Information", icon: "person.fill") {
                    if !viewModel.displayName.isEmpty {
                        ReviewRow(label: "Name", value: viewModel.displayName)
                    }
                    ReviewRow(label: "Age", value: "\(viewModel.age) years")
                    ReviewRow(label: "Sex", value: viewModel.biologicalSex.rawValue)
                    ReviewRow(label: "Height", value: String(format: "%.0f cm", viewModel.heightCm))
                    ReviewRow(label: "Weight", value: String(format: "%.1f kg", viewModel.weightKg))
                    ReviewRow(
                        label: "BMI",
                        value: String(format: "%.1f (%@)", viewModel.calculatedBMI, viewModel.bmiCategory.rawValue)
                    )
                }
                
                // Health Conditions
                ReviewSection(title: "Health Conditions", icon: "heart.text.square.fill") {
                    if viewModel.selectedConditions.isEmpty || viewModel.selectedConditions == [.none] {
                        ReviewRow(label: "Conditions", value: "None reported")
                    } else {
                        let conditions = viewModel.selectedConditions
                            .filter { $0 != .none }
                            .map { $0.rawValue }
                            .joined(separator: ", ")
                        ReviewRow(label: "Conditions", value: conditions)
                    }
                    
                    if !viewModel.allergies.isEmpty {
                        ReviewRow(label: "Allergies", value: viewModel.allergies.joined(separator: ", "))
                    }
                }
                
                // Medications & Supplements
                ReviewSection(title: "Medications & Supplements", icon: "pills.fill") {
                    ReviewRow(
                        label: "Medications",
                        value: viewModel.currentMedications.isEmpty ? 
                               "None" : "\(viewModel.currentMedications.count) medication(s)"
                    )
                    ReviewRow(
                        label: "Supplements",
                        value: viewModel.currentSupplements.isEmpty ? 
                               "None" : "\(viewModel.currentSupplements.count) supplement(s)"
                    )
                }
                
                // Fitness Profile
                ReviewSection(title: "Fitness Profile", icon: "figure.run") {
                    ReviewRow(label: "Fitness Level", value: viewModel.fitnessLevel.rawValue)
                    ReviewRow(label: "Weekly Activity", value: "\(viewModel.weeklyActivityDays) days/week")
                    ReviewRow(label: "Gym Access", value: viewModel.hasGymAccess ? "Yes" : "No")
                    ReviewRow(label: "Workout Time", value: "\(viewModel.availableWorkoutMinutes) min/session")
                    if !viewModel.selectedActivities.isEmpty {
                        let activities = viewModel.selectedActivities.map { $0.rawValue }.joined(separator: ", ")
                        ReviewRow(label: "Activities", value: activities)
                    }
                }
                
                // Diet Preferences
                ReviewSection(title: "Dietary Preferences", icon: "fork.knife") {
                    ReviewRow(label: "Diet Type", value: viewModel.dietType.rawValue)
                    ReviewRow(label: "Meals/Day", value: "\(viewModel.mealsPerDay)")
                    ReviewRow(label: "Cooking Skill", value: viewModel.cookingSkillLevel.rawValue)
                    if !viewModel.foodIntolerances.isEmpty {
                        ReviewRow(label: "Intolerances", value: viewModel.foodIntolerances.joined(separator: ", "))
                    }
                }
                
                // Lifestyle
                ReviewSection(title: "Lifestyle", icon: "moon.stars.fill") {
                    ReviewRow(label: "Sleep", value: String(format: "%.1f hrs/night", viewModel.averageSleepHours))
                    ReviewRow(label: "Sleep Quality", value: viewModel.sleepQuality.rawValue)
                    ReviewRow(label: "Stress Level", value: viewModel.stressLevel.rawValue)
                    ReviewRow(label: "Water Intake", value: String(format: "%.1fL/day", viewModel.dailyWaterIntakeLiters))
                }
                
                // Goals
                ReviewSection(title: "Health Goals", icon: "target") {
                    if viewModel.selectedGoals.isEmpty {
                        ReviewRow(label: "Goals", value: "None selected")
                    } else {
                        let goals = viewModel.selectedGoals.map { $0.rawValue }.joined(separator: ", ")
                        ReviewRow(label: "Goals", value: goals)
                    }
                    ReviewRow(label: "Timeline", value: "\(viewModel.goalTimelineWeeks) weeks")
                }
                
                // Privacy Notice
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Privacy Protected")
                            .font(.headline)
                    }
                    
                    Text("Your health data is stored securely on your device. When generating recommendations, only anonymized health metrics are sent to the AI service - never your personal information.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Edit buttons
                VStack(spacing: 8) {
                    Text("Need to make changes?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: { viewModel.goToStep(.basicInfo) }) {
                        Text("Edit Profile")
                            .font(.subheadline)
                    }
                }
                .padding(.top)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
}

// MARK: - Review Section

struct ReviewSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Review Row

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = OnboardingViewModel()
    viewModel.displayName = "John"
    viewModel.age = 35
    viewModel.heightCm = 180
    viewModel.weightKg = 85
    viewModel.selectedGoals = [.loseWeight, .buildMuscle]
    viewModel.fitnessLevel = .intermediate
    return ReviewView(viewModel: viewModel)
}
