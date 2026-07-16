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

#Preview("App shell") {
    AppShellView(
        router: AppRouter(),
        cardStore: PreviewStores.recapCardStore()
    )
}
