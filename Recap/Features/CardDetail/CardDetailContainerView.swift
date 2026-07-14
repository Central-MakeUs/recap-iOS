import SwiftUI

struct CardDetailContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    let cardID: InformationCard.ID

    var body: some View {
        if let card = cardStore.card(id: cardID) {
            CardDetailView(card: card, onAction: handleAction)
        } else {
            MissingCardView(cardID: cardID)
        }
    }

    private func handleAction(_ action: CardDetailAction) {
        switch action {
        case .openOriginal(let id):
            router.presentFullScreenCover(.originalPreview(cardID: id))
        case .share(let id):
            router.presentSheet(.sharePreview(cardID: id))
        case .edit(let id):
            router.navigate(.cardEdit(id))
        case .changeCollection(let id):
            router.presentSheet(.collectionPicker(cardID: id))
        case .toggleFavorite(let id):
            cardStore.toggleFavorite(id: id)
        case .exclude(let id), .delete(let id):
            cardStore.removeCard(id: id)
            dismiss()
        }
    }
}

#Preview("정보카드 상세 컨테이너") {
    NavigationStack {
        CardDetailContainerView(cardID: SampleData.cards[1].id)
    }
    .environment(AppRouter())
    .environment(PreviewStores.recapCardStore())
}
