import SwiftUI

@MainActor
struct SearchContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(CardStore.self) private var cardStore

    @State private var model: SearchFeatureModel
    @State private var recentSearchStore: RecentSearchStore

    let invalidationCenter: CardDataInvalidationCenter

    init(
        loader: any SearchLoading,
        captureMutator: any CaptureMutating,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        _model = State(
            initialValue: SearchFeatureModel(
                loader: loader,
                captureMutator: captureMutator,
                invalidationCenter: invalidationCenter
            )
        )
        _recentSearchStore = State(initialValue: RecentSearchStore())
        self.invalidationCenter = invalidationCenter
    }

    init(
        loader: any SearchLoading,
        recentSearchStore: RecentSearchStore,
        captureMutator: any CaptureMutating,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        _model = State(
            initialValue: SearchFeatureModel(
                loader: loader,
                captureMutator: captureMutator,
                invalidationCenter: invalidationCenter
            )
        )
        _recentSearchStore = State(initialValue: recentSearchStore)
        self.invalidationCenter = invalidationCenter
    }

    var body: some View {
        SearchResultsView(
            model: model,
            recentSearchStore: recentSearchStore,
            onAction: handleAction
        )
        .task(id: invalidationCenter.searchRevision) {
            guard invalidationCenter.searchRevision > 0 else { return }
            await model.refreshCurrentQuery()
        }
    }

    private func handleAction(_ action: SearchAction) {
        switch action {
        case .openCard(let card):
            cardStore.upsert(card)
            router.navigate(.remoteCardDetail(card))
        }
    }
}
