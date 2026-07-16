import SwiftUI

struct AppShellView: View {
    let router: AppRouter
    let cardStore: RecapCardStore
    var onLogout: () -> Void = {}

    @State private var toast: RecapToastContent?

    init(
        router: AppRouter,
        cardStore: RecapCardStore,
        onLogout: @escaping () -> Void = {}
    ) {
        self.router = router
        self.cardStore = cardStore
        self.onLogout = onLogout
        _toast = State(initialValue: nil)
    }

    var body: some View {
        ZStack {
            Color.recapBackground
                .ignoresSafeArea()

            activeTabStack
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if showsBottomBar {
                        RecapBottomNavigationBar(
                            selectedTab: selectedTab,
                            onCardCreation: openCardCreationFlow
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
        .recapToast(toast)
        .task(id: toast) {
            await clearToastIfNeeded()
        }
    }

    @ViewBuilder
    private var activeTabStack: some View {
        switch router.selectedTab {
        case .home:
            tabStack(for: .home) { HomeContainerView() }
        case .archive:
            tabStack(for: .archive) { CollectionHomeContainerView() }
        case .cardCreation:
            tabStack(for: .cardCreation) { CardCreationContainerView() }
        }
    }

    @ViewBuilder
    private func tabStack<Content: View>(
        for tab: MainTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack(path: router.binding(for: tab)) {
            content()
                .withAppNavigationDestinations(
                    cardStore: cardStore,
                    onCardDeleted: showCardDeletedToast
                )
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
        case .search, .allRecentCards, .cardDetail, .cardCreationStart, .settings:
            return false
        }
    }

    private func openCardCreationFlow() {
        router.selectedTab = .cardCreation
        if router.cardCreationPath.last != .cardCreationStart {
            router.cardCreationPath = [.cardCreationStart]
        }
    }

    private func showCardDeletedToast() {
        toast = RecapToastContent(
            style: .success,
            message: "스크린샷을 삭제했어요."
        )
    }

    private func clearToastIfNeeded() async {
        guard toast != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        toast = nil
    }
}

private struct RecapBottomNavigationBar: View {
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
                        .font(RecapFont.pretendard(size: 12, weight: .semibold))
                        .tracking(-0.24)
                }
                .foregroundStyle(.white)
                .frame(width: 87, height: 54)
                .background(Color.recapBrandBlue)
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
            .background(isSelected ? Color.recapControlFill : Color.clear)
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
