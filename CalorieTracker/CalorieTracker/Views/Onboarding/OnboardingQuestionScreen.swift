import SwiftUI

struct OnboardingQuestionScreen<Content: View>: View {
    let step: Int
    let totalSteps: Int
    let title: String
    let subtitle: String?
    let canGoBack: Bool
    let canContinue: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if canGoBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 32, height: 32)
                            .glassCardAlt(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 32, height: 32)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hairline)
                        Capsule()
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * CGFloat(step) / CGFloat(totalSteps))
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(Theme.Font.display(26))
                            .foregroundStyle(Theme.textPrimary)
                        if let subtitle {
                            Text(subtitle)
                                .font(Theme.Font.text(14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(.top, 20)

                    content
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Button(action: onContinue) {
                Text("Continue")
                    .font(Theme.Font.text(16, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canContinue ? Theme.accent : Theme.accent.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
