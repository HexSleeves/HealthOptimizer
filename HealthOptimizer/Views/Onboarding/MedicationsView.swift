//
//  MedicationsView.swift
//  HealthOptimizer
//
//  View for collecting current medications and supplements
//

import SwiftUI

// MARK: - Medications View

struct MedicationsView: View {

  @Bindable var viewModel: OnboardingViewModel
  @State private var showAddMedication = false
  @State private var showAddSupplement = false

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        SectionHeader(
          title: "Medications & Supplements",
          subtitle:
            "Tell us what you're currently taking so we can check for interactions and avoid duplications."
        )

        // Important notice
        HStack(spacing: 12) {
          Image(systemName: "info.circle.fill")
            .foregroundColor(.blue)
          Text(
            "This information is crucial for safe supplement recommendations. Some supplements can interact with medications."
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)

        // Current Medications Section
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Current Medications")
              .font(.headline)
            Spacer()
            Button(action: { showAddMedication = true }) {
              Label("Add", systemImage: "plus.circle.fill")
                .font(.subheadline)
            }
          }

          if viewModel.currentMedications.isEmpty {
            Text("No medications added")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.vertical, 20)
          } else {
            ForEach(viewModel.currentMedications) { medication in
              MedicationRow(
                name: medication.name,
                dosage: medication.dosage,
                frequency: medication.frequency.rawValue,
                onDelete: { viewModel.removeMedication(medication) }
              )
            }
          }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)

        // Current Supplements Section
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Current Supplements")
              .font(.headline)
            Spacer()
            Button(action: { showAddSupplement = true }) {
              Label("Add", systemImage: "plus.circle.fill")
                .font(.subheadline)
            }
          }

          if viewModel.currentSupplements.isEmpty {
            Text("No supplements added")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.vertical, 20)
          } else {
            ForEach(viewModel.currentSupplements) { supplement in
              MedicationRow(
                name: supplement.name,
                dosage: supplement.dosage,
                frequency: supplement.frequency.rawValue,
                onDelete: { viewModel.removeSupplement(supplement) }
              )
            }
          }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)

        // Skip hint
        Text("If you're not taking any medications or supplements, you can skip this step.")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)

        Spacer()
          .frame(height: 100)
      }
      .padding(.top)
    }
    .sheet(isPresented: $showAddMedication) {
      AddMedicationSheet(onAdd: { name, dosage, frequency in
        viewModel.addMedication(name: name, dosage: dosage, frequency: frequency)
      })
    }
    .sheet(isPresented: $showAddSupplement) {
      AddSupplementSheet(onAdd: { name, dosage, frequency in
        viewModel.addSupplement(name: name, dosage: dosage, frequency: frequency)
      })
    }
  }
}

// MARK: - Medication Row

struct MedicationRow: View {
  let name: String
  let dosage: String
  let frequency: String
  let onDelete: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(name)
          .font(.subheadline)
          .fontWeight(.medium)

        HStack(spacing: 8) {
          if !dosage.isEmpty {
            Text(dosage)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Text(frequency)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Button(action: onDelete) {
        Image(systemName: "trash")
          .foregroundColor(.red)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(8)
  }
}

// MARK: - Add Medication Sheet

struct AddMedicationSheet: View {
  @Environment(\.dismiss) private var dismiss

  let onAdd: (String, String, MedicationFrequency) -> Void

  @State private var name = ""
  @State private var dosage = ""
  @State private var frequency: MedicationFrequency = .daily

  var body: some View {
    NavigationStack {
      Form {
        Section("Medication Details") {
          TextField("Medication Name", text: $name)
          TextField("Dosage (e.g., 10mg)", text: $dosage)
          Picker("Frequency", selection: $frequency) {
            ForEach(MedicationFrequency.allCases) { freq in
              Text(freq.rawValue).tag(freq)
            }
          }
        }

        Section("Common Medications") {
          ForEach(MedicationCategory.allCases, id: \.rawValue) { category in
            if !category.examples.isEmpty {
              DisclosureGroup(category.rawValue) {
                ForEach(category.examples, id: \.self) { example in
                  Button(action: { name = example }) {
                    Text(example)
                      .foregroundColor(.primary)
                  }
                }
              }
            }
          }
        }
      }
      .navigationTitle("Add Medication")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            onAdd(name, dosage, frequency)
            dismiss()
          }
          .disabled(name.isEmpty)
        }
      }
    }
  }
}

// MARK: - Add Supplement Sheet

struct AddSupplementSheet: View {
  @Environment(\.dismiss) private var dismiss

  let onAdd: (String, String, MedicationFrequency) -> Void

  @State private var name = ""
  @State private var dosage = ""
  @State private var frequency: MedicationFrequency = .daily

  private let commonSupplements = [
    "Vitamin D", "Vitamin C", "Vitamin B12", "Multivitamin",
    "Fish Oil/Omega-3", "Magnesium", "Zinc", "Iron",
    "Calcium", "Probiotics", "Protein Powder", "Creatine",
    "Collagen", "Turmeric/Curcumin", "Melatonin", "Ashwagandha",
  ]

  var body: some View {
    NavigationStack {
      Form {
        Section("Supplement Details") {
          TextField("Supplement Name", text: $name)
          TextField("Dosage (e.g., 1000mg, 5000 IU)", text: $dosage)
          Picker("Frequency", selection: $frequency) {
            ForEach(MedicationFrequency.allCases) { freq in
              Text(freq.rawValue).tag(freq)
            }
          }
        }

        Section("Common Supplements") {
          ForEach(commonSupplements, id: \.self) { supplement in
            Button(action: { name = supplement }) {
              Text(supplement)
                .foregroundColor(.primary)
            }
          }
        }
      }
      .navigationTitle("Add Supplement")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            onAdd(name, dosage, frequency)
            dismiss()
          }
          .disabled(name.isEmpty)
        }
      }
    }
  }
}

// MARK: - Preview

#Preview {
  MedicationsView(viewModel: OnboardingViewModel())
}
