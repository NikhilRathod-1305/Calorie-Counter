import SwiftUI

/// Card housing a week `DateStripPicker` that expands into a full `MonthCalendarView`.
/// Toggling happens by tapping the chevron, or by dragging it down (to expand) /
/// up (to collapse) — the same interaction as the reference step tracker screen.
struct ExpandableDateHeader: View {
    @Binding var selectedDate: Date
    var progress: (Date) -> Double = { _ in 0 }
    var tint: Color = Theme.accent
    var tintSoft: Color = Theme.accentSoft
    var tintGradient: LinearGradient = Theme.accentGradient

    @State private var isExpanded = false
    @State private var dragTranslation: CGFloat = 0

    private let dragActivationDistance: CGFloat = 28

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                MonthCalendarView(
                    selectedDate: $selectedDate,
                    progress: progress,
                    tint: tint,
                    tintSoft: tintSoft,
                    tintGradient: tintGradient
                )
                .padding(16)
                .padding(.bottom, 4)
                .transition(.opacity)
            } else {
                DateStripPicker(
                    selectedDate: $selectedDate,
                    progress: progress,
                    showsHeader: false,
                    wrapsInCard: false,
                    tint: tint,
                    tintSoft: tintSoft,
                    tintGradient: tintGradient
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 4)
                .transition(.opacity)
            }

            chevronHandle
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var chevronHandle: some View {
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.textFaint)
            .frame(width: 60, height: 28)
            .contentShape(Rectangle())
            .rotationEffect(.degrees(dragTranslation * 1.2))
            .offset(y: dragTranslation)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            .onTapGesture { setExpanded(!isExpanded) }
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .local)
                    .onChanged { value in
                        // Rubber-band toward the drag with diminishing return near the clamp,
                        // and ease continuously each frame instead of snapping.
                        let rawOffset = value.translation.height / 2
                        let maxOffset: CGFloat = 16
                        let eased = maxOffset * tanh(rawOffset / maxOffset)
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7)) {
                            dragTranslation = eased
                        }
                    }
                    .onEnded { value in
                        let shouldExpand = value.translation.height > dragActivationDistance
                        let shouldCollapse = value.translation.height < -dragActivationDistance
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragTranslation = 0
                        }
                        if shouldExpand {
                            setExpanded(true)
                        } else if shouldCollapse {
                            setExpanded(false)
                        }
                    }
            )
    }

    private func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isExpanded = expanded
        }
    }
}
