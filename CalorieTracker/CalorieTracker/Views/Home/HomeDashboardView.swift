import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.timestamp) private var allEntries: [MealEntry]
    @Query private var profiles: [UserProfile]
    @Query(sort: \ExerciseEntry.timestamp) private var exerciseEntries: [ExerciseEntry]

    @State private var viewedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var sheetMealType: MealType?
    @State private var editingMealEntry: MealEntry?
    @State private var toastMessage: String?

    private var isToday: Bool { Calendar.current.isDateInToday(viewedDate) }
    private var profile: UserProfile { profiles.first ?? UserProfile() }
    private var goals: DailyGoals { NutritionGoalCalculator.compute(profile: profile) }

    /// Only top-level entries — a multi-item scan's nested items live under
    /// their parent's `children` and must not be counted as separate rows.
    private var viewedEntries: [MealEntry] {
        let cal = Calendar.current
        return allEntries.filter { $0.isTopLevel && cal.isDate($0.timestamp, inSameDayAs: viewedDate) }
    }

    private var viewedExercise: [ExerciseEntry] {
        let cal = Calendar.current
        return exerciseEntries.filter { cal.isDate($0.timestamp, inSameDayAs: viewedDate) }
    }

    private var totals: NutritionValues {
        viewedEntries.reduce(NutritionValues.zero) { $0 + $1.totalNutrition }
    }

    private var exerciseCaloriesBurned: Int {
        Int(viewedExercise.reduce(0) { $0 + $1.caloriesBurned })
    }

    private func entries(for meal: MealType) -> [MealEntry] {
        viewedEntries.filter { $0.mealType == meal }.sorted { $0.timestamp < $1.timestamp }
    }

    private func calorieProgress(for day: Date) -> Double {
        let cal = Calendar.current
        let dayCalories = allEntries
            .filter { $0.isTopLevel && cal.isDate($0.timestamp, inSameDayAs: day) }
            .reduce(0.0) { $0 + $1.totalNutrition.calories }
        guard goals.calorieGoal > 0 else { return 0 }
        return min(1, dayCalories / Double(goals.calorieGoal))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar()

                ScrollView {
                    VStack(spacing: 16) {
                        dateStripSection

                        VStack(spacing: 16) {
                            CalorieRingCard(
                                baseGoal: goals.calorieGoal,
                                food: Int(totals.calories),
                                exercise: exerciseCaloriesBurned,
                                carbs: totals.carbs,
                                carbGoal: goals.carbG,
                                protein: totals.protein,
                                proteinGoal: goals.proteinG,
                                fat: totals.fat,
                                fatGoal: goals.fatG
                            )

                            ForEach(MealType.allCases.sorted { $0.sortOrder < $1.sortOrder }, id: \.self) { meal in
                                mealSection(meal)
                            }

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)
                }
                .background(Theme.groupedBackground.ignoresSafeArea())
            }
            .navigationBarHidden(true)
        }
        .toast(toastMessage)
        .sheet(item: $sheetMealType) { meal in
            LogFoodSheet(
                initialMode: .browse,
                mealType: meal,
                date: viewedDate,
                onClose: { sheetMealType = nil },
                onAdded: {
                    sheetMealType = nil
                    showToast("Added to \(meal.rawValue)")
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .sheet(item: $editingMealEntry) { entry in
            LogFoodSheet(
                initialMode: .browse,
                mealType: entry.mealType,
                editingEntry: entry,
                onClose: { editingMealEntry = nil },
                onAdded: {
                    editingMealEntry = nil
                    showToast("Updated")
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
    }

    // MARK: Header + date strip + expandable month calendar

    private var dateStripSection: some View {
        ExpandableDateHeader(selectedDate: $viewedDate, progress: calorieProgress)
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { toastMessage = nil }
        }
    }

    private func deleteMealEntry(_ entry: MealEntry) {
        // The cascade delete rule on MealEntry.children removes nested items
        // automatically when a parent is deleted.
        modelContext.delete(entry)
        try? modelContext.save()
    }

    // MARK: Meal list

    private func servingLabel(for entry: MealEntry) -> String {
        if let food = entry.foodItem {
            let ratio = entry.quantity / food.servingSize
            let servings = ratio == ratio.rounded() ? "\(Int(ratio))" : String(format: "%.1f", ratio)
            return "\(servings) × \(Int(food.servingSize))\(food.servingUnit)"
        }
        // AI-parsed entries (scan/text/voice) with no linked FoodItem store a
        // portion multiplier in `quantity` (1.0 = the estimated portion, set
        // via QuantityStepper), not a gram weight — label it accordingly.
        let multiplier = entry.quantity
        if multiplier == 1 { return "1 portion" }
        let formatted = multiplier == multiplier.rounded() ? "\(Int(multiplier))" : String(format: "%.1f", multiplier)
        return "\(formatted)× portion"
    }

    private func mealSection(_ meal: MealType) -> some View {
        let mealEntries = entries(for: meal)
        let mealTotal = mealEntries.reduce(0.0) { $0 + $1.totalNutrition.calories }

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(meal.emoji)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.rawValue)
                        .font(Theme.Font.text(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(mealEntries.isEmpty ? "No entries yet" : "\(Int(mealTotal)) kcal")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Button {
                    sheetMealType = meal
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 36, height: 36)
                        .background(Theme.accent, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            if !mealEntries.isEmpty {
                Divider().overlay(Theme.hairline)
                ForEach(mealEntries) { entry in
                    mealEntryRow(entry)
                    Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 14)
                }
            }
        }
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    @ViewBuilder
    private func mealEntryRow(_ entry: MealEntry) -> some View {
        let children = entry.children ?? []
        let isGroup = !children.isEmpty

        SwipeToDeleteRow(
            onTap: { editingMealEntry = entry },
            onDelete: { deleteMealEntry(entry) }
        ) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayName)
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textPrimary)
                    Text(isGroup ? "\(children.count) items" : servingLabel(for: entry))
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Text("\(Int(entry.totalNutrition.calories)) cal")
                    .font(Theme.Font.text(12))
                    .foregroundStyle(Theme.textSecondary)
                if isGroup {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textFaint)
                        .padding(.leading, 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
    }
}

extension MealType: Identifiable {
    public var id: String { rawValue }
}
