import SwiftUI

/// Shared card shell for the Tracker tab: a colored circular icon + title header,
/// a chevron on the right, and a nested light-gray content area below.
struct TrackerCardRow<Icon: View, Content: View>: View {
    let iconColor: Color
    let title: String
    var onTap: (() -> Void)? = nil
    @ViewBuilder let icon: Icon
    @ViewBuilder let content: Content

    init(
        icon systemIcon: String,
        iconColor: Color,
        title: String,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) where Icon == AnyView {
        self.iconColor = iconColor
        self.title = title
        self.onTap = onTap
        self.icon = AnyView(
            Image(systemName: systemIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        )
        self.content = content()
    }

    init(
        iconColor: Color,
        title: String,
        onTap: (() -> Void)? = nil,
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder content: () -> Content
    ) {
        self.iconColor = iconColor
        self.title = title
        self.onTap = onTap
        self.icon = icon()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                onTap?()
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 34, height: 34)
                        .overlay(icon.clipShape(Circle()).padding(6))
                    Text(title)
                        .font(Theme.Font.text(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if onTap != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.textFaint)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(onTap == nil)

            content
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Theme.cardBackgroundAlt, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .padding(16)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }
}
