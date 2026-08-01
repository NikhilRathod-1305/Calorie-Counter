import SwiftUI
import SwiftData

struct WaterDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var waterEntries: [WaterLogEntry]
    @Query private var profiles: [UserProfile]

    @State private var viewedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showingMonthCalendar = false
    @State private var showingCupSwitcher = false
    @State private var showingEditGoal = false
    @AppStorage("water.lastCupSize") private var lastCupSize: Int = 200
    @AppStorage("water.lastDrinkType") private var lastDrinkTypeRaw: String = DrinkType.water.rawValue

    private var profile: UserProfile { profiles.first ?? UserProfile() }
    private let calendar = Calendar.current

    private var lastDrinkType: DrinkType {
        DrinkType(rawValue: lastDrinkTypeRaw) ?? .water
    }

    private var viewedEntries: [WaterLogEntry] {
        waterEntries
            .filter { calendar.isDate($0.date, inSameDayAs: viewedDate) }
            .sorted { $0.date > $1.date }
    }

    private var waterMl: Int { viewedEntries.reduce(0) { $0 + $1.milliliters } }
    private var fraction: Double { min(1, Double(waterMl) / Double(max(1, profile.waterGoalMl))) }

    private func dayProgress(_ day: Date) -> Double {
        let dayMl = waterEntries
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.milliliters }
        return min(1, Double(dayMl) / Double(max(1, profile.waterGoalMl)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                dateStripSection

                VStack(spacing: 20) {
                    DropletFillView(fraction: fraction)
                        .frame(width: 180, height: 210)

                    VStack(spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(waterMl)")
                                .font(Theme.Font.display(36))
                                .foregroundStyle(Theme.textPrimary)
                            Text("mL")
                                .font(Theme.Font.text(14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        HStack(spacing: 4) {
                            Text("Daily goal:")
                                .font(Theme.Font.text(13))
                                .foregroundStyle(Theme.textFaint)
                            Text("\(profile.waterGoalMl) mL")
                                .font(Theme.Font.text(13, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
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

                Color.clear.frame(height: 16)
            }
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Water Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
        .safeAreaInset(edge: .bottom) {
            drinkBar
        }
        .sheet(isPresented: $showingCupSwitcher) {
            CupSizeSwitcherSheet(
                selectedSize: $lastCupSize,
                selectedDrinkType: Binding(
                    get: { lastDrinkType },
                    set: { lastDrinkTypeRaw = $0.rawValue }
                ),
                onClose: { showingCupSwitcher = false }
            )
            .presentationDetents([.height(460)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingEditGoal) {
            EditWaterGoalSheet(
                currentGoalMl: profile.waterGoalMl,
                onClose: { showingEditGoal = false },
                onSave: { newGoal in
                    profile.waterGoalMl = newGoal
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
                    tint: Theme.water,
                    tintSoft: Theme.waterSoft,
                    tintGradient: Theme.waterGradient
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
                    tint: Theme.water,
                    tintSoft: Theme.waterSoft,
                    tintGradient: Theme.waterGradient
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
                    .frame(width: 32, height: 24)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
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
                    WaterHistoryView()
                } label: {
                    HStack(spacing: 3) {
                        Text("View All")
                        Image(systemName: "arrow.right")
                    }
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.water)
                }
            }
            .padding(.horizontal, 2)

            if viewedEntries.isEmpty {
                Text("No drinks logged for this day")
                    .font(Theme.Font.text(13))
                    .foregroundStyle(Theme.textFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewedEntries.enumerated()), id: \.element.id) { index, entry in
                        historyRow(entry)
                        if index < viewedEntries.count - 1 {
                            Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 58)
                        }
                    }
                }
                .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            }
        }
        .padding(.horizontal, 16)
    }

    private func historyRow(_ entry: WaterLogEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.drinkType.icon)
                .font(.system(size: 16))
                .foregroundStyle(entry.drinkType.tint)
                .frame(width: 36, height: 36)
                .background(Theme.cardBackgroundAlt, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.drinkType.label)
                    .font(Theme.Font.text(13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(timeString(entry.date))
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Text("\(entry.milliliters) mL")
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: Bottom drink bar

    private var drinkBar: some View {
        HStack(spacing: 12) {
            Button {
                showingCupSwitcher = true
            } label: {
                Image(systemName: lastDrinkType.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(lastDrinkType.tint)
                    .frame(width: 52, height: 52)
                    .background(Theme.cardBackground, in: Circle())
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            Button {
                logDrink()
            } label: {
                Text("Drink (\(lastCupSize) mL)")
                    .font(Theme.Font.text(15, weight: .semibold))
                    .foregroundStyle(Theme.onWater)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.water, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .background(Theme.groupedBackground)
    }

    private func logDrink() {
        let entry = WaterLogEntry(milliliters: lastCupSize, date: viewedDate, drinkType: lastDrinkType)
        modelContext.insert(entry)
        try? modelContext.save()
    }
}
