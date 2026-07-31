import Foundation
import SwiftData

@Model
final class ExerciseEntry {
    var id: UUID
    var name: String
    var caloriesBurned: Double
    var durationMinutes: Double?
    var timestamp: Date

    init(name: String, caloriesBurned: Double, durationMinutes: Double? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.caloriesBurned = caloriesBurned
        self.durationMinutes = durationMinutes
        self.timestamp = timestamp
    }
}
