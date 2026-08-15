import Foundation

nonisolated struct HomeSummaryContent: Equatable, Sendable {
    let recentCards: [CardSnapshot]
    let favoriteCards: [CardSnapshot]
    let frequentTypes: [CollectionSummary]
    let hasAnyCapture: Bool

    init(
        recentCards: [CardSnapshot],
        favoriteCards: [CardSnapshot],
        frequentTypes: [CollectionSummary],
        hasAnyCapture: Bool
    ) {
        self.recentCards = recentCards
        self.favoriteCards = favoriteCards
        self.frequentTypes = frequentTypes
        self.hasAnyCapture = hasAnyCapture
    }

    init(dto: HomeSummaryDTO) {
        recentCards = dto.recentCaptures.map(CardSnapshot.init(dto:))
        favoriteCards = dto.favorites
            .enumerated()
            .sorted { lhs, rhs in
                lhs.element.organizedAt == rhs.element.organizedAt
                    ? lhs.offset < rhs.offset
                    : lhs.element.organizedAt > rhs.element.organizedAt
            }
            .map { CardSnapshot(dto: $0.element) }
        frequentTypes = dto.topTypes.map(CollectionSummary.init(dto:))
        hasAnyCapture = dto.hasAnyCapture
    }

    static let empty = HomeSummaryContent(
        recentCards: [],
        favoriteCards: [],
        frequentTypes: [],
        hasAnyCapture: false
    )
}

extension CardSnapshot {
    nonisolated init(dto: HomeCaptureSummaryDTO) {
        let kind = dto.typeCode.collectionKind

        self.init(
            captureID: dto.captureId,
            title: dto.title,
            summary: dto.summary,
            collection: kind,
            organizedAt: dto.organizedAt,
            location: "",
            businessHours: "",
            confirmationLabel: nil,
            memo: "",
            tags: [],
            thumbnailURL: dto.thumbnailUrl,
            isFavorite: dto.isFavorite
        )
    }
}

nonisolated struct RecentCapturesPage: Equatable, Sendable {
    let totalCount: Int
    let hasNext: Bool
    let cards: [CardSnapshot]

    init(totalCount: Int, hasNext: Bool, cards: [CardSnapshot]) {
        self.totalCount = totalCount
        self.hasNext = hasNext
        self.cards = cards
    }

    init(dto: RecentCapturesPageDTO) {
        totalCount = dto.count
        hasNext = dto.hasNext
        cards = dto.items.map(CardSnapshot.init(dto:))
    }
}

private extension CollectionSummary {
    nonisolated init(dto: HomeTopTypeDTO) {
        let kind = dto.typeCode.collectionKind

        self.init(
            kind: kind,
            count: dto.count,
            previewTitle: kind.displayTitle,
            representativeThumbnailURL: dto.representativeThumbnailUrl
        )
    }
}
