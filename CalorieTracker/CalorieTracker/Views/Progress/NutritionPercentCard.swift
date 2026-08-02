import SwiftUI

struct NutritionDayBreakdown: Identifiable {
    let date: Date
    let carbsPct: Double
    let proteinPct: Double
    let fatPct: Double
    var id: Date { date }
}

/// Stacked capsule chart showing each day's macro split as a percentage of that
/// day's total, plus an overall average legend (Carbs / Protein / Fat %).
/// Tapping or dragging across the chart reveals a badge with that day's split.
struct NutritionPercentCard: View {
    let days: [NutritionDayBreakdown]
    let axisLabels: [String]

    @State private var selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nutrition (%)")
                .font(Theme.Font.text(14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            legend

            HStack(alignment: .top, spacing: 8) {
                yAxisLabels
                    .frame(height: 170)

                ZStack(alignment: .topLeading) {
                    chart
                        .frame(height: 170)
                    axisLabelsRow
                        .offset(y: 170 + axisLabelsTopGap)
                    selectionBadgeOverlay
                        .allowsHitTesting(false)
                }
                .frame(height: 170 + axisLabelsTopGap + 12)
            }
        }
        .padding(16)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Theme.carbColor, label: "Carbs")
            legendItem(color: Theme.proteinColor, label: "Protein")
            legendItem(color: Theme.fatColor, label: "Fat")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(Theme.Font.text(10))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    /// Half-width/height of the selection badge, used to keep it fully on-screen
    /// (including near the first/last bar) and to size its clearance above a bar.
    private let badgeRadius: CGFloat = 22
    private let badgeGap: CGFloat = 12
    private let yAxisWidth: CGFloat = 28
    private let axisLabelsTopGap: CGFloat = 8

    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach([100, 75, 50, 25, 0], id: \.self) { value in
                Text("\(value)")
                    .font(Theme.Font.text(9))
                    .foregroundStyle(Theme.textFaint)
                if value > 0 { Spacer(minLength: 0) }
            }
        }
        .frame(width: yAxisWidth, alignment: .trailing)
    }

    private var chart: some View {
        GeometryReader { geo in
            let count = max(1, days.count)
            let inset = badgeRadius
            let plotWidth = max(0, geo.size.width - inset * 2)
            let slot = plotWidth / CGFloat(count)
            let barWidth = min(30, slot * 0.72)

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: inset)
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        let total = day.carbsPct + day.proteinPct + day.fatPct
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            if total > 0 {
                                VStack(spacing: 2) {
                                    Rectangle()
                                        .fill(Theme.fatColor)
                                        .frame(height: max(1, geo.size.height * CGFloat(day.fatPct / 100)))
                                    Rectangle()
                                        .fill(Theme.proteinColor)
                                        .frame(height: max(1, geo.size.height * CGFloat(day.proteinPct / 100)))
                                    Rectangle()
                                        .fill(Theme.carbColor)
                                        .frame(height: max(1, geo.size.height * CGFloat(day.carbsPct / 100)))
                                }
                                .frame(width: barWidth)
                                .background(Theme.cardBackground)
                                .clipShape(Capsule())
                            } else {
                                Capsule()
                                    .fill(Theme.hairline)
                                    .frame(width: barWidth, height: barWidth)
                            }
                        }
                        .frame(width: slot, height: geo.size.height)
                        .opacity(selectedIndex == nil || selectedIndex == index ? 1 : 0.45)
                    }
                    Color.clear.frame(width: inset)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                selectedIndex = nearestIndex(x: location.x, inset: inset, slot: slot)
            }
            .simultaneousGesture(
                // Only treat the drag as point-selection once it's clearly more
                // horizontal than vertical — otherwise a vertical scroll gesture
                // starting on the chart would also drive selectedIndex updates on
                // every touch move, fighting the ScrollView for the same drag.
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        selectedIndex = nearestIndex(x: value.location.x, inset: inset, slot: slot)
                    }
            )
        }
    }

    /// Drawn as a separate top-level layer (rather than nested inside `chart`) so it
    /// paints over the axis labels below instead of being covered by them.
    private var selectionBadgeOverlay: some View {
        GeometryReader { geo in
            if let selectedIndex, days.indices.contains(selectedIndex) {
                let inset = badgeRadius
                let plotWidth = max(0, geo.size.width - inset * 2)
                let slot = plotWidth / CGFloat(max(1, days.count))
                let x = inset + slot * CGFloat(selectedIndex) + slot / 2
                let day = days[selectedIndex]
                let barWidth = min(30, slot * 0.72)
                // Empty days render as a small nub at the bottom, not a full-height
                // bar, so the badge must track that same top edge instead of always
                // hugging the chart's top.
                let isEmpty = day.carbsPct + day.proteinPct + day.fatPct <= 0
                let barTopY = isEmpty ? geo.size.height - barWidth : 0
                badge(for: day)
                    .alignmentGuide(VerticalAlignment.center) { d in d[VerticalAlignment.bottom] }
                    .position(x: x, y: barTopY - badgeGap * 3)
            }
        }
        .frame(height: 170)
    }

    private func nearestIndex(x: CGFloat, inset: CGFloat, slot: CGFloat) -> Int? {
        guard !days.isEmpty else { return nil }
        let index = Int((x - inset) / slot)
        return min(max(0, index), days.count - 1)
    }

    private func badge(for day: NutritionDayBreakdown) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 1) {
                macroRow(color: Theme.carbColor, pct: day.carbsPct)
                macroRow(color: Theme.proteinColor, pct: day.proteinPct)
                macroRow(color: Theme.fatColor, pct: day.fatPct)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)

            BadgePointer()
                .fill(Theme.cardBackground)
                .overlay(
                    BadgePointerSides()
                        .stroke(Theme.hairline, lineWidth: 1)
                )
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
    }

    private func macroRow(color: Color, pct: Double) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(Int(pct.rounded()))%")
                .font(Theme.Font.text(10, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    /// Mirrors the chart's own inset/slot math so each label centers under its bar.
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
