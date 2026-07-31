import SwiftUI
import UIKit

enum Theme {
    // MARK: Backgrounds (deep space-black surface system for a liquid-glass look)
    static let background = Color(light: 0xFFF8F6, dark: 0x0A0D12)
    static let groupedBackground = Color(light: 0xFBF4F1, dark: 0x0A0D12)
    static let cardBackground = Color(light: 0xFFFFFF, dark: 0x151A21)
    static let cardBackgroundAlt = Color(light: 0xF3ECE8, dark: 0x11151B)

    // MARK: Text
    static let textPrimary = Color(light: 0x1F1B18, dark: 0xF2F4F8)
    static let textSecondary = Color(light: 0x1F1B18, dark: 0xF2F4F8, opacity: 0.62)
    static let textTertiary = Color(light: 0x1F1B18, dark: 0xFFB98C, opacity: 0.75)
    static let textFaint = Color(light: 0x1F1B18, dark: 0xF2F4F8, opacity: 0.30)

    // MARK: Lines / separators
    static let hairline = Color(light: 0xA98A7D, dark: 0xFF6B00, opacity: 0.18)
    static let separator = Color(light: 0xA98A7D, dark: 0xFF6B00, opacity: 0.25)

    // MARK: Accent (vivid primary orange)
    static let accent = Color(light: 0xA04100, dark: 0xFF6B00)
    static let accentSoft = Color(light: 0xA04100, dark: 0xFF6B00, opacity: 0.16)
    static let onAccent = Color(light: 0xFFFFFF, dark: 0x2E1300)

    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0xFF6B00), Color(hex: 0xFFB693)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Secondary (electric cyan — data viz / trend accent)
    static let secondary = Color(light: 0x0090A0, dark: 0x00F0FF)
    static let secondarySoft = Color(light: 0x0090A0, dark: 0x00F0FF, opacity: 0.16)
    static let onSecondary = Color(light: 0xFFFFFF, dark: 0x00343A)

    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: 0x00F0FF), Color(hex: 0x0090A0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Macro colors (Stitch secondary/tertiary/primary triad)
    static let proteinColor = Color(light: 0x0090A0, dark: 0x00F0FF)
    static let carbColor = Color(light: 0xC0392B, dark: 0xFFB4AA)
    static let fatColor = Color(light: 0xA04100, dark: 0xFF6B00)

    // MARK: Feature accents
    static let steps = Color(light: 0x0090A0, dark: 0x00F0FF)
    static let water = Color(light: 0x1550A0, dark: 0x4B8EFF)
    static let onWater = Color(light: 0xFFFFFF, dark: 0x00285C)
    static let exercise = Color(light: 0x9A2A20, dark: 0xFF6B00)

    // MARK: Status
    static let success = Color(light: 0x1FBF7A, dark: 0x3AD98F)
    static let warning = Color(light: 0xE0A430, dark: 0xF0B840)
    static let danger = Color(light: 0x93000A, dark: 0xFFB4AB)

    enum Font {
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .bold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func text(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight)
        }
    }

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let sheet: CGFloat = 20
    }
}

extension View {
    /// Liquid Glass card surface — replaces a flat `Theme.cardBackground` fill with real
    /// iOS 26 glass tinted to match the app's card color, so cards read as frosted glass
    /// over the dark background rather than opaque panels.
    func glassCard<S: Shape>(_ shape: S, tint: Color = Theme.cardBackground) -> some View {
        self.glassEffect(.regular.tint(tint.opacity(0.38)), in: shape)
    }

    func glassCardAlt<S: Shape>(_ shape: S, tint: Color = Theme.cardBackgroundAlt) -> some View {
        self.glassEffect(.regular.tint(tint.opacity(0.38)), in: shape)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    init(light: UInt32, dark: UInt32, opacity: Double = 1) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            let r = CGFloat((hex >> 16) & 0xFF) / 255
            let g = CGFloat((hex >> 8) & 0xFF) / 255
            let b = CGFloat(hex & 0xFF) / 255
            return UIColor(red: r, green: g, blue: b, alpha: opacity)
        })
    }
}
