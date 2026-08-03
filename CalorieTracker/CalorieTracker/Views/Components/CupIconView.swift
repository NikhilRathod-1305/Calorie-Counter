import SwiftUI

/// A small water-vessel glyph — a real container silhouette (glass, mug,
/// bottle, or bowl) filled with a static wave, optionally with a few rising
/// bubbles — used anywhere the app previously showed a plain "drop.fill" SF
/// Symbol for water (history rows, the cup-size switcher, the quick-drink
/// button). Mirrors DropletFillView's wave/gradient treatment so the two read
/// as the same visual language.
struct CupIconView: View {
    var kind: VesselKind = .glass
    var fraction: Double = 0.5
    var showBubbles: Bool = false

    private let emptyFill = Color(light: 0xEBEBEB, dark: 0x2A322D)
    private let outline = Color(light: 0xC9C9C9, dark: 0x3A423C)
    private let waveTop = Color(light: 0x5CB8F7, dark: 0x6BC0FF)
    private let waveBottom = Color(light: 0x0E7FE0, dark: 0x1A7BD8)
    private let bubble = Color.white.opacity(0.55)

    var body: some View {
        let shape = kind.shape
        ZStack {
            shape.fill(emptyFill)

            ZStack {
                WaterWaveShape(fraction: fraction, waveHeight: 2, wavelengthScale: 1.0, phase: -.pi / 2)
                    .fill(LinearGradient(colors: [waveTop, waveBottom], startPoint: .top, endPoint: .bottom))

                if showBubbles && fraction > 0.08 {
                    BubblesShape(seed: kind.hashValue)
                        .fill(bubble)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .mask(WaterWaveShape(fraction: fraction, waveHeight: 2, wavelengthScale: 1.0, phase: -.pi / 2))
                }
            }
            .clipShape(shape)

            shape.stroke(outline, lineWidth: 1)

            if kind == .mug {
                MugHandleShape()
                    .stroke(outline, lineWidth: 1.5)
            }
        }
    }
}

/// The real container silhouettes used across the cup-size picker.
enum VesselKind: Hashable {
    /// A drinking glass — wider mouth, tapering to a narrower, rounded base.
    case glass
    /// A straight-sided mug with a side handle.
    case mug
    /// A narrow-necked bottle with sloped shoulders.
    case bottle
    /// A wide, shallow bowl.
    case bowl

    fileprivate var shape: VesselShape { VesselShape(kind: self) }
}

extension CupSize {
    /// Which real vessel represents this preset size in the size picker —
    /// cycles through a small set of recognizable containers rather than a
    /// different abstract shape per size.
    var vesselKind: VesselKind {
        switch self {
        case .ml100: return .bowl
        case .ml125: return .glass
        case .ml150: return .glass
        case .ml200: return .mug
        case .ml250: return .bowl
        case .ml300: return .glass
        case .ml350: return .bottle
        case .ml400: return .mug
        case .ml500: return .bottle
        case .ml600: return .bottle
        }
    }

    /// The vessel silhouette for an arbitrary logged amount (which may not
    /// exactly match a preset), by snapping to the closest preset size —
    /// used for history rows and the quick-drink button, where only a raw
    /// milliliter total is stored.
    static func vesselKind(forMilliliters milliliters: Int) -> VesselKind {
        let closest = CupSize.allCases.min { lhs, rhs in
            abs(lhs.rawValue - milliliters) < abs(rhs.rawValue - milliliters)
        }
        return (closest ?? .ml250).vesselKind
    }
}

/// Builds the outline path for each VesselKind, modeled on real container
/// proportions rather than abstract trapezoids.
private struct VesselShape: Shape {
    let kind: VesselKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .glass: return glassPath(in: rect)
        case .mug: return mugPath(in: rect)
        case .bottle: return bottlePath(in: rect)
        case .bowl: return bowlPath(in: rect)
        }
    }

    /// A classic drinking glass: slightly wider at the rim than the base,
    /// straight tapered sides, gently rounded bottom corners.
    private func glassPath(in rect: CGRect) -> Path {
        let w = rect.width
        let topInset = w * 0.08
        let bottomInset = w * 0.18
        let cornerRadius = w * 0.1

        let topLeft = CGPoint(x: rect.minX + topInset, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX - topInset, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX - bottomInset, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX + bottomInset, y: rect.maxY)

        var path = Path()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y), control: bottomRight)
        path.addLine(to: CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y))
        path.addQuadCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius), control: bottomLeft)
        path.closeSubpath()
        return path
    }

    /// A straight-sided mug: nearly vertical walls, small rounded base.
    private func mugPath(in rect: CGRect) -> Path {
        let w = rect.width
        let inset = w * 0.16
        let cornerRadius = w * 0.08

        let topLeft = CGPoint(x: rect.minX + inset, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX - inset * 1.4, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX - inset * 1.6, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX + inset * 0.8, y: rect.maxY)

        var path = Path()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y), control: bottomRight)
        path.addLine(to: CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y))
        path.addQuadCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius), control: bottomLeft)
        path.closeSubpath()
        return path
    }

    /// A bottle: narrow neck at top, sloped shoulders widening into a
    /// straight-sided body with a rounded base.
    private func bottlePath(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let neckInset = w * 0.32
        let bodyInset = w * 0.14
        let shoulderY = rect.minY + h * 0.32
        let cornerRadius = w * 0.1

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + neckInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - neckInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - neckInset, y: rect.minY + h * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX - bodyInset, y: shoulderY))
        path.addLine(to: CGPoint(x: rect.maxX - bodyInset, y: rect.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - bodyInset - cornerRadius, y: rect.maxY), control: CGPoint(x: rect.maxX - bodyInset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bodyInset + cornerRadius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + bodyInset, y: rect.maxY - cornerRadius), control: CGPoint(x: rect.minX + bodyInset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bodyInset, y: shoulderY))
        path.addLine(to: CGPoint(x: rect.minX + neckInset, y: rect.minY + h * 0.12))
        path.closeSubpath()
        return path
    }

    /// A wide, shallow bowl — much narrower base than rim, gently curved sides.
    private func bowlPath(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let bowlHeight = h * 0.62
        let top = rect.minY + (h - bowlHeight) / 2
        let bottom = top + bowlHeight

        let topLeft = CGPoint(x: rect.minX, y: top)
        let topRight = CGPoint(x: rect.maxX, y: top)
        let baseHalfWidth = w * 0.16

        var path = Path()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addCurve(
            to: CGPoint(x: rect.midX + baseHalfWidth, y: bottom),
            control1: CGPoint(x: rect.maxX, y: top + bowlHeight * 0.6),
            control2: CGPoint(x: rect.midX + baseHalfWidth * 1.8, y: bottom)
        )
        path.addLine(to: CGPoint(x: rect.midX - baseHalfWidth, y: bottom))
        path.addCurve(
            to: topLeft,
            control1: CGPoint(x: rect.midX - baseHalfWidth * 1.8, y: bottom),
            control2: CGPoint(x: rect.minX, y: top + bowlHeight * 0.6)
        )
        path.closeSubpath()
        return path
    }
}

/// A small D-shaped handle on the right side, for the mug vessel kind —
/// drawn as an open arc so a plain stroke renders it as a handle outline.
private struct MugHandleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.midY)
        let radius = rect.height * 0.16

        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .degrees(-80), endAngle: .degrees(80), clockwise: false)
        return path
    }
}

/// A few small static circles suggesting bubbles in the liquid; positions are
/// derived deterministically from `seed` so the same vessel kind always shows
/// the same arrangement (no per-frame randomness/animation).
///
/// Drawn as a single `Shape` rather than a `GeometryReader` + `ForEach` of
/// `Circle` views — `Shape.path(in:)` is handed its final rect directly by
/// layout, so this avoids an extra per-instance layout pass. That matters
/// here because `CupIconView` is instantiated per row in scrolling history
/// lists, where a `GeometryReader` per row was a measurable jank contributor.
private struct BubblesShape: Shape {
    let seed: Int

    private struct Bubble { let x: CGFloat; let y: CGFloat; let size: CGFloat }

    private var bubbles: [Bubble] {
        var generator = SeededGenerator(seed: seed)
        return (0..<5).map { _ in
            Bubble(
                x: CGFloat.random(in: 0.2...0.8, using: &generator),
                y: CGFloat.random(in: 0.1...0.9, using: &generator),
                size: CGFloat.random(in: 0.05...0.11, using: &generator)
            )
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for bubble in bubbles {
            let diameter = rect.width * bubble.size
            let center = CGPoint(x: rect.width * bubble.x, y: rect.height * bubble.y)
            path.addEllipse(in: CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter))
        }
        return path
    }
}

/// Deterministic pseudo-random generator so bubble layout is stable across
/// re-renders instead of reshuffling every frame.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) { state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// Circular badge used in history rows and drink buttons: a filled CupIconView
/// for water, or the drink type's own SF Symbol for everything else — same
/// background circle either way so the two styles sit consistently in a list.
struct DrinkIconBadge: View {
    let type: DrinkType
    /// The logged amount, used to pick which vessel silhouette to draw for
    /// water entries (ignored for other drink types, which use their SF Symbol).
    var milliliters: Int = 250
    var size: CGFloat = 36
    var background: Color = Theme.cardBackgroundAlt

    var body: some View {
        Group {
            if type == .water {
                CupIconView(kind: CupSize.vesselKind(forMilliliters: milliliters), showBubbles: true)
                    .padding(size * 0.18)
            } else {
                Image(systemName: type.icon)
                    .font(.system(size: size * 0.44))
                    .foregroundStyle(type.tint)
            }
        }
        .frame(width: size, height: size)
        .background(background, in: Circle())
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            CupIconView(kind: .glass)
            CupIconView(kind: .mug)
            CupIconView(kind: .bottle)
            CupIconView(kind: .bowl)
        }
        HStack(spacing: 16) {
            CupIconView(kind: .glass, showBubbles: true)
            CupIconView(kind: .mug, showBubbles: true)
            CupIconView(kind: .bottle, showBubbles: true)
            CupIconView(kind: .bowl, showBubbles: true)
        }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
            ForEach(CupSize.allCases) { size in
                CupIconView(kind: size.vesselKind)
                    .frame(width: 40, height: 40)
            }
        }
    }
    .frame(width: 48, height: 48)
    .padding()
}
