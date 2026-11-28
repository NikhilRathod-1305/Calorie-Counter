import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: WorkoutSession
    let onEnd: () -> Void

    @State private var showingExercisePicker = false
    @State private var showingFinishConfirm = false
    @State private var editingSet: WorkoutSet?
    @State private var restSecondsRemaining: Int?
    @State private var elapsed: TimeInterval = 0

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let rest = restSecondsRemaining, rest > 0 {
                            restBanner(rest)
                        }

                        ForEach(session.exerciseGroups, id: \.exerciseName) { group in
                            exerciseCard(group)
                        }

                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus.circle.fill")
                                .font(Theme.Font.text(14, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                        }
                        .buttonStyle(.plain)

                        Color.clear.frame(height: 60)
                    }
                    .padding(16)
                }
                .background(Theme.groupedBackground.ignoresSafeArea())
            }
        }
        .onReceive(ticker) { _ in
            elapsed = session.durationMinutes
            if let remaining = restSecondsRemaining {
                restSecondsRemaining = remaining > 0 ? remaining - 1 : nil
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(mode: .add, onClose: { showingExercisePicker = false }, onPick: { exercise in
                addExercise(exercise)
                showingExercisePicker = false
            })
        }
        .sheet(item: $editingSet) { set in
            EditSetSheet(set: set, onClose: { editingSet = nil }, onSave: { saveSet(set) })
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
        }
        .confirmationDialog("Finish workout?", isPresented: $showingFinishConfirm, titleVisibility: .visible) {
            Button("Finish") { finishWorkout() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack {
            Button {
                onEnd()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32, height: 32)
                    .glassCardAlt(Circle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 1) {
                Text(session.name)
                    .font(Theme.Font.display(16))
                    .foregroundStyle(Theme.textPrimary)
                Text(elapsedLabel)
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                showingFinishConfirm = true
            } label: {
                Text("Finish")
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.cardBackground)
    }

    private var elapsedLabel: String {
        let minutes = Int(elapsed)
        let seconds = Int((elapsed - Double(minutes)) * 60)
        return String(format: "%d:%02d elapsed", minutes, seconds)
    }

    private func restBanner(_ remaining: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text("Rest: \(remaining)s")
                .font(Theme.Font.text(14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button("Skip") { restSecondsRemaining = nil }
                .font(Theme.Font.text(12, weight: .semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(14)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium), tint: Theme.accentSoft)
    }

    private func exerciseCard(_ group: (exercise: Exercise?, exerciseName: String, sets: [WorkoutSet])) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(group.exercise?.emoji ?? "🏋️")
                Text(group.exerciseName)
                    .font(Theme.Font.text(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(14)

            Divider().overlay(Theme.hairline)

            ForEach(Array(group.sets.enumerated()), id: \.element.id) { index, set in
                setRow(set, index: index)
                if set.id != group.sets.last?.id {
                    Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 14)
                }
            }

            Button {
                addSet(like: group.sets.last, exercise: group.exercise, name: group.exerciseName)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(Theme.Font.text(12, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private func setRow(_ set: WorkoutSet, index: Int) -> some View {
        SwipeToDeleteRow(
            onTap: { editingSet = set },
            onDelete: { deleteSet(set) }
        ) {
            HStack(spacing: 10) {
                Text("\(index + 1)")
                    .font(Theme.Font.text(12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(width: 20)

                Text(set.summaryLabel.isEmpty ? "Tap to log" : set.summaryLabel)
                    .font(Theme.Font.text(13))
                    .foregroundStyle(set.summaryLabel.isEmpty ? Theme.textFaint : Theme.textPrimary)

                Spacer()

                Button {
                    completeSet(set)
                } label: {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(set.isCompleted ? Theme.success : Theme.textFaint)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
    }

    // MARK: Actions

    private func addExercise(_ exercise: Exercise) {
        let nextOrder = ((session.sets ?? []).map(\.order).max() ?? -1) + 1
        let set = WorkoutSet(exercise: exercise, exerciseName: exercise.name, order: nextOrder, isCompleted: false)
        set.session = session
        modelContext.insert(set)
        try? modelContext.save()
    }

    private func addSet(like previous: WorkoutSet?, exercise: Exercise?, name: String) {
        let nextOrder = ((session.sets ?? []).map(\.order).max() ?? -1) + 1
        let set = WorkoutSet(
            exercise: exercise,
            exerciseName: name,
            order: nextOrder,
            reps: previous?.reps,
            weightKg: previous?.weightKg,
            durationMinutes: previous?.durationMinutes,
            distanceKm: previous?.distanceKm,
            isCompleted: false
        )
        set.session = session
        modelContext.insert(set)
        try? modelContext.save()
    }

    private func completeSet(_ set: WorkoutSet) {
        set.isCompleted.toggle()
        try? modelContext.save()
        if set.isCompleted {
            restSecondsRemaining = set.restSeconds ?? 90
        }
    }

    private func saveSet(_ set: WorkoutSet) {
        try? modelContext.save()
    }

    private func deleteSet(_ set: WorkoutSet) {
        modelContext.delete(set)
        try? modelContext.save()
    }

    private func finishWorkout() {
        session.endedAt = Date()
        try? modelContext.save()
        onEnd()
    }
}
