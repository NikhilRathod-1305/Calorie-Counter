import SwiftUI

struct EditStepGoalSheet: View {
    let onClose: () -> Void
    let onSave: (Int) -> Void

    @State private var goal: Int

    init(currentGoal: Int, onClose: @escaping () -> Void, onSave: @escaping (Int) -> Void) {
        self.onClose = onClose
        self.onSave = onSave
        _goal = State(initialValue: currentGoal)
    }

    var body: some View {
        BottomSheetContainer(title: "Edit daily goal", onClose: onClose) {
            VStack(spacing: 18) {
                HStack(spacing: 6) {
                    TextField("0", value: $goal, format: .number)
                        .keyboardType(.numberPad)
                        .font(Theme.Font.display(40))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(width: 140)
                    Text("steps")
                        .font(Theme.Font.text(16))
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassCardAlt(RoundedRectangle(cornerRadius: 16))

                Button {
                    onSave(goal)
                } label: {
                    Text("Save goal")
                        .font(Theme.Font.text(14, weight: .semibold))
                        .foregroundStyle(Theme.onSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.steps, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(goal <= 0)
            }
        }
    }
}
