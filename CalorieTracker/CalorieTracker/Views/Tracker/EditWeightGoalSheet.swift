import SwiftUI

struct EditWeightGoalSheet: View {
    let onClose: () -> Void
    let onSave: (Double) -> Void

    @State private var goalKg: Double

    init(currentGoalKg: Double, onClose: @escaping () -> Void, onSave: @escaping (Double) -> Void) {
        self.onClose = onClose
        self.onSave = onSave
        _goalKg = State(initialValue: currentGoalKg)
    }

    var body: some View {
        BottomSheetContainer(title: "Edit goal weight", onClose: onClose) {
            VStack(spacing: 18) {
                HStack(spacing: 6) {
                    TextField("0", value: $goalKg, format: .number)
                        .keyboardType(.decimalPad)
                        .font(Theme.Font.display(40))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(width: 140)
                    Text("kg")
                        .font(Theme.Font.text(16))
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassCardAlt(RoundedRectangle(cornerRadius: 16))

                Button {
                    onSave(goalKg)
                } label: {
                    Text("Save goal")
                        .font(Theme.Font.text(14, weight: .semibold))
                        .foregroundStyle(Theme.onSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.secondary, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(goalKg <= 0)
            }
        }
    }
}
