//
//  ProgressView.swift
//  HealthOptimizer
//
//  Progress tracking and history view
//

import Charts
import SwiftData
import SwiftUI

// MARK: - Progress View

struct ProgressTrackingView: View {

  // MARK: - Environment

  @Environment(\.modelContext) private var modelContext

  // MARK: - Queries

  @Query(sort: \ProgressEntry.date, order: .reverse)
  private var allEntries: [ProgressEntry]

  // MARK: - State

  @State private var showingAddEntry = false
  @State private var selectedTimeRange: TimeRange = .month
  @State private var selectedMetric: ProgressMetric = .weight

  // MARK: - Computed Properties

  private var filteredEntries: [ProgressEntry] {
    let cutoffDate = selectedTimeRange.cutoffDate
    return allEntries.filter { $0.date >= cutoffDate }.reversed()
  }

  private var latestEntry: ProgressEntry? {
    allEntries.first
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          // Quick Stats Cards
          quickStatsSection

          // Chart Section
          chartSection

          // Recent Entries
          recentEntriesSection
        }
        .padding()
      }
      .navigationTitle("Progress")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { showingAddEntry = true }) {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
          }
        }
      }
      .sheet(isPresented: $showingAddEntry) {
        AddProgressEntryView()
      }
    }
  }

  // MARK: - Quick Stats Section

  @ViewBuilder
  private var quickStatsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Current Stats")
        .font(.headline)

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCard(
          title: "Weight",
          value: latestEntry?.weight.map { String(format: "%.1f", $0) } ?? "--",
          unit: "kg",
          icon: "scalemass.fill",
          color: .blue,
          trend: calculateTrend(for: \.weight)
        )

        StatCard(
          title: "Body Fat",
          value: latestEntry?.bodyFatPercentage.map { String(format: "%.1f", $0) } ?? "--",
          unit: "%",
          icon: "percent",
          color: .orange,
          trend: calculateTrend(for: \.bodyFatPercentage)
        )

        StatCard(
          title: "Energy",
          value: latestEntry?.energyLevel.map { "\($0)/5" } ?? "--",
          unit: "",
          icon: "bolt.fill",
          color: .yellow,
          trend: nil
        )

        StatCard(
          title: "Mood",
          value: latestEntry?.mood.map { "\($0)/5" } ?? "--",
          unit: "",
          icon: "face.smiling.fill",
          color: .green,
          trend: nil
        )
      }
    }
  }

  // MARK: - Chart Section

  @ViewBuilder
  private var chartSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Trends")
          .font(.headline)

        Spacer()

        Picker("Time Range", selection: $selectedTimeRange) {
          ForEach(TimeRange.allCases, id: \.self) { range in
            Text(range.title).tag(range)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
      }

      Picker("Metric", selection: $selectedMetric) {
        ForEach(ProgressMetric.allCases, id: \.self) { metric in
          Text(metric.title).tag(metric)
        }
      }
      .pickerStyle(.segmented)

      if filteredEntries.isEmpty {
        emptyChartPlaceholder
      } else {
        chartView
          .frame(height: 200)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
  }

  @ViewBuilder
  private var chartView: some View {
    let data = chartData
    if data.isEmpty {
      emptyChartPlaceholder
    } else {
      Chart(data) { point in
        LineMark(
          x: .value("Date", point.date),
          y: .value(selectedMetric.title, point.value)
        )
        .foregroundStyle(selectedMetric.color.gradient)
        .interpolationMethod(.catmullRom)

        PointMark(
          x: .value("Date", point.date),
          y: .value(selectedMetric.title, point.value)
        )
        .foregroundStyle(selectedMetric.color)
      }
      .chartXAxis {
        AxisMarks(values: .automatic(desiredCount: 5)) { _ in
          AxisGridLine()
          AxisValueLabel(format: .dateTime.month(.abbreviated).day())
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading)
      }
    }
  }

  private var chartData: [ChartDataPoint] {
    filteredEntries.compactMap { entry in
      guard let value = selectedMetric.value(from: entry) else { return nil }
      return ChartDataPoint(date: entry.date, value: value)
    }
  }

  @ViewBuilder
  private var emptyChartPlaceholder: some View {
    VStack(spacing: 8) {
      Image(systemName: "chart.line.uptrend.xyaxis")
        .font(.largeTitle)
        .foregroundColor(.secondary)
      Text("No data for this period")
        .font(.subheadline)
        .foregroundColor(.secondary)
      Text("Add entries to see your trends")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(height: 200)
    .frame(maxWidth: .infinity)
  }

  // MARK: - Recent Entries Section

  @ViewBuilder
  private var recentEntriesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Recent Entries")
        .font(.headline)

      if allEntries.isEmpty {
        emptyEntriesPlaceholder
      } else {
        ForEach(allEntries.prefix(10)) { entry in
          ProgressEntryRow(entry: entry)
        }
      }
    }
  }

  @ViewBuilder
  private var emptyEntriesPlaceholder: some View {
    VStack(spacing: 16) {
      Image(systemName: "chart.bar.doc.horizontal")
        .font(.system(size: 50))
        .foregroundColor(.secondary)

      Text("No Progress Entries Yet")
        .font(.headline)

      Text("Start tracking your progress by adding your first entry.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button(action: { showingAddEntry = true }) {
        Label("Add First Entry", systemImage: "plus.circle.fill")
          .font(.headline)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(.vertical, 40)
    .frame(maxWidth: .infinity)
  }

  // MARK: - Helper Methods

  private func calculateTrend(for keyPath: KeyPath<ProgressEntry, Double?>) -> Double? {
    let recentEntries = Array(allEntries.prefix(7))
    guard recentEntries.count >= 2 else { return nil }

    let values = recentEntries.compactMap { $0[keyPath: keyPath] }
    guard values.count >= 2 else { return nil }

    let latest = values[0]
    let previous = values[values.count - 1]
    return latest - previous
  }
}

// MARK: - Stat Card

struct StatCard: View {
  let title: String
  let value: String
  let unit: String
  let icon: String
  let color: Color
  let trend: Double?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(color)
        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(value)
          .font(.title2)
          .fontWeight(.semibold)
        Text(unit)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      if let trend = trend {
        HStack(spacing: 2) {
          Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
          Text(String(format: "%.1f", abs(trend)))
        }
        .font(.caption2)
        .foregroundColor(trend >= 0 ? .green : .red)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
  }
}

// MARK: - Progress Entry Row

struct ProgressEntryRow: View {
  let entry: ProgressEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
          .font(.subheadline)
          .fontWeight(.medium)

        Spacer()

        if let mood = entry.mood {
          HStack(spacing: 2) {
            Image(systemName: moodIcon(mood))
            Text("\(mood)")
          }
          .font(.caption)
          .foregroundColor(moodColor(mood))
        }
      }

      HStack(spacing: 16) {
        if let weight = entry.weight {
          Label(String(format: "%.1f kg", weight), systemImage: "scalemass")
        }
        if let bodyFat = entry.bodyFatPercentage {
          Label(String(format: "%.1f%%", bodyFat), systemImage: "percent")
        }
        if let energy = entry.energyLevel {
          Label("\(energy)/5", systemImage: "bolt.fill")
        }
      }
      .font(.caption)
      .foregroundColor(.secondary)

      if let notes = entry.notes, !notes.isEmpty {
        Text(notes)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(2)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
  }

  private func moodIcon(_ mood: Int) -> String {
    switch mood {
    case 1: return "face.smiling.inverse"
    case 2: return "face.smiling"
    case 3: return "face.smiling"
    case 4: return "face.smiling.fill"
    case 5: return "face.smiling.fill"
    default: return "face.smiling"
    }
  }

  private func moodColor(_ mood: Int) -> Color {
    switch mood {
    case 1: return .red
    case 2: return .orange
    case 3: return .yellow
    case 4: return .green
    case 5: return .green
    default: return .gray
    }
  }
}

// MARK: - Add Progress Entry View

struct AddProgressEntryView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var date = Date()
  @State private var weight: String = ""
  @State private var bodyFatPercentage: String = ""
  @State private var waistCircumference: String = ""
  @State private var mood: Int = 3
  @State private var energyLevel: Int = 3
  @State private var sleepHours: String = ""
  @State private var workoutsCompleted: String = ""
  @State private var supplementsAdherence: Double = 80
  @State private var dietAdherence: Double = 80
  @State private var notes: String = ""

  var body: some View {
    NavigationStack {
      Form {
        Section("Date") {
          DatePicker("Entry Date", selection: $date, displayedComponents: .date)
        }

        Section("Measurements") {
          HStack {
            Text("Weight")
            Spacer()
            TextField("kg", text: $weight)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
              .frame(width: 80)
            Text("kg")
              .foregroundColor(.secondary)
          }

          HStack {
            Text("Body Fat")
            Spacer()
            TextField("%", text: $bodyFatPercentage)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
              .frame(width: 80)
            Text("%")
              .foregroundColor(.secondary)
          }

          HStack {
            Text("Waist")
            Spacer()
            TextField("cm", text: $waistCircumference)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
              .frame(width: 80)
            Text("cm")
              .foregroundColor(.secondary)
          }
        }

        Section("How are you feeling?") {
          VStack(alignment: .leading, spacing: 8) {
            Text("Mood: \(moodDescription(mood))")
            Picker("Mood", selection: $mood) {
              ForEach(1...5, id: \.self) { level in
                Text("\(level)").tag(level)
              }
            }
            .pickerStyle(.segmented)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Energy Level: \(energyDescription(energyLevel))")
            Picker("Energy", selection: $energyLevel) {
              ForEach(1...5, id: \.self) { level in
                Text("\(level)").tag(level)
              }
            }
            .pickerStyle(.segmented)
          }

          HStack {
            Text("Sleep")
            Spacer()
            TextField("hours", text: $sleepHours)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
              .frame(width: 80)
            Text("hrs")
              .foregroundColor(.secondary)
          }
        }

        Section("Activity") {
          HStack {
            Text("Workouts Completed")
            Spacer()
            TextField("0", text: $workoutsCompleted)
              .keyboardType(.numberPad)
              .multilineTextAlignment(.trailing)
              .frame(width: 60)
          }
        }

        Section("Adherence") {
          VStack(alignment: .leading) {
            Text("Supplements: \(Int(supplementsAdherence))%")
            Slider(value: $supplementsAdherence, in: 0...100, step: 5)
          }

          VStack(alignment: .leading) {
            Text("Diet: \(Int(dietAdherence))%")
            Slider(value: $dietAdherence, in: 0...100, step: 5)
          }
        }

        Section("Notes") {
          TextEditor(text: $notes)
            .frame(minHeight: 80)
        }
      }
      .navigationTitle("Log Progress")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { saveEntry() }
            .fontWeight(.semibold)
        }
      }
    }
  }

  private func saveEntry() {
    let entry = ProgressEntry(
      date: date,
      weight: Double(weight),
      bodyFatPercentage: Double(bodyFatPercentage),
      waistCircumference: Double(waistCircumference),
      notes: notes.isEmpty ? nil : notes,
      mood: mood,
      energyLevel: energyLevel,
      sleepHours: Double(sleepHours),
      workoutsCompleted: Int(workoutsCompleted),
      supplementsAdherence: Int(supplementsAdherence),
      dietAdherence: Int(dietAdherence)
    )

    modelContext.insert(entry)

    do {
      try modelContext.save()

      // Sync to cloud
      Task {
        await SyncService.shared.syncProgressEntry(entry)
      }

      dismiss()
    } catch {
      print("Error saving progress entry: \(error)")
    }
  }

  private func moodDescription(_ level: Int) -> String {
    switch level {
    case 1: return "😞 Very Low"
    case 2: return "😕 Low"
    case 3: return "😐 Neutral"
    case 4: return "🙂 Good"
    case 5: return "😄 Great!"
    default: return "Unknown"
    }
  }

  private func energyDescription(_ level: Int) -> String {
    switch level {
    case 1: return "Exhausted"
    case 2: return "Tired"
    case 3: return "Normal"
    case 4: return "Energized"
    case 5: return "Full of Energy!"
    default: return "Unknown"
    }
  }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
  case week = "1W"
  case month = "1M"
  case threeMonths = "3M"
  case year = "1Y"

  var title: String { rawValue }

  var cutoffDate: Date {
    let calendar = Calendar.current
    switch self {
    case .week:
      return calendar.date(byAdding: .day, value: -7, to: Date())!
    case .month:
      return calendar.date(byAdding: .month, value: -1, to: Date())!
    case .threeMonths:
      return calendar.date(byAdding: .month, value: -3, to: Date())!
    case .year:
      return calendar.date(byAdding: .year, value: -1, to: Date())!
    }
  }
}

enum ProgressMetric: String, CaseIterable {
  case weight
  case bodyFat
  case energy
  case mood
  case sleep

  var title: String {
    switch self {
    case .weight: return "Weight"
    case .bodyFat: return "Body Fat"
    case .energy: return "Energy"
    case .mood: return "Mood"
    case .sleep: return "Sleep"
    }
  }

  var color: Color {
    switch self {
    case .weight: return .blue
    case .bodyFat: return .orange
    case .energy: return .yellow
    case .mood: return .green
    case .sleep: return .purple
    }
  }

  func value(from entry: ProgressEntry) -> Double? {
    switch self {
    case .weight: return entry.weight
    case .bodyFat: return entry.bodyFatPercentage
    case .energy: return entry.energyLevel.map { Double($0) }
    case .mood: return entry.mood.map { Double($0) }
    case .sleep: return entry.sleepHours
    }
  }
}

struct ChartDataPoint: Identifiable {
  let id = UUID()
  let date: Date
  let value: Double
}

// MARK: - Preview

#Preview {
  ProgressTrackingView()
    .modelContainer(for: ProgressEntry.self, inMemory: true)
}
