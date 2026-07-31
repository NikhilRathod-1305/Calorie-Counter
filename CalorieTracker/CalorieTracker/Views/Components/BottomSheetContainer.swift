import SwiftUI

struct BottomSheetContainer<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let onClose: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.textPrimary.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack(alignment: subtitle == nil ? .center : .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.Font.display(18))
                        .foregroundStyle(Theme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, height: 30)
                        .glassCardAlt(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            content
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .glassCard(
            .rect(topLeadingRadius: Theme.Radius.sheet, topTrailingRadius: Theme.Radius.sheet)
        )
    }
}
