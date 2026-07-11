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
                        let collection = RecapPresentation.collectionDisplay(for: card.collection)
                        HStack(spacing: RecapTheme.Spacing.medium) {
                            RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                                .fill(RecapTheme.ColorToken.thumbnail)
                                .overlay(
                                    RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                                        .fill(collection.dotColor.opacity(0.08))
                                )
                                .overlay(
                                    Image(systemName: "doc.text.fill")
                                        .font(.caption)
                                        .foregroundStyle(collection.dotColor.opacity(0.55))
                                )
                                .frame(width: 54, height: 54)

                            VStack(alignment: .leading, spacing: RecapTheme.Spacing.xSmall) {
                                Text(card.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                                    .lineLimit(1)

                                Text(card.summary)
                                    .font(.caption)
                                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                                    .lineLimit(1)

                                HStack(spacing: RecapTheme.Spacing.xSmall) {
                                    Circle()
                                        .fill(collection.dotColor)
                                        .frame(width: 5, height: 5)
                                    Text(collection.title)
                                    Text("·")
                                    Text(card.dateText)
                                }
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                            }

                            Spacer(minLength: RecapTheme.Spacing.small)
                        }
                        .padding(RecapTheme.Spacing.medium)
                        .recapCard(radius: RecapTheme.Radius.medium)
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
