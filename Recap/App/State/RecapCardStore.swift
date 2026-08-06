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
            let recentTitles = cardsForKind
                .sorted { ($0.organizedAt ?? .distantPast) > ($1.organizedAt ?? .distantPast) }
                .prefix(2)
                .map(\.title)
                .joined(separator: " · ")
            return CollectionSummary(
                kind: kind,
                count: cardsForKind.count,
                previewTitle: recentTitles
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

    func removeAllCards() {
        cards.removeAll()
    }

    func cacheRemoteCards(_ remoteCards: [InformationCard]) {
        for remoteCard in remoteCards {
            guard let captureID = remoteCard.captureID else { continue }

            if let index = cards.firstIndex(where: { $0.captureID == captureID }) {
                cards[index] = remoteCard
            } else {
                cards.append(remoteCard)
            }
        }
    }
}

/// 순수 값 복사라 격리가 필요 없다. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
/// 아래에서는 extension 멤버가 암묵적으로 MainActor가 되므로 명시한다.
nonisolated extension InformationCard {
    func with(editDraft draft: CardEditDraft) -> InformationCard {
        InformationCard(
            id: id,
            captureID: captureID,
            title: draft.title,
            summary: draft.summary,
            collection: draft.collection,
            organizedAt: organizedAt,
            dateText: dateText,
            location: location,
            businessHours: businessHours,
            category: draft.collection.displayTitle,
            confirmationLabel: confirmationLabel,
            memo: draft.body,
            tags: tags,
            originalImageAssetName: originalImageAssetName,
            thumbnailAssetName: thumbnailAssetName,
            originalImageURL: originalImageURL,
            thumbnailURL: thumbnailURL,
            isFavorite: isFavorite
        )
    }

    func with(isFavorite: Bool) -> InformationCard {
        InformationCard(
            id: id, captureID: captureID, title: title, summary: summary, collection: collection,
            organizedAt: organizedAt,
            dateText: dateText, location: location, businessHours: businessHours,
            category: category, confirmationLabel: confirmationLabel, memo: memo,
            tags: tags, originalImageAssetName: originalImageAssetName,
            thumbnailAssetName: thumbnailAssetName, originalImageURL: originalImageURL,
            thumbnailURL: thumbnailURL,
            isFavorite: isFavorite
        )
    }
}
