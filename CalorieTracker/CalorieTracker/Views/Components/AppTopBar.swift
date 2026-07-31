import SwiftUI

struct AppLogoMark: View {
    var size: CGFloat = 32

    var body: some View {
        Image("AppMark")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

struct AppTopBar: View {
    @State private var showingProfile = false

    var body: some View {
        HStack {
            AppLogoMark(size: 30)

            Spacer()

            Text("Count on Me")
                .font(Theme.Font.display(17))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button {
                showingProfile = true
            } label: {
                Image(systemName: "person.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .glassCardAlt(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.cardBackground, in: Rectangle())
        .sheet(isPresented: $showingProfile) {
            NavigationStack {
                ProfileView()
            }
        }
    }
}
