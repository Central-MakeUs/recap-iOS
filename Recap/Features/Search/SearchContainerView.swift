import SwiftUI

struct SearchContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        SearchResultsView(
            search: cardStore.search,
            onAction: handleAction
        )
    }

    private func handleAction(_ action: SearchAction) {
        switch action {
        case .openCard(let id):
            router.navigate(.cardDetail(id))
        }
    }
}
