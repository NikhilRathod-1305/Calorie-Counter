import SwiftUI

/// Week-at-a-time date picker matching the reference: bold month/year title with
/// prev/next chevron buttons, and a swipeable Mon–Sun row of day cells below —
/// each showing a small progress ring (e.g. calorie goal completion for that day).
///
/// Swiping/paging only changes which week is *visible* — it never changes
/// `selectedDate` on its own. The selected date only changes when the user taps
/// a specific day, even if that day is now scrolled out of view.
struct DateStripPicker: View {
    @Binding var selectedDate: Date
    /// Returns 0...1 progress for a given day, used to draw that day's ring.
    var progress: (Date) -> Double = { _ in 0 }

    @State private var visibleWeekOffset: Int = 0

    private let calendar = Calendar.current
    private let weekOffsetRange = -520...520 // ~10 years back/forward

    private var referenceWeekStart: Date {
        calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    private var visibleWeekStart: Date {
        weekStart(atOffset: visibleWeekOffset)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(monthLabel(for: visibleWeekStart))
                    .font(Theme.Font.display(20))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                navButton(icon: "chevron.left") { shiftVisibleWeek(by: -1) }
                navButton(icon: "chevron.right") { shiftVisibleWeek(by: 1) }
            }

            TabView(selection: $visibleWeekOffset) {
                ForEach(weekOffsetRange, id: \.self) { offset in
                    weekRow(for: weekStart(atOffset: offset))
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 76)
        }
        .padding(16)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .padding(.horizontal, 16)
        .onAppear {
            visibleWeekOffset = weekOffset(for: selectedDate)
        }
    }

    private func weekOffset(for date: Date) -> Int {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return calendar.dateComponents([.weekOfYear], from: referenceWeekStart, to: weekStart).weekOfYear ?? 0
    }

    private func weekStart(atOffset offset: Int) -> Date {
        calendar.date(byAdding: .weekOfYear, value: offset, to: referenceWeekStart) ?? referenceWeekStart
    }

    private func weekDays(from weekStart: Date) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func weekRow(for weekStart: Date) -> some View {
        HStack(spacing: 6) {
            ForEach(weekDays(from: weekStart), id: \.self) { day in
                dayCell(day)
            }
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

    private func shiftVisibleWeek(by weeks: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            visibleWeekOffset += weeks
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isFuture = day > calendar.startOfDay(for: Date())
        let dayProgress = progress(day)

        return VStack(spacing: 6) {
            Text(weekdayLabel(day))
                .font(Theme.Font.text(11, weight: .medium))
                .foregroundStyle(isSelected ? Theme.accent : Theme.textFaint)

            ZStack {
                RingGaugeView(
                    progress: isFuture ? 0 : dayProgress,
                    lineWidth: 2.5,
                    trackColor: Theme.hairline,
                    progressGradient: Theme.accentGradient
                )
                Text("\(calendar.component(.day, from: day))")
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.accent : (isFuture ? Theme.textFaint : Theme.textPrimary))
            }
            .frame(width: 34, height: 34)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Theme.accentSoft : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Theme.accent : Color.clear, lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .opacity(isFuture ? 0.4 : 1)
        .onTapGesture {
            guard !isFuture else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                selectedDate = day
            }
        }
    }

    private func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
