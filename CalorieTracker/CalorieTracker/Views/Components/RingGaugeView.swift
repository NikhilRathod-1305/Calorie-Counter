import SwiftUI

/// Circular progress dial matching the reference design's calorie/step/water gauges:
/// a thick background track, a gradient progress arc, and a centered value label.
struct RingGaugeView: View {
    let progress: Double
    var lineWidth: CGFloat = 12
    var trackColor: Color = Theme.hairline
    var progressGradient: LinearGradient = Theme.accentGradient

    init(progress: Double, lineWidth: CGFloat = 12, trackColor: Color = Theme.hairline, progressGradient: LinearGradient = Theme.accentGradient) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.progressGradient = progressGradient
    }

    init(progress: Double, lineWidth: CGFloat = 12, trackColor: Color = Theme.hairline, progressColor: Color) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.progressGradient = LinearGradient(colors: [progressColor, progressColor], startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(progressGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
