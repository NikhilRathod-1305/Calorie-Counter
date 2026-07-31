import SwiftUI

struct LogWaterView: View {
    let goalMl: Int
    let onClose: () -> Void
    let onSave: (Int, Date) -> Void

    @State private var milliliters: Int
    @State private var date: Date = Date()
    @State private var time: Date = Date()
    @State private var showingCustomEntry = false

    init(goalMl: Int, initialMilliliters: Int = 0, onClose: @escaping () -> Void, onSave: @escaping (Int, Date) -> Void) {
        self.goalMl = goalMl
        self.onClose = onClose
        self.onSave = onSave
        _milliliters = State(initialValue: initialMilliliters)
    }

    private var fraction: Double {
        min(1, Double(milliliters) / 1000)
    }

    private var combinedDate: Date {
        let cal = Calendar.current
        let dayComponents = cal.dateComponents([.year, .month, .day], from: date)
        let timeComponents = cal.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = dayComponents.year
        merged.month = dayComponents.month
        merged.day = dayComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        return cal.date(from: merged) ?? Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 34, height: 34)
                        .glassCardAlt(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Log Water")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 28) {
                    bottleVisual
                        .padding(.top, 12)

                    VStack(spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(milliliters)")
                                .font(Theme.Font.display(44))
                                .foregroundStyle(Theme.textPrimary)
                            Text("ml")
                                .font(Theme.Font.text(16))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Text("GOAL: \(goalMl)ML")
                            .font(Theme.Font.text(11, weight: .medium))
                            .foregroundStyle(Theme.textFaint)
                            .tracking(0.5)
                    }

                    VStack(spacing: 6) {
                        Slider(value: Binding(
                            get: { Double(milliliters) },
                            set: { milliliters = Int($0) }
                        ), in: 0...1000, step: 10)
                        .tint(Theme.water)

                        HStack {
                            Text("0")
                            Spacer()
                            Text("1000ml")
                        }
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textFaint)
                    }
                    .padding(.horizontal, 4)

                    HStack(spacing: 10) {
                        presetButton(amount: 100, emoji: "💧")
                        presetButton(amount: 250, emoji: "☕")
                        presetButton(amount: 500, emoji: "🍶")
                        customButton
                    }

                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                                .labelsHidden()
                                .tint(Theme.water)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .glassCardAlt(RoundedRectangle(cornerRadius: 14))

                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(Theme.water)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .glassCardAlt(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onSave(milliliters, combinedDate)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log Water")
                        }
                        .font(Theme.Font.text(15, weight: .semibold))
                        .foregroundStyle(Theme.onWater)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.water, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(milliliters <= 0)

                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
    }

    private var bottleVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Theme.hairline, lineWidth: 2)
                .frame(width: 150, height: 210)

            WaterWaveShape(fraction: fraction)
                .fill(
                    LinearGradient(
                        colors: [Theme.water.opacity(0.75), Theme.water.opacity(0.4)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 146, height: 206)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: fraction)

            VStack {
                ForEach(1..<4, id: \.self) { i in
                    if i > 1 { Spacer() }
                    HStack {
                        Rectangle().fill(Theme.hairline.opacity(0.6)).frame(width: 8, height: 1)
                        Spacer()
                    }
                }
                Spacer()
            }
            .frame(width: 150, height: 190)
            .padding(.top, 10)
        }
    }

    private func presetButton(amount: Int, emoji: String) -> some View {
        Button {
            milliliters = min(1000, milliliters + amount)
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 16))
                Text("+\(amount)")
                    .font(Theme.Font.text(12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCardAlt(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var customButton: some View {
        Button {
            showingCustomEntry = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.accent)
                Text("Custom")
                    .font(Theme.Font.text(12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCardAlt(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .alert("Custom amount", isPresented: $showingCustomEntry) {
            TextField("ml", value: $milliliters, format: .number)
                .keyboardType(.numberPad)
            Button("Set") {}
            Button("Cancel", role: .cancel) {}
        }
    }
}
