import SwiftUI

struct StepsWidgetCard: View {
    private let stepGoal = 10_000

    @State private var steps: Int?
    @State private var unavailable = false

    private var fraction: Double {
        min(1, Double(steps ?? 0) / Double(stepGoal))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.steps)
                Text("Steps")
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }

            if unavailable {
                Text("Steps unavailable — enable in Settings")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textFaint)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(steps ?? 0)")
                        .font(Theme.Font.display(22))
                        .foregroundStyle(Theme.textPrimary)
                    Text("/ \(stepGoal)")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textTertiary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.hairline)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.steps)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 6)
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
