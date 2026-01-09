//
//  LifestyleView.swift
//  HealthOptimizer
//
//  View for collecting lifestyle factors (sleep, stress, etc.)
//

import SwiftUI

// MARK: - Lifestyle View

struct LifestyleView: View {

  @Bindable var viewModel: OnboardingViewModel

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        SectionHeader(
          title: "Lifestyle",
          subtitle:
            "Your daily habits significantly impact your health. This helps us give holistic recommendations."
        )

        // Sleep Section
        VStack(alignment: .leading, spacing: 16) {
          Label("Sleep", systemImage: "moon.fill")
            .font(.headline)

          // Average sleep hours
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Average Sleep")
              Spacer()
              Text(String(format: "%.1f hours", viewModel.averageSleepHours))
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
            }

            Slider(
              value: $viewModel.averageSleepHours,
              in: 3...12,
              step: 0.5
            )

            HStack {
              Text("3 hrs")
              Spacer()
              Text("12 hrs")
            }
            .font(.caption)
            .foregroundColor(.secondary)
          }

          // Sleep quality
          VStack(alignment: .leading, spacing: 8) {
            Text("Sleep Quality")

            Picker("Sleep Quality", selection: $viewModel.sleepQuality) {
              ForEach(SleepQuality.allCases) { quality in
                Text(quality.rawValue).tag(quality)
              }
            }
            .pickerStyle(.segmented)

            Text(viewModel.sleepQuality.description)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)

        // Stress Section
        VStack(alignment: .leading, spacing: 16) {
          Label("Stress Level", systemImage: "brain.head.profile")
            .font(.headline)

          Picker("Stress Level", selection: $viewModel.stressLevel) {
            ForEach(StressLevel.allCases) { level in
              Text(level.rawValue).tag(level)
            }
          }
          .pickerStyle(.segmented)

          Text(viewModel.stressLevel.description)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)

        // Occupation
        VStack(alignment: .leading, spacing: 12) {
          Label("Occupation Type", systemImage: "briefcase.fill")
            .font(.headline)

          ForEach(OccupationType.allCases) { type in
            Button(action: { viewModel.occupationType = type }) {
              HStack {
                Image(
                  systemName: viewModel.occupationType == type ? "checkmark.circle.fill" : "circle"
                )
                .foregroundColor(viewModel.occupationType == type ? .accentColor : .secondary)
                Text(type.rawValue)
                  .foregroundColor(.primary)
                Spacer()
              }
              .padding(.vertical, 8)
            }
          }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)

        // Hydration
        VStack(alignment: .leading, spacing: 12) {
          Label("Daily Water Intake", systemImage: "drop.fill")
            .font(.headline)

          HStack {
            Slider(
              value: $viewModel.dailyWaterIntakeLiters,
              in: 0.5...5,
              step: 0.25
            )

            Text(String(format: "%.1fL", viewModel.dailyWaterIntakeLiters))
              .fontWeight(.semibold)
              .foregroundColor(.accentColor)
              .frame(width: 50)
          }

          // Quick recommendations
          HStack {
            Text("Recommended: 2-3L daily")
              .font(.caption)
              .foregroundColor(.secondary)
            Spacer()
          }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)

        // Substances Section
        VStack(alignment: .leading, spacing: 16) {
          Text("Habits")
            .font(.headline)

          // Caffeine
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: "cup.and.saucer.fill")
              Text("Caffeine")
              Spacer()
              Text("\(viewModel.caffeineCupsPerDay) cups/day")
                .foregroundColor(.secondary)
            }

            Stepper(
              value: $viewModel.caffeineCupsPerDay,
              in: 0...10
            ) {
              EmptyView()
            }
          }

          Divider()

          // Alcohol
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: "wineglass.fill")
              Text("Alcohol Consumption")
            }

            Picker("Alcohol", selection: $viewModel.alcoholConsumption) {
              ForEach(ConsumptionFrequency.allCases) { freq in
                Text(freq.rawValue).tag(freq)
              }
            }
            .pickerStyle(.menu)
          }

          Divider()

          // Smoking
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: "smoke.fill")
              Text("Smoking Status")
            }

            Picker("Smoking", selection: $viewModel.smokingStatus) {
              ForEach(SmokingStatus.allCases) { status in
                Text(status.rawValue).tag(status)
              }
            }
            .pickerStyle(.menu)
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
}

// MARK: - Preview

#Preview {
  LifestyleView(viewModel: OnboardingViewModel())
}
