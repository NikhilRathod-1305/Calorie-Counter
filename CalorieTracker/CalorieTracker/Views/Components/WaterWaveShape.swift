import SwiftUI

struct WaterWaveShape: Shape {
    var fraction: Double
    var waveHeight: CGFloat = 7
    var wavelengthScale: CGFloat = 1.6
    var phase: Double = 0

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let level = rect.height * (1 - CGFloat(min(1, max(0, fraction))))
        var path = Path()

        guard fraction > 0 else { return path }

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: level))

        let wavelength = rect.width * wavelengthScale
        let steps = 20
        for i in 0...steps {
            let x = rect.width * CGFloat(i) / CGFloat(steps)
            let relativeX = x / wavelength
            let y = level + sin((relativeX * 2 * .pi) + phase) * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}
