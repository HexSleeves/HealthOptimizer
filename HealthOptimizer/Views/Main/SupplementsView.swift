//
//  SupplementsView.swift
//  HealthOptimizer
//
//  View displaying supplement recommendations
//

import SwiftUI

// MARK: - Supplements View

struct SupplementsView: View {

  let recommendation: HealthRecommendation?
  @State private var selectedSupplement: SupplementRecommendation?
  @State private var selectedTiming: SupplementTiming?

  var supplementPlan: SupplementPlan? {
    recommendation?.supplementPlan
  }

  var body: some View {
    NavigationStack {
      Group {
        if let plan = supplementPlan {
          supplementList(plan)
        } else {
          noSupplementsView
        }
      }
      .navigationTitle("Supplements")
      .sheet(item: $selectedSupplement) { supplement in
        SupplementDetailSheet(supplement: supplement)
      }
    }
  }

  // MARK: - Supplement List

  private func supplementList(_ plan: SupplementPlan) -> some View {
    ScrollView {
      VStack(spacing: 20) {
        // Overview Card
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Image(systemName: "pills.fill")
              .foregroundColor(.green)
            Text("Your Supplement Plan")
              .font(.headline)
          }

          Text(plan.generalGuidelines)
            .font(.subheadline)
            .foregroundColor(.secondary)

          // Priority counts
          HStack(spacing: 16) {
            PriorityBadge(
              count: plan.supplements.filter { $0.priority == .essential }.count,
              priority: .essential
            )
            PriorityBadge(
              count: plan.supplements.filter { $0.priority == .recommended }.count,
              priority: .recommended
            )
            PriorityBadge(
              count: plan.supplements.filter { $0.priority == .beneficial }.count,
              priority: .beneficial
            )
          }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)

        // Timing Filter
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            TimingFilterChip(
              title: "All",
              isSelected: selectedTiming == nil,
              action: { selectedTiming = nil }
            )

            ForEach(SupplementTiming.allCases) { timing in
              let count = plan.supplements.filter { $0.timing == timing }.count
              if count > 0 {
                TimingFilterChip(
                  title: timing.rawValue,
                  count: count,
                  isSelected: selectedTiming == timing,
                  action: { selectedTiming = timing }
                )
              }
            }
          }
          .padding(.horizontal)
        }

        // Supplements by timing or filtered
        let filteredSupplements =
          selectedTiming == nil
          ? plan.supplements : plan.supplements.filter { $0.timing == selectedTiming }

        let sortedSupplements = filteredSupplements.sorted {
          $0.priority.sortOrder < $1.priority.sortOrder
        }

        ForEach(sortedSupplements) { supplement in
          SupplementCard(supplement: supplement) {
            selectedSupplement = supplement
          }
        }

        // Warnings Section
        if !plan.warnings.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Label("Important Warnings", systemImage: "exclamationmark.triangle.fill")
              .font(.headline)
              .foregroundColor(.orange)

            ForEach(plan.warnings, id: \.self) { warning in
              Text("• \(warning)")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .padding()
          .background(Color.orange.opacity(0.1))
          .cornerRadius(12)
          .padding(.horizontal)
        }

        // Interaction Notes
        if !plan.interactionNotes.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Label("Interaction Notes", systemImage: "info.circle.fill")
              .font(.headline)
              .foregroundColor(.blue)

            ForEach(plan.interactionNotes, id: \.self) { note in
              Text("• \(note)")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .padding()
          .background(Color.blue.opacity(0.1))
          .cornerRadius(12)
          .padding(.horizontal)
        }

        Spacer()
          .frame(height: 100)
      }
      .padding(.top)
    }
  }

  // MARK: - No Supplements View

  private var noSupplementsView: some View {
    VStack(spacing: 20) {
      Image(systemName: "pills")
        .font(.system(size: 60))
        .foregroundColor(.secondary)

      Text("No Supplement Plan Yet")
        .font(.headline)

      Text("Generate recommendations from the Dashboard to see your personalized supplement plan.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
  let count: Int
  let priority: SupplementPriority

  var body: some View {
    if count > 0 {
      HStack(spacing: 4) {
        Text("\(count)")
          .fontWeight(.bold)
        Text(priority.rawValue)
          .font(.caption)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(priorityColor.opacity(0.2))
      .foregroundColor(priorityColor)
      .cornerRadius(8)
    }
  }

  private var priorityColor: Color {
    switch priority {
    case .essential: return .red
    case .recommended: return .orange
    case .beneficial: return .blue
    case .optional: return .gray
    }
  }
}

// MARK: - Timing Filter Chip

struct TimingFilterChip: View {
  let title: String
  var count: Int? = nil
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        Text(title)
        if let count = count {
          Text("(\(count))")
            .font(.caption)
        }
      }
      .font(.subheadline)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(isSelected ? Color.accentColor : Color(.systemGray6))
      .foregroundColor(isSelected ? .white : .primary)
      .cornerRadius(20)
    }
  }
}

// MARK: - Supplement Card

struct SupplementCard: View {
  let supplement: SupplementRecommendation
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 12) {
        // Header
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(supplement.name)
              .font(.headline)
              .foregroundColor(.primary)

            Text(supplement.dosageDisplay)
              .font(.subheadline)
              .foregroundColor(.accentColor)
          }

          Spacer()

          PriorityTag(priority: supplement.priority)
        }

        // Timing info
        HStack(spacing: 16) {
          Label(supplement.timing.rawValue, systemImage: supplement.timing.icon)
            .font(.caption)
            .foregroundColor(.secondary)

          Label(
            supplement.withFood ? "With food" : "Empty stomach",
            systemImage: supplement.withFood ? "fork.knife" : "clock"
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }

        // Brief reasoning
        Text(supplement.reasoning)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(2)

        // Benefits preview
        if !supplement.benefits.isEmpty {
          HStack {
            ForEach(supplement.benefits.prefix(3), id: \.self) { benefit in
              Text(benefit)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(4)
            }
          }
        }

        // Tap for more
        HStack {
          Spacer()
          Text("Tap for details")
            .font(.caption2)
            .foregroundColor(.secondary)
          Image(systemName: "chevron.right")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
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

// MARK: - Priority Tag

struct PriorityTag: View {
  let priority: SupplementPriority

  var body: some View {
    Text(priority.rawValue)
      .font(.caption2)
      .fontWeight(.semibold)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(priorityColor.opacity(0.2))
      .foregroundColor(priorityColor)
      .cornerRadius(4)
  }

  private var priorityColor: Color {
    switch priority {
    case .essential: return .red
    case .recommended: return .orange
    case .beneficial: return .blue
    case .optional: return .gray
    }
  }
}

// MARK: - Supplement Detail Sheet

struct SupplementDetailSheet: View {
  @Environment(\.dismiss) private var dismiss
  let supplement: SupplementRecommendation

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text(supplement.name)
                .font(.title)
                .fontWeight(.bold)
              Spacer()
              PriorityTag(priority: supplement.priority)
            }

            if !supplement.alternateNames.isEmpty {
              Text("Also known as: \(supplement.alternateNames.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          // Dosage Card
          VStack(alignment: .leading, spacing: 8) {
            Text("Dosage & Timing")
              .font(.headline)

            HStack(spacing: 20) {
              VStack {
                Text(supplement.dosageDisplay)
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(.accentColor)
                Text("Dosage")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              Divider()
                .frame(height: 40)

              VStack {
                Text(supplement.frequency.rawValue)
                  .font(.subheadline)
                  .fontWeight(.semibold)
                Text("Frequency")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              Divider()
                .frame(height: 40)

              VStack {
                Image(systemName: supplement.timing.icon)
                  .font(.title3)
                Text(supplement.timing.rawValue)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }

            HStack {
              Image(systemName: supplement.withFood ? "fork.knife" : "clock")
              Text(supplement.withFood ? "Take with food" : "Take on empty stomach")
            }
            .font(.caption)
            .foregroundColor(.secondary)
          }
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(12)

          // Reasoning
          DetailSection(title: "Why This Supplement?", icon: "lightbulb.fill") {
            Text(supplement.reasoning)
              .font(.subheadline)
          }

          // Scientific Backing
          if !supplement.scientificBacking.isEmpty {
            DetailSection(title: "Scientific Evidence", icon: "book.fill") {
              Text(supplement.scientificBacking)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          // Benefits
          if !supplement.benefits.isEmpty {
            DetailSection(title: "Benefits", icon: "checkmark.circle.fill") {
              ForEach(supplement.benefits, id: \.self) { benefit in
                HStack(alignment: .top) {
                  Image(systemName: "checkmark")
                    .foregroundColor(.green)
                    .font(.caption)
                  Text(benefit)
                    .font(.subheadline)
                }
              }
            }
          }

          // Side Effects
          if !supplement.potentialSideEffects.isEmpty {
            DetailSection(title: "Potential Side Effects", icon: "exclamationmark.triangle.fill") {
              ForEach(supplement.potentialSideEffects, id: \.self) { effect in
                HStack(alignment: .top) {
                  Image(systemName: "minus")
                    .foregroundColor(.orange)
                    .font(.caption)
                  Text(effect)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
              }
            }
          }

          // Interactions
          if !supplement.interactions.isEmpty {
            DetailSection(title: "Drug Interactions", icon: "pills.fill") {
              ForEach(supplement.interactions, id: \.self) { interaction in
                Text("• \(interaction)")
                  .font(.subheadline)
                  .foregroundColor(.red)
              }
            }
          }

          // Quality Notes
          if let notes = supplement.qualityNotes {
            DetailSection(title: "What to Look For", icon: "magnifyingglass") {
              Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
          }

          // Cost
          if let cost = supplement.estimatedMonthlyCost {
            HStack {
              Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.green)
              Text("Estimated Monthly Cost: \(cost)")
                .font(.subheadline)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
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

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
  let title: String
  let icon: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: icon)
        .font(.headline)
      content
    }
  }
}

// MARK: - Preview

private struct SupplementsPreview: View {
  @State private var recommendation: HealthRecommendation?

  var body: some View {
    SupplementsView(recommendation: recommendation)
      .onAppear {
        let rec = HealthRecommendation(status: .completed)
        rec.supplementPlan = SupplementPlan.sample
        recommendation = rec
      }
  }
}

#Preview {
  SupplementsPreview()
}
