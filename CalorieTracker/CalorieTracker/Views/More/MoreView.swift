import SwiftUI
import SwiftData

struct ShareFile: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \MealEntry.timestamp) private var mealEntries: [MealEntry]
    @Query(sort: \ExerciseEntry.timestamp) private var exerciseEntries: [ExerciseEntry]
    @Query(sort: \WeightLogEntry.date) private var weightEntries: [WeightLogEntry]
    @Query private var waterEntries: [WaterLogEntry]

    @State private var showingLogWeight = false
    @State private var showingResetConfirm = false
    @State private var shareItem: ShareFile?

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let created = UserProfile()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar()
                moreList
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingLogWeight) {
            LogWeightSheet(
                initialWeight: profile.weightKg,
                onClose: { showingLogWeight = false },
                onSave: { newWeight, date in
                    profile.weightKg = newWeight
                    modelContext.insert(WeightLogEntry(weightKg: newWeight, date: date))
                    try? modelContext.save()
                    showingLogWeight = false
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
        .confirmationDialog("Reset today's log?", isPresented: $showingResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { resetToday() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all food and water entries logged today. This can't be undone.")
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    private var moreList: some View {
            List {
                Section {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        HStack {
                            AppLogoMark(size: 48)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(String(format: "%.1f", profile.weightKg))kg")
                                    .font(Theme.Font.text(15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Goal: \(String(format: "%.1f", profile.targetWeightKg))kg")
                                    .font(Theme.Font.text(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.cardBackground)
                }

                Section("Goals") {
                    NavigationLink {
                        GoalsSettingsView()
                    } label: {
                        moreRow(icon: "flag", label: "Calorie & Macro Goals")
                    }
                    .listRowBackground(Theme.cardBackground)

                    NavigationLink {
                        WaterExerciseGoalsView()
                    } label: {
                        moreRow(icon: "drop", label: "Water & Exercise Goals")
                    }
                    .listRowBackground(Theme.cardBackground)

                    Button {
                        showingLogWeight = true
                    } label: {
                        moreRow(icon: "scalemass", label: "Log Weight")
                    }
                    .listRowBackground(Theme.cardBackground)
                }

                Section("Preferences") {
                    HStack {
                        moreRow(icon: "moon", label: "Appearance")
                        Spacer()
                        Picker("", selection: appearanceBinding) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.accent)
                    }
                    .listRowBackground(Theme.cardBackground)

                    NavigationLink {
                        APIKeySettingsView()
                    } label: {
                        moreRow(icon: "key", label: "Gemini API Key")
                    }
                    .listRowBackground(Theme.cardBackground)
                }

                Section("Data") {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        moreRow(icon: "list.bullet.rectangle", label: "View All Logs")
                    }
                    .listRowBackground(Theme.cardBackground)

                    Button {
                        exportData()
                    } label: {
                        moreRow(icon: "square.and.arrow.up", label: "Export Data (CSV)")
                    }
                    .listRowBackground(Theme.cardBackground)

                    Button {
                        showingResetConfirm = true
                    } label: {
                        moreRow(icon: "arrow.counterclockwise", label: "Reset Today's Log", tint: Theme.danger)
                    }
                    .listRowBackground(Theme.cardBackground)
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        moreRow(icon: "info.circle", label: "About & Help")
                    }
                    .listRowBackground(Theme.cardBackground)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.groupedBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 60) }
    }

    private func exportData() {
        if let url = DataExportService.exportCSV(meals: mealEntries, exercise: exerciseEntries, weight: weightEntries, water: waterEntries) {
            shareItem = ShareFile(url: url)
        }
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(get: { profile.appearance }, set: { profile.appearance = $0; try? modelContext.save() })
    }

    private func moreRow(icon: String, label: String, tint: Color = Theme.textPrimary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint == Theme.textPrimary ? Theme.accent : tint)
                .frame(width: 24)
            Text(label)
                .font(Theme.Font.text(14))
                .foregroundStyle(tint)
        }
        .padding(.vertical, 4)
    }

    private func resetToday() {
        let cal = Calendar.current
        let fetch = FetchDescriptor<MealEntry>()
        if let entries = try? modelContext.fetch(fetch) {
            for entry in entries where cal.isDateInToday(entry.timestamp) {
                modelContext.delete(entry)
            }
        }
        let waterFetch = FetchDescriptor<WaterLogEntry>()
        if let waters = try? modelContext.fetch(waterFetch) {
            for w in waters where cal.isDateInToday(w.date) {
                modelContext.delete(w)
            }
        }
        try? modelContext.save()
    }
}
