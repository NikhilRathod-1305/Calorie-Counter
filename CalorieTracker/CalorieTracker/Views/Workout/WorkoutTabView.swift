import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutRoutine.createdAt) private var routines: [WorkoutRoutine]

    @State private var activeSession: WorkoutSession?
    @State private var showingRoutineBuilder = false
    @State private var editingRoutine: WorkoutRoutine?
    @State private var showingExerciseLibrary = false
    @State private var selectedHistorySession: WorkoutSession?

    private var inProgressSession: WorkoutSession? { sessions.first { $0.isActive } }
    private var completedSessions: [WorkoutSession] { sessions.filter { !$0.isActive } }
    private var savedRoutines: [WorkoutRoutine] { routines.filter { !$0.isStarter } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let inProgressSession {
                            resumeCard(inProgressSession)
                        }

                        quickStartSection
                        routinesSection

                        if !completedSessions.isEmpty {
                            historySection
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .background(Theme.groupedBackground.ignoresSafeArea())
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $activeSession) { session in
            ActiveWorkoutView(session: session, onEnd: { activeSession = nil })
        }
        .sheet(isPresented: $showingRoutineBuilder) {
            RoutineBuilderView(onClose: { showingRoutineBuilder = false })
        }
        .sheet(item: $editingRoutine) { routine in
            RoutineBuilderView(routine: routine, onClose: { editingRoutine = nil })
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            ExercisePickerView(mode: .browse, onClose: { showingExerciseLibrary = false }, onPick: { _ in })
        }
        .sheet(item: $selectedHistorySession) { session in
            WorkoutSessionDetailView(session: session, onClose: { selectedHistorySession = nil })
        }
    }

    // MARK: Resume in-progress

    private func resumeCard(_ session: WorkoutSession) -> some View {
        Button {
            activeSession = session
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.exercise)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout in progress")
                        .font(Theme.Font.text(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(session.name) · \(Int(session.durationMinutes)) min elapsed")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(14)
            .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium), tint: Theme.exercise.opacity(0.12))
        }
        .buttonStyle(.plain)
    }

    // MARK: Quick start

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start a workout")
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 10) {
                startTile(icon: "plus", label: "Empty Workout") {
                    startEmptyWorkout()
                }
                startTile(icon: "arrow.counterclockwise", label: "Repeat Last", disabled: completedSessions.isEmpty) {
                    if let last = completedSessions.first { repeatWorkout(last) }
                }
                startTile(icon: "magnifyingglass", label: "Browse\nExercises") {
                    showingExerciseLibrary = true
                }
            }
        }
    }

    private func startTile(icon: String, label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(disabled ? Theme.textFaint : Theme.accent)
                    .frame(width: 40, height: 40)
                Text(label)
                    .font(Theme.Font.text(11, weight: .medium))
                    .foregroundStyle(disabled ? Theme.textFaint : Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: Routines

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Routines")
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Button {
                    showingRoutineBuilder = true
                } label: {
                    Label("New", systemImage: "plus")
                        .font(Theme.Font.text(12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }

            if savedRoutines.isEmpty {
                Text("Create a routine to quickly start the same workout again.")
                    .font(Theme.Font.text(12))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            } else {
                VStack(spacing: 10) {
                    ForEach(savedRoutines) { routine in
                        routineRow(routine)
                    }
                }
            }
        }
    }

    private func routineRow(_ routine: WorkoutRoutine) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.name)
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(routine.orderedExercises.count) exercises")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button {
                editingRoutine = routine
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32, height: 32)
                    .glassCardAlt(Circle())
            }
            .buttonStyle(.plain)
            Button {
                startWorkout(from: routine)
            } label: {
                Text("Start")
                    .font(Theme.Font.text(12, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    // MARK: History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent workouts")
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 10) {
                ForEach(completedSessions.prefix(10)) { session in
                    SwipeToDeleteRow(
                        onTap: { selectedHistorySession = session },
                        onDelete: { deleteSession(session) }
                    ) {
                        historyRow(session)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                }
            }
        }
    }

    private func historyRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(session.startedAt.formatted(date: .abbreviated, time: .omitted)) · \(session.exerciseCount) exercises · \(Int(session.durationMinutes)) min")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textFaint)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    // MARK: Actions

    private func startEmptyWorkout() {
        let session = WorkoutSession(name: "Workout")
        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session
    }

    private func startWorkout(from routine: WorkoutRoutine) {
        let session = WorkoutSession(name: routine.name, sourceRoutineName: routine.name)
        modelContext.insert(session)
        for (index, planned) in routine.orderedExercises.enumerated() {
            for setIndex in 0..<max(1, planned.targetSets) {
                let set = WorkoutSet(
                    exercise: planned.exercise,
                    exerciseName: planned.exerciseName,
                    order: index * 100 + setIndex,
                    reps: planned.isCardio ? nil : planned.targetReps,
                    weightKg: planned.isCardio ? nil : planned.targetWeightKg,
                    durationMinutes: planned.isCardio ? planned.targetDurationMinutes : nil,
                    isCompleted: false
                )
                set.session = session
                modelContext.insert(set)
            }
        }
        try? modelContext.save()
        activeSession = session
    }

    private func repeatWorkout(_ previous: WorkoutSession) {
        let session = WorkoutSession(name: previous.name, sourceRoutineName: previous.sourceRoutineName)
        modelContext.insert(session)
        for (index, set) in previous.orderedSets.enumerated() {
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
            newSet.session = session
            modelContext.insert(newSet)
        }
        try? modelContext.save()
        activeSession = session
    }

    private func deleteSession(_ session: WorkoutSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
}
