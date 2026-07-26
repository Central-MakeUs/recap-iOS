import SwiftUI

@MainActor
struct SearchContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    @State private var model: SearchFeatureModel
    @State private var recentSearchStore: RecentSearchStore

    init(loader: any SearchLoading) {
        _model = State(initialValue: SearchFeatureModel(loader: loader))
        _recentSearchStore = State(initialValue: RecentSearchStore())
    }

    init(loader: any SearchLoading, recentSearchStore: RecentSearchStore) {
        _model = State(initialValue: SearchFeatureModel(loader: loader))
        _recentSearchStore = State(initialValue: recentSearchStore)
    }

    var body: some View {
        SearchResultsView(
            model: model,
            recentSearchStore: recentSearchStore,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: SearchAction) {
        switch action {
        case .openCard(let card):
            cardStore.cacheRemoteCards([card])
            router.navigate(.remoteCardDetail(card))
        }
    }
}
