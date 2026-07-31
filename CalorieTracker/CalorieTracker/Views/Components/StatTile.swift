import SwiftUI

struct StatTile: View {
    let label: String
    let value: String
    let unit: String
    var trailingAccessory: AnyView? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if let trailingAccessory {
                    trailingAccessory
                }
            }
            .frame(height: 32)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 130)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .onTapGesture { onTap?() }
    }
}
