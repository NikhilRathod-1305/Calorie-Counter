import SwiftUI
import SwiftData

struct WaterExerciseGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let created = UserProfile()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily water goal")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 6) {
                            TextField("", value: waterGoalBinding, format: .number)
                                .keyboardType(.numberPad)
                                .font(Theme.Font.display(24))
                                .foregroundStyle(Theme.textPrimary)
                            Text("ml")
                                .font(Theme.Font.text(13))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weekly exercise goal")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 6) {
                            TextField("", value: exerciseGoalBinding, format: .number)
                                .keyboardType(.numberPad)
                                .font(Theme.Font.display(24))
                                .foregroundStyle(Theme.textPrimary)
                            Text("min / week")
                                .font(Theme.Font.text(13))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Text("The general recommendation is 150 minutes of moderate activity per week.")
                            .font(Theme.Font.text(11))
                            .foregroundStyle(Theme.textFaint)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))

                    Color.clear.frame(height: 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Water & Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var waterGoalBinding: Binding<Int> {
        Binding(get: { profile.waterGoalMl }, set: { profile.waterGoalMl = max(0, $0); try? modelContext.save() })
    }
    private var exerciseGoalBinding: Binding<Int> {
        Binding(get: { profile.weeklyExerciseGoalMinutes }, set: { profile.weeklyExerciseGoalMinutes = max(0, $0); try? modelContext.save() })
    }
}
