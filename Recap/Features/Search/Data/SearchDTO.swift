import Foundation

nonisolated struct SearchResponseDTO: Decodable, Sendable {
    let count: Int
    let hasNext: Bool
    let items: [SearchResultDTO]
}

nonisolated struct SearchResultDTO: Decodable, Sendable {
    let captureId: Int64
    let typeCode: CardTypeCode
    let thumbnailUrl: URL?
    let titleHighlighted: String
    let summaryHighlighted: String
    let ocrExcerptHighlighted: String?
    let isFavorite: Bool
    let organizedAt: Date
}
