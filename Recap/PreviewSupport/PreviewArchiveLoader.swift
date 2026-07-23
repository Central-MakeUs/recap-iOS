import Foundation

@MainActor
final class PreviewArchiveLoader: ArchiveLoading {
    func fetchHome() async throws -> ArchiveHomeContent {
        ArchiveHomeContent(
            summaries: SampleData.collectionSummaries,
            favoriteCount: SampleData.cards.filter(\.isFavorite).count,
            otherCount: SampleData.cards(in: .other).count
        )
    }

    func fetchCards(
        scope: ArchiveDetailScope,
        sort: ArchiveSort
    ) async throws -> [InformationCard] {
        switch scope {
        case .favorites:
            SampleData.cards.filter(\.isFavorite)
        case .category(let kind):
            SampleData.cards(in: kind)
        }
    }
}
