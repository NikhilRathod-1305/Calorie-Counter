import SwiftUI

struct QuantityStepper: View {
    @Binding var quantity: Double
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 14) {
            stepButton(symbol: "minus") {
                quantity = max(0.5, (quantity - 0.5 * 10).rounded() / 10)
            }
            Text(quantityText)
                .font(Theme.Font.text(14))
                .foregroundStyle(Theme.textPrimary)
                .frame(minWidth: 34)
                .multilineTextAlignment(.center)
            stepButton(symbol: "plus") {
                quantity = ((quantity + 0.5) * 10).rounded() / 10
            }
        }
    }

    private var quantityText: String {
        let rounded = (quantity * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "\(Int(rounded))×"
        }
        return String(format: "%.1f×", rounded)
    }

    private func stepButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: size, height: size)
                .glassCardAlt(Circle())
        }
        .buttonStyle(.plain)
    }
}
