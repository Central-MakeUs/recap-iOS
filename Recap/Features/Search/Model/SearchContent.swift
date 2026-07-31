import Foundation

nonisolated enum SearchScope: Equatable, Sendable {
    case all
    case favorites
    case other
    case type(CollectionKind)

    var queryValue: String {
        switch self {
        case .all:
            "ALL"
        case .favorites:
            "FAVORITE"
        case .other:
            "ETC"
        case .type:
            "TYPE"
        }
    }

    var typeCode: CardTypeCode? {
        guard case .type(let kind) = self else { return nil }
        return CardTypeCode(collectionKind: kind)
    }
}

nonisolated struct SearchHighlightSegment: Equatable, Sendable {
    let text: String
    let isHighlighted: Bool
}

nonisolated struct SearchHighlightedString: Equatable, Sendable {
    let segments: [SearchHighlightSegment]

    init(serverValue: String) {
        segments = Self.parse(serverValue)
    }

    var plainText: String {
        segments.map(\.text).joined()
    }

    private static func parse(_ value: String) -> [SearchHighlightSegment] {
        let openingTag = "<mark>"
        let closingTag = "</mark>"
        var remaining = value[...]
        var parsed: [SearchHighlightSegment] = []

        while let openingRange = remaining.range(of: openingTag) {
            append(
                String(remaining[..<openingRange.lowerBound]),
                highlighted: false,
                to: &parsed
            )

            let highlightedStart = openingRange.upperBound
            guard let closingRange = remaining[highlightedStart...].range(of: closingTag) else {
                append(String(remaining[openingRange.lowerBound...]), highlighted: false, to: &parsed)
                return parsed
            }

            append(
                String(remaining[highlightedStart..<closingRange.lowerBound]),
                highlighted: true,
                to: &parsed
            )
            remaining = remaining[closingRange.upperBound...]
        }

        append(String(remaining), highlighted: false, to: &parsed)
        return parsed
    }

    private static func append(
        _ text: String,
        highlighted: Bool,
        to segments: inout [SearchHighlightSegment]
    ) {
        guard !text.isEmpty else { return }
        segments.append(
            SearchHighlightSegment(text: text, isHighlighted: highlighted)
        )
    }
}

nonisolated struct SearchResult: Identifiable, Equatable, Sendable {
    let captureID: Int64
    let card: InformationCard
    let title: SearchHighlightedString
    let summary: SearchHighlightedString

    var id: InformationCard.ID { card.id }

    init(dto: SearchResultDTO) {
        let title = SearchHighlightedString(serverValue: dto.titleHighlighted)
        let summary = SearchHighlightedString(
            serverValue: dto.ocrExcerptHighlighted ?? dto.summaryHighlighted
        )

        self.captureID = dto.captureId
        self.title = title
        self.summary = summary
        self.card = InformationCard(
            id: UUID(),
            captureID: dto.captureId,
            title: title.plainText,
            summary: summary.plainText,
            collection: dto.typeCode.collectionKind,
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

    init(card: InformationCard) {
        captureID = card.captureID ?? 0
        self.card = card
        title = SearchHighlightedString(serverValue: card.title)
        summary = SearchHighlightedString(serverValue: card.summary)
    }

    private init(
        captureID: Int64,
        card: InformationCard,
        title: SearchHighlightedString,
        summary: SearchHighlightedString
    ) {
        self.captureID = captureID
        self.card = card
        self.title = title
        self.summary = summary
    }

    /// 하이라이트를 유지한 채 카드만 교체한다.
    func with(card: InformationCard) -> SearchResult {
        SearchResult(
            captureID: captureID,
            card: card,
            title: title,
            summary: summary
        )
    }
}

nonisolated struct SearchPage: Equatable, Sendable {
    let count: Int
    let hasNext: Bool
    let items: [SearchResult]

    init(count: Int, hasNext: Bool, items: [SearchResult]) {
        self.count = count
        self.hasNext = hasNext
        self.items = items
    }

    init(dto: SearchResponseDTO) {
        count = dto.count
        hasNext = dto.hasNext
        items = dto.items.map(SearchResult.init(dto:))
    }
}

nonisolated struct SearchContent: Equatable, Sendable {
    let query: String
    let totalCount: Int
    let hasNext: Bool
    let nextPage: Int
    let results: [SearchResult]

    func applyingFavorite(_ isFavorite: Bool, captureID: Int64) -> SearchContent {
        SearchContent(
            query: query,
            totalCount: totalCount,
            hasNext: hasNext,
            nextPage: nextPage,
            results: results.map { result in
                result.captureID == captureID
                    ? result.with(card: result.card.with(isFavorite: isFavorite))
                    : result
            }
        )
    }
}
