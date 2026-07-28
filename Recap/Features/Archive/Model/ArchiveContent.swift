import Foundation

nonisolated struct ArchiveHomeRefreshScope: OptionSet, Sendable {
    let rawValue: Int

    static let types = Self(rawValue: 1 << 0)
    static let favorites = Self(rawValue: 1 << 1)
    static let other = Self(rawValue: 1 << 2)
    static let all: Self = [.types, .favorites, .other]
}

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

nonisolated enum ArchiveSort: String, CaseIterable, Hashable, Sendable {
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

    var toggled: ArchiveSort {
        self == .latest ? .oldest : .latest
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
