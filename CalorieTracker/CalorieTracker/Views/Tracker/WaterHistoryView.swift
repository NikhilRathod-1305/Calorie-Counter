import SwiftUI
import SwiftData

struct WaterHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterLogEntry.date, order: .reverse) private var waterEntries: [WaterLogEntry]

    @State private var editingEntry: WaterLogEntry?
    @State private var showingJumpToDate = false
    @State private var jumpDate = Date()
    @State private var toastMessage: String?
    @State private var lastDeleted: (milliliters: Int, date: Date, drinkType: DrinkType)?

    // Cached instead of recomputed in a plain `var` — this view re-renders on every
    // pixel of a swipe-to-delete drag (via SwipeToDeleteRow's @State offset), and
    // without caching that meant re-grouping/re-sorting all entries every frame.
    @State private var cachedGroups: [(label: String, entries: [WaterLogEntry])] = []

    private let calendar = Calendar.current

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private func regroupEntries() {
        let groups = Dictionary(grouping: waterEntries) { calendar.startOfDay(for: $0.date) }
        cachedGroups = groups.keys.sorted(by: >).map { day in
            let label: String
            if calendar.isDateInToday(day) { label = "Today, \(dateString(day))" }
            else if calendar.isDateInYesterday(day) { label = "Yesterday, \(dateString(day))" }
            else { label = dateString(day) }
            return (label, groups[day]?.sorted { $0.date > $1.date } ?? [])
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if cachedGroups.isEmpty {
                    Text("No water logged yet")
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textFaint)
                        .padding(.top, 60)
                } else {
                    ForEach(cachedGroups, id: \.label) { group in
                        dayGroup(label: group.label, entries: group.entries)
                    }
                }
                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Water Intake History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingJumpToDate = true
                } label: {
                    Image(systemName: "calendar")
                }
            }
        }
        .onAppear { regroupEntries() }
        .onChange(of: waterEntries) { _, _ in regroupEntries() }
        .toast(toastMessage, actionTitle: lastDeleted != nil ? "Undo" : nil, action: undoDelete)
        .sheet(item: $editingEntry) { entry in
            LogWaterSheet(
                editingEntry: entry,
                onClose: { editingEntry = nil },
                onSave: { ml, date in
                    entry.milliliters = ml
                    entry.date = date
                    try? modelContext.save()
                    editingEntry = nil
                }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingJumpToDate) {
            NavigationStack {
                VStack {
                    MonthCalendarView(selectedDate: $jumpDate)
                        .padding(16)
                }
                .navigationTitle("Jump to Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showingJumpToDate = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func dayGroup(label: String, entries: [WaterLogEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textFaint)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    row(for: entry)
                    if index < entries.count - 1 {
                        Divider().overlay(Theme.hairline.opacity(0.6)).padding(.leading, 58)
                    }
                }
            }
            .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }

    private func row(for entry: WaterLogEntry) -> some View {
        SwipeToDeleteRow(
            onTap: { editingEntry = entry },
            onDelete: { delete(entry) }
        ) {
            HStack(spacing: 12) {
                DrinkIconBadge(type: entry.drinkType, milliliters: entry.milliliters)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.drinkType.label)
                        .font(Theme.Font.text(13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(timeString(entry.date))
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Text("\(entry.milliliters) mL")
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private func delete(_ entry: WaterLogEntry) {
        lastDeleted = (entry.milliliters, entry.date, entry.drinkType)
        modelContext.delete(entry)
        try? modelContext.save()
        showToast("History deleted!")
    }

    private func undoDelete() {
        guard let lastDeleted else { return }
        let restored = WaterLogEntry(milliliters: lastDeleted.milliliters, date: lastDeleted.date, drinkType: lastDeleted.drinkType)
        modelContext.insert(restored)
        try? modelContext.save()
        self.lastDeleted = nil
        withAnimation { toastMessage = nil }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            guard toastMessage == message else { return }
            withAnimation { toastMessage = nil }
            lastDeleted = nil
        }
    }

    private func timeString(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }
}
