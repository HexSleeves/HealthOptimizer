//
//  ProgressEntry.swift
//  HealthOptimizer
//
//  Model for tracking progress over time
//

import Foundation
import SwiftData

// MARK: - Progress Entry

/// A single progress tracking entry
@Model
final class ProgressEntry {

  // MARK: - Properties

  var id: UUID
  var date: Date
  var weight: Double?
  var bodyFatPercentage: Double?
  var notes: String?
  var mood: String?
  var energyLevel: Int?  // 1-10 scale
  var sleepHours: Double?
  var createdAt: Date

  // MARK: - Initialization

  init(
    date: Date = Date(),
    weight: Double? = nil,
    bodyFatPercentage: Double? = nil,
    notes: String? = nil,
    mood: String? = nil,
    energyLevel: Int? = nil,
    sleepHours: Double? = nil
  ) {
    self.id = UUID()
    self.date = date
    self.weight = weight
    self.bodyFatPercentage = bodyFatPercentage
    self.notes = notes
    self.mood = mood
    self.energyLevel = energyLevel
    self.sleepHours = sleepHours
    self.createdAt = Date()
  }
}
