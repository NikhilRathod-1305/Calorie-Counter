import Foundation
import SwiftData

/// A catalog entry describing a movement (e.g. "Bench Press", "Running") —
/// the exercise database used for search/discovery and as the template
/// referenced by routines and logged sets. Distinct from `WorkoutSet`, which
/// records an actual performed instance of one of these.
@Model
final class Exercise {
    var id: UUID
    var name: String
    var category: String // ExerciseCategory raw value
    var muscleGroups: [String] // MuscleGroup raw values
    var equipment: String // Equipment raw value
    var isCardio: Bool
    var instructions: String?
    var isCustom: Bool
    var createdAt: Date

    init(
        name: String,
        category: ExerciseCategory,
        muscleGroups: [MuscleGroup] = [],
        equipment: Equipment = .none,
        isCardio: Bool = false,
        instructions: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.category = category.rawValue
        self.muscleGroups = muscleGroups.map(\.rawValue)
        self.equipment = equipment.rawValue
        self.isCardio = isCardio
        self.instructions = instructions
        self.isCustom = isCustom
        self.createdAt = Date()
    }

    var categoryValue: ExerciseCategory {
        get { ExerciseCategory(rawValue: category) ?? .other }
        set { category = newValue.rawValue }
    }

    var equipmentValue: Equipment {
        get { Equipment(rawValue: equipment) ?? .none }
        set { equipment = newValue.rawValue }
    }

    var muscleGroupValues: [MuscleGroup] {
        muscleGroups.compactMap(MuscleGroup.init(rawValue:))
    }

    var emoji: String { isCardio ? "🏃" : categoryValue.emoji }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    case other = "Other"

    var emoji: String {
        switch self {
        case .chest: return "💪"
        case .back: return "🏋️"
        case .shoulders: return "🤸"
        case .arms: return "💪"
        case .legs: return "🦵"
        case .core: return "🔥"
        case .cardio: return "🏃"
        case .fullBody: return "⚡️"
        case .other: return "🏷️"
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Chest"
    case lats = "Lats"
    case upperBack = "Upper Back"
    case lowerBack = "Lower Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case abs = "Abs"
    case obliques = "Obliques"
    case fullBody = "Full Body"
}

enum Equipment: String, Codable, CaseIterable {
    case none = "Bodyweight"
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case kettlebell = "Kettlebell"
    case band = "Band"
    case other = "Other"
}
