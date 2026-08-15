#if DEBUG
import Foundation

@MainActor
final class PreviewArchiveLoader: ArchiveLoading {
    private let cardRepository: PreviewCardRepository

    init(cardRepository: PreviewCardRepository = PreviewCardRepository()) {
        self.cardRepository = cardRepository
    }

    func fetchHome() async throws -> ArchiveHomeContent {
        let cards = await cardRepository.allCards()
        return ArchiveHomeContent(
            summaries: CardCategory.folderCases.map { category in
                let cardsForKind = cards.filter { $0.category == category }
                let recentTitles = cardsForKind
                    .sorted { ($0.organizedAt ?? .distantPast) > ($1.organizedAt ?? .distantPast) }
                    .prefix(2)
                    .map(\.title)
                    .joined(separator: " · ")
                return CategorySummary(
                    category: category,
                    count: cardsForKind.count,
                    previewTitle: recentTitles
                )
            },
            favoriteCount: cards.filter(\.isFavorite).count,
            otherCount: cards.filter { $0.category == .other }.count
        )
    }

    func fetchCards(
        scope: ArchiveDetailScope,
        sort: ArchiveSort
    ) async throws -> [CardSnapshot] {
        let cards = await cardRepository.allCards()

        switch scope {
        case .favorites:
            return cards.filter(\.isFavorite)
        case .category(let category):
            return cards.filter { $0.category == category }
        }
    }
}
#endif
