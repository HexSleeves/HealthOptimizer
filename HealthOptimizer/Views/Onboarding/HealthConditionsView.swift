//
//  HealthConditionsView.swift
//  HealthOptimizer
//
//  View for collecting health conditions and medical history
//

import SwiftUI

// MARK: - Health Conditions View

struct HealthConditionsView: View {

  @Bindable var viewModel: OnboardingViewModel
  @State private var expandedCategory: HealthConditionCategory?

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        SectionHeader(
          title: "Health Conditions",
          subtitle:
            "Select any conditions you currently have or have been diagnosed with. This helps us avoid contraindicated supplements and exercises."
        )

        // Warning banner
        HStack(spacing: 12) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
          Text(
            "Always consult your healthcare provider before starting new supplements or exercise programs."
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)

        // Condition categories
        ForEach(HealthConditionCategory.allCases) { category in
          ConditionCategorySection(
            category: category,
            selectedConditions: $viewModel.selectedConditions,
            isExpanded: expandedCategory == category,
            onTap: {
              withAnimation(.easeInOut(duration: 0.2)) {
                expandedCategory = expandedCategory == category ? nil : category
              }
            },
            onToggle: viewModel.toggleCondition
          )
        }

        // Allergies section
        VStack(alignment: .leading, spacing: 12) {
          Text("Allergies")
            .font(.headline)
          Text("List any allergies (especially to foods, medications, or supplements)")
            .font(.caption)
            .foregroundColor(.secondary)

          HStack {
            TextField("Add an allergy", text: $viewModel.newAllergy)
              .textFieldStyle(.roundedBorder)
              .submitLabel(.done)
              .onSubmit(viewModel.addAllergy)

            Button(action: viewModel.addAllergy) {
              Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            }
            .disabled(viewModel.newAllergy.isEmpty)
          }

          // Allergy chips
          if !viewModel.allergies.isEmpty {
            FlowLayout(spacing: 8) {
              ForEach(viewModel.allergies, id: \.self) { allergy in
                HStack(spacing: 4) {
                  Text(allergy)
                    .font(.subheadline)
                  Button(action: { viewModel.removeAllergy(allergy) }) {
                    Image(systemName: "xmark.circle.fill")
                      .font(.caption)
                  }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(16)
              }
            }
          }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)

        // Family history notes
        VStack(alignment: .leading, spacing: 8) {
          Text("Family Medical History (Optional)")
            .font(.headline)
          Text("Note any significant conditions in your immediate family")
            .font(.caption)
            .foregroundColor(.secondary)

          TextEditor(text: $viewModel.familyHistoryNotes)
            .frame(minHeight: 80)
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
}

// MARK: - Condition Category Section

struct ConditionCategorySection: View {
  let category: HealthConditionCategory
  @Binding var selectedConditions: Set<HealthCondition>
  let isExpanded: Bool
  let onTap: () -> Void
  let onToggle: (HealthCondition) -> Void

  var selectedCount: Int {
    category.conditions.filter { selectedConditions.contains($0) }.count
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header
      Button(action: onTap) {
        HStack {
          Image(systemName: category.icon)
            .foregroundColor(.accentColor)
            .frame(width: 24)

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
          ForEach(category.conditions) { condition in
            Button(action: { onToggle(condition) }) {
              HStack {
                Image(
                  systemName: selectedConditions.contains(condition)
                    ? "checkmark.circle.fill" : "circle"
                )
                .foregroundColor(selectedConditions.contains(condition) ? .accentColor : .secondary)

                Text(condition.rawValue)
                  .foregroundColor(.primary)

                Spacer()
              }
              .padding(.horizontal)
              .padding(.vertical, 12)
            }

            if condition != category.conditions.last {
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

// MARK: - Flow Layout

/// Layout that wraps items to multiple lines
struct FlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
    return result.size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
    for (index, subview) in subviews.enumerated() {
      subview.place(
        at: CGPoint(
          x: bounds.minX + result.positions[index].x,
          y: bounds.minY + result.positions[index].y),
        proposal: .unspecified)
    }
  }

  struct FlowResult {
    var size: CGSize = .zero
    var positions: [CGPoint] = []

    init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
      var x: CGFloat = 0
      var y: CGFloat = 0
      var rowHeight: CGFloat = 0

      for subview in subviews {
        let size = subview.sizeThatFits(.unspecified)

        if x + size.width > width && x > 0 {
          x = 0
          y += rowHeight + spacing
          rowHeight = 0
        }

        positions.append(CGPoint(x: x, y: y))
        rowHeight = max(rowHeight, size.height)
        x += size.width + spacing
      }

      self.size = CGSize(width: width, height: y + rowHeight)
    }
  }
}

// MARK: - Preview

#Preview {
  HealthConditionsView(viewModel: OnboardingViewModel())
}
