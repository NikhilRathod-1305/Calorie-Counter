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

    private let calendar = Calendar.current

    private var groupedEntries: [(label: String, entries: [WaterLogEntry])] {
        let groups = Dictionary(grouping: waterEntries) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
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
                if groupedEntries.isEmpty {
                    Text("No water logged yet")
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textFaint)
                        .padding(.top, 60)
                } else {
                    ForEach(groupedEntries, id: \.label) { group in
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
        .hidesTabBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingJumpToDate = true
                } label: {
                    Image(systemName: "calendar")
                }
            }
        }
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
                Image(systemName: entry.drinkType.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(entry.drinkType.tint)
                    .frame(width: 36, height: 36)
                    .background(Theme.cardBackgroundAlt, in: Circle())

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
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}
