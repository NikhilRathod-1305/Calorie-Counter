import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasCompletedOnboarding {
                MainTabView()
                    .preferredColorScheme(profile.appearance.colorScheme)
            } else {
                OnboardingFlowView { completedProfile in
                    if let existing = profiles.first {
                        existing.heightCm = completedProfile.heightCm
                        existing.age = completedProfile.age
                        existing.weightKg = completedProfile.weightKg
                        existing.targetWeightKg = completedProfile.targetWeightKg
                        existing.activityLevel = completedProfile.activityLevel
                        existing.macroPreset = completedProfile.macroPreset
                        existing.goalType = completedProfile.goalType
                        existing.sex = completedProfile.sex
                        existing.weeklyRateKg = completedProfile.weeklyRateKg
                        existing.hasCompletedOnboarding = true
                    } else {
                        modelContext.insert(completedProfile)
                        modelContext.insert(WeightLogEntry(weightKg: completedProfile.weightKg))
                    }
                    try? modelContext.save()
                }
            }
        }
    }
}

private enum RootTab: String, CaseIterable {
    case home, tracker, progress, more, add

    var label: String {
        switch self {
        case .home: return "Home"
        case .tracker: return "Tracker"
        case .progress: return "Progress"
        case .more: return "More"
        case .add: return "Add"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .tracker: return "square.grid.2x2"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .more: return "person"
        case .add: return "plus"
        }
    }
}

private struct MainTabView: View {
    @State private var selectedTab: RootTab = .home
    @State private var previousTab: RootTab = .home
    @State private var showingQuickLog = false
    @State private var toastMessage: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(RootTab.home.label, systemImage: RootTab.home.icon, value: .home) {
                HomeDashboardView()
            }
            Tab(RootTab.tracker.label, systemImage: RootTab.tracker.icon, value: .tracker) {
                TrackerPlaceholderView()
            }
            Tab(RootTab.progress.label, systemImage: RootTab.progress.icon, value: .progress) {
                ProgressTabView()
            }
            Tab(RootTab.more.label, systemImage: RootTab.more.icon, value: .more) {
                MoreView()
            }
            Tab(RootTab.add.label, systemImage: RootTab.add.icon, value: .add, role: .search) {
                Color.clear
            }
        }
        .tint(Theme.accent)
        .onChange(of: selectedTab) { oldValue, newValue in
            guard newValue == .add else {
                previousTab = newValue
                return
            }
            showingQuickLog = true
            selectedTab = previousTab
        }
        .toast(toastMessage)
        .sheet(isPresented: $showingQuickLog) {
            QuickLogSheet(
                onClose: { showingQuickLog = false },
                onAdded: {
                    showingQuickLog = false
                    showToast("Added to Diary")
                }
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .presentationDetents([.height(470)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.ultraThinMaterial)
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { toastMessage = nil }
        }
    }
}
