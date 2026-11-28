import Foundation
import SwiftData

/// A single performed set within a `WorkoutSession` — covers both strength
/// (reps/weight/RPE) and cardio (duration/distance/pace/heart rate) via one
/// flexible model, since a session can mix both kinds of exercise.
@Model
final class WorkoutSet {
    var id: UUID
    var session: WorkoutSession?
    var exercise: Exercise?
    /// Denormalized name, kept even if `exercise` is nil (deleted from the
    /// library) or the set was logged via voice/manual entry without a
    /// matched catalog exercise.
    var exerciseName: String
    var order: Int
    var timestamp: Date

    // Strength fields
    var reps: Int?
    var weightKg: Double?
    var rpe: Double?

    // Cardio fields
    var durationMinutes: Double?
    var distanceKm: Double?
    var averageHeartRate: Int?
    var caloriesBurned: Double?

    var restSeconds: Int?
    var notes: String?
    var isCompleted: Bool
    var inputMethod: InputMethod

    init(
        exercise: Exercise? = nil,
        exerciseName: String,
        order: Int = 0,
        timestamp: Date = Date(),
        reps: Int? = nil,
        weightKg: Double? = nil,
        rpe: Double? = nil,
        durationMinutes: Double? = nil,
        distanceKm: Double? = nil,
        averageHeartRate: Int? = nil,
        caloriesBurned: Double? = nil,
        restSeconds: Int? = nil,
        notes: String? = nil,
        isCompleted: Bool = true,
        inputMethod: InputMethod = .manual
    ) {
        self.id = UUID()
        self.exercise = exercise
        self.exerciseName = exerciseName
        self.order = order
        self.timestamp = timestamp
        self.reps = reps
        self.weightKg = weightKg
        self.rpe = rpe
        self.durationMinutes = durationMinutes
        self.distanceKm = distanceKm
        self.averageHeartRate = averageHeartRate
        self.caloriesBurned = caloriesBurned
        self.restSeconds = restSeconds
        self.notes = notes
        self.isCompleted = isCompleted
        self.inputMethod = inputMethod
    }

    var isCardioSet: Bool { exercise?.isCardio ?? (durationMinutes != nil && reps == nil) }

    var volumeKg: Double {
        guard let reps, let weightKg else { return 0 }
        return Double(reps) * weightKg
    }

    var paceMinPerKm: Double? {
        guard let durationMinutes, let distanceKm, distanceKm > 0 else { return nil }
        return durationMinutes / distanceKm
    }

    var summaryLabel: String {
        if isCardioSet {
            var parts: [String] = []
            if let durationMinutes { parts.append("\(Int(durationMinutes)) min") }
            if let distanceKm { parts.append(String(format: "%.2f km", distanceKm)) }
            return parts.joined(separator: " · ")
        } else {
            var parts: [String] = []
            if let weightKg { parts.append(String(format: "%.1f kg", weightKg)) }
            if let reps { parts.append("\(reps) reps") }
            return parts.joined(separator: " × ")
        }
    }
}
