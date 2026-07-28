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
                return CollectionSummary(
                    kind: kind,
                    count: cardsForKind.count,
                    previewTitle: cardsForKind.first?.title ?? "카드 없음"
                )
            },
            favoriteCount: cards.filter(\.isFavorite).count,
            otherCount: cards.filter { $0.collection == .other }.count
        )
    }

    func fetchCards(
        scope: ArchiveDetailScope,
        sort: ArchiveSort
    ) async throws -> [InformationCard] {
        let cards = await cardRepository.allCards()

        switch scope {
        case .favorites:
            return cards.filter(\.isFavorite)
        case .category(let kind):
            return cards.filter { $0.collection == kind }
        }
    }
}
