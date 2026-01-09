//
//  AIPromptBuilder.swift
//  HealthOptimizer
//
//  Builds prompts for AI health recommendation generation
//  Constructs detailed, structured prompts for optimal AI responses
//

import Foundation

// MARK: - AI Prompt Builder

/// Builds structured prompts for AI health recommendations
struct AIPromptBuilder {

  // MARK: - System Prompt

  /// Build the system prompt that defines AI behavior and output format
  func buildSystemPrompt() -> String {
    """
    You are an expert health optimization consultant with deep knowledge in:
    - Clinical nutrition and dietetics
    - Exercise physiology and program design
    - Nutraceuticals and supplementation
    - Integrative and functional medicine approaches
    - Sleep science and stress management

    Your role is to analyze user health profiles and generate comprehensive, personalized health optimization plans. You must:

    1. Consider all health conditions, medications, and contraindications
    2. Provide evidence-based recommendations with scientific backing
    3. Prioritize safety - flag any concerns or necessary medical consultations
    4. Create practical, sustainable recommendations
    5. Explain the reasoning behind each recommendation

    IMPORTANT GUIDELINES:
    - Never recommend supplements that interact negatively with user's medications
    - Always include disclaimers about consulting healthcare providers
    - Be conservative with dosages, starting on the lower end
    - Consider user's lifestyle constraints (time, budget, cooking ability)
    - For users with health conditions like diabetes, prioritize blood sugar management

    OUTPUT FORMAT:
    You must respond with a valid JSON object matching this exact structure. Do not include any text before or after the JSON:

    {
      "healthSummary": "string - comprehensive analysis of user's health profile",
      "keyInsights": ["string array - 4-6 key observations from the profile"],
      "priorityActions": ["string array - 3-5 most important actions to take"],
      "supplementPlan": {
        "id": "UUID string",
        "supplements": [
          {
            "id": "UUID string",
            "name": "supplement name",
            "alternateNames": ["other names"],
            "dosage": "amount",
            "unit": "mg/IU/etc",
            "timing": "Morning|Midday|Evening|Before Bed|With Meals|etc",
            "frequency": "Daily|Twice Daily|etc",
            "withFood": true/false,
            "priority": "Essential|Highly Recommended|Beneficial|Optional/Consider",
            "reasoning": "why this supplement",
            "scientificBacking": "research support",
            "benefits": ["list of benefits"],
            "potentialSideEffects": ["possible side effects"],
            "interactions": ["drug/supplement interactions"],
            "contraindications": ["who should not take this"],
            "qualityNotes": "what to look for when buying",
            "estimatedMonthlyCost": "$X-Y range"
          }
        ],
        "generalGuidelines": "overall supplementation guidance",
        "warnings": ["important warnings"],
        "interactionNotes": ["interaction considerations"],
        "createdAt": "ISO date string"
      },
      "workoutPlan": {
        "id": "UUID string",
        "name": "program name",
        "description": "program description",
        "durationWeeks": number,
        "daysPerWeek": number,
        "workoutDays": [
          {
            "id": "UUID string",
            "dayNumber": 1-7,
            "name": "day name",
            "focus": ["muscle groups"],
            "workoutType": "Strength Training|Hypertrophy|Cardio|etc",
            "exercises": [
              {
                "id": "UUID string",
                "name": "exercise name",
                "muscleGroups": ["target muscles"],
                "sets": number,
                "reps": "rep range string",
                "restSeconds": number,
                "rpe": 1-10,
                "instructions": "how to perform",
                "tips": ["form tips"],
                "commonMistakes": ["mistakes to avoid"],
                "alternatives": ["substitute exercises"]
              }
            ],
            "estimatedDuration": minutes
          }
        ],
        "restDayGuidelines": "rest day advice",
        "warmupGuidelines": "warmup protocol",
        "cooldownGuidelines": "cooldown protocol",
        "progressionNotes": "how to progress",
        "equipmentNeeded": ["required equipment"],
        "difficultyLevel": "Beginner|Intermediate|Advanced|Athlete",
        "estimatedCaloriesBurnedPerSession": "calorie range",
        "createdAt": "ISO date string"
      },
      "dietPlan": {
        "id": "UUID string",
        "name": "plan name",
        "description": "plan description",
        "dailyCalories": number,
        "macros": {
          "proteinGrams": number,
          "proteinPercentage": number,
          "carbsGrams": number,
          "carbsPercentage": number,
          "fatGrams": number,
          "fatPercentage": number,
          "fiberGrams": number,
          "sugarLimitGrams": number,
          "sodiumLimitMg": number
        },
        "mealSchedule": [
          {
            "id": "UUID string",
            "mealType": "Breakfast|Lunch|Dinner|etc",
            "targetCalories": number,
            "targetProtein": number,
            "targetCarbs": number,
            "targetFat": number,
            "suggestedTime": "time range",
            "guidelines": "meal guidelines"
          }
        ],
        "sampleMealPlan": [
          {
            "id": "UUID string",
            "dayNumber": 1-7,
            "dayName": "day name",
            "meals": [
              {
                "id": "UUID string",
                "mealType": "meal type",
                "name": "meal name",
                "description": "brief description",
                "ingredients": [
                  {
                    "id": "UUID string",
                    "name": "ingredient",
                    "amount": number,
                    "unit": "unit",
                    "notes": "optional notes",
                    "isOptional": true/false
                  }
                ],
                "instructions": ["step by step"],
                "prepTimeMinutes": number,
                "cookTimeMinutes": number,
                "servings": number,
                "calories": number,
                "protein": number,
                "carbs": number,
                "fat": number,
                "fiber": number,
                "tips": ["cooking tips"],
                "substitutions": {"ingredient": "substitution"},
                "mealPrepFriendly": true/false,
                "tags": ["tags"]
              }
            ],
            "totalCalories": number,
            "totalProtein": number,
            "totalCarbs": number,
            "totalFat": number
          }
        ],
        "generalGuidelines": ["eating guidelines"],
        "foodsToInclude": ["foods to eat"],
        "foodsToLimit": ["foods to limit"],
        "hydrationGuidelines": "water intake guidance",
        "mealTimingGuidelines": "when to eat",
        "snackingGuidelines": "snack advice",
        "createdAt": "ISO date string"
      },
      "lifestyleRecommendations": ["string array - lifestyle changes"],
      "disclaimers": ["string array - medical/legal disclaimers"],
      "suggestedReviewWeeks": number
    }

    Generate UUIDs in standard format (e.g., "550e8400-e29b-41d4-a716-446655440000").
    Dates should be ISO 8601 format (e.g., "2024-01-15T10:30:00Z").
    """
  }

  // MARK: - User Prompt

  /// Build the user prompt with profile data
  func buildUserPrompt(for profile: UserProfile) -> String {
    var prompt =
      "Please analyze the following health profile and generate comprehensive recommendations:\n\n"

    // Basic Information
    prompt += "## BASIC INFORMATION\n"
    prompt += "- Age: \(profile.age) years\n"
    prompt += "- Biological Sex: \(profile.biologicalSex.rawValue)\n"
    prompt += "- Height: \(profile.heightCm) cm (\(cmToFeetInches(profile.heightCm)))\n"
    prompt += "- Weight: \(profile.weightKg) kg (\(kgToLbs(profile.weightKg)) lbs)\n"
    prompt += "- BMI: \(String(format: "%.1f", profile.bmi)) (\(profile.bmiCategory.rawValue))\n"
    if let bodyFat = profile.bodyFatPercentage {
      prompt += "- Body Fat: \(bodyFat)%\n"
    }
    if let waist = profile.waistCircumferenceCm {
      prompt += "- Waist Circumference: \(waist) cm\n"
    }
    prompt += "- Estimated BMR: \(Int(profile.estimatedBMR)) calories\n"
    prompt += "- Estimated TDEE: \(Int(profile.estimatedTDEE)) calories\n\n"

    // Health Conditions
    prompt += "## HEALTH CONDITIONS\n"
    if profile.healthConditions.isEmpty || profile.healthConditions == [.none] {
      prompt += "- No reported health conditions\n"
    } else {
      for condition in profile.healthConditions where condition != .none {
        prompt += "- \(condition.rawValue)\n"
      }
    }
    if let familyHistory = profile.familyHistoryNotes, !familyHistory.isEmpty {
      prompt += "- Family History Notes: \(familyHistory)\n"
    }
    prompt += "\n"

    // Allergies
    prompt += "## ALLERGIES\n"
    if profile.allergies.isEmpty {
      prompt += "- No known allergies\n"
    } else {
      for allergy in profile.allergies {
        prompt += "- \(allergy)\n"
      }
    }
    prompt += "\n"

    // Medications
    prompt += "## CURRENT MEDICATIONS\n"
    if profile.currentMedications.isEmpty {
      prompt += "- No current medications\n"
    } else {
      for med in profile.currentMedications {
        prompt += "- \(med.name)"
        if !med.dosage.isEmpty {
          prompt += " (\(med.dosage), \(med.frequency.rawValue))"
        }
        if let purpose = med.purpose {
          prompt += " - for: \(purpose)"
        }
        prompt += "\n"
      }
    }
    prompt += "\n"

    // Current Supplements
    prompt += "## CURRENT SUPPLEMENTS\n"
    if profile.currentSupplements.isEmpty {
      prompt += "- Not currently taking supplements\n"
    } else {
      for supp in profile.currentSupplements {
        prompt += "- \(supp.name)"
        if !supp.dosage.isEmpty {
          prompt += " (\(supp.dosage))"
        }
        prompt += "\n"
      }
    }
    prompt += "\n"

    // Fitness Profile
    prompt += "## FITNESS PROFILE\n"
    prompt +=
      "- Fitness Level: \(profile.fitnessLevel.rawValue) - \(profile.fitnessLevel.description)\n"
    prompt += "- Weekly Activity Days: \(profile.weeklyActivityDays)\n"
    prompt += "- Current Activities: "
    if profile.currentActivities.isEmpty {
      prompt += "None\n"
    } else {
      prompt += profile.currentActivities.map { $0.rawValue }.joined(separator: ", ") + "\n"
    }
    prompt += "- Has Gym Access: \(profile.hasGymAccess ? "Yes" : "No")\n"
    prompt += "- Available Workout Time: \(profile.availableWorkoutMinutes) minutes per session\n"
    if !profile.physicalLimitations.isEmpty {
      prompt += "- Physical Limitations: \(profile.physicalLimitations.joined(separator: ", "))\n"
    }
    prompt += "\n"

    // Dietary Information
    prompt += "## DIETARY INFORMATION\n"
    prompt += "- Diet Type: \(profile.dietType.rawValue)\n"
    prompt += "- Meals Per Day: \(profile.mealsPerDay)\n"
    prompt += "- Cooking Skill: \(profile.cookingSkillLevel.rawValue)\n"
    prompt += "- Weekly Meal Prep Time: \(profile.weeklyMealPrepHours) hours\n"
    if !profile.foodIntolerances.isEmpty {
      prompt += "- Food Intolerances: \(profile.foodIntolerances.joined(separator: ", "))\n"
    }
    if !profile.foodsToAvoid.isEmpty {
      prompt += "- Foods to Avoid: \(profile.foodsToAvoid.joined(separator: ", "))\n"
    }
    if !profile.favoriteFoods.isEmpty {
      prompt += "- Favorite Foods: \(profile.favoriteFoods.joined(separator: ", "))\n"
    }
    if let calorieTarget = profile.dailyCalorieTarget {
      prompt += "- Target Calories: \(calorieTarget)\n"
    }
    prompt += "\n"

    // Lifestyle Factors
    prompt += "## LIFESTYLE FACTORS\n"
    prompt += "- Average Sleep: \(profile.averageSleepHours) hours/night\n"
    prompt += "- Sleep Quality: \(profile.sleepQuality.rawValue)\n"
    prompt += "- Stress Level: \(profile.stressLevel.rawValue)\n"
    prompt += "- Occupation Type: \(profile.occupationType.rawValue)\n"
    prompt += "- Daily Water Intake: \(profile.dailyWaterIntakeLiters) liters\n"
    prompt += "- Alcohol: \(profile.alcoholConsumption.rawValue)\n"
    prompt += "- Caffeine: \(profile.caffeineCupsPerDay) cups/day\n"
    prompt += "- Smoking Status: \(profile.smokingStatus.rawValue)\n\n"

    // Health Goals
    prompt += "## HEALTH GOALS\n"
    if profile.healthGoals.isEmpty {
      prompt += "- No specific goals set\n"
    } else {
      for goal in profile.healthGoals {
        prompt += "- \(goal.rawValue)\n"
      }
    }
    prompt += "- Goal Timeline: \(profile.goalTimelineWeeks) weeks\n"
    if let notes = profile.additionalNotes, !notes.isEmpty {
      prompt += "- Additional Notes: \(notes)\n"
    }
    prompt += "\n"

    // Final instruction
    prompt += """
      \n## TASK
      Based on this comprehensive health profile, generate a complete health optimization plan including:
      1. Personalized supplement recommendations with proper consideration of medications and conditions
      2. A workout program appropriate for their fitness level, available time, and goals
      3. A nutrition plan respecting their dietary preferences, intolerances, and cooking ability
      4. Lifestyle modifications to support their goals

      Ensure all recommendations are safe, evidence-based, and practical for this individual.
      Return your response as a valid JSON object matching the specified format.
      """

    return prompt
  }

  // MARK: - Helper Methods

  private func cmToFeetInches(_ cm: Double) -> String {
    let totalInches = cm / 2.54
    let feet = Int(totalInches / 12)
    let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
    return "\(feet)'\(inches)\""
  }

  private func kgToLbs(_ kg: Double) -> String {
    return String(format: "%.1f", kg * 2.205)
  }
}
