import SwiftUI
import SwiftData

struct TrackerPlaceholderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var waterEntries: [WaterLogEntry]
    @Query(sort: \WeightLogEntry.date) private var weightEntries: [WeightLogEntry]
    @Query private var profiles: [UserProfile]

    @State private var steps: Int?
    @State private var stepsUnavailable = false
    @State private var showingLogWater = false
    @State private var showingLogWeight = false

    private let stepGoal = 10_000

    private var profile: UserProfile { profiles.first ?? UserProfile() }

    private var todaysWater: [WaterLogEntry] {
        let cal = Calendar.current
        return waterEntries.filter { cal.isDateInToday($0.date) }
    }
    private var waterMl: Int { todaysWater.reduce(0) { $0 + $1.milliliters } }
    private var waterFraction: Double { min(1, Double(waterMl) / Double(max(1, profile.waterGoalMl))) }

    private var stepFraction: Double { min(1, Double(steps ?? 0) / Double(stepGoal)) }

    private var currentWeight: Double { weightEntries.last?.weightKg ?? profile.weightKg }
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

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tracker")
                                .font(Theme.Font.display(24))
                                .foregroundStyle(Theme.textPrimary)
                            Text(dateLabel)
                                .font(Theme.Font.text(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 16)

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
        .task { await loadSteps() }
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
        .fullScreenCover(isPresented: $showingLogWater) {
            LogWaterView(
                goalMl: profile.waterGoalMl,
                onClose: { showingLogWater = false },
                onSave: { ml, date in
                    let entry = WaterLogEntry(milliliters: ml, date: date)
                    modelContext.insert(entry)
                    try? modelContext.save()
                    showingLogWater = false
                }
            )
        }
    }

    // MARK: Water

    private var waterCard: some View {
        TrackerCardRow(icon: "drop.fill", iconColor: Theme.water, title: "Water", onTap: { showingLogWater = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(waterMl)")
                            .font(Theme.Font.display(22))
                            .foregroundStyle(Theme.textPrimary)
                        Text("mL")
                            .font(Theme.Font.text(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text("Goal: \(profile.waterGoalMl) mL")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                ZStack {
                    RingGaugeView(progress: waterFraction, lineWidth: 6, progressColor: Theme.water)
                    Text("\(Int(waterFraction * 100))%")
                        .font(Theme.Font.text(11, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 46, height: 46)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: Steps

    private var stepsCard: some View {
        TrackerCardRow(icon: "shoeprints.fill", iconColor: Theme.steps, title: "Step", onTap: nil) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if stepsUnavailable {
                        Text("Unavailable")
                            .font(Theme.Font.display(18))
                            .foregroundStyle(Theme.textFaint)
                    } else {
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text("\(steps ?? 0)")
                                .font(Theme.Font.display(22))
                                .foregroundStyle(Theme.textPrimary)
                            Text("steps")
                                .font(Theme.Font.text(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Text("Goal: \(stepGoal) steps")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if !stepsUnavailable {
                    ZStack {
                        RingGaugeView(progress: stepFraction, lineWidth: 6, progressColor: Theme.steps)
                        Text("\(Int(stepFraction * 100))%")
                            .font(Theme.Font.text(11, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .frame(width: 46, height: 46)
                }
            }
        }
        .padding(.horizontal, 16)
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
        steps = try? await HealthKitStepsService.todaySteps()
    }

    // MARK: Weight

    private var weightCard: some View {
        TrackerCardRow(icon: "scalemass.fill", iconColor: Theme.weight, title: "Weight", onTap: { showingLogWeight = true }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(String(format: "%.0f", currentWeight))
                            .font(Theme.Font.display(22))
                            .foregroundStyle(Theme.textPrimary)
                        Text("kg")
                            .font(Theme.Font.text(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    if weightDelta != 0 {
                        HStack(spacing: 3) {
                            Image(systemName: weightDelta < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 12))
                            Text("\(weightDelta > 0 ? "+" : "")\(String(format: "%.1f", weightDelta))kg")
                                .font(Theme.Font.text(12, weight: .semibold))
                        }
                        .foregroundStyle(weightDelta < 0 ? Theme.success : Theme.weight)
                    }
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.hairline)
                    .frame(height: 8)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.weight)
                                .frame(width: geo.size.width * weightFraction)
                        }
                    }

                HStack {
                    Text("Starting: \(String(format: "%.0f", startWeight))")
                    Spacer()
                    Text("Goal: \(String(format: "%.0f", profile.targetWeightKg)) kg")
                }
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textFaint)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: BMI

    private var bmiCard: some View {
        TrackerCardRow(iconColor: .white, title: "BMI (kg/m2)", onTap: nil) {
            PieBadgeIcon()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", bmi))
                        .font(Theme.Font.display(22))
                        .foregroundStyle(Theme.textPrimary)
                    Text(bmiCategory)
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                BMIScaleBar(bmi: bmi)
            }
        }
        .padding(.horizontal, 16)
    }
}
