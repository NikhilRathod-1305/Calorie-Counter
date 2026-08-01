import SwiftUI

/// BMI scale shown as discrete colored pill segments (underweight → obese) with a
/// small triangle marker positioned under the segment matching the current BMI.
struct BMIScaleBar: View {
    let bmi: Double

    private let segmentColors: [Color] = [
        Color(hex: 0x1B3A8A), Color(hex: 0x2F63C7), Color(hex: 0x4A90E2),
        Color(hex: 0x4CAF50), Color(hex: 0xF0C43A), Color(hex: 0xF0A430), Color(hex: 0xE8422E)
    ]

    /// BMI thresholds each segment boundary represents (severe underweight ... severe obese).
    private let thresholds: [Double] = [15, 16, 18.5, 25, 30, 35, 40, 45]

    private var activeSegmentIndex: Int {
        for i in 0..<(thresholds.count - 1) {
            if bmi < thresholds[i + 1] { return i }
        }
        return segmentColors.count - 1
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                let segmentWidth = geo.size.width / CGFloat(segmentColors.count)
                Image(systemName: "triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.accent)
                    .rotationEffect(.degrees(180))
                    .position(x: segmentWidth * (CGFloat(activeSegmentIndex) + 0.5), y: 6)
            }
            .frame(height: 12)

            HStack(spacing: 4) {
                ForEach(Array(segmentColors.enumerated()), id: \.offset) { index, color in
                    Capsule()
                        .fill(color)
                        .opacity(index == activeSegmentIndex ? 1 : 0.85)
                        .frame(height: 10)
                }
            }
        }
    }
}
