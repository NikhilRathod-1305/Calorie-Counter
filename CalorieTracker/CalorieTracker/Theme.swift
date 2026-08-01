import SwiftUI
import UIKit

enum Theme {
    // MARK: Backgrounds
    static let background = Color(light: 0xF6F8F6, dark: 0x0E1512)
    static let groupedBackground = Color(light: 0xF1F4F1, dark: 0x0E1512)
    static let cardBackground = Color(light: 0xFFFFFF, dark: 0x18211C)
    static let cardBackgroundAlt = Color(light: 0xF4F7F4, dark: 0x141C18)

    // MARK: Text
    static let textPrimary = Color(light: 0x14231A, dark: 0xEAF2ED)
    static let textSecondary = Color(light: 0x14231A, dark: 0xEAF2ED, opacity: 0.62)
    static let textTertiary = Color(light: 0x4A5A50, dark: 0xEAF2ED, opacity: 0.55)
    static let textFaint = Color(light: 0x14231A, dark: 0xEAF2ED, opacity: 0.32)

    // MARK: Lines / separators
    static let hairline = Color(light: 0x1F3D2C, dark: 0x4CAF50, opacity: 0.14)
    static let separator = Color(light: 0x1F3D2C, dark: 0x4CAF50, opacity: 0.20)

    // MARK: Accent (primary green — brand color)
    static let accent = Color(light: 0x2FA84F, dark: 0x4CD46B)
    static let accentSoft = Color(light: 0x2FA84F, dark: 0x4CD46B, opacity: 0.14)
    static let onAccent = Color(light: 0xFFFFFF, dark: 0x06210E)

    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0x4CD46B), Color(hex: 0x2FA84F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Secondary (warm orange — calories / food / energy)
    static let secondary = Color(light: 0xFF8A34, dark: 0xFF9A4D)
    static let secondarySoft = Color(light: 0xFF8A34, dark: 0xFF9A4D, opacity: 0.14)
    static let onSecondary = Color(light: 0xFFFFFF, dark: 0x2E1600)

    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: 0xFFA95C), Color(hex: 0xFF7A1A)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Macro colors
    static let proteinColor = Color(light: 0x2F7CE0, dark: 0x5B9CFF)
    static let carbColor = Color(light: 0xFF8A34, dark: 0xFF9A4D)
    static let fatColor = Color(light: 0xE0435A, dark: 0xFF6B80)

    // MARK: Feature accents
    static let steps = Color(light: 0xFF8A34, dark: 0xFF9A4D)
    static let water = Color(light: 0x2F9CE0, dark: 0x4FB6F5)
    static let waterSoft = Color(light: 0x2F9CE0, dark: 0x4FB6F5, opacity: 0.14)
    static let onWater = Color(light: 0xFFFFFF, dark: 0x00263B)

    static let waterGradient = LinearGradient(
        colors: [Color(hex: 0x4FB6F5), Color(hex: 0x2F9CE0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let exercise = Color(light: 0xFF8A34, dark: 0xFF9A4D)
    static let weight = Color(light: 0x2F7CE0, dark: 0x5B9CFF)
    static let weightSoft = Color(light: 0x2F7CE0, dark: 0x5B9CFF, opacity: 0.14)

    static let weightGradient = LinearGradient(
        colors: [Color(hex: 0x5B9CFF), Color(hex: 0x2F7CE0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Status
    static let success = Color(light: 0x2FA84F, dark: 0x4CD46B)
    static let warning = Color(light: 0xE0A430, dark: 0xF0B840)
    static let danger = Color(light: 0xE0435A, dark: 0xFF6B80)

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
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let sheet: CGFloat = 24
    }
}

extension View {
    /// Flat card surface with a soft shadow — matches a light, friendly card-based UI
    /// rather than a frosted/glass panel. Works the same in light and dark since the
    /// shadow is nearly invisible on dark backgrounds anyway.
    func glassCard<S: Shape>(_ shape: S, tint: Color = Theme.cardBackground) -> some View {
        self
            .background(tint, in: shape)
            .clipShape(shape)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    func glassCardAlt<S: Shape>(_ shape: S, tint: Color = Theme.cardBackgroundAlt) -> some View {
        self
            .background(tint, in: shape)
            .clipShape(shape)
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
