import Foundation

@MainActor
final class PreviewSearchLoader: SearchLoading {
    func search(
        query: String,
        scope: SearchScope,
        page: Int,
        size: Int
    ) async throws -> SearchPage {
        let cards = SampleData.search(query)
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
