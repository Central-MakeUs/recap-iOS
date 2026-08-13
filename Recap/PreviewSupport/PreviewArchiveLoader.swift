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
            summaries: CollectionKind.folderCases.map { kind in
                let cardsForKind = cards.filter { $0.collection == kind }
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
            },
            favoriteCount: cards.filter(\.isFavorite).count,
            otherCount: cards.filter { $0.collection == .other }.count
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
        case .category(let kind):
            return cards.filter { $0.collection == kind }
        }
    }
}
#endif
