//
//  BasicInfoView.swift
//  HealthOptimizer
//
//  Basic information collection view (age, weight, height)
//

import SwiftUI

// MARK: - Basic Info View

/// View for collecting basic health metrics
struct BasicInfoView: View {

    // MARK: - Properties

    @Bindable var viewModel: OnboardingViewModel

    // For unit conversion display
    @State private var showMetric = true

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                SectionHeader(
                    title: "Basic Information",
                    subtitle: "This information helps us calculate your metabolic needs and create personalized recommendations."
                )

                // Name (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name (optional)")
                        .font(.headline)
                    TextField("How should we call you?", text: $viewModel.displayName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                }
                .padding(.horizontal)

                // Age
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.headline)

                    Stepper(value: $viewModel.age, in: 13...120) {
                        HStack {
                            Text("\(viewModel.age)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("years old")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Biological Sex
                VStack(alignment: .leading, spacing: 8) {
                    Text("Biological Sex")
                        .font(.headline)
                    Text("Used for accurate metabolic calculations")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Biological Sex", selection: $viewModel.biologicalSex) {
                        ForEach(BiologicalSex.allCases) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                // Unit toggle
                HStack {
                    Text("Units")
                        .font(.headline)
                    Spacer()
                    Picker("Units", selection: $showMetric) {
                        Text("Metric").tag(true)
                        Text("Imperial").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                .padding(.horizontal)

                // Height
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Height")
                            .font(.headline)
                        Spacer()
                        Text(heightDisplay)
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }

                    Slider(
                        value: $viewModel.heightCm,
                        in: 100...250,
                        step: 1
                    )
                    .accentColor(.accentColor)

                    HStack {
                        Text("100 cm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("250 cm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Weight")
                            .font(.headline)
                        Spacer()
                        Text(weightDisplay)
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }

                    Slider(
                        value: $viewModel.weightKg,
                        in: 30...200,
                        step: 0.5
                    )
                    .accentColor(.accentColor)

                    HStack {
                        Text("30 kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("200 kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // BMI Display
                BMICard(bmi: viewModel.calculatedBMI, category: viewModel.bmiCategory)
                    .padding(.horizontal)

                // Optional: Body fat percentage
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Body Fat Percentage")
                            .font(.subheadline)

                        HStack {
                            TextField("e.g., 20", value: $viewModel.bodyFatPercentage, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            Text("%")
                                .foregroundColor(.secondary)
                        }

                        Text("Waist Circumference")
                            .font(.subheadline)

                        HStack {
                            TextField("e.g., 85", value: $viewModel.waistCircumferenceCm, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            Text("cm")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Label("Additional Measurements (Optional)", systemImage: "ruler")
                        .font(.subheadline)
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

    // MARK: - Computed Properties

    private var heightDisplay: String {
        if showMetric {
            return String(format: "%.0f cm", viewModel.heightCm)
        } else {
            let totalInches = viewModel.heightCm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\""
        }
    }

    private var weightDisplay: String {
        if showMetric {
            return String(format: "%.1f kg", viewModel.weightKg)
        } else {
            let lbs = viewModel.weightKg * 2.205
            return String(format: "%.1f lbs", lbs)
        }
    }
}

// MARK: - BMI Card

/// Card displaying BMI calculation and category
struct BMICard: View {
    let bmi: Double
    let category: BMICategory

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Your BMI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", bmi))
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                Text(category.rawValue)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(categoryColor.opacity(0.2))
                    .foregroundColor(categoryColor)
                    .cornerRadius(8)
            }

            // BMI scale visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient
                    LinearGradient(
                        colors: [.blue, .green, .yellow, .orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .cornerRadius(4)

                    // Indicator
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(radius: 2)
                        .offset(x: indicatorPosition(in: geometry.size.width))
                }
            }
            .frame(height: 16)

            // Scale labels
            HStack {
                Text("15")
                Spacer()
                Text("18.5")
                Spacer()
                Text("25")
                Spacer()
                Text("30")
                Spacer()
                Text("40")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var categoryColor: Color {
        switch category {
        case .underweight: return .blue
        case .normal: return .green
        case .overweight: return .orange
        case .obese: return .red
        }
    }

    private func indicatorPosition(in width: CGFloat) -> CGFloat {
        // Map BMI 15-40 to 0-width
        let clampedBMI = min(max(bmi, 15), 40)
        let normalized = (clampedBMI - 15) / 25  // 15 to 40 range = 25
        return (width - 16) * normalized
    }
}

// MARK: - Section Header

/// Reusable section header with title and subtitle
struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    BasicInfoView(viewModel: OnboardingViewModel())
}
