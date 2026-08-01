import SwiftUI
import SwiftData

struct StepDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showingMonthCalendar = false
    @State private var showingEditGoal = false
    @State private var dailySteps: [Date: Int] = [:]
    @State private var unavailable = false

    private var profile: UserProfile { profiles.first ?? UserProfile() }
    private let calendar = Calendar.current

    private var viewedSteps: Int { dailySteps[calendar.startOfDay(for: viewedDate)] ?? 0 }
    private var fraction: Double { min(1, Double(viewedSteps) / Double(max(1, profile.stepGoal))) }

    private func dayProgress(_ day: Date) -> Double {
        let steps = dailySteps[calendar.startOfDay(for: day)] ?? 0
        return min(1, Double(steps) / Double(max(1, profile.stepGoal)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                dateStripSection

                VStack(spacing: -8) {
                    GaugeDialView(progress: fraction)
                        .frame(width: 190, height: 190)

                    VStack(spacing: 4) {
                        Text("Steps")
                            .font(Theme.Font.text(13))
                            .foregroundStyle(Theme.textFaint)
                        if unavailable {
                            Text("Unavailable")
                                .font(Theme.Font.display(30))
                                .foregroundStyle(Theme.textFaint)
                        } else {
                            Text("\(viewedSteps)")
                                .font(Theme.Font.display(36))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        HStack(spacing: 4) {
                            Text("/ \(profile.stepGoal) steps")
                                .font(Theme.Font.text(13))
                                .foregroundStyle(Theme.textFaint)
                            Button {
                                showingEditGoal = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textFaint)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
                .padding(.horizontal, 16)

                historySection

                Color.clear.frame(height: 24)
            }
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Step Counter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task { await loadSteps() }
        .sheet(isPresented: $showingEditGoal) {
            EditStepGoalSheet(
                currentGoal: profile.stepGoal,
                onClose: { showingEditGoal = false },
                onSave: { newGoal in
                    profile.stepGoal = newGoal
                    try? modelContext.save()
                    showingEditGoal = false
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
    }

    // MARK: Header + date strip + expandable month calendar

    private var dateStripSection: some View {
        VStack(spacing: 0) {
            if showingMonthCalendar {
                MonthCalendarView(
                    selectedDate: $viewedDate,
                    progress: dayProgress,
                    tint: Theme.steps,
                    tintSoft: Theme.secondarySoft,
                    tintGradient: Theme.secondaryGradient
                )
                .padding(16)
                .padding(.bottom, 4)
                .transition(.opacity)
            } else {
                DateStripPicker(
                    selectedDate: $viewedDate,
                    progress: dayProgress,
                    showsHeader: false,
                    wrapsInCard: false,
                    tint: Theme.steps,
                    tintSoft: Theme.secondarySoft,
                    tintGradient: Theme.secondaryGradient
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 4)
                .transition(.opacity)
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    showingMonthCalendar.toggle()
                }
            } label: {
                Image(systemName: showingMonthCalendar ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textFaint)
                    .frame(width: 60, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    // MARK: History preview (last 7 days)

    private var recentDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: Date())) }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("History")
                    .font(Theme.Font.display(16))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                NavigationLink {
                    StepHistoryView()
                } label: {
                    HStack(spacing: 3) {
                        Text("View All")
                        Image(systemName: "arrow.right")
                    }
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.steps)
                }
            }
            .padding(.horizontal, 2)

            if unavailable {
                Text("Steps unavailable — enable Health access in Settings")
                    .font(Theme.Font.text(13))
                    .foregroundStyle(Theme.textFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentDays.enumerated()), id: \.element) { index, day in
                        historyRow(day)
                        if index < recentDays.count - 1 {
                            Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 58)
                        }
                    }
                }
                .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            }
        }
        .padding(.horizontal, 16)
    }

    private func historyRow(_ day: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "shoeprints.fill")
                .font(.system(size: 16))
                .foregroundStyle(Theme.steps)
                .frame(width: 36, height: 36)
                .background(Theme.cardBackgroundAlt, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(dayLabel(day))
                    .font(Theme.Font.text(13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text("Goal: \(profile.stepGoal) steps")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Text("\(dailySteps[day] ?? 0)")
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func dayLabel(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: day)
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
        let start = calendar.date(byAdding: .day, value: -180, to: calendar.startOfDay(for: Date())) ?? Date()
        dailySteps = (try? await HealthKitStepsService.dailySteps(from: start)) ?? [:]
    }
}
