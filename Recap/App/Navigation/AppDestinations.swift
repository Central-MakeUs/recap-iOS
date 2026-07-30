import SwiftUI

extension View {
    @MainActor
    func withAppNavigationDestinations(
        cardStore: RecapCardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        captureService: any CaptureServing,
        userAccountService: any UserAccountServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        organizeNotificationController: OrganizeNotificationController,
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
                organizeNotificationController: organizeNotificationController,
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
        cardStore: RecapCardStore,
        homeSummaryLoader: any HomeSummaryLoading,
        archiveLoader: any ArchiveLoading,
        searchLoader: any SearchLoading,
        captureService: any CaptureServing,
        userAccountService: any UserAccountServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        organizeNotificationController: OrganizeNotificationController,
        onCardDeleted: @escaping () -> Void,
        onAccountWithdrawalCompleted: @escaping () -> Void,
        onAccountDataDeleted: @escaping () -> Void
    ) -> some View {
        switch route {
        case .search:
            SearchContainerView(
                loader: searchLoader,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .allRecentCards:
            AllRecentCardsContainerView(
                summaryLoader: homeSummaryLoader,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .archiveFavorites:
            CollectionDetailContainerView(
                scope: .favorites,
                loader: archiveLoader,
                searchLoader: searchLoader,
                captureMutator: captureService,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .archiveDetail(let kind):
            CollectionDetailContainerView(
                scope: .category(kind),
                loader: archiveLoader,
                searchLoader: searchLoader,
                captureMutator: captureService,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .cardDetail(let id):
            if let card = cardStore.card(id: id) {
                CardDetailView(
                    card: card,
                    captureService: captureService,
                    invalidationCenter: cardDataInvalidationCenter,
                    onDeleted: onCardDeleted
                )
            }
        case .remoteCardDetail(let card):
            RemoteCardDetailDestination(
                card: card,
                captureService: captureService,
                invalidationCenter: cardDataInvalidationCenter,
                onDeleted: onCardDeleted
            )
        case .cardCreationStart:
            CardCreationFlowView(
                viewModel: CardCreationFlowViewModel(
                    processor: cardCreationProcessor,
                    invalidationCenter: cardDataInvalidationCenter,
                    notificationController: organizeNotificationController,
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
    @Environment(RecapCardStore.self) private var cardStore

    let card: InformationCard
    let captureService: any CaptureServing
    let invalidationCenter: CardDataInvalidationCenter
    let onDeleted: () -> Void

    var body: some View {
        CardDetailView(
            card: card,
            captureService: captureService,
            invalidationCenter: invalidationCenter,
            onDeleted: onDeleted
        )
            .onAppear {
                cardStore.cacheRemoteCards([card])
            }
    }
}
