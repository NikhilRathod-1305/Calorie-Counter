import Foundation
import SwiftData

/// One logged workout instance — either in progress (`endedAt == nil`) or
/// completed. Holds an ordered collection of `WorkoutSet`s, each referencing
/// an `Exercise`. Optionally created from a `WorkoutRoutine` template.
@Model
final class WorkoutSession {
    var id: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?
    var sourceRoutineName: String?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet]?

    init(
        name: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        sourceRoutineName: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.sourceRoutineName = sourceRoutineName
        self.notes = notes
        self.sets = []
    }

    var isActive: Bool { endedAt == nil }

    var durationMinutes: Double {
        let end = endedAt ?? Date()
        return end.timeIntervalSince(startedAt) / 60
    }

    var orderedSets: [WorkoutSet] {
        (sets ?? []).sorted { $0.order < $1.order }
    }

    /// Sets grouped by exercise, preserving first-appearance order — the
    /// shape an active-workout or history screen wants to render.
    var exerciseGroups: [(exercise: Exercise?, exerciseName: String, sets: [WorkoutSet])] {
        var order: [String] = []
        var groups: [String: [WorkoutSet]] = [:]
        for set in orderedSets {
            let key = set.exercise?.name ?? set.exerciseName
            if groups[key] == nil {
                groups[key] = []
                order.append(key)
            }
            groups[key]?.append(set)
        }
        return order.map { key in
            let sets = groups[key] ?? []
            return (exercise: sets.first?.exercise, exerciseName: key, sets: sets)
        }
    }

    var totalVolumeKg: Double {
        orderedSets.reduce(0) { $0 + $1.volumeKg }
    }

    var totalCaloriesBurned: Double {
        orderedSets.reduce(0) { $0 + ($1.caloriesBurned ?? 0) }
    }

    var exerciseCount: Int {
        Set(orderedSets.map { $0.exercise?.name ?? $0.exerciseName }).count
    }
}
