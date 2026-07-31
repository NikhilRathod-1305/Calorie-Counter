import Foundation
import SwiftData
import SwiftUI

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case light = "Light"
    case moderate = "Moderate"
    case active = "Active"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        }
    }
}

enum MacroPreset: String, Codable, CaseIterable, Identifiable {
    case balanced = "Balanced"
    case highProtein = "High-protein"
    case lowCarb = "Low-carb"

    var id: String { rawValue }

    var split: (protein: Double, carb: Double, fat: Double) {
        switch self {
        case .balanced: return (0.30, 0.40, 0.30)
        case .highProtein: return (0.40, 0.30, 0.30)
        case .lowCarb: return (0.35, 0.20, 0.45)
        }
    }
}

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case lose = "Lose weight"
    case maintain = "Maintain weight"
    case gain = "Gain weight"

    var id: String { rawValue }
}

enum Sex: String, Codable, CaseIterable, Identifiable {
    case female = "Female"
    case male = "Male"
    case other = "Other"

    var id: String { rawValue }
}

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Model
final class UserProfile {
    var id: UUID
    var heightCm: Double
    var age: Int
    var weightKg: Double
    var targetWeightKg: Double
    var activityLevelRaw: String
    var macroPresetRaw: String
    var goalTypeRaw: String
    var sexRaw: String
    var weeklyRateKg: Double
    var hasCompletedOnboarding: Bool
    var waterGoalMl: Int
    var weeklyExerciseGoalMinutes: Int
    var appearanceRaw: String
    var createdAt: Date

    init(
        heightCm: Double = 178,
        age: Int = 30,
        weightKg: Double = 80,
        targetWeightKg: Double = 75,
        activityLevel: ActivityLevel = .moderate,
        macroPreset: MacroPreset = .balanced,
        goalType: GoalType = .maintain,
        sex: Sex = .other,
        weeklyRateKg: Double = 0.5,
        hasCompletedOnboarding: Bool = false,
        waterGoalMl: Int = 2000,
        weeklyExerciseGoalMinutes: Int = 150,
        appearance: AppearanceMode = .system
    ) {
        self.id = UUID()
        self.heightCm = heightCm
        self.age = age
        self.weightKg = weightKg
        self.targetWeightKg = targetWeightKg
        self.activityLevelRaw = activityLevel.rawValue
        self.macroPresetRaw = macroPreset.rawValue
        self.goalTypeRaw = goalType.rawValue
        self.sexRaw = sex.rawValue
        self.weeklyRateKg = weeklyRateKg
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.waterGoalMl = waterGoalMl
        self.weeklyExerciseGoalMinutes = weeklyExerciseGoalMinutes
        self.appearanceRaw = appearance.rawValue
        self.createdAt = Date()
    }

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .moderate }
        set { activityLevelRaw = newValue.rawValue }
    }

    var macroPreset: MacroPreset {
        get { MacroPreset(rawValue: macroPresetRaw) ?? .balanced }
        set { macroPresetRaw = newValue.rawValue }
    }

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .maintain }
        set { goalTypeRaw = newValue.rawValue }
    }

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .other }
        set { sexRaw = newValue.rawValue }
    }

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
