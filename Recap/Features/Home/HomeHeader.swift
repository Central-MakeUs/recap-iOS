import SwiftUI

struct HomeHeader: View {
    let openSettings: () -> Void
    let openSearch: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RecapLogoText()

            Spacer()

            Button(action: openSettings) {
                RecapIconView(
                    icon: .setting,
                    size: 24,
                    color: Color.recapGray900
                )
            }
            .buttonStyle(.plain)

            Button(action: openSearch) {
                RecapIconView(
                    icon: .search,
                    size: 24,
                    color: Color.recapGray900
                )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 29)
    }
}

#Preview {
    HomeHeader(openSettings: {}, openSearch: {})
        .padding()
        .background(Color.recapBackground)
}
