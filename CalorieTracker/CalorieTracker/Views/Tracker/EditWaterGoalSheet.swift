import SwiftUI

struct EditWaterGoalSheet: View {
    let onClose: () -> Void
    let onSave: (Int) -> Void

    @State private var goalMl: Int

    init(currentGoalMl: Int, onClose: @escaping () -> Void, onSave: @escaping (Int) -> Void) {
        self.onClose = onClose
        self.onSave = onSave
        _goalMl = State(initialValue: currentGoalMl)
    }

    var body: some View {
        BottomSheetContainer(title: "Edit daily goal", onClose: onClose) {
            VStack(spacing: 18) {
                HStack(spacing: 6) {
                    TextField("0", value: $goalMl, format: .number)
                        .keyboardType(.numberPad)
                        .font(Theme.Font.display(40))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(width: 140)
                    Text("mL")
                        .font(Theme.Font.text(16))
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassCardAlt(RoundedRectangle(cornerRadius: 16))

                Button {
                    onSave(goalMl)
                } label: {
                    Text("Save goal")
                        .font(Theme.Font.text(14, weight: .semibold))
                        .foregroundStyle(Theme.onWater)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.water, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(goalMl <= 0)
            }
        }
    }
}
