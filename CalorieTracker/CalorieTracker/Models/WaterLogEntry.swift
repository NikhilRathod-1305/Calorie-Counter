import Foundation
import SwiftData

@Model
final class WaterLogEntry {
    var id: UUID
    var milliliters: Int
    var date: Date

    init(milliliters: Int, date: Date = Date()) {
        self.id = UUID()
        self.milliliters = milliliters
        self.date = date
    }
}
