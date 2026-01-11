//
//  NotificationService.swift
//  HealthOptimizer
//
//  Local notification service for reminders
//

import Foundation
import UserNotifications

// MARK: - Notification Service

/// Service for managing local notifications and reminders
@MainActor
@Observable
final class NotificationService {

  // MARK: - Singleton

  static let shared = NotificationService()

  // MARK: - Observable Properties

  var isAuthorized = false
  var authorizationStatus: UNAuthorizationStatus = .notDetermined

  // MARK: - Constants

  private enum NotificationCategory {
    static let supplement = "SUPPLEMENT_REMINDER"
    static let workout = "WORKOUT_REMINDER"
    static let progress = "PROGRESS_REMINDER"
    static let hydration = "HYDRATION_REMINDER"
  }

  private enum NotificationAction {
    static let complete = "COMPLETE_ACTION"
    static let snooze = "SNOOZE_ACTION"
    static let skip = "SKIP_ACTION"
  }

  // MARK: - UserDefaults Keys

  private enum DefaultsKey {
    static let supplementRemindersEnabled = "supplementRemindersEnabled"
    static let workoutRemindersEnabled = "workoutRemindersEnabled"
    static let progressRemindersEnabled = "progressRemindersEnabled"
    static let hydrationRemindersEnabled = "hydrationRemindersEnabled"
    static let supplementReminderTimes = "supplementReminderTimes"
    static let workoutReminderTime = "workoutReminderTime"
    static let progressReminderDay = "progressReminderDay"
    static let hydrationStartHour = "hydrationStartHour"
    static let hydrationEndHour = "hydrationEndHour"
    static let hydrationIntervalHours = "hydrationIntervalHours"
  }

  // MARK: - Settings

  var supplementRemindersEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: DefaultsKey.supplementRemindersEnabled) }
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.supplementRemindersEnabled)
      Task { await updateSupplementReminders() }
    }
  }

  var workoutRemindersEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: DefaultsKey.workoutRemindersEnabled) }
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.workoutRemindersEnabled)
      Task { await updateWorkoutReminders() }
    }
  }

  var progressRemindersEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: DefaultsKey.progressRemindersEnabled) }
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.progressRemindersEnabled)
      Task { await updateProgressReminders() }
    }
  }

  var hydrationRemindersEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: DefaultsKey.hydrationRemindersEnabled) }
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.hydrationRemindersEnabled)
      Task { await updateHydrationReminders() }
    }
  }

  /// Supplement reminder times (stored as array of hour values, e.g., [8, 12, 20])
  var supplementReminderTimes: [Int] {
    get {
      let times = UserDefaults.standard.array(forKey: DefaultsKey.supplementReminderTimes) as? [Int]
      return times ?? [8, 20]  // Default: 8 AM and 8 PM
    }
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.supplementReminderTimes)
      Task { await updateSupplementReminders() }
    }
  }

  /// Workout reminder time (hour of day)
  var workoutReminderTime: Int {
    get { UserDefaults.standard.integer(forKey: DefaultsKey.workoutReminderTime).nonZeroOr(17) }  // Default: 5 PM
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.workoutReminderTime)
      Task { await updateWorkoutReminders() }
    }
  }

  /// Day of week for progress reminder (1 = Sunday, 7 = Saturday)
  var progressReminderDay: Int {
    get { UserDefaults.standard.integer(forKey: DefaultsKey.progressReminderDay).nonZeroOr(1) }  // Default: Sunday
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.progressReminderDay)
      Task { await updateProgressReminders() }
    }
  }

  /// Hydration reminder start hour
  var hydrationStartHour: Int {
    get { UserDefaults.standard.integer(forKey: DefaultsKey.hydrationStartHour).nonZeroOr(8) }  // Default: 8 AM
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.hydrationStartHour)
      Task { await updateHydrationReminders() }
    }
  }

  /// Hydration reminder end hour
  var hydrationEndHour: Int {
    get { UserDefaults.standard.integer(forKey: DefaultsKey.hydrationEndHour).nonZeroOr(20) }  // Default: 8 PM
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.hydrationEndHour)
      Task { await updateHydrationReminders() }
    }
  }

  /// Hours between hydration reminders
  var hydrationIntervalHours: Int {
    get { UserDefaults.standard.integer(forKey: DefaultsKey.hydrationIntervalHours).nonZeroOr(2) }  // Default: every 2 hours
    set {
      UserDefaults.standard.set(newValue, forKey: DefaultsKey.hydrationIntervalHours)
      Task { await updateHydrationReminders() }
    }
  }

  // MARK: - Initialization

  private init() {
    Task {
      await checkAuthorizationStatus()
      await registerCategories()
    }
  }

  // MARK: - Authorization

  /// Request notification authorization from the user
  func requestAuthorization() async -> Bool {
    do {
      let options: UNAuthorizationOptions = [.alert, .badge, .sound]
      let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
      await checkAuthorizationStatus()
      return granted
    } catch {
      print("[NotificationService] Authorization request failed: \(error)")
      return false
    }
  }

  /// Check current authorization status
  func checkAuthorizationStatus() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    authorizationStatus = settings.authorizationStatus
    isAuthorized = settings.authorizationStatus == .authorized
  }

  // MARK: - Category Registration

  /// Register notification categories and actions
  private func registerCategories() async {
    let completeAction = UNNotificationAction(
      identifier: NotificationAction.complete,
      title: "Done",
      options: [.foreground]
    )

    let snoozeAction = UNNotificationAction(
      identifier: NotificationAction.snooze,
      title: "Snooze 30 min",
      options: []
    )

    let skipAction = UNNotificationAction(
      identifier: NotificationAction.skip,
      title: "Skip",
      options: [.destructive]
    )

    let supplementCategory = UNNotificationCategory(
      identifier: NotificationCategory.supplement,
      actions: [completeAction, snoozeAction, skipAction],
      intentIdentifiers: []
    )

    let workoutCategory = UNNotificationCategory(
      identifier: NotificationCategory.workout,
      actions: [completeAction, snoozeAction, skipAction],
      intentIdentifiers: []
    )

    let progressCategory = UNNotificationCategory(
      identifier: NotificationCategory.progress,
      actions: [completeAction, snoozeAction],
      intentIdentifiers: []
    )

    let hydrationCategory = UNNotificationCategory(
      identifier: NotificationCategory.hydration,
      actions: [completeAction, snoozeAction],
      intentIdentifiers: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([
      supplementCategory,
      workoutCategory,
      progressCategory,
      hydrationCategory
    ])
  }

  // MARK: - Supplement Reminders

  /// Update supplement reminders based on current settings
  func updateSupplementReminders() async {
    // Remove existing supplement reminders
    await removeNotifications(withPrefix: "supplement_")

    guard supplementRemindersEnabled && isAuthorized else { return }

    for hour in supplementReminderTimes {
      let content = UNMutableNotificationContent()
      content.title = "Supplement Reminder"
      content.body = "Time to take your supplements!"
      content.sound = .default
      content.categoryIdentifier = NotificationCategory.supplement

      var dateComponents = DateComponents()
      dateComponents.hour = hour
      dateComponents.minute = 0

      let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
      let request = UNNotificationRequest(
        identifier: "supplement_\(hour)",
        content: content,
        trigger: trigger
      )

      do {
        try await UNUserNotificationCenter.current().add(request)
        print("[NotificationService] Scheduled supplement reminder at \(hour):00")
      } catch {
        print("[NotificationService] Failed to schedule supplement reminder: \(error)")
      }
    }
  }

  /// Schedule a reminder for a specific supplement
  func scheduleSupplementReminder(name: String, hour: Int, minute: Int = 0) async {
    guard isAuthorized else { return }

    let content = UNMutableNotificationContent()
    content.title = "Supplement Reminder"
    content.body = "Time to take \(name)"
    content.sound = .default
    content.categoryIdentifier = NotificationCategory.supplement

    var dateComponents = DateComponents()
    dateComponents.hour = hour
    dateComponents.minute = minute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let identifier = "supplement_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(hour)_\(minute)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    do {
      try await UNUserNotificationCenter.current().add(request)
      print("[NotificationService] Scheduled reminder for \(name) at \(hour):\(String(format: "%02d", minute))")
    } catch {
      print("[NotificationService] Failed to schedule supplement reminder: \(error)")
    }
  }

  // MARK: - Workout Reminders

  /// Update workout reminders based on current settings
  func updateWorkoutReminders() async {
    await removeNotifications(withPrefix: "workout_")

    guard workoutRemindersEnabled && isAuthorized else { return }

    let content = UNMutableNotificationContent()
    content.title = "Workout Reminder"
    content.body = "Time to get moving! Your workout is waiting."
    content.sound = .default
    content.categoryIdentifier = NotificationCategory.workout

    var dateComponents = DateComponents()
    dateComponents.hour = workoutReminderTime
    dateComponents.minute = 0

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(
      identifier: "workout_daily",
      content: content,
      trigger: trigger
    )

    do {
      try await UNUserNotificationCenter.current().add(request)
      print("[NotificationService] Scheduled daily workout reminder at \(workoutReminderTime):00")
    } catch {
      print("[NotificationService] Failed to schedule workout reminder: \(error)")
    }
  }

  /// Schedule workout reminders for specific days
  func scheduleWorkoutReminders(forDays days: [Int], atHour hour: Int) async {
    await removeNotifications(withPrefix: "workout_")

    guard isAuthorized else { return }

    for day in days {
      let content = UNMutableNotificationContent()
      content.title = "Workout Day!"
      content.body = "Today's workout is ready. Let's crush it!"
      content.sound = .default
      content.categoryIdentifier = NotificationCategory.workout

      var dateComponents = DateComponents()
      dateComponents.weekday = day  // 1 = Sunday, 2 = Monday, etc.
      dateComponents.hour = hour
      dateComponents.minute = 0

      let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
      let request = UNNotificationRequest(
        identifier: "workout_day_\(day)",
        content: content,
        trigger: trigger
      )

      do {
        try await UNUserNotificationCenter.current().add(request)
        print("[NotificationService] Scheduled workout reminder for weekday \(day) at \(hour):00")
      } catch {
        print("[NotificationService] Failed to schedule workout reminder: \(error)")
      }
    }
  }

  // MARK: - Progress Reminders

  /// Update weekly progress check-in reminder
  func updateProgressReminders() async {
    await removeNotifications(withPrefix: "progress_")

    guard progressRemindersEnabled && isAuthorized else { return }

    let content = UNMutableNotificationContent()
    content.title = "Weekly Check-in"
    content.body = "Time to log your progress! Track your weight, measurements, and how you're feeling."
    content.sound = .default
    content.categoryIdentifier = NotificationCategory.progress

    var dateComponents = DateComponents()
    dateComponents.weekday = progressReminderDay
    dateComponents.hour = 9  // 9 AM
    dateComponents.minute = 0

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(
      identifier: "progress_weekly",
      content: content,
      trigger: trigger
    )

    do {
      try await UNUserNotificationCenter.current().add(request)
      print("[NotificationService] Scheduled weekly progress reminder for weekday \(progressReminderDay)")
    } catch {
      print("[NotificationService] Failed to schedule progress reminder: \(error)")
    }
  }

  // MARK: - Hydration Reminders

  /// Update hydration reminders based on current settings
  func updateHydrationReminders() async {
    await removeNotifications(withPrefix: "hydration_")

    guard hydrationRemindersEnabled && isAuthorized else { return }

    let messages = [
      "Stay hydrated! Time for a glass of water.",
      "Water break! Your body will thank you.",
      "Hydration check! Have you had water recently?",
      "Drink up! Keep that hydration going.",
      "Water time! A healthy habit for a healthy you."
    ]

    var hour = hydrationStartHour
    var index = 0

    while hour <= hydrationEndHour {
      let content = UNMutableNotificationContent()
      content.title = "💧 Hydration Reminder"
      content.body = messages[index % messages.count]
      content.sound = .default
      content.categoryIdentifier = NotificationCategory.hydration

      var dateComponents = DateComponents()
      dateComponents.hour = hour
      dateComponents.minute = 0

      let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
      let request = UNNotificationRequest(
        identifier: "hydration_\(hour)",
        content: content,
        trigger: trigger
      )

      do {
        try await UNUserNotificationCenter.current().add(request)
      } catch {
        print("[NotificationService] Failed to schedule hydration reminder: \(error)")
      }

      hour += hydrationIntervalHours
      index += 1
    }

    print("[NotificationService] Scheduled hydration reminders from \(hydrationStartHour):00 to \(hydrationEndHour):00")
  }

  // MARK: - Utility Methods

  /// Remove all pending notifications with a given prefix
  private func removeNotifications(withPrefix prefix: String) async {
    let center = UNUserNotificationCenter.current()
    let requests = await center.pendingNotificationRequests()
    let identifiersToRemove = requests
      .map { $0.identifier }
      .filter { $0.hasPrefix(prefix) }

    center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
  }

  /// Remove all pending notifications
  func removeAllNotifications() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    print("[NotificationService] Removed all pending notifications")
  }

  /// Get count of pending notifications
  func getPendingNotificationCount() async -> Int {
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    return requests.count
  }

  /// List all pending notifications (for debugging)
  func listPendingNotifications() async {
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    print("[NotificationService] Pending notifications (\(requests.count)):")
    for request in requests {
      print("  - \(request.identifier): \(request.content.title)")
    }
  }

  /// Refresh all reminders based on current settings
  func refreshAllReminders() async {
    await updateSupplementReminders()
    await updateWorkoutReminders()
    await updateProgressReminders()
    await updateHydrationReminders()
  }
}

// MARK: - Int Extension

private extension Int {
  /// Return self if non-zero, otherwise return default value
  func nonZeroOr(_ defaultValue: Int) -> Int {
    self != 0 ? self : defaultValue
  }
}
