import SwiftUI

struct CalorieRingCard: View {
    let baseGoal: Int
    let food: Int
    let exercise: Int
    let onEdit: () -> Void

    private var remaining: Int { max(0, baseGoal - food + exercise) }
    private var progress: Double {
        let consumed = Double(food)
        let total = Double(baseGoal + exercise)
        guard total > 0 else { return 0 }
        return min(1, consumed / total)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("CALORIES REMAINING")
                    .font(Theme.Font.text(11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.5)
                Spacer()
                Button(action: onEdit) {
                    Text("Edit")
                        .font(Theme.Font.text(13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }

            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.accentGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(remaining)")
                        .font(Theme.Font.display(36))
                        .foregroundStyle(Theme.textPrimary)
                        .minimumScaleFactor(0.6)
                    Text("kcal")
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 170, height: 170)

            HStack {
                statColumn(label: "Base Goal", value: baseGoal, color: Theme.textSecondary)
                Spacer(minLength: 0)
                statColumn(label: "Food", icon: "fork.knife", value: food, color: Theme.accent)
                Spacer(minLength: 0)
                statColumn(label: "Burn", icon: "flame.fill", value: exercise, color: Theme.exercise)
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private func statColumn(label: String, icon: String? = nil, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text("\(value)")
                .font(Theme.Font.text(16, weight: .semibold))
                .foregroundStyle(color == Theme.textSecondary ? Theme.textPrimary : color)
        }
    }
}
