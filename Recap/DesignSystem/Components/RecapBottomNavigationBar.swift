import SwiftUI

struct RecapBottomNavigationBar: View {
    @Binding var selectedTab: MainTab
    let onCardCreation: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.archive)
            }
            .padding(4)
            .frame(width: 155, height: 54)
            .background(Color.white)
            .clipShape(Capsule())

            Spacer(minLength: 0)

            Button(action: onCardCreation) {
                HStack(spacing: 7) {
                    Image("RecapUploadIcon")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text("업로드")
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                }
                .foregroundStyle(.white)
                .frame(width: 107, height: 54)
                .background(Color.recapBrandBlue)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("업로드")
        }
        .padding(.horizontal, 22)
        .padding(.top, 28.5)
        .frame(maxWidth: .infinity)
        .frame(height: 111, alignment: .top)
        .background {
            Color.recapBackground
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tabButton(_ tab: MainTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            let isSelected = selectedTab == tab
            Image(tab == .home ? "RecapTabHomeIcon" : "RecapTabArchiveIcon")
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(isSelected ? Color.recapBlue300 : Color.recapGray300)
                .frame(width: 72, height: 46)
                .background(isSelected ? Color.recapPrimarySoft : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("하단 내비게이션") {
    @Previewable @State var selectedTab = MainTab.home

    RecapBottomNavigationBar(
        selectedTab: $selectedTab,
        onCardCreation: {}
    )
}
