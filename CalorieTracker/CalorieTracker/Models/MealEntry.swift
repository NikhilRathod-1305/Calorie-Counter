import Foundation
import SwiftData
import SwiftUI

@Model
final class MealEntry {
    var id: UUID
    var foodItem: FoodItem?
    var customFoodName: String?
    var quantity: Double
    var mealType: MealType
    var timestamp: Date
    var notes: String?
    var inputMethod: InputMethod
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double

    init(
        foodItem: FoodItem? = nil,
        customFoodName: String? = nil,
        quantity: Double = 100,
        mealType: MealType = .lunch,
        timestamp: Date = Date(),
        notes: String? = nil,
        inputMethod: InputMethod = .text,
        calories: Double = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0
    ) {
        self.id = UUID()
        self.foodItem = foodItem
        self.customFoodName = customFoodName
        self.quantity = quantity
        self.mealType = mealType
        self.timestamp = timestamp
        self.notes = notes
        self.inputMethod = inputMethod
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }

    var displayName: String {
        foodItem?.name ?? customFoodName ?? "Unknown Food"
    }

    var nutrition: NutritionValues {
        if let food = foodItem {
            return food.nutritionFor(quantity: quantity)
        }
        return NutritionValues(calories: calories, protein: protein, carbs: carbs, fat: fat, fiber: fiber, sugar: sugar, sodium: sodium)
    }

    var dominantMacroColor: Color {
        let n = nutrition
        if n.protein >= n.carbs && n.protein >= n.fat { return Theme.proteinColor }
        if n.carbs >= n.fat { return Theme.carbColor }
        return Theme.fatColor
    }

    var hourOfDay: Double {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: timestamp)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var emoji: String {
        switch self {
        case .breakfast: return "🥞"
        case .lunch: return "🥗"
        case .dinner: return "🍝"
        case .snack: return "🥑"
        }
    }

    var color: String {
        switch self {
        case .breakfast: return "orange"
        case .lunch: return "green"
        case .dinner: return "indigo"
        case .snack: return "purple"
        }
    }

    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }

    static var currentMealType: MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<18: return .snack
        default: return .dinner
        }
    }
}

enum InputMethod: String, Codable {
    case text = "Text"
    case voice = "Voice"
    case photo = "Photo"
    case search = "Search"
    case manual = "Manual"
    case barcode = "Barcode"
}
