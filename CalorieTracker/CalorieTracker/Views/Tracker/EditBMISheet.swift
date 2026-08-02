import SwiftUI

struct EditBMISheet: View {
    let onClose: () -> Void
    let onSave: (Double, Double) -> Void

    @State private var heightCm: Double
    @State private var weightKg: Double

    init(currentHeightCm: Double, currentWeightKg: Double, onClose: @escaping () -> Void, onSave: @escaping (Double, Double) -> Void) {
        self.onClose = onClose
        self.onSave = onSave
        _heightCm = State(initialValue: currentHeightCm)
        _weightKg = State(initialValue: currentWeightKg)
    }

    var body: some View {
        BottomSheetContainer(title: "Edit BMI", onClose: onClose) {
            VStack(spacing: 14) {
                labeledField(label: "Height", value: $heightCm, unit: "cm")
                labeledField(label: "Weight", value: $weightKg, unit: "kg")

                HStack(spacing: 10) {
                    Button(action: onClose) {
                        Text("Cancel")
                            .font(Theme.Font.text(14, weight: .semibold))
                            .foregroundStyle(Theme.bmi)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .overlay(Capsule().stroke(Theme.bmi, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSave(heightCm, weightKg)
                    } label: {
                        Text("Save")
                            .font(Theme.Font.text(14, weight: .semibold))
                            .foregroundStyle(Theme.onBMI)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.bmi, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(heightCm <= 0 || weightKg <= 0)
                }
                .padding(.top, 4)
            }
        }
    }

    private func labeledField(label: String, value: Binding<Double>, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.Font.text(12))
                .foregroundStyle(Theme.textFaint)
            HStack(spacing: 6) {
                TextField("0", value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .font(Theme.Font.display(32))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: 120)
                Text(unit)
                    .font(Theme.Font.text(14))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCardAlt(RoundedRectangle(cornerRadius: 16))
    }
}
