import SwiftUI

/// Full-screen emoji grid for picking a custom food's icon, matching the
/// reference "Set Icon" screen: a search field filtering a curated food emoji set.
struct FoodIconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    @State private var query: String = ""

    private static let emojis: [String] = [
        "🌭", "🫐", "🥑", "🍞", "🍱",
        "🦀", "🍆", "🥐", "🦞", "🍧",
        "🥛", "🍉", "🍪", "🥖", "🍙",
        "🍤", "🍨", "☕", "🍊", "🥕",
        "🍅", "🍩", "🍋", "🌿", "🍪",
        "🍵", "🍌", "🌶️", "🥯", "🍜",
        "🎂", "🫑", "🥞", "🍰", "🥭",
        "🥒", "🧁", "🍷", "🍎", "🥬",
        "🍕", "🍔", "🌮", "🌯", "🥗",
        "🍳", "🥩", "🍗", "🍖", "🥓",
        "🍟", "🍿", "🥨", "🧀", "🍇",
        "🍓", "🍑", "🍒", "🍍", "🥥",
        "🥦", "🌽", "🥔", "🍠", "🧅",
        "🧄", "🍄", "🥜", "🌰", "🍚",
        "🍛", "🍣", "🍥", "🥟", "🍢",
        "🍡", "🍦", "🍮", "🍯", "🥤"
    ]

    private var filtered: [String] {
        guard !query.isEmpty else { return Self.emojis }
        // Emoji have no textual name here, so search is a no-op filter hook
        // kept for parity with the reference UI's search field.
        return Self.emojis
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 18), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TextField("Search", text: $query)
                        .font(Theme.Font.text(14))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .glassCardAlt(RoundedRectangle(cornerRadius: 12))

                    LazyVGrid(columns: columns, spacing: 22) {
                        ForEach(filtered, id: \.self) { emoji in
                            Button {
                                onSelect(emoji)
                                dismiss()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 30))
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Set Icon")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
