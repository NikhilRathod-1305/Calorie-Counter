import SwiftUI

struct SwipeToDeleteRow<Content: View>: View {
    let onTap: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @State private var showingDeleteConfirm = false
    @State private var isHorizontalDrag: Bool?

    private let deleteWidth: CGFloat = 76
    private let revealThreshold: CGFloat = 40

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Button {
                    showingDeleteConfirm = true
                } label: {
                    Text("Delete")
                        .font(Theme.Font.text(13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: deleteWidth)
                        .frame(maxHeight: .infinity)
                        .background(Theme.danger)
                }
                .buttonStyle(.plain)
            }
            .opacity(offset < 0 ? 1 : 0)

            content
                .background(Theme.cardBackground)
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            if isHorizontalDrag == nil {
                                isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height) * 1.5
                            }
                            guard isHorizontalDrag == true else { return }
                            guard value.translation.width < 0 else {
                                offset = 0
                                return
                            }
                            offset = max(value.translation.width, -deleteWidth)
                        }
                        .onEnded { value in
                            defer { isHorizontalDrag = nil }
                            guard isHorizontalDrag == true else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { offset = 0 }
                                return
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                offset = value.translation.width < -revealThreshold ? -deleteWidth : 0
                            }
                        }
                )
                .onTapGesture {
                    if offset != 0 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { offset = 0 }
                    } else {
                        onTap()
                    }
                }
        }
        .clipShape(Rectangle())
        .confirmationDialog("Delete this entry?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { offset = 0 }
                onDelete()
            }
            Button("Cancel", role: .cancel) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { offset = 0 }
            }
        }
    }
}
