import Foundation

nonisolated struct ArchiveCaptureListDTO: Decodable, Sendable {
    let count: Int
    let items: [ArchiveCaptureSummaryDTO]
}

nonisolated struct ArchiveCaptureSummaryDTO: Decodable, Sendable {
    let captureId: Int64
    let title: String
    let summary: String
    let typeCode: CardTypeCode
    let thumbnailUrl: URL?
    let isFavorite: Bool
    let organizedAt: Date
}

nonisolated struct ArchiveStorageTypeDTO: Decodable, Sendable {
    let typeCode: CardTypeCode
    let count: Int
    let representativeTitles: [String]
}
