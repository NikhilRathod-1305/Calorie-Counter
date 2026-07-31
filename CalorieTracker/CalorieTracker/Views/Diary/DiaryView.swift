import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.timestamp) private var allEntries: [MealEntry]
    @Query private var profiles: [UserProfile]
    @Query private var waterEntries: [WaterLogEntry]
    @Query(sort: \ExerciseEntry.timestamp) private var exerciseEntries: [ExerciseEntry]

    @State private var viewedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var sheetMealType: MealType?
    @State private var editingMealEntry: MealEntry?
    @State private var showingLogExercise = false
    @State private var editingExerciseEntry: ExerciseEntry?
    @State private var toastMessage: String?

    private var isToday: Bool { Calendar.current.isDateInToday(viewedDate) }

    private var profile: UserProfile { profiles.first ?? UserProfile() }
    private var goals: DailyGoals { NutritionGoalCalculator.compute(profile: profile) }

    private var todaysEntries: [MealEntry] {
        let cal = Calendar.current
        return allEntries.filter { cal.isDate($0.timestamp, inSameDayAs: viewedDate) }
    }

    private var todaysWater: [WaterLogEntry] {
        let cal = Calendar.current
        return waterEntries.filter { cal.isDate($0.date, inSameDayAs: viewedDate) }
    }

    private var todaysExercise: [ExerciseEntry] {
        let cal = Calendar.current
        return exerciseEntries.filter { cal.isDate($0.timestamp, inSameDayAs: viewedDate) }
    }

    private var totals: NutritionValues {
        todaysEntries.reduce(NutritionValues.zero) { $0 + $1.nutrition }
    }

    private var exerciseCalories: Double {
        todaysExercise.reduce(0) { $0 + $1.caloriesBurned }
    }

    private var waterMl: Int { todaysWater.reduce(0) { $0 + $1.milliliters } }

    private var remaining: Int {
        goals.calorieGoal + Int(exerciseCalories) - Int(totals.calories)
    }

    private func entries(for meal: MealType) -> [MealEntry] {
        todaysEntries.filter { $0.mealType == meal }.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar()

                ScrollView {
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 16) {
                            dateHeader

                            summaryCard

                            ForEach(MealType.allCases.sorted { $0.sortOrder < $1.sortOrder }, id: \.self) { meal in
                                mealSection(meal)
                            }

                            exerciseSection

                            micronutrientSection

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
        .toast(toastMessage)
        .sheet(item: $sheetMealType) { meal in
            LogFoodSheet(
                initialMode: .browse,
                mealType: meal,
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
        .sheet(isPresented: $showingLogExercise) {
            LogExerciseSheet(
                onClose: { showingLogExercise = false },
                onSave: { name, calories, duration in
                    let entry = ExerciseEntry(name: name, caloriesBurned: calories, durationMinutes: duration, timestamp: Date())
                    modelContext.insert(entry)
                    try? modelContext.save()
                    showingLogExercise = false
                    showToast("Exercise logged")
                }
            )
            .presentationDetents([.height(340)])
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
                    showToast("Updated")
                }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
    }

    private func deleteMealEntry(_ entry: MealEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    private func deleteExerciseEntry(_ entry: ExerciseEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { toastMessage = nil }
        }
    }

    // MARK: Date header

    private var dateHeader: some View {
        HStack {
            Button {
                shiftDay(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32, height: 32)
                    .glassCardAlt(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(dateLabel)
                .font(Theme.Font.text(16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button {
                shiftDay(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isToday ? Theme.textFaint.opacity(0.4) : Theme.textSecondary)
                    .frame(width: 32, height: 32)
                    .glassCardAlt(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isToday)
        }
    }

    private func shiftDay(by days: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: viewedDate) else { return }
        let today = Calendar.current.startOfDay(for: Date())
        withAnimation { viewedDate = min(newDate, today) }
    }

    private var dateLabel: String {
        let cal = Calendar.current
        if isToday { return "Today" }
        if cal.isDateInYesterday(viewedDate) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: viewedDate)
    }

    // MARK: Summary card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(totals.calories))")
                        .font(Theme.Font.display(32))
                        .foregroundStyle(Theme.accent)
                    Text("Calories Eaten")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(max(0, remaining))")
                        .font(Theme.Font.display(22))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Remaining")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            VStack(spacing: 10) {
                macroBar(label: "Protein", value: totals.protein, goal: goals.proteinG, color: Theme.proteinColor)
                macroBar(label: "Carbs", value: totals.carbs, goal: goals.carbG, color: Theme.carbColor)
                macroBar(label: "Fat", value: totals.fat, goal: goals.fatG, color: Theme.fatColor)
            }
        }
        .padding(16)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private func macroBar(label: String, value: Double, goal: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Int(value))g / \(goal)g")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Theme.hairline)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * min(1, value / Double(max(1, goal))))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: Meal sections

    private func servingLabel(for entry: MealEntry) -> String {
        if let food = entry.foodItem {
            let ratio = entry.quantity / food.servingSize
            let servings = ratio == ratio.rounded() ? "\(Int(ratio))" : String(format: "%.1f", ratio)
            return "\(servings) × \(Int(food.servingSize))\(food.servingUnit)"
        }
        return "\(Int(entry.quantity))g"
    }

    private func mealSection(_ meal: MealType) -> some View {
        let mealEntries = entries(for: meal)
        let mealTotal = mealEntries.reduce(0.0) { $0 + $1.nutrition.calories }

        return VStack(spacing: 0) {
            HStack {
                Text("\(meal.emoji) \(meal.rawValue)")
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Int(mealTotal)) cal")
                    .font(Theme.Font.text(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if !mealEntries.isEmpty {
                Divider().overlay(Theme.hairline)
                ForEach(mealEntries) { entry in
                    SwipeToDeleteRow(
                        onTap: { editingMealEntry = entry },
                        onDelete: { deleteMealEntry(entry) }
                    ) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayName)
                                    .font(Theme.Font.text(13))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(servingLabel(for: entry))
                                    .font(Theme.Font.text(11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            Spacer()
                            Text("\(Int(entry.nutrition.calories)) cal")
                                .font(Theme.Font.text(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 14)
                }
            }

            Button {
                sheetMealType = meal
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Food")
                        .font(Theme.Font.text(13, weight: .semibold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    // MARK: Exercise

    private var exerciseSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("🏃 Exercise")
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("-\(Int(exerciseCalories)) cal")
                    .font(Theme.Font.text(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if !todaysExercise.isEmpty {
                Divider().overlay(Theme.hairline)
                ForEach(todaysExercise) { exercise in
                    SwipeToDeleteRow(
                        onTap: { editingExerciseEntry = exercise },
                        onDelete: { deleteExerciseEntry(exercise) }
                    ) {
                        HStack {
                            Text(exercise.name)
                                .font(Theme.Font.text(13))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("-\(Int(exercise.caloriesBurned)) cal")
                                .font(Theme.Font.text(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                }
            }

            if isToday {
                Button {
                    showingLogExercise = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add Exercise")
                            .font(Theme.Font.text(13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    // MARK: Micronutrients / water

    private var micronutrientSection: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            StatTile(label: "Fiber", value: "\(Int(totals.fiber))", unit: "g")
            StatTile(label: "Sugar", value: "\(Int(totals.sugar))", unit: "g")
            StatTile(label: "Sodium", value: "\(Int(totals.sodium))", unit: "mg")
            waterTile
        }
    }

    private var waterFillFraction: Double {
        min(1, Double(waterMl) / Double(max(1, profile.waterGoalMl)))
    }

    private var waterTile: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
                WaterWaveShape(fraction: waterFillFraction)
                    .fill(
                        LinearGradient(
                            colors: [Theme.water.opacity(0.55), Theme.water.opacity(0.28)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: waterFillFraction)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Water")
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            removeLastWater()
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(todaysWater.isEmpty ? Theme.textFaint : Theme.water)
                                .frame(width: 32, height: 32)
                                .glassCardAlt(Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!isToday || todaysWater.isEmpty)

                        Button {
                            addWater()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.water)
                                .frame(width: 32, height: 32)
                                .glassCardAlt(Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!isToday)
                    }
                }
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(waterMl)")
                        .font(Theme.Font.display(18))
                        .foregroundStyle(Theme.textPrimary)
                    Text("/ \(profile.waterGoalMl)ml")
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 130)
        .opacity(isToday ? 1 : 0.5)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private func addWater() {
        let entry = WaterLogEntry(milliliters: 250)
        modelContext.insert(entry)
        try? modelContext.save()
    }

    private func removeLastWater() {
        guard let last = todaysWater.max(by: { $0.date < $1.date }) else { return }
        modelContext.delete(last)
        try? modelContext.save()
    }
}

extension MealType: Identifiable {
    public var id: String { rawValue }
}
