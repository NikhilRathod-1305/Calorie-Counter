import SwiftUI
import SwiftData
import PhotosUI

enum LogMode: String, CaseIterable {
    case scan = "Scan"
    case barcode = "Barcode"
    case voice = "Voice"
    case text = "Text"
    case browse = "Browse"
}

/// One detected food item awaiting review, with its own editable portion —
/// several of these can come from a single scan/text/voice entry.
struct PendingFoodResult: Identifiable {
    let id = UUID()
    var result: ParsedFoodResult
    var quantity: Double = 1
    /// Set when this card represents an existing MealEntry being edited
    /// (either the single entry being edited, or one child of a group) —
    /// nil for freshly scanned/parsed results that haven't been saved yet.
    var sourceEntry: MealEntry?
}

struct LogFoodSheet: View {
    @Environment(\.modelContext) private var modelContext
    let initialMode: LogMode
    let editingEntry: MealEntry?
    let date: Date
    let onClose: () -> Void
    let onAdded: () -> Void

    @State private var mode: LogMode
    @State private var mealType: MealType

    // Scan
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var saveCapturedPhoto = false

    // Refinement — lets the user correct any pending result (scan, text,
    // voice, or an already-saved entry being edited) with a free-text note.
    @State private var refinementText: String = ""
    @FocusState private var isRefinementFieldFocused: Bool

    // Barcode
    @State private var barcodeScanID = UUID()

    // Voice
    @StateObject private var speech = SpeechTranscriber()

    // Text
    @State private var textDraft: String = ""

    // Shared result — one card per detected item, each with its own portion.
    @State private var pendingResults: [PendingFoodResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var saveToMyFoods: Bool
    /// Children removed from a group while editing — deleted on save.
    @State private var removedSourceEntries: [MealEntry] = []

    init(initialMode: LogMode, mealType: MealType = MealType.currentMealType, editingEntry: MealEntry? = nil, date: Date = Date(), onClose: @escaping () -> Void, onAdded: @escaping () -> Void) {
        self.initialMode = initialMode
        self.editingEntry = editingEntry
        self.date = date
        self.onClose = onClose
        self.onAdded = onAdded
        _mode = State(initialValue: initialMode)
        _mealType = State(initialValue: editingEntry?.mealType ?? mealType)
        // Existing entries default the checkbox off — saving to My Foods here is an
        // explicit opt-in rather than a side effect of just editing a quantity/value.
        _saveToMyFoods = State(initialValue: editingEntry == nil)
        if let editingEntry {
            let children = (editingEntry.children ?? []).sorted { $0.timestamp < $1.timestamp }
            if !children.isEmpty {
                // Editing a multi-item group: one card per nested food so
                // each can be adjusted (or removed) independently, same as
                // the original multi-item scan review screen.
                _pendingResults = State(initialValue: children.map { child in
                    PendingFoodResult(
                        result: ParsedFoodResult(
                            name: child.displayName,
                            calories: child.nutrition.calories,
                            protein: child.nutrition.protein,
                            carbs: child.nutrition.carbs,
                            fat: child.nutrition.fat,
                            fiber: child.nutrition.fiber,
                            sugar: child.nutrition.sugar,
                            sodium: child.nutrition.sodium
                        ),
                        quantity: child.quantity,
                        sourceEntry: child
                    )
                })
            } else {
                _pendingResults = State(initialValue: [PendingFoodResult(
                    result: ParsedFoodResult(
                        name: editingEntry.displayName,
                        calories: editingEntry.nutrition.calories,
                        protein: editingEntry.nutrition.protein,
                        carbs: editingEntry.nutrition.carbs,
                        fat: editingEntry.nutrition.fat,
                        fiber: editingEntry.nutrition.fiber,
                        sugar: editingEntry.nutrition.sugar,
                        sodium: editingEntry.nutrition.sodium
                    ),
                    quantity: editingEntry.quantity,
                    sourceEntry: editingEntry
                )])
            }
        }
    }

    var body: some View {
        BottomSheetContainer(title: editingEntry != nil ? "Edit food" : "Log food", onClose: onClose) {
            VStack(spacing: 18) {
                PillSegmentedControl(
                    options: MealType.allCases.sorted { $0.sortOrder < $1.sortOrder }.map { ($0, "\($0.emoji) \($0.rawValue)") },
                    selection: $mealType,
                    style: .outlined
                )

                if editingEntry == nil {
                    PillSegmentedControl(
                        options: LogMode.allCases.map { ($0, $0.rawValue) },
                        selection: $mode
                    )
                    .onChange(of: mode) { _, _ in resetTransient() }
                }

                if pendingResults.isEmpty && mode == .browse {
                    FoodBrowseView(mealType: mealType, date: date, onAdded: onAdded)
                } else if wantsFullHeightLiveView {
                    // Live camera/scanner previews want to fill the sheet's
                    // remaining height for easier framing — a ScrollView
                    // sizes to its content, not available space, so these
                    // states bypass it in favor of a flexible frame.
                    fullHeightLiveView
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        Group {
                            if !pendingResults.isEmpty {
                                resultsList
                            } else {
                                switch mode {
                                case .scan: scanBody
                                case .barcode: barcodeBody
                                case .voice: voiceBody
                                case .text: textBody
                                case .browse: EmptyView()
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.Font.text(12))
                        .foregroundStyle(.red.opacity(0.85))
                }
            }
        }
    }

    /// True when the sheet should show a live camera/scanner view that wants
    /// to expand to fill the sheet's height, rather than the ScrollView-
    /// wrapped, fixed-height content used everywhere else.
    private var wantsFullHeightLiveView: Bool {
        guard pendingResults.isEmpty, !isLoading else { return false }
        switch mode {
        case .scan: return capturedImage == nil && MealCameraController.isAvailable
        case .barcode: return BarcodeScannerView.isAvailable
        default: return false
        }
    }

    @ViewBuilder
    private var fullHeightLiveView: some View {
        switch mode {
        case .scan: scanBody
        case .barcode: barcodeBody
        default: EmptyView()
        }
    }

    private func resetTransient() {
        pendingResults = []
        removedSourceEntries = []
        errorMessage = nil
        capturedImage = nil
        saveCapturedPhoto = false
        refinementText = ""
        speech.stop()
        speech.transcript = ""
        textDraft = ""
        saveToMyFoods = true
    }

    // MARK: Scan

    private var scanBody: some View {
        VStack(spacing: 18) {
            if let capturedImage {
                ZStack {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    if isLoading {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.black.opacity(0.45))
                        VStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Analyzing meal…")
                                .font(Theme.Font.text(12, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            } else if isLoading {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.cardBackgroundAlt)
                    .frame(height: 220)
                    .overlay(ProgressView().tint(Theme.accent))
            } else if MealCameraController.isAvailable {
                VStack(spacing: 12) {
                    Button {
                        saveCapturedPhoto.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: saveCapturedPhoto ? "checkmark.square.fill" : "square")
                                .font(.system(size: 17))
                                .foregroundStyle(saveCapturedPhoto ? Theme.accent : Theme.textFaint)
                            Text("Save photo to Photos")
                                .font(Theme.Font.text(12, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    MealCameraCaptureControl { image in
                        capturedImage = image
                        if saveCapturedPhoto {
                            PhotoLibrarySaver.save(image)
                        }
                        Task { await runScan(image: image) }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "camera")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.textFaint)
                            Text("Camera unavailable on this device.")
                                .font(Theme.Font.text(12))
                                .foregroundStyle(Theme.textFaint)
                        }
                    )
            }

            if !isLoading {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Text("Choose from Library")
                        .font(Theme.Font.text(14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                capturedImage = image
                await runScan(image: image)
            }
        }
    }

    // MARK: Barcode

    private var barcodeBody: some View {
        VStack(spacing: 18) {
            if isLoading {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.cardBackgroundAlt)
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: 10) {
                            ProgressView().tint(Theme.accent)
                            Text("Looking up product…")
                                .font(Theme.Font.text(12, weight: .medium))
                                .foregroundStyle(Theme.textFaint)
                        }
                    )
            } else if BarcodeScannerView.isAvailable {
                ZStack {
                    BarcodeScannerView { code in
                        Task { await runBarcodeLookup(code) }
                    }
                    .id(barcodeScanID)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    VStack {
                        Spacer()
                        Text("Align the barcode within the frame")
                            .font(Theme.Font.text(12, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.4), in: Capsule())
                            .padding(.bottom, 14)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.textFaint)
                            Text("Camera unavailable on this device.")
                                .font(Theme.Font.text(12))
                                .foregroundStyle(Theme.textFaint)
                        }
                    )
            }
        }
    }

    private func runBarcodeLookup(_ code: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await OpenFoodFactsService.lookup(barcode: code)
            pendingResults = [PendingFoodResult(result: result)]
        } catch {
            errorMessage = error.localizedDescription
            // Recreate the scanner so its session (stopped after the first
            // detection) restarts and the user can retry immediately.
            barcodeScanID = UUID()
        }
        isLoading = false
    }

    private func runScan(image: UIImage, correction: String? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            let results = try await GeminiFoodService.parseImage(image, refinementText: correction)
            pendingResults = results.map { PendingFoodResult(result: $0) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Applies the refinement note to whatever's currently on screen. When a
    /// captured photo is still available (fresh scan review), it re-sends
    /// the photo with the correction; otherwise (text/voice review, or
    /// editing an already-saved entry with no photo on hand) it re-estimates
    /// from the current item list instead. Either way the result replaces
    /// what's shown — any items tied to already-saved entries stay queued
    /// for deletion on save so the refined list is what actually gets saved.
    private func applyRefinement() async {
        let trimmed = refinementText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let results: [ParsedFoodResult]
            if mode == .scan, let capturedImage {
                results = try await GeminiFoodService.parseImage(capturedImage, refinementText: trimmed)
            } else {
                results = try await GeminiFoodService.refine(items: pendingResults.map(\.result), refinementText: trimmed)
            }
            // Anything that was tied to a saved entry and isn't part of the
            // refined list needs deleting on save — the refined cards below
            // replace them as fresh (unsaved) items.
            removedSourceEntries.append(contentsOf: pendingResults.compactMap(\.sourceEntry))
            pendingResults = results.map { PendingFoodResult(result: $0) }
            refinementText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: Voice

    private var voiceBody: some View {
        VStack(spacing: 18) {
            HStack(spacing: 4) {
                ForEach(0..<9, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.accent)
                        .frame(width: 4, height: speech.isListening ? CGFloat(8 + abs(4 - i) * 4) : 6)
                        .animation(speech.isListening ? .easeInOut(duration: 0.5 + Double(i % 3) * 0.15).repeatForever(autoreverses: true) : .default, value: speech.isListening)
                }
            }
            .frame(height: 40)

            Button {
                Task {
                    if speech.isListening {
                        speech.stop()
                        if !speech.transcript.isEmpty {
                            await runTextParse(speech.transcript, isVoice: true)
                        }
                    } else {
                        let granted = await speech.requestPermissions()
                        if granted {
                            speech.start()
                        } else {
                            errorMessage = "Microphone or speech permission denied."
                        }
                    }
                }
            } label: {
                ZStack {
                    Circle().fill(Theme.accent).frame(width: 64, height: 64)
                    if isLoading {
                        ProgressView().tint(Theme.onAccent)
                    } else {
                        Image(systemName: speech.isListening ? "stop.fill" : "mic.fill")
                            .foregroundStyle(Theme.onAccent)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Text(speech.isListening ? (speech.transcript.isEmpty ? "Listening…" : speech.transcript) : "Tap to speak")
                .font(Theme.Font.text(12))
                .foregroundStyle(Theme.textFaint)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(minHeight: 180)
    }

    // MARK: Text

    private var textBody: some View {
        VStack(spacing: 14) {
            TextEditor(text: $textDraft)
                .scrollContentBackground(.hidden)
                .font(Theme.Font.text(14))
                .foregroundStyle(Theme.textPrimary)
                .frame(minHeight: 90)
                .padding(12)
                .glassCardAlt(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    if textDraft.isEmpty {
                        Text("Describe what you ate…")
                            .font(Theme.Font.text(14))
                            .foregroundStyle(Theme.textFaint)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }

            Button {
                Task { await runTextParse(textDraft, isVoice: false) }
            } label: {
                ZStack {
                    Text("Parse entry")
                        .opacity(isLoading ? 0 : 1)
                    if isLoading { ProgressView().tint(Theme.onAccent) }
                }
                .font(Theme.Font.text(14, weight: .semibold))
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isLoading || textDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @State private var lastVoiceTranscript: String?

    private func runTextParse(_ text: String, isVoice: Bool) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        if isVoice { lastVoiceTranscript = trimmed }
        do {
            let results = try await GeminiFoodService.parseText(trimmed)
            pendingResults = results.map { PendingFoodResult(result: $0) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: Pending results (Scan/Barcode/Voice/Text) — editable before adding

    /// Binding into `pendingResults` for a given item id, so each stacked
    /// card can edit its own entry independently of the others.
    private func binding(for id: PendingFoodResult.ID) -> Binding<PendingFoodResult> {
        Binding(
            get: { pendingResults.first(where: { $0.id == id }) ?? PendingFoodResult(result: ParsedFoodResult(name: "", calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0)) },
            set: { updated in
                if let index = pendingResults.firstIndex(where: { $0.id == id }) {
                    pendingResults[index] = updated
                }
            }
        )
    }

    private var resultsList: some View {
        VStack(spacing: 16) {
            if let lastVoiceTranscript, mode == .voice {
                Text("Heard: \"\(lastVoiceTranscript)\"")
                    .font(Theme.Font.text(12))
                    .italic()
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if pendingResults.count > 1 {
                Text(editingEntry != nil
                     ? "\(pendingResults.count) items in this meal — adjust portions below, or remove any you didn't eat."
                     : "\(pendingResults.count) items detected — adjust portions below, or remove any you didn't eat.")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(pendingResults) { item in
                resultCard(binding(for: item.id))
            }

            if !pendingResults.isEmpty {
                refinementField
            }

            if editingEntry?.foodItem == nil && editingEntry == nil {
                Button {
                    saveToMyFoods.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: saveToMyFoods ? "checkmark.square.fill" : "square")
                            .font(.system(size: 17))
                            .foregroundStyle(saveToMyFoods ? Theme.accent : Theme.textFaint)
                        Text("Save to My Foods for next time")
                            .font(Theme.Font.text(12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

            let totalCalories = pendingResults.reduce(0) { $0 + $1.result.calories * $1.quantity }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Spacer()
                Text("\(Int(totalCalories))")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.textPrimary)
                Text(" cal total")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }

            Button {
                if let editingEntry {
                    saveEditedEntry(editingEntry, with: pendingResults)
                } else {
                    addAllParsedResults(pendingResults)
                }
            } label: {
                Text(editingEntry != nil ? "Save changes" : (pendingResults.count > 1 ? "Add all \(pendingResults.count) to log" : "Add to log"))
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(pendingResults.isEmpty)
        }
    }

    private var refinementField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(editingEntry != nil ? "Refine this entry" : "Refine the result")
                .font(Theme.Font.text(10))
                .foregroundStyle(Theme.textFaint)
            TextEditor(text: $refinementText)
                .scrollContentBackground(.hidden)
                .font(Theme.Font.text(13))
                .foregroundStyle(Theme.textPrimary)
                .frame(minHeight: 60)
                .padding(10)
                .glassCardAlt(RoundedRectangle(cornerRadius: 12))
                .focused($isRefinementFieldFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isRefinementFieldFocused = false }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if refinementText.isEmpty {
                        Text("e.g. \"only ate the egg whites\" or \"remove the toast\"")
                            .font(Theme.Font.text(13))
                            .foregroundStyle(Theme.textFaint)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            Button {
                isRefinementFieldFocused = false
                Task { await applyRefinement() }
            } label: {
                ZStack {
                    Text(mode == .scan && capturedImage != nil ? "Re-scan with correction" : "Apply correction")
                        .opacity(isLoading ? 0 : 1)
                    if isLoading { ProgressView().tint(Theme.textPrimary) }
                }
                .font(Theme.Font.text(13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isLoading || refinementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func resultCard(_ item: Binding<PendingFoodResult>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            editableField(label: "Name", text: item.result.name)

            HStack(spacing: 10) {
                editableNumberField(label: "Calories", value: item.result.calories, unit: "cal")
                editableNumberField(label: "Protein", value: item.result.protein, unit: "g")
            }
            HStack(spacing: 10) {
                editableNumberField(label: "Carbs", value: item.result.carbs, unit: "g")
                editableNumberField(label: "Fat", value: item.result.fat, unit: "g")
            }
            HStack(spacing: 10) {
                editableNumberField(label: "Fiber", value: item.result.fiber, unit: "g")
                editableNumberField(label: "Sugar", value: item.result.sugar, unit: "g")
            }
            editableNumberField(label: "Sodium", value: item.result.sodium, unit: "mg")

            Text("Adjust the portion below — useful when you only ate part of what was scanned.")
                .font(Theme.Font.text(11))
                .foregroundStyle(Theme.textFaint)

            HStack {
                QuantityStepper(quantity: item.quantity, size: 32)
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(Int(item.wrappedValue.result.calories * item.wrappedValue.quantity))")
                        .font(Theme.Font.text(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(" cal")
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                if pendingResults.count > 1 {
                    Button {
                        if let source = item.wrappedValue.sourceEntry {
                            removedSourceEntries.append(source)
                        }
                        pendingResults.removeAll { $0.id == item.wrappedValue.id }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textFaint)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardAlt(RoundedRectangle(cornerRadius: 16))
    }

    /// Saves edits for whatever's currently on screen when editing an
    /// existing entry — keyed off the *current* shape of `pendingResults`,
    /// which may no longer match the original entry (e.g. a refinement
    /// added/removed items, or trimmed a group down to one item).
    ///
    /// Any card still tied to a saved MealEntry (`sourceEntry`, untouched by
    /// a refine) is updated in place; everything else is deleted and the
    /// current list is (re)inserted fresh under one shared timestamp/input
    /// method, saved flat if it's a single item or as a parent+children
    /// group otherwise.
    private func saveEditedEntry(_ entry: MealEntry, with items: [PendingFoodResult]) {
        let originalGroup = entry.parent ?? entry
        let timestamp = originalGroup.timestamp
        let inputMethod = originalGroup.inputMethod

        for removedChild in removedSourceEntries {
            modelContext.delete(removedChild)
        }

        guard !items.isEmpty else {
            modelContext.delete(originalGroup)
            try? modelContext.save()
            onAdded()
            return
        }

        func apply(_ item: PendingFoodResult, to child: MealEntry) {
            let result = item.result
            let quantity = item.quantity
            child.foodItem = nil
            child.customFoodName = result.name
            child.quantity = quantity
            child.mealType = mealType
            child.calories = result.calories * quantity
            child.protein = result.protein * quantity
            child.carbs = result.carbs * quantity
            child.fat = result.fat * quantity
            child.fiber = result.fiber * quantity
            child.sugar = result.sugar * quantity
            child.sodium = result.sodium * quantity
        }

        if items.count == 1 {
            let item = items[0]
            let target = item.sourceEntry ?? MealEntry(mealType: mealType, timestamp: timestamp, inputMethod: inputMethod)
            if item.sourceEntry == nil {
                modelContext.insert(target)
                modelContext.delete(originalGroup)
            }
            apply(item, to: target)
            target.parent = nil
            target.groupName = nil
        } else {
            let groupParent = entry.parent ?? (((entry.children ?? []).isEmpty) ? nil : entry)
                ?? {
                    let created = MealEntry(mealType: mealType, timestamp: timestamp, inputMethod: inputMethod)
                    modelContext.insert(created)
                    modelContext.delete(entry)
                    return created
                }()
            groupParent.mealType = mealType
            groupParent.groupName = multiItemGroupName(for: items)

            var updatedChildren: [MealEntry] = []
            for item in items {
                let child = item.sourceEntry ?? {
                    let created = MealEntry(mealType: mealType, timestamp: timestamp, inputMethod: inputMethod)
                    modelContext.insert(created)
                    return created
                }()
                apply(item, to: child)
                child.parent = groupParent
                updatedChildren.append(child)
            }
            groupParent.children = updatedChildren
        }

        try? modelContext.save()
        onAdded()
    }

    private func editableField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.Font.text(10))
                .foregroundStyle(Theme.textFaint)
            TextField("", text: text)
                .font(Theme.Font.text(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func editableNumberField(label: String, value: Binding<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.Font.text(10))
                .foregroundStyle(Theme.textFaint)
            HStack(spacing: 3) {
                TextField("0", value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .font(Theme.Font.text(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func addAllParsedResults(_ items: [PendingFoodResult]) {
        let inputMethod: InputMethod
        switch mode {
        case .scan: inputMethod = .photo
        case .barcode: inputMethod = .barcode
        case .voice: inputMethod = .voice
        case .text: inputMethod = .text
        case .browse: inputMethod = .search
        }

        func makeEntry(_ item: PendingFoodResult) -> MealEntry {
            let result = item.result
            let quantity = item.quantity

            let savedFood: FoodItem?
            if saveToMyFoods {
                let food = FoodItem(
                    name: result.name,
                    calories: result.calories,
                    protein: result.protein,
                    carbs: result.carbs,
                    fat: result.fat,
                    fiber: result.fiber,
                    sugar: result.sugar,
                    sodium: result.sodium,
                    servingSize: 1,
                    servingUnit: "serving",
                    isCustom: true,
                    emoji: FoodCategory.other.emoji
                )
                modelContext.insert(food)
                savedFood = food
            } else {
                savedFood = nil
            }

            let entry = MealEntry(
                foodItem: savedFood,
                customFoodName: savedFood == nil ? result.name : nil,
                quantity: quantity,
                mealType: mealType,
                timestamp: entryTimestamp,
                inputMethod: inputMethod,
                calories: result.calories * quantity,
                protein: result.protein * quantity,
                carbs: result.carbs * quantity,
                fat: result.fat * quantity,
                fiber: result.fiber * quantity,
                sugar: result.sugar * quantity,
                sodium: result.sodium * quantity
            )
            modelContext.insert(entry)
            return entry
        }

        if items.count > 1 {
            // Multiple detected items collapse into one parent "meal" row
            // with each food nested underneath, rather than several
            // independent top-level log entries.
            let parent = MealEntry(
                mealType: mealType,
                timestamp: entryTimestamp,
                inputMethod: inputMethod,
                groupName: multiItemGroupName(for: items)
            )
            modelContext.insert(parent)
            parent.children = items.map { item in
                let child = makeEntry(item)
                child.parent = parent
                return child
            }
        } else if let only = items.first {
            _ = makeEntry(only)
        }

        try? modelContext.save()
        onAdded()
    }

    /// The selected day combined with the current time-of-day, so entries
    /// logged for a past day still sort sensibly instead of all landing at
    /// midnight.
    private var entryTimestamp: Date {
        let cal = Calendar.current
        guard !cal.isDateInToday(date) else { return Date() }
        let time = cal.dateComponents([.hour, .minute, .second], from: Date())
        return cal.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0, of: date) ?? date
    }

    private func multiItemGroupName(for items: [PendingFoodResult]) -> String {
        let names = items.prefix(3).map { $0.result.name }
        let joined = names.joined(separator: ", ")
        return items.count > 3 ? "\(joined) + \(items.count - 3) more" : joined
    }
}
