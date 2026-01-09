//
//  AuthView.swift
//  HealthOptimizer
//
//  Authentication view with Sign in with Apple and Email/Password
//

import AuthenticationServices
import SwiftUI

// MARK: - Auth View

struct AuthView: View {

  // MARK: - Environment

  @Environment(\.colorScheme) private var colorScheme

  // MARK: - State

  @State private var authService = AuthService.shared
  @State private var showEmailAuth = false
  @State private var isSignUp = false

  // MARK: - Body

  var body: some View {
    NavigationStack {
      VStack(spacing: 32) {
        Spacer()

        // Logo and Title
        VStack(spacing: 16) {
          Image(systemName: "heart.text.square.fill")
            .font(.system(size: 80))
            .foregroundStyle(.linearGradient(
              colors: [.blue, .purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ))

          Text("HealthOptimizer")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("AI-powered health recommendations\npersonalized for you")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }

        Spacer()

        // Auth Buttons
        VStack(spacing: 16) {
          // Sign in with Apple
          SignInWithAppleButton(
            onRequest: { request in
              let appleRequest = authService.prepareAppleSignIn()
              request.requestedScopes = appleRequest.requestedScopes
              request.nonce = appleRequest.nonce
            },
            onCompletion: { result in
              Task {
                try? await authService.handleAppleSignIn(result: result)
              }
            }
          )
          .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
          .frame(height: 50)
          .cornerRadius(12)

          // Divider
          HStack {
            Rectangle()
              .fill(Color.secondary.opacity(0.3))
              .frame(height: 1)
            Text("or")
              .font(.caption)
              .foregroundColor(.secondary)
            Rectangle()
              .fill(Color.secondary.opacity(0.3))
              .frame(height: 1)
          }

          // Email Sign In
          Button(action: {
            isSignUp = false
            showEmailAuth = true
          }) {
            HStack {
              Image(systemName: "envelope.fill")
              Text("Sign in with Email")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
          }

          // Create Account
          Button(action: {
            isSignUp = true
            showEmailAuth = true
          }) {
            Text("Create an account")
              .font(.subheadline)
              .foregroundColor(.accentColor)
          }
        }
        .padding(.horizontal, 24)

        // Loading indicator
        if authService.isLoading {
          ProgressView()
            .padding()
        }

        // Error message
        if let error = authService.errorMessage {
          Text(error)
            .font(.caption)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }

        Spacer()

        // Terms and Privacy
        VStack(spacing: 4) {
          Text("By continuing, you agree to our")
            .font(.caption2)
            .foregroundColor(.secondary)

          HStack(spacing: 4) {
            Button("Terms of Service") {
              // Open terms
            }
            Text("and")
            Button("Privacy Policy") {
              // Open privacy
            }
          }
          .font(.caption2)
        }
        .padding(.bottom, 16)
      }
      .sheet(isPresented: $showEmailAuth) {
        EmailAuthView(isSignUp: isSignUp)
      }
    }
  }
}

// MARK: - Email Auth View

struct EmailAuthView: View {

  // MARK: - Environment

  @Environment(\.dismiss) private var dismiss

  // MARK: - State

  @State private var authService = AuthService.shared
  @State private var email = ""
  @State private var password = ""
  @State private var confirmPassword = ""
  @State private var showForgotPassword = false

  let isSignUp: Bool

  // MARK: - Computed

  private var isValid: Bool {
    let emailValid = email.contains("@") && email.contains(".")
    let passwordValid = password.count >= 6

    if isSignUp {
      return emailValid && passwordValid && password == confirmPassword
    }
    return emailValid && passwordValid
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Email", text: $email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .autocorrectionDisabled()

          SecureField("Password", text: $password)
            .textContentType(isSignUp ? .newPassword : .password)

          if isSignUp {
            SecureField("Confirm Password", text: $confirmPassword)
              .textContentType(.newPassword)
          }
        } header: {
          Text(isSignUp ? "Create Account" : "Sign In")
        } footer: {
          if isSignUp {
            Text("Password must be at least 6 characters.")
          }
        }

        Section {
          Button(action: performAuth) {
            HStack {
              Spacer()
              if authService.isLoading {
                ProgressView()
              } else {
                Text(isSignUp ? "Create Account" : "Sign In")
              }
              Spacer()
            }
          }
          .disabled(!isValid || authService.isLoading)
        }

        if !isSignUp {
          Section {
            Button("Forgot Password?") {
              showForgotPassword = true
            }
            .font(.subheadline)
          }
        }

        if let error = authService.errorMessage {
          Section {
            Text(error)
              .foregroundColor(.red)
              .font(.caption)
          }
        }
      }
      .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .alert("Reset Password", isPresented: $showForgotPassword) {
        TextField("Email", text: $email)
        Button("Cancel", role: .cancel) {}
        Button("Send Reset Link") {
          Task {
            try? await authService.sendPasswordReset(email: email)
          }
        }
      } message: {
        Text("Enter your email to receive a password reset link.")
      }
      .onChange(of: authService.isSignedIn) { _, isSignedIn in
        if isSignedIn {
          dismiss()
        }
      }
    }
  }

  // MARK: - Methods

  private func performAuth() {
    Task {
      do {
        if isSignUp {
          try await authService.signUp(email: email, password: password)
        } else {
          try await authService.signIn(email: email, password: password)
        }
        dismiss()
      } catch {
        // Error is shown via authService.errorMessage
      }
    }
  }
}

// MARK: - Preview

#Preview {
  AuthView()
}
