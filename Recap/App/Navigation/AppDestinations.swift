import SwiftUI

extension View {
    @MainActor
    func withAppNavigationDestinations(
        cardStore: CardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        captureService: any CaptureServing,
        userAccountService: any UserAccountServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        organizeNotificationStore: OrganizeNotificationStore,
        onCardDeleted: @escaping () -> Void,
        onAccountWithdrawalCompleted: @escaping () -> Void,
        onAccountDataDeleted: @escaping () -> Void
    ) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            destination(
                for: route,
                cardStore: cardStore,
                homeSummaryLoader: homeSummaryLoader,
                archiveLoader: archiveLoader,
                searchLoader: searchLoader,
                captureService: captureService,
                userAccountService: userAccountService,
                cardCreationProcessor: cardCreationProcessor,
                cardDataInvalidationCenter: cardDataInvalidationCenter,
                organizeNotificationStore: organizeNotificationStore,
                onCardDeleted: onCardDeleted,
                onAccountWithdrawalCompleted: onAccountWithdrawalCompleted,
                onAccountDataDeleted: onAccountDataDeleted
            )
        }
    }

    @MainActor
    @ViewBuilder
    private func destination(
        for route: AppRoute,
        cardStore: CardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        captureService: any CaptureServing,
        userAccountService: any UserAccountServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        organizeNotificationStore: OrganizeNotificationStore,
        onCardDeleted: @escaping () -> Void,
        onAccountWithdrawalCompleted: @escaping () -> Void,
        onAccountDataDeleted: @escaping () -> Void
    ) -> some View {
        switch route {
        case .search:
            SearchContainerView(
                loader: searchLoader,
                cardStore: cardStore,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .allRecentCards:
            AllRecentCardsContainerView(
                summaryLoader: homeSummaryLoader,
                cardStore: cardStore,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .archiveFavorites:
            CollectionDetailContainerView(
                scope: .favorites,
                loader: archiveLoader,
                searchLoader: searchLoader,
                cardStore: cardStore,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .archiveDetail(let kind):
            CollectionDetailContainerView(
                scope: .category(kind),
                loader: archiveLoader,
                searchLoader: searchLoader,
                cardStore: cardStore,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .remoteCardDetail(let card):
            RemoteCardDetailDestination(
                card: card,
                captureService: captureService,
                onDeleted: onCardDeleted
            )
        case .cardCreationStart:
            CardCreationFlowView(
                viewModel: CardCreationFlowViewModel(
                    processor: cardCreationProcessor,
                    invalidationCenter: cardDataInvalidationCenter,
                    notificationStore: organizeNotificationStore,
                    backgroundExecution: SystemOrganizeBackgroundExecution()
                )
            )
        case .settings:
            SettingsContainerView(
                userAccountService: userAccountService,
                accountWithdrawalCompleted: onAccountWithdrawalCompleted,
                accountDataDeleted: onAccountDataDeleted
            )
        }
    }
}

private struct RemoteCardDetailDestination: View {
    @Environment(CardStore.self) private var cardStore

    /// 경로 페이로드. 목록이 미리 upsert해두므로 보통 스토어에 이미 있고,
    /// 없으면(스토어를 거치지 않은 진입) 한 프레임 뒤 합류한다.
    let card: InformationCard
    let captureService: any CaptureServing
    let onDeleted: () -> Void

    var body: some View {
        if let captureID = card.captureID,
           let sharedCard = cardStore.card(withCaptureID: captureID) {
            CardDetailView(
                card: sharedCard,
                captureService: captureService,
                cardStore: cardStore,
                onDeleted: onDeleted
            )
        } else {
            // body에서 upsert하면 갱신 중 상태 변경이라, 등록만 onAppear로 미룬다.
            Color.recapBackground
                .onAppear {
                    cardStore.upsert(card)
                }
        }
    }
}
