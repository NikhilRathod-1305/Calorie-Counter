import SwiftUI
import SwiftData

struct AboutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showingResetOnboardingConfirm = false

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it works")
                            .font(Theme.Font.text(13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Count on Me tracks your food, water, exercise, and weight fully on your device — there's no server and no account. Photo, voice, and barcode logging use Gemini and Open Food Facts to identify nutrition, but nothing you log is stored anywhere except this phone.")
                            .font(Theme.Font.text(13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))

                    Button {
                        showingResetOnboardingConfirm = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.accent)
                            Text("Redo onboarding")
                                .font(Theme.Font.text(14))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                        }
                        .padding(16)
                        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Text("Count on Me")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textFaint)
                        Spacer()
                        Text("v1.0")
                            .font(Theme.Font.text(12))
                            .foregroundStyle(Theme.textFaint)
                    }
                    .padding(.horizontal, 4)

                    Color.clear.frame(height: 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Redo onboarding?", isPresented: $showingResetOnboardingConfirm, titleVisibility: .visible) {
            Button("Redo onboarding", role: .destructive) { resetOnboarding() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This walks you through the setup questions again so you can adjust your goal, activity level, or rate. Your logged history is not affected.")
        }
    }

    private func resetOnboarding() {
        guard let profile = profiles.first else { return }
        profile.hasCompletedOnboarding = false
        try? modelContext.save()
    }
}
