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

    /// 같은 캡처가 최근·즐겨찾기 목록에 각각 다른 `id`로 존재하므로 `captureID`로 찾는다.
    func applyingFavorite(_ isFavorite: Bool, captureID: Int64) -> HomeSummaryContent {
        HomeSummaryContent(
            recentCards: recentCards.map { card in
                card.captureID == captureID ? card.with(isFavorite: isFavorite) : card
            },
            favoriteCards: isFavorite
                ? favoriteCards
                : favoriteCards.filter { $0.captureID != captureID },
            frequentTypes: frequentTypes,
            hasAnyCapture: hasAnyCapture
        )
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
