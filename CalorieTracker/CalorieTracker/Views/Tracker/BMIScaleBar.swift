import SwiftUI

/// Horizontal BMI scale: a segmented green→yellow→orange gradient bar with a
/// downward-pointing triangle marking the current BMI, and tick labels below.
struct BMIScaleBar: View {
    let bmi: Double

    private let ticks: [Double] = [15, 16, 18.5, 25, 30, 35, 40]
    private let minValue: Double = 15
    private let maxValue: Double = 40

    private var fraction: CGFloat {
        CGFloat(min(max(bmi, minValue), maxValue) - minValue) / CGFloat(maxValue - minValue)
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        colors: [
                            Color(hex: 0x1B7A3D), Color(hex: 0x4CAF50), Color(hex: 0x9ACD32),
                            Color(hex: 0xE8D93A), Color(hex: 0xF0A430), Color(hex: 0xE8642E)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textPrimary)
                        .offset(x: geo.size.width * fraction - 6, y: -14)
                }
            }
            .frame(height: 8)
            .padding(.top, 14)

            HStack {
                ForEach(ticks, id: \.self) { tick in
                    Text(tick.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(tick))" : String(format: "%.1f", tick))
                        .font(Theme.Font.text(10))
                        .foregroundStyle(Theme.textFaint)
                    if tick != ticks.last { Spacer(minLength: 0) }
                }
            }
        }
    }
}
