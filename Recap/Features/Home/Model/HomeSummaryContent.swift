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
        favoriteCards = dto.favorites.map(InformationCard.init(dto:))
        frequentTypes = dto.topTypes.map(CollectionSummary.init(dto:))
        hasAnyCapture = dto.hasAnyCapture
    }

    var allCards: [InformationCard] {
        var cardsByCaptureID: [Int64: InformationCard] = [:]

        for card in recentCards + favoriteCards {
            guard let captureID = card.captureID else { continue }
            cardsByCaptureID[captureID] = card
        }

        return Array(cardsByCaptureID.values)
    }

    static let empty = HomeSummaryContent(
        recentCards: [],
        favoriteCards: [],
        frequentTypes: [],
        hasAnyCapture: false
    )
}

private extension InformationCard {
    nonisolated init(dto: HomeCaptureSummaryDTO) {
        let kind = dto.typeCode.collectionKind

        self.init(
            id: UUID(),
            captureID: dto.captureId,
            title: dto.title,
            summary: dto.summary,
            collection: kind,
            organizedAt: dto.organizedAt,
            dateText: dto.organizedAt.formatted(
                .dateTime.year().month(.twoDigits).day(.twoDigits)
            ),
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
