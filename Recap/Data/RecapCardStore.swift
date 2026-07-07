import Foundation
import Observation

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

    var collectionSummaries: [CollectionSummary] {
        CollectionKind.allCases.map { kind in
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
        guard !query.isEmpty else { return Array(cards.prefix(2)) }
        return cards.filter { card in
            card.title.localizedCaseInsensitiveContains(query)
                || card.summary.localizedCaseInsensitiveContains(query)
                || card.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    func moveCard(id: InformationCard.ID, to collection: CollectionKind) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index] = cards[index].with(collection: collection)
    }

    func removeCard(id: InformationCard.ID) {
        cards.removeAll { $0.id == id }
    }
}

private extension InformationCard {
    func with(collection: CollectionKind) -> InformationCard {
        InformationCard(
            id: id,
            title: title,
            summary: summary,
            collection: collection,
            dateText: dateText,
            location: location,
            businessHours: businessHours,
            category: category,
            confirmationLabel: confirmationLabel,
            memo: memo,
            tags: tags
        )
    }
}
