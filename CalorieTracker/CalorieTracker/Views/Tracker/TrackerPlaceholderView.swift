import SwiftUI
import SwiftData

struct TrackerPlaceholderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var waterEntries: [WaterLogEntry]
    @Query(sort: \WeightLogEntry.date) private var weightEntries: [WeightLogEntry]
    @Query private var profiles: [UserProfile]

    @State private var viewedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var steps: Int?
    @State private var stepsUnavailable = false
    @State private var showingLogWeight = false

    private let waterStep = 250

    private var profile: UserProfile { profiles.first ?? UserProfile() }

    private var viewedWater: [WaterLogEntry] {
        let cal = Calendar.current
        return waterEntries.filter { cal.isDate($0.date, inSameDayAs: viewedDate) }
    }
    private var waterMl: Int { viewedWater.reduce(0) { $0 + $1.milliliters } }
    private var waterFraction: Double { min(1, Double(waterMl) / Double(max(1, profile.waterGoalMl))) }

    private var stepFraction: Double { min(1, Double(steps ?? 0) / Double(max(1, profile.stepGoal))) }

    /// Weight as of the viewed date: the most recent entry on or before that day,
    /// falling back to the profile's current weight if nothing's logged yet.
    private var currentWeight: Double {
        let cal = Calendar.current
        let entriesUpToDate = weightEntries.filter { $0.date <= cal.startOfDay(for: viewedDate).addingTimeInterval(86400) }
        return entriesUpToDate.last?.weightKg ?? profile.weightKg
    }
    private var startWeight: Double { weightEntries.first?.weightKg ?? currentWeight }
    private var weightDelta: Double { currentWeight - startWeight }
    private var weightFraction: Double {
        let goal = profile.targetWeightKg
        guard goal != startWeight else { return 1 }
        return min(1, max(0, (currentWeight - startWeight) / (goal - startWeight)))
    }

    private var bmi: Double {
        let heightM = profile.heightCm / 100
        guard heightM > 0 else { return 0 }
        return currentWeight / (heightM * heightM)
    }
    private var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "High"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        waterCard
                        stepsCard
                        weightCard
                        bmiCard

                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 12)
                }
                .background(Theme.groupedBackground.ignoresSafeArea())
            }
            .navigationBarHidden(true)
        }
        .task(id: viewedDate) { await loadSteps() }
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

    // MARK: Card shell

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .padding(.horizontal, 16)
    }

    // MARK: Water

    private var waterCard: some View {
        ZStack(alignment: .trailing) {
            NavigationLink {
                WaterDetailsView()
            } label: {
                card {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Water")
                                .font(Theme.Font.text(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text("\(waterMl)")
                                    .font(Theme.Font.display(26))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("mL")
                                    .font(Theme.Font.text(13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Text("/ \(profile.waterGoalMl) mL")
                                .font(Theme.Font.text(12))
                                .foregroundStyle(Theme.textFaint)
                        }

                        Spacer(minLength: 0)

                        // Reserve visual space for the droplet + +/- buttons drawn on top.
                        Color.clear.frame(width: 148, height: 70)
                    }
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                waterStepButton(icon: "minus") { adjustWater(by: -waterStep) }
                DropletFillView(fraction: waterFraction)
                    .frame(width: 60, height: 70)
                waterStepButton(icon: "plus") { adjustWater(by: waterStep) }
            }
            .padding(.trailing, 16)
        }
    }

    private func waterStepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.water)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .overlay(Circle().stroke(Theme.water, lineWidth: 1.5).padding(6))
        }
        .buttonStyle(.plain)
    }

    private func adjustWater(by amount: Int) {
        if amount > 0 {
            modelContext.insert(WaterLogEntry(milliliters: amount, date: viewedDate))
        } else if let last = viewedWater.max(by: { $0.date < $1.date }) {
            modelContext.delete(last)
        }
        try? modelContext.save()
    }

    // MARK: Steps

    private var stepsCard: some View {
        NavigationLink {
            StepDetailsView()
        } label: {
            card {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Step")
                            .font(Theme.Font.text(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if stepsUnavailable {
                            Text("Unavailable")
                                .font(Theme.Font.display(18))
                                .foregroundStyle(Theme.textFaint)
                        } else {
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text("\(steps ?? 0)")
                                    .font(Theme.Font.display(26))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("steps")
                                    .font(Theme.Font.text(13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Text("/ \(profile.stepGoal) steps")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textFaint)
                    }

                    Spacer(minLength: 0)

                    if !stepsUnavailable {
                        GaugeDialView(progress: stepFraction)
                            .frame(width: 84, height: 84)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func loadSteps() async {
        guard HealthKitStepsService.isAvailable else {
            stepsUnavailable = true
            return
        }
        let granted = await HealthKitStepsService.requestAuthorization()
        guard granted else {
            stepsUnavailable = true
            return
        }
        steps = try? await HealthKitStepsService.steps(on: viewedDate)
    }

    // MARK: Weight

    private var weightCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weight")
                            .font(Theme.Font.text(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 8) {
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text(String(format: "%.1f", currentWeight))
                                    .font(Theme.Font.display(26))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("kg")
                                    .font(Theme.Font.text(13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            if weightDelta != 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: weightDelta < 0 ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                                        .font(.system(size: 12))
                                    Text("\(weightDelta > 0 ? "+" : "")\(String(format: "%.1f", weightDelta)) kg")
                                        .font(Theme.Font.text(12, weight: .semibold))
                                }
                                .foregroundStyle(weightDelta < 0 ? Theme.success : Theme.weight)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    Button {
                        showingLogWeight = true
                    } label: {
                        Text("Update")
                            .font(Theme.Font.text(13, weight: .semibold))
                            .foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Theme.secondary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                RoundedRectangle(cornerRadius: 7)
                    .fill(Theme.hairline)
                    .frame(height: 14)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Theme.secondary)
                                .frame(width: geo.size.width * weightFraction)
                        }
                    }

                HStack {
                    Text("Starting: \(String(format: "%.1f", startWeight)) kg")
                    Spacer()
                    Text("Goal: \(String(format: "%.1f", profile.targetWeightKg)) kg")
                }
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textFaint)
            }
        }
    }

    // MARK: BMI

    private var bmiCard: some View {
        card {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BMI (kg/m2)")
                        .font(Theme.Font.text(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f", bmi))
                            .font(Theme.Font.display(26))
                            .foregroundStyle(Theme.textPrimary)
                        Text(bmiCategory)
                            .font(Theme.Font.text(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Button {
                    showingLogWeight = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.cardBackgroundAlt, in: Circle())
                }
                .buttonStyle(.plain)
            }

            BMIScaleBar(bmi: bmi)
                .padding(.top, 14)
        }
    }
}
