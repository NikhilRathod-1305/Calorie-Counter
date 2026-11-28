import SwiftUI
import SwiftData

struct RoutineBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    var routine: WorkoutRoutine?
    let onClose: () -> Void

    @State private var name: String
    @State private var plannedExercises: [PlannedExercise]
    @State private var showingExercisePicker = false

    struct PlannedExercise: Identifiable {
        let id = UUID()
        var exercise: Exercise?
        var exerciseName: String
        var targetSets: Int
        var targetReps: Int?
        var targetDurationMinutes: Double?
    }

    init(routine: WorkoutRoutine? = nil, onClose: @escaping () -> Void) {
        self.routine = routine
        self.onClose = onClose
        _name = State(initialValue: routine?.name ?? "")
        _plannedExercises = State(initialValue: (routine?.orderedExercises ?? []).map {
            PlannedExercise(exercise: $0.exercise, exerciseName: $0.exerciseName, targetSets: $0.targetSets, targetReps: $0.targetReps, targetDurationMinutes: $0.targetDurationMinutes)
        })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section {
                        TextField("Routine name", text: $name)
                    }

                    Section("Exercises") {
                        ForEach($plannedExercises) { $planned in
                            plannedRow($planned)
                        }
                        .onDelete { plannedExercises.remove(atOffsets: $0) }

                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                        }
                    }

                    if routine != nil {
                        Section {
                            Button("Delete Routine", role: .destructive) {
                                deleteRoutine()
                            }
                        }
                    }
                }
            }
            .navigationTitle(routine != nil ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || plannedExercises.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(mode: .add, onClose: { showingExercisePicker = false }, onPick: { exercise in
                plannedExercises.append(PlannedExercise(exercise: exercise, exerciseName: exercise.name, targetSets: 3, targetReps: exercise.isCardio ? nil : 10, targetDurationMinutes: exercise.isCardio ? 20 : nil))
                showingExercisePicker = false
            })
        }
    }

    private func plannedRow(_ planned: Binding<PlannedExercise>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(planned.wrappedValue.exerciseName)
                .font(Theme.Font.text(14, weight: .semibold))
            if planned.wrappedValue.targetDurationMinutes != nil {
                Stepper("Duration: \(Int(planned.wrappedValue.targetDurationMinutes ?? 0)) min", value: Binding(
                    get: { planned.wrappedValue.targetDurationMinutes ?? 20 },
                    set: { planned.wrappedValue.targetDurationMinutes = $0 }
                ), in: 5...180, step: 5)
            } else {
                Stepper("Sets: \(planned.wrappedValue.targetSets)", value: planned.targetSets, in: 1...10)
                Stepper("Reps: \(planned.wrappedValue.targetReps ?? 0)", value: Binding(
                    get: { planned.wrappedValue.targetReps ?? 10 },
                    set: { planned.wrappedValue.targetReps = $0 }
                ), in: 1...50)
            }
        }
    }

    private func save() {
        let target = routine ?? WorkoutRoutine(name: name)
        target.name = name
        if routine == nil {
            modelContext.insert(target)
        } else {
            for existing in target.orderedExercises {
                modelContext.delete(existing)
            }
        }
        for (index, planned) in plannedExercises.enumerated() {
            let routineExercise = WorkoutRoutineExercise(
                exercise: planned.exercise,
                exerciseName: planned.exerciseName,
                order: index,
                targetSets: planned.targetSets,
                targetReps: planned.targetReps,
                targetDurationMinutes: planned.targetDurationMinutes
            )
            routineExercise.routine = target
            modelContext.insert(routineExercise)
        }
        try? modelContext.save()
        onClose()
    }

    private func deleteRoutine() {
        if let routine {
            modelContext.delete(routine)
            try? modelContext.save()
        }
        onClose()
    }
}
