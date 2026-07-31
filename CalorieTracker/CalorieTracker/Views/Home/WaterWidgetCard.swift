import SwiftUI
import SwiftData

struct WaterWidgetCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var waterEntries: [WaterLogEntry]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile { profiles.first ?? UserProfile() }

    private var todaysWater: [WaterLogEntry] {
        let cal = Calendar.current
        return waterEntries.filter { cal.isDateInToday($0.date) }
    }

    private var waterMl: Int { todaysWater.reduce(0) { $0 + $1.milliliters } }

    private var fraction: Double {
        min(1, Double(waterMl) / Double(max(1, profile.waterGoalMl)))
    }

    private var waterGradient: LinearGradient {
        LinearGradient(colors: [Theme.water, Color(hex: 0x1E6FA8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("💧")
                        .font(.system(size: 14))
                    Text("Water")
                        .font(Theme.Font.text(13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(litersString(waterMl))
                        .font(Theme.Font.display(24))
                        .foregroundStyle(Theme.textPrimary)
                    Text("/ \(litersString(profile.waterGoalMl))L")
                        .font(Theme.Font.text(12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer(minLength: 0)

            ZStack {
                RingGaugeView(progress: fraction, lineWidth: 8, progressGradient: waterGradient)
                Text("\(Int(fraction * 100))%")
                    .font(Theme.Font.text(12, weight: .bold))
                    .foregroundStyle(Theme.water)
            }
            .frame(width: 56, height: 56)

            Button(action: addWater) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.onWater)
                    .frame(width: 32, height: 32)
                    .background(Theme.water, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private func litersString(_ ml: Int) -> String {
        String(format: "%.1f", Double(ml) / 1000)
    }

    private func addWater() {
        let entry = WaterLogEntry(milliliters: 250)
        modelContext.insert(entry)
        try? modelContext.save()
    }
}
