import Foundation
import SwiftData

/// A user-defined (or starter) workout template — an ordered list of
/// exercises with target sets/reps, used to start a `WorkoutSession` without
/// re-entering the same exercises each time. Deliberately data-driven rather
/// than hardcoded, so users can create/edit/delete their own routines.
@Model
final class WorkoutRoutine {
    var id: UUID
    var name: String
    var notes: String?
    var createdAt: Date
    var isStarter: Bool

    @Relationship(deleteRule: .cascade, inverse: \WorkoutRoutineExercise.routine)
    var exercises: [WorkoutRoutineExercise]?

    init(name: String, notes: String? = nil, isStarter: Bool = false) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
        self.isStarter = isStarter
        self.exercises = []
    }

    var orderedExercises: [WorkoutRoutineExercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }
}

/// One row within a `WorkoutRoutine` — a planned exercise with target
/// sets/reps (or duration for cardio). Not itself a performed set; when the
/// routine is started, each target set becomes a `WorkoutSet` to fill in.
@Model
final class WorkoutRoutineExercise {
    var id: UUID
    var routine: WorkoutRoutine?
    var exercise: Exercise?
    var exerciseName: String
    var order: Int
    var targetSets: Int
    var targetReps: Int?
    var targetWeightKg: Double?
    var targetDurationMinutes: Double?

    init(
        exercise: Exercise? = nil,
        exerciseName: String,
        order: Int = 0,
        targetSets: Int = 3,
        targetReps: Int? = nil,
        targetWeightKg: Double? = nil,
        targetDurationMinutes: Double? = nil
    ) {
        self.id = UUID()
        self.exercise = exercise
        self.exerciseName = exerciseName
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.targetDurationMinutes = targetDurationMinutes
    }

    var isCardio: Bool { exercise?.isCardio ?? (targetDurationMinutes != nil) }

    var targetLabel: String {
        if isCardio, let targetDurationMinutes {
            return "\(Int(targetDurationMinutes)) min"
        }
        if let targetReps {
            return "\(targetSets) × \(targetReps)"
        }
        return "\(targetSets) sets"
    }
}
