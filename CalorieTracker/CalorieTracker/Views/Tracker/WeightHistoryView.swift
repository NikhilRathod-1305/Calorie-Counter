import SwiftUI
import SwiftData

struct WeightHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightLogEntry.date, order: .reverse) private var weightEntries: [WeightLogEntry]
    @Query private var profiles: [UserProfile]

    @State private var editingEntry: WeightLogEntry?
    @State private var showingJumpToDate = false
    @State private var jumpDate = Date()
    @State private var toastMessage: String?
    @State private var lastDeleted: (weightKg: Double, date: Date)?

    private let calendar = Calendar.current
    private var profile: UserProfile { profiles.first ?? UserProfile() }

    /// Entries sorted oldest-first, used to compute each row's delta from the entry logged before it.
    private var chronological: [WeightLogEntry] {
        weightEntries.sorted { $0.date < $1.date }
    }

    private func delta(for entry: WeightLogEntry) -> Double? {
        guard let index = chronological.firstIndex(where: { $0.id == entry.id }), index > 0 else { return nil }
        return entry.weightKg - chronological[index - 1].weightKg
    }

    private var groupedEntries: [(label: String, entries: [WeightLogEntry])] {
        let groups = Dictionary(grouping: weightEntries) { calendar.startOfDay(for: $0.date) }
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
                    Text("No weight logged yet")
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
        .navigationTitle("Weight History")
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
        .toast(toastMessage, actionTitle: lastDeleted != nil ? "Undo" : nil, action: undoDelete)
        .sheet(item: $editingEntry) { entry in
            LogWeightSheet(
                initialWeight: entry.weightKg,
                editingEntry: entry,
                onClose: { editingEntry = nil },
                onSave: { newWeight, date in
                    entry.weightKg = newWeight
                    entry.date = date
                    if entry.id == weightEntries.first?.id {
                        profile.weightKg = newWeight
                    }
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

    private func dayGroup(label: String, entries: [WeightLogEntry]) -> some View {
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

    private func row(for entry: WeightLogEntry) -> some View {
        let change = delta(for: entry)
        return SwipeToDeleteRow(
            onTap: { editingEntry = entry },
            onDelete: { delete(entry) }
        ) {
            HStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 36, height: 36)
                    .background(Theme.cardBackgroundAlt, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f kg", entry.weightKg))
                        .font(Theme.Font.text(13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(timeString(entry.date))
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                if let change, change != 0 {
                    changePill(change)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private func changePill(_ change: Double) -> some View {
        let isDown = change < 0
        return HStack(spacing: 3) {
            Image(systemName: isDown ? "arrow.down" : "arrow.up")
                .font(.system(size: 9, weight: .bold))
            Text(String(format: "%.1f kg", abs(change)))
                .font(Theme.Font.text(12, weight: .semibold))
        }
        .foregroundStyle(isDown ? Theme.success : Theme.danger)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isDown ? Theme.success : Theme.danger).opacity(0.15), in: Capsule())
    }

    private func delete(_ entry: WeightLogEntry) {
        lastDeleted = (entry.weightKg, entry.date)
        modelContext.delete(entry)
        try? modelContext.save()
        if let mostRecent = weightEntries.first(where: { $0.id != entry.id }) {
            profile.weightKg = mostRecent.weightKg
        }
        showToast("History deleted!")
    }

    private func undoDelete() {
        guard let lastDeleted else { return }
        let restored = WeightLogEntry(weightKg: lastDeleted.weightKg, date: lastDeleted.date)
        modelContext.insert(restored)
        if lastDeleted.date >= weightEntries.first?.date ?? .distantPast {
            profile.weightKg = lastDeleted.weightKg
        }
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
