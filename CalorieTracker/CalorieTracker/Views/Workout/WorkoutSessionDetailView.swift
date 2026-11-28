import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let session: WorkoutSession
    let onClose: () -> Void

    @State private var repeatedSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard

                    ForEach(session.exerciseGroups, id: \.exerciseName) { group in
                        exerciseCard(group)
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(16)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Repeat", action: repeatWorkout)
                }
            }
        }
        .fullScreenCover(item: $repeatedSession) { newSession in
            ActiveWorkoutView(session: newSession, onEnd: {
                repeatedSession = nil
                onClose()
            })
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            statColumn(label: "Duration", value: "\(Int(session.durationMinutes)) min")
            statColumn(label: "Exercises", value: "\(session.exerciseCount)")
            statColumn(label: "Volume", value: "\(Int(session.totalVolumeKg)) kg")
        }
        .padding(14)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Font.display(16))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func exerciseCard(_ group: (exercise: Exercise?, exerciseName: String, sets: [WorkoutSet])) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.exerciseName)
                .font(Theme.Font.text(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(14)

            Divider().overlay(Theme.hairline)

            ForEach(Array(group.sets.enumerated()), id: \.element.id) { index, set in
                HStack {
                    Text("Set \(index + 1)")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                    Text(set.summaryLabel)
                        .font(Theme.Font.text(13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                if set.id != group.sets.last?.id {
                    Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 14)
                }
            }
        }
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private func repeatWorkout() {
        let newSession = WorkoutSession(name: session.name, sourceRoutineName: session.sourceRoutineName)
        modelContext.insert(newSession)
        for (index, set) in session.orderedSets.enumerated() {
            let newSet = WorkoutSet(
                exercise: set.exercise,
                exerciseName: set.exerciseName,
                order: index,
                reps: set.reps,
                weightKg: set.weightKg,
                durationMinutes: set.durationMinutes,
                distanceKm: set.distanceKm,
                isCompleted: false
            )
            newSet.session = newSession
            modelContext.insert(newSet)
        }
        try? modelContext.save()
        repeatedSession = newSession
    }
}
