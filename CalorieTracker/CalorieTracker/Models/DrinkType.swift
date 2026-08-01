import SwiftUI

enum DrinkType: String, Codable, CaseIterable, Identifiable {
    case water, coffee, tea, juice, sportDrink, coconutWater, smoothie, chocolateMilk, soda, wine, beer, liquor

    var id: String { rawValue }

    var label: String {
        switch self {
        case .water: return "Water"
        case .coffee: return "Coffee"
        case .tea: return "Tea"
        case .juice: return "Juice"
        case .sportDrink: return "Sport Drink"
        case .coconutWater: return "Coconut Water"
        case .smoothie: return "Smoothie"
        case .chocolateMilk: return "Chocolate"
        case .soda: return "Carbonated"
        case .wine: return "Wine"
        case .beer: return "Beer"
        case .liquor: return "Liquor"
        }
    }

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .tea: return "mug.fill"
        case .juice: return "waterbottle.fill"
        case .sportDrink: return "bolt.fill"
        case .coconutWater: return "tree.fill"
        case .smoothie: return "takeoutbag.and.cup.and.straw.fill"
        case .chocolateMilk: return "cup.and.saucer.fill"
        case .soda: return "bubbles.and.sparkles.fill"
        case .wine: return "wineglass.fill"
        case .beer: return "mug.fill"
        case .liquor: return "flame.fill"
        }
    }

    var tint: Color {
        switch self {
        case .water: return Theme.water
        case .coffee: return Color(hex: 0x6F4E37)
        case .tea: return Color(hex: 0xC0392B)
        case .juice: return Color(hex: 0xFF9F1C)
        case .sportDrink: return Color(hex: 0x2ECC71)
        case .coconutWater: return Color(hex: 0x27AE60)
        case .smoothie: return Color(hex: 0xE056A0)
        case .chocolateMilk: return Color(hex: 0x7B4B2A)
        case .soda: return Color(hex: 0xE74C3C)
        case .wine: return Color(hex: 0x922B3E)
        case .beer: return Color(hex: 0xF0A500)
        case .liquor: return Color(hex: 0x4A4A4A)
        }
    }

    /// Fraction of the drink's volume that counts toward the hydration goal.
    var hydrationFactor: Double {
        switch self {
        case .water, .sportDrink, .coconutWater: return 1.0
        case .tea, .juice, .smoothie, .chocolateMilk, .soda: return 0.9
        case .coffee: return 0.8
        case .wine, .beer, .liquor: return 0.5
        }
    }
}

enum CupSize: Int, CaseIterable, Identifiable {
    case ml100 = 100, ml125 = 125, ml150 = 150, ml200 = 200
    case ml250 = 250, ml300 = 300, ml350 = 350, ml400 = 400
    case ml500 = 500, ml600 = 600

    var id: Int { rawValue }
    var label: String { "\(rawValue) mL" }
}
