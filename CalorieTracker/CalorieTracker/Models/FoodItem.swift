import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var brand: String?
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var servingSize: Double
    var servingUnit: String
    var category: FoodCategory
    var isCustom: Bool
    var emoji: String
    var isFavorite: Bool = false
    var createdAt: Date = Date()

    init(
        name: String,
        brand: String? = nil,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        servingSize: Double = 100,
        servingUnit: String = "g",
        category: FoodCategory = .other,
        isCustom: Bool = false,
        emoji: String = "🍽️",
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.category = category
        self.isCustom = isCustom
        self.emoji = emoji
        self.isFavorite = isFavorite
        self.createdAt = Date()
    }

    func nutritionFor(quantity: Double) -> NutritionValues {
        let ratio = quantity / servingSize
        return NutritionValues(
            calories: calories * ratio,
            protein: protein * ratio,
            carbs: carbs * ratio,
            fat: fat * ratio,
            fiber: fiber * ratio,
            sugar: sugar * ratio,
            sodium: sodium * ratio
        )
    }
}

enum FoodCategory: String, Codable, CaseIterable {
    case fruits = "Fruits"
    case vegetables = "Vegetables"
    case grains = "Grains"
    case protein = "Protein"
    case dairy = "Dairy"
    case snacks = "Snacks"
    case beverages = "Beverages"
    case fastFood = "Fast Food"
    case desserts = "Desserts"
    case other = "Other"

    var emoji: String {
        switch self {
        case .fruits: return "🍎"
        case .vegetables: return "🥦"
        case .grains: return "🌾"
        case .protein: return "🥩"
        case .dairy: return "🥛"
        case .snacks: return "🍿"
        case .beverages: return "☕"
        case .fastFood: return "🍔"
        case .desserts: return "🍰"
        case .other: return "🍽️"
        }
    }
}

struct NutritionValues {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double

    static var zero: NutritionValues {
        NutritionValues(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0)
    }

    static func + (lhs: NutritionValues, rhs: NutritionValues) -> NutritionValues {
        NutritionValues(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sugar: lhs.sugar + rhs.sugar,
            sodium: lhs.sodium + rhs.sodium
        )
    }
}
