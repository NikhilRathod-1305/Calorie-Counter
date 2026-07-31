import SwiftUI

struct LogWeightSheet: View {
    let editingEntry: WeightLogEntry?
    let onClose: () -> Void
    let onSave: (Double, Date) -> Void

    @State private var weight: Double
    @State private var date: Date

    init(initialWeight: Double, editingEntry: WeightLogEntry? = nil, onClose: @escaping () -> Void, onSave: @escaping (Double, Date) -> Void) {
        self.editingEntry = editingEntry
        self.onClose = onClose
        self.onSave = onSave
        _weight = State(initialValue: editingEntry?.weightKg ?? initialWeight)
        _date = State(initialValue: editingEntry?.date ?? Date())
    }

    var body: some View {
        BottomSheetContainer(title: editingEntry != nil ? "Edit weight" : "Log weight", onClose: onClose) {
            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 18) {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            TextField("0", value: $weight, format: .number)
                                .keyboardType(.decimalPad)
                                .font(Theme.Font.display(40))
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .frame(width: 140)
                            Text("kg")
                                .font(Theme.Font.text(16))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .glassCardAlt(RoundedRectangle(cornerRadius: 16))

                    if editingEntry != nil {
                        DatePicker("Date", selection: $date, in: ...Date())
                            .datePickerStyle(.compact)
                            .font(Theme.Font.text(14))
                            .tint(Theme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .glassCardAlt(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onSave(weight, date)
                    } label: {
                        Text(editingEntry != nil ? "Save changes" : "Save")
                            .font(Theme.Font.text(14, weight: .semibold))
                            .foregroundStyle(Theme.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(weight <= 0)
                }
            }
        }
    }
}
