import SwiftUI

struct WeightWidgetCard: View {
    let currentWeightKg: Double
    let targetWeightKg: Double
    let recentEntries: [WeightLogEntry]
    var onLogWeight: (() -> Void)? = nil
    var tint: Color = Theme.weight
    var tintGradient: LinearGradient = Theme.weightGradient

    private var weights: [WeightLogEntry] {
        recentEntries.isEmpty ? [WeightLogEntry(weightKg: currentWeightKg)] : recentEntries
    }

    private var values: [Double] {
        weights.map { $0.weightKg } + [targetWeightKg]
    }
    private var wMin: Double { (values.min() ?? 0) - 1 }
    private var wMax: Double { (values.max() ?? 1) + 1 }
    private var range: Double { max(0.1, wMax - wMin) }

    private var goalInRange: Bool {
        targetWeightKg >= wMin && targetWeightKg <= wMax
    }

    private var changeFromFirst: Double? {
        guard weights.count > 1, let first = weights.first else { return nil }
        return currentWeightKg - first.weightKg
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Weight")
                        .font(Theme.Font.text(13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", currentWeightKg))
                            .font(Theme.Font.display(32))
                            .foregroundStyle(Theme.textPrimary)
                        Text("kg")
                            .font(Theme.Font.text(14))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Spacer()
                if let changeFromFirst {
                    changePill(changeFromFirst)
                }
                if let onLogWeight {
                    Button(action: onLogWeight) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.onAccent)
                            .frame(width: 28, height: 28)
                            .glassEffect(.regular.tint(Theme.accent).interactive(), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
            }

            Divider().overlay(Theme.hairline.opacity(0.5))

            if weights.count > 1 {
                chart
                    .frame(height: 130)

                HStack {
                    Text(dayLabel(weights.first?.date ?? Date()))
                    Spacer()
                    Text(dayLabel(weights.last?.date ?? Date()))
                }
                .font(Theme.Font.text(10))
                .foregroundStyle(Theme.textFaint)
            } else {
                Text("Log a weight to see your trend")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textFaint)
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private func changePill(_ change: Double) -> some View {
        let isDown = change <= 0
        return HStack(spacing: 4) {
            Image(systemName: isDown ? "arrow.down" : "arrow.up")
                .font(.system(size: 10, weight: .bold))
            Text("\(String(format: "%.1f", abs(change))) kg")
                .font(Theme.Font.text(12, weight: .semibold))
        }
        .foregroundStyle(isDown ? Theme.success : Theme.danger)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((isDown ? Theme.success : Theme.danger).opacity(0.15), in: Capsule())
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private let topInset: CGFloat = 20
    private let bottomInset: CGFloat = 6

    private func plotY(_ value: Double, plotHeight: CGFloat) -> CGFloat {
        topInset + plotHeight * (1 - CGFloat((value - wMin) / range))
    }

    private var chart: some View {
        GeometryReader { geo in
            let plotHeight = geo.size.height - topInset - bottomInset
            let goalY = plotY(targetWeightKg, plotHeight: plotHeight)
            ZStack {
                if goalInRange {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geo.size.width, y: goalY))
                    }
                    .stroke(Theme.textFaint, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                lineAreaPath(geo: geo, plotHeight: plotHeight)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.35), tint.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                linePath(geo: geo, plotHeight: plotHeight)
                    .stroke(tintGradient, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                ForEach(Array(weights.enumerated()), id: \.offset) { index, entry in
                    let x = geo.size.width * CGFloat(index) / CGFloat(max(1, weights.count - 1))
                    let y = plotY(entry.weightKg, plotHeight: plotHeight)

                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private func linePath(geo: GeometryProxy, plotHeight: CGFloat) -> Path {
        Path { path in
            for (index, entry) in weights.enumerated() {
                let x = geo.size.width * CGFloat(index) / CGFloat(max(1, weights.count - 1))
                let y = plotY(entry.weightKg, plotHeight: plotHeight)
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
    }

    private func lineAreaPath(geo: GeometryProxy, plotHeight: CGFloat) -> Path {
        Path { path in
            for (index, entry) in weights.enumerated() {
                let x = geo.size.width * CGFloat(index) / CGFloat(max(1, weights.count - 1))
                let y = plotY(entry.weightKg, plotHeight: plotHeight)
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            path.addLine(to: CGPoint(x: geo.size.width, y: topInset + plotHeight))
            path.addLine(to: CGPoint(x: 0, y: topInset + plotHeight))
            path.closeSubpath()
        }
    }
}
