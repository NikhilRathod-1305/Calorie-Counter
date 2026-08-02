import Foundation
import SwiftData

/// TEMPORARY: seeds a week of realistic meal/water/weight data on the current
/// calendar week so the Progress screen's charts have something to render while
/// visually verifying chart styling. Remove this file and its call site before shipping.
enum DebugDataSeeder {
    static func seedWeekIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<MealEntry>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let calorieValues: [Double] = [1950, 1700, 2050, 1900, 2000, 1850, 1750]
        let waterValues: [Int] = [1800, 2000, 1900, 2100, 2000, 2300, 1200]
        let weightValues: [Double] = [97.5, 97.2, 97.0, 96.8, 96.6, 96.4, 96.0]

        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -(6 - offset), to: today) else { continue }
            let cals = calorieValues[offset]

            let breakfast = MealEntry(
                customFoodName: "Breakfast",
                mealType: .breakfast,
                timestamp: cal.date(bySettingHour: 8, minute: 30, second: 0, of: day) ?? day,
                calories: cals * 0.3, protein: 20, carbs: 40, fat: 10
            )
            let lunch = MealEntry(
                customFoodName: "Lunch",
                mealType: .lunch,
                timestamp: cal.date(bySettingHour: 13, minute: 0, second: 0, of: day) ?? day,
                calories: cals * 0.4, protein: 35, carbs: 55, fat: 15
            )
            let dinner = MealEntry(
                customFoodName: "Dinner",
                mealType: .dinner,
                timestamp: cal.date(bySettingHour: 19, minute: 30, second: 0, of: day) ?? day,
                calories: cals * 0.3, protein: 25, carbs: 45, fat: 12
            )
            context.insert(breakfast)
            context.insert(lunch)
            context.insert(dinner)

            context.insert(WaterLogEntry(milliliters: waterValues[offset], date: cal.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? day))
            context.insert(WaterLogEntry(milliliters: 500, date: cal.date(bySettingHour: 16, minute: 0, second: 0, of: day) ?? day))

            context.insert(WeightLogEntry(weightKg: weightValues[offset], date: cal.date(bySettingHour: 7, minute: 0, second: 0, of: day) ?? day))
        }

        try? context.save()
    }
}
