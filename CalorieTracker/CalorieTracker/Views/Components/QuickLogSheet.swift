import SwiftUI
import SwiftData

struct QuickLogSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    let onClose: () -> Void
    let onAdded: () -> Void

    @State private var activeMode: LogMode?
    @State private var showingWorkout = false
    @State private var showingWater = false

    private var profile: UserProfile { profiles.first ?? UserProfile() }

    var body: some View {
        BottomSheetContainer(title: "Quick Log", subtitle: "Choose an entry type", onClose: onClose) {
            GlassEffectContainer(spacing: 10) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    emojiTile(emoji: "🍽️", label: "Log Food", color: Theme.secondary) { activeMode = .browse }
                    tile(icon: "barcode.viewfinder", label: "Barcode Scan", color: Theme.secondary) { activeMode = .barcode }
                    emojiTile(emoji: "🎙️", label: "Voice Log", color: Theme.secondary) { activeMode = .voice }
                    emojiTile(emoji: "📸", label: "Scan Meal", color: Theme.secondary) { activeMode = .scan }
                    emojiTile(emoji: "💧", label: "Water", color: Theme.water) { showingWater = true }
                    emojiTile(emoji: "🏃", label: "Workout", color: Theme.exercise) { showingWorkout = true }
                }
            }
            .padding(.bottom, 8)
        }
        .fullScreenCover(item: $activeMode) { mode in
            LogFoodSheet(
                initialMode: mode,
                onClose: { activeMode = nil },
                onAdded: {
                    activeMode = nil
                    onAdded()
                }
            )
        }
        .sheet(isPresented: $showingWorkout) {
            LogExerciseSheet(
                onClose: { showingWorkout = false },
                onSave: { name, calories, duration in
                    let entry = ExerciseEntry(name: name, caloriesBurned: calories, durationMinutes: duration, timestamp: Date())
                    modelContext.insert(entry)
                    try? modelContext.save()
                    showingWorkout = false
                    onAdded()
                }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $showingWater) {
            LogWaterView(
                goalMl: profile.waterGoalMl,
                onClose: { showingWater = false },
                onSave: { ml, date in
                    let entry = WaterLogEntry(milliliters: ml, date: date)
                    modelContext.insert(entry)
                    try? modelContext.save()
                    showingWater = false
                    onAdded()
                }
            )
        }
    }

    private func tile(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                Text(label)
                    .font(Theme.Font.text(13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .glassCardAlt(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .buttonStyle(.plain)
    }

    private func emojiTile(emoji: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                Text(label)
                    .font(Theme.Font.text(13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .glassCardAlt(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .buttonStyle(.plain)
    }
}

extension LogMode: Identifiable {
    public var id: String { rawValue }
}
