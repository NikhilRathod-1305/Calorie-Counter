import SwiftUI

enum BMICategory: CaseIterable {
    case verySeverelyUnderweight
    case severelyUnderweight
    case underweight
    case normal
    case overweight
    case obeseClass1

    var label: String {
        switch self {
        case .verySeverelyUnderweight: return "Very severely underweight"
        case .severelyUnderweight: return "Severely underweight"
        case .underweight: return "Underweight"
        case .normal: return "Normal"
        case .overweight: return "Overweight"
        case .obeseClass1: return "Obese Class I"
        }
    }

    /// Upper bound of this category's BMI range; lower bound is the previous case's upper bound.
    var upperBound: Double {
        switch self {
        case .verySeverelyUnderweight: return 16.0
        case .severelyUnderweight: return 16.9
        case .underweight: return 18.4
        case .normal: return 24.9
        case .overweight: return 29.9
        case .obeseClass1: return 34.9
        }
    }

    var rangeLabel: String {
        switch self {
        case .verySeverelyUnderweight: return "BMI < 16.0"
        case .severelyUnderweight: return "BMI 16.0 - 16.9"
        case .underweight: return "BMI 17.0 - 18.4"
        case .normal: return "BMI 18.5 - 24.9"
        case .overweight: return "BMI 25.0 - 29.9"
        case .obeseClass1: return "BMI 30.0 - 34.9"
        }
    }

    /// Collapses the six medically-precise ranges into four visual bands
    /// (underweight/normal/overweight/obese) so the gauge and legend read as
    /// simple blue/green/yellow/red zones instead of six subtly different hues.
    var color: Color {
        switch self {
        case .verySeverelyUnderweight, .severelyUnderweight, .underweight: return Color(hex: 0x4FA8E0)
        case .normal: return Color(hex: 0x4CAF50)
        case .overweight: return Color(hex: 0xF0C030)
        case .obeseClass1: return Color(hex: 0xE0435A)
        }
    }

    static func category(for bmi: Double) -> BMICategory {
        allCases.first { bmi < $0.upperBound } ?? .obeseClass1
    }

    /// This category's [start, end] fraction of the gauge's 0...gaugeMax scale.
    static func fraction(for category: BMICategory, gaugeMax: Double) -> (start: Double, end: Double) {
        let all = allCases
        guard let index = all.firstIndex(of: category) else { return (0, 0) }
        let lower = index == 0 ? 0 : all[index - 1].upperBound
        return (lower / gaugeMax, category.upperBound / gaugeMax)
    }
}

/// Near-full-circle BMI gauge: six colored arc segments (one per BMI category), tick
/// marks around the dial, and a thick tapered needle pointing at the current value.
struct BMIGaugeView: View {
    let bmi: Double

    private var category: BMICategory { BMICategory.category(for: bmi) }

    private let startAngle: Double = 125
    private let sweepAngle: Double = 290
    private let gaugeMax: Double = BMICategory.allCases.last!.upperBound
    private let arcLineWidth: CGFloat = 20
    private let tickCount = 28

    /// Four equal-width bands (blue/green/yellow/red), matching the reference dial
    /// rather than widths proportional to each BMI range's real size.
    private let quadrantColors: [Color] = [
        Color(hex: 0x4FA8E0),
        Color(hex: 0x4CAF50),
        Color(hex: 0xF0C030),
        Color(hex: 0xE0435A)
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let outerRadius = size / 2 - arcLineWidth / 2
            let tickInnerRadius = outerRadius - arcLineWidth / 2 - 8
            let tickOuterRadius = tickInnerRadius + 5
            let needleRadius = outerRadius - arcLineWidth / 2 - 6

            ZStack {
                ForEach(0..<tickCount, id: \.self) { i in
                    let angle = Angle.degrees(startAngle + sweepAngle * (Double(i) / Double(tickCount - 1)))
                    Path { path in
                        path.move(to: point(center: center, radius: tickInnerRadius, angle: angle))
                        path.addLine(to: point(center: center, radius: tickOuterRadius, angle: angle))
                    }
                    .stroke(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }

                ForEach(Array(quadrantColors.enumerated()), id: \.offset) { index, quadrantColor in
                    let start = Double(index) / Double(quadrantColors.count)
                    let end = Double(index + 1) / Double(quadrantColors.count)
                    Circle()
                        .trim(from: start * (sweepAngle / 360), to: end * (sweepAngle / 360))
                        .stroke(quadrantColor, style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .butt))
                        .rotationEffect(.degrees(startAngle))
                        .frame(width: outerRadius * 2, height: outerRadius * 2)
                        .position(center)
                }

                needle(center: center, radius: needleRadius)

                Circle()
                    .strokeBorder(Theme.accent, lineWidth: 5)
                    .background(Circle().fill(Theme.cardBackground))
                    .frame(width: 36, height: 36)
                    .position(center)
            }
        }
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(x: center.x + cos(angle.radians) * radius, y: center.y + sin(angle.radians) * radius)
    }

    private func needle(center: CGPoint, radius: CGFloat) -> some View {
        let clamped = max(0, min(gaugeMax, bmi))
        let angle = Angle.degrees(startAngle + sweepAngle * (clamped / gaugeMax))
        let tip = point(center: center, radius: radius, angle: angle)
        let gradient = LinearGradient(
            colors: [Theme.accent.opacity(0.2), Theme.accent],
            startPoint: .init(x: 0.5, y: 1),
            endPoint: .init(x: 0.5, y: 0)
        )

        return NeedleShape(base: center, tip: tip, baseWidth: 20, tipWidth: 8)
            .fill(gradient)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: bmi)
    }
}

/// A gently tapered needle: wide at the pivot (base), staying fairly wide at the
/// tip (a blunt trapezoid) rather than narrowing to a sharp point.
private struct NeedleShape: Shape {
    var base: CGPoint
    var tip: CGPoint
    var baseWidth: CGFloat
    var tipWidth: CGFloat

    var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get { AnimatablePair(base.animatableData, tip.animatableData) }
        set {
            base.animatableData = newValue.first
            tip.animatableData = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let dx = tip.x - base.x
        let dy = tip.y - base.y
        let length = max(1, (dx * dx + dy * dy).squareRoot())
        let perpX = -dy / length
        let perpY = dx / length
        let baseHalf = baseWidth / 2
        let tipHalf = tipWidth / 2

        let baseLeft = CGPoint(x: base.x + perpX * baseHalf, y: base.y + perpY * baseHalf)
        let baseRight = CGPoint(x: base.x - perpX * baseHalf, y: base.y - perpY * baseHalf)
        let tipLeft = CGPoint(x: tip.x + perpX * tipHalf, y: tip.y + perpY * tipHalf)
        let tipRight = CGPoint(x: tip.x - perpX * tipHalf, y: tip.y - perpY * tipHalf)

        let dirX = dx / length
        let dirY = dy / length
        let roundedTip = CGPoint(x: tip.x + dirX * tipHalf, y: tip.y + dirY * tipHalf)

        var path = Path()
        path.move(to: baseLeft)
        path.addLine(to: tipLeft)
        path.addQuadCurve(to: tipRight, control: roundedTip)
        path.addLine(to: baseRight)
        path.closeSubpath()
        return path
    }
}
