import SwiftUI
import SwiftData

struct GoalsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let created = UserProfile()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    private var goals: DailyGoals { NutritionGoalCalculator.compute(profile: profile) }

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    statsGrid

                    sectionLabel("Activity level")
                    PillSegmentedControl(
                        options: ActivityLevel.allCases.map { ($0, $0.rawValue) },
                        selection: activityBinding
                    )

                    sectionLabel("Macro split")
                    PillSegmentedControl(
                        options: MacroPreset.allCases.map { ($0, $0.rawValue) },
                        selection: macroBinding,
                        style: .outlined
                    )

                    goalCard

                    Color.clear.frame(height: 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.text(12))
            .foregroundStyle(Theme.textSecondary)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            numberField(label: "Height (cm)", value: heightBinding)
            numberField(label: "Age", value: ageBinding)
            numberField(label: "Target weight (kg)", value: targetWeightBinding)
        }
    }

    private func numberField(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textSecondary)
            TextField("", value: value, format: .number)
                .keyboardType(.decimalPad)
                .font(Theme.Font.display(18))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily calorie goal")
                .font(Theme.Font.text(12))
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(goals.calorieGoal)")
                    .font(Theme.Font.display(30))
                    .foregroundStyle(Theme.textPrimary)
                Text(" cal")
                    .font(Theme.Font.text(13))
                    .foregroundStyle(Theme.textTertiary)
            }
            HStack {
                Text("Protein \(goals.proteinG)g")
                Spacer()
                Text("Carbs \(goals.carbG)g")
                Spacer()
                Text("Fat \(goals.fatG)g")
            }
            .font(Theme.Font.text(12))
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private var heightBinding: Binding<Double> {
        Binding(get: { profile.heightCm }, set: { profile.heightCm = $0; try? modelContext.save() })
    }
    private var ageBinding: Binding<Double> {
        Binding(get: { Double(profile.age) }, set: { profile.age = Int($0); try? modelContext.save() })
    }
    private var targetWeightBinding: Binding<Double> {
        Binding(get: { profile.targetWeightKg }, set: { profile.targetWeightKg = $0; try? modelContext.save() })
    }
    private var activityBinding: Binding<ActivityLevel> {
        Binding(get: { profile.activityLevel }, set: { profile.activityLevel = $0; try? modelContext.save() })
    }
    private var macroBinding: Binding<MacroPreset> {
        Binding(get: { profile.macroPreset }, set: { profile.macroPreset = $0; try? modelContext.save() })
    }
}
