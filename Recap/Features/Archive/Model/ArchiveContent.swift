import Foundation

nonisolated struct ArchiveHomeContent: Equatable, Sendable {
    let summaries: [CollectionSummary]
    let favoriteCount: Int
    let otherCount: Int

    static let empty = ArchiveHomeContent(
        summaries: [],
        favoriteCount: 0,
        otherCount: 0
    )
}

nonisolated enum ArchiveSort: String, CaseIterable, Sendable {
    case latest
    case oldest

    var title: String {
        switch self {
        case .latest:
            "최신순"
        case .oldest:
            "오래된순"
        }
    }
}

extension InformationCard {
    nonisolated init(archiveDTO dto: ArchiveCaptureSummaryDTO) {
        self.init(
            id: UUID(),
            captureID: dto.captureId,
            title: dto.title,
            summary: dto.summary,
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
}

extension CollectionSummary {
    nonisolated init(archiveDTO dto: ArchiveStorageTypeDTO) {
        self.init(
            kind: dto.typeCode.collectionKind,
            count: dto.count,
            previewTitle: dto.representativeTitles.first ?? "카드 없음"
        )
    }
}
