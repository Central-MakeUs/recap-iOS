#if DEBUG
import Foundation

@MainActor
final class PreviewSearchLoader: SearchLoading {
    private let cardRepository: PreviewCardRepository

    init(cardRepository: PreviewCardRepository = PreviewCardRepository()) {
        self.cardRepository = cardRepository
    }

    func search(
        query: String,
        scope: SearchScope,
        page: Int,
        size: Int
    ) async throws -> SearchPage {
        let allCards = await cardRepository.allCards()
        let queryResults = RecapCardCollection.search(allCards, query: query)
        let cards = queryResults.filter { card in
            switch scope {
            case .all:
                true
            case .favorites:
                card.isFavorite
            case .other:
                card.category == .other
            case .type(let category):
                card.category == category
            }
        }
        let start = min(page * size, cards.count)
        let end = min(start + size, cards.count)
        let pageCards = cards[start..<end]

        return SearchPage(
            count: cards.count,
            hasNext: end < cards.count,
            items: pageCards.map(SearchResult.init(card:))
        )
    }
}
#endif
