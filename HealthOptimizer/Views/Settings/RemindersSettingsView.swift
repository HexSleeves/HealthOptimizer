//
//  RemindersSettingsView.swift
//  HealthOptimizer
//
//  Settings view for managing notifications and reminders
//

import SwiftUI

// MARK: - Reminders Settings View

struct RemindersSettingsView: View {

  // MARK: - Properties

  @StateObject private var notificationService = NotificationService.shared
  @State private var showingAuthorizationAlert = false

  // MARK: - Body

  var body: some View {
    List {
      // Authorization Section
      if !notificationService.isAuthorized {
        authorizationSection
      }

      // Supplement Reminders
      supplementRemindersSection

      // Workout Reminders
      workoutRemindersSection

      // Progress Reminders
      progressRemindersSection

      // Hydration Reminders
      hydrationRemindersSection
    }
    .navigationTitle("Reminders")
    .task {
      await notificationService.checkAuthorizationStatus()
    }
    .alert("Notifications Disabled", isPresented: $showingAuthorizationAlert) {
      Button("Open Settings") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Please enable notifications in Settings to receive reminders.")
    }
  }

  // MARK: - Authorization Section

  @ViewBuilder
  private var authorizationSection: some View {
    Section {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: "bell.badge")
            .font(.title)
            .foregroundColor(.orange)

          VStack(alignment: .leading) {
            Text("Enable Notifications")
              .font(.headline)
            Text("Get reminders for supplements, workouts, and more")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Button(action: requestAuthorization) {
          Text("Enable Notifications")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
      }
      .padding(.vertical, 8)
    }
  }

  // MARK: - Supplement Reminders Section

  @ViewBuilder
  private var supplementRemindersSection: some View {
    Section {
      Toggle("Supplement Reminders", isOn: Binding(
        get: { notificationService.supplementRemindersEnabled },
        set: { newValue in
          if newValue && !notificationService.isAuthorized {
            showingAuthorizationAlert = true
          } else {
            notificationService.supplementRemindersEnabled = newValue
          }
        }
      ))

      if notificationService.supplementRemindersEnabled {
        NavigationLink {
          SupplementReminderTimesView()
        } label: {
          HStack {
            Text("Reminder Times")
            Spacer()
            Text(formatReminderTimes(notificationService.supplementReminderTimes))
              .foregroundColor(.secondary)
          }
        }
      }
    } header: {
      Label("Supplements", systemImage: "pills.fill")
    } footer: {
      Text("Get reminded to take your supplements at specific times each day.")
    }
  }

  // MARK: - Workout Reminders Section

  @ViewBuilder
  private var workoutRemindersSection: some View {
    Section {
      Toggle("Workout Reminders", isOn: Binding(
        get: { notificationService.workoutRemindersEnabled },
        set: { newValue in
          if newValue && !notificationService.isAuthorized {
            showingAuthorizationAlert = true
          } else {
            notificationService.workoutRemindersEnabled = newValue
          }
        }
      ))

      if notificationService.workoutRemindersEnabled {
        Picker("Reminder Time", selection: Binding(
          get: { notificationService.workoutReminderTime },
          set: { notificationService.workoutReminderTime = $0 }
        )) {
          ForEach(5..<22, id: \.self) { hour in
            Text(formatHour(hour)).tag(hour)
          }
        }
      }
    } header: {
      Label("Workouts", systemImage: "dumbbell.fill")
    } footer: {
      Text("Get a daily reminder to complete your workout.")
    }
  }

  // MARK: - Progress Reminders Section

  @ViewBuilder
  private var progressRemindersSection: some View {
    Section {
      Toggle("Weekly Check-in", isOn: Binding(
        get: { notificationService.progressRemindersEnabled },
        set: { newValue in
          if newValue && !notificationService.isAuthorized {
            showingAuthorizationAlert = true
          } else {
            notificationService.progressRemindersEnabled = newValue
          }
        }
      ))

      if notificationService.progressRemindersEnabled {
        Picker("Check-in Day", selection: Binding(
          get: { notificationService.progressReminderDay },
          set: { notificationService.progressReminderDay = $0 }
        )) {
          Text("Sunday").tag(1)
          Text("Monday").tag(2)
          Text("Tuesday").tag(3)
          Text("Wednesday").tag(4)
          Text("Thursday").tag(5)
          Text("Friday").tag(6)
          Text("Saturday").tag(7)
        }
      }
    } header: {
      Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
    } footer: {
      Text("Get a weekly reminder to log your progress and measurements.")
    }
  }

  // MARK: - Hydration Reminders Section

  @ViewBuilder
  private var hydrationRemindersSection: some View {
    Section {
      Toggle("Hydration Reminders", isOn: Binding(
        get: { notificationService.hydrationRemindersEnabled },
        set: { newValue in
          if newValue && !notificationService.isAuthorized {
            showingAuthorizationAlert = true
          } else {
            notificationService.hydrationRemindersEnabled = newValue
          }
        }
      ))

      if notificationService.hydrationRemindersEnabled {
        Picker("Start Time", selection: Binding(
          get: { notificationService.hydrationStartHour },
          set: { notificationService.hydrationStartHour = $0 }
        )) {
          ForEach(5..<20, id: \.self) { hour in
            Text(formatHour(hour)).tag(hour)
          }
        }

        Picker("End Time", selection: Binding(
          get: { notificationService.hydrationEndHour },
          set: { notificationService.hydrationEndHour = $0 }
        )) {
          ForEach(12..<24, id: \.self) { hour in
            Text(formatHour(hour)).tag(hour)
          }
        }

        Picker("Frequency", selection: Binding(
          get: { notificationService.hydrationIntervalHours },
          set: { notificationService.hydrationIntervalHours = $0 }
        )) {
          Text("Every hour").tag(1)
          Text("Every 2 hours").tag(2)
          Text("Every 3 hours").tag(3)
          Text("Every 4 hours").tag(4)
        }
      }
    } header: {
      Label("Hydration", systemImage: "drop.fill")
    } footer: {
      Text("Get regular reminders to drink water throughout the day.")
    }
  }

  // MARK: - Helper Methods

  private func requestAuthorization() {
    Task {
      let granted = await notificationService.requestAuthorization()
      if !granted {
        showingAuthorizationAlert = true
      }
    }
  }

  private func formatHour(_ hour: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    var components = DateComponents()
    components.hour = hour
    components.minute = 0
    let date = Calendar.current.date(from: components) ?? Date()
    return formatter.string(from: date)
  }

  private func formatReminderTimes(_ hours: [Int]) -> String {
    hours.map { formatHour($0) }.joined(separator: ", ")
  }
}

// MARK: - Supplement Reminder Times View

struct SupplementReminderTimesView: View {
  @StateObject private var notificationService = NotificationService.shared
  @State private var times: [Int] = []
  @State private var showingAddTime = false
  @State private var newTimeHour = 8

  var body: some View {
    List {
      Section {
        ForEach(times.sorted(), id: \.self) { hour in
          HStack {
            Text(formatHour(hour))
            Spacer()
          }
        }
        .onDelete(perform: deleteTime)

        Button(action: { showingAddTime = true }) {
          Label("Add Time", systemImage: "plus.circle.fill")
        }
      } footer: {
        Text("Add multiple times to get reminded throughout the day.")
      }
    }
    .navigationTitle("Reminder Times")
    .onAppear {
      times = notificationService.supplementReminderTimes
    }
    .onChange(of: times) { _, newTimes in
      notificationService.supplementReminderTimes = newTimes
    }
    .sheet(isPresented: $showingAddTime) {
      NavigationStack {
        Form {
          Picker("Time", selection: $newTimeHour) {
            ForEach(5..<24, id: \.self) { hour in
              Text(formatHour(hour)).tag(hour)
            }
          }
          .pickerStyle(.wheel)
        }
        .navigationTitle("Add Reminder Time")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { showingAddTime = false }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Add") {
              if !times.contains(newTimeHour) {
                times.append(newTimeHour)
              }
              showingAddTime = false
            }
          }
        }
      }
      .presentationDetents([.medium])
    }
  }

  private func deleteTime(at offsets: IndexSet) {
    let sortedTimes = times.sorted()
    for index in offsets {
      if let idx = times.firstIndex(of: sortedTimes[index]) {
        times.remove(at: idx)
      }
    }
  }

  private func formatHour(_ hour: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    var components = DateComponents()
    components.hour = hour
    components.minute = 0
    let date = Calendar.current.date(from: components) ?? Date()
    return formatter.string(from: date)
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    RemindersSettingsView()
  }
}
