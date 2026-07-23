import Foundation

nonisolated struct HomeSummaryDTO: Decodable, Sendable {
    let recentCaptures: [HomeCaptureSummaryDTO]
    let favorites: [HomeCaptureSummaryDTO]
    let topTypes: [HomeTopTypeDTO]
    let hasAnyCapture: Bool
}

nonisolated struct HomeCaptureSummaryDTO: Decodable, Sendable {
    let captureId: Int64
    let title: String
    let summary: String
    let typeCode: CardTypeCode
    let thumbnailUrl: URL?
    let isFavorite: Bool
    let organizedAt: Date
}

nonisolated struct HomeTopTypeDTO: Decodable, Sendable {
    let typeCode: CardTypeCode
    let count: Int
    let representativeThumbnailUrl: URL?
}
