import SwiftUI

struct LogExerciseSheet: View {
    var editingEntry: ExerciseEntry? = nil
    let onClose: () -> Void
    let onSave: (String, Double, Double?) -> Void

    @State private var name: String
    @State private var calories: Double
    @State private var duration: Double

    init(editingEntry: ExerciseEntry? = nil, onClose: @escaping () -> Void, onSave: @escaping (String, Double, Double?) -> Void) {
        self.editingEntry = editingEntry
        self.onClose = onClose
        self.onSave = onSave
        _name = State(initialValue: editingEntry?.name ?? "")
        _calories = State(initialValue: editingEntry?.caloriesBurned ?? 0)
        _duration = State(initialValue: editingEntry?.durationMinutes ?? 0)
    }

    var body: some View {
        BottomSheetContainer(title: editingEntry != nil ? "Edit exercise" : "Log exercise", onClose: onClose) {
            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Activity")
                            .font(Theme.Font.text(11))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("e.g. Running, Gym, Cycling", text: $name)
                            .font(Theme.Font.text(15))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .glassCardAlt(RoundedRectangle(cornerRadius: 12))
                    }

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Calories burned")
                                .font(Theme.Font.text(11))
                                .foregroundStyle(Theme.textSecondary)
                            TextField("0", value: $calories, format: .number)
                                .keyboardType(.numberPad)
                                .font(Theme.Font.display(18))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .glassCardAlt(RoundedRectangle(cornerRadius: 12))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Duration (min)")
                                .font(Theme.Font.text(11))
                                .foregroundStyle(Theme.textSecondary)
                            TextField("Optional", value: $duration, format: .number)
                                .keyboardType(.numberPad)
                                .font(Theme.Font.display(18))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .glassCardAlt(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmed.isEmpty ? "Exercise" : trimmed, calories, duration > 0 ? duration : nil)
                    } label: {
                        Text(editingEntry != nil ? "Save changes" : "Add to log")
                            .font(Theme.Font.text(14, weight: .semibold))
                            .foregroundStyle(Theme.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(calories <= 0)
                }
            }
        }
    }
}
