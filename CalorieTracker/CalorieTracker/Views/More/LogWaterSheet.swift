import SwiftUI

struct LogWaterSheet: View {
    let onClose: () -> Void
    let onSave: (Int, Date) -> Void

    @State private var milliliters: Int
    @State private var date: Date

    init(editingEntry: WaterLogEntry, onClose: @escaping () -> Void, onSave: @escaping (Int, Date) -> Void) {
        self.onClose = onClose
        self.onSave = onSave
        _milliliters = State(initialValue: editingEntry.milliliters)
        _date = State(initialValue: editingEntry.date)
    }

    var body: some View {
        BottomSheetContainer(title: "Edit water", onClose: onClose) {
            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 18) {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            TextField("0", value: $milliliters, format: .number)
                                .keyboardType(.numberPad)
                                .font(Theme.Font.display(40))
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .frame(width: 140)
                            Text("ml")
                                .font(Theme.Font.text(16))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .glassCardAlt(RoundedRectangle(cornerRadius: 16))

                    DatePicker("Date", selection: $date, in: ...Date())
                        .datePickerStyle(.compact)
                        .font(Theme.Font.text(14))
                        .tint(Theme.water)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .glassCardAlt(RoundedRectangle(cornerRadius: 14))

                    Button {
                        onSave(milliliters, date)
                    } label: {
                        Text("Save changes")
                            .font(Theme.Font.text(14, weight: .semibold))
                            .foregroundStyle(Theme.onWater)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.water, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(milliliters <= 0)
                }
            }
        }
    }
}
