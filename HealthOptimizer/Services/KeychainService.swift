//
//  KeychainService.swift
//  HealthOptimizer
//
//  Secure storage for API keys using iOS Keychain
//  IMPORTANT: Never store API keys in source code or UserDefaults
//

import Foundation
import Security

// MARK: - Keychain Service Protocol

/// Protocol for secure credential storage
protocol KeychainServiceProtocol {
    func saveAPIKey(_ key: String, for provider: AIProvider) -> Bool
    func getAPIKey(for provider: AIProvider) -> String?
    func deleteAPIKey(for provider: AIProvider) -> Bool
}

// MARK: - Keychain Service

/// Implementation of secure keychain storage
final class KeychainService: KeychainServiceProtocol {

    // MARK: - Singleton

    static let shared = KeychainService()

    // MARK: - Properties

    private let serviceIdentifier = "com.healthoptimizer.apikeys"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Save an API key to the keychain
    /// - Parameters:
    ///   - key: The API key to store
    ///   - provider: The AI provider this key is for
    /// - Returns: True if saved successfully
    @discardableResult
    func saveAPIKey(_ key: String, for provider: AIProvider) -> Bool {
        // First, try to delete any existing key
        deleteAPIKey(for: provider)

        guard let data = key.data(using: .utf8) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: provider.apiKeyName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieve an API key from the keychain
    /// - Parameter provider: The AI provider to get the key for
    /// - Returns: The API key if found, nil otherwise
    func getAPIKey(for provider: AIProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: provider.apiKeyName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    /// Delete an API key from the keychain
    /// - Parameter provider: The AI provider whose key should be deleted
    /// - Returns: True if deleted (or didn't exist)
    @discardableResult
    func deleteAPIKey(for provider: AIProvider) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: provider.apiKeyName
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Check if an API key exists for a provider
    /// - Parameter provider: The AI provider to check
    /// - Returns: True if a key exists
    func hasAPIKey(for provider: AIProvider) -> Bool {
        return getAPIKey(for: provider) != nil
    }
}

// MARK: - Mock Keychain Service (for Previews/Testing)

/// Mock implementation for previews and testing
final class MockKeychainService: KeychainServiceProtocol {

    private var storage: [String: String] = [:]

    func saveAPIKey(_ key: String, for provider: AIProvider) -> Bool {
        storage[provider.apiKeyName] = key
        return true
    }

    func getAPIKey(for provider: AIProvider) -> String? {
        return storage[provider.apiKeyName]
    }

    func deleteAPIKey(for provider: AIProvider) -> Bool {
        storage.removeValue(forKey: provider.apiKeyName)
        return true
    }
}
