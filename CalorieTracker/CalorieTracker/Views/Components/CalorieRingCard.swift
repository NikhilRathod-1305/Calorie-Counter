import SwiftUI

struct CalorieRingCard: View {
    let baseGoal: Int
    let food: Int
    let exercise: Int
    let carbs: Double
    let carbGoal: Int
    let protein: Double
    let proteinGoal: Int
    let fat: Double
    let fatGoal: Int

    private var remaining: Int { max(0, baseGoal - food + exercise) }
    private var progress: Double {
        let consumed = Double(food)
        let total = Double(baseGoal + exercise)
        guard total > 0 else { return 0 }
        return min(1, consumed / total)
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .center, spacing: 0) {
                statColumn(value: food, label: "Eaten")

                ZStack {
                    SemicircleGaugeView(progress: progress, lineWidth: 12)

                    VStack(spacing: 2) {
                        Text("\(remaining)")
                            .font(Theme.Font.display(28))
                            .foregroundStyle(Theme.textPrimary)
                            .minimumScaleFactor(0.6)
                        Text("kcal left")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(width: 160, height: 160)
                .padding(.horizontal, 8)

                statColumn(value: exercise, label: "Burned")
            }

            HStack(alignment: .top, spacing: 20) {
                macroColumn(label: "Carbs", value: carbs, goal: carbGoal)
                macroColumn(label: "Protein", value: protein, goal: proteinGoal)
                macroColumn(label: "Fat", value: fat, goal: fatGoal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private func statColumn(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(Theme.Font.display(22))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func macroColumn(label: String, value: Double, goal: Int) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textSecondary)

            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.hairline)
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * min(1, value / Double(max(1, goal))))
                    }
                }

            Text("\(Int(value))/\(goal) g")
                .font(Theme.Font.text(12))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
