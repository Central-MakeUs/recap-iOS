import Foundation
import Observation

enum RecapCardCollection {
    static func search(_ cards: [InformationCard], query: String) -> [InformationCard] {
        guard !query.isEmpty else { return [] }
        return cards.filter { card in
            card.title.localizedCaseInsensitiveContains(query)
                || card.summary.localizedCaseInsensitiveContains(query)
                || card.category.localizedCaseInsensitiveContains(query)
                || card.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    static func moving(
        cardID: InformationCard.ID,
        in cards: [InformationCard],
        to collection: CollectionKind
    ) -> [InformationCard] {
        cards.map { card in
            card.id == cardID ? card.with(collection: collection) : card
        }
    }

    static func togglingFavorite(
        cardID: InformationCard.ID,
        in cards: [InformationCard]
    ) -> [InformationCard] {
        cards.map { card in
            card.id == cardID ? card.with(isFavorite: !card.isFavorite) : card
        }
    }
}

@MainActor
@Observable
final class RecapCardStore {
    private var cards: [InformationCard]

    init(cards: [InformationCard]) {
        self.cards = cards
    }

    var recentCards: [InformationCard] {
        Array(cards.prefix(3))
    }

    var favoriteCards: [InformationCard] {
        cards.filter(\.isFavorite)
    }

    var uncategorizedCards: [InformationCard] {
        cards.filter { $0.collection == .other }
    }

    var collectionSummaries: [CollectionSummary] {
        CollectionKind.folderCases.map { kind in
            let cardsForKind = cards(in: kind)
            return CollectionSummary(
                kind: kind,
                count: cardsForKind.count,
                previewTitle: cardsForKind.first?.title ?? "카드 없음"
            )
        }
    }

    func allCards() -> [InformationCard] {
        cards
    }

    func cards(in kind: CollectionKind) -> [InformationCard] {
        cards.filter { $0.collection == kind }
    }

    func card(id: InformationCard.ID) -> InformationCard? {
        cards.first { $0.id == id }
    }

    func search(_ query: String) -> [InformationCard] {
        RecapCardCollection.search(cards, query: query)
    }

    func moveCard(id: InformationCard.ID, to collection: CollectionKind) {
        cards = RecapCardCollection.moving(cardID: id, in: cards, to: collection)
    }

    func updateCard(id: InformationCard.ID, with draft: CardEditDraft) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index] = cards[index].with(editDraft: draft)
    }

    func toggleFavorite(id: InformationCard.ID) {
        cards = RecapCardCollection.togglingFavorite(cardID: id, in: cards)
    }

    func removeCard(id: InformationCard.ID) {
        cards.removeAll { $0.id == id }
    }
}

extension InformationCard {
    func with(collection: CollectionKind) -> InformationCard {
        InformationCard(
            id: id,
            title: title,
            summary: summary,
            collection: collection,
            dateText: dateText,
            location: location,
            businessHours: businessHours,
            category: RecapPresentation.collectionDisplay(for: collection).title,
            confirmationLabel: confirmationLabel,
            memo: memo,
            tags: tags,
            originalImageAssetName: originalImageAssetName,
            thumbnailAssetName: thumbnailAssetName,
            isFavorite: isFavorite
        )
    }

    func with(editDraft draft: CardEditDraft) -> InformationCard {
        InformationCard(
            id: id,
            title: draft.title,
            summary: draft.summary,
            collection: draft.collection,
            dateText: dateText,
            location: location,
            businessHours: businessHours,
            category: RecapPresentation.collectionDisplay(for: draft.collection).title,
            confirmationLabel: confirmationLabel,
            memo: draft.body,
            tags: tags,
            originalImageAssetName: originalImageAssetName,
            thumbnailAssetName: thumbnailAssetName,
            isFavorite: isFavorite
        )
    }

    func with(isFavorite: Bool) -> InformationCard {
        InformationCard(
            id: id, title: title, summary: summary, collection: collection,
            dateText: dateText, location: location, businessHours: businessHours,
            category: category, confirmationLabel: confirmationLabel, memo: memo,
            tags: tags, originalImageAssetName: originalImageAssetName,
            thumbnailAssetName: thumbnailAssetName, isFavorite: isFavorite
        )
    }
}
