//
//  AIJSONCoding.swift
//  HealthOptimizer
//
//  Shared JSON coding utilities for AI provider responses
//

import Foundation

nonisolated enum AIJSONCoding {

  static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      if let seconds = try? container.decode(Double.self) {
        if seconds > 10_000_000_000 {  // likely milliseconds
          return Date(timeIntervalSince1970: seconds / 1000.0)
        }
        return Date(timeIntervalSince1970: seconds)
      }

      let string = try container.decode(String.self)

      if let date = ISO8601Parsing.parse(string) {
        return date
      }

      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid ISO8601 date string: \(string)"
      )
    }
    return decoder
  }

  #if DEBUG
  static func debugDescribeDecodingError(_ error: Error) -> String {
    guard let decodingError = error as? DecodingError else {
      return String(describing: error)
    }

    func codingPathString(_ path: [CodingKey]) -> String {
      path.map { key in
        if let intValue = key.intValue { return "[\(intValue)]" }
        return key.stringValue
      }.joined(separator: ".")
    }

    switch decodingError {
    case .typeMismatch(let type, let context):
      return "typeMismatch(\(type)) at \(codingPathString(context.codingPath)): \(context.debugDescription)"
    case .valueNotFound(let type, let context):
      return "valueNotFound(\(type)) at \(codingPathString(context.codingPath)): \(context.debugDescription)"
    case .keyNotFound(let key, let context):
      return "keyNotFound(\(key.stringValue)) at \(codingPathString(context.codingPath)): \(context.debugDescription)"
    case .dataCorrupted(let context):
      return "dataCorrupted at \(codingPathString(context.codingPath)): \(context.debugDescription)"
    @unknown default:
      return "unknown DecodingError: \(decodingError)"
    }
  }

  static func debugSummarizeTopLevelJSON(from jsonData: Data) -> String {
    do {
      let object = try JSONSerialization.jsonObject(with: jsonData, options: [])
      if let dict = object as? [String: Any] {
        let keys = dict.keys.sorted()
        return "top-level keys: \(keys)"
      } else if object is [Any] {
        return "top-level JSON is an array"
      } else {
        return "top-level JSON is \(type(of: object))"
      }
    } catch {
      return "JSONSerialization failed: \(error)"
    }
  }

  static func debugSnippet(_ string: String, head: Int = 800, tail: Int = 400) -> String {
    let normalized = string.replacingOccurrences(of: "\r\n", with: "\n")
    if normalized.count <= head + tail {
      return normalized
    }
    let headIndex = normalized.index(normalized.startIndex, offsetBy: head)
    let tailIndex = normalized.index(normalized.endIndex, offsetBy: -tail)
    return """
    \(normalized[..<headIndex])
    …<\(normalized.count - head - tail) chars omitted>…
    \(normalized[tailIndex...])
    """
  }
  #endif

  // MARK: - Flexible Array Decoding

  /// Decode a value that may be a String array or a single String
  static func decodeStringArray<K: CodingKey>(
    from container: KeyedDecodingContainer<K>,
    forKey key: K
  ) -> [String] {
    if let array = try? container.decode([String].self, forKey: key) {
      return array
    } else if let string = try? container.decode(String.self, forKey: key) {
      return [string]
    }
    return []
  }

  /// Decode a value that may be Int or String, returning Int
  static func decodeInt<K: CodingKey>(
    from container: KeyedDecodingContainer<K>,
    forKey key: K,
    default defaultValue: Int
  ) -> Int {
    if let intValue = try? container.decode(Int.self, forKey: key) {
      return intValue
    } else if let stringValue = try? container.decode(String.self, forKey: key),
              let intValue = Int(stringValue) {
      return intValue
    }
    return defaultValue
  }

  /// Decode a value that may be Double or Int, returning Double
  static func decodeDouble<K: CodingKey>(
    from container: KeyedDecodingContainer<K>,
    forKey key: K,
    default defaultValue: Double
  ) -> Double {
    if let doubleValue = try? container.decode(Double.self, forKey: key) {
      return doubleValue
    } else if let intValue = try? container.decode(Int.self, forKey: key) {
      return Double(intValue)
    }
    return defaultValue
  }

  /// Decode a value that may be String, Int, or Double, returning String
  static func decodeString<K: CodingKey>(
    from container: KeyedDecodingContainer<K>,
    forKey key: K,
    default defaultValue: String = ""
  ) -> String {
    if let stringValue = try? container.decode(String.self, forKey: key) {
      return stringValue
    } else if let intValue = try? container.decode(Int.self, forKey: key) {
      return String(intValue)
    } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
      return String(doubleValue)
    }
    return defaultValue
  }

  /// Decode a UUID that may be invalid (AI sometimes generates non-hex characters)
  /// Returns a new UUID if the value is missing or invalid
  static func decodeUUID<K: CodingKey>(
    from container: KeyedDecodingContainer<K>,
    forKey key: K
  ) -> UUID {
    // First try standard UUID decoding
    if let uuid = try? container.decode(UUID.self, forKey: key) {
      return uuid
    }
    // If that fails, try to decode as string and parse
    if let string = try? container.decode(String.self, forKey: key),
       let uuid = UUID(uuidString: string) {
      return uuid
    }
    // Fall back to generating a new UUID
    return UUID()
  }

  private nonisolated enum ISO8601Parsing {
    static func parse(_ string: String) -> Date? {
      let withFractionalSeconds = ISO8601DateFormatter()
      withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = withFractionalSeconds.date(from: string) {
        return date
      }

      let withoutFractionalSeconds = ISO8601DateFormatter()
      withoutFractionalSeconds.formatOptions = [.withInternetDateTime]
      return withoutFractionalSeconds.date(from: string)
    }
  }
}
