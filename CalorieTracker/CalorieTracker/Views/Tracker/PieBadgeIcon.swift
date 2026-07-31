import SwiftUI

/// Small 4-color pie/donut icon used for the BMI badge, matching the reference's
/// red/yellow/green/blue segmented circle.
struct PieBadgeIcon: View {
    private let segments: [Color] = [
        Color(hex: 0xE8642E), // red/orange
        Color(hex: 0xF0C43A), // yellow
        Color(hex: 0x4CAF50), // green
        Color(hex: 0x2F9CE0)  // blue
    ]

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, color in
                PieSlice(startAngle: .degrees(Double(index) * 90), endAngle: .degrees(Double(index + 1) * 90))
                    .fill(color)
            }
        }
    }
}

private struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle - .degrees(90), endAngle: endAngle - .degrees(90), clockwise: false)
        path.closeSubpath()
        return path
    }
}
