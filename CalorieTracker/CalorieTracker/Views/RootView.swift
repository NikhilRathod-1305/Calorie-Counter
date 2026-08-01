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
    case home, tracker, progress, more

    var label: String {
        switch self {
        case .home: return "Home"
        case .tracker: return "Tracker"
        case .progress: return "Progress"
        case .more: return "More"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .tracker: return "square.grid.2x2"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .more: return "person"
        }
    }

    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

private struct MainTabView: View {
    @State private var selectedTab: RootTab = .home
    @State private var showingQuickLog = false
    @State private var toastMessage: String?
    @State private var barWidth: CGFloat = 0
    @State private var isDragging = false
    @State private var hidesTabBar = false
    @GestureState private var dragTranslation: CGFloat = 0

    private let tabs = RootTab.allCases

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home: HomeDashboardView()
                case .tracker: TrackerPlaceholderView()
                case .progress: ProgressTabView()
                case .more: MoreView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !hidesTabBar {
                HStack(alignment: .center, spacing: 10) {
                    tabBar
                    fab
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .onPreferenceChange(HideTabBarPreferenceKey.self) { hidden in
            withAnimation(.easeInOut(duration: 0.2)) { hidesTabBar = hidden }
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
            .presentationDetents([.height(460)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { toastMessage = nil }
        }
    }

    private var slotWidth: CGFloat {
        barWidth / CGFloat(tabs.count)
    }

    private var liveIndex: CGFloat {
        guard slotWidth > 0 else { return CGFloat(selectedTab.index) }
        let raw = CGFloat(selectedTab.index) + dragTranslation / slotWidth
        return min(max(raw, 0), CGFloat(tabs.count - 1))
    }

    private let barHorizontalPadding: CGFloat = 10

    private var tabBar: some View {
        GlassEffectContainer(spacing: 8) {
            ZStack(alignment: .leading) {
                HStack(spacing: 4) {
                    ForEach(tabs, id: \.self) { tab in
                        tabButton(tab)
                    }
                }
                .padding(.horizontal, barHorizontalPadding)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: Capsule())

                if slotWidth > 0 {
                    Capsule()
                        .fill(.clear)
                        .frame(width: slotWidth - 6, height: 44)
                        .glassEffect(.regular.tint(Theme.accent.opacity(0.5)).interactive(), in: Capsule())
                        .offset(x: barHorizontalPadding + liveIndex * slotWidth + 3)
                        .animation(isDragging ? nil : .interpolatingSpring(stiffness: 170, damping: 22), value: liveIndex)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { barWidth = geo.size.width - barHorizontalPadding * 2 }
                    .onChange(of: geo.size.width) { _, newValue in barWidth = newValue - barHorizontalPadding * 2 }
            }
        )
        .highPriorityGesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.width
            }
            .onChanged { _ in
                if !isDragging { isDragging = true }
            }
            .onEnded { value in
                isDragging = false
                let slot = slotWidth
                guard slot > 0 else { return }
                if abs(value.translation.width) < 8 {
                    let tappedIndex = Int((value.location.x / slot).rounded(.down))
                    if tabs.indices.contains(tappedIndex) {
                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 22)) {
                            selectedTab = tabs[tappedIndex]
                        }
                    }
                    return
                }
                let raw = CGFloat(selectedTab.index) + value.translation.width / slot
                let clamped = min(max(raw, 0), CGFloat(tabs.count - 1))
                let nearest = tabs[Int(clamped.rounded())]
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 22)) {
                    selectedTab = nearest
                }
            }
    }

    private var fab: some View {
        Button {
            showingQuickLog = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 64, height: 64)
                .contentShape(Circle())
                .glassEffect(.regular.tint(Theme.accent).interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .shadow(color: Theme.accent.opacity(0.35), radius: 12, y: 5)
        .zIndex(1)
    }

    private func tabButton(_ tab: RootTab) -> some View {
        VStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: 20, weight: .regular))
            Text(tab.label)
                .font(Theme.Font.text(10, weight: .regular))
        }
        .foregroundStyle(selectedTab == tab ? Theme.accent : Theme.textFaint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
