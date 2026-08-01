import SwiftUI

struct ToastView: View {
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textPrimary)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.Font.text(13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
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
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message {
                ToastView(message: message, actionTitle: actionTitle, action: action)
                    .padding(.top, 64)
            }
        }
    }
}

extension View {
    func toast(_ message: String?) -> some View {
        modifier(ToastOverlayModifier(message: message))
    }

    func toast(_ message: String?, actionTitle: String?, action: (() -> Void)?) -> some View {
        modifier(ToastOverlayModifier(message: message, actionTitle: actionTitle, action: action))
    }
}
