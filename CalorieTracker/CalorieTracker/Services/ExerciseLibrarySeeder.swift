import Foundation
import SwiftData

enum ExerciseLibrarySeeder {
    /// Inserts any starter exercises not already present (matched by name
    /// among non-custom entries), rather than gating on the table being
    /// empty — so newly added starter entries still reach existing users.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { !$0.isCustom })
        let existingNames = Set((try? context.fetch(descriptor))?.map(\.name) ?? [])

        let missing = starterExercises.filter { !existingNames.contains($0.name) }
        guard !missing.isEmpty else { return }

        for seed in missing {
            context.insert(seed.makeExercise())
        }
        try? context.save()
    }

    private struct Seed {
        let name: String
        let category: ExerciseCategory
        let muscleGroups: [MuscleGroup]
        let equipment: Equipment
        var isCardio: Bool = false

        func makeExercise() -> Exercise {
            Exercise(name: name, category: category, muscleGroups: muscleGroups, equipment: equipment, isCardio: isCardio)
        }
    }

    private static let starterExercises: [Seed] = [
        // Chest
        Seed(name: "Bench Press", category: .chest, muscleGroups: [.chest, .triceps, .shoulders], equipment: .barbell),
        Seed(name: "Incline Bench Press", category: .chest, muscleGroups: [.chest, .shoulders, .triceps], equipment: .barbell),
        Seed(name: "Dumbbell Bench Press", category: .chest, muscleGroups: [.chest, .triceps], equipment: .dumbbell),
        Seed(name: "Push-Up", category: .chest, muscleGroups: [.chest, .triceps, .abs], equipment: .none),
        Seed(name: "Chest Fly", category: .chest, muscleGroups: [.chest], equipment: .dumbbell),
        Seed(name: "Cable Crossover", category: .chest, muscleGroups: [.chest], equipment: .cable),
        Seed(name: "Dip", category: .chest, muscleGroups: [.chest, .triceps], equipment: .none),

        // Back
        Seed(name: "Deadlift", category: .back, muscleGroups: [.lowerBack, .hamstrings, .glutes], equipment: .barbell),
        Seed(name: "Pull-Up", category: .back, muscleGroups: [.lats, .biceps], equipment: .none),
        Seed(name: "Lat Pulldown", category: .back, muscleGroups: [.lats, .biceps], equipment: .cable),
        Seed(name: "Bent-Over Row", category: .back, muscleGroups: [.upperBack, .lats, .biceps], equipment: .barbell),
        Seed(name: "Seated Cable Row", category: .back, muscleGroups: [.upperBack, .lats], equipment: .cable),
        Seed(name: "Dumbbell Row", category: .back, muscleGroups: [.lats, .upperBack], equipment: .dumbbell),
        Seed(name: "T-Bar Row", category: .back, muscleGroups: [.upperBack, .lats], equipment: .machine),

        // Shoulders
        Seed(name: "Overhead Press", category: .shoulders, muscleGroups: [.shoulders, .triceps], equipment: .barbell),
        Seed(name: "Dumbbell Shoulder Press", category: .shoulders, muscleGroups: [.shoulders, .triceps], equipment: .dumbbell),
        Seed(name: "Lateral Raise", category: .shoulders, muscleGroups: [.shoulders], equipment: .dumbbell),
        Seed(name: "Front Raise", category: .shoulders, muscleGroups: [.shoulders], equipment: .dumbbell),
        Seed(name: "Face Pull", category: .shoulders, muscleGroups: [.shoulders, .upperBack], equipment: .cable),
        Seed(name: "Shrug", category: .shoulders, muscleGroups: [.shoulders], equipment: .barbell),

        // Arms
        Seed(name: "Barbell Curl", category: .arms, muscleGroups: [.biceps], equipment: .barbell),
        Seed(name: "Dumbbell Curl", category: .arms, muscleGroups: [.biceps], equipment: .dumbbell),
        Seed(name: "Hammer Curl", category: .arms, muscleGroups: [.biceps, .forearms], equipment: .dumbbell),
        Seed(name: "Triceps Pushdown", category: .arms, muscleGroups: [.triceps], equipment: .cable),
        Seed(name: "Skull Crusher", category: .arms, muscleGroups: [.triceps], equipment: .barbell),
        Seed(name: "Overhead Triceps Extension", category: .arms, muscleGroups: [.triceps], equipment: .dumbbell),

        // Legs
        Seed(name: "Squat", category: .legs, muscleGroups: [.quads, .glutes, .hamstrings], equipment: .barbell),
        Seed(name: "Leg Press", category: .legs, muscleGroups: [.quads, .glutes], equipment: .machine),
        Seed(name: "Romanian Deadlift", category: .legs, muscleGroups: [.hamstrings, .glutes, .lowerBack], equipment: .barbell),
        Seed(name: "Leg Extension", category: .legs, muscleGroups: [.quads], equipment: .machine),
        Seed(name: "Leg Curl", category: .legs, muscleGroups: [.hamstrings], equipment: .machine),
        Seed(name: "Walking Lunge", category: .legs, muscleGroups: [.quads, .glutes], equipment: .dumbbell),
        Seed(name: "Calf Raise", category: .legs, muscleGroups: [.calves], equipment: .machine),
        Seed(name: "Hip Thrust", category: .legs, muscleGroups: [.glutes, .hamstrings], equipment: .barbell),
        Seed(name: "Bulgarian Split Squat", category: .legs, muscleGroups: [.quads, .glutes], equipment: .dumbbell),

        // Core
        Seed(name: "Plank", category: .core, muscleGroups: [.abs], equipment: .none),
        Seed(name: "Crunch", category: .core, muscleGroups: [.abs], equipment: .none),
        Seed(name: "Hanging Leg Raise", category: .core, muscleGroups: [.abs], equipment: .none),
        Seed(name: "Russian Twist", category: .core, muscleGroups: [.obliques, .abs], equipment: .none),
        Seed(name: "Cable Woodchopper", category: .core, muscleGroups: [.obliques], equipment: .cable),
        Seed(name: "Ab Wheel Rollout", category: .core, muscleGroups: [.abs], equipment: .other),

        // Full body / other
        Seed(name: "Kettlebell Swing", category: .fullBody, muscleGroups: [.glutes, .hamstrings, .shoulders], equipment: .kettlebell),
        Seed(name: "Clean and Jerk", category: .fullBody, muscleGroups: [.fullBody], equipment: .barbell),
        Seed(name: "Burpee", category: .fullBody, muscleGroups: [.fullBody], equipment: .none),
        Seed(name: "Battle Ropes", category: .fullBody, muscleGroups: [.shoulders, .abs], equipment: .other),

        // Cardio
        Seed(name: "Running", category: .cardio, muscleGroups: [.quads, .hamstrings, .calves], equipment: .none, isCardio: true),
        Seed(name: "Walking", category: .cardio, muscleGroups: [.quads, .calves], equipment: .none, isCardio: true),
        Seed(name: "Cycling", category: .cardio, muscleGroups: [.quads, .hamstrings], equipment: .other, isCardio: true),
        Seed(name: "Rowing", category: .cardio, muscleGroups: [.lats, .quads, .hamstrings], equipment: .machine, isCardio: true),
        Seed(name: "Swimming", category: .cardio, muscleGroups: [.fullBody], equipment: .none, isCardio: true),
        Seed(name: "Elliptical", category: .cardio, muscleGroups: [.quads, .hamstrings], equipment: .machine, isCardio: true),
        Seed(name: "Jump Rope", category: .cardio, muscleGroups: [.calves], equipment: .other, isCardio: true),
        Seed(name: "Stair Climber", category: .cardio, muscleGroups: [.quads, .glutes], equipment: .machine, isCardio: true),
        Seed(name: "Hiking", category: .cardio, muscleGroups: [.quads, .hamstrings, .calves], equipment: .none, isCardio: true),
    ]
}
