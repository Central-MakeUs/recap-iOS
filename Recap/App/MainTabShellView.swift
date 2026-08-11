import SwiftUI

struct AppShellView: View {
    @Environment(\.scenePhase) private var scenePhase

    let router: AppRouter
    let cardStore: RecapCardStore
    let homeSummaryLoader: any HomeSummaryLoading
    let archiveLoader: any ArchiveLoading
    let searchLoader: any SearchLoading
    let captureService: any CaptureServing
    let userAccountService: any UserAccountServing
    let cardCreationProcessor: any CardCreationProcessing
    let cardDataInvalidationCenter: CardDataInvalidationCenter
    let organizeNotificationStore: OrganizeNotificationStore
    let aiDataTransferConsentStore: AIDataTransferConsentStore
    var onLogout: () -> Void = {}
    var onAccountWithdrawalCompleted: () -> Void = {}

    @State private var toast: RecapToastContent?

    init(
        router: AppRouter,
        cardStore: RecapCardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        captureService: any CaptureServing,
        userAccountService: any UserAccountServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        organizeNotificationStore: OrganizeNotificationStore,
        aiDataTransferConsentStore: AIDataTransferConsentStore,
        onLogout: @escaping () -> Void = {},
        onAccountWithdrawalCompleted: @escaping () -> Void = {}
    ) {
        self.router = router
        self.cardStore = cardStore
        self.homeSummaryLoader = homeSummaryLoader
        self.archiveLoader = archiveLoader
        self.searchLoader = searchLoader
        self.captureService = captureService
        self.userAccountService = userAccountService
        self.cardCreationProcessor = cardCreationProcessor
        self.cardDataInvalidationCenter = cardDataInvalidationCenter
        self.organizeNotificationStore = organizeNotificationStore
        self.aiDataTransferConsentStore = aiDataTransferConsentStore
        self.onLogout = onLogout
        self.onAccountWithdrawalCompleted = onAccountWithdrawalCompleted
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
                searchLoader: searchLoader,
                captureService: captureService,
                userAccountService: userAccountService,
                cardCreationProcessor: cardCreationProcessor,
                cardDataInvalidationCenter: cardDataInvalidationCenter,
                organizeNotificationStore: organizeNotificationStore,
                onUpload: openCardCreationFlow,
                onCardDeleted: showCardDeletedToast,
                onAccountWithdrawalCompleted: onAccountWithdrawalCompleted,
                onAccountDataDeleted: handleAccountDataDeleted
            )
        }
        .environment(router)
        .environment(cardStore)
        .environment(organizeNotificationStore)
        .environment(aiDataTransferConsentStore)
        .environment(\.recapLogout, onLogout)
        .recapToast(toast)
        .task(id: toast) {
            await clearToastIfNeeded()
        }
        .task {
            try? await aiDataTransferConsentStore.refresh()
        }
        .task(id: scenePhase) {
            organizeNotificationStore.setApplicationInBackground(scenePhase == .background)
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

    private func handleAccountDataDeleted() {
        cardStore.removeAllCards()
        cardDataInvalidationCenter.invalidate(.captureDeleted)
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
            cardDataInvalidationCenter.invalidate(.organizeResultAcknowledged)
        } catch {
            // 다음 active 진입에서 같은 결과를 다시 조회한다.
        }
    }
}

#if DEBUG
#Preview("App shell") {
    AppShellView(
        router: AppRouter(),
        cardStore: PreviewStores.recapCardStore(),
        homeSummaryLoader: PreviewHomeSummaryLoaderForAppShell(),
        archiveLoader: PreviewArchiveLoader(),
        searchLoader: PreviewSearchLoader(),
        captureService: PreviewCaptureService(),
        userAccountService: PreviewUserAccountService(),
        cardCreationProcessor: PreviewCardCreationPipeline(),
        cardDataInvalidationCenter: CardDataInvalidationCenter(),
        organizeNotificationStore: OrganizeNotificationStore(
            delivery: PreviewOrganizeNotificationDelivery(),
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        ),
        aiDataTransferConsentStore: AIDataTransferConsentStore(
            service: PreviewAIDataTransferConsentService()
        )
    )
}
#endif

#if DEBUG
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
#endif
