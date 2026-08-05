import SwiftUI
import SwiftData

private enum InsightsRange: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var days: Int {
        switch self {
        case .weekly: return 7
        case .monthly: return 30
        case .yearly: return 365
        }
    }
}

struct ProgressTabView: View {
    @Query(sort: \WeightLogEntry.date) private var weightEntries: [WeightLogEntry]
    @Query(sort: \MealEntry.timestamp) private var mealEntries: [MealEntry]
    @Query(sort: \WaterLogEntry.date) private var waterEntries: [WaterLogEntry]
    @Query private var profiles: [UserProfile]

    @State private var range: InsightsRange = .weekly
    @State private var pageOffset: Int = 0
    @State private var dailySteps: [Date: Int] = [:]

    private let calendar = Calendar.current
    private var profile: UserProfile { profiles.first ?? UserProfile() }

    // MARK: Date window

    private var windowEnd: Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: pageOffset * range.days, to: today) ?? today
    }

    private var windowStart: Date {
        calendar.date(byAdding: .day, value: -(range.days - 1), to: windowEnd) ?? windowEnd
    }

    private var windowDays: [Date] {
        (0..<range.days).compactMap { calendar.date(byAdding: .day, value: $0, to: windowStart) }
    }

    private var dateRangeLabel: String {
        let formatter = DateFormatter()
        switch range {
        case .weekly:
            formatter.dateFormat = "MMM d"
            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "yyyy"
            return "\(formatter.string(from: windowStart)) - \(formatter.string(from: windowEnd)), \(yearFormatter.string(from: windowEnd))"
        case .monthly:
            formatter.dateFormat = "MMM d"
            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "yyyy"
            return "\(formatter.string(from: windowStart)) - \(formatter.string(from: windowEnd)), \(yearFormatter.string(from: windowEnd))"
        case .yearly:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: windowEnd)
        }
    }

    // MARK: Weight / BMI

    private var currentWeight: Double { weightEntries.last?.weightKg ?? profile.weightKg }
    private var bmi: Double {
        let heightM = profile.heightCm / 100
        guard heightM > 0 else { return 0 }
        return currentWeight / (heightM * heightM)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        rangeNavigator

                        MetricChartCard(
                            title: "Calorie (kcal)",
                            points: caloriePoints,
                            goal: Double(NutritionGoalCalculator.compute(profile: profile).calorieGoal),
                            color: Theme.sage,
                            unit: "kcal",
                            axisLabels: axisLabels
                        )

                        NutritionPercentCard(days: nutritionBreakdown, axisLabels: axisLabels)

                        MetricChartCard(
                            title: "Water (mL)",
                            points: waterPoints,
                            goal: Double(profile.waterGoalMl),
                            color: Theme.water,
                            unit: "mL",
                            axisLabels: axisLabels
                        )

                        MetricChartCard(
                            title: "Step",
                            points: stepPoints,
                            goal: Double(profile.stepGoal),
                            color: Theme.steps,
                            unit: "",
                            axisLabels: axisLabels
                        )

                        MetricChartCard(
                            title: "Weight (kg)",
                            points: weightPoints,
                            goal: profile.targetWeightKg,
                            color: Theme.weight,
                            unit: "kg",
                            axisLabels: axisLabels
                        )

                        BMICard(bmi: bmi)

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .background(Theme.groupedBackground.ignoresSafeArea())
            }
            .navigationBarHidden(true)
        }
        .task(id: windowStart) { await loadSteps() }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Insights")
                    .font(Theme.Font.display(22))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Menu {
                    Button("Export Data", systemImage: "square.and.arrow.up") {}
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textFaint)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            PillSegmentedControl(
                options: InsightsRange.allCases.map { ($0, $0.rawValue) },
                selection: $range
            )
            .onChange(of: range) { pageOffset = 0 }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Theme.background)
    }

    private var rangeNavigator: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { pageOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(dateRangeLabel)
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button {
                guard pageOffset < 0 else { return }
                withAnimation(.easeInOut(duration: 0.15)) { pageOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(pageOffset < 0 ? Theme.textSecondary : Theme.textFaint)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .disabled(pageOffset >= 0)
        }
    }

    // MARK: Axis labels

    private var axisLabels: [String] {
        let formatter = DateFormatter()
        switch range {
        case .weekly:
            formatter.dateFormat = "d"
            return windowDays.map { formatter.string(from: $0) }
        case .monthly:
            formatter.dateFormat = "d"
            let stride = max(1, windowDays.count / 6)
            return windowDays.enumerated().compactMap { index, day in
                index % stride == 0 ? formatter.string(from: day) : nil
            }
        case .yearly:
            formatter.dateFormat = "MMM"
            var seen = Set<Int>()
            var labels: [String] = []
            for day in windowDays {
                let month = calendar.component(.month, from: day)
                if !seen.contains(month) {
                    seen.insert(month)
                    labels.append(formatter.string(from: day))
                }
            }
            return labels
        }
    }

    // MARK: Data aggregation

    private var mealsByDay: [Date: [MealEntry]] {
        // Only top-level entries — a multi-item scan's nested items are
        // counted via the parent's totalNutrition, not counted separately.
        Dictionary(grouping: mealEntries.filter(\.isTopLevel)) { calendar.startOfDay(for: $0.timestamp) }
    }

    private var waterByDay: [Date: Int] {
        Dictionary(grouping: waterEntries) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.milliliters } }
    }

    private var weightByDay: [Date: Double] {
        Dictionary(grouping: weightEntries) { calendar.startOfDay(for: $0.date) }
            .compactMapValues { $0.last?.weightKg }
    }

    private var caloriePoints: [MetricChartPoint] {
        windowDays.map { day in
            let total = (mealsByDay[day] ?? []).reduce(0.0) { $0 + $1.totalNutrition.calories }
            return MetricChartPoint(date: day, value: total)
        }
    }

    private var waterPoints: [MetricChartPoint] {
        windowDays.map { MetricChartPoint(date: $0, value: Double(waterByDay[$0] ?? 0)) }
    }

    private var stepPoints: [MetricChartPoint] {
        windowDays.map { MetricChartPoint(date: $0, value: Double(dailySteps[$0] ?? 0)) }
    }

    private var weightPoints: [MetricChartPoint] {
        var lastKnown = weightEntries.first(where: { $0.date < windowStart })?.weightKg ?? currentWeight
        return windowDays.map { day in
            if let value = weightByDay[day] { lastKnown = value }
            return MetricChartPoint(date: day, value: lastKnown)
        }
    }

    private var nutritionBreakdown: [NutritionDayBreakdown] {
        windowDays.map { day in
            let entries = mealsByDay[day] ?? []
            guard !entries.isEmpty else {
                return NutritionDayBreakdown(date: day, carbsPct: 0, proteinPct: 0, fatPct: 0)
            }
            let totals = entries.reduce(NutritionValues.zero) { $0 + $1.totalNutrition }
            let carbsCal = totals.carbs * 4
            let proteinCal = totals.protein * 4
            let fatCal = totals.fat * 9
            let sum = max(1, carbsCal + proteinCal + fatCal)
            return NutritionDayBreakdown(
                date: day,
                carbsPct: carbsCal / sum * 100,
                proteinPct: proteinCal / sum * 100,
                fatPct: fatCal / sum * 100
            )
        }
    }

    private func loadSteps() async {
        guard HealthKitStepsService.isAvailable else { return }
        let granted = await HealthKitStepsService.requestAuthorization()
        guard granted else { return }
        let all = (try? await HealthKitStepsService.dailySteps(from: windowStart)) ?? [:]
        dailySteps = all.filter { $0.key <= windowEnd }
    }
}
