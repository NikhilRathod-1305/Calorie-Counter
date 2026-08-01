import SwiftUI

/// Expandable month calendar: prev/next month header with a Mon–Sun grid of
/// day cells, each showing a progress ring (e.g. that day's hydration goal
/// completion). Used underneath a week strip for a "peek a whole month" view.
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    var progress: (Date) -> Double = { _ in 0 }
    /// Color used for the selected day and progress rings. Defaults to the
    /// app's green accent; callers can override to match a feature's own
    /// color (e.g. blue for the water screen).
    var tint: Color = Theme.accent
    var tintSoft: Color = Theme.accentSoft
    var tintGradient: LinearGradient = Theme.accentGradient

    @State private var visibleMonth: Date

    private let calendar = Calendar.current

    init(
        selectedDate: Binding<Date>,
        progress: @escaping (Date) -> Double = { _ in 0 },
        tint: Color = Theme.accent,
        tintSoft: Color = Theme.accentSoft,
        tintGradient: LinearGradient = Theme.accentGradient
    ) {
        self._selectedDate = selectedDate
        self.progress = progress
        self.tint = tint
        self.tintSoft = tintSoft
        self.tintGradient = tintGradient
        self._visibleMonth = State(initialValue: selectedDate.wrappedValue)
    }

    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstOfMonth = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        // Weekday is 1=Sun...7=Sat; convert to Monday-first leading blank count.
        let leadingBlanks = (weekday + 5) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: visibleMonth)?.count ?? 30

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        days += (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: firstOfMonth) }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(monthLabel(for: visibleMonth))
                    .font(Theme.Font.display(17))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                navButton(icon: "chevron.left") { shiftMonth(by: -1) }
                navButton(icon: "chevron.right") { shiftMonth(by: 1) }
            }

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(Theme.Font.text(11, weight: .medium))
                        .foregroundStyle(Theme.textFaint)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
        .onChange(of: selectedDate) { _, newValue in
            if !calendar.isDate(newValue, equalTo: visibleMonth, toGranularity: .month) {
                visibleMonth = newValue
            }
        }
    }

    private var weekdaySymbols: [String] { ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func shiftMonth(by months: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            visibleMonth = calendar.date(byAdding: .month, value: months, to: visibleMonth) ?? visibleMonth
        }
    }

    private func navButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 32, height: 32)
                .background(Theme.cardBackgroundAlt, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isFuture = day > calendar.startOfDay(for: Date())
        let dayProgress = progress(day)

        return ZStack {
            RingGaugeView(
                progress: isFuture ? 0 : dayProgress,
                lineWidth: 2.5,
                trackColor: Theme.hairline,
                progressGradient: tintGradient
            )
            Text("\(calendar.component(.day, from: day))")
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(isSelected ? tint : (isFuture ? Theme.textFaint : Theme.textPrimary))
        }
        .frame(height: 34)
        .opacity(isFuture ? 0.4 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isFuture else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                selectedDate = day
            }
        }
    }
}
