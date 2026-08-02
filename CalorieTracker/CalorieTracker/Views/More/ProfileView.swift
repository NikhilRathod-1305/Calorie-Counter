import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showingLogWeight = false

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let created = UserProfile()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    sectionLabel("Biological sex")
                    PillSegmentedControl(
                        options: Sex.allCases.map { ($0, $0.rawValue) },
                        selection: sexBinding
                    )

                    sectionLabel("Goal")
                    PillSegmentedControl(
                        options: GoalType.allCases.map { ($0, $0.rawValue) },
                        selection: goalTypeBinding
                    )

                    sectionLabel("Activity level")
                    PillSegmentedControl(
                        options: ActivityLevel.allCases.map { ($0, $0.rawValue) },
                        selection: activityBinding
                    )

                    detailsGrid

                    NavigationLink {
                        GoalsSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "flag")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.accent)
                            Text("Calorie & Macro Goals")
                                .font(Theme.Font.text(14))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textFaint)
                        }
                        .padding(14)
                        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                    }
                    .buttonStyle(.plain)

                    Color.clear.frame(height: 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
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

    private var header: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Theme.accent.opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(format: "%.1f", profile.weightKg))kg")
                    .font(Theme.Font.display(20))
                    .foregroundStyle(Theme.textPrimary)
                Text("Goal: \(String(format: "%.1f", profile.targetWeightKg))kg")
                    .font(Theme.Font.text(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                showingLogWeight = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(width: 34, height: 34)
                    .glassEffect(.regular.tint(Theme.accent).interactive(), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.text(12))
            .foregroundStyle(Theme.textSecondary)
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            numberField(label: "Age", value: ageBinding)
            numberField(label: "Height (cm)", value: heightBinding)
            numberField(label: "Current weight (kg)", value: weightBinding)
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

    private var sexBinding: Binding<Sex> {
        Binding(get: { profile.sex }, set: { profile.sex = $0; try? modelContext.save() })
    }
    private var goalTypeBinding: Binding<GoalType> {
        Binding(get: { profile.goalType }, set: { profile.goalType = $0; try? modelContext.save() })
    }
    private var activityBinding: Binding<ActivityLevel> {
        Binding(get: { profile.activityLevel }, set: { profile.activityLevel = $0; try? modelContext.save() })
    }
    private var ageBinding: Binding<Double> {
        Binding(get: { Double(profile.age) }, set: { profile.age = Int($0); try? modelContext.save() })
    }
    private var heightBinding: Binding<Double> {
        Binding(get: { profile.heightCm }, set: { profile.heightCm = $0; try? modelContext.save() })
    }
    private var weightBinding: Binding<Double> {
        Binding(get: { profile.weightKg }, set: { profile.weightKg = $0; try? modelContext.save() })
    }
    private var targetWeightBinding: Binding<Double> {
        Binding(get: { profile.targetWeightKg }, set: { profile.targetWeightKg = $0; try? modelContext.save() })
    }
}
