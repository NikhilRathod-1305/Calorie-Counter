import SwiftUI

enum CreateFoodMode {
    case create
    case quickLog
    case edit(FoodItem)

    var title: String {
        switch self {
        case .create: return "Create Food"
        case .quickLog: return "Quick Log"
        case .edit: return "Edit Food"
        }
    }

    /// Quick Log only asks for a name + calories; Create/Edit show full macros.
    var showsFullFields: Bool {
        switch self {
        case .quickLog: return false
        case .create, .edit: return true
        }
    }
}

/// Full-screen form for creating a custom food, quick-logging a calorie-only
/// entry, or editing an existing personal food — all three share the same
/// icon + name + serving + macro fields, differing only in which are shown.
struct CreateFoodView: View {
    @Environment(\.dismiss) private var dismiss
    let mode: CreateFoodMode
    let onSave: (FoodItem) -> Void

    @State private var emoji: String
    @State private var name: String
    @State private var servingSize: String
    @State private var servingUnit: String
    @State private var calories: String
    @State private var carbs: String
    @State private var protein: String
    @State private var fat: String
    @State private var showingIconPicker = false

    private static let units = ["gram (g)", "ml", "oz", "piece", "cup"]

    init(mode: CreateFoodMode, onSave: @escaping (FoodItem) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case .edit(let food) = mode {
            _emoji = State(initialValue: food.emoji)
            _name = State(initialValue: food.name)
            _servingSize = State(initialValue: Self.trimmed(food.servingSize))
            _servingUnit = State(initialValue: food.servingUnit)
            _calories = State(initialValue: Self.trimmed(food.calories))
            _carbs = State(initialValue: Self.trimmed(food.carbs))
            _protein = State(initialValue: Self.trimmed(food.protein))
            _fat = State(initialValue: Self.trimmed(food.fat))
        } else {
            _emoji = State(initialValue: "")
            _name = State(initialValue: "")
            _servingSize = State(initialValue: "")
            _servingUnit = State(initialValue: "gram (g)")
            _calories = State(initialValue: "")
            _carbs = State(initialValue: "")
            _protein = State(initialValue: "")
            _fat = State(initialValue: "")
        }
    }

    private static func trimmed(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard Double(calories) != nil else { return false }
        if mode.showsFullFields {
            return servingSize.isEmpty == false && Double(servingSize) != nil
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    iconButton

                    VStack(alignment: .leading, spacing: 18) {
                        field(label: "Food Name", text: $name, placeholder: "e.g. Salad, Sandwich, etc")

                        if mode.showsFullFields {
                            HStack(spacing: 14) {
                                field(label: "Serving", text: $servingSize, placeholder: "e.g. 100", keyboard: .decimalPad)
                                unitField
                            }
                            HStack(spacing: 14) {
                                field(label: "Calorie (kcal)", text: $calories, placeholder: "e.g. 100", keyboard: .decimalPad)
                                field(label: "Carbs (g)", text: $carbs, placeholder: "e.g. 100", keyboard: .decimalPad)
                            }
                            HStack(spacing: 14) {
                                field(label: "Protein (g)", text: $protein, placeholder: "e.g. 100", keyboard: .decimalPad)
                                field(label: "Fat (g)", text: $fat, placeholder: "e.g. 100", keyboard: .decimalPad)
                            }
                        } else {
                            field(label: "Calorie (kcal)", text: $calories, placeholder: "e.g. 200", keyboard: .decimalPad)
                        }
                    }

                    Color.clear.frame(height: 60)
                }
                .padding(20)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(Theme.Font.text(15, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(canSave ? Theme.accent : Theme.accent.opacity(0.4), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .background(Theme.groupedBackground)
            }
            .sheet(isPresented: $showingIconPicker) {
                FoodIconPickerView { selected in
                    emoji = selected
                }
            }
        }
    }

    private var iconButton: some View {
        Button {
            showingIconPicker = true
        } label: {
            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 1.5)
                    .frame(width: 84, height: 84)
                if emoji.isEmpty {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(Theme.textFaint)
                } else {
                    Text(emoji)
                        .font(.system(size: 40))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var unitField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Unit")
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textPrimary)
            Menu {
                ForEach(Self.units, id: \.self) { unit in
                    Button(unit) { servingUnit = unit }
                }
            } label: {
                HStack {
                    Text(servingUnit)
                        .font(Theme.Font.text(14))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textFaint)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassCardAlt(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func field(label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textPrimary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(Theme.Font.text(14))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassCardAlt(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        let unitLabel = servingUnit.components(separatedBy: " ").first ?? servingUnit
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let resolvedEmoji = emoji.isEmpty ? "🍽️" : emoji

        if case .edit(let existing) = mode {
            existing.name = trimmedName
            existing.calories = Double(calories) ?? 0
            existing.protein = Double(protein) ?? 0
            existing.carbs = Double(carbs) ?? 0
            existing.fat = Double(fat) ?? 0
            existing.servingSize = Double(servingSize) ?? 100
            existing.servingUnit = unitLabel
            existing.emoji = resolvedEmoji
            onSave(existing)
        } else {
            let food = FoodItem(
                name: trimmedName,
                calories: Double(calories) ?? 0,
                protein: Double(protein) ?? 0,
                carbs: Double(carbs) ?? 0,
                fat: Double(fat) ?? 0,
                servingSize: mode.showsFullFields ? (Double(servingSize) ?? 100) : 1,
                servingUnit: mode.showsFullFields ? unitLabel : "serving",
                isCustom: true,
                emoji: resolvedEmoji
            )
            onSave(food)
        }
        dismiss()
    }
}
