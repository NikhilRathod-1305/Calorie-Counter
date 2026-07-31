import Foundation
import SwiftData

@Model
final class WeightLogEntry {
    var id: UUID
    var weightKg: Double
    var date: Date

    init(weightKg: Double, date: Date = Date()) {
        self.id = UUID()
        self.weightKg = weightKg
        self.date = date
    }
}
