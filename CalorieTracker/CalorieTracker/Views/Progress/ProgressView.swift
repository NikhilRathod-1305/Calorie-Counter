import SwiftUI
import SwiftData

private enum ProgressRange: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case year = "1Y"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
}

struct ProgressTabView: View {
    @Query(sort: \WeightLogEntry.date) private var weightEntries: [WeightLogEntry]
    @Query(sort: \MealEntry.timestamp) private var mealEntries: [MealEntry]
    @Query private var profiles: [UserProfile]

    @State private var range: ProgressRange = .week

    private var profile: UserProfile { profiles.first ?? UserProfile() }
    private var goals: DailyGoals { NutritionGoalCalculator.compute(profile: profile) }

    private var rangedWeights: [WeightLogEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? .distantPast
        let filtered = weightEntries.filter { $0.date >= cutoff }
        return filtered.isEmpty ? Array(weightEntries.suffix(1)) : filtered
    }

    private var currentWeight: Double {
        weightEntries.last?.weightKg ?? profile.weightKg
    }

    private var startWeight: Double {
        rangedWeights.first?.weightKg ?? currentWeight
    }

    private var weightDelta: Double {
        currentWeight - startWeight
    }

    private var fromStartDelta: Double {
        currentWeight - (weightEntries.first?.weightKg ?? currentWeight)
    }

    private var bmi: Double {
        let heightM = profile.heightCm / 100
        guard heightM > 0 else { return 0 }
        return currentWeight / (heightM * heightM)
    }

    private var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal range"
        case 25..<30: return "Overweight"
        default: return "High range"
        }
    }

    // MARK: Daily intake (calories/protein)

    private struct DailyIntake: Identifiable {
        let day: Date
        let calories: Double
        let protein: Double
        let hasEntries: Bool
        var id: Date { day }
    }

    /// Number of days grouped into each bar: 1 for week/month/3-month (daily bars),
    /// 7 for year (weekly bars, so the chart stays at a readable ~52 bars instead of 365).
    private var intakeBucketDays: Int {
        range == .year ? 7 : 1
    }

    private var dailyIntake: [DailyIntake] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let startDay = cal.date(byAdding: .day, value: -(range.days - 1), to: today) ?? today

        let grouped = Dictionary(grouping: mealEntries) { cal.startOfDay(for: $0.timestamp) }

        var results: [DailyIntake] = []
        var bucketStart = startDay
        let bucketSize = intakeBucketDays
        while bucketStart <= today {
            let bucketEnd = cal.date(byAdding: .day, value: bucketSize - 1, to: bucketStart) ?? bucketStart
            var totals = NutritionValues.zero
            var daysWithEntries = 0
            var day = bucketStart
            while day <= bucketEnd && day <= today {
                if let entries = grouped[day] {
                    totals = totals + entries.reduce(NutritionValues.zero) { $0 + $1.nutrition }
                    daysWithEntries += 1
                }
                guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            let divisor = max(1, daysWithEntries)
            results.append(DailyIntake(
                day: bucketStart,
                calories: bucketSize == 1 ? totals.calories : totals.calories / Double(divisor),
                protein: bucketSize == 1 ? totals.protein : totals.protein / Double(divisor),
                hasEntries: daysWithEntries > 0
            ))
            guard let next = cal.date(byAdding: .day, value: bucketSize, to: bucketStart) else { break }
            bucketStart = next
        }
        return results
    }

    private var maxCalorieValue: Double {
        max(dailyIntake.map { $0.calories }.max() ?? 0, Double(goals.calorieGoal), 1)
    }

    private var loggedIntakeDays: [DailyIntake] {
        dailyIntake.filter { $0.hasEntries }
    }

    private var averageCalories: Double {
        guard !loggedIntakeDays.isEmpty else { return 0 }
        return loggedIntakeDays.reduce(0) { $0 + $1.calories } / Double(loggedIntakeDays.count)
    }

    private var averageProtein: Double {
        guard !loggedIntakeDays.isEmpty else { return 0 }
        return loggedIntakeDays.reduce(0) { $0 + $1.protein } / Double(loggedIntakeDays.count)
    }

    private var loggingStreak: Int {
        let cal = Calendar.current
        let loggedDays = Set(mealEntries.map { cal.startOfDay(for: $0.timestamp) })
        var streak = 0
        var day = cal.startOfDay(for: Date())
        while loggedDays.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private var milestones: [(icon: String, title: String, subtitle: String, achieved: Bool)] {
        let lost = max(0, -fromStartDelta)
        let goalGap = abs(currentWeight - profile.targetWeightKg)
        return [
            (
                "trophy.fill",
                "\(Int(lost))kg Lost!",
                lost > 0 ? "Since you started" : "Log more weigh-ins to see progress",
                lost >= 1
            ),
            (
                "target",
                "Reach goal weight",
                goalGap < 0.5 ? "You're there!" : "\(String(format: "%.1f", goalGap))kg away from \(Int(profile.targetWeightKg))kg",
                goalGap < 0.5
            ),
            (
                "flame.fill",
                "Healthy BMI",
                bmiCategory == "Normal range" ? "You're in range" : "Keep going",
                bmiCategory == "Normal range"
            )
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar()

                ScrollView {
                    GlassEffectContainer(spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Progress")
                                .font(Theme.Font.display(24))
                                .foregroundStyle(Theme.textPrimary)

                            PillSegmentedControl(
                                options: ProgressRange.allCases.map { ($0, $0.rawValue) },
                                selection: $range
                            )

                            streakCard

                            intakeCard

                            weightCard

                            HStack(spacing: 10) {
                                bentoCard(icon: "scalemass.fill", label: "BMI", value: String(format: "%.1f", bmi), subtitle: bmiCategory, color: Theme.steps)
                                bentoCard(
                                    icon: "flag.fill",
                                    label: "FROM START",
                                    value: "\(fromStartDelta > 0 ? "+" : "")\(String(format: "%.1f", fromStartDelta))kg",
                                    subtitle: "Goal: \(Int(profile.targetWeightKg))kg",
                                    color: Theme.exercise
                                )
                            }

                            Text("Milestones")
                                .font(Theme.Font.text(16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.top, 4)

                            VStack(spacing: 10) {
                                ForEach(Array(milestones.enumerated()), id: \.offset) { _, milestone in
                                    milestoneRow(milestone)
                                }
                            }

                            Color.clear.frame(height: 90)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .background(Theme.groupedBackground.ignoresSafeArea())
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: Streak

    private var streakCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Theme.exercise.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.exercise)
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(loggingStreak)")
                        .font(Theme.Font.display(24))
                        .foregroundStyle(Theme.textPrimary)
                    Text(loggingStreak == 1 ? "day streak" : "day streak")
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Text(loggingStreak > 0 ? "Keep logging to grow your streak" : "Log food today to start a streak")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textFaint)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    // MARK: Calories / Protein intake chart

    private var intakeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Daily Intake")
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                HStack(spacing: 14) {
                    legendDot(color: Theme.accent, label: "Calories")
                    legendDot(color: Theme.proteinColor, label: "Protein")
                }
            }

            if loggedIntakeDays.isEmpty {
                Text("Log food to see your averages")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textFaint)
            } else {
                HStack(spacing: 18) {
                    averageStat(label: "Avg Calories", value: "\(Int(averageCalories))", unit: "kcal", color: Theme.accent)
                    averageStat(label: "Avg Protein", value: "\(Int(averageProtein))", unit: "g", color: Theme.proteinColor)
                }
            }

            intakeChart
                .frame(height: 160)

            HStack {
                ForEach(Array(intakeAxisLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(Theme.Font.text(9))
                        .foregroundStyle(Theme.textFaint)
                    if index < intakeAxisLabels.count - 1 { Spacer(minLength: 0) }
                }
            }
        }
        .padding(16)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(Theme.Font.text(10))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func averageStat(label: String, value: String, unit: String, color: Color) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(value)
                .font(Theme.Font.display(18))
                .foregroundStyle(color)
            Text(unit)
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textTertiary)
            Text(label)
                .font(Theme.Font.text(10))
                .foregroundStyle(Theme.textFaint)
        }
    }

    private var intakeChart: some View {
        let data = dailyIntake
        return GeometryReader { geo in
            let count = max(1, data.count)
            let slot = geo.size.width / CGFloat(count)
            let barWidth = min(22, slot * 0.55)
            let goalY = geo.size.height * (1 - CGFloat(min(1, Double(goals.calorieGoal) / maxCalorieValue)))

            ZStack(alignment: .bottomLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: goalY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: goalY))
                }
                .stroke(Theme.textFaint, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                Text("Goal")
                    .font(Theme.Font.text(8, weight: .medium))
                    .foregroundStyle(Theme.textFaint)
                    .padding(.horizontal, 4)
                    .background(Theme.cardBackground)
                    .position(x: geo.size.width - 16, y: max(8, goalY))

                ForEach(Array(data.enumerated()), id: \.element.id) { index, day in
                    let x = slot * CGFloat(index) + slot / 2
                    let calHeight = geo.size.height * CGFloat(day.calories / maxCalorieValue)
                    let proteinHeight = geo.size.height * CGFloat(min(1, day.protein / max(1, Double(goals.proteinG))))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.accent.opacity(day.calories > 0 ? 0.85 : 0.12))
                        .frame(width: barWidth, height: max(2, calHeight))
                        .position(x: x, y: geo.size.height - max(2, calHeight) / 2)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.proteinColor.opacity(day.protein > 0 ? 0.9 : 0))
                        .frame(width: barWidth * 0.4, height: max(0, proteinHeight))
                        .position(x: x, y: geo.size.height - max(0, proteinHeight) / 2)
                }
            }
        }
    }

    private var intakeAxisLabels: [String] {
        let data = dailyIntake
        guard !data.isEmpty else { return [] }
        let formatter = DateFormatter()

        switch range {
        case .week:
            formatter.dateFormat = "EEEEE"
            return data.map { formatter.string(from: $0.day) }
        case .month, .threeMonths:
            formatter.dateFormat = "d"
            let stride = max(1, data.count / 6)
            return data.enumerated().compactMap { index, entry in
                index % stride == 0 ? formatter.string(from: entry.day) : nil
            }
        case .year:
            formatter.dateFormat = "MMM"
            let cal = Calendar.current
            var seen = Set<Int>()
            var labels: [String] = []
            for entry in data {
                let month = cal.component(.month, from: entry.day)
                if !seen.contains(month) {
                    seen.insert(month)
                    labels.append(formatter.string(from: entry.day))
                }
            }
            return labels
        }
    }

    // MARK: Weight card

    private var weightCard: some View {
        let weights = rangedWeights.isEmpty ? [WeightLogEntry(weightKg: currentWeight)] : rangedWeights
        let values = weights.map { $0.weightKg } + [profile.targetWeightKg]
        let wMin = (values.min() ?? 0) - 1
        let wMax = (values.max() ?? 1) + 1
        let range = max(0.1, wMax - wMin)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Weight")
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", currentWeight))
                            .font(Theme.Font.display(30))
                            .foregroundStyle(Theme.textPrimary)
                        Text("kg")
                            .font(Theme.Font.text(13))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Spacer()
                if weightDelta != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: weightDelta < 0 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(String(format: "%.1f", abs(weightDelta))) kg")
                            .font(Theme.Font.text(12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.secondarySoft, in: Capsule())
                }
            }

            GeometryReader { geo in
                let goalY = geo.size.height * (1 - CGFloat((profile.targetWeightKg - wMin) / range))
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geo.size.width, y: goalY))
                    }
                    .stroke(Theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                    if weights.count > 1 {
                        Path { path in
                            for (index, entry) in weights.enumerated() {
                                let x = geo.size.width * CGFloat(index) / CGFloat(weights.count - 1)
                                let y = geo.size.height * (1 - CGFloat((entry.weightKg - wMin) / range))
                                if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Theme.secondary, lineWidth: 2)

                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height))
                            for (index, entry) in weights.enumerated() {
                                let x = geo.size.width * CGFloat(index) / CGFloat(weights.count - 1)
                                let y = geo.size.height * (1 - CGFloat((entry.weightKg - wMin) / range))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(colors: [Theme.secondary.opacity(0.18), Theme.secondary.opacity(0)], startPoint: .top, endPoint: .bottom)
                        )
                    }

                    ForEach(Array(weights.enumerated()), id: \.offset) { index, entry in
                        let x = weights.count > 1 ? geo.size.width * CGFloat(index) / CGFloat(weights.count - 1) : geo.size.width / 2
                        let y = geo.size.height * (1 - CGFloat((entry.weightKg - wMin) / range))
                        Circle()
                            .fill(Theme.secondary)
                            .frame(width: 7, height: 7)
                            .position(x: x, y: y)
                    }
                }
            }
            .frame(height: 120)

            HStack {
                ForEach(monthLabels(for: weights), id: \.self) { label in
                    Text(label)
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textFaint)
                    if label != monthLabels(for: weights).last { Spacer() }
                }
            }
        }
        .padding(16)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private func monthLabels(for weights: [WeightLogEntry]) -> [String] {
        guard let first = weights.first?.date, let last = weights.last?.date else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        if weights.count < 2 || first == last { return [formatter.string(from: last)] }
        let mid = weights[weights.count / 2].date
        return [formatter.string(from: first), formatter.string(from: mid), formatter.string(from: last)]
    }

    // MARK: Bento cards

    private func bentoCard(icon: String, label: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(Theme.Font.text(10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(0.5)
            }
            Text(value)
                .font(Theme.Font.display(22))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    // MARK: Milestones

    private func milestoneRow(_ milestone: (icon: String, title: String, subtitle: String, achieved: Bool)) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(milestone.achieved ? Theme.accentSoft : Theme.hairline)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: milestone.achieved ? milestone.icon : "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(milestone.achieved ? Theme.accent : Theme.textFaint)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(milestone.achieved ? Theme.textPrimary : Theme.textFaint)
                Text(milestone.subtitle)
                    .font(Theme.Font.text(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .opacity(milestone.achieved ? 1 : 0.65)
    }
}
