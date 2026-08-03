import SwiftUI
import SwiftData

@main
struct CalorieTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: FoodItem.self, MealEntry.self, UserProfile.self, WeightLogEntry.self, WaterLogEntry.self, ExerciseEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
 
        let context = modelContainer.mainContext
        FoodLibrarySeeder.seedIfNeeded(context: context)

        let profileDescriptor = FetchDescriptor<UserProfile>()
        if (try? context.fetchCount(profileDescriptor)) == 0 {
            let profile = UserProfile()
            profile.hasCompletedOnboarding = true
            context.insert(profile)
            try? context.save()
        }

        DebugDataSeeder.seedWeekIfNeeded(context: context)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
