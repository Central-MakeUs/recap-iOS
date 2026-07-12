import SwiftUI

struct AppShellView: View {
    let router: AppRouter
    let cardStore: RecapCardStore
    var onLogout: () -> Void = {}

    var body: some View {
        ZStack {
            RecapTheme.ColorToken.background
                .ignoresSafeArea()

            activeTabStack
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if showsBottomBar {
                        RecapBottomNavigationBar(
                            selectedTab: selectedTab,
                            onOrganize: openOrganizeFlow
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        .animation(.easeInOut(duration: 0.18), value: router.selectedTab)
        .animation(.easeInOut(duration: 0.18), value: showsBottomBar)
        .environment(router)
        .environment(cardStore)
        .environment(\.recapLogout, onLogout)
        .withAppPresentations(router: router, cardStore: cardStore)
    }

    @ViewBuilder
    private var activeTabStack: some View {
        switch router.selectedTab {
        case .home:
            tabStack(for: .home) { HomeContainerView() }
        case .archive:
            tabStack(for: .archive) { CollectionHomeContainerView() }
        case .organize:
            tabStack(for: .organize) { OrganizeContainerView() }
        }
    }

    @ViewBuilder
    private func tabStack<Content: View>(
        for tab: MainTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack(path: router.binding(for: tab)) {
            content()
                .withAppNavigationDestinations()
        }
    }

    private var selectedTab: Binding<MainTab> {
        Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        )
    }

    private var showsBottomBar: Bool {
        guard let lastRoute = router.path(for: router.selectedTab).last else { return true }
        switch lastRoute {
        case .archiveDetail:
            return true
        case .search, .allRecentCards, .cardDetail, .cardEdit, .organizeStart, .settings:
            return false
        }
    }

    private func openOrganizeFlow() {
        router.selectedTab = .organize
        if router.organizePath.last != .organizeStart {
            router.organizePath = [.organizeStart]
        }
    }
}

private struct RecapBottomNavigationBar: View {
    @Binding var selectedTab: MainTab
    let onOrganize: () -> Void

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

            Button(action: onOrganize) {
                HStack(spacing: 7) {
                    Image("RecapUploadIcon")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text("업로드")
                        .font(RecapFont.pretendard(size: 12, weight: .semibold))
                        .tracking(-0.24)
                }
                .foregroundStyle(.white)
                .frame(width: 87, height: 54)
                .background(Color(red: 92 / 255, green: 109 / 255, blue: 255 / 255))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("업로드")
        }
        .padding(.horizontal, 32)
        .padding(.top, 28.5)
        .frame(maxWidth: .infinity)
        .frame(height: 111, alignment: .top)
        .background {
            RecapTheme.ColorToken.background
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
            .foregroundStyle(isSelected ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.textTertiary)
            .frame(width: 72, height: 46)
            .background(isSelected ? RecapTheme.ColorToken.controlFill : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("App shell") {
    AppShellView(
        router: AppRouter(),
        cardStore: PreviewStores.recapCardStore()
    )
}
