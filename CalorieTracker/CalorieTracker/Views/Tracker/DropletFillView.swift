import SwiftUI

/// A classic droplet outline — a circle with a pointed peak formed by lines
/// tangent to the circle from an apex above it — filled from the bottom with an
/// animated water wave, matching the reference art. Using true tangent lines
/// (rather than approximated Bezier curves) guarantees the peak meets the
/// circle with no visible seam/kink.
struct DropletFillView: View {
    let fraction: Double

    var body: some View {
        ZStack {
            DropletShape()
                .fill(Theme.cardBackgroundAlt)
            WaterWaveShape(fraction: fraction)
                .fill(Theme.water)
                .clipShape(DropletShape())
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: fraction)
            DropletShape()
                .stroke(Theme.hairline, lineWidth: 2)
        }
    }
}

private struct DropletShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height

        let bulbRadius = width * 0.42
        let bulbCenter = CGPoint(x: rect.midX, y: rect.minY + height - bulbRadius)
        let apex = CGPoint(x: rect.midX, y: rect.minY)

        // Distance from apex straight down to the circle's center.
        let d = bulbCenter.y - apex.y
        guard d > bulbRadius else {
            // Degenerate (too squat to form a peak) — just draw the circle.
            return Circle().path(in: CGRect(x: bulbCenter.x - bulbRadius, y: bulbCenter.y - bulbRadius, width: bulbRadius * 2, height: bulbRadius * 2))
        }

        // Tangent-point geometry: right triangle apex–center–tangentPoint with the
        // right angle at the tangent point. sin(phi) = r/d gives the angle at the
        // apex; 90°−phi gives the angle at the center between "straight up" and
        // the tangent point, so the line apex→tangentPoint is exactly tangent to
        // the circle (no kink where it meets the arc).
        let phi = asin(Double(bulbRadius / d))
        let angleAtCenter = 90 - phi * 180 / .pi
        let rightTangentDeg = -90 + angleAtCenter
        let leftTangentDeg = -90 - angleAtCenter

        let rightTangent = point(on: bulbCenter, radius: bulbRadius, degrees: rightTangentDeg)
        let leftTangent = point(on: bulbCenter, radius: bulbRadius, degrees: leftTangentDeg)

        var path = Path()
        path.move(to: apex)
        path.addLine(to: rightTangent)
        path.addArc(
            center: bulbCenter, radius: bulbRadius,
            startAngle: .degrees(rightTangentDeg), endAngle: .degrees(leftTangentDeg + 360),
            clockwise: false
        )
        path.addLine(to: apex)
        path.closeSubpath()
        return path
    }

    private func point(on center: CGPoint, radius: CGFloat, degrees: Double) -> CGPoint {
        let angle = Angle.degrees(degrees)
        return CGPoint(x: center.x + cos(angle.radians) * radius, y: center.y + sin(angle.radians) * radius)
    }
}
