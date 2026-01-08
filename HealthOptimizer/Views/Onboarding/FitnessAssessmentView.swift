//
//  FitnessAssessmentView.swift
//  HealthOptimizer
//
//  View for assessing fitness level and exercise preferences
//

import SwiftUI

// MARK: - Fitness Assessment View

struct FitnessAssessmentView: View {
    
    @Bindable var viewModel: OnboardingViewModel
    @State private var newLimitation = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                SectionHeader(
                    title: "Fitness Profile",
                    subtitle: "Help us understand your current fitness level and exercise preferences to create the right workout plan."
                )
                
                // Fitness Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fitness Level")
                        .font(.headline)
                    
                    ForEach(FitnessLevel.allCases) { level in
                        FitnessLevelOption(
                            level: level,
                            isSelected: viewModel.fitnessLevel == level,
                            onSelect: { viewModel.fitnessLevel = level }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Weekly Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Activity")
                        .font(.headline)
                    Text("How many days per week are you currently active?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(0...7, id: \.self) { days in
                            Button(action: { viewModel.weeklyActivityDays = days }) {
                                Text("\(days)")
                                    .font(.headline)
                                    .frame(width: 36, height: 36)
                                    .background(viewModel.weeklyActivityDays == days ? 
                                                Color.accentColor : Color(.systemGray5))
                                    .foregroundColor(viewModel.weeklyActivityDays == days ? 
                                                     .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Current Activities
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Activities")
                        .font(.headline)
                    Text("What types of exercise do you currently do?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(ActivityType.allCases) { activity in
                            ActivityChip(
                                activity: activity,
                                isSelected: viewModel.selectedActivities.contains(activity),
                                onTap: { viewModel.toggleActivity(activity) }
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Gym Access
                Toggle(isOn: $viewModel.hasGymAccess) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gym Access")
                            .font(.headline)
                        Text("Do you have access to a gym or equipment?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Available Workout Time
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Available Workout Time")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.availableWorkoutMinutes) min")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                    
                    Text("How much time can you dedicate per workout session?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.availableWorkoutMinutes) },
                            set: { viewModel.availableWorkoutMinutes = Int($0) }
                        ),
                        in: 15...120,
                        step: 5
                    )
                    
                    HStack {
                        Text("15 min")
                        Spacer()
                        Text("120 min")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Physical Limitations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Physical Limitations")
                        .font(.headline)
                    Text("Any injuries or limitations we should know about?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("e.g., Bad knee, Lower back pain", text: $newLimitation)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                            .onSubmit(addLimitation)
                        
                        Button(action: addLimitation) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .disabled(newLimitation.isEmpty)
                    }
                    
                    if !viewModel.physicalLimitations.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.physicalLimitations, id: \.self) { limitation in
                                HStack(spacing: 4) {
                                    Text(limitation)
                                        .font(.subheadline)
                                    Button(action: { removeLimitation(limitation) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(16)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.top)
        }
    }
    
    private func addLimitation() {
        let trimmed = newLimitation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !viewModel.physicalLimitations.contains(trimmed) else { return }
        viewModel.physicalLimitations.append(trimmed)
        newLimitation = ""
    }
    
    private func removeLimitation(_ limitation: String) {
        viewModel.physicalLimitations.removeAll { $0 == limitation }
    }
}

// MARK: - Fitness Level Option

struct FitnessLevelOption: View {
    let level: FitnessLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Activity Chip

struct ActivityChip: View {
    let activity: ActivityType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: activity.icon)
                    .font(.caption)
                Text(activity.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    FitnessAssessmentView(viewModel: OnboardingViewModel())
}
