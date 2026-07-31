import Foundation
import SwiftData

enum FoodLibrarySeeder {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<FoodItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for seed in starterFoods {
            context.insert(seed.makeFoodItem())
        }
        try? context.save()
    }

    private struct Seed {
        let name: String
        let serving: String
        let servingSize: Double
        let servingUnit: String
        let cals: Double, protein: Double, carbs: Double, fat: Double
        let fiber: Double, sugar: Double, sodium: Double
        let category: FoodCategory

        func makeFoodItem() -> FoodItem {
            FoodItem(
                name: name, calories: cals, protein: protein, carbs: carbs, fat: fat,
                fiber: fiber, sugar: sugar, sodium: sodium,
                servingSize: servingSize, servingUnit: servingUnit,
                category: category, isCustom: false, emoji: category.emoji
            )
        }
    }

    private static let starterFoods: [Seed] = [
        Seed(name: "Grilled Chicken Breast", serving: "150g", servingSize: 150, servingUnit: "g", cals: 248, protein: 46, carbs: 0, fat: 5, fiber: 0, sugar: 0, sodium: 105, category: .protein),
        Seed(name: "Brown Rice", serving: "1 cup", servingSize: 195, servingUnit: "g", cals: 216, protein: 5, carbs: 45, fat: 1.8, fiber: 3.5, sugar: 0.7, sodium: 10, category: .grains),
        Seed(name: "Avocado", serving: "half", servingSize: 100, servingUnit: "g", cals: 120, protein: 1.5, carbs: 6, fat: 11, fiber: 5, sugar: 0.5, sodium: 5, category: .fruits),
        Seed(name: "Greek Yogurt", serving: "170g", servingSize: 170, servingUnit: "g", cals: 100, protein: 17, carbs: 6, fat: 0.5, fiber: 0, sugar: 6, sodium: 60, category: .dairy),
        Seed(name: "Banana", serving: "1 medium", servingSize: 118, servingUnit: "g", cals: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3.1, sugar: 14, sodium: 1, category: .fruits),
        Seed(name: "Almonds", serving: "28g", servingSize: 28, servingUnit: "g", cals: 164, protein: 6, carbs: 6, fat: 14, fiber: 3.5, sugar: 1.2, sodium: 0, category: .snacks),
        Seed(name: "Salmon Fillet", serving: "150g", servingSize: 150, servingUnit: "g", cals: 280, protein: 39, carbs: 0, fat: 13, fiber: 0, sugar: 0, sodium: 75, category: .protein),
        Seed(name: "Broccoli", serving: "1 cup", servingSize: 91, servingUnit: "g", cals: 55, protein: 3.7, carbs: 11, fat: 0.6, fiber: 5, sugar: 2, sodium: 33, category: .vegetables),
        Seed(name: "Oatmeal", serving: "1 cup cooked", servingSize: 234, servingUnit: "g", cals: 166, protein: 6, carbs: 28, fat: 3.5, fiber: 4, sugar: 1, sodium: 9, category: .grains),
        Seed(name: "Eggs", serving: "2 large", servingSize: 100, servingUnit: "g", cals: 143, protein: 12.6, carbs: 1, fat: 9.5, fiber: 0, sugar: 0.4, sodium: 140, category: .protein),
        Seed(name: "Sweet Potato", serving: "1 medium", servingSize: 130, servingUnit: "g", cals: 112, protein: 2, carbs: 26, fat: 0.1, fiber: 4, sugar: 5.4, sodium: 72, category: .vegetables),
        Seed(name: "Peanut Butter", serving: "2 tbsp", servingSize: 32, servingUnit: "g", cals: 188, protein: 8, carbs: 6, fat: 16, fiber: 2, sugar: 3, sodium: 150, category: .snacks),
        Seed(name: "Whole Milk", serving: "1 cup", servingSize: 244, servingUnit: "ml", cals: 149, protein: 8, carbs: 12, fat: 8, fiber: 0, sugar: 12, sodium: 105, category: .dairy),
        Seed(name: "Apple", serving: "1 medium", servingSize: 182, servingUnit: "g", cals: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4.4, sugar: 19, sodium: 2, category: .fruits),
        Seed(name: "Whole Wheat Bread", serving: "1 slice", servingSize: 32, servingUnit: "g", cals: 82, protein: 4, carbs: 14, fat: 1.1, fiber: 2, sugar: 1.5, sodium: 144, category: .grains),
        Seed(name: "Cheddar Cheese", serving: "28g", servingSize: 28, servingUnit: "g", cals: 113, protein: 7, carbs: 0.4, fat: 9.3, fiber: 0, sugar: 0.1, sodium: 174, category: .dairy),
        Seed(name: "Black Beans", serving: "1 cup", servingSize: 172, servingUnit: "g", cals: 227, protein: 15, carbs: 41, fat: 0.9, fiber: 15, sugar: 0.6, sodium: 2, category: .protein),
        Seed(name: "Spinach", serving: "1 cup", servingSize: 30, servingUnit: "g", cals: 7, protein: 0.9, carbs: 1.1, fat: 0.1, fiber: 0.7, sugar: 0.1, sodium: 24, category: .vegetables),
        Seed(name: "Quinoa", serving: "1 cup cooked", servingSize: 185, servingUnit: "g", cals: 222, protein: 8, carbs: 39, fat: 3.6, fiber: 5.2, sugar: 1.6, sodium: 13, category: .grains),
        Seed(name: "Dark Chocolate", serving: "28g", servingSize: 28, servingUnit: "g", cals: 155, protein: 2, carbs: 13, fat: 11, fiber: 3, sugar: 7, sodium: 6, category: .desserts),
        Seed(name: "Black Coffee", serving: "1 cup", servingSize: 240, servingUnit: "ml", cals: 2, protein: 0.3, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 5, category: .beverages),
        Seed(name: "Cheeseburger", serving: "1 burger", servingSize: 200, servingUnit: "g", cals: 550, protein: 28, carbs: 40, fat: 30, fiber: 2, sugar: 8, sodium: 980, category: .fastFood),
    ]
}
