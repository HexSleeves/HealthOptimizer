//
//  Extensions.swift
//  HealthOptimizer
//
//  Swift extensions for common functionality
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
  /// Format date for display
  func formatted(style: DateFormatter.Style) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = style
    return formatter.string(from: self)
  }

  /// Check if date is today
  var isToday: Bool {
    Calendar.current.isDateInToday(self)
  }

  /// Check if date is this week
  var isThisWeek: Bool {
    Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
  }

  /// Days ago from now
  var daysAgo: Int {
    Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
  }
}

// MARK: - Double Extensions

extension Double {
  /// Round to specified decimal places
  func rounded(toPlaces places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }

  /// Convert kg to lbs
  var toLbs: Double {
    self * 2.205
  }

  /// Convert lbs to kg
  var toKg: Double {
    self / 2.205
  }

  /// Convert cm to inches
  var toInches: Double {
    self / 2.54
  }

  /// Convert inches to cm
  var toCm: Double {
    self * 2.54
  }
}

// MARK: - String Extensions

extension String {
  /// Check if string is valid email
  var isValidEmail: Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
  }

  /// Trim whitespace and newlines
  var trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Check if string contains only numbers
  var isNumeric: Bool {
    !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
  }
}

// MARK: - View Extensions

extension View {
  /// Apply a conditional modifier
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }

  /// Hide keyboard
  func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }

  /// Card style modifier
  func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 12) -> some View {
    self
      .padding(padding)
      .background(Color(.systemBackground))
      .cornerRadius(cornerRadius)
      .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
  }
}

// MARK: - Color Extensions

extension Color {
  /// Initialize from hex string
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

// MARK: - Array Extensions

extension Array {
  /// Safe subscript access
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

extension Array where Element: Identifiable {
  /// Find index by ID
  func index(of element: Element) -> Int? {
    firstIndex(where: { $0.id == element.id })
  }
}

// MARK: - Bundle Extensions

extension Bundle {
  /// App version string
  var appVersion: String {
    infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  }

  /// Build number
  var buildNumber: String {
    infoDictionary?["CFBundleVersion"] as? String ?? "1"
  }
}
