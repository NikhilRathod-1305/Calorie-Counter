import SwiftUI
import SwiftData

struct WeightDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightLogEntry.date) private var weightEntries: [WeightLogEntry]
    @Query private var profiles: [UserProfile]

    @State private var showingLogWeight = false
    @State private var showingEditGoal = false

    private var profile: UserProfile { profiles.first ?? UserProfile() }

    private var currentWeight: Double { weightEntries.last?.weightKg ?? profile.weightKg }
    private var startWeight: Double { weightEntries.first?.weightKg ?? currentWeight }
    private var recentEntries: [WeightLogEntry] { Array(weightEntries.suffix(10)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WeightWidgetCard(
                    currentWeightKg: currentWeight,
                    targetWeightKg: profile.targetWeightKg,
                    recentEntries: recentEntries,
                    onLogWeight: { showingLogWeight = true },
                    tint: Theme.secondary,
                    tintGradient: Theme.secondaryGradient
                )
                .padding(.horizontal, 16)

                goalCard

                historySection

                Color.clear.frame(height: 16)
            }
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Weight Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            logBar
        }
        .sheet(isPresented: $showingLogWeight) {
            LogWeightSheet(
                initialWeight: currentWeight,
                onClose: { showingLogWeight = false },
                onSave: { newWeight, date in
                    profile.weightKg = newWeight
                    modelContext.insert(WeightLogEntry(weightKg: newWeight, date: date))
                    try? modelContext.save()
                    showingLogWeight = false
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingEditGoal) {
            EditWeightGoalSheet(
                currentGoalKg: profile.targetWeightKg,
                onClose: { showingEditGoal = false },
                onSave: { newGoal in
                    profile.targetWeightKg = newGoal
                    try? modelContext.save()
                    showingEditGoal = false
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
    }

    // MARK: Goal summary

    private var goalCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Starting")
                    .font(Theme.Font.text(12))
                    .foregroundStyle(Theme.textFaint)
                Text(String(format: "%.1f kg", startWeight))
                    .font(Theme.Font.text(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Divider().frame(height: 28).overlay(Theme.hairline.opacity(0.6))
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Goal")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textFaint)
                    Button {
                        showingEditGoal = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textFaint)
                    }
                    .buttonStyle(.plain)
                }
                Text(String(format: "%.1f kg", profile.targetWeightKg))
                    .font(Theme.Font.text(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .padding(.horizontal, 16)
    }

    // MARK: History preview

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("History")
                    .font(Theme.Font.display(16))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                NavigationLink {
                    WeightHistoryView()
                } label: {
                    HStack(spacing: 3) {
                        Text("View All")
                        Image(systemName: "arrow.right")
                    }
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                }
            }
            .padding(.horizontal, 2)

            if weightEntries.isEmpty {
                Text("No weight logged yet")
                    .font(Theme.Font.text(13))
                    .foregroundStyle(Theme.textFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            } else {
                let recent = Array(weightEntries.reversed().prefix(5))
                VStack(spacing: 0) {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, entry in
                        historyRow(entry)
                        if index < recent.count - 1 {
                            Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 58)
                        }
                    }
                }
                .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            }
        }
        .padding(.horizontal, 16)
    }

    private func historyRow(_ entry: WeightLogEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 16))
                .foregroundStyle(Theme.secondary)
                .frame(width: 36, height: 36)
                .background(Theme.cardBackgroundAlt, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1f kg", entry.weightKg))
                    .font(Theme.Font.text(13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(dateString(entry.date))
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func dateString(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today, \(timeString(date))" }
        if cal.isDateInYesterday(date) { return "Yesterday, \(timeString(date))" }
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: Bottom log bar

    private var logBar: some View {
        Button {
            showingLogWeight = true
        } label: {
            Text("Log Weight")
                .font(Theme.Font.text(15, weight: .semibold))
                .foregroundStyle(Theme.onSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.secondary, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .background(Theme.groupedBackground)
    }
}
