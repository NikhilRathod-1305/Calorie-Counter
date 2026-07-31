import SwiftUI
import SwiftData

struct OnboardingDraft {
    var goalType: GoalType?
    var sex: Sex?
    var birthday: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var heightCm: Double?
    var weightKg: Double?
    var targetWeightKg: Double?
    var activityLevel: ActivityLevel?
    var weeklyRateKg: Double = 0.5
    var macroPreset: MacroPreset?

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 25
    }
}

struct OnboardingFlowView: View {
    let onComplete: (UserProfile) -> Void

    @State private var step: Int = 0
    @State private var draft = OnboardingDraft()

    private let totalSteps = 9

    var body: some View {
        Group {
            switch step {
            case 0: goalStep
            case 1: sexStep
            case 2: birthdayStep
            case 3: heightWeightStep
            case 4: activityStep
            case 5: targetWeightStep
            case 6: rateStep
            case 7: dietStep
            default: summaryStep
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    private func goBack() { if step > 0 { step -= 1 } }
    private func goNext() { if step < totalSteps { step += 1 } }

    // MARK: Step 0 — Goal

    private var goalStep: some View {
        OnboardingQuestionScreen(
            step: 1, totalSteps: totalSteps,
            title: "What's your goal?",
            subtitle: "This shapes your daily calorie target.",
            canGoBack: false, canContinue: draft.goalType != nil,
            onBack: goBack, onContinue: goNext
        ) {
            VStack(spacing: 10) {
                ForEach(GoalType.allCases) { goal in
                    OnboardingOptionCard(title: goal.rawValue, subtitle: nil, isSelected: draft.goalType == goal) {
                        draft.goalType = goal
                    }
                }
            }
        }
    }

    // MARK: Step 1 — Sex

    private var sexStep: some View {
        OnboardingQuestionScreen(
            step: 2, totalSteps: totalSteps,
            title: "What's your sex?",
            subtitle: "Used to estimate your calorie needs accurately.",
            canGoBack: true, canContinue: draft.sex != nil,
            onBack: goBack, onContinue: goNext
        ) {
            VStack(spacing: 10) {
                ForEach(Sex.allCases) { sex in
                    OnboardingOptionCard(title: sex.rawValue, subtitle: nil, isSelected: draft.sex == sex) {
                        draft.sex = sex
                    }
                }
            }
        }
    }

    // MARK: Step 2 — Birthday

    private var birthdayStep: some View {
        OnboardingQuestionScreen(
            step: 3, totalSteps: totalSteps,
            title: "When were you born?",
            subtitle: nil,
            canGoBack: true, canContinue: true,
            onBack: goBack, onContinue: goNext
        ) {
            DatePicker("", selection: $draft.birthday, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Step 3 — Height / weight

    private var heightWeightStep: some View {
        OnboardingQuestionScreen(
            step: 4, totalSteps: totalSteps,
            title: "Height & current weight",
            subtitle: nil,
            canGoBack: true, canContinue: (draft.heightCm ?? 0) > 0 && (draft.weightKg ?? 0) > 0,
            onBack: goBack, onContinue: {
                if draft.targetWeightKg == nil { draft.targetWeightKg = draft.weightKg }
                goNext()
            }
        ) {
            GlassEffectContainer(spacing: 14) {
                VStack(spacing: 14) {
                    onboardingNumberField(label: "Height (cm)", value: Binding(get: { draft.heightCm ?? 0 }, set: { draft.heightCm = $0 }))
                    onboardingNumberField(label: "Current weight (kg)", value: Binding(get: { draft.weightKg ?? 0 }, set: { draft.weightKg = $0 }))
                }
            }
        }
    }

    // MARK: Step 4 — Activity

    private var activityStep: some View {
        OnboardingQuestionScreen(
            step: 5, totalSteps: totalSteps,
            title: "How active are you?",
            subtitle: "Outside of intentional exercise.",
            canGoBack: true, canContinue: draft.activityLevel != nil,
            onBack: goBack, onContinue: goNext
        ) {
            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases) { level in
                    OnboardingOptionCard(title: level.rawValue, subtitle: activityDescription(level), isSelected: draft.activityLevel == level) {
                        draft.activityLevel = level
                    }
                }
            }
        }
    }

    private func activityDescription(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "Desk job, little to no exercise"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .active: return "Hard exercise 6-7 days/week"
        }
    }

    // MARK: Step 5 — Target weight

    private var targetWeightStep: some View {
        OnboardingQuestionScreen(
            step: 6, totalSteps: totalSteps,
            title: "What's your target weight?",
            subtitle: nil,
            canGoBack: true, canContinue: (draft.targetWeightKg ?? 0) > 0,
            onBack: goBack, onContinue: goNext
        ) {
            onboardingNumberField(label: "Target weight (kg)", value: Binding(get: { draft.targetWeightKg ?? 0 }, set: { draft.targetWeightKg = $0 }))
        }
    }

    // MARK: Step 6 — Rate of change

    private var rateOptions: [Double] { [0.25, 0.5, 0.75, 1.0] }

    private var rateStep: some View {
        OnboardingQuestionScreen(
            step: 7, totalSteps: totalSteps,
            title: draft.goalType == .maintain ? "Pace" : "How fast do you want to reach your goal?",
            subtitle: draft.goalType == .maintain ? "You're maintaining, so this won't change much." : "A moderate pace is easier to sustain.",
            canGoBack: true, canContinue: true,
            onBack: goBack, onContinue: goNext
        ) {
            VStack(spacing: 10) {
                ForEach(rateOptions, id: \.self) { rate in
                    OnboardingOptionCard(
                        title: "\(String(format: "%.2g", rate)) kg/week",
                        subtitle: nil,
                        isSelected: draft.weeklyRateKg == rate
                    ) {
                        draft.weeklyRateKg = rate
                    }
                }
            }
        }
    }

    // MARK: Step 7 — Diet preference

    private var dietStep: some View {
        OnboardingQuestionScreen(
            step: 8, totalSteps: totalSteps,
            title: "Any macro preference?",
            subtitle: "Sets how your calories split across protein, carbs, and fat.",
            canGoBack: true, canContinue: draft.macroPreset != nil,
            onBack: goBack, onContinue: goNext
        ) {
            VStack(spacing: 10) {
                ForEach(MacroPreset.allCases) { preset in
                    OnboardingOptionCard(title: preset.rawValue, subtitle: macroDescription(preset), isSelected: draft.macroPreset == preset) {
                        draft.macroPreset = preset
                    }
                }
            }
        }
    }

    private func macroDescription(_ preset: MacroPreset) -> String {
        let split = preset.split
        return "\(Int(split.protein * 100))% protein · \(Int(split.carb * 100))% carbs · \(Int(split.fat * 100))% fat"
    }

    // MARK: Summary

    private var computedProfile: UserProfile {
        let profile = UserProfile(
            heightCm: draft.heightCm ?? 170,
            age: draft.age,
            weightKg: draft.weightKg ?? 70,
            targetWeightKg: draft.targetWeightKg ?? draft.weightKg ?? 70,
            activityLevel: draft.activityLevel ?? .moderate,
            macroPreset: draft.macroPreset ?? .balanced,
            goalType: draft.goalType ?? .maintain,
            sex: draft.sex ?? .other,
            weeklyRateKg: draft.weeklyRateKg,
            hasCompletedOnboarding: true
        )
        return profile
    }

    private var summaryStep: some View {
        let goals = NutritionGoalCalculator.compute(profile: computedProfile)
        return OnboardingQuestionScreen(
            step: totalSteps, totalSteps: totalSteps,
            title: "Your daily goal",
            subtitle: "Based on your answers. You can fine-tune this anytime in More.",
            canGoBack: true, canContinue: true,
            onBack: goBack, onContinue: { onComplete(computedProfile) }
        ) {
            GlassEffectContainer(spacing: 10) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Daily calorie goal")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textSecondary)
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(goals.calorieGoal)")
                                .font(Theme.Font.display(40))
                                .foregroundStyle(Theme.textPrimary)
                            Text(" cal")
                                .font(Theme.Font.text(15))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))

                    HStack(spacing: 10) {
                        summaryMacroTile(label: "Protein", value: goals.proteinG, color: Theme.proteinColor)
                        summaryMacroTile(label: "Carbs", value: goals.carbG, color: Theme.carbColor)
                        summaryMacroTile(label: "Fat", value: goals.fatG, color: Theme.fatColor)
                    }
                }
            }
        }
    }

    private func summaryMacroTile(label: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(value)g")
                .font(Theme.Font.display(16))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private func onboardingNumberField(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textSecondary)
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .font(Theme.Font.display(22))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }
}
