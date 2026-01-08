//
//  MainTabView.swift
//  HealthOptimizer
//
//  Main tab navigation for the app
//

import SwiftUI
import SwiftData

// MARK: - Main Tab View

struct MainTabView: View {
    
    // MARK: - State
    
    @State private var selectedTab: Tab = .dashboard
    @State private var dashboardViewModel = DashboardViewModel()
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)
            
            // Supplements
            SupplementsView(recommendation: dashboardViewModel.currentRecommendation)
                .tabItem {
                    Label("Supplements", systemImage: "pills.fill")
                }
                .tag(Tab.supplements)
            
            // Workouts
            WorkoutsView(recommendation: dashboardViewModel.currentRecommendation)
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(Tab.workouts)
            
            // Diet
            DietView(recommendation: dashboardViewModel.currentRecommendation)
                .tabItem {
                    Label("Diet", systemImage: "fork.knife")
                }
                .tag(Tab.diet)
            
            // Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .task {
            dashboardViewModel.loadData()
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case dashboard = "Dashboard"
    case supplements = "Supplements"
    case workouts = "Workouts"
    case diet = "Diet"
    case profile = "Profile"
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
