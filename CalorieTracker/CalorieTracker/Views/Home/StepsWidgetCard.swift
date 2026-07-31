import SwiftUI

struct StepsWidgetCard: View {
    private let stepGoal = 10_000

    @State private var steps: Int?
    @State private var unavailable = false

    private var fraction: Double {
        min(1, Double(steps ?? 0) / Double(stepGoal))
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.steps)
                    Text("Steps")
                        .font(Theme.Font.text(13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }

                if unavailable {
                    Text("Steps unavailable — enable in Settings")
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textFaint)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(steps ?? 0)")
                            .font(Theme.Font.display(24))
                            .foregroundStyle(Theme.textPrimary)
                        Text("/ \(stepGoal)")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }

            Spacer(minLength: 0)

            if !unavailable {
                ZStack {
                    RingGaugeView(progress: fraction, lineWidth: 8, progressGradient: Theme.secondaryGradient)
                    Image(systemName: "shoeprints.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.steps)
                }
                .frame(width: 56, height: 56)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .task { await loadSteps() }
    }

    private func loadSteps() async {
        guard HealthKitStepsService.isAvailable else {
            unavailable = true
            return
        }
        let granted = await HealthKitStepsService.requestAuthorization()
        guard granted else {
            unavailable = true
            return
        }
        steps = try? await HealthKitStepsService.todaySteps()
    }
}
