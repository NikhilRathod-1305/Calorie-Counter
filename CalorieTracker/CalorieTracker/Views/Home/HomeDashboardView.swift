import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.timestamp) private var allEntries: [MealEntry]
    @Query private var profiles: [UserProfile]
    @Query(sort: \ExerciseEntry.timestamp) private var exerciseEntries: [ExerciseEntry]
    @Query(sort: \WeightLogEntry.date) private var weightEntries: [WeightLogEntry]

    @State private var showingGoals = false
    @State private var showingLogWeight = false

    private var profile: UserProfile { profiles.first ?? UserProfile() }
    private var goals: DailyGoals { NutritionGoalCalculator.compute(profile: profile) }

    private var todaysEntries: [MealEntry] {
        let cal = Calendar.current
        return allEntries.filter { cal.isDateInToday($0.timestamp) }
    }

    private var todaysExercise: [ExerciseEntry] {
        let cal = Calendar.current
        return exerciseEntries.filter { cal.isDateInToday($0.timestamp) }
    }

    private var totals: NutritionValues {
        todaysEntries.reduce(NutritionValues.zero) { $0 + $1.nutrition }
    }

    private var exerciseCaloriesBurned: Int {
        Int(todaysExercise.reduce(0) { $0 + $1.caloriesBurned })
    }

    private var recentWeights: [WeightLogEntry] {
        Array(weightEntries.suffix(8))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar()

                ScrollView {
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 16) {
                            CalorieRingCard(
                                baseGoal: goals.calorieGoal,
                                food: Int(totals.calories),
                                exercise: exerciseCaloriesBurned,
                                onEdit: { showingGoals = true }
                            )

                            StepsWidgetCard()

                            WaterWidgetCard()

                            WeightWidgetCard(
                                currentWeightKg: profile.weightKg,
                                targetWeightKg: profile.targetWeightKg,
                                recentEntries: recentWeights,
                                onLogWeight: { showingLogWeight = true }
                            )

                            Color.clear.frame(height: 100)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .background(Theme.groupedBackground.ignoresSafeArea())
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingGoals) {
                GoalsSettingsView()
            }
        }
        .sheet(isPresented: $showingLogWeight) {
            LogWeightSheet(
                initialWeight: profile.weightKg,
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
    }
}
