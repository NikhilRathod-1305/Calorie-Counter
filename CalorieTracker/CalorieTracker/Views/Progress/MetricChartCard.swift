import SwiftUI

enum ChartStyle {
    case bar
    case line
}

struct MetricChartPoint: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

/// Card used for Calorie, Water, Step, and Weight metrics: a title, a bar/line style
/// toggle, a dashed goal line, and axis labels. Tapping or dragging across the chart
/// reveals a callout bubble on the nearest point — nothing is highlighted by default.
struct MetricChartCard: View {
    let title: String
    let points: [MetricChartPoint]
    let goal: Double?
    let color: Color
    let unit: String
    let axisLabels: [String]
    var defaultStyle: ChartStyle = .line

    @State private var style: ChartStyle
    @State private var selectedIndex: Int?

    init(title: String, points: [MetricChartPoint], goal: Double?, color: Color, unit: String, axisLabels: [String], defaultStyle: ChartStyle = .line) {
        self.title = title
        self.points = points
        self.goal = goal
        self.color = color
        self.unit = unit
        self.axisLabels = axisLabels
        self.defaultStyle = defaultStyle
        _style = State(initialValue: defaultStyle)
    }

    /// Padded above the highest point/goal so the goal line and selection callout
    /// always have clear headroom instead of touching the chart's top edge.
    private var maxValue: Double {
        max(points.map(\.value).max() ?? 0, goal ?? 0, 1) * 1.35
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                styleToggle
            }

            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text("Selected")
                    .font(Theme.Font.text(10))
                    .foregroundStyle(Theme.textTertiary)
                if goal != nil {
                    Spacer()
                    HStack(spacing: 6) {
                        DashLine()
                            .stroke(Theme.warning, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                            .frame(width: 12, height: 1.5)
                        Text("\(title) Goal")
                            .font(Theme.Font.text(10))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }

            HStack(alignment: .top, spacing: 8) {
                yAxisLabels
                    .frame(height: 170)

                chart
                    .frame(height: 170)
            }

            HStack(spacing: 8) {
                Color.clear.frame(width: yAxisWidth)
                axisLabelsRow
            }
        }
        .padding(16)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private let yAxisWidth: CGFloat = 34

    /// Evenly-spaced numeric labels for the vertical axis, top (max) to bottom (0).
    private var yAxisSteps: [Double] {
        let top = maxValue
        return (0..<4).map { top * (1 - Double($0) / 3) }
    }

    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(yAxisSteps.enumerated()), id: \.offset) { index, value in
                Text(formatAxisValue(value))
                    .font(Theme.Font.text(9))
                    .foregroundStyle(Theme.textFaint)
                if index < yAxisSteps.count - 1 { Spacer(minLength: 0) }
            }
        }
        .frame(width: yAxisWidth, alignment: .trailing)
    }

    private func formatAxisValue(_ value: Double) -> String {
        if value >= 1000 { return String(format: "%.1fk", value / 1000) }
        return "\(Int(value))"
    }

    /// Mirrors the chart's own inset/slot math so each label centers under its bar or point.
    private var axisLabelsRow: some View {
        GeometryReader { geo in
            let count = max(1, axisLabels.count)
            let inset = badgeRadius
            let plotWidth = max(0, geo.size.width - inset * 2)
            let slot = plotWidth / CGFloat(count)
            ForEach(Array(axisLabels.enumerated()), id: \.offset) { index, label in
                let x = axisLabels.count > 1
                    ? inset + slot * CGFloat(index) + slot / 2
                    : geo.size.width / 2
                Text(label)
                    .font(Theme.Font.text(9))
                    .foregroundStyle(Theme.textFaint)
                    .position(x: x, y: geo.size.height / 2)
            }
        }
        .frame(height: 12)
    }

    private var styleToggle: some View {
        HStack(spacing: 6) {
            toggleButton(icon: "chart.bar.fill", target: .bar)
            toggleButton(icon: "chart.xyaxis.line", target: .line)
        }
    }

    private func toggleButton(icon: String, target: ChartStyle) -> some View {
        let isSelected = style == target
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { style = target }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.onAccent : Theme.textSecondary)
                .frame(width: 26, height: 26)
                .background(isSelected ? color : Theme.cardBackgroundAlt, in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private var chart: some View {
        GeometryReader { geo in
            let count = max(1, points.count)
            // Inset the plotting area so the first/last point's selection badge has
            // room to sit centered above it without being pushed inward off the point.
            let inset = badgeRadius
            let plotWidth = max(0, geo.size.width - inset * 2)
            let slot = plotWidth / CGFloat(count)
            let goalY = goal.map { geo.size.height * (1 - CGFloat($0 / maxValue)) }

            ZStack(alignment: .bottomLeading) {
                if let goalY {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geo.size.width, y: goalY))
                    }
                    .stroke(Theme.warning, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                }

                if style == .bar {
                    barLayer(geo: geo, inset: inset, slot: slot)
                } else {
                    lineLayer(geo: geo, inset: inset, plotWidth: plotWidth)
                }

                if let selectedIndex, points.indices.contains(selectedIndex) {
                    let point = points[selectedIndex]
                    let x = style == .bar
                        ? inset + slot * CGFloat(selectedIndex) + slot / 2
                        : (points.count > 1 ? inset + plotWidth * CGFloat(selectedIndex) / CGFloat(points.count - 1) : geo.size.width / 2)
                    let rawY = geo.size.height * (1 - CGFloat(point.value / maxValue))
                    // Bars have a minimum pill height (barMinHeight) so near-zero values
                    // still render as a visible nub; the marker must track that same
                    // floor or it ends up floating below the bar's actual top.
                    let y = style == .bar ? min(rawY, geo.size.height - barMinHeight(slot: slot)) : rawY

                    Path { path in
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    calloutBubble(value: point.value)
                        .alignmentGuide(VerticalAlignment.center) { d in
                            // Anchor by the pointer's own tip so the badge's measured
                            // size is accounted for, instead of guessing a fixed
                            // offset from the point.
                            d[VerticalAlignment.bottom]
                        }
                        .position(x: x, y: y - badgeGap * 3)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                selectedIndex = nearestIndex(x: location.x, inset: inset, slot: slot, geo: geo)
            }
            .simultaneousGesture(
                // Only treat the drag as point-selection once it's clearly more
                // horizontal than vertical — otherwise a vertical scroll gesture
                // starting on the chart would also drive selectedIndex updates on
                // every touch move, fighting the ScrollView for the same drag.
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        selectedIndex = nearestIndex(x: value.location.x, inset: inset, slot: slot, geo: geo)
                    }
            )
        }
    }

    private func nearestIndex(x: CGFloat, inset: CGFloat, slot: CGFloat, geo: GeometryProxy) -> Int? {
        guard !points.isEmpty else { return nil }
        if style == .bar {
            let index = Int((x - inset) / slot)
            return min(max(0, index), points.count - 1)
        } else {
            guard points.count > 1 else { return 0 }
            let plotWidth = max(0, geo.size.width - inset * 2)
            let step = plotWidth / CGFloat(points.count - 1)
            let index = Int(((x - inset) / step).rounded())
            return min(max(0, index), points.count - 1)
        }
    }

    private func barMinHeight(slot: CGFloat) -> CGFloat {
        min(26, slot * 0.62)
    }

    private func barLayer(geo: GeometryProxy, inset: CGFloat, slot: CGFloat) -> some View {
        let barWidth = barMinHeight(slot: slot)
        return ForEach(points) { point in
            let index = points.firstIndex { $0.id == point.id } ?? 0
            let x = inset + slot * CGFloat(index) + slot / 2
            let height = geo.size.height * CGFloat(point.value / maxValue)
            Capsule()
                .fill(point.value > 0 ? (index == selectedIndex ? color : color.opacity(0.45)) : color.opacity(0.12))
                .frame(width: barWidth, height: max(barWidth, height))
                .position(x: x, y: geo.size.height - max(barWidth, height) / 2)
        }
    }

    private func lineLayer(geo: GeometryProxy, inset: CGFloat, plotWidth: CGFloat) -> some View {
        ZStack {
            if points.count > 1 {
                Path { path in
                    for (index, point) in points.enumerated() {
                        let x = inset + plotWidth * CGFloat(index) / CGFloat(points.count - 1)
                        let y = geo.size.height * (1 - CGFloat(point.value / maxValue))
                        if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                Path { path in
                    path.move(to: CGPoint(x: inset, y: geo.size.height))
                    for (index, point) in points.enumerated() {
                        let x = inset + plotWidth * CGFloat(index) / CGFloat(points.count - 1)
                        let y = geo.size.height * (1 - CGFloat(point.value / maxValue))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: inset + plotWidth, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [color.opacity(0.16), color.opacity(0)], startPoint: .top, endPoint: .bottom))
            }

            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                let x = points.count > 1 ? inset + plotWidth * CGFloat(index) / CGFloat(points.count - 1) : geo.size.width / 2
                let y = geo.size.height * (1 - CGFloat(point.value / maxValue))
                Circle()
                    .fill(Theme.cardBackground)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(color, lineWidth: 2))
                    .position(x: x, y: y)
            }
        }
    }

    /// Half-width/height of the selection badge, used to keep it fully on-screen
    /// (including near the first/last bar) and to size its clearance above a point.
    private let badgeRadius: CGFloat = 22
    private let badgeGap: CGFloat = 12

    private func calloutBubble(value: Double) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("\(Int(value))")
                    .font(Theme.Font.text(12, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(Theme.Font.text(8))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: badgeRadius * 2, height: badgeRadius * 2)
            .background(Circle().fill(Theme.cardBackground))
            .overlay(Circle().stroke(color, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)

            BadgePointer()
                .fill(Theme.cardBackground)
                .overlay(BadgePointerSides().stroke(color, lineWidth: 1.5))
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
    }
}

private struct BadgePointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

/// Just the two slanted edges of `BadgePointer`, open (no top edge), so stroking it
/// looks like a speech-bubble tail instead of an outlined triangle.
private struct BadgePointerSides: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}

private struct DashLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

#Preview("Calorie bar/line") {
    let cal = Calendar.current
    let days = (16...22).map { cal.date(from: DateComponents(year: 2024, month: 12, day: $0))! }
    let values: [Double] = [2450, 2100, 2600, 2500, 2550, 2500, 2200]
    let points = zip(days, values).map { MetricChartPoint(date: $0, value: $1) }
    return ScrollView {
        VStack(spacing: 16) {
            MetricChartCard(
                title: "Calorie (kcal)",
                points: points,
                goal: 2500,
                color: Theme.sage,
                unit: "kcal",
                axisLabels: ["16", "17", "18", "19", "20", "21", "22"],
                defaultStyle: .bar
            )
            MetricChartCard(
                title: "Calorie (kcal)",
                points: points,
                goal: 2500,
                color: Theme.sage,
                unit: "kcal",
                axisLabels: ["16", "17", "18", "19", "20", "21", "22"],
                defaultStyle: .line
            )
        }
        .padding(16)
    }
    .background(Theme.groupedBackground)
}
