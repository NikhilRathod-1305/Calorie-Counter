import SwiftUI

struct PillSegmentedControl<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T
    var style: Style = .filled

    enum Style {
        case filled
        case outlined
    }

    var body: some View {
        switch style {
        case .filled:
            HStack(spacing: 0) {
                ForEach(options, id: \.value) { option in
                    segmentButton(option)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
        case .outlined:
            HStack(spacing: 8) {
                ForEach(options, id: \.value) { option in
                    outlinedButton(option)
                }
            }
        }
    }

    @ViewBuilder
    private func segmentButton(_ option: (value: T, label: String)) -> some View {
        let isSelected = option.value == selection
        Text(option.label)
            .font(Theme.Font.text(11, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Theme.onAccent : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(isSelected ? Theme.accent : .clear)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selection = option.value
                }
            }
    }

    @ViewBuilder
    private func outlinedButton(_ option: (value: T, label: String)) -> some View {
        let isSelected = option.value == selection
        Text(option.label)
            .font(Theme.Font.text(11, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selection = option.value
                }
            }
    }
}
