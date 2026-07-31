import SwiftUI

struct APIKeySettingsView: View {
    @State private var apiKeyDraft: String = ""
    @State private var showSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Free from Google AI Studio. Used for photo and text food recognition. Stored securely on this device only.")
                    .font(Theme.Font.text(13))
                    .foregroundStyle(Theme.textSecondary)

                SecureField("AIza...", text: $apiKeyDraft)
                    .font(Theme.Font.text(14))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .glassCard(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Button {
                        KeychainStore.saveAPIKey(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines))
                        showSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showSaved = false }
                    } label: {
                        Text("Save key")
                            .font(Theme.Font.text(14, weight: .semibold))
                            .foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    if showSaved {
                        Text("Saved")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.success)
                    }
                }

                Color.clear.frame(height: 24)
            }
            .padding(16)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Gemini API Key")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            apiKeyDraft = KeychainStore.loadAPIKey() ?? ""
        }
    }
}
