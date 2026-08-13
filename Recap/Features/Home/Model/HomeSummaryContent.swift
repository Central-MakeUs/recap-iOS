import Foundation

nonisolated struct HomeSummaryContent: Equatable, Sendable {
    let recentCards: [InformationCard]
    let favoriteCards: [InformationCard]
    let frequentTypes: [CollectionSummary]
    let hasAnyCapture: Bool

    init(
        recentCards: [InformationCard],
        favoriteCards: [InformationCard],
        frequentTypes: [CollectionSummary],
        hasAnyCapture: Bool
    ) {
        self.recentCards = recentCards
        self.favoriteCards = favoriteCards
        self.frequentTypes = frequentTypes
        self.hasAnyCapture = hasAnyCapture
    }

    init(dto: HomeSummaryDTO) {
        recentCards = dto.recentCaptures.map(InformationCard.init(dto:))
        favoriteCards = dto.favorites
            .enumerated()
            .sorted { lhs, rhs in
                lhs.element.organizedAt == rhs.element.organizedAt
                    ? lhs.offset < rhs.offset
                    : lhs.element.organizedAt > rhs.element.organizedAt
            }
            .map { InformationCard(dto: $0.element) }
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

extension InformationCard {
    nonisolated init(dto: HomeCaptureSummaryDTO) {
        let kind = dto.typeCode.collectionKind

        self.init(
            id: UUID(),
            captureID: dto.captureId,
            title: dto.title,
            summary: dto.summary,
            collection: kind,
            organizedAt: dto.organizedAt,
            location: "",
            businessHours: "",
            category: dto.typeCode.displayTitle,
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
    let cards: [InformationCard]

    init(totalCount: Int, hasNext: Bool, cards: [InformationCard]) {
        self.totalCount = totalCount
        self.hasNext = hasNext
        self.cards = cards
    }

    init(dto: RecentCapturesPageDTO) {
        totalCount = dto.count
        hasNext = dto.hasNext
        cards = dto.items.map(InformationCard.init(dto:))
    }
}

private extension CollectionSummary {
    nonisolated init(dto: HomeTopTypeDTO) {
        let kind = dto.typeCode.collectionKind

        self.init(
            kind: kind,
            count: dto.count,
            previewTitle: dto.typeCode.displayTitle,
            representativeThumbnailURL: dto.representativeThumbnailUrl
        )
    }
}
