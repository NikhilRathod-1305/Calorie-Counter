import Foundation
import SwiftData

enum FoodLibrarySeeder {
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
        var brand: String? = nil

        func makeFoodItem() -> FoodItem {
            FoodItem(
                name: name, brand: brand, calories: cals, protein: protein, carbs: carbs, fat: fat,
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

        // MARK: More Indian regional dishes
        Seed(name: "Poha", serving: "1 cup", servingSize: 180, servingUnit: "g", cals: 250, protein: 5, carbs: 42, fat: 7, fiber: 3, sugar: 4, sodium: 380, category: .grains, emoji: "🍚", isIndian: true),
        Seed(name: "Misal Pav", serving: "1 plate", servingSize: 300, servingUnit: "g", cals: 420, protein: 14, carbs: 48, fat: 18, fiber: 9, sugar: 5, sodium: 780, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Thepla", serving: "2 pieces", servingSize: 80, servingUnit: "g", cals: 220, protein: 5, carbs: 30, fat: 9, fiber: 3, sugar: 1, sodium: 300, category: .grains, emoji: "🫓", isIndian: true),
        Seed(name: "Undhiyu", serving: "1 cup", servingSize: 220, servingUnit: "g", cals: 260, protein: 6, carbs: 26, fat: 15, fiber: 7, sugar: 6, sodium: 420, category: .vegetables, emoji: "🥘", isIndian: true),
        Seed(name: "Khichdi", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 240, protein: 9, carbs: 40, fat: 5, fiber: 5, sugar: 1, sodium: 380, category: .grains, emoji: "🍲", isIndian: true),
        Seed(name: "Litti Chokha", serving: "2 pieces", servingSize: 200, servingUnit: "g", cals: 380, protein: 10, carbs: 48, fat: 16, fiber: 6, sugar: 2, sodium: 520, category: .fastFood, emoji: "🍘", isIndian: true),
        Seed(name: "Macher Jhol", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 260, protein: 24, carbs: 8, fat: 15, fiber: 1.5, sugar: 2, sodium: 580, category: .fastFood, emoji: "🐟", isIndian: true),
        Seed(name: "Shorshe Ilish", serving: "1 piece", servingSize: 180, servingUnit: "g", cals: 320, protein: 22, carbs: 4, fat: 24, fiber: 1, sugar: 1, sodium: 540, category: .fastFood, emoji: "🐟", isIndian: true),
        Seed(name: "Aloo Posto", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 260, protein: 4, carbs: 24, fat: 17, fiber: 3, sugar: 2, sodium: 380, category: .vegetables, emoji: "🥘", isIndian: true),
        Seed(name: "Rasam", serving: "1 cup", servingSize: 240, servingUnit: "g", cals: 90, protein: 3, carbs: 14, fat: 2.5, fiber: 2, sugar: 3, sodium: 480, category: .protein, emoji: "🍲", isIndian: true),
        Seed(name: "Bisi Bele Bath", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 300, protein: 8, carbs: 48, fat: 8, fiber: 4, sugar: 3, sodium: 550, category: .grains, emoji: "🍚", isIndian: true),
        Seed(name: "Appam", serving: "2 pieces", servingSize: 120, servingUnit: "g", cals: 210, protein: 4, carbs: 40, fat: 3.5, fiber: 1, sugar: 2, sodium: 220, category: .grains, emoji: "🥞", isIndian: true),
        Seed(name: "Puttu", serving: "1 cup", servingSize: 150, servingUnit: "g", cals: 240, protein: 5, carbs: 48, fat: 3, fiber: 3, sugar: 1, sodium: 150, category: .grains, emoji: "🍚", isIndian: true),
        Seed(name: "Kerala Fish Curry", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 280, protein: 22, carbs: 8, fat: 18, fiber: 2, sugar: 3, sodium: 560, category: .fastFood, emoji: "🐟", isIndian: true),
        Seed(name: "Malai Kofta", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 460, protein: 11, carbs: 30, fat: 34, fiber: 3, sugar: 8, sodium: 700, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Shahi Paneer", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 430, protein: 15, carbs: 16, fat: 34, fiber: 2, sugar: 7, sodium: 650, category: .fastFood, emoji: "🧀", isIndian: true),
        Seed(name: "Matar Paneer", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 350, protein: 15, carbs: 18, fat: 24, fiber: 4, sugar: 6, sodium: 600, category: .fastFood, emoji: "🧀", isIndian: true),
        Seed(name: "Kadhi Pakora", serving: "1 cup", servingSize: 250, servingUnit: "g", cals: 260, protein: 8, carbs: 22, fat: 16, fiber: 2, sugar: 6, sodium: 580, category: .protein, emoji: "🍲", isIndian: true),
        Seed(name: "Malabar Paratha", serving: "1 piece", servingSize: 80, servingUnit: "g", cals: 280, protein: 5, carbs: 34, fat: 14, fiber: 1.5, sugar: 1, sodium: 300, category: .grains, emoji: "🫓", isIndian: true),
        Seed(name: "Egg Bhurji", serving: "1 cup", servingSize: 150, servingUnit: "g", cals: 260, protein: 14, carbs: 5, fat: 20, fiber: 1, sugar: 2, sodium: 420, category: .protein, emoji: "🍳", isIndian: true),
        Seed(name: "Keema", serving: "1 cup", servingSize: 220, servingUnit: "g", cals: 380, protein: 26, carbs: 8, fat: 27, fiber: 1.5, sugar: 3, sodium: 620, category: .fastFood, emoji: "🍛", isIndian: true),
        Seed(name: "Chicken 65", serving: "8 pieces", servingSize: 150, servingUnit: "g", cals: 340, protein: 26, carbs: 12, fat: 21, fiber: 1, sugar: 3, sodium: 640, category: .snacks, emoji: "🍗", isIndian: true),
        Seed(name: "Gobi Manchurian", serving: "1 cup", servingSize: 180, servingUnit: "g", cals: 260, protein: 6, carbs: 30, fat: 13, fiber: 3, sugar: 8, sodium: 620, category: .snacks, emoji: "🥦", isIndian: true),
        Seed(name: "Paneer Bhurji", serving: "1 cup", servingSize: 180, servingUnit: "g", cals: 320, protein: 17, carbs: 8, fat: 24, fiber: 1.5, sugar: 3, sodium: 460, category: .protein, emoji: "🧀", isIndian: true),
        Seed(name: "Rava Kesari", serving: "1 cup", servingSize: 150, servingUnit: "g", cals: 300, protein: 4, carbs: 42, fat: 13, fiber: 0.5, sugar: 26, sodium: 40, category: .desserts, emoji: "🍮", isIndian: true),
        Seed(name: "Mysore Pak", serving: "2 pieces", servingSize: 60, servingUnit: "g", cals: 280, protein: 3, carbs: 30, fat: 17, fiber: 0.3, sugar: 24, sodium: 20, category: .desserts, emoji: "🟨", isIndian: true),
        Seed(name: "Modak", serving: "2 pieces", servingSize: 80, servingUnit: "g", cals: 220, protein: 3, carbs: 34, fat: 8, fiber: 1, sugar: 20, sodium: 30, category: .desserts, emoji: "🍡", isIndian: true),
        Seed(name: "Sooji Halwa", serving: "1 cup", servingSize: 150, servingUnit: "g", cals: 290, protein: 4, carbs: 40, fat: 13, fiber: 0.5, sugar: 24, sodium: 40, category: .desserts, emoji: "🍮", isIndian: true),
        Seed(name: "Kulfi", serving: "1 piece", servingSize: 80, servingUnit: "g", cals: 180, protein: 4, carbs: 20, fat: 9, fiber: 0, sugar: 18, sodium: 60, category: .desserts, emoji: "🍦", isIndian: true),
        Seed(name: "Nimbu Pani", serving: "1 glass", servingSize: 250, servingUnit: "ml", cals: 60, protein: 0.2, carbs: 15, fat: 0, fiber: 0, sugar: 14, sodium: 100, category: .beverages, emoji: "🍋", isIndian: true),
        Seed(name: "Buttermilk", serving: "1 glass", servingSize: 250, servingUnit: "ml", cals: 40, protein: 3, carbs: 4, fat: 1, fiber: 0, sugar: 4, sodium: 200, category: .beverages, emoji: "🥛", isIndian: true),
        Seed(name: "Filter Coffee", serving: "1 cup", servingSize: 150, servingUnit: "ml", cals: 60, protein: 2, carbs: 8, fat: 2, fiber: 0, sugar: 6, sodium: 30, category: .beverages, emoji: "☕", isIndian: true),

        // MARK: Global staples & common brands
        Seed(name: "White Rice", serving: "1 cup cooked", servingSize: 158, servingUnit: "g", cals: 205, protein: 4.3, carbs: 45, fat: 0.4, fiber: 0.6, sugar: 0.1, sodium: 2, category: .grains),
        Seed(name: "Pasta", serving: "1 cup cooked", servingSize: 140, servingUnit: "g", cals: 220, protein: 8, carbs: 43, fat: 1.3, fiber: 2.5, sugar: 0.8, sodium: 1, category: .grains, emoji: "🍝"),
        Seed(name: "Turkey Breast", serving: "150g", servingSize: 150, servingUnit: "g", cals: 195, protein: 42, carbs: 0, fat: 1.5, fiber: 0, sugar: 0, sodium: 90, category: .protein, emoji: "🦃"),
        Seed(name: "Tofu", serving: "100g", servingSize: 100, servingUnit: "g", cals: 76, protein: 8, carbs: 1.9, fat: 4.8, fiber: 0.3, sugar: 0.6, sodium: 7, category: .protein, emoji: "🧊"),
        Seed(name: "Shrimp", serving: "100g", servingSize: 100, servingUnit: "g", cals: 99, protein: 24, carbs: 0.2, fat: 0.3, fiber: 0, sugar: 0, sodium: 111, category: .protein, emoji: "🍤"),
        Seed(name: "Tuna (canned in water)", serving: "1 can", servingSize: 142, servingUnit: "g", cals: 128, protein: 29, carbs: 0, fat: 1, fiber: 0, sugar: 0, sodium: 320, category: .protein, emoji: "🐟"),
        Seed(name: "Cottage Cheese", serving: "1 cup", servingSize: 226, servingUnit: "g", cals: 220, protein: 25, carbs: 8, fat: 9.5, fiber: 0, sugar: 8, sodium: 819, category: .dairy, emoji: "🧀"),
        Seed(name: "Mozzarella Cheese", serving: "28g", servingSize: 28, servingUnit: "g", cals: 85, protein: 6.3, carbs: 0.6, fat: 6.3, fiber: 0, sugar: 0.3, sodium: 178, category: .dairy, emoji: "🧀"),
        Seed(name: "Butter", serving: "1 tbsp", servingSize: 14, servingUnit: "g", cals: 102, protein: 0.1, carbs: 0, fat: 11.5, fiber: 0, sugar: 0, sodium: 82, category: .dairy),
        Seed(name: "Orange", serving: "1 medium", servingSize: 131, servingUnit: "g", cals: 62, protein: 1.2, carbs: 15.4, fat: 0.2, fiber: 3.1, sugar: 12.2, sodium: 0, category: .fruits, emoji: "🍊"),
        Seed(name: "Strawberries", serving: "1 cup", servingSize: 152, servingUnit: "g", cals: 49, protein: 1, carbs: 12, fat: 0.5, fiber: 3, sugar: 7, sodium: 2, category: .fruits, emoji: "🍓"),
        Seed(name: "Blueberries", serving: "1 cup", servingSize: 148, servingUnit: "g", cals: 84, protein: 1.1, carbs: 21, fat: 0.5, fiber: 3.6, sugar: 15, sodium: 1, category: .fruits, emoji: "🫐"),
        Seed(name: "Grapes", serving: "1 cup", servingSize: 151, servingUnit: "g", cals: 104, protein: 1.1, carbs: 27, fat: 0.2, fiber: 1.4, sugar: 23, sodium: 3, category: .fruits, emoji: "🍇"),
        Seed(name: "Mango", serving: "1 cup sliced", servingSize: 165, servingUnit: "g", cals: 99, protein: 1.4, carbs: 25, fat: 0.6, fiber: 2.6, sugar: 23, sodium: 2, category: .fruits, emoji: "🥭"),
        Seed(name: "Watermelon", serving: "1 cup", servingSize: 152, servingUnit: "g", cals: 46, protein: 0.9, carbs: 11.5, fat: 0.2, fiber: 0.6, sugar: 9.4, sodium: 2, category: .fruits, emoji: "🍉"),
        Seed(name: "Carrot", serving: "1 medium", servingSize: 61, servingUnit: "g", cals: 25, protein: 0.6, carbs: 6, fat: 0.1, fiber: 1.7, sugar: 2.9, sodium: 42, category: .vegetables, emoji: "🥕"),
        Seed(name: "Cucumber", serving: "1 cup sliced", servingSize: 104, servingUnit: "g", cals: 16, protein: 0.7, carbs: 3.8, fat: 0.1, fiber: 0.5, sugar: 1.7, sodium: 2, category: .vegetables, emoji: "🥒"),
        Seed(name: "Bell Pepper", serving: "1 medium", servingSize: 119, servingUnit: "g", cals: 24, protein: 1, carbs: 6, fat: 0.2, fiber: 2, sugar: 4, sodium: 4, category: .vegetables, emoji: "🫑"),
        Seed(name: "Tomato", serving: "1 medium", servingSize: 123, servingUnit: "g", cals: 22, protein: 1.1, carbs: 4.8, fat: 0.2, fiber: 1.5, sugar: 3.2, sodium: 6, category: .vegetables, emoji: "🍅"),
        Seed(name: "Onion", serving: "1 medium", servingSize: 110, servingUnit: "g", cals: 44, protein: 1.2, carbs: 10.3, fat: 0.1, fiber: 1.9, sugar: 4.7, sodium: 4, category: .vegetables, emoji: "🧅"),
        Seed(name: "Cauliflower", serving: "1 cup", servingSize: 107, servingUnit: "g", cals: 27, protein: 2.1, carbs: 5.3, fat: 0.3, fiber: 2.5, sugar: 2.4, sodium: 32, category: .vegetables, emoji: "🥦"),
        Seed(name: "Potato Chips", serving: "28g", servingSize: 28, servingUnit: "g", cals: 152, protein: 2, carbs: 15, fat: 10, fiber: 1.2, sugar: 0.2, sodium: 149, category: .snacks, emoji: "🥔", brand: "Lay's"),
        Seed(name: "Trail Mix", serving: "1/4 cup", servingSize: 40, servingUnit: "g", cals: 173, protein: 5, carbs: 16, fat: 11, fiber: 2.5, sugar: 9, sodium: 60, category: .snacks, emoji: "🥜"),
        Seed(name: "Granola Bar", serving: "1 bar", servingSize: 35, servingUnit: "g", cals: 140, protein: 3, carbs: 24, fat: 4, fiber: 2, sugar: 10, sodium: 80, category: .snacks, emoji: "🍫", brand: "Nature Valley"),
        Seed(name: "Protein Bar", serving: "1 bar", servingSize: 60, servingUnit: "g", cals: 220, protein: 20, carbs: 24, fat: 8, fiber: 10, sugar: 1, sodium: 200, category: .snacks, emoji: "🍫", brand: "Quest"),
        Seed(name: "Hummus", serving: "2 tbsp", servingSize: 30, servingUnit: "g", cals: 70, protein: 2, carbs: 6, fat: 4.5, fiber: 2, sugar: 0, sodium: 130, category: .snacks, emoji: "🥙"),
        Seed(name: "Popcorn", serving: "3 cups popped", servingSize: 24, servingUnit: "g", cals: 93, protein: 3, carbs: 19, fat: 1, fiber: 3.5, sugar: 0.2, sodium: 1, category: .snacks, emoji: "🍿"),
        Seed(name: "Oreo Cookies", serving: "3 cookies", servingSize: 34, servingUnit: "g", cals: 160, protein: 1, carbs: 25, fat: 7, fiber: 1, sugar: 14, sodium: 135, category: .desserts, emoji: "🍪", brand: "Oreo"),
        Seed(name: "Snickers Bar", serving: "1 bar (52g)", servingSize: 52, servingUnit: "g", cals: 250, protein: 4, carbs: 33, fat: 12, fiber: 1, sugar: 27, sodium: 120, category: .desserts, emoji: "🍫", brand: "Snickers"),
        Seed(name: "Vanilla Ice Cream", serving: "1/2 cup", servingSize: 66, servingUnit: "g", cals: 137, protein: 2.3, carbs: 16, fat: 7.3, fiber: 0.5, sugar: 14, sodium: 53, category: .desserts, emoji: "🍦"),
        Seed(name: "Coca-Cola", serving: "1 can (355ml)", servingSize: 355, servingUnit: "ml", cals: 140, protein: 0, carbs: 39, fat: 0, fiber: 0, sugar: 39, sodium: 45, category: .beverages, emoji: "🥤", brand: "Coca-Cola"),
        Seed(name: "Orange Juice", serving: "1 cup", servingSize: 248, servingUnit: "ml", cals: 112, protein: 1.7, carbs: 26, fat: 0.5, fiber: 0.5, sugar: 21, sodium: 2, category: .beverages, emoji: "🧃"),
        Seed(name: "Green Tea", serving: "1 cup", servingSize: 240, servingUnit: "ml", cals: 2, protein: 0.5, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 2, category: .beverages, emoji: "🍵"),
        Seed(name: "Protein Shake", serving: "1 scoop + water", servingSize: 300, servingUnit: "ml", cals: 130, protein: 25, carbs: 4, fat: 1.5, fiber: 1, sugar: 2, sodium: 130, category: .beverages, emoji: "🥤"),
        Seed(name: "Beer", serving: "1 can (355ml)", servingSize: 355, servingUnit: "ml", cals: 153, protein: 1.6, carbs: 13, fat: 0, fiber: 0, sugar: 0, sodium: 14, category: .beverages, emoji: "🍺"),
        Seed(name: "Red Wine", serving: "5oz glass", servingSize: 147, servingUnit: "ml", cals: 125, protein: 0.1, carbs: 3.8, fat: 0, fiber: 0, sugar: 0.9, sodium: 6, category: .beverages, emoji: "🍷"),
        Seed(name: "Pizza Slice (Cheese)", serving: "1 slice", servingSize: 107, servingUnit: "g", cals: 285, protein: 12, carbs: 36, fat: 10, fiber: 2, sugar: 4, sodium: 640, category: .fastFood, emoji: "🍕"),
        Seed(name: "French Fries", serving: "medium", servingSize: 117, servingUnit: "g", cals: 365, protein: 4, carbs: 48, fat: 17, fiber: 4, sugar: 0.3, sodium: 246, category: .fastFood, emoji: "🍟"),
        Seed(name: "Caesar Salad", serving: "1 bowl", servingSize: 200, servingUnit: "g", cals: 320, protein: 9, carbs: 12, fat: 27, fiber: 3, sugar: 3, sodium: 700, category: .vegetables, emoji: "🥗"),
        Seed(name: "Grilled Cheese Sandwich", serving: "1 sandwich", servingSize: 120, servingUnit: "g", cals: 400, protein: 15, carbs: 33, fat: 24, fiber: 2, sugar: 4, sodium: 850, category: .fastFood, emoji: "🥪"),
        Seed(name: "Peanut Butter & Jelly Sandwich", serving: "1 sandwich", servingSize: 100, servingUnit: "g", cals: 350, protein: 11, carbs: 45, fat: 15, fiber: 3, sugar: 18, sodium: 380, category: .fastFood, emoji: "🥪"),
        Seed(name: "Sushi Roll (California)", serving: "8 pieces", servingSize: 180, servingUnit: "g", cals: 255, protein: 9, carbs: 38, fat: 7, fiber: 2, sugar: 6, sodium: 430, category: .fastFood, emoji: "🍣"),
        Seed(name: "Pancakes", serving: "3 pancakes", servingSize: 150, servingUnit: "g", cals: 350, protein: 9, carbs: 55, fat: 10, fiber: 2, sugar: 12, sodium: 600, category: .fastFood, emoji: "🥞"),
        Seed(name: "Waffle", serving: "1 waffle", servingSize: 75, servingUnit: "g", cals: 220, protein: 5.5, carbs: 25, fat: 11, fiber: 1.3, sugar: 4.5, sodium: 380, category: .fastFood, emoji: "🧇"),
        Seed(name: "Bagel with Cream Cheese", serving: "1 bagel", servingSize: 130, servingUnit: "g", cals: 370, protein: 13, carbs: 50, fat: 13, fiber: 2, sugar: 6, sodium: 550, category: .fastFood, emoji: "🥯"),
        Seed(name: "Hot Dog", serving: "1 hot dog", servingSize: 100, servingUnit: "g", cals: 290, protein: 10, carbs: 22, fat: 18, fiber: 1, sugar: 4, sodium: 810, category: .fastFood, emoji: "🌭"),
        Seed(name: "Taco (Beef)", serving: "1 taco", servingSize: 100, servingUnit: "g", cals: 210, protein: 10, carbs: 15, fat: 12, fiber: 2, sugar: 1, sodium: 480, category: .fastFood, emoji: "🌮"),
        Seed(name: "Burrito (Chicken)", serving: "1 burrito", servingSize: 300, servingUnit: "g", cals: 550, protein: 30, carbs: 65, fat: 18, fiber: 6, sugar: 3, sodium: 1200, category: .fastFood, emoji: "🌯"),
        Seed(name: "Ramen", serving: "1 bowl", servingSize: 400, servingUnit: "g", cals: 480, protein: 18, carbs: 60, fat: 18, fiber: 3, sugar: 4, sodium: 1800, category: .fastFood, emoji: "🍜"),
        Seed(name: "Pad Thai", serving: "1 plate", servingSize: 350, servingUnit: "g", cals: 550, protein: 20, carbs: 70, fat: 20, fiber: 3, sugar: 12, sodium: 1100, category: .fastFood, emoji: "🍜"),
        Seed(name: "Fried Rice", serving: "1 cup", servingSize: 200, servingUnit: "g", cals: 330, protein: 8, carbs: 45, fat: 12, fiber: 1.5, sugar: 2, sodium: 700, category: .fastFood, emoji: "🍚"),
        Seed(name: "Spring Rolls", serving: "3 pieces", servingSize: 120, servingUnit: "g", cals: 220, protein: 5, carbs: 26, fat: 11, fiber: 2, sugar: 2, sodium: 400, category: .snacks, emoji: "🥢"),

        // MARK: Fast food chains
        Seed(name: "Big Mac", serving: "1 sandwich", servingSize: 219, servingUnit: "g", cals: 563, protein: 26, carbs: 45, fat: 33, fiber: 3, sugar: 9, sodium: 1010, category: .fastFood, emoji: "🍔", brand: "McDonald's"),
        Seed(name: "McChicken", serving: "1 sandwich", servingSize: 143, servingUnit: "g", cals: 400, protein: 14, carbs: 40, fat: 21, fiber: 2, sugar: 5, sodium: 700, category: .fastFood, emoji: "🍔", brand: "McDonald's"),
        Seed(name: "McDonald's Fries (Medium)", serving: "1 medium", servingSize: 117, servingUnit: "g", cals: 320, protein: 4, carbs: 43, fat: 15, fiber: 4, sugar: 0, sodium: 260, category: .fastFood, emoji: "🍟", brand: "McDonald's"),
        Seed(name: "Chicken McNuggets (10pc)", serving: "10 pieces", servingSize: 160, servingUnit: "g", cals: 420, protein: 23, carbs: 26, fat: 25, fiber: 1.5, sugar: 0, sodium: 900, category: .fastFood, emoji: "🍗", brand: "McDonald's"),
        Seed(name: "Whopper", serving: "1 sandwich", servingSize: 291, servingUnit: "g", cals: 657, protein: 28, carbs: 49, fat: 40, fiber: 2, sugar: 11, sodium: 980, category: .fastFood, emoji: "🍔", brand: "Burger King"),
        Seed(name: "Crispy Chicken Sandwich", serving: "1 sandwich", servingSize: 220, servingUnit: "g", cals: 670, protein: 28, carbs: 55, fat: 38, fiber: 2, sugar: 6, sodium: 1360, category: .fastFood, emoji: "🍔", brand: "Burger King"),
        Seed(name: "Original Recipe Chicken (breast)", serving: "1 piece", servingSize: 161, servingUnit: "g", cals: 390, protein: 39, carbs: 11, fat: 21, fiber: 0.5, sugar: 0, sodium: 1190, category: .fastFood, emoji: "🍗", brand: "KFC"),
        Seed(name: "Zinger Burger", serving: "1 sandwich", servingSize: 228, servingUnit: "g", cals: 550, protein: 27, carbs: 50, fat: 27, fiber: 2, sugar: 6, sodium: 1250, category: .fastFood, emoji: "🍔", brand: "KFC"),
        Seed(name: "6-inch Turkey Sub", serving: "1 sub", servingSize: 220, servingUnit: "g", cals: 280, protein: 18, carbs: 46, fat: 3.5, fiber: 5, sugar: 7, sodium: 760, category: .fastFood, emoji: "🥪", brand: "Subway"),
        Seed(name: "6-inch Chicken Teriyaki Sub", serving: "1 sub", servingSize: 250, servingUnit: "g", cals: 370, protein: 26, carbs: 55, fat: 5, fiber: 5, sugar: 17, sodium: 900, category: .fastFood, emoji: "🥪", brand: "Subway"),
        Seed(name: "Pepperoni Pizza (Medium slice)", serving: "1 slice", servingSize: 111, servingUnit: "g", cals: 300, protein: 13, carbs: 34, fat: 12, fiber: 2, sugar: 4, sodium: 700, category: .fastFood, emoji: "🍕", brand: "Domino's"),
        Seed(name: "Chicken Burrito Bowl", serving: "1 bowl", servingSize: 500, servingUnit: "g", cals: 630, protein: 42, carbs: 66, fat: 20, fiber: 12, sugar: 4, sodium: 1400, category: .fastFood, emoji: "🥗", brand: "Chipotle"),
        Seed(name: "Caramel Macchiato (Grande)", serving: "16 fl oz", servingSize: 473, servingUnit: "ml", cals: 250, protein: 10, carbs: 35, fat: 7, fiber: 0, sugar: 33, sodium: 150, category: .beverages, emoji: "☕", brand: "Starbucks"),
        Seed(name: "Iced Caramel Frappuccino (Grande)", serving: "16 fl oz", servingSize: 473, servingUnit: "ml", cals: 380, protein: 5, carbs: 60, fat: 15, fiber: 0, sugar: 54, sodium: 240, category: .beverages, emoji: "🥤", brand: "Starbucks"),
        Seed(name: "Classic Chicken Burger", serving: "1 burger", servingSize: 168, servingUnit: "g", cals: 380, protein: 16, carbs: 39, fat: 18, fiber: 2, sugar: 5, sodium: 820, category: .fastFood, emoji: "🍔", brand: "Wendy's"),
        Seed(name: "Baconator", serving: "1 burger", servingSize: 285, servingUnit: "g", cals: 950, protein: 58, carbs: 37, fat: 63, fiber: 2, sugar: 8, sodium: 1740, category: .fastFood, emoji: "🍔", brand: "Wendy's"),
        Seed(name: "Glazed Donut", serving: "1 donut", servingSize: 52, servingUnit: "g", cals: 190, protein: 2, carbs: 22, fat: 10, fiber: 0.7, sugar: 10, sodium: 95, category: .desserts, emoji: "🍩", brand: "Dunkin'"),
        Seed(name: "Iced Coffee (Medium)", serving: "24 fl oz", servingSize: 710, servingUnit: "ml", cals: 15, protein: 0, carbs: 3, fat: 0, fiber: 0, sugar: 2, sodium: 15, category: .beverages, emoji: "☕", brand: "Dunkin'"),

        // MARK: Raw ingredients (per 100g reference)
        Seed(name: "Chicken Breast (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 120, protein: 22.5, carbs: 0, fat: 2.6, fiber: 0, sugar: 0, sodium: 65, category: .protein, emoji: "🍗"),
        Seed(name: "Chicken Thigh (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 156, protein: 17.5, carbs: 0, fat: 9.2, fiber: 0, sugar: 0, sodium: 80, category: .protein, emoji: "🍗"),
        Seed(name: "Ground Beef (85/15, raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 215, protein: 19, carbs: 0, fat: 15, fiber: 0, sugar: 0, sodium: 66, category: .protein, emoji: "🥩"),
        Seed(name: "Pork Chop (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 143, protein: 21, carbs: 0, fat: 6, fiber: 0, sugar: 0, sodium: 57, category: .protein, emoji: "🥩"),
        Seed(name: "Egg (raw, 1 large)", serving: "1 large", servingSize: 50, servingUnit: "g", cals: 72, protein: 6.3, carbs: 0.4, fat: 4.8, fiber: 0, sugar: 0.2, sodium: 71, category: .protein, emoji: "🥚"),
        Seed(name: "Lentils (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 353, protein: 25, carbs: 60, fat: 1.1, fiber: 31, sugar: 2, sodium: 6, category: .protein, emoji: "🫘"),
        Seed(name: "Chickpeas (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 364, protein: 19, carbs: 61, fat: 6, fiber: 17, sugar: 11, sodium: 24, category: .protein, emoji: "🫘"),
        Seed(name: "White Rice (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 365, protein: 7.1, carbs: 80, fat: 0.7, fiber: 1.3, sugar: 0.1, sodium: 5, category: .grains, emoji: "🍚"),
        Seed(name: "Basmati Rice (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 350, protein: 7.5, carbs: 78, fat: 0.6, fiber: 1.2, sugar: 0.1, sodium: 2, category: .grains, emoji: "🍚"),
        Seed(name: "Rolled Oats (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 389, protein: 16.9, carbs: 66, fat: 6.9, fiber: 10.6, sugar: 0, sodium: 2, category: .grains, emoji: "🌾"),
        Seed(name: "All-Purpose Flour (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 364, protein: 10, carbs: 76, fat: 1, fiber: 2.7, sugar: 0.3, sodium: 2, category: .grains, emoji: "🌾"),
        Seed(name: "Whole Wheat Flour (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 340, protein: 13.7, carbs: 72, fat: 2.5, fiber: 10.7, sugar: 0.4, sodium: 2, category: .grains, emoji: "🌾"),
        Seed(name: "Olive Oil (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 884, protein: 0, carbs: 0, fat: 100, fiber: 0, sugar: 0, sodium: 2, category: .other, emoji: "🫒"),
        Seed(name: "Vegetable Oil (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 884, protein: 0, carbs: 0, fat: 100, fiber: 0, sugar: 0, sodium: 0, category: .other, emoji: "🛢️"),
        Seed(name: "Ghee (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 900, protein: 0, carbs: 0, fat: 100, fiber: 0, sugar: 0, sodium: 0, category: .other, emoji: "🧈"),
        Seed(name: "Sugar (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 387, protein: 0, carbs: 100, fat: 0, fiber: 0, sugar: 100, sodium: 1, category: .other, emoji: "🍬"),
        Seed(name: "Honey (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 304, protein: 0.3, carbs: 82, fat: 0, fiber: 0.2, sugar: 82, sodium: 4, category: .other, emoji: "🍯"),
        Seed(name: "Salmon (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 208, protein: 20, carbs: 0, fat: 13, fiber: 0, sugar: 0, sodium: 59, category: .protein, emoji: "🐟"),
        Seed(name: "Whole Wheat Pasta (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 348, protein: 14.6, carbs: 71, fat: 2.5, fiber: 9.6, sugar: 3.3, sodium: 6, category: .grains, emoji: "🍝"),
        Seed(name: "Milk (Whole, 100ml)", serving: "100ml", servingSize: 100, servingUnit: "ml", cals: 61, protein: 3.2, carbs: 4.8, fat: 3.3, fiber: 0, sugar: 5.1, sodium: 43, category: .dairy, emoji: "🥛"),
        Seed(name: "Milk (Skim, 100ml)", serving: "100ml", servingSize: 100, servingUnit: "ml", cals: 34, protein: 3.4, carbs: 5, fat: 0.1, fiber: 0, sugar: 5.1, sodium: 42, category: .dairy, emoji: "🥛"),
        Seed(name: "Paneer (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 265, protein: 18.3, carbs: 3.6, fat: 20.8, fiber: 0, sugar: 3.6, sodium: 22, category: .dairy, emoji: "🧀"),
        Seed(name: "Almonds (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 579, protein: 21, carbs: 22, fat: 50, fiber: 12.5, sugar: 4.4, sodium: 1, category: .snacks, emoji: "🌰"),
        Seed(name: "Peanuts (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 567, protein: 25.8, carbs: 16.1, fat: 49.2, fiber: 8.5, sugar: 4.7, sodium: 18, category: .snacks, emoji: "🥜"),
        Seed(name: "Cashews (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 553, protein: 18.2, carbs: 30.2, fat: 43.9, fiber: 3.3, sugar: 5.9, sodium: 12, category: .snacks, emoji: "🌰"),
        Seed(name: "Walnuts (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 654, protein: 15.2, carbs: 13.7, fat: 65.2, fiber: 6.7, sugar: 2.6, sodium: 2, category: .snacks, emoji: "🌰"),
        Seed(name: "Garlic (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 149, protein: 6.4, carbs: 33, fat: 0.5, fiber: 2.1, sugar: 1, sodium: 17, category: .vegetables, emoji: "🧄"),
        Seed(name: "Ginger (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 80, protein: 1.8, carbs: 18, fat: 0.8, fiber: 2, sugar: 1.7, sodium: 13, category: .vegetables, emoji: "🫚"),
        Seed(name: "Green Chili (100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 40, protein: 2, carbs: 9, fat: 0.2, fiber: 1.5, sugar: 5, sodium: 7, category: .vegetables, emoji: "🌶️"),
        Seed(name: "Potato (raw, 100g)", serving: "100g", servingSize: 100, servingUnit: "g", cals: 77, protein: 2, carbs: 17, fat: 0.1, fiber: 2.2, sugar: 0.8, sodium: 6, category: .vegetables, emoji: "🥔"),
    ]
}
