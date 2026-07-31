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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.water)
                Text("Water")
                    .font(Theme.Font.text(13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Button(action: addWater) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.water)
                        .frame(width: 30, height: 30)
                        .glassCardAlt(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(litersString(waterMl))
                    .font(Theme.Font.display(22))
                    .foregroundStyle(Theme.textPrimary)
                Text("Liters / \(litersString(profile.waterGoalMl))L")
                    .font(Theme.Font.text(12))
                    .foregroundStyle(Theme.textTertiary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.hairline)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.water)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
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
