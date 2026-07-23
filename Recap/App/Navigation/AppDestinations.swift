import SwiftUI

extension View {
    @MainActor
    func withAppNavigationDestinations(
        cardStore: RecapCardStore,
        archiveLoader: any ArchiveLoading,
        onCardDeleted: @escaping () -> Void
    ) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            destination(
                for: route,
                cardStore: cardStore,
                archiveLoader: archiveLoader,
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
                loader: archiveLoader
            )
        case .archiveDetail(let kind):
            CollectionDetailContainerView(
                scope: .category(kind),
                loader: archiveLoader
            )
        case .cardDetail(let id):
            if let card = cardStore.card(id: id) {
                CardDetailView(card: card, onDeleted: onCardDeleted)
            }
        case .remoteCardDetail(let card):
            RemoteCardDetailDestination(
                card: card,
                onDeleted: onCardDeleted
            )
        case .cardCreationStart:
            CardCreationFlowView()
        case .settings:
            AccountManagementView()
        }
    }
}

private struct RemoteCardDetailDestination: View {
    @Environment(RecapCardStore.self) private var cardStore

    let card: InformationCard
    let onDeleted: () -> Void

    var body: some View {
        CardDetailView(card: card, onDeleted: onDeleted)
            .onAppear {
                cardStore.cacheRemoteCards([card])
            }
    }
}
