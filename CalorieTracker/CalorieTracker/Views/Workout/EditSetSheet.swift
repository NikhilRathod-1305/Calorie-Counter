import SwiftUI

struct EditSetSheet: View {
    @Bindable var workoutSet: WorkoutSet
    let onClose: () -> Void
    let onSave: () -> Void

    @State private var reps: Double
    @State private var weightKg: Double
    @State private var durationMinutes: Double
    @State private var distanceKm: Double
    @State private var rpe: Double
    @State private var restSeconds: Double

    init(set: WorkoutSet, onClose: @escaping () -> Void, onSave: @escaping () -> Void) {
        self.workoutSet = set
        self.onClose = onClose
        self.onSave = onSave
        _reps = State(initialValue: Double(set.reps ?? 0))
        _weightKg = State(initialValue: set.weightKg ?? 0)
        _durationMinutes = State(initialValue: set.durationMinutes ?? 0)
        _distanceKm = State(initialValue: set.distanceKm ?? 0)
        _rpe = State(initialValue: set.rpe ?? 0)
        _restSeconds = State(initialValue: Double(set.restSeconds ?? 90))
    }

    private var isCardio: Bool { workoutSet.isCardioSet }

    var body: some View {
        BottomSheetContainer(title: workoutSet.exerciseName, subtitle: isCardio ? "Cardio" : "Strength", onClose: onClose) {
            VStack(spacing: 16) {
                if isCardio {
                    fieldRow(label: "Duration (min)", value: $durationMinutes)
                    fieldRow(label: "Distance (km)", value: $distanceKm, isDecimal: true)
                } else {
                    HStack(spacing: 10) {
                        fieldRow(label: "Weight (kg)", value: $weightKg, isDecimal: true)
                        fieldRow(label: "Reps", value: $reps)
                    }
                    HStack(spacing: 10) {
                        fieldRow(label: "RPE", value: $rpe, isDecimal: true)
                        fieldRow(label: "Rest (sec)", value: $restSeconds)
                    }
                }

                Button {
                    save()
                } label: {
                    Text("Save")
                        .font(Theme.Font.text(14, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fieldRow(label: String, value: Binding<Double>, isDecimal: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textSecondary)
            TextField("0", value: value, format: isDecimal ? .number.precision(.fractionLength(0...1)) : .number)
                .keyboardType(isDecimal ? .decimalPad : .numberPad)
                .font(Theme.Font.display(18))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassCardAlt(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        if isCardio {
            workoutSet.durationMinutes = durationMinutes > 0 ? durationMinutes : nil
            workoutSet.distanceKm = distanceKm > 0 ? distanceKm : nil
        } else {
            workoutSet.weightKg = weightKg > 0 ? weightKg : nil
            workoutSet.reps = reps > 0 ? Int(reps) : nil
            workoutSet.rpe = rpe > 0 ? rpe : nil
            workoutSet.restSeconds = restSeconds > 0 ? Int(restSeconds) : nil
        }
        workoutSet.isCompleted = true
        onSave()
        onClose()
    }
}
