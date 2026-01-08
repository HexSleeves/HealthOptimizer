//
//  GoalsView.swift
//  HealthOptimizer
//
//  View for selecting health goals and objectives
//

import SwiftUI

// MARK: - Goals View

struct GoalsView: View {
    
    @Bindable var viewModel: OnboardingViewModel
    @State private var expandedCategory: GoalCategory?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                SectionHeader(
                    title: "Your Health Goals",
                    subtitle: "What do you want to achieve? Select all that apply. This shapes your personalized recommendations."
                )
                
                // Selected goals summary
                if !viewModel.selectedGoals.isEmpty {
                    SelectedGoalsSummary(goals: Array(viewModel.selectedGoals))
                        .padding(.horizontal)
                }
                
                // Goal categories
                ForEach(GoalCategory.allCases) { category in
                    GoalCategorySection(
                        category: category,
                        selectedGoals: $viewModel.selectedGoals,
                        isExpanded: expandedCategory == category,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedCategory = expandedCategory == category ? nil : category
                            }
                        },
                        onToggle: viewModel.toggleGoal
                    )
                }
                
                // Goal Timeline
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal Timeline")
                        .font(.headline)
                    Text("How long do you want to work towards these goals?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(viewModel.goalTimelineWeeks) weeks")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                        
                        Spacer()
                        
                        Text(timelineDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.goalTimelineWeeks) },
                            set: { viewModel.goalTimelineWeeks = Int($0) }
                        ),
                        in: 4...52,
                        step: 4
                    )
                    
                    // Timeline markers
                    HStack {
                        ForEach([4, 12, 24, 36, 52], id: \.self) { weeks in
                            Text("\(weeks)w")
                                .font(.caption2)
                                .foregroundColor(viewModel.goalTimelineWeeks == weeks ? .accentColor : .secondary)
                            if weeks != 52 { Spacer() }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Additional Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Notes (Optional)")
                        .font(.headline)
                    Text("Anything else you'd like us to know?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $viewModel.additionalNotes)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
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
    
    private var timelineDescription: String {
        switch viewModel.goalTimelineWeeks {
        case 4...8: return "Short-term focus"
        case 9...16: return "Medium-term commitment"
        case 17...32: return "Long-term transformation"
        default: return "Year-long journey"
        }
    }
}

// MARK: - Selected Goals Summary

struct SelectedGoalsSummary: View {
    let goals: [HealthGoal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("\(goals.count) goal\(goals.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            FlowLayout(spacing: 6) {
                ForEach(goals.prefix(6), id: \.rawValue) { goal in
                    Text(goal.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(12)
                }
                
                if goals.count > 6 {
                    Text("+\(goals.count - 6) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Goal Category Section

struct GoalCategorySection: View {
    let category: GoalCategory
    @Binding var selectedGoals: Set<HealthGoal>
    let isExpanded: Bool
    let onTap: () -> Void
    let onToggle: (HealthGoal) -> Void
    
    var selectedCount: Int {
        category.goals.filter { selectedGoals.contains($0) }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if selectedCount > 0 {
                        Text("\(selectedCount)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            .background(Color(.systemGray6))
            
            // Expandable content
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(category.goals) { goal in
                        GoalRow(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal),
                            onToggle: { onToggle(goal) }
                        )
                        
                        if goal != category.goals.last {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Goal Row

struct GoalRow: View {
    let goal: HealthGoal
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Image(systemName: goal.icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Preview

#Preview {
    GoalsView(viewModel: OnboardingViewModel())
}
