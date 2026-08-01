import SwiftUI

/// Full-screen food detail: macro donut ring, per-macro breakdown, sodium,
/// a weight/quantity stepper, and an Add button — matching the reference's
/// "Cheeseburger" detail screen. Reused for both library foods and personal foods.
struct FoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let food: FoodItem
    var isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onAdd: (Double) -> Void

    @State private var quantity: Double = 1

    private var nutrition: NutritionValues { food.nutritionFor(quantity: food.servingSize * quantity) }

    private var macroCalorieShares: (carbs: Double, protein: Double, fat: Double) {
        let carbsCal = nutrition.carbs * 4
        let proteinCal = nutrition.protein * 4
        let fatCal = nutrition.fat * 9
        let total = max(1, carbsCal + proteinCal + fatCal)
        return (carbsCal / total, proteinCal / total, fatCal / total)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(food.emoji)
                        .font(.system(size: 64))
                        .frame(width: 120, height: 120)
                        .background(Theme.cardBackgroundAlt, in: Circle())

                    Text(food.name)
                        .font(Theme.Font.display(22))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Divider().overlay(Theme.hairline)

                    HStack(spacing: 24) {
                        ZStack {
                            macroRing
                            VStack(spacing: 2) {
                                Text("\(Int(nutrition.calories))")
                                    .font(Theme.Font.display(30))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("kcal")
                                    .font(Theme.Font.text(11))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .frame(width: 130, height: 130)

                        VStack(alignment: .leading, spacing: 12) {
                            macroLegendRow(color: Theme.carbColor, label: "Carbs", grams: nutrition.carbs, share: macroCalorieShares.carbs)
                            macroLegendRow(color: Theme.proteinColor, label: "Protein", grams: nutrition.protein, share: macroCalorieShares.protein)
                            macroLegendRow(color: Theme.fatColor, label: "Fat", grams: nutrition.fat, share: macroCalorieShares.fat)
                        }
                        Spacer(minLength: 0)
                    }

                    Divider().overlay(Theme.hairline)

                    VStack(spacing: 0) {
                        statRow(label: "Sodium", value: "\(Int(nutrition.sodium)) mg")
                        Divider().overlay(Theme.hairline.opacity(0.6))
                        statRow(label: "Fiber", value: "\(String(format: "%.1f", nutrition.fiber)) g")
                        Divider().overlay(Theme.hairline.opacity(0.6))
                        statRow(label: "Sugar", value: "\(String(format: "%.1f", nutrition.sugar)) g")
                    }

                    Color.clear.frame(height: 60)
                }
                .padding(20)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onToggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? Theme.danger : Theme.textPrimary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Weight")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textFaint)
                        Spacer()
                        QuantityStepper(quantity: $quantity, size: 30)
                    }

                    Button {
                        onAdd(quantity)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .font(Theme.Font.text(15, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .background(Theme.groupedBackground)
            }
        }
    }

    private var macroRing: some View {
        let shares = macroCalorieShares
        let carbsEnd = shares.carbs
        let proteinEnd = carbsEnd + shares.protein
        return ZStack {
            Circle()
                .trim(from: 0, to: carbsEnd)
                .stroke(Theme.carbColor, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
            Circle()
                .trim(from: carbsEnd, to: proteinEnd)
                .stroke(Theme.proteinColor, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
            Circle()
                .trim(from: proteinEnd, to: 1)
                .stroke(Theme.fatColor, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
        }
        .rotationEffect(.degrees(-90))
    }

    private func macroLegendRow(color: Color, label: String, grams: Double, share: Double) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 12)
            Text("\(String(format: "%.1f", grams))g")
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("(\(Int(share * 100))%)")
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textFaint)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 10)
    }
}
