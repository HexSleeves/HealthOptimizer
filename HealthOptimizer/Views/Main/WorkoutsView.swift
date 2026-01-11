//
//  WorkoutsView.swift
//  HealthOptimizer
//
//  View displaying workout recommendations
//

import SwiftUI

// MARK: - Workouts View

struct WorkoutsView: View {

  let recommendation: HealthRecommendation?
  @State private var selectedDay: WorkoutDay?

  var workoutPlan: WorkoutPlan? {
    recommendation?.workoutPlan
  }

  var body: some View {
    NavigationStack {
      Group {
        if let plan = workoutPlan {
          workoutContent(plan)
        } else {
          noWorkoutsView
        }
      }
      .navigationTitle("Workouts")
      .sheet(item: $selectedDay) { day in
        WorkoutDayDetailSheet(day: day)
      }
    }
  }

  // MARK: - Workout Content

  private func workoutContent(_ plan: WorkoutPlan) -> some View {
    ScrollView {
      VStack(spacing: 20) {
        // Plan Overview
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Image(systemName: "dumbbell.fill")
              .foregroundColor(.orange)
            Text(plan.name)
              .font(.headline)
          }

          Text(plan.description)
            .font(.subheadline)
            .foregroundColor(.secondary)

          // Quick stats
          HStack(spacing: 20) {
            WorkoutStatBadge(
              value: "\(plan.durationWeeks)",
              label: "weeks",
              icon: "calendar"
            )
            WorkoutStatBadge(
              value: "\(plan.daysPerWeek)",
              label: "days/wk",
              icon: "clock"
            )
            WorkoutStatBadge(
              value: plan.difficultyLevel.rawValue,
              label: "level",
              icon: "speedometer"
            )
          }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)

        // Equipment Needed
        if !plan.equipmentNeeded.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Label("Equipment Needed", systemImage: "wrench.and.screwdriver.fill")
              .font(.subheadline)
              .fontWeight(.semibold)

            FlowLayout(spacing: 8) {
              ForEach(plan.equipmentNeeded, id: \.self) { equipment in
                Text(equipment)
                  .font(.caption)
                  .padding(.horizontal, 10)
                  .padding(.vertical, 6)
                  .background(Color.orange.opacity(0.1))
                  .foregroundColor(.orange)
                  .cornerRadius(8)
              }
            }
          }
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(12)
          .padding(.horizontal)
        }

        // Weekly Schedule
        VStack(alignment: .leading, spacing: 12) {
          Text("Weekly Schedule")
            .font(.headline)
            .padding(.horizontal)

          ForEach(plan.workoutDays) { day in
            WorkoutDayCard(day: day) {
              selectedDay = day
            }
          }
        }

        // Guidelines
        VStack(alignment: .leading, spacing: 16) {
          // Warmup
          if !plan.warmupGuidelines.isEmpty {
            GuidelineCard(
              title: "Warm-Up",
              content: plan.warmupGuidelines,
              icon: "flame.fill",
              color: .red
            )
          }

          // Cooldown
          if !plan.cooldownGuidelines.isEmpty {
            GuidelineCard(
              title: "Cool-Down",
              content: plan.cooldownGuidelines,
              icon: "snowflake",
              color: .blue
            )
          }

          // Rest days
          if !plan.restDayGuidelines.isEmpty {
            GuidelineCard(
              title: "Rest Days",
              content: plan.restDayGuidelines,
              icon: "bed.double.fill",
              color: .purple
            )
          }

          // Progression
          if !plan.progressionNotes.isEmpty {
            GuidelineCard(
              title: "Progression",
              content: plan.progressionNotes,
              icon: "chart.line.uptrend.xyaxis",
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

  // MARK: - No Workouts View

  private var noWorkoutsView: some View {
    VStack(spacing: 20) {
      Image(systemName: "figure.run")
        .font(.system(size: 60))
        .foregroundColor(.secondary)

      Text("No Workout Plan Yet")
        .font(.headline)

      Text("Generate recommendations from the Dashboard to see your personalized workout plan.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Workout Stat Badge

struct WorkoutStatBadge: View {
  let value: String
  let label: String
  let icon: String

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .font(.caption)
        .foregroundColor(.orange)
      Text(value)
        .font(.headline)
      Text(label)
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Workout Day Card

struct WorkoutDayCard: View {
  let day: WorkoutDay
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        // Day number circle
        ZStack {
          Circle()
            .fill(Color.orange)
            .frame(width: 44, height: 44)
          Text("Day \(day.dayNumber)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(day.name)
            .font(.headline)
            .foregroundColor(.primary)

          HStack(spacing: 12) {
            Label("\(day.exercises.count) exercises", systemImage: "list.bullet")
            Label("\(day.estimatedDuration) min", systemImage: "clock")
          }
          .font(.caption)
          .foregroundColor(.secondary)

          // Muscle groups
          HStack(spacing: 4) {
            ForEach(day.focus.uniqued().prefix(3), id: \.rawValue) { muscle in
              Text(muscle.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(4)
            }
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .foregroundColor(.secondary)
      }
      .padding()
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .shadow(color: .black.opacity(0.05), radius: 5)
    }
    .buttonStyle(.plain)
    .padding(.horizontal)
  }
}

// MARK: - Guideline Card

struct GuidelineCard: View {
  let title: String
  let content: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: icon)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(color)

      Text(content)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(color.opacity(0.1))
    .cornerRadius(12)
  }
}

// MARK: - Workout Day Detail Sheet

struct WorkoutDayDetailSheet: View {
  @Environment(\.dismiss) private var dismiss
  let day: WorkoutDay

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Text(day.name)
              .font(.title)
              .fontWeight(.bold)

            HStack(spacing: 16) {
              Label("\(day.exercises.count) exercises", systemImage: "list.bullet")
              Label("\(day.estimatedDuration) min", systemImage: "clock")
              Label(day.workoutType.rawValue, systemImage: "dumbbell")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
          }

          // Target muscles
          VStack(alignment: .leading, spacing: 8) {
            Text("Target Muscles")
              .font(.headline)

            FlowLayout(spacing: 8) {
              ForEach(day.focus.uniqued(), id: \.rawValue) { muscle in
                HStack(spacing: 4) {
                  Image(systemName: muscle.icon)
                  Text(muscle.rawValue)
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(8)
              }
            }
          }

          // Exercises
          VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
              .font(.headline)

            ForEach(Array(day.exercises.enumerated()), id: \.offset) { index, exercise in
              ExerciseCard(exercise: exercise, index: index + 1)
            }
          }

          // Notes
          if let notes = day.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              Label("Notes", systemImage: "note.text")
                .font(.headline)
              Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
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

// MARK: - Exercise Card

struct ExerciseCard: View {
  let exercise: Exercise
  let index: Int
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Main content - always visible
      Button(action: { withAnimation { isExpanded.toggle() } }) {
        HStack(alignment: .top) {
          // Index
          Text("\(index)")
            .font(.caption)
            .fontWeight(.bold)
            .frame(width: 24, height: 24)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)

          VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
              .font(.headline)
              .foregroundColor(.primary)

            HStack(spacing: 12) {
              Text(exercise.setsRepsDisplay)
                .fontWeight(.semibold)
                .foregroundColor(.orange)

              Text(exercise.restDisplay)
                .foregroundColor(.secondary)

              if let rpe = exercise.rpe {
                Text("RPE \(rpe)")
                  .foregroundColor(.secondary)
              }
            }
            .font(.caption)
          }

          Spacer()

          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      .buttonStyle(.plain)

      // Expandable details
      if isExpanded {
        VStack(alignment: .leading, spacing: 12) {
          // Instructions
          if !exercise.instructions.isEmpty {
            Text("Instructions")
              .font(.caption)
              .fontWeight(.semibold)
            Text(exercise.instructions)
              .font(.caption)
              .foregroundColor(.secondary)
          }

          // Tips
          if !exercise.tips.isEmpty {
            Text("Tips")
              .font(.caption)
              .fontWeight(.semibold)
            ForEach(exercise.tips, id: \.self) { tip in
              HStack(alignment: .top, spacing: 4) {
                Image(systemName: "lightbulb.fill")
                  .font(.caption2)
                  .foregroundColor(.yellow)
                Text(tip)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }

          // Common mistakes
          if !exercise.commonMistakes.isEmpty {
            Text("Avoid")
              .font(.caption)
              .fontWeight(.semibold)
            ForEach(exercise.commonMistakes, id: \.self) { mistake in
              HStack(alignment: .top, spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                  .font(.caption2)
                  .foregroundColor(.red)
                Text(mistake)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }

          // Alternatives
          if !exercise.alternatives.isEmpty {
            Text("Alternatives: \(exercise.alternatives.joined(separator: ", "))")
              .font(.caption)
              .foregroundColor(.blue)
          }
        }
        .padding(.leading, 32)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 3)
  }
}

// MARK: - Preview

private struct WorkoutsPreview: View {
  @State private var recommendation: HealthRecommendation?

  var body: some View {
    WorkoutsView(recommendation: recommendation)
      .onAppear {
        let rec = HealthRecommendation(status: .completed)
        rec.workoutPlan = WorkoutPlan.sample
        recommendation = rec
      }
  }
}

#Preview {
  WorkoutsPreview()
}
