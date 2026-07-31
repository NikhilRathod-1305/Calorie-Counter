import Foundation

struct DailyGoals {
    var calorieGoal: Int
    var proteinG: Int
    var carbG: Int
    var fatG: Int

    static let fiberTargetG = 28
    static let sugarLimitG = 50
    static let sodiumLimitMg = 2300
}

enum NutritionGoalCalculator {
    private static let kcalPerKgBodyFat = 7700.0
    private static let minimumCalorieGoal = 1200.0

    static func compute(profile: UserProfile) -> DailyGoals {
        let sexConstant: Double
        switch profile.sex {
        case .male: sexConstant = 5
        case .female: sexConstant = -161
        case .other: sexConstant = -78
        }
        let bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age) + sexConstant
        let tdee = bmr * profile.activityLevel.multiplier

        let dailyDelta = (profile.weeklyRateKg * kcalPerKgBodyFat) / 7
        var adjustment = 0.0
        switch profile.goalType {
        case .lose: adjustment = -dailyDelta
        case .gain: adjustment = dailyDelta
        case .maintain: adjustment = 0
        }

        let rawGoal = max(minimumCalorieGoal, tdee + adjustment)
        let calorieGoal = Int((rawGoal / 10).rounded()) * 10
        let split = profile.macroPreset.split

        return DailyGoals(
            calorieGoal: calorieGoal,
            proteinG: Int(((Double(calorieGoal) * split.protein) / 4).rounded()),
            carbG: Int(((Double(calorieGoal) * split.carb) / 4).rounded()),
            fatG: Int(((Double(calorieGoal) * split.fat) / 9).rounded())
        )
    }
}
