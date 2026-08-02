import SwiftUI

struct DropletFillView: View {
    let fraction: Double

    private let emptyFill = Color(light: 0xEBEBEB, dark: 0x2A322D)
    private let outline = Color(light: 0xDADADA, dark: 0x3A423C)
    private let backWaveTop = Color(light: 0x5CADF7, dark: 0x6BC0FF)
    private let backWaveBottom = Color(light: 0x1E88F0, dark: 0x2E98FF)
    private let frontWaveTop = Color(light: 0x2A93F5, dark: 0x4FB6F5)
    private let frontWaveBottom = Color(light: 0x0068E9, dark: 0x1A7BD8)

    var body: some View {
        ZStack {
            DropletShape()
                .fill(Color(light: 0xF5F5F5, dark: 0x1C231F))
                .padding(-6)
                .blur(radius: 3)

            DropletShape()
                .fill(emptyFill)

            // Two overlapping wave layers that continuously scroll sideways
            // (at different speeds, offset in phase) — the back wave (lighter)
            // rises where the front wave (darker) dips, and because both keep
            // moving it reads as actual water motion rather than a fixed
            // crossing, matching the reference art.
            //
            // Throttled to 30fps (instead of the display's native refresh rate,
            // up to 120fps on ProMotion) since a slow-moving wave doesn't need
            // more, and each tick recomputes two 40-point sine paths plus
            // re-rasterizes the DropletShape clip mask.
            TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    WaterWaveShape(fraction: fraction, waveHeight: 7, wavelengthScale: 1.0, phase: .pi / 2 + t * 0.6)
                        .fill(LinearGradient(colors: [backWaveTop, backWaveBottom], startPoint: .top, endPoint: .bottom))
                    WaterWaveShape(fraction: fraction, waveHeight: 7, wavelengthScale: 1.0, phase: -.pi / 2 - t * 0.9)
                        .fill(LinearGradient(colors: [frontWaveTop, frontWaveBottom], startPoint: .top, endPoint: .bottom))
                }
            }
            .clipShape(DropletShape())
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: fraction)

            DropletShape()
                .stroke(outline, lineWidth: 1.5)
        }
    }
}

/// Matches the reference droplet icon's silhouette, which is built from two
/// circles rather than a circle-plus-straight-tangent-lines: a small "bulb"
/// circle for the rounded base, and a much larger circle (radius ≈1.93× the
/// bulb, mirrored left/right) whose arc forms each side and passes through
/// the apex. The two circles are exactly internally tangent to each other,
/// so the outline has no kink where the arcs meet — reproducing the outward
/// "bulge" measured in the reference (the sides sit ~14% of the chord length
/// outside where a straight tangent line would put them).
private struct DropletShape: Shape {
    /// Large-circle radius as a multiple of the bulb radius, and apex height
    /// above the bulb center as a multiple of the bulb radius — both measured
    /// from the reference artwork.
    private let largeRadiusRatio: CGFloat = 1.93
    private let apexHeightRatio: CGFloat = 1.356

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let bulbRadius = width * 0.46
        let bulbCenter = CGPoint(x: rect.midX, y: rect.minY + rect.height - bulbRadius)

        let apexHeight = bulbRadius * apexHeightRatio
        let apex = CGPoint(x: rect.midX, y: bulbCenter.y - apexHeight)
        let largeRadius = bulbRadius * largeRadiusRatio

        // Solve for the large circle's center: it must be internally tangent
        // to the bulb circle (distance between centers = largeRadius − bulbRadius)
        // and pass through the apex. Two constraints, two unknowns (dx, dy) —
        // by symmetry the right-side circle's center sits to the left of the
        // vertical axis (dx < 0) so its arc bulges rightward/outward.
        let a = apexHeight
        let r = largeRadius / bulbRadius
        let dy = ((2 * r - 1) - pow(a / bulbRadius, 2)) / (2 * (a / bulbRadius)) * bulbRadius
        let dxSquared = pow(largeRadius - bulbRadius, 2) - dy * dy
        let dx = sqrt(max(0, dxSquared))

        let rightLargeCenter = CGPoint(x: bulbCenter.x - dx, y: bulbCenter.y + dy)
        let leftLargeCenter = CGPoint(x: bulbCenter.x + dx, y: bulbCenter.y + dy)

        // Angle from each large circle's center to the apex, and to the point
        // where it touches the bulb circle (along the line joining the two centers).
        let rightApexAngle = angle(from: rightLargeCenter, to: apex)
        let rightTangentPoint = pointBetween(rightLargeCenter, bulbCenter, ratio: largeRadius / (largeRadius - bulbRadius))
        let rightTangentAngle = angle(from: rightLargeCenter, to: rightTangentPoint)

        let leftApexAngle = angle(from: leftLargeCenter, to: apex)
        let leftTangentPoint = pointBetween(leftLargeCenter, bulbCenter, ratio: largeRadius / (largeRadius - bulbRadius))
        let leftTangentAngle = angle(from: leftLargeCenter, to: leftTangentPoint)

        let bulbRightAngle = angle(from: bulbCenter, to: rightTangentPoint)
        let bulbLeftAngle = angle(from: bulbCenter, to: leftTangentPoint)

        // Round the sharp apex: stop each large-circle arc a few degrees short
        // of the true apex angle, then join the two truncated endpoints with a
        // quadratic curve through the apex. Since both arcs already meet the
        // bulb circle tangentially, this only softens the tip — the shoulders
        // stay kink-free.
        let apexRoundingDeg = 2.5
        let rightArcEndAngle = rightApexAngle + (rightTangentAngle > rightApexAngle ? 1 : -1) * apexRoundingDeg * .pi / 180
        let leftArcStartAngle = leftApexAngle + (leftTangentAngle > leftApexAngle ? 1 : -1) * apexRoundingDeg * .pi / 180
        let rightRoundedEnd = point(on: rightLargeCenter, radius: largeRadius, angle: rightArcEndAngle)

        var path = Path()
        path.move(to: rightRoundedEnd)
        path.addArc(center: rightLargeCenter, radius: largeRadius, startAngle: .radians(rightArcEndAngle), endAngle: .radians(rightTangentAngle), clockwise: rightApexAngle > rightTangentAngle)
        path.addArc(center: bulbCenter, radius: bulbRadius, startAngle: .radians(bulbRightAngle), endAngle: .radians(bulbLeftAngle), clockwise: false)
        path.addArc(center: leftLargeCenter, radius: largeRadius, startAngle: .radians(leftTangentAngle), endAngle: .radians(leftArcStartAngle), clockwise: leftTangentAngle > leftApexAngle)
        path.addQuadCurve(to: rightRoundedEnd, control: apex)
        path.closeSubpath()
        return path
    }

    private func angle(from center: CGPoint, to p: CGPoint) -> Double {
        atan2(Double(p.y - center.y), Double(p.x - center.x))
    }

    private func pointBetween(_ a: CGPoint, _ b: CGPoint, ratio: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * ratio, y: a.y + (b.y - a.y) * ratio)
    }

    private func point(on center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
    }
}
