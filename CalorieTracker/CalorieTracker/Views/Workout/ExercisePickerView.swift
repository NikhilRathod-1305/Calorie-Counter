import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    enum Mode {
        case add    // adding to an active workout — tapping picks and closes
        case browse // pure discovery — tapping shows detail, no pick action
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    let mode: Mode
    let onClose: () -> Void
    let onPick: (Exercise) -> Void

    @State private var searchText = ""
    @State private var categoryFilter: ExerciseCategory?
    @State private var showingCreateExercise = false
    @State private var detailExercise: Exercise?

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = categoryFilter == nil || exercise.categoryValue == categoryFilter
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(nil, label: "All")
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            categoryChip(category, label: category.rawValue)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)

                List {
                    ForEach(filtered) { exercise in
                        exerciseRow(exercise)
                    }
                }
                .listStyle(.plain)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showingCreateExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateExercise) {
            CreateExerciseSheet(onClose: { showingCreateExercise = false }, onCreated: { exercise in
                showingCreateExercise = false
                if mode == .add { onPick(exercise) }
            })
        }
        .sheet(item: $detailExercise) { exercise in
            ExerciseDetailSheet(exercise: exercise, onClose: { detailExercise = nil })
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textTertiary)
            TextField("Search exercises", text: $searchText)
                .font(Theme.Font.text(15))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCardAlt(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func categoryChip(_ category: ExerciseCategory?, label: String) -> some View {
        let isSelected = categoryFilter == category
        return Text(label)
            .font(Theme.Font.text(12, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Theme.onAccent : Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.accent : Theme.cardBackgroundAlt, in: Capsule())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { categoryFilter = category }
            }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button {
            if mode == .add {
                onPick(exercise)
            } else {
                detailExercise = exercise
            }
        } label: {
            HStack(spacing: 12) {
                Text(exercise.emoji)
                    .font(.system(size: 22))
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(Theme.Font.text(14, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(exercise.muscleGroupValues.map(\.rawValue).joined(separator: ", "))
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                if mode == .add {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Theme.groupedBackground)
        .listRowSeparatorTint(Theme.hairline)
    }
}

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    let onClose: () -> Void

    var body: some View {
        BottomSheetContainer(title: exercise.name, subtitle: exercise.categoryValue.rawValue, onClose: onClose) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(exercise.muscleGroupValues, id: \.self) { group in
                        Text(group.rawValue)
                            .font(Theme.Font.text(11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .glassCardAlt(Capsule())
                    }
                }
                HStack {
                    Text("Equipment")
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(exercise.equipmentValue.rawValue)
                        .font(Theme.Font.text(13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
                if let instructions = exercise.instructions, !instructions.isEmpty {
                    Text(instructions)
                        .font(Theme.Font.text(13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}

struct CreateExerciseSheet: View {
    let onClose: () -> Void
    let onCreated: (Exercise) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var category: ExerciseCategory = .other
    @State private var equipment: Equipment = .none
    @State private var isCardio = false

    var body: some View {
        BottomSheetContainer(title: "New Exercise", onClose: onClose) {
            VStack(spacing: 16) {
                TextField("Exercise name", text: $name)
                    .font(Theme.Font.text(15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .glassCardAlt(RoundedRectangle(cornerRadius: 12))

                Picker("Category", selection: $category) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)

                Toggle("Cardio exercise", isOn: $isCardio)

                Button {
                    let exercise = Exercise(name: name, category: category, equipment: equipment, isCardio: isCardio, isCustom: true)
                    modelContext.insert(exercise)
                    try? modelContext.save()
                    onCreated(exercise)
                } label: {
                    Text("Create")
                        .font(Theme.Font.text(14, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}
