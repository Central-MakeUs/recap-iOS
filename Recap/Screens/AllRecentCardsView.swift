import SwiftUI

struct AllRecentCardsContainerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(RecapCardStore.self) private var cardStore

    var body: some View {
        AllRecentCardsView(cards: cardStore.allCards()) { cardID in
            router.navigate(.cardDetail(cardID))
        }
    }
}

struct AllRecentCardsView: View {
    let cards: [InformationCard]
    let onSelectCard: (InformationCard.ID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.medium) {
                ForEach(cards) { card in
                    Button {
                        onSelectCard(card.id)
                    } label: {
                        InfoCardRow(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(RecapTheme.Spacing.large)
        }
        .background(RecapTheme.ColorToken.background)
        .navigationTitle("전체 정리된 카드")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AllRecentCardsView(
            cards: SampleData.cards,
            onSelectCard: PreviewActions.handleCardSelection
        )
    }
}
