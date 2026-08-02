import Foundation
import SwiftData

enum FoodLibrarySeeder {
    /// Names of the seeded Indian dishes, so other views (e.g. the Indian tab in
    /// FoodBrowseView) can filter for them without duplicating the list.
    static let indianDishNames: Set<String> = Set(starterFoods.filter(\.isIndian).map(\.name))

    /// Inserts any starter foods not already present (matched by name among
    /// non-custom items), rather than gating on the table being empty — so
    /// newly added starter entries (e.g. a later batch of Indian dishes) still
    /// reach users who installed the app before those entries existed.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<FoodItem>(predicate: #Predicate { !$0.isCustom })
        let existingNames = Set((try? context.fetch(descriptor))?.map(\.name) ?? [])

        let missing = starterFoods.filter { !existingNames.contains($0.name) }
        guard !missing.isEmpty else { return }

        for seed in missing {
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
        var emoji: String? = nil
        var isIndian: Bool = false

        func makeFoodItem() -> FoodItem {
            FoodItem(
                name: name, calories: cals, protein: protein, carbs: carbs, fat: fat,
                fiber: fiber, sugar: sugar, sodium: sodium,
                servingSize: servingSize, servingUnit: servingUnit,
                category: category, isCustom: false, emoji: emoji ?? category.emoji
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

        // MARK: Indian breads
        Seed(name: "Roti", serving: "1 piece", servingSize: 40, servingUnit: "g", cals: 104, protein: 3, carbs: 20, fat: 1.2, fiber: 2.5, sugar: 0.5, sodium: 100, category: .grains, emoji: "🫓", isIndian: true),
        Seed(name: "Chapati", serving: "1 piece", servingSize: 40, servingUnit: "g", cals: 104, protein: 3, carbs: 20, fat: 1.2, fiber: 2.5, sugar: 0.5, sodium: 100, category: .grains, emoji: "🫓", isIndian: true),
        Seed(name: "Naan", serving: "1 piece", servingSize: 90, servingUnit: "g", cals: 262, protein: 8.7, carbs: 45, fat: 5.1, fiber: 2, sugar: 3, sodium: 418, category: .grains, emoji: "🫓", isIndian: true),
        Seed(name: "Paratha", serving: "1 piece", servingSize: 70, servingUnit: "g", cals: 260, protein: 5, carbs: 35, fat: 11, fiber: 3, sugar: 1, sodium: 250, category: .grains, emoji: "🫓", isIndian: true),
        Seed(name: "Aloo Paratha", serving: "1 piece", servingSize: 120, servingUnit: "g", cals: 330, protein: 7, carbs: 45, fat: 14, fiber: 4, sugar: 2, sodium: 400, category: .grains, emoji: "🥔", isIndian: true),
        Seed(name: "Puri", serving: "1 piece", servingSize: 30, servingUnit: "g", cals: 101, protein: 1.8, carbs: 11, fat: 5.6, fiber: 0.8, sugar: 0.2, sodium: 50, category: .grains, emoji: "🫓", isIndian: true),

        // MARK: Rice dishes
        Seed(name: "Chicken Biryani", serving: "1 plate", servingSize: 350, servingUnit: "g", cals: 630, protein: 30, carbs: 70, fat: 24, fiber: 3, sugar: 4, sodium: 950, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Veg Biryani", serving: "1 plate", servingSize: 300, servingUnit: "g", cals: 450, protein: 9, carbs: 68, fat: 16, fiber: 5, sugar: 5, sodium: 780, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Jeera Rice", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 280, protein: 5, carbs: 52, fat: 6, fiber: 1.5, sugar: 0.3, sodium: 300, category: .grains, emoji: "🍚", isIndian: true),
        Seed(name: "Curd Rice", serving: "1 cup", servingSize: 220, servingUnit: "g", cals: 250, protein: 7, carbs: 40, fat: 6, fiber: 1, sugar: 4, sodium: 200, category: .grains, emoji: "🍚", isIndian: true),
        Seed(name: "Pulao", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 320, protein: 6, carbs: 55, fat: 8, fiber: 2, sugar: 2, sodium: 400, category: .grains, emoji: "🍛", isIndian: true),

        // MARK: Curries & gravies
        Seed(name: "Chicken Curry", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 320, protein: 28, carbs: 8, fat: 20, fiber: 2, sugar: 3, sodium: 620, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Butter Chicken", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 490, protein: 27, carbs: 12, fat: 36, fiber: 1.5, sugar: 6, sodium: 780, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Paneer Butter Masala", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 450, protein: 15, carbs: 15, fat: 36, fiber: 2, sugar: 8, sodium: 700, category: .fastFood, emoji: "🧀", isIndian: true),
        Seed(name: "Paneer Tikka Masala", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 420, protein: 17, carbs: 14, fat: 32, fiber: 2.5, sugar: 6, sodium: 680, category: .fastFood, emoji: "🧀", isIndian: true),
        Seed(name: "Palak Paneer", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 320, protein: 14, carbs: 10, fat: 25, fiber: 3, sugar: 3, sodium: 550, category: .vegetables, emoji: "🥬", isIndian: true),
        Seed(name: "Chana Masala", serving: "1 cup", servingSize: 240, servingUnit: "g", cals: 280, protein: 12, carbs: 40, fat: 8, fiber: 10, sugar: 6, sodium: 620, category: .protein, emoji: "🍛", isIndian: true),
        Seed(name: "Rajma", serving: "1 cup", servingSize: 240, servingUnit: "g", cals: 270, protein: 13, carbs: 42, fat: 5, fiber: 12, sugar: 4, sodium: 580, category: .protein, emoji: "🍛", isIndian: true),
        Seed(name: "Mutton Curry", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 380, protein: 26, carbs: 8, fat: 27, fiber: 2, sugar: 2, sodium: 650, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Fish Curry", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 290, protein: 24, carbs: 8, fat: 18, fiber: 1.5, sugar: 3, sodium: 600, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Egg Curry", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 300, protein: 15, carbs: 10, fat: 22, fiber: 2, sugar: 4, sodium: 580, category: .protein, emoji: "🍛", isIndian: true),
        Seed(name: "Dal Tadka", serving: "1 cup", servingSize: 240, servingUnit: "g", cals: 210, protein: 10, carbs: 30, fat: 6, fiber: 8, sugar: 2, sodium: 480, category: .protein, emoji: "🍲", isIndian: true),
        Seed(name: "Dal Makhani", serving: "1 cup", servingSize: 240, servingUnit: "g", cals: 330, protein: 12, carbs: 32, fat: 18, fiber: 9, sugar: 3, sodium: 620, category: .protein, emoji: "🍲", isIndian: true),
        Seed(name: "Sambar", serving: "1 cup", servingSize: 240, servingUnit: "g", cals: 160, protein: 7, carbs: 24, fat: 4, fiber: 6, sugar: 4, sodium: 500, category: .protein, emoji: "🍲", isIndian: true),
        Seed(name: "Bhindi Masala", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 180, protein: 4, carbs: 16, fat: 12, fiber: 5, sugar: 3, sodium: 380, category: .vegetables, emoji: "🥘", isIndian: true),
        Seed(name: "Aloo Gobi", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 190, protein: 4, carbs: 22, fat: 10, fiber: 4, sugar: 3, sodium: 400, category: .vegetables, emoji: "🥘", isIndian: true),
        Seed(name: "Baingan Bharta", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 170, protein: 3, carbs: 16, fat: 11, fiber: 5, sugar: 4, sodium: 380, category: .vegetables, emoji: "🍆", isIndian: true),
        Seed(name: "Kadai Paneer", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 400, protein: 16, carbs: 12, fat: 32, fiber: 2.5, sugar: 5, sodium: 650, category: .fastFood, emoji: "🧀", isIndian: true),

        // MARK: South Indian
        Seed(name: "Idli", serving: "2 pieces", servingSize: 100, servingUnit: "g", cals: 78, protein: 2.5, carbs: 16, fat: 0.3, fiber: 0.8, sugar: 0.5, sodium: 160, category: .grains, emoji: "🍘", isIndian: true),
        Seed(name: "Masala Dosa", serving: "1 piece", servingSize: 200, servingUnit: "g", cals: 380, protein: 8, carbs: 55, fat: 14, fiber: 3, sugar: 3, sodium: 620, category: .grains, emoji: "🥞", isIndian: true),
        Seed(name: "Plain Dosa", serving: "1 piece", servingSize: 130, servingUnit: "g", cals: 168, protein: 4, carbs: 30, fat: 3.7, fiber: 1, sugar: 0.5, sodium: 380, category: .grains, emoji: "🥞", isIndian: true),
        Seed(name: "Uttapam", serving: "1 piece", servingSize: 150, servingUnit: "g", cals: 220, protein: 5, carbs: 34, fat: 7, fiber: 2, sugar: 2, sodium: 420, category: .grains, emoji: "🥞", isIndian: true),
        Seed(name: "Vada", serving: "2 pieces", servingSize: 100, servingUnit: "g", cals: 230, protein: 6, carbs: 24, fat: 12, fiber: 3, sugar: 1, sodium: 400, category: .snacks, emoji: "🍩", isIndian: true),
        Seed(name: "Upma", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 250, protein: 6, carbs: 38, fat: 8, fiber: 3, sugar: 2, sodium: 450, category: .grains, emoji: "🍲", isIndian: true),
        Seed(name: "Pongal", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 280, protein: 7, carbs: 42, fat: 9, fiber: 2, sugar: 1, sodium: 400, category: .grains, emoji: "🍲", isIndian: true),

        // MARK: Snacks & street food
        Seed(name: "Samosa", serving: "1 piece", servingSize: 60, servingUnit: "g", cals: 180, protein: 3.5, carbs: 20, fat: 10, fiber: 2, sugar: 1, sodium: 300, category: .snacks, emoji: "🥟", isIndian: true),
        Seed(name: "Pakora", serving: "5 pieces", servingSize: 80, servingUnit: "g", cals: 220, protein: 5, carbs: 20, fat: 14, fiber: 2, sugar: 1, sodium: 350, category: .snacks, emoji: "🍤", isIndian: true),
        Seed(name: "Pani Puri", serving: "6 pieces", servingSize: 120, servingUnit: "g", cals: 200, protein: 4, carbs: 32, fat: 6, fiber: 2, sugar: 4, sodium: 480, category: .snacks, emoji: "🥙", isIndian: true),
        Seed(name: "Bhel Puri", serving: "1 cup", servingSize: 150, servingUnit: "g", cals: 220, protein: 5, carbs: 36, fat: 7, fiber: 3, sugar: 6, sodium: 520, category: .snacks, emoji: "🥙", isIndian: true),
        Seed(name: "Vada Pav", serving: "1 piece", servingSize: 140, servingUnit: "g", cals: 330, protein: 7, carbs: 42, fat: 15, fiber: 3, sugar: 3, sodium: 550, category: .fastFood, emoji: "🍔", isIndian: true),
        Seed(name: "Pav Bhaji", serving: "1 plate", servingSize: 300, servingUnit: "g", cals: 450, protein: 9, carbs: 55, fat: 20, fiber: 6, sugar: 8, sodium: 900, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Chole Bhature", serving: "1 plate", servingSize: 350, servingUnit: "g", cals: 620, protein: 14, carbs: 75, fat: 28, fiber: 10, sugar: 6, sodium: 850, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Dhokla", serving: "4 pieces", servingSize: 100, servingUnit: "g", cals: 160, protein: 6, carbs: 24, fat: 4, fiber: 2, sugar: 3, sodium: 380, category: .snacks, emoji: "🍰", isIndian: true),
        Seed(name: "Momos", serving: "6 pieces", servingSize: 150, servingUnit: "g", cals: 260, protein: 9, carbs: 38, fat: 7, fiber: 2, sugar: 1, sodium: 450, category: .snacks, emoji: "🥟", isIndian: true),
        Seed(name: "Kachori", serving: "1 piece", servingSize: 70, servingUnit: "g", cals: 220, protein: 4, carbs: 24, fat: 12, fiber: 2, sugar: 1, sodium: 320, category: .snacks, emoji: "🥟", isIndian: true),

        // MARK: Tandoori & grilled
        Seed(name: "Tandoori Chicken", serving: "2 pieces", servingSize: 200, servingUnit: "g", cals: 340, protein: 42, carbs: 4, fat: 17, fiber: 0.5, sugar: 2, sodium: 700, category: .protein, emoji: "🍗", isIndian: true),
        Seed(name: "Chicken Tikka", serving: "5 pieces", servingSize: 150, servingUnit: "g", cals: 280, protein: 34, carbs: 4, fat: 14, fiber: 0.5, sugar: 2, sodium: 620, category: .protein, emoji: "🍗", isIndian: true),
        Seed(name: "Seekh Kebab", serving: "3 pieces", servingSize: 150, servingUnit: "g", cals: 320, protein: 26, carbs: 4, fat: 22, fiber: 0.5, sugar: 1, sodium: 580, category: .protein, emoji: "🍢", isIndian: true),
        Seed(name: "Paneer Tikka", serving: "5 pieces", servingSize: 150, servingUnit: "g", cals: 300, protein: 15, carbs: 8, fat: 22, fiber: 1.5, sugar: 3, sodium: 480, category: .protein, emoji: "🧀", isIndian: true),

        // MARK: Dairy-based & desserts
        Seed(name: "Lassi", serving: "1 glass", servingSize: 250, servingUnit: "ml", cals: 180, protein: 6, carbs: 24, fat: 6, fiber: 0, sugar: 22, sodium: 90, category: .beverages, emoji: "🥤", isIndian: true),
        Seed(name: "Masala Chai", serving: "1 cup", servingSize: 180, servingUnit: "ml", cals: 90, protein: 2.5, carbs: 12, fat: 3.5, fiber: 0, sugar: 10, sodium: 40, category: .beverages, emoji: "🍵", isIndian: true),
        Seed(name: "Gulab Jamun", serving: "2 pieces", servingSize: 80, servingUnit: "g", cals: 300, protein: 4, carbs: 40, fat: 14, fiber: 0.5, sugar: 36, sodium: 60, category: .desserts, emoji: "🍮", isIndian: true),
        Seed(name: "Rasgulla", serving: "2 pieces", servingSize: 80, servingUnit: "g", cals: 186, protein: 4, carbs: 34, fat: 4, fiber: 0, sugar: 30, sodium: 40, category: .desserts, emoji: "🍡", isIndian: true),
        Seed(name: "Jalebi", serving: "3 pieces", servingSize: 60, servingUnit: "g", cals: 250, protein: 2, carbs: 40, fat: 10, fiber: 0.2, sugar: 36, sodium: 30, category: .desserts, emoji: "🍥", isIndian: true),
        Seed(name: "Kheer", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 280, protein: 7, carbs: 42, fat: 9, fiber: 0.5, sugar: 32, sodium: 80, category: .desserts, emoji: "🍮", isIndian: true),
        Seed(name: "Gajar Halwa", serving: "1 cup", servingSize: 150, servingUnit: "g", cals: 320, protein: 5, carbs: 38, fat: 17, fiber: 3, sugar: 30, sodium: 60, category: .desserts, emoji: "🥕", isIndian: true),
    ]
}
