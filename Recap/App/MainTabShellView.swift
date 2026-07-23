import SwiftUI

struct AppShellView: View {
    let router: AppRouter
    let cardStore: RecapCardStore
    let homeSummaryLoader: any HomeSummaryLoading
    let archiveLoader: any ArchiveLoading
    var onLogout: () -> Void = {}

    @State private var toast: RecapToastContent?

    init(
        router: AppRouter,
        cardStore: RecapCardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        onLogout: @escaping () -> Void = {}
    ) {
        self.router = router
        self.cardStore = cardStore
        self.homeSummaryLoader = homeSummaryLoader
        self.archiveLoader = archiveLoader
        self.onLogout = onLogout
        _toast = State(initialValue: nil)
    }

    var body: some View {
        ZStack {
            Color.recapBackground
                .ignoresSafeArea()

            RecapMainTabContainer(
                router: router,
                cardStore: cardStore,
                homeSummaryLoader: homeSummaryLoader,
                archiveLoader: archiveLoader,
                onUpload: openCardCreationFlow,
                onCardDeleted: showCardDeletedToast
            )
        }
        .environment(router)
        .environment(cardStore)
        .environment(\.recapLogout, onLogout)
        .recapToast(toast)
        .task(id: toast) {
            await clearToastIfNeeded()
        }
    }

    private func openCardCreationFlow() {
        let activePath = router.path(for: router.selectedTab)
        if activePath.last != .cardCreationStart {
            router.navigate(.cardCreationStart)
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
        cardStore: PreviewStores.recapCardStore(),
        homeSummaryLoader: PreviewHomeSummaryLoaderForAppShell(),
        archiveLoader: PreviewArchiveLoader()
    )
}

@MainActor
private final class PreviewHomeSummaryLoaderForAppShell: HomeSummaryLoading {
    func fetchSummary() async throws -> HomeSummaryContent {
        HomeSummaryContent(
            recentCards: SampleData.recentCards,
            favoriteCards: SampleData.cards.filter(\.isFavorite),
            frequentTypes: SampleData.collectionSummaries,
            hasAnyCapture: true
        )
    }
}
