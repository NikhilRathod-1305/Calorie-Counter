import SwiftUI

/// Open arc gauge (~270°, gap at the bottom) matching the calorie counter reference:
/// a thick gray track running most of the way around, with a shorter colored progress
/// arc starting from the same bottom-left point.
struct SemicircleGaugeView: View {
    let progress: Double
    var lineWidth: CGFloat = 14
    var trackColor: Color = Theme.hairline
    var progressColor: Color = Theme.accent

    /// Arc spans from 135° to 405° (135° past a full circle), i.e. starts bottom-left,
    /// sweeps clockwise over the top, ends bottom-right — a 270° opening at the bottom.
    private let startAngle: Double = 135
    private let sweepAngle: Double = 270

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: sweepAngle / 360)
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(startAngle))

            Circle()
                .trim(from: 0, to: (sweepAngle / 360) * max(0, min(1, progress)))
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(startAngle))
        }
    }
}
