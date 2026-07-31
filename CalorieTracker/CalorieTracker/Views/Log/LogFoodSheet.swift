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
    @Query private var allFoods: [FoodItem]
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
    @State private var showingCamera = false

    // Barcode
    @State private var showingBarcodeScanner = false

    // Voice
    @StateObject private var speech = SpeechTranscriber()

    // Text
    @State private var textDraft: String = ""

    // Browse
    @State private var browseQuery: String = ""
    @State private var browseSelectedID: PersistentIdentifier?

    // Shared result
    @State private var pendingResult: ParsedFoodResult?
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(initialMode: LogMode, mealType: MealType = MealType.currentMealType, editingEntry: MealEntry? = nil, onClose: @escaping () -> Void, onAdded: @escaping () -> Void) {
        self.initialMode = initialMode
        self.editingEntry = editingEntry
        self.onClose = onClose
        self.onAdded = onAdded
        _mode = State(initialValue: initialMode)
        _mealType = State(initialValue: editingEntry?.mealType ?? mealType)
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
                            case .browse: browseBody
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.Font.text(12))
                        .foregroundStyle(.red.opacity(0.85))
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureView(
                onCapture: { image in
                    showingCamera = false
                    capturedImage = image
                    Task { await runScan(image: image) }
                },
                onCancel: { showingCamera = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showingBarcodeScanner) {
            ZStack(alignment: .topTrailing) {
                BarcodeScannerView { code in
                    showingBarcodeScanner = false
                    Task { await runBarcodeLookup(code) }
                }
                .ignoresSafeArea()

                Button {
                    showingBarcodeScanner = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.4), in: Circle())
                }
                .padding(20)
            }
        }
    }

    private func resetTransient() {
        pendingResult = nil
        errorMessage = nil
        capturedImage = nil
        speech.stop()
        speech.transcript = ""
        textDraft = ""
        browseQuery = ""
        browseSelectedID = nil
        quantity = 1
    }

    // MARK: Scan

    private var scanBody: some View {
        VStack(spacing: 18) {
            if let capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "camera")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.textFaint)
                            Text("Point at your plate")
                                .font(Theme.Font.text(12))
                                .foregroundStyle(Theme.textFaint)
                        }
                    )
            }

            if isLoading {
                ProgressView().tint(Theme.accent)
            } else {
                VStack(spacing: 10) {
                    Button {
                        showingCamera = true
                    } label: {
                        Text("Take Photo")
                            .font(Theme.Font.text(14, weight: .semibold))
                            .foregroundStyle(Theme.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(!CameraCaptureView.isAvailable)

                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Text("Choose from Library")
                            .font(Theme.Font.text(14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    if !CameraCaptureView.isAvailable {
                        Text("Camera unavailable on this device.")
                            .font(Theme.Font.text(11))
                            .foregroundStyle(Theme.textFaint)
                    }
                }
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
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .frame(height: 180)
                .overlay(
                    VStack(spacing: 10) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.textFaint)
                        Text("Scan a product barcode")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textFaint)
                    }
                )

            if isLoading {
                ProgressView().tint(Theme.accent)
            } else {
                Button {
                    showingBarcodeScanner = true
                } label: {
                    Text("Scan Barcode")
                        .font(Theme.Font.text(14, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(!BarcodeScannerView.isAvailable)

                if !BarcodeScannerView.isAvailable {
                    Text("Camera unavailable on this device.")
                        .font(Theme.Font.text(11))
                        .foregroundStyle(Theme.textFaint)
                }
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

    // MARK: Browse

    private var filteredFoods: [FoodItem] {
        guard !browseQuery.isEmpty else { return allFoods }
        return allFoods.filter { $0.name.localizedCaseInsensitiveContains(browseQuery) }
    }

    private var browseBody: some View {
        VStack(spacing: 12) {
            TextField("Search foods…", text: $browseQuery)
                .font(Theme.Font.text(14))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassCardAlt(RoundedRectangle(cornerRadius: 12))

            LazyVStack(spacing: 0) {
                ForEach(filteredFoods) { food in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(Theme.Font.text(14))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(Int(food.servingSize))\(food.servingUnit) serving")
                                    .font(Theme.Font.text(11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            Spacer()
                            Text("\(Int(food.calories)) cal")
                                .font(Theme.Font.text(13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                browseSelectedID = (browseSelectedID == food.persistentModelID) ? nil : food.persistentModelID
                                quantity = 1
                            }
                        }

                        if browseSelectedID == food.persistentModelID {
                            HStack {
                                QuantityStepper(quantity: $quantity)
                                Spacer()
                                Button {
                                    addFoodItem(food, quantity: quantity)
                                } label: {
                                    Text("Add")
                                        .font(Theme.Font.text(13, weight: .semibold))
                                        .foregroundStyle(Theme.onAccent)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 9)
                                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.bottom, 14)
                        }
                    }
                    Divider().overlay(Theme.hairline.opacity(0.6))
                }
            }
        }
    }

    private func addFoodItem(_ food: FoodItem, quantity: Double) {
        let nutrition = food.nutritionFor(quantity: food.servingSize * quantity)
        let entry = MealEntry(
            foodItem: food,
            quantity: food.servingSize * quantity,
            mealType: mealType,
            timestamp: Date(),
            inputMethod: .search,
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbs: nutrition.carbs,
            fat: nutrition.fat,
            fiber: nutrition.fiber,
            sugar: nutrition.sugar,
            sodium: nutrition.sodium
        )
        modelContext.insert(entry)
        try? modelContext.save()
        onAdded()
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
        entry.foodItem = nil
        entry.customFoodName = result.name
        entry.mealType = mealType
        entry.quantity = 1
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
        let entry = MealEntry(
            customFoodName: result.name,
            quantity: 1,
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
