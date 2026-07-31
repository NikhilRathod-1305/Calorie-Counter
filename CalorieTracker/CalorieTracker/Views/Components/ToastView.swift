import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Theme.Font.text(13))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Theme.cardBackgroundAlt, in: Capsule())
            .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct ToastOverlayModifier: ViewModifier {
    let message: String?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message {
                ToastView(message: message)
                    .padding(.top, 64)
            }
        }
    }
}

extension View {
    func toast(_ message: String?) -> some View {
        modifier(ToastOverlayModifier(message: message))
    }
}
