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
    /// When false, omits the "Month Year" label + prev/next chevrons, showing
    /// just the week row — for callers that build their own header above it.
    var showsHeader: Bool = true
    /// When false, omits the card background/padding so a caller can merge
    /// this strip visually with its own surrounding card.
    var wrapsInCard: Bool = true
    /// Color used for the selected day (text, ring stroke, highlight fill).
    /// Defaults to the app's green accent; callers can override to match a
    /// feature's own color (e.g. blue for the water screen).
    var tint: Color = Theme.accent
    var tintSoft: Color = Theme.accentSoft
    var tintGradient: LinearGradient = Theme.accentGradient

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
            if showsHeader {
                HStack {
                    Text(monthLabel(for: visibleWeekStart))
                        .font(Theme.Font.display(20))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    navButton(icon: "chevron.left") { shiftVisibleWeek(by: -1) }
                    navButton(icon: "chevron.right") { shiftVisibleWeek(by: 1) }
                }
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
        .modifier(OptionalCardWrap(wraps: wrapsInCard))
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
                .foregroundStyle(isSelected ? tint : Theme.textFaint)

            ZStack {
                RingGaugeView(
                    progress: isFuture ? 0 : dayProgress,
                    lineWidth: 2.5,
                    trackColor: Theme.hairline,
                    progressGradient: tintGradient
                )
                Text("\(calendar.component(.day, from: day))")
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(isSelected ? tint : (isFuture ? Theme.textFaint : Theme.textPrimary))
            }
            .frame(width: 34, height: 34)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? tintSoft : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? tint : Color.clear, lineWidth: 1.5)
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

private struct OptionalCardWrap: ViewModifier {
    let wraps: Bool

    func body(content: Content) -> some View {
        if wraps {
            content
                .padding(16)
                .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
                .padding(.horizontal, 16)
        } else {
            content
        }
    }
}
