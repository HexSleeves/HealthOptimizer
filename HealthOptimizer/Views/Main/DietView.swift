//
//  DietView.swift
//  HealthOptimizer
//
//  View displaying diet and meal plan recommendations
//

import SwiftUI

// MARK: - Diet View

struct DietView: View {
    
    let recommendation: HealthRecommendation?
    @State private var selectedDay: DayMealPlan?
    @State private var selectedMeal: Meal?
    
    var dietPlan: DietPlan? {
        recommendation?.dietPlan
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let plan = dietPlan {
                    dietContent(plan)
                } else {
                    noDietView
                }
            }
            .navigationTitle("Diet Plan")
            .sheet(item: $selectedMeal) { meal in
                MealDetailSheet(meal: meal)
            }
        }
    }
    
    // MARK: - Diet Content
    
    private func dietContent(_ plan: DietPlan) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.blue)
                        Text(plan.name)
                            .font(.headline)
                    }
                    
                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Calorie and Macro Overview
                    HStack(spacing: 16) {
                        CalorieBadge(calories: plan.dailyCalories)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            MacroRow(label: "Protein", grams: plan.macros.proteinGrams, percent: plan.macros.proteinPercentage, color: .red)
                            MacroRow(label: "Carbs", grams: plan.macros.carbsGrams, percent: plan.macros.carbsPercentage, color: .blue)
                            MacroRow(label: "Fat", grams: plan.macros.fatGrams, percent: plan.macros.fatPercentage, color: .yellow)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                .padding(.horizontal)
                
                // Guidelines
                if !plan.generalGuidelines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Guidelines", systemImage: "list.clipboard.fill")
                            .font(.headline)
                        
                        ForEach(plan.generalGuidelines, id: \.self) { guideline in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(guideline)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Foods to Include/Avoid
                HStack(spacing: 12) {
                    FoodListCard(
                        title: "Include",
                        foods: plan.foodsToInclude,
                        icon: "checkmark",
                        color: .green
                    )
                    
                    FoodListCard(
                        title: "Limit",
                        foods: plan.foodsToLimit,
                        icon: "minus",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Meal Schedule
                if !plan.mealSchedule.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Meal Schedule")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(plan.mealSchedule) { template in
                            MealTemplateCard(template: template)
                        }
                    }
                }
                
                // Sample Meal Plan
                if !plan.sampleMealPlan.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sample 7-Day Plan")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(plan.sampleMealPlan) { dayPlan in
                                    DayPlanCard(dayPlan: dayPlan) { meal in
                                        selectedMeal = meal
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Additional Guidelines
                VStack(spacing: 12) {
                    if !plan.hydrationGuidelines.isEmpty {
                        MiniGuidelineCard(
                            title: "Hydration",
                            content: plan.hydrationGuidelines,
                            icon: "drop.fill",
                            color: .blue
                        )
                    }
                    
                    if !plan.mealTimingGuidelines.isEmpty {
                        MiniGuidelineCard(
                            title: "Meal Timing",
                            content: plan.mealTimingGuidelines,
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    
                    if !plan.snackingGuidelines.isEmpty {
                        MiniGuidelineCard(
                            title: "Snacking",
                            content: plan.snackingGuidelines,
                            icon: "leaf.fill",
                            color: .green
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.top)
        }
    }
    
    // MARK: - No Diet View
    
    private var noDietView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Diet Plan Yet")
                .font(.headline)
            
            Text("Generate recommendations from the Dashboard to see your personalized diet plan.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Calorie Badge

struct CalorieBadge: View {
    let calories: Int
    
    var body: some View {
        VStack {
            Text("\(calories)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("kcal/day")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(
            Circle()
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Macro Row

struct MacroRow: View {
    let label: String
    let grams: Int
    let percent: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
            Spacer()
            Text("\(grams)g")
                .font(.caption)
                .fontWeight(.semibold)
            Text("(\(percent)%)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Food List Card

struct FoodListCard: View {
    let title: String
    let foods: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            ForEach(foods.prefix(4), id: \.self) { food in
                Text("• \(food)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if foods.count > 4 {
                Text("+\(foods.count - 4) more")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Meal Template Card

struct MealTemplateCard: View {
    let template: MealTemplate
    
    var body: some View {
        HStack {
            Image(systemName: template.mealType.icon)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(template.mealType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(template.suggestedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Text("\(template.targetCalories) cal")
                    Text("P: \(template.targetProtein)g")
                    Text("C: \(template.targetCarbs)g")
                    Text("F: \(template.targetFat)g")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Day Plan Card

struct DayPlanCard: View {
    let dayPlan: DayMealPlan
    let onMealTap: (Meal) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dayPlan.dayName)
                .font(.headline)
            
            Text("\(dayPlan.totalCalories) cal")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(dayPlan.meals) { meal in
                Button(action: { onMealTap(meal) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: meal.mealType.icon)
                                .font(.caption)
                            Text(meal.mealType.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        
                        Text(meal.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 180)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Mini Guideline Card

struct MiniGuidelineCard: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Meal Detail Sheet

struct MealDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let meal: Meal
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: meal.mealType.icon)
                            Text(meal.mealType.rawValue)
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        
                        Text(meal.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(meal.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Nutrition & Time Info
                    HStack(spacing: 16) {
                        NutritionBadge(value: "\(meal.calories)", label: "cal", color: .orange)
                        NutritionBadge(value: "\(meal.protein)g", label: "protein", color: .red)
                        NutritionBadge(value: "\(meal.carbs)g", label: "carbs", color: .blue)
                        NutritionBadge(value: "\(meal.fat)g", label: "fat", color: .yellow)
                    }
                    
                    HStack(spacing: 16) {
                        Label(meal.totalTimeDisplay, systemImage: "clock")
                        if meal.mealPrepFriendly {
                            Label("Meal prep friendly", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Tags
                    if !meal.tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(meal.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        ForEach(meal.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.display)
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.headline)
                        
                        ForEach(Array(meal.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 24, height: 24)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                
                                Text(instruction)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    // Tips
                    if !meal.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tips")
                                .font(.headline)
                            
                            ForEach(meal.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    Text(tip)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Substitutions
                    if !meal.substitutions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Substitutions")
                                .font(.headline)
                            
                            ForEach(Array(meal.substitutions.keys), id: \.self) { key in
                                if let value = meal.substitutions[key] {
                                    HStack {
                                        Text(key)
                                            .font(.caption)
                                        Image(systemName: "arrow.right")
                                            .font(.caption2)
                                        Text(value)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Nutrition Badge

struct NutritionBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    DietView(recommendation: HealthRecommendation.sample)
}
