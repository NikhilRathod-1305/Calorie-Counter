import SwiftUI
import SwiftData

enum FoodListTab: String, CaseIterable {
    case recent = "Recent"
    case favorites = "Favorites"
    case personal = "My Foods"
}

/// Search-first food browser matching the reference "Log food" screen:
/// Recent/Favorites/Personal tabs, multi-select rows with a running total,
/// Quick Log / Create Food shortcuts, and a food detail drill-down.
struct FoodBrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodItem.name) private var allFoods: [FoodItem]
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var allEntries: [MealEntry]

    let mealType: MealType
    let date: Date
    let onAdded: () -> Void

    @State private var query: String = ""
    @State private var tab: FoodListTab = .recent
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var detailFood: FoodItem?
    @State private var editingFood: FoodItem?
    @State private var showingCreateFood = false
    @State private var showingQuickLog = false
    @State private var showingBarcodeScanner = false
    @State private var deletingFood: FoodItem?
    @State private var unfavoritingFood: FoodItem?

    private var recentFoods: [FoodItem] {
        var seen = Set<PersistentIdentifier>()
        var ordered: [FoodItem] = []
        for entry in allEntries {
            guard let food = entry.foodItem, seen.insert(food.persistentModelID).inserted else { continue }
            ordered.append(food)
            if ordered.count >= 30 { break }
        }

        // Foods created (via Create Food/Quick Log) but never actually logged
        // yet still belong in Recent, newest first, after the logged ones.
        let unloggedPersonal = allFoods
            .filter { $0.isCustom && seen.insert($0.persistentModelID).inserted }
            .sorted { $0.createdAt > $1.createdAt }
        ordered.append(contentsOf: unloggedPersonal)

        return ordered
    }

    private var favoriteFoods: [FoodItem] { allFoods.filter(\.isFavorite) }

    private var listedFoods: [FoodItem] {
        let base: [FoodItem]
        switch tab {
        case .recent: base = recentFoods
        case .favorites: base = favoriteFoods
        case .personal: base = allFoods
        }
        guard !query.isEmpty else { return base }
        return Self.rankedMatches(of: query, in: base)
    }

    /// Search is global across the whole library regardless of which tab is
    /// active, so a query always surfaces every matching food, not just the
    /// ones in the current tab's subset.
    private var searchResults: [FoodItem]? {
        guard !query.isEmpty else { return nil }
        return Self.rankedMatches(of: query, in: allFoods)
    }

    /// Ranks foods by match quality rather than relying on `@Query`'s name
    /// sort order: exact name match, then name-prefix, then a word inside the
    /// name starting with the query, then any substring hit in name/brand.
    /// Keeps ties in alphabetical order since `foods` is already name-sorted.
    private static func rankedMatches(of query: String, in foods: [FoodItem]) -> [FoodItem] {
        func score(_ food: FoodItem) -> Int? {
            let name = food.name
            if name.caseInsensitiveCompare(query) == .orderedSame { return 0 }
            if name.range(of: query, options: [.caseInsensitive, .anchored]) != nil { return 1 }
            if name.range(of: " \(query)", options: [.caseInsensitive]) != nil { return 2 }
            if name.localizedCaseInsensitiveContains(query) { return 3 }
            if let brand = food.brand, brand.localizedCaseInsensitiveContains(query) { return 4 }
            return nil
        }
        return foods
            .compactMap { food in score(food).map { (food, $0) } }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    private var selectedTotal: Int {
        selectedIDs.reduce(0) { total, id in
            guard let food = allFoods.first(where: { $0.persistentModelID == id }) else { return total }
            return total + Int(food.calories)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.textFaint)
                    TextField("Search", text: $query)
                        .font(Theme.Font.text(14))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassCardAlt(RoundedRectangle(cornerRadius: 12))

                Button {
                    showingBarcodeScanner = true
                } label: {
                    Image(systemName: "barcode.viewfinder")
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 40, height: 40)
                        .glassCardAlt(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!BarcodeScannerView.isAvailable)
            }

            HStack(spacing: 10) {
                shortcutButton(icon: "bolt.fill", label: "Quick Log") { showingQuickLog = true }
                shortcutButton(icon: "plus", label: "Create Food") { showingCreateFood = true }
            }

            if searchResults == nil {
                PillSegmentedControl(
                    options: FoodListTab.allCases.map { ($0, $0.rawValue) },
                    selection: $tab,
                    style: .outlined
                )
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    let rows = searchResults ?? listedFoods
                    if rows.isEmpty {
                        Text(emptyMessage)
                            .font(Theme.Font.text(13))
                            .foregroundStyle(Theme.textFaint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(rows) { food in
                            foodRow(food)
                            Divider().overlay(Theme.hairline.opacity(0.6))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            if !selectedIDs.isEmpty {
                addBar
            }
        }
        .sheet(item: $detailFood) { food in
            FoodDetailView(
                food: food,
                isFavorite: food.isFavorite,
                onToggleFavorite: { toggleFavorite(food) },
                onAdd: { quantity in
                    addFoodItem(food, quantity: quantity)
                }
            )
        }
        .sheet(isPresented: $showingCreateFood) {
            CreateFoodView(mode: .create) { newFood in
                modelContext.insert(newFood)
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $showingQuickLog) {
            CreateFoodView(mode: .quickLog) { newFood in
                modelContext.insert(newFood)
                try? modelContext.save()
                addFoodItem(newFood, quantity: 1)
            }
        }
        .sheet(item: $editingFood) { food in
            CreateFoodView(mode: .edit(food)) { _ in
                try? modelContext.save()
            }
        }
        .fullScreenCover(isPresented: $showingBarcodeScanner) {
            ZStack(alignment: .topTrailing) {
                BarcodeScannerView { code in
                    showingBarcodeScanner = false
                }
                .ignoresSafeArea()

                Button {
                    showingBarcodeScanner = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.4), in: Circle())
                }
                .padding(20)
            }
        }
        .confirmationDialog(
            "Sure you want to remove this food from favorites? You can always add it back later.",
            isPresented: Binding(get: { unfavoritingFood != nil }, set: { if !$0 { unfavoritingFood = nil } }),
            titleVisibility: .visible
        ) {
            Button("Yes, Remove", role: .destructive) {
                if let food = unfavoritingFood { food.isFavorite = false; try? modelContext.save() }
                unfavoritingFood = nil
            }
            Button("Cancel", role: .cancel) { unfavoritingFood = nil }
        }
        .confirmationDialog(
            "Sure you want to delete this personal food? This action cannot be undone.",
            isPresented: Binding(get: { deletingFood != nil }, set: { if !$0 { deletingFood = nil } }),
            titleVisibility: .visible
        ) {
            Button("Yes, Delete", role: .destructive) {
                if let food = deletingFood {
                    modelContext.delete(food)
                    try? modelContext.save()
                }
                deletingFood = nil
            }
            Button("Cancel", role: .cancel) { deletingFood = nil }
        }
    }

    private var emptyMessage: String {
        switch tab {
        case .recent: return "No recent foods yet"
        case .favorites: return "No favorites yet — tap the heart on a food to save it here"
        case .personal: return "No foods found"
        }
    }

    private func shortcutButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(Theme.Font.text(13, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .glassCardAlt(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func foodRow(_ food: FoodItem) -> some View {
        let isSelected = selectedIDs.contains(food.persistentModelID)
        return HStack(spacing: 12) {
            Button {
                toggleSelection(food)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.accent.opacity(0.5))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(food.name)
                        .font(Theme.Font.text(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if let brand = food.brand {
                        Text(brand)
                            .font(Theme.Font.text(11, weight: .medium))
                            .foregroundStyle(Theme.textFaint)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .glassCardAlt(RoundedRectangle(cornerRadius: 6))
                    }
                }
                Text("\(Int(food.calories)) kcal , \(Int(food.servingSize)) \(food.servingUnit)")
                    .font(Theme.Font.text(12))
                    .foregroundStyle(Theme.textFaint)
            }

            Spacer()

            if food.isCustom {
                Menu {
                    Button("Edit") { editingFood = food }
                    Button("Delete", role: .destructive) { deletingFood = food }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.textFaint)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    detailFood = food
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textFaint)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { detailFood = food }
    }

    private var addBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("kcal")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textFaint)
                Text("\(selectedTotal)")
                    .font(Theme.Font.display(20))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Button {
                addSelected()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add (\(selectedIDs.count))")
                }
                .font(Theme.Font.text(15, weight: .semibold))
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 220)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .background(Theme.groupedBackground)
    }

    private func toggleSelection(_ food: FoodItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            if selectedIDs.contains(food.persistentModelID) {
                selectedIDs.remove(food.persistentModelID)
            } else {
                selectedIDs.insert(food.persistentModelID)
            }
        }
    }

    private func toggleFavorite(_ food: FoodItem) {
        if food.isFavorite {
            unfavoritingFood = food
        } else {
            food.isFavorite = true
            try? modelContext.save()
        }
    }

    /// The selected day combined with the current time-of-day, so entries
    /// logged for a past day still sort sensibly instead of all landing at
    /// midnight.
    private var entryTimestamp: Date {
        let cal = Calendar.current
        guard !cal.isDateInToday(date) else { return Date() }
        let time = cal.dateComponents([.hour, .minute, .second], from: Date())
        return cal.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0, of: date) ?? date
    }

    private func addFoodItem(_ food: FoodItem, quantity: Double) {
        let nutrition = food.nutritionFor(quantity: food.servingSize * quantity)
        let entry = MealEntry(
            foodItem: food,
            quantity: food.servingSize * quantity,
            mealType: mealType,
            timestamp: entryTimestamp,
            inputMethod: .search,
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbs: nutrition.carbs,
            fat: nutrition.fat,
            fiber: nutrition.fiber,
            sugar: nutrition.sugar,
            sodium: nutrition.sodium
        )
        modelContext.insert(entry)
        try? modelContext.save()
        onAdded()
    }

    private func addSelected() {
        for food in allFoods where selectedIDs.contains(food.persistentModelID) {
            addFoodItem(food, quantity: 1)
        }
        selectedIDs.removeAll()
    }
}
