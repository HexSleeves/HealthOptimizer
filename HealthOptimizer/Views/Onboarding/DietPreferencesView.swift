//
//  DietPreferencesView.swift
//  HealthOptimizer
//
//  View for collecting dietary preferences and restrictions
//

import SwiftUI

// MARK: - Diet Preferences View

struct DietPreferencesView: View {
    
    @Bindable var viewModel: OnboardingViewModel
    @State private var newIntolerance = ""
    @State private var newFoodToAvoid = ""
    @State private var newFavoriteFood = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                SectionHeader(
                    title: "Dietary Preferences",
                    subtitle: "Tell us about your eating habits and preferences so we can create a sustainable meal plan."
                )
                
                // Diet Type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Diet Type")
                        .font(.headline)
                    Text("What best describes your current diet?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(DietType.allCases) { diet in
                        DietTypeOption(
                            diet: diet,
                            isSelected: viewModel.dietType == diet,
                            onSelect: { viewModel.dietType = diet }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Meals Per Day
                VStack(alignment: .leading, spacing: 12) {
                    Text("Meals Per Day")
                        .font(.headline)
                    
                    Stepper(value: $viewModel.mealsPerDay, in: 2...6) {
                        HStack {
                            Text("\(viewModel.mealsPerDay)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("meals/day")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Cooking Skill Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cooking Skill Level")
                        .font(.headline)
                    
                    Picker("Cooking Skill", selection: $viewModel.cookingSkillLevel) {
                        ForEach(CookingSkillLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(viewModel.cookingSkillLevel.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Meal Prep Time
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Weekly Meal Prep Time")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f hours", viewModel.weeklyMealPrepHours))
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                    
                    Slider(
                        value: $viewModel.weeklyMealPrepHours,
                        in: 0...10,
                        step: 0.5
                    )
                    
                    HStack {
                        Text("0 hrs")
                        Spacer()
                        Text("10 hrs")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Food Intolerances
                FoodListSection(
                    title: "Food Intolerances",
                    subtitle: "Foods that cause digestive issues or reactions",
                    items: $viewModel.foodIntolerances,
                    newItem: $newIntolerance,
                    placeholder: "e.g., Lactose, Gluten",
                    chipColor: .red
                )
                
                // Foods to Avoid
                FoodListSection(
                    title: "Foods to Avoid",
                    subtitle: "Foods you prefer not to eat",
                    items: $viewModel.foodsToAvoid,
                    newItem: $newFoodToAvoid,
                    placeholder: "e.g., Mushrooms, Olives",
                    chipColor: .orange
                )
                
                // Favorite Foods
                FoodListSection(
                    title: "Favorite Foods",
                    subtitle: "Foods you'd like to include in your plan",
                    items: $viewModel.favoriteFoods,
                    newItem: $newFavoriteFood,
                    placeholder: "e.g., Chicken, Broccoli",
                    chipColor: .green
                )
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.top)
        }
    }
}

// MARK: - Diet Type Option

struct DietTypeOption: View {
    let diet: DietType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(diet.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// MARK: - Food List Section

struct FoodListSection: View {
    let title: String
    let subtitle: String
    @Binding var items: [String]
    @Binding var newItem: String
    let placeholder: String
    let chipColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField(placeholder, text: $newItem)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(addItem)
                
                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .disabled(newItem.isEmpty)
            }
            
            if !items.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 4) {
                            Text(item)
                                .font(.subheadline)
                            Button(action: { removeItem(item) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(chipColor.opacity(0.1))
                        .foregroundColor(chipColor)
                        .cornerRadius(16)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !items.contains(trimmed) else { return }
        items.append(trimmed)
        newItem = ""
    }
    
    private func removeItem(_ item: String) {
        items.removeAll { $0 == item }
    }
}

// MARK: - Preview

#Preview {
    DietPreferencesView(viewModel: OnboardingViewModel())
}
