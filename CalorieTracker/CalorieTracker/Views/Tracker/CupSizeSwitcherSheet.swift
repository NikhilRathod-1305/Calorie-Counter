import SwiftUI

/// Grid of preset cup sizes plus a row of drink types, matching the reference
/// "Switch Cup Size" sheet. Selecting an item sets the active default used by
/// the quick "Drink" button on the Water Details screen — it does not log by itself.
struct CupSizeSwitcherSheet: View {
    @Binding var selectedSize: Int
    @Binding var selectedDrinkType: DrinkType
    let onClose: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    var body: some View {
        BottomSheetContainer(title: "Switch Cup Size", onClose: onClose) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(CupSize.allCases) { size in
                            sizeCell(size)
                        }
                        addCustomCell
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or Drink")
                            .font(Theme.Font.text(12, weight: .medium))
                            .foregroundStyle(Theme.textFaint)

                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(DrinkType.allCases.filter { $0 != .water }) { type in
                                drinkCell(type)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 420)
        }
    }

    private func sizeCell(_ size: CupSize) -> some View {
        let isSelected = selectedSize == size.rawValue && selectedDrinkType == .water
        return VStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.water)
                .frame(width: 56, height: 56)
                .background(Theme.cardBackgroundAlt, in: Circle())
                .overlay(Circle().stroke(isSelected ? Theme.water : Color.clear, lineWidth: 2))

            Text(size.label)
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textSecondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                selectedSize = size.rawValue
                selectedDrinkType = .water
            }
            onClose()
        }
    }

    private var addCustomCell: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 56, height: 56)
                .background(Theme.cardBackgroundAlt, in: Circle())
            Text("Add New")
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func drinkCell(_ type: DrinkType) -> some View {
        let isSelected = selectedDrinkType == type
        return VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundStyle(type.tint)
                .frame(width: 56, height: 56)
                .background(Theme.cardBackgroundAlt, in: Circle())
                .overlay(Circle().stroke(isSelected ? type.tint : Color.clear, lineWidth: 2))

            Text(type.label)
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                selectedDrinkType = type
            }
            onClose()
        }
    }
}
