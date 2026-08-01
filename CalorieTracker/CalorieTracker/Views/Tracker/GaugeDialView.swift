import SwiftUI

/// Speedometer-style dial matching the reference's step tracker: a gray arc track,
/// short tick marks along the top, a needle pointing to current progress, and a
/// filled dot at the arc's start (bottom-left) and hub (center).
struct GaugeDialView: View {
    let progress: Double
    var color: Color = Theme.steps

    private let startAngle: Double = 145
    private let sweepAngle: Double = 250
    private let tickCount = 8

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let outerRadius = size / 2 - 4
            let tickRadius = outerRadius - 10
            let needleRadius = tickRadius - 10

            ZStack {
                Circle()
                    .trim(from: 0, to: sweepAngle / 360)
                    .stroke(Theme.hairline, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(startAngle))
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .position(center)

                Circle()
                    .trim(from: 0, to: (sweepAngle / 360) * max(0, min(1, progress)))
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(startAngle))
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .position(center)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                ForEach(0...tickCount, id: \.self) { i in
                    let angle = Angle.degrees(startAngle + sweepAngle * Double(i) / Double(tickCount))
                    Capsule()
                        .fill(Theme.textFaint.opacity(0.7))
                        .frame(width: 2.5, height: 7)
                        .rotationEffect(angle + .degrees(90))
                        .position(
                            x: center.x + cos(angle.radians) * tickRadius,
                            y: center.y + sin(angle.radians) * tickRadius
                        )
                }

                startDot(center: center, radius: outerRadius, color: color)

                needle(center: center, radius: needleRadius, progress: progress, color: color)

                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .position(center)
            }
        }
    }

    private func startDot(center: CGPoint, radius: CGFloat, color: Color) -> some View {
        let angle = Angle.degrees(startAngle)
        return Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .position(
                x: center.x + cos(angle.radians) * radius,
                y: center.y + sin(angle.radians) * radius
            )
    }

    private func needle(center: CGPoint, radius: CGFloat, progress: Double, color: Color) -> some View {
        let angle = Angle.degrees(startAngle + sweepAngle * max(0, min(1, progress)))
        return Path { path in
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + cos(angle.radians) * radius, y: center.y + sin(angle.radians) * radius))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
    }
}
