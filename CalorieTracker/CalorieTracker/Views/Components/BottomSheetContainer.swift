import SwiftUI

struct BottomSheetContainer<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    /// When true, the card surface uses a translucent glass material instead
    /// of the opaque card background — useful when the sheet's fixed detent
    /// height leaves extra space below the content, so that leftover area
    /// blends with the dimmed backdrop instead of showing as an opaque block.
    var translucent: Bool = false
    let onClose: () -> Void
    @ViewBuilder let content: Content

    // A large-detent sheet's native drag-to-dismiss competes with any
    // ScrollView inside it (the scroll view's own pan gesture wins once the
    // touch starts over scrollable content), so swiping down from within the
    // content often doesn't dismiss. This gives the grabber/header a
    // guaranteed drag-to-dismiss area that always works regardless of what's
    // happening in the content below.
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false

    private var headerDragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                guard value.translation.height > 0 else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                if value.translation.height > 80 || value.predictedEndTranslation.height > 200 {
                    onClose()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { dragOffset = 0 }
                }
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.textPrimary.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack(alignment: subtitle == nil ? .center : .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.Font.display(18))
                        .foregroundStyle(Theme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, height: 30)
                        .glassCardAlt(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .contentShape(Rectangle())
            .gesture(headerDragGesture)

            content
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

            Spacer(minLength: 0)
        }
        .offset(y: dragOffset)
        .animation(isDragging ? nil : .spring(response: 0.3, dampingFraction: 0.85), value: dragOffset)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background {
            if !translucent {
                Theme.cardBackground
            }
        }
        .clipShape(
            UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.sheet, topTrailingRadius: Theme.Radius.sheet)
        )
        .ignoresSafeArea(edges: .bottom)
        .shadow(color: Color.black.opacity(translucent ? 0 : 0.06), radius: 10, x: 0, y: 4)
    }
}
