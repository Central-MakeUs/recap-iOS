import SwiftUI

extension View {
    @MainActor
    func withAppNavigationDestinations(
        cardStore: RecapCardStore,
        archiveLoader: any ArchiveLoading,
        captureService: any CaptureServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        onCardDeleted: @escaping () -> Void
    ) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            destination(
                for: route,
                cardStore: cardStore,
                archiveLoader: archiveLoader,
                captureService: captureService,
                cardCreationProcessor: cardCreationProcessor,
                cardDataInvalidationCenter: cardDataInvalidationCenter,
                onCardDeleted: onCardDeleted
            )
        }
    }

    @MainActor
    @ViewBuilder
    private func destination(
        for route: AppRoute,
        cardStore: RecapCardStore,
        archiveLoader: any ArchiveLoading,
        captureService: any CaptureServing,
        cardCreationProcessor: any CardCreationProcessing,
        cardDataInvalidationCenter: CardDataInvalidationCenter,
        onCardDeleted: @escaping () -> Void
    ) -> some View {
        switch route {
        case .search:
            SearchContainerView()
        case .allRecentCards:
            AllRecentCardsContainerView()
        case .archiveFavorites:
            CollectionDetailContainerView(
                scope: .favorites,
                loader: archiveLoader,
                invalidationCenter: cardDataInvalidationCenter
            )
        case .archiveDetail(let kind):
            CollectionDetailContainerView(
                scope: .category(kind),
                loader: archiveLoader,
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
                    invalidationCenter: cardDataInvalidationCenter
                )
            )
        case .settings:
            AccountManagementView()
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
