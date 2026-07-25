import SwiftUI

struct SearchContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    @State private var model: SearchFeatureModel

    init(loader: any SearchLoading) {
        _model = State(initialValue: SearchFeatureModel(loader: loader))
    }

    var body: some View {
        SearchResultsView(
            model: model,
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
