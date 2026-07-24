import SwiftUI

struct AppShellView: View {
    @Environment(\.scenePhase) private var scenePhase

    let router: AppRouter
    let cardStore: RecapCardStore
    let homeSummaryLoader: any HomeSummaryLoading
    let archiveLoader: any ArchiveLoading
    let captureService: any CaptureServing
    let cardCreationProcessor: any CardCreationProcessing
    let cardDataInvalidationCenter: CardDataInvalidationCenter
    var onLogout: () -> Void = {}

    @State private var toast: RecapToastContent?

    init(
        router: AppRouter,
        cardStore: RecapCardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        captureService: any CaptureServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        onLogout: @escaping () -> Void = {}
    ) {
        self.router = router
        self.cardStore = cardStore
        self.homeSummaryLoader = homeSummaryLoader
        self.archiveLoader = archiveLoader
        self.captureService = captureService
        self.cardCreationProcessor = cardCreationProcessor
        self.cardDataInvalidationCenter = cardDataInvalidationCenter
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
                captureService: captureService,
                cardCreationProcessor: cardCreationProcessor,
                cardDataInvalidationCenter: cardDataInvalidationCenter,
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
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await showPendingOrganizeResultIfNeeded()
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

    private func showPendingOrganizeResultIfNeeded() async {
        guard let result = try? await captureService.pendingOrganizeResult() else {
            return
        }

        switch result.status {
        case .completed:
            toast = RecapToastContent(
                style: .success,
                message: "\(result.successCount)개의 스크린샷을 정리했어요."
            )
        case .partialFailed:
            toast = RecapToastContent(
                style: .error,
                message: "\(result.failCount)개의 스크린샷을 정리하지 못했어요."
            )
        case .failed:
            toast = RecapToastContent(
                style: .error,
                message: "스크린샷을 정리하지 못했어요."
            )
        case .cancelled, .processing:
            return
        }

        await Task.yield()

        do {
            try await captureService.acknowledgeOrganizeResult(batchID: result.batchId)
            cardDataInvalidationCenter.invalidate()
        } catch {
            // 다음 active 진입에서 같은 결과를 다시 조회한다.
        }
    }
}

#Preview("App shell") {
    AppShellView(
        router: AppRouter(),
        cardStore: PreviewStores.recapCardStore(),
        homeSummaryLoader: PreviewHomeSummaryLoaderForAppShell(),
        archiveLoader: PreviewArchiveLoader(),
        captureService: PreviewCaptureService(),
        cardCreationProcessor: PreviewCardCreationPipeline(),
        cardDataInvalidationCenter: CardDataInvalidationCenter()
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
