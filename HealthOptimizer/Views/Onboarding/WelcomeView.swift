//
//  WelcomeView.swift
//  HealthOptimizer
//
//  Welcome screen for onboarding
//

import SwiftUI

// MARK: - Welcome View

/// Welcome screen introducing the app and its purpose
struct WelcomeView: View {

  // MARK: - State

  @State private var isAnimating = false

  // MARK: - Body

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        Spacer()
          .frame(height: 40)

        // App icon/illustration
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 120, height: 120)
            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)

          Image(systemName: "heart.text.square.fill")
            .font(.system(size: 50))
            .foregroundColor(.white)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .animation(
              .spring(response: 0.6, dampingFraction: 0.6)
                .repeatForever(autoreverses: true),
              value: isAnimating
            )
        }

        // Title and subtitle
        VStack(spacing: 12) {
          Text("Welcome to")
            .font(.title2)
            .foregroundColor(.secondary)

          Text("HealthOptimizer")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(
              LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
              )
            )

          Text("Your AI-powered health optimization assistant")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }

        // Features list
        VStack(spacing: 20) {
          FeatureRow(
            icon: "pills.fill",
            title: "Personalized Supplements",
            description: "Get custom supplement recommendations based on your unique profile",
            color: .green
          )

          FeatureRow(
            icon: "figure.run",
            title: "Custom Workout Plans",
            description: "Exercise routines tailored to your fitness level and goals",
            color: .orange
          )

          FeatureRow(
            icon: "fork.knife",
            title: "Tailored Nutrition",
            description: "Meal plans that fit your preferences and health needs",
            color: .blue
          )

          FeatureRow(
            icon: "brain.head.profile",
            title: "AI-Powered Analysis",
            description: "Advanced AI analyzes your profile for optimal recommendations",
            color: .purple
          )
        }
        .padding(.horizontal)

        // Privacy notice
        VStack(spacing: 8) {
          HStack(spacing: 4) {
            Image(systemName: "lock.shield.fill")
            Text("Your Privacy Matters")
          }
          .font(.headline)
          .foregroundColor(.primary)

          Text(
            "Your health data stays on your device. We never store or share your personal information."
          )
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)

        Spacer()
          .frame(height: 100)
      }
    }
    .onAppear {
      isAnimating = true
    }
  }
}

// MARK: - Feature Row

/// Row displaying a feature with icon and description
struct FeatureRow: View {
  let icon: String
  let title: String
  let description: String
  let color: Color

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(color)
        .frame(width: 40, height: 40)
        .background(color.opacity(0.15))
        .cornerRadius(10)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)

        Text(description)
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
  }
}

// MARK: - Preview

#Preview {
  WelcomeView()
}
