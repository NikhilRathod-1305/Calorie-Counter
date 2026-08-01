import SwiftUI
import SwiftData

struct StepHistoryView: View {
    @Query private var profiles: [UserProfile]

    @State private var dailySteps: [Date: Int] = [:]
    @State private var unavailable = false
    @State private var showingJumpToDate = false
    @State private var jumpDate = Date()

    private let calendar = Calendar.current
    private let daysBack = 60

    private var profile: UserProfile { profiles.first ?? UserProfile() }

    private var orderedDays: [Date] {
        (0..<daysBack).compactMap { calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: Date())) }
            .filter { dailySteps[$0] != nil }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if unavailable {
                    Text("Steps unavailable — enable Health access in Settings")
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textFaint)
                        .padding(.top, 60)
                } else if orderedDays.isEmpty {
                    Text("No steps recorded yet")
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textFaint)
                        .padding(.top, 60)
                } else {
                    ForEach(orderedDays, id: \.self) { day in
                        dayRow(day)
                    }
                }
                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Step Counter History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingJumpToDate = true
                } label: {
                    Image(systemName: "calendar")
                }
            }
        }
        .task { await loadSteps() }
        .sheet(isPresented: $showingJumpToDate) {
            NavigationStack {
                VStack {
                    MonthCalendarView(selectedDate: $jumpDate, tint: Theme.steps, tintSoft: Theme.secondarySoft, tintGradient: Theme.secondaryGradient)
                        .padding(16)
                }
                .navigationTitle("Jump to Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showingJumpToDate = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func dayRow(_ day: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateString(day))
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textFaint)
                .padding(.horizontal, 2)

            HStack(spacing: 12) {
                Image(systemName: "shoeprints.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.steps)
                    .frame(width: 36, height: 36)
                    .background(Theme.cardBackgroundAlt, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(dailySteps[day] ?? 0) steps")
                        .font(Theme.Font.text(13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Goal: \(profile.stepGoal) steps")
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Text(progressString(day))
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle((dailySteps[day] ?? 0) >= profile.stepGoal ? Theme.success : Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }

    private func progressString(_ day: Date) -> String {
        let pct = Int(min(1, Double(dailySteps[day] ?? 0) / Double(max(1, profile.stepGoal))) * 100)
        return "\(pct)%"
    }

    private func dateString(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today, \(formatted(date))" }
        if calendar.isDateInYesterday(date) { return "Yesterday, \(formatted(date))" }
        return formatted(date)
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private func loadSteps() async {
        guard HealthKitStepsService.isAvailable else {
            unavailable = true
            return
        }
        let granted = await HealthKitStepsService.requestAuthorization()
        guard granted else {
            unavailable = true
            return
        }
        let start = calendar.date(byAdding: .day, value: -daysBack, to: calendar.startOfDay(for: Date())) ?? Date()
        dailySteps = (try? await HealthKitStepsService.dailySteps(from: start)) ?? [:]
    }
}
