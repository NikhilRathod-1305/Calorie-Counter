import SwiftUI
import SwiftData

private enum HistoryCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case food = "Food"
    case exercise = "Exercise"
    case weight = "Weight"
    case water = "Water"

    var id: String { rawValue }
}

private enum LogItem: Identifiable {
    case meal(MealEntry)
    case exercise(ExerciseEntry)
    case weight(WeightLogEntry)
    case water(WaterLogEntry)

    var id: String {
        switch self {
        case .meal(let e): return "meal-\(e.id)"
        case .exercise(let e): return "exercise-\(e.id)"
        case .weight(let e): return "weight-\(e.id)"
        case .water(let e): return "water-\(e.id)"
        }
    }

    var timestamp: Date {
        switch self {
        case .meal(let e): return e.timestamp
        case .exercise(let e): return e.timestamp
        case .weight(let e): return e.date
        case .water(let e): return e.date
        }
    }

    var category: HistoryCategory {
        switch self {
        case .meal: return .food
        case .exercise: return .exercise
        case .weight: return .weight
        case .water: return .water
        }
    }

    var title: String {
        switch self {
        case .meal(let e): return e.displayName
        case .exercise(let e): return e.name
        case .weight: return "Weight logged"
        case .water: return "Water logged"
        }
    }

    var subtitle: String {
        let time: String = {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: timestamp)
        }()
        switch self {
        case .meal(let e): return "\(time) · \(e.mealType.rawValue)"
        case .exercise: return time
        case .weight: return time
        case .water: return time
        }
    }

    var trailingText: String {
        switch self {
        case .meal(let e): return "\(Int(e.nutrition.calories)) kcal"
        case .exercise(let e): return "-\(Int(e.caloriesBurned)) kcal"
        case .weight(let e): return "\(String(format: "%.1f", e.weightKg)) kg"
        case .water(let e): return "\(e.milliliters) ml"
        }
    }

    var icon: String {
        switch self {
        case .meal: return "fork.knife"
        case .exercise: return "figure.run"
        case .weight: return "scalemass.fill"
        case .water: return "drop.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .meal: return Theme.accent
        case .exercise: return Theme.exercise
        case .weight: return Theme.steps
        case .water: return Theme.water
        }
    }

    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return title.localizedCaseInsensitiveContains(query)
    }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var mealEntries: [MealEntry]
    @Query(sort: \ExerciseEntry.timestamp, order: .reverse) private var exerciseEntries: [ExerciseEntry]
    @Query(sort: \WeightLogEntry.date, order: .reverse) private var weightEntries: [WeightLogEntry]
    @Query(sort: \WaterLogEntry.date, order: .reverse) private var waterEntries: [WaterLogEntry]
    @Query private var profiles: [UserProfile]

    @State private var category: HistoryCategory = .all
    @State private var searchText: String = ""
    @State private var editingMealEntry: MealEntry?
    @State private var editingExerciseEntry: ExerciseEntry?
    @State private var editingWeightEntry: WeightLogEntry?
    @State private var editingWaterEntry: WaterLogEntry?

    private var profile: UserProfile { profiles.first ?? UserProfile() }

    private var allItems: [LogItem] {
        var items: [LogItem] = []
        items.append(contentsOf: mealEntries.map(LogItem.meal))
        items.append(contentsOf: exerciseEntries.map(LogItem.exercise))
        items.append(contentsOf: weightEntries.map(LogItem.weight))
        items.append(contentsOf: waterEntries.map(LogItem.water))
        return items.sorted { $0.timestamp > $1.timestamp }
    }

    private var filteredItems: [LogItem] {
        allItems.filter { item in
            (category == .all || item.category == category) && item.matches(searchText)
        }
    }

    private var groupedItems: [(label: String, items: [LogItem])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filteredItems) { cal.startOfDay(for: $0.timestamp) }
        return groups.keys.sorted(by: >).map { day in
            let label: String
            if cal.isDateInToday(day) { label = "Today" }
            else if cal.isDateInYesterday(day) { label = "Yesterday" }
            else {
                let f = DateFormatter()
                f.dateFormat = "EEEE, MMM d"
                label = f.string(from: day)
            }
            return (label, groups[day] ?? [])
        }
    }

    private var todaysCalories: Int {
        let cal = Calendar.current
        return mealEntries
            .filter { cal.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + Int($1.nutrition.calories) }
    }

    private var todaysLogCount: Int {
        let cal = Calendar.current
        return allItems.filter { cal.isDateInToday($0.timestamp) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 16) {
                    categoryPills

                    statCards

                    if groupedItems.isEmpty {
                        emptyState("No logs found")
                            .padding(.top, 60)
                    } else {
                        ForEach(groupedItems, id: \.label) { group in
                            dayGroup(label: group.label, items: group.items)
                        }
                    }

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingMealEntry) { entry in
            LogFoodSheet(
                initialMode: .browse,
                mealType: entry.mealType,
                editingEntry: entry,
                onClose: { editingMealEntry = nil },
                onAdded: { editingMealEntry = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .sheet(item: $editingExerciseEntry) { entry in
            LogExerciseSheet(
                editingEntry: entry,
                onClose: { editingExerciseEntry = nil },
                onSave: { name, calories, duration in
                    entry.name = name
                    entry.caloriesBurned = calories
                    entry.durationMinutes = duration
                    try? modelContext.save()
                    editingExerciseEntry = nil
                }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .sheet(item: $editingWeightEntry) { entry in
            LogWeightSheet(
                initialWeight: entry.weightKg,
                editingEntry: entry,
                onClose: { editingWeightEntry = nil },
                onSave: { newWeight, date in
                    entry.weightKg = newWeight
                    entry.date = date
                    if entry.id == weightEntries.first?.id {
                        profile.weightKg = newWeight
                    }
                    try? modelContext.save()
                    editingWeightEntry = nil
                }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .sheet(item: $editingWaterEntry) { entry in
            LogWaterSheet(
                editingEntry: entry,
                onClose: { editingWaterEntry = nil },
                onSave: { ml, date in
                    entry.milliliters = ml
                    entry.date = date
                    try? modelContext.save()
                    editingWaterEntry = nil
                }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textFaint)
            TextField("Search logs…", text: $searchText)
                .font(Theme.Font.text(14))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glassCardAlt(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryCategory.allCases) { cat in
                    let isSelected = cat == category
                    Text(cat.rawValue)
                        .font(Theme.Font.text(12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Theme.onAccent : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isSelected ? Theme.accent : Theme.cardBackgroundAlt, in: Capsule())
                        .contentShape(Capsule())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { category = cat }
                        }
                }
            }
        }
    }

    private var statCards: some View {
        HStack(spacing: 10) {
            StatTile(label: "Total Calories", value: "\(todaysCalories)", unit: "kcal")
            StatTile(label: "Logs Today", value: "\(todaysLogCount)", unit: "entries")
        }
    }

    private func dayGroup(label: String, items: [LogItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Theme.Font.display(16))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    row(for: item)
                    if index < items.count - 1 {
                        Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 58)
                    }
                }
            }
            .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }

    private func row(for item: LogItem) -> some View {
        SwipeToDeleteRow(
            onTap: { edit(item) },
            onDelete: { delete(item) }
        ) {
            HStack(spacing: 12) {
                Circle()
                    .fill(item.iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: item.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(item.iconColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(Theme.Font.text(13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(item.subtitle)
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Text(item.trailingText)
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private func edit(_ item: LogItem) {
        switch item {
        case .meal(let e): editingMealEntry = e
        case .exercise(let e): editingExerciseEntry = e
        case .weight(let e): editingWeightEntry = e
        case .water(let e): editingWaterEntry = e
        }
    }

    private func delete(_ item: LogItem) {
        switch item {
        case .meal(let e): modelContext.delete(e)
        case .exercise(let e): modelContext.delete(e)
        case .weight(let e): modelContext.delete(e)
        case .water(let e): modelContext.delete(e)
        }
        try? modelContext.save()
    }

    private func emptyState(_ message: String) -> some View {
        VStack {
            Text(message)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity)
    }
}
