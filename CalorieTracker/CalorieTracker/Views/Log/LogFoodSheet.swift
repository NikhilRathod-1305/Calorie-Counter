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

struct LogFoodSheet: View {
    @Environment(\.modelContext) private var modelContext
    let initialMode: LogMode
    let editingEntry: MealEntry?
    let onClose: () -> Void
    let onAdded: () -> Void

    @State private var mode: LogMode
    @State private var mealType: MealType
    @State private var quantity: Double = 1

    // Scan
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var saveCapturedPhoto = false

    // Barcode
    @State private var barcodeScanID = UUID()

    // Voice
    @StateObject private var speech = SpeechTranscriber()

    // Text
    @State private var textDraft: String = ""

    // Shared result
    @State private var pendingResult: ParsedFoodResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var saveToMyFoods: Bool

    init(initialMode: LogMode, mealType: MealType = MealType.currentMealType, editingEntry: MealEntry? = nil, onClose: @escaping () -> Void, onAdded: @escaping () -> Void) {
        self.initialMode = initialMode
        self.editingEntry = editingEntry
        self.onClose = onClose
        self.onAdded = onAdded
        _mode = State(initialValue: initialMode)
        _mealType = State(initialValue: editingEntry?.mealType ?? mealType)
        // Existing entries default the checkbox off — saving to My Foods here is an
        // explicit opt-in rather than a side effect of just editing a quantity/value.
        _saveToMyFoods = State(initialValue: editingEntry == nil)
        if let editingEntry {
            _pendingResult = State(initialValue: ParsedFoodResult(
                name: editingEntry.displayName,
                calories: editingEntry.nutrition.calories,
                protein: editingEntry.nutrition.protein,
                carbs: editingEntry.nutrition.carbs,
                fat: editingEntry.nutrition.fat,
                fiber: editingEntry.nutrition.fiber,
                sugar: editingEntry.nutrition.sugar,
                sodium: editingEntry.nutrition.sodium
            ))
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

                if pendingResult == nil && mode == .browse {
                    FoodBrowseView(mealType: mealType, onAdded: onAdded)
                } else {
                    ScrollView {
                        Group {
                            if let pendingResult {
                                resultCard(Binding(
                                    get: { pendingResult },
                                    set: { self.pendingResult = $0 }
                                ))
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
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.Font.text(12))
                        .foregroundStyle(.red.opacity(0.85))
                }
            }
        }
    }

    private func resetTransient() {
        pendingResult = nil
        errorMessage = nil
        capturedImage = nil
        saveCapturedPhoto = false
        speech.stop()
        speech.transcript = ""
        textDraft = ""
        quantity = 1
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
                }
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
                .frame(height: 220)
                .frame(maxWidth: .infinity)
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
            pendingResult = result
        } catch {
            errorMessage = error.localizedDescription
            // Recreate the scanner so its session (stopped after the first
            // detection) restarts and the user can retry immediately.
            barcodeScanID = UUID()
        }
        isLoading = false
    }

    private func runScan(image: UIImage) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await GeminiFoodService.parseImage(image)
            pendingResult = result
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
            let result = try await GeminiFoodService.parseText(trimmed)
            pendingResult = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: Pending result (Scan/Barcode/Voice/Text) — editable before adding

    private func resultCard(_ result: Binding<ParsedFoodResult>) -> some View {
        VStack(spacing: 16) {
            if let lastVoiceTranscript, mode == .voice {
                Text("Heard: \"\(lastVoiceTranscript)\"")
                    .font(Theme.Font.text(12))
                    .italic()
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 14) {
                editableField(label: "Name", text: result.name)

                HStack(spacing: 10) {
                    editableNumberField(label: "Calories", value: result.calories, unit: "cal")
                    editableNumberField(label: "Protein", value: result.protein, unit: "g")
                }
                HStack(spacing: 10) {
                    editableNumberField(label: "Carbs", value: result.carbs, unit: "g")
                    editableNumberField(label: "Fat", value: result.fat, unit: "g")
                }
                HStack(spacing: 10) {
                    editableNumberField(label: "Fiber", value: result.fiber, unit: "g")
                    editableNumberField(label: "Sugar", value: result.sugar, unit: "g")
                }
                editableNumberField(label: "Sodium", value: result.sodium, unit: "mg")

                Text("Adjust any value above before adding — useful when you only ate part of what was scanned.")
                    .font(Theme.Font.text(11))
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCardAlt(RoundedRectangle(cornerRadius: 16))

            if editingEntry?.foodItem == nil {
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

            HStack {
                QuantityStepper(quantity: $quantity, size: 32)
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(Int(result.wrappedValue.calories * quantity))")
                        .font(Theme.Font.display(18))
                        .foregroundStyle(Theme.textPrimary)
                    Text(" cal total")
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Button {
                if let editingEntry {
                    updateEntry(editingEntry, with: result.wrappedValue, quantity: quantity)
                } else {
                    addParsedResult(result.wrappedValue, quantity: quantity)
                }
            } label: {
                Text(editingEntry != nil ? "Save changes" : "Add to log")
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private func updateEntry(_ entry: MealEntry, with result: ParsedFoodResult, quantity: Double) {
        if saveToMyFoods && entry.foodItem == nil {
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
            entry.foodItem = food
            entry.customFoodName = nil
            entry.quantity = quantity
        } else {
            entry.foodItem = nil
            entry.customFoodName = result.name
            entry.quantity = 1
        }
        entry.mealType = mealType
        entry.calories = result.calories * quantity
        entry.protein = result.protein * quantity
        entry.carbs = result.carbs * quantity
        entry.fat = result.fat * quantity
        entry.fiber = result.fiber * quantity
        entry.sugar = result.sugar * quantity
        entry.sodium = result.sodium * quantity
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

    private func addParsedResult(_ result: ParsedFoodResult, quantity: Double) {
        let inputMethod: InputMethod
        switch mode {
        case .scan: inputMethod = .photo
        case .barcode: inputMethod = .barcode
        case .voice: inputMethod = .voice
        case .text: inputMethod = .text
        case .browse: inputMethod = .search
        }

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
            timestamp: Date(),
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
        try? modelContext.save()
        onAdded()
    }
}
