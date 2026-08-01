import Foundation
import SwiftData

@Model
final class WaterLogEntry {
    var id: UUID
    var milliliters: Int
    var date: Date
    var drinkTypeRaw: String = DrinkType.water.rawValue

    init(milliliters: Int, date: Date = Date(), drinkType: DrinkType = .water) {
        self.id = UUID()
        self.milliliters = milliliters
        self.date = date
        self.drinkTypeRaw = drinkType.rawValue
    }

    var drinkType: DrinkType {
        get { DrinkType(rawValue: drinkTypeRaw) ?? .water }
        set { drinkTypeRaw = newValue.rawValue }
    }
}
