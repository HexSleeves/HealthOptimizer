//
//  AuthService.swift
//  HealthOptimizer
//
//  Firebase Authentication service for user management
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation

// MARK: - Auth Service

/// Service for handling Firebase Authentication
@MainActor
@Observable
final class AuthService {

  // MARK: - Singleton

  static let shared = AuthService()

  // MARK: - Published State

  /// Current authenticated user
  private(set) var currentUser: User?

  /// Whether user is signed in
  var isSignedIn: Bool {
    currentUser != nil
  }

  /// Loading state for auth operations
  var isLoading = false

  /// Error message for display
  var errorMessage: String?

  // MARK: - Private Properties

  /// Current nonce for Sign in with Apple
  private var currentNonce: String?

  /// Auth state listener handle
  private var authStateHandle: AuthStateDidChangeListenerHandle?

  // MARK: - Initialization

  private init() {
    setupAuthStateListener()
  }

  // MARK: - Auth State Listener

  private func setupAuthStateListener() {
    authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
      // Fetch user on MainActor to avoid Sendable issues
      Task { @MainActor in
        let user = Auth.auth().currentUser
        self?.currentUser = user
        if let user = user {
          print("[AuthService] User signed in: \(user.uid)")
        } else {
          print("[AuthService] User signed out")
        }
      }
    }
  }

  // MARK: - Sign in with Apple

  /// Prepare Sign in with Apple request
  func prepareAppleSignIn() -> ASAuthorizationAppleIDRequest {
    let nonce = randomNonceString()
    currentNonce = nonce

    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)

    return request
  }

  /// Handle Sign in with Apple completion
  func handleAppleSignIn(result: Result<ASAuthorization, Error>) async throws {
    isLoading = true
    errorMessage = nil

    defer { isLoading = false }

    switch result {
    case .success(let authorization):
      guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
        throw AuthError.invalidCredential
      }

      guard let nonce = currentNonce else {
        throw AuthError.invalidNonce
      }

      guard let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
        throw AuthError.missingToken
      }

      let credential = OAuthProvider.appleCredential(
        withIDToken: idTokenString,
        rawNonce: nonce,
        fullName: appleIDCredential.fullName
      )

      let authResult = try await Auth.auth().signIn(with: credential)
      print("[AuthService] Apple Sign In successful: \(authResult.user.uid)")

    case .failure(let error):
      // User cancelled is not an error
      if (error as? ASAuthorizationError)?.code == .canceled {
        return
      }
      errorMessage = error.localizedDescription
      throw error
    }
  }

  // MARK: - Email/Password Auth

  /// Sign up with email and password
  func signUp(email: String, password: String) async throws {
    isLoading = true
    errorMessage = nil

    defer { isLoading = false }

    do {
      let result = try await Auth.auth().createUser(withEmail: email, password: password)
      print("[AuthService] Sign up successful: \(result.user.uid)")
    } catch {
      errorMessage = mapAuthError(error)
      throw error
    }
  }

  /// Sign in with email and password
  func signIn(email: String, password: String) async throws {
    isLoading = true
    errorMessage = nil

    defer { isLoading = false }

    do {
      let result = try await Auth.auth().signIn(withEmail: email, password: password)
      print("[AuthService] Sign in successful: \(result.user.uid)")
    } catch {
      errorMessage = mapAuthError(error)
      throw error
    }
  }

  /// Send password reset email
  func sendPasswordReset(email: String) async throws {
    isLoading = true
    errorMessage = nil

    defer { isLoading = false }

    do {
      try await Auth.auth().sendPasswordReset(withEmail: email)
      print("[AuthService] Password reset email sent to \(email)")
    } catch {
      errorMessage = mapAuthError(error)
      throw error
    }
  }

  // MARK: - Sign Out

  /// Sign out current user
  func signOut() throws {
    do {
      try Auth.auth().signOut()
      print("[AuthService] Sign out successful")
    } catch {
      errorMessage = error.localizedDescription
      throw error
    }
  }

  // MARK: - Account Management

  /// Delete current user account
  func deleteAccount() async throws {
    guard currentUser != nil else {
      throw AuthError.notSignedIn
    }

    isLoading = true
    errorMessage = nil

    defer { isLoading = false }

    do {
      // Get user directly from Auth to avoid Sendable issues
      guard let user = Auth.auth().currentUser else {
        throw AuthError.notSignedIn
      }
      try await user.delete()
      print("[AuthService] Account deleted successfully")
    } catch {
      errorMessage = mapAuthError(error)
      throw error
    }
  }

  // MARK: - Helper Methods

  /// Generate random nonce for Sign in with Apple
  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
      fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
    }

    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    let nonce = randomBytes.map { byte in
      charset[Int(byte) % charset.count]
    }
    return String(nonce)
  }

  /// SHA256 hash for nonce
  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
  }

  /// Map Firebase Auth errors to user-friendly messages
  private func mapAuthError(_ error: Error) -> String {
    guard let authError = error as? AuthErrorCode else {
      return error.localizedDescription
    }

    switch authError.code {
    case .emailAlreadyInUse:
      return "This email is already registered. Try signing in instead."
    case .invalidEmail:
      return "Please enter a valid email address."
    case .weakPassword:
      return "Password must be at least 6 characters."
    case .wrongPassword:
      return "Incorrect password. Please try again."
    case .userNotFound:
      return "No account found with this email."
    case .userDisabled:
      return "This account has been disabled."
    case .tooManyRequests:
      return "Too many attempts. Please try again later."
    case .networkError:
      return "Network error. Please check your connection."
    case .requiresRecentLogin:
      return "Please sign in again to complete this action."
    default:
      return error.localizedDescription
    }
  }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
  case invalidCredential
  case invalidNonce
  case missingToken
  case notSignedIn

  var errorDescription: String? {
    switch self {
    case .invalidCredential:
      return "Invalid credentials received."
    case .invalidNonce:
      return "Invalid state. Please try again."
    case .missingToken:
      return "Unable to fetch identity token."
    case .notSignedIn:
      return "You must be signed in to perform this action."
    }
  }
}
