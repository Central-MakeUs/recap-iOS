import SwiftUI

extension View {
    @MainActor
    func withAppNavigationDestinations(
        cardStore: RecapCardStore,
        onCardDeleted: @escaping () -> Void
    ) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            destination(
                for: route,
                cardStore: cardStore,
                onCardDeleted: onCardDeleted
            )
        }
    }

    @MainActor
    @ViewBuilder
    private func destination(
        for route: AppRoute,
        cardStore: RecapCardStore,
        onCardDeleted: @escaping () -> Void
    ) -> some View {
        switch route {
        case .search:
            SearchContainerView()
        case .allRecentCards:
            AllRecentCardsContainerView()
        case .archiveDetail(let kind):
            CollectionDetailContainerView(kind: kind)
        case .cardDetail(let id):
            if let card = cardStore.card(id: id) {
                CardDetailView(card: card, onDeleted: onCardDeleted)
            }
        case .cardCreationStart:
            CardCreationFlowView()
        case .settings:
            SettingsContainerView()
        }
    }
}
